import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage crittografato e autenticato (Cipher + Keyed MAC) per proteggere
/// i timestamp salvati in locale contro modifiche manuali o rollback dell'orologio.
class SecureTimeVault {
  static const String _vaultPrefsKey = 'ink_sec_time_vault_v1';
  static const List<int> _keyBytes = <int>[
    0x49, 0x4E, 0x4B, 0x5F, 0x54, 0x4F, 0x57, 0x45,
    0x52, 0x5F, 0x52, 0x49, 0x53, 0x4F, 0x5F, 0x32,
    0x30, 0x32, 0x36, 0x5F, 0x53, 0x41, 0x4C, 0x54,
    0xA5, 0x5A, 0xF0, 0x0F, 0xC3, 0x3C, 0x7E, 0xE7,
  ];

  /// Cifra e autentica un payload JSON restituendo un token Base64 sicuro.
  static String encryptAndSign(Map<String, dynamic> data) {
    final jsonBytes = utf8.encode(jsonEncode(data));
    final cipherBytes = Uint8List(jsonBytes.length);
    for (int i = 0; i < jsonBytes.length; i++) {
      final k1 = _keyBytes[i % _keyBytes.length];
      final k2 = ((i * 31) ^ 0x5D) & 0xFF;
      cipherBytes[i] = jsonBytes[i] ^ k1 ^ k2;
    }
    final mac = _computeKeyedMac(cipherBytes);
    final payload = base64UrlEncode(cipherBytes);
    return '$payload.$mac';
  }

