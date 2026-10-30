import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

// --- Definizioni FFI per Windows (winmm.dll) ---
typedef _PlaySoundNative = Int32 Function(
  Pointer<Uint8> pszSound,
  IntPtr hmod,
  Uint32 fdwSound,
);
typedef _PlaySoundDart = int Function(
  Pointer<Uint8> pszSound,
  int hmod,
  int fdwSound,
);

/// Sintetizzatore procedurale di effetti sonori a 44.1kHz 16-bit in memoria pre-allocata.
/// - Tutti i buffer PCM/WAV sono pre-generati e pre-caricati una sola volta in [init].
/// - Zero allocazioni di memoria o decodifiche durante il salto ([playLaunch]) o i rimbalzi.
/// - Supporta silenziamento/ducking istantaneo in pausa ([setPaused]) e rilascio memoria ([dispose]).
class NativeSoundSynth {
  static const int _sampleRate = 44100;
  static const int _sndAsync = 0x0001;
  static const int _sndNoDefault = 0x0002;
  static const int _sndMemory = 0x0004;
  static const int _flags = _sndAsync | _sndNoDefault | _sndMemory;

  static const MethodChannel _androidAudioChannel =
      MethodChannel('com.alemaccio.inktower/audio');

  _PlaySoundDart? _playSoundWin;
  bool _androidSoundPoolReady = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _isPaused = false;
  bool _musicEnabled = true;

  // Mappe argomenti pre-allocate per evitare allocazioni GC a ogni salto su MethodChannel
  final Map<String, Map<String, Object>> _playArgsPool = {};

  // Buffer PCM 16-bit pre-calcolati
  late final Int16List _aimTickPcm;
  late final Int16List _launchPcm;
  final List<Int16List> _padStickPcms = [];
  late final Int16List _wallBouncePcm;
  late final Int16List _bumperPcm;
  final List<Int16List> _sealPcms = [];
  late final Int16List _shieldPcm;
  late final Int16List _victoryPcm;
  late final Int16List _crashPcm;
  late final Int16List _zenChordPcm;

  // Buffer WAV in memoria nativa (usati su Windows PlaySoundW)
  Pointer<Uint8>? _aimTickWav;
  Pointer<Uint8>? _launchWav;
  final List<Pointer<Uint8>> _padStickWavs = [];
  Pointer<Uint8>? _wallBounceWav;
  Pointer<Uint8>? _bumperWav;
  final List<Pointer<Uint8>> _sealWavs = [];
  Pointer<Uint8>? _shieldWav;
  Pointer<Uint8>? _victoryWav;
  Pointer<Uint8>? _crashWav;
  Pointer<Uint8>? _zenChordWav;

