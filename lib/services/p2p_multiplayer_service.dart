import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

typedef P2PIncomingInvite = P2PChallengeInvite;

/// Formato della sfida Multiplayer P2P scelto da chi lancia l'invito 1-Tap.
enum P2PDuelFormat {
  race100m,
  infiniteSurvival,
}

/// Rappresenta un invito diretto P2P ricevuto da un amico nella propria Lista Amici.
class P2PChallengeInvite {
  final String challengerCode;
  final String challengerName;
  final String challengerAvatar;
  final String challengerSkinId;
  final P2PDuelFormat format;
  final int towerSeed;

  const P2PChallengeInvite({
    required this.challengerCode,
    required this.challengerName,
    required this.challengerAvatar,
    required this.challengerSkinId,
    required this.format,
    required this.towerSeed,
  });

  String get senderName => challengerName;
}

/// Stato mutabile pre-allocato dell'avversario P2P (zero allocazioni nel loop a 60/120 FPS).
class P2POpponentState {
  String code = 'INK-9042';
  String name = 'Kenji_Zen';
  String avatarEmoji = '🥷';
  String skinId = 'shinobi_star';

  double x = 0.0;
  double y = 0.0;
  double vx = 0.0;
  double vy = 0.0;
  double targetX = 0.0;
  double targetY = 0.0;
  double meters = 0.0;
  double maxMeters = 0.0;
  int bounces = 0;

  bool isStuck = true;
  bool hasShield = false;
  bool isShadowPhase = false;
  bool isDead = false;
  bool hasReachedGoal = false;
  bool isRemoteSocketPeer = false;

  bool get hasWon => hasReachedGoal;

  void resetForMatch({
    required String friendCode,
    required String friendName,
    required String friendAvatar,
    required String friendSkinId,
  }) {
    code = friendCode;
    name = friendName;
    avatarEmoji = friendAvatar;
    skinId = friendSkinId;
    x = 0.0;
    y = 0.0;
    vx = 0.0;
    vy = 0.0;
    targetX = 0.0;
    targetY = 0.0;
    meters = 0.0;
    maxMeters = 0.0;
    bounces = 0;
    isStuck = true;
    hasShield = false;
    isShadowPhase = false;
    isDead = false;
    hasReachedGoal = false;
    isRemoteSocketPeer = false;
  }
}

/// Servizio leggero ed ultra-ottimizzato per il Multiplayer P2P e la Sezione Amici 1-Tap:
/// - Scoperta e sincronizzazione automatica su rete locale (UDP 45888) a zero configurazione
/// - Invito diretto 1-Tap verso qualsiasi amico salvato senza creare stanze manualmente
/// - Throttling dei pacchetti a ~18Hz per zero impatto su frame-rate (120 FPS) e batteria
class P2PMultiplayerService {
  static const int _p2pPort = 45888;
  final StorageService storage;

  RawDatagramSocket? _udpSocket;
  InternetAddress? _lastPeerAddress;
  int _lastPeerPort = _p2pPort;
  double _networkSyncAccumulator = 0.0;

  final P2POpponentState opponent = P2POpponentState();
  P2PDuelFormat activeDuelFormat = P2PDuelFormat.race100m;
  int activeMatchSeed = 0;

  /// Notifier per mostrare il banner popup istantaneo quando un amico ti sfida
  final ValueNotifier<P2PChallengeInvite?> incomingInviteNotifier =
      ValueNotifier<P2PChallengeInvite?>(null);

  /// Notifier leggero per la quota in metri dell'avversario nell'HUD (aggiornato solo su variazioni >= 0.1m)
  final ValueNotifier<double> opponentMetersNotifier =
      ValueNotifier<double>(0.0);

  /// Notifier che segnala se l'avversario è morto o ha vinto
  final ValueNotifier<bool> opponentDeadNotifier = ValueNotifier<bool>(false);

  /// Callback invocato quando l'avversario usa l'abilità di disturbo "Spruzzo d'Inchiostro"
  void Function()? onIncomingSabotage;

  P2PMultiplayerService({required this.storage});