  /// Verifica il MAC e decifra il token salvato. Restituisce `null` se manomesso.
  static Map<String, dynamic>? verifyAndDecrypt(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 2) return null;
    try {
      final cipherBytes = base64Url.decode(parts[0]);
      final expectedMac = _computeKeyedMac(cipherBytes);
      if (parts[1] != expectedMac) {
        return null; // Firma non valida: tentativo di manomissione dello storage!
      }
      final plainBytes = Uint8List(cipherBytes.length);
      for (int i = 0; i < cipherBytes.length; i++) {
        final k1 = _keyBytes[i % _keyBytes.length];
        final k2 = ((i * 31) ^ 0x5D) & 0xFF;
        plainBytes[i] = cipherBytes[i] ^ k1 ^ k2;
      }
      final decoded = jsonDecode(utf8.decode(plainBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Calcola un Message Authentication Code a 64-bit con mixing FNV-1a + Sip-style
  static String _computeKeyedMac(Uint8List bytes) {
    int h1 = 0xCBF29CE484222325;
    int h2 = 0x84222325CBF29CE4;
    for (int i = 0; i < _keyBytes.length; i++) {
      h1 ^= _keyBytes[i];
      h1 = (h1 * 0x100000001B3) & 0x7FFFFFFFFFFFFFFF;
    }
    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      h1 ^= b;
      h1 = (h1 * 0x100000001B3) & 0x7FFFFFFFFFFFFFFF;
      h2 ^= (b ^ _keyBytes[i % _keyBytes.length]);
      h2 = ((h2 << 7) | (h2 >> 57)) & 0x7FFFFFFFFFFFFFFF;
      h2 = (h2 * 0x9E3779B97F4A7C15) & 0x7FFFFFFFFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(16, '0')}${h2.toRadixString(16).padLeft(16, '0')}';
  }

  static Future<Map<String, dynamic>?> read(SharedPreferences? prefs) async {
    if (prefs == null) return null;
    final raw = prefs.getString(_vaultPrefsKey);
    return verifyAndDecrypt(raw);
  }

  static Future<void> write(
    SharedPreferences? prefs,
    Map<String, dynamic> data,
  ) async {
    if (prefs == null) return;
    final encrypted = encryptAndSign(data);
    await prefs.setString(_vaultPrefsKey, encrypted);
  }
}

/// Servizio anti-exploit per la validazione della data/ora dei Livelli Giornalieri:
/// 1. Verifica il timestamp UTC reale tramite server HTTP/NTP leggero.
/// 2. Mantiene un orologio monotonico hardware (`Stopwatch`) in memoria durante la sessione
///    attiva per calcolare il tempo attuale e il countdown rimanente, ignorando modifiche
///    all'orologio di sistema a runtime.
/// 3. In modalità offline, persiste l'ultimo timestamp Unix in `SecureTimeVault` (crittografato)
///    e blocca i contenuti giornalieri se rileva un rollback (`currentTime < lastRecordedTime`)
///    o uno spostamento manuale anomalo dell'orologio.
class TrustedTimeService {
  static final TrustedTimeService instance = TrustedTimeService();

  /// Tolleranza per micro-oscillazioni NTP di sistema (60 secondi)
  static const int rollbackToleranceMs = 60 * 1000;

  final Stopwatch _monotonicClock = Stopwatch();
  int _anchorUtcMs = 0;
  int _lastRecordedUnixMs = 0;
  int _maxObservedUnixMs = 0;
  bool _isNetworkVerified = false;
  bool _isClockTampered = false;
  bool _initialized = false;

  SharedPreferences? _prefs;

  TrustedTimeService() {
    _anchorUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    _monotonicClock.start();
  }

  bool get isNetworkVerified => _isNetworkVerified;
  bool get isClockTampered => _isClockTampered;
  int get lastRecordedUnixMs => _lastRecordedUnixMs;

  /// Inizializza il servizio leggendo lo storage crittografato e tentando
  /// una sincronizzazione non bloccante con il timestamp server.
  Future<void> init({
    SharedPreferences? prefs,
    bool attemptNetworkSync = true,
    DateTime? debugDeviceUtc,
  }) async {
    _prefs = prefs ?? _prefs;
    final deviceUtcMs =
        (debugDeviceUtc ?? DateTime.now().toUtc()).millisecondsSinceEpoch;

    // 1. Legge l'ultimo timestamp registrato dallo storage crittografato
    final vaultData = await SecureTimeVault.read(_prefs);
    if (vaultData != null) {
      _lastRecordedUnixMs = (vaultData['lastUnixMs'] as int?) ?? 0;
      _maxObservedUnixMs =
          (vaultData['maxUnixMs'] as int?) ?? _lastRecordedUnixMs;
      final wasTampered = (vaultData['tampered'] as bool?) ?? false;

      // Verifica anti-rollback: se currentTime < lastRecordedTime, rileva la manomissione!
      if (deviceUtcMs + rollbackToleranceMs < _lastRecordedUnixMs ||
          deviceUtcMs + rollbackToleranceMs < _maxObservedUnixMs) {
        _isClockTampered = true;
      } else {
        _isClockTampered = false;
      }

      if (wasTampered && _isClockTampered) {
        _isClockTampered = true;
      }
    } else if (_prefs != null &&
        _prefs!.containsKey('ink_sec_time_vault_v1')) {
      // Il vault esisteva ma la firma crittografica è stata alterata!
      _isClockTampered = true;
    }

    // Imposta l'ancora iniziale per il timer monotonico della sessione
    if (!_isClockTampered) {
      _anchorUtcMs = max(deviceUtcMs, _lastRecordedUnixMs);
      _lastRecordedUnixMs = _anchorUtcMs;
      _maxObservedUnixMs = max(_maxObservedUnixMs, _anchorUtcMs);
    } else {
      // Se manomesso, mantiene l'ultimo timestamp valido noto come riferimento
      _anchorUtcMs = max(_lastRecordedUnixMs, _maxObservedUnixMs);
    }

    _monotonicClock
      ..reset()
      ..start();
    _initialized = true;

    await _persistVault();

    if (attemptNetworkSync) {
      // Avvia la validazione server-side in background senza bloccare il caricamento dei dati locali
      unawaited(syncWithServer());
    }
  }

  /// Verifica il timestamp UTC reale interrogando un endpoint server ad alta affidabilità.
  /// Se ha successo, sblocca eventuali stati di manomissione e riallinea il clock monotonico.
  Future<bool> syncWithServer({
    Duration timeout = const Duration(milliseconds: 1800),
    Future<DateTime?> Function()? customFetcher,
  }) async {
    try {
      DateTime? serverUtc;
      if (customFetcher != null) {
        serverUtc = await customFetcher().timeout(timeout);
      } else {
        serverUtc = await _fetchNetworkUtc(timeout);
      }

      if (serverUtc != null) {
        final serverMs = serverUtc.toUtc().millisecondsSinceEpoch;
        _anchorUtcMs = serverMs;
        _monotonicClock
          ..reset()
          ..start();
        _lastRecordedUnixMs = serverMs;
        _maxObservedUnixMs = serverMs;
        _isNetworkVerified = true;
        _isClockTampered = false;
        await _persistVault();
        return true;
      }
    } catch (_) {
      // Offline: continua con il fallback locale crittografato + clock monotonico
    }
    return false;
  }

  Future<DateTime?> _fetchNetworkUtc(Duration timeout) async {
    final endpoints = <String>[
      'https://www.google.com',
      'https://cloudflare.com',
    ];
    for (final url in endpoints) {
      HttpClient? client;
      try {
        client = HttpClient()..connectionTimeout = timeout;
        final req = await client.headUrl(Uri.parse(url)).timeout(timeout);
        final resp = await req.close().timeout(timeout);
        final dateHeader = resp.headers.value(HttpHeaders.dateHeader);
        if (dateHeader != null && dateHeader.isNotEmpty) {
          return HttpDate.parse(dateHeader).toUtc();
        }
      } catch (_) {
        // Prova l'endpoint successivo
      } finally {
        client?.close(force: true);
      }
    }
    return null;
  }

  /// Verifica a runtime se l'utente ha alterato l'orologio di sistema mentre l'app
  /// era aperta o in background (confrontando il wall-clock con l'orologio monotonico
  /// e con l'ultimo timestamp registrato).
  bool verifyRuntimeIntegrity({DateTime? debugWallClockUtc}) {
    if (!_initialized) return !_isClockTampered;

    final wallMs =
        (debugWallClockUtc ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    final monotonicNowMs =
        _anchorUtcMs + _monotonicClock.elapsedMilliseconds;

    // 1. Controllo Rollback: l'orologio di sistema è stato portato indietro rispetto all'ultimo registrato
    if (wallMs + rollbackToleranceMs < _lastRecordedUnixMs ||
        wallMs + rollbackToleranceMs < monotonicNowMs) {
      _isClockTampered = true;
      _persistVault();
      return false;
    }

    // 2. Controllo Salto in Avanti Offline: se non siamo verificati da rete e il wall-clock
    //    è balzato in avanti di oltre 15 minuti rispetto allo scorrere reale del timer monotonico
    const maxForwardDriftMs = 15 * 60 * 1000;
    if (!_isNetworkVerified &&
        (wallMs - monotonicNowMs) > maxForwardDriftMs) {
      _isClockTampered = true;
      _persistVault();
      return false;
    }

    // Se l'orologio era bloccato per rollback e l'utente ha ripristinato la data corretta
    // (coerente con l'ultimo timestamp registrato senza salti anomali in avanti):
    if (_isClockTampered &&
        wallMs >= _lastRecordedUnixMs &&
        (wallMs - monotonicNowMs).abs() <= maxForwardDriftMs) {
      _isClockTampered = false;
    }

    // Aggiorna l'high-water mark usando il clock monotonico sicuro
    if (!_isClockTampered && monotonicNowMs > _lastRecordedUnixMs) {
      _lastRecordedUnixMs = monotonicNowMs;
      if (monotonicNowMs > _maxObservedUnixMs) {
        _maxObservedUnixMs = monotonicNowMs;
      }
      _persistVault();
    }

    return !_isClockTampered;
  }

  /// Restituisce l'orario UTC corrente calcolato tramite il timer monotonico hardware
  /// (`_anchorUtcMs + _monotonicClock.elapsedMilliseconds`), mai dipendente dal wall-clock non validato.
  DateTime nowUtc() {
    final currentMs = _anchorUtcMs + _monotonicClock.elapsedMilliseconds;
    if (!_isClockTampered && currentMs > _lastRecordedUnixMs) {
      _lastRecordedUnixMs = currentMs;
      if (currentMs > _maxObservedUnixMs) {
        _maxObservedUnixMs = currentMs;
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(currentMs, isUtc: true);
  }

  /// Calcola il tempo rimanente allo sblocco della prossima Torre Giornaliera (mezzanotte UTC)
  /// utilizzando esclusivamente il timer monotonico hardware in memoria.
  Duration getRemainingDailyTime({Duration? debugElapsedOverride}) {
    final elapsedMs = debugElapsedOverride != null
        ? debugElapsedOverride.inMilliseconds
        : _monotonicClock.elapsedMilliseconds;
    final currentUtc = DateTime.fromMillisecondsSinceEpoch(
      _anchorUtcMs + elapsedMs,
      isUtc: true,
    );
    final nextMidnightUtc = DateTime.utc(
      currentUtc.year,
      currentUtc.month,
      currentUtc.day + 1,
    );
    final diff = nextMidnightUtc.difference(currentUtc);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Formatta il tempo rimanente come `HH:MM:SS`
  String getFormattedRemainingDailyTime({Duration? debugElapsedOverride}) {
    final rem = getRemainingDailyTime(
      debugElapsedOverride: debugElapsedOverride,
    );
    final h = rem.inHours.toString().padLeft(2, '0');
    final m = (rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _persistVault() async {
    await SecureTimeVault.write(_prefs, <String, dynamic>{
      'lastUnixMs': _lastRecordedUnixMs,
      'maxUnixMs': _maxObservedUnixMs,
      'netVerified': _isNetworkVerified,
      'tampered': _isClockTampered,
    });
  }
}