  void init() {
    if (_initialized || _disposed) return;
    _initialized = true;

    // Pre-alloca le mappe degli argomenti MethodChannel per azzerare il GC a runtime
    const baseKeys = [
      'aimTick',
      'launch',
      'wallBounce',
      'bumper',
      'shield',
      'victory',
      'crash',
      'zenChord',
    ];
    for (final k in baseKeys) {
      _playArgsPool[k] = <String, Object>{'key': k, 'volume': 1.0};
    }
    for (int i = 0; i < 8; i++) {
      _playArgsPool['padStick_$i'] = <String, Object>{
        'key': 'padStick_$i',
        'volume': 1.0,
      };
      _playArgsPool['seal_$i'] = <String, Object>{
        'key': 'seal_$i',
        'volume': 1.0,
      };
    }

    // 1. Genera i timbri sonori ben distinti tra loro in memoria all'avvio
    _aimTickPcm = _synthSweepPcm(
      durationSec: 0.026,
      startFreq: 1120,
      endFreq: 740,
      volume: 0.56,
      triangleMix: 0.25,
    );

    _launchPcm = _synthSweepPcm(
      durationSec: 0.135,
      startFreq: 165,
      endFreq: 690,
      volume: 0.78,
      triangleMix: 0.55,
    );

    const pentatonic = [1.0, 1.122, 1.26, 1.498, 1.682, 2.0, 2.245, 2.52];
    for (final mult in pentatonic) {
      _padStickPcms.add(
        _synthArpeggioPcm(
          notesHz: [280.0 * mult, 420.0 * mult],
          noteDurationSec: 0.042,
          volume: 0.72,
        ),
      );
      _sealPcms.add(
        _synthArpeggioPcm(
          notesHz: [
            523.25 * mult * 0.75,
            659.25 * mult * 0.75,
            783.99 * mult * 0.75,
            1046.50 * mult * 0.75,
          ],
          noteDurationSec: 0.045,
          volume: 0.80,
        ),
      );
    }

    _wallBouncePcm = _synthSweepPcm(
      durationSec: 0.095,
      startFreq: 185,
      endFreq: 65,
      volume: 0.85,
      triangleMix: 0.45,
      noiseMix: 0.14,
    );

    _bumperPcm = _synthArpeggioPcm(
      notesHz: [440.0, 880.0, 659.25, 1174.66],
      noteDurationSec: 0.038,
      volume: 0.82,
    );

    _shieldPcm = _synthArpeggioPcm(
      notesHz: [880.0, 622.25, 440.0, 311.13],
      noteDurationSec: 0.048,
      volume: 0.78,
    );

    _victoryPcm = _synthArpeggioPcm(
      notesHz: [523.25, 659.25, 783.99, 987.77, 1046.50],
      noteDurationSec: 0.085,
      volume: 0.86,
    );

    _crashPcm = _synthSweepPcm(
      durationSec: 0.28,
      startFreq: 260,
      endFreq: 55,
      volume: 0.85,
      triangleMix: 0.35,
      noiseMix: 0.35,
    );

    // Accordo armonico zen morbido per feedback musicale ambientale
    _zenChordPcm = _synthArpeggioPcm(
      notesHz: [261.63, 329.63, 392.00, 523.25],
      noteDurationSec: 0.065,
      volume: 0.42,
    );

    if (Platform.isWindows) {
      try {
        final winmm = DynamicLibrary.open('winmm.dll');
        _playSoundWin = winmm
            .lookupFunction<_PlaySoundNative, _PlaySoundDart>('PlaySoundW');

        _aimTickWav = _allocWav(_encodeWav(_aimTickPcm));
        _launchWav = _allocWav(_encodeWav(_launchPcm));
        for (final pcm in _padStickPcms) {
          _padStickWavs.add(_allocWav(_encodeWav(pcm)));
        }
        for (final pcm in _sealPcms) {
          _sealWavs.add(_allocWav(_encodeWav(pcm)));
        }
        _wallBounceWav = _allocWav(_encodeWav(_wallBouncePcm));
        _bumperWav = _allocWav(_encodeWav(_bumperPcm));
        _shieldWav = _allocWav(_encodeWav(_shieldPcm));
        _victoryWav = _allocWav(_encodeWav(_victoryPcm));
        _crashWav = _allocWav(_encodeWav(_crashPcm));
        _zenChordWav = _allocWav(_encodeWav(_zenChordPcm));
      } catch (_) {
        _playSoundWin = null;
      }
    } else if (Platform.isAndroid) {
      _initAndroidAudio();
    }
  }

  Future<void> _initAndroidAudio() async {
    try {
      final wavMap = <String, Uint8List>{
        'aimTick': _encodeWav(_aimTickPcm),
        'launch': _encodeWav(_launchPcm),
        'wallBounce': _encodeWav(_wallBouncePcm),
        'bumper': _encodeWav(_bumperPcm),
        'shield': _encodeWav(_shieldPcm),
        'victory': _encodeWav(_victoryPcm),
        'crash': _encodeWav(_crashPcm),
        'zenChord': _encodeWav(_zenChordPcm),
      };
      for (int i = 0; i < _padStickPcms.length; i++) {
        wavMap['padStick_$i'] = _encodeWav(_padStickPcms[i]);
      }
      for (int i = 0; i < _sealPcms.length; i++) {
        wavMap['seal_$i'] = _encodeWav(_sealPcms[i]);
      }

      final ok =
          await _androidAudioChannel.invokeMethod<bool>('initWavs', wavMap);
      if (ok == true) {
        _androidSoundPoolReady = true;
      }
    } catch (_) {
      _androidSoundPoolReady = false;
    }
  }