  /// Avvia in modo non-bloccante e sicuro il socket P2P per scoprire amici sulla rete
  Future<void> initNetworkSocket() async {
    if (_udpSocket != null) return;
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _p2pPort,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;
      _udpSocket = socket;
      socket.listen(
        _onSocketEvent,
        onError: (_) {},
        cancelOnError: false,
      );
      _sendPacket(<String, dynamic>{
        't': 'HELLO',
        'code': storage.myFriendCode,
        'name': storage.playerName,
        'skin': storage.selectedBallSkinId,
      });
    } catch (_) {
      // Fallback silenzioso su piattaforme/sandbox senza permessi UDP raw
    }
  }

  void _onSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _udpSocket?.receive();
    if (dg == null) return;
    try {
      final msg = utf8.decode(dg.data);
      final map = jsonDecode(msg);
      if (map is! Map<String, dynamic>) return;

      final senderCode = (map['code'] as String?) ?? '';
      if (senderCode.isEmpty || senderCode == storage.myFriendCode) return;

      _lastPeerAddress = dg.address;
      _lastPeerPort = dg.port;

      final type = map['t'] as String?;
      if (type == 'HELLO') {
        storage.addFriend(
          code: senderCode,
          name: (map['name'] as String?) ?? 'Climber',
          skinId: (map['skin'] as String?) ?? 'classic_ink',
        );
      } else if (type == 'INVITE') {
        final targetCode = (map['target'] as String?) ?? '';
        if (targetCode.isEmpty ||
            targetCode.toUpperCase() == storage.myFriendCode.toUpperCase()) {
          final fmtStr = (map['fmt'] as String?) ?? 'race100m';
          incomingInviteNotifier.value = P2PChallengeInvite(
            challengerCode: senderCode,
            challengerName: (map['name'] as String?) ?? 'Friend',
            challengerAvatar: (map['avatar'] as String?) ?? '🥷',
            challengerSkinId: (map['skin'] as String?) ?? 'shinobi_star',
            format: fmtStr == 'infiniteSurvival'
                ? P2PDuelFormat.infiniteSurvival
                : P2PDuelFormat.race100m,
            towerSeed: (map['seed'] as int?) ?? 421984,
          );
        }
      } else if (type == 'STATE') {
        opponent.isRemoteSocketPeer = true;
        opponent.targetX = (map['x'] as num?)?.toDouble() ?? opponent.targetX;
        opponent.targetY = (map['y'] as num?)?.toDouble() ?? opponent.targetY;
        opponent.vx = (map['vx'] as num?)?.toDouble() ?? opponent.vx;
        opponent.vy = (map['vy'] as num?)?.toDouble() ?? opponent.vy;
        final m = (map['m'] as num?)?.toDouble() ?? opponent.meters;
        opponent.meters = m;
        if (m > opponent.maxMeters) {
          opponent.maxMeters = m;
          if ((opponent.maxMeters - opponentMetersNotifier.value).abs() >= 0.1) {
            opponentMetersNotifier.value = opponent.maxMeters;
          }
        }
        opponent.isStuck = (map['st'] as bool?) ?? false;
        opponent.hasShield = (map['sh'] as bool?) ?? false;
        opponent.isShadowPhase = (map['sp'] as bool?) ?? false;
        final deadNow = (map['dead'] as bool?) ?? false;
        if (deadNow && !opponent.isDead) {
          opponent.isDead = true;
          opponentDeadNotifier.value = true;
        }
        opponent.hasReachedGoal = (map['won'] as bool?) ?? false;
      } else if (type == 'SABOTAGE') {
        onIncomingSabotage?.call();
      }
    } catch (_) {}
  }

  void _sendPacket(Map<String, dynamic> payload) {
    final socket = _udpSocket;
    if (socket == null) return;
    try {
      final bytes = utf8.encode(jsonEncode(payload));
      if (_lastPeerAddress != null) {
        socket.send(bytes, _lastPeerAddress!, _lastPeerPort);
      }
      socket.send(
        bytes,
        InternetAddress('255.255.255.255'),
        _p2pPort,
      );
    } catch (_) {}
  }

  /// Lancia una sfida 1-Tap a un amico della lista senza dover creare stanze manuali
  void prepareDirectChallenge({
    required FriendRecord friend,
    required P2PDuelFormat format,
    int? customSeed,
  }) {
    activeDuelFormat = format;
    activeMatchSeed = customSeed ??
        (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);
    opponent.resetForMatch(
      friendCode: friend.code,
      friendName: friend.name,
      friendAvatar: friend.avatarEmoji,
      friendSkinId: friend.skinId,
    );
    opponentMetersNotifier.value = 0.0;
    opponentDeadNotifier.value = false;

    _sendPacket(<String, dynamic>{
      't': 'INVITE',
      'code': storage.myFriendCode,
      'target': friend.code,
      'name': storage.playerName,
      'skin': storage.selectedBallSkinId,
      'fmt': format.name,
      'seed': activeMatchSeed,
    });
  }

  /// Simula la ricezione di un invito in tempo reale da parte di un amico della lista
  void simulateIncomingInviteFromFriend({
    FriendRecord? friend,
    P2PDuelFormat format = P2PDuelFormat.race100m,
  }) {
    final chosen = friend ??
        (storage.friendsList.isNotEmpty
            ? storage.friendsList.first
            : const FriendRecord(
                code: 'INK-9042',
                name: 'Kenji_Zen',
                avatarEmoji: '🥷',
                skinId: 'shinobi_star',
              ));
    incomingInviteNotifier.value = P2PChallengeInvite(
      challengerCode: chosen.code,
      challengerName: chosen.name,
      challengerAvatar: chosen.avatarEmoji,
      challengerSkinId: chosen.skinId,
      format: format,
      towerSeed: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
    );
  }

  void simulateIncomingInviteFrom(
    FriendRecord friend, {
    P2PDuelFormat format = P2PDuelFormat.race100m,
  }) => simulateIncomingInviteFromFriend(friend: friend, format: format);

  void broadcastPlayerState({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double meters,
    required bool isStuck,
    required bool hasShield,
    required bool isShadowPhase,
    required bool isDead,
    required bool hasWon,
    bool force = false,
  }) {
    updateLocalPlayerSync(
      dt: force ? 1.0 : 0.016,
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      meters: meters,
      isStuck: isStuck,
      hasShield: hasShield,
      hasWon: hasWon,
      isShadowPhase: isShadowPhase,
      isDead: isDead,
    );
  }

  void declineIncomingInvite() {
    incomingInviteNotifier.value = null;
  }

  /// Invia con throttling (~18Hz) lo stato del giocatore locale all'avversario P2P
  void updateLocalPlayerSync({
    required double dt,
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double meters,
    required bool isStuck,
    required bool hasShield,
    required bool isShadowPhase,
    required bool isDead,
    required bool hasWon,
  }) {
    _networkSyncAccumulator += dt;
    if (_networkSyncAccumulator < 0.055 && !isDead && !hasWon) return;
    _networkSyncAccumulator = 0.0;

    if (_udpSocket == null) return;
    _sendPacket(<String, dynamic>{
      't': 'STATE',
      'code': storage.myFriendCode,
      'x': (x * 10).roundToDouble() / 10,
      'y': (y * 10).roundToDouble() / 10,
      'vx': vx.round(),
      'vy': vy.round(),
      'm': (meters * 10).roundToDouble() / 10,
      'st': isStuck,
      'sh': hasShield,
      'sp': isShadowPhase,
      'dead': isDead,
      'won': hasWon,
    });
  }

  /// Invia il pacchetto di disturbo "Spruzzo d'Inchiostro" all'avversario P2P
  void sendSabotageToOpponent() {
    _sendPacket(<String, dynamic>{
      't': 'SABOTAGE',
      'code': storage.myFriendCode,
    });
  }

  void dispose() {
    try {
      _udpSocket?.close();
    } catch (_) {}
    _udpSocket = null;
    incomingInviteNotifier.dispose();
    opponentMetersNotifier.dispose();
    opponentDeadNotifier.dispose();
  }
}