  void setPaused(bool paused) {
    _isPaused = paused;
    if (paused) {
      if (Platform.isWindows && _playSoundWin != null) {
        _playSoundWin!(nullptr, 0, 0);
      } else if (Platform.isAndroid && _androidSoundPoolReady) {
        unawaited(_androidAudioChannel.invokeMethod<void>('setPaused', true));
      }
    } else {
      if (Platform.isAndroid && _androidSoundPoolReady) {
        unawaited(_androidAudioChannel.invokeMethod<void>('setPaused', false));
      }
    }
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (_musicEnabled && !_isPaused) {
      _play('zenChord', _zenChordPcm, _zenChordWav, allowWhenPaused: true);
    }
  }

  void stopAll() {
    if (Platform.isWindows && _playSoundWin != null) {
      _playSoundWin!(nullptr, 0, 0);
    } else if (Platform.isAndroid && _androidSoundPoolReady) {
      unawaited(_androidAudioChannel.invokeMethod<void>('stopAll'));
    }
  }

  void _play(
    String key,
    Int16List pcm,
    Pointer<Uint8>? winWav, {
    bool allowWhenPaused = false,
  }) {
    if (_disposed) return;
    if (_isPaused && !allowWhenPaused) return;
    if (!_initialized) init();

    if (Platform.isWindows && _playSoundWin != null && winWav != null) {
      _playSoundWin!(winWav, 0, _flags);
    } else if (Platform.isAndroid && _androidSoundPoolReady) {
      final args = _playArgsPool[key];
      if (args != null) {
        args['volume'] = _isPaused ? 0.25 : 1.0;
        unawaited(_androidAudioChannel.invokeMethod<void>('play', args));
      }
    }
  }

  void playAimTick() =>
      _play('aimTick', _aimTickPcm, _aimTickWav, allowWhenPaused: true);
  void playLaunch() => _play('launch', _launchPcm, _launchWav);

  void playPadStick(int combo) {
    if (!_initialized) init();
    final idx = combo.clamp(0, _padStickPcms.length - 1);
    final wav = idx < _padStickWavs.length ? _padStickWavs[idx] : null;
    _play('padStick_$idx', _padStickPcms[idx], wav);
  }

  void playWallBounce() => _play('wallBounce', _wallBouncePcm, _wallBounceWav);
  void playBumper() => _play('bumper', _bumperPcm, _bumperWav);

  void playSeal(int combo) {
    if (!_initialized) init();
    final idx = combo.clamp(0, _sealPcms.length - 1);
    final wav = idx < _sealWavs.length ? _sealWavs[idx] : null;
    _play('seal_$idx', _sealPcms[idx], wav);
  }

  void playShieldBreak() => _play('shield', _shieldPcm, _shieldWav);
  void playVictory() => _play('victory', _victoryPcm, _victoryWav);
  void playCrash() => _play('crash', _crashPcm, _crashWav);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopAll();
    if (Platform.isWindows) {
      _freePtr(_aimTickWav);
      _freePtr(_launchWav);
      _freePtr(_wallBounceWav);
      _freePtr(_bumperWav);
      _freePtr(_shieldWav);
      _freePtr(_victoryWav);
      _freePtr(_crashWav);
      _freePtr(_zenChordWav);
      for (final p in _padStickWavs) {
        _freePtr(p);
      }
      for (final p in _sealWavs) {
        _freePtr(p);
      }
      _padStickWavs.clear();
      _sealWavs.clear();
    }
  }

  void _freePtr(Pointer<Uint8>? ptr) {
    if (ptr != null && ptr != nullptr) {
      try {
        malloc.free(ptr);
      } catch (_) {}
    }
  }

  Pointer<Uint8> _allocWav(Uint8List wavBytes) {
    final ptr = malloc.allocate<Uint8>(wavBytes.length);
    ptr.asTypedList(wavBytes.length).setAll(0, wavBytes);
    return ptr;
  }

  Int16List _synthSweepPcm({
    required double durationSec,
    required double startFreq,
    required double endFreq,
    required double volume,
    double noiseMix = 0.0,
    double triangleMix = 0.0,
  }) {
    final numSamples = (_sampleRate * durationSec).round();
    final pcm = Int16List(numSamples);
    final rng = Random(42);
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = startFreq + (endFreq - startFreq) * t;
      phase += (2 * pi * freq) / _sampleRate;

      final attack = (i / (_sampleRate * 0.004)).clamp(0.0, 1.0);
      final decay = pow(1.0 - t, 1.35).toDouble();
      final env = attack * decay;

      double sample = sin(phase);
      if (triangleMix > 0) {
        final tri = (2.0 / pi) * asin(sin(phase));
        sample = sample * (1.0 - triangleMix) + tri * triangleMix;
      }
      if (noiseMix > 0) {
        final noise = rng.nextDouble() * 2.0 - 1.0;
        sample = sample * (1.0 - noiseMix) + noise * noiseMix;
      }

      pcm[i] = (sample * env * volume * 32767.0).round().clamp(-32768, 32767);
    }
    return pcm;
  }

  Int16List _synthArpeggioPcm({
    required List<double> notesHz,
    required double noteDurationSec,
    required double volume,
  }) {
    final samplesPerNote = (_sampleRate * noteDurationSec).round();
    final totalSamples = samplesPerNote * notesHz.length;
    final pcm = Int16List(totalSamples);
    double phase = 0.0;

    for (int n = 0; n < notesHz.length; n++) {
      final freq = notesHz[n];
      for (int i = 0; i < samplesPerNote; i++) {
        final t = i / samplesPerNote;
        phase += (2 * pi * freq) / _sampleRate;
        final attack = (i / (_sampleRate * 0.003)).clamp(0.0, 1.0);
        final decay = pow(1.0 - t * 0.85, 1.25).toDouble();
        final sample = sin(phase) * 0.72 + sin(phase * 2.0) * 0.28;
        pcm[n * samplesPerNote + i] =
            (sample * attack * decay * volume * 32767.0)
                .round()
                .clamp(-32768, 32767);
      }
    }
    return pcm;
  }

  Uint8List _encodeWav(Int16List pcmSamples) {
    final dataSize = pcmSamples.length * 2;
    final fileSize = 44 + dataSize;
    final bytes = ByteData(fileSize);

    bytes.setUint8(0, 0x52); // 'R'
    bytes.setUint8(1, 0x49); // 'I'
    bytes.setUint8(2, 0x46); // 'F'
    bytes.setUint8(3, 0x46); // 'F'
    bytes.setUint32(4, fileSize - 8, Endian.little);
    bytes.setUint8(8, 0x57); // 'W'
    bytes.setUint8(9, 0x41); // 'A'
    bytes.setUint8(10, 0x56); // 'V'
    bytes.setUint8(11, 0x45); // 'E'

    bytes.setUint8(12, 0x66); // 'f'
    bytes.setUint8(13, 0x6D); // 'm'
    bytes.setUint8(14, 0x74); // 't'
    bytes.setUint8(15, 0x20); // ' '
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);

    bytes.setUint8(36, 0x64); // 'd'
    bytes.setUint8(37, 0x61); // 'a'
    bytes.setUint8(38, 0x74); // 't'
    bytes.setUint8(39, 0x61); // 'a'
    bytes.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < pcmSamples.length; i++) {
      bytes.setInt16(44 + i * 2, pcmSamples[i], Endian.little);
    }

    return bytes.buffer.asUint8List();
  }
}
