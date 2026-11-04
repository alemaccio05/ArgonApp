import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../core/profile_icons.dart';
import 'storage_service.dart';

typedef P2PIncomingInvite = P2PChallengeInvite;

/// Esito dell'invio di una richiesta di amicizia tramite Codice Amico a 8 cifre.
enum FriendRequestSendStatus {
  sent,
  autoAcceptedMutual,
  alreadyFriends,
  cannotAddSelf,
  invalidCode,
}

/// Formato della sfida Multiplayer P2P scelto da chi lancia l'invito 1-Tap.
enum P2PDuelFormat {
  race100m,
  infiniteSurvival,
}

/// Stato della votazione per la Rivincita a fine partita P2P reale.
enum P2PRematchVoteStatus {
  idle,
  waitingPeerAccept,
  incomingPeerRequest,
  acceptedLaunching,
  peerDeclined,
  peerLeft,
}

/// Rappresenta un invito diretto P2P ricevuto da un amico nella propria Lista Amici.
class P2PChallengeInvite {
  final String inviteId;
  final String challengerCode;
  final String challengerName;
  final String challengerAvatar;
  final String challengerSkinId;
  final P2PDuelFormat format;
  final int towerSeed;

  const P2PChallengeInvite({
    this.inviteId = '',
    required this.challengerCode,
    required this.challengerName,
    required this.challengerAvatar,
    required this.challengerSkinId,
    required this.format,
    required this.towerSeed,
  });

  String get senderName => challengerName;
}

class _QueuedMqttMessage {
  final String topic;
  final Map<String, dynamic> payload;
  final bool retain;
  final MqttQos qos;

  const _QueuedMqttMessage({
    required this.topic,
    required this.payload,
    required this.retain,
    required this.qos,
  });
}

/// Stato mutabile pre-allocato dell'avversario P2P (zero allocazioni nel loop a 60/120 FPS).
class P2POpponentState {
  String code = 'INK-90428173';
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
  bool hasLeftMatch = false;

  bool get hasWon => hasReachedGoal;

  void resetForMatch({
    required String friendCode,
    required String friendName,
    required String friendAvatar,
    required String friendSkinId,
  }) {
    code = StorageService.normalizeFriendCode(friendCode);
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
    hasLeftMatch = false;
  }
}

/// Servizio Ibrido Globale (Cloud MQTT + Subnet UDP Locale 45888) per il Multiplayer P2P:
/// - Broker canonico unificato (`broker.emqx.io`) con auto-resubscribe, coda outbox e Last-Will Presence
/// - Discovery & sincronizzazione offline su Wi-Fi locale / Hotspot mobile tramite broadcast di sottorete + IP diretti
/// - Sincronizzazione in tempo reale Stato Online/Offline e cambio Nome/Avatar/Skin nella Lista Amici
/// - Handshake affidabile con retry (`INVITE` / `ACCEPT` / `INVITE_DECLINE` / `INVITE_CANCEL`), Pausa Condivisa QoS 1 e Rivincita a Votazione
class P2PMultiplayerService {
  static const int _p2pPort = 45888;
  static const String _canonicalCloudBroker = 'broker.emqx.io';
  static const int presenceTimeoutMs = 22000;

  final StorageService storage;

  RawDatagramSocket? _udpSocket;
  InternetAddress? _lastPeerAddress;
  int _lastPeerPort = _p2pPort;
  final Map<String, InternetAddress> _peerAddressesByCode =
      <String, InternetAddress>{};
  final Map<String, int> _peerPortsByCode = <String, int>{};
  List<InternetAddress> _cachedBroadcastAddresses = <InternetAddress>[
    InternetAddress('255.255.255.255'),
    InternetAddress('192.168.43.255'),
    InternetAddress('192.168.49.255'),
  ];
  int _lastInterfacesRefreshMs = 0;

  MqttServerClient? _mqttClient;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _mqttSub;
  bool _isConnectingMqtt = false;
  bool _networkRuntimeActive = false;
  bool _disposed = false;
  String? _subscribedRoomTopic;
  String? _lastAcceptedMatchKey;
  final List<_QueuedMqttMessage> _pendingMqttOutbox = <_QueuedMqttMessage>[];

  final Map<String, int> _peerLastSeenMs = <String, int>{};
  final Set<String> _dismissedInviteIds = <String>{};
  final Map<String, int> _lastRemotePauseSeqByPeer = <String, int>{};
  final Set<Timer> _transientTimers = <Timer>{};

  Timer? _presenceHeartbeatTimer;
  Timer? _inviteRetryTimer;
  Timer? _rematchRetryTimer;

  String _activeOutgoingInviteId = '';
  int _pauseSeq = 0;
  int _pendingRematchSeed = 0;
  int _incomingRematchSeed = 0;
  P2PDuelFormat _incomingRematchFormat = P2PDuelFormat.race100m;
  int? _lastRematchLaunchedSeed;

  double _networkSyncAccumulator = 0.0;

  final P2POpponentState opponent = P2POpponentState();
  P2PDuelFormat activeDuelFormat = P2PDuelFormat.race100m;
  int activeMatchSeed = 0;

  /// Notifier per mostrare il banner popup istantaneo (globale sopra ogni dialog) quando un amico ti sfida
  final ValueNotifier<P2PChallengeInvite?> incomingInviteNotifier =
      ValueNotifier<P2PChallengeInvite?>(null);

  /// Notifier dell'amico a cui abbiamo inviato una sfida attualmente in attesa di risposta
  final ValueNotifier<FriendRecord?> outgoingInviteFriendNotifier =
      ValueNotifier<FriendRecord?>(null);

  /// Notifier per mostrare feedback istantaneo se l'amico rifiuta l'invito (contiene il nome dell'amico)
  final ValueNotifier<String?> inviteDeclinedByNotifier =
      ValueNotifier<String?>(null);

  /// Notifier per mostrare il banner popup quando arriva una Richiesta di Amicizia da accettare
  final ValueNotifier<FriendRequestRecord?> incomingFriendRequestNotifier =
      ValueNotifier<FriendRequestRecord?>(null);

  /// Notifier incrementale per aggiornare in tempo reale la UI Lista Amici / Richieste / Nomi / Stato Online
  final ValueNotifier<int> friendsUpdatedNotifier = ValueNotifier<int>(0);

  /// Notifier leggero per la quota in metri dell'avversario nell'HUD (aggiornato solo su variazioni >= 0.1m)
  final ValueNotifier<double> opponentMetersNotifier =
      ValueNotifier<double>(0.0);

  /// Notifier che segnala se l'avversario è morto o ha vinto
  final ValueNotifier<bool> opponentDeadNotifier = ValueNotifier<bool>(false);

  /// Notifier che segnala se l'avversario ha abbandonato la partita (il fantasma scompare)
  final ValueNotifier<bool> opponentLeftNotifier = ValueNotifier<bool>(false);

  /// Notifier per lo stato della votazione di Rivincita (1/2 -> 2/2)
  final ValueNotifier<P2PRematchVoteStatus> rematchStatusNotifier =
      ValueNotifier<P2PRematchVoteStatus>(P2PRematchVoteStatus.idle);

  /// Notifier che segnala se il broker Cloud globale (4G/5G/Wi-Fi) è connesso
  final ValueNotifier<bool> cloudConnectedNotifier = ValueNotifier<bool>(false);

  /// Callback invocato quando l'avversario usa l'abilità di disturbo "Spruzzo d'Inchiostro"
  void Function()? onIncomingSabotage;

  /// Callback invocato quando l'avversario mette in pausa o riprende la partita P2P
  void Function(bool isPaused, String byPlayerName)? onIncomingPauseChanged;

  /// Callback pubblico invocato quando l'amico accetta l'invito a distanza (mantenuto per UI/test)
  void Function(String responderCode, String responderName)?
      onChallengeAcceptedByPeer;

  /// Callback globale del motore di gioco per avviare con certezza la partita lato sfidante appena arriva ACCEPT
  void Function(FriendRecord friend, P2PDuelFormat format, int agreedSeed)?
      onHandshakeLaunchMatch;

  /// Callback invocato quando il peer remoto muore o raggiunge il traguardo durante il duello
  void Function(bool reachedGoal)? onRemoteOpponentFinishedOrDied;

  /// Callback invocato quando l'avversario esce dalla partita o si disconnette definitivamente
  void Function()? onRemoteOpponentLeft;

  /// Callback invocato quando la votazione della Rivincita raggiunge il consenso 2/2
  void Function(int agreedSeed, P2PDuelFormat format)? onRematchAgreed;

  P2PMultiplayerService({required this.storage}) {
    _refreshIncomingRequestBanner();
  }

  void _refreshIncomingRequestBanner() {
    incomingFriendRequestNotifier.value =
        storage.incomingFriendRequests.isNotEmpty
            ? storage.incomingFriendRequests.first
            : null;
  }

  /// Restituisce `true` solo se l'amico ha inviato un segnale di presenza negli ultimi `presenceTimeoutMs`
  bool isFriendOnline(String friendCode) {
    final norm = StorageService.normalizeFriendCode(friendCode);
    final lastSeen = _peerLastSeenMs[norm];
    if (lastSeen == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastSeen) <= presenceTimeoutMs;
  }

  /// Topic univoco della casella d'arrivo di un giocatore (`inktower/inbox/INK-XXXXXXXX`)
  static String buildInboxTopic(String friendCode) {
    final norm = StorageService.normalizeFriendCode(friendCode);
    return 'inktower/inbox/$norm';
  }

  /// Topic di presenza real-time e Last-Will (`inktower/presence/INK-XXXXXXXX`)
  static String buildPresenceTopic(String friendCode) {
    final norm = StorageService.normalizeFriendCode(friendCode);
    return 'inktower/presence/$norm';
  }

  /// Topic retained del profilo giocatore (Nome, Avatar, Skin) (`inktower/profile/INK-XXXXXXXX`)
  static String buildProfileTopic(String friendCode) {
    final norm = StorageService.normalizeFriendCode(friendCode);
    return 'inktower/profile/$norm';
  }

  /// Topic retained per consegnare richieste di amicizia anche se il destinatario apre l'app più tardi
  static String buildFriendReqTopic(String targetCode, String senderCode) {
    final t = StorageService.normalizeFriendCode(targetCode);
    final s = StorageService.normalizeFriendCode(senderCode);
    return 'inktower/freq/$t/$s';
  }

  /// Wildcard topic per ricevere tutte le richieste di amicizia indirizzate al proprio codice
  static String buildFriendReqWildcardTopic(String myCode) {
    final m = StorageService.normalizeFriendCode(myCode);
    return 'inktower/freq/$m/+';
  }

  /// Topic retained per notificare l'accettazione/rifiuto dell'amicizia al mittente
  static String buildFriendAckTopic(String targetCode, String senderCode) {
    final t = StorageService.normalizeFriendCode(targetCode);
    final s = StorageService.normalizeFriendCode(senderCode);
    return 'inktower/fack/$t/$s';
  }

  /// Wildcard topic per ricevere tutte le conferme di amicizia indirizzate al proprio codice
  static String buildFriendAckWildcardTopic(String myCode) {
    final m = StorageService.normalizeFriendCode(myCode);
    return 'inktower/fack/$m/+';
  }

  /// Topic deterministico della stanza di duello tra due Codici Amico (`inktower/room/CODE1_CODE2`)
  static String buildRoomTopic(String codeA, String codeB) {
    final a = StorageService.normalizeFriendCode(codeA);
    final b = StorageService.normalizeFriendCode(codeB);
    final codes = <String>[a, b]..sort();
    return 'inktower/room/${codes[0]}_${codes[1]}';
  }

  /// Avvia in modo non-bloccante e sicuro sia il socket UDP locale (LAN/Hotspot offline) sia il broker Cloud MQTT
  Future<void> initNetworkSocket({bool enableCloudBroker = true}) async {
    if (_disposed || Platform.environment.containsKey('FLUTTER_TEST')) return;
    _networkRuntimeActive = true;
    await _refreshSubnetBroadcastAddresses();
    await _initLocalUdpSocket();
    _startPresenceHeartbeatTimer();
    if (enableCloudBroker) {
      unawaited(_connectCloudMqttBroker());
    }
  }

  void _scheduleDelayed(Duration delay, void Function() callback) {
    if (!_networkRuntimeActive || _disposed) return;
    late final Timer timer;
    timer = Timer(delay, () {
      _transientTimers.remove(timer);
      if (!_disposed) {
        callback();
      }
    });
    _transientTimers.add(timer);
  }

  void _startPresenceHeartbeatTimer() {
    if (!_networkRuntimeActive || _disposed) return;
    _presenceHeartbeatTimer ??= Timer.periodic(
      const Duration(seconds: 7),
      (_) {
        if (_disposed) return;
        _pruneStaleOnlineFriends();
        broadcastLivePresence(isOnline: true);
        if (_mqttClient == null ||
            _mqttClient?.connectionStatus?.state !=
                MqttConnectionState.connected) {
          unawaited(_connectCloudMqttBroker());
        }
      },
    );
  }

  void onAppLifecycleStateChanged(AppLifecycleState state) {
    if (_disposed || !_networkRuntimeActive) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      broadcastLivePresence(isOnline: false);
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_refreshSubnetBroadcastAddresses(force: true));
      unawaited(_initLocalUdpSocket());
      if (_mqttClient?.connectionStatus?.state !=
          MqttConnectionState.connected) {
        unawaited(_connectCloudMqttBroker());
      } else {
        _resubscribeAllTopics();
      }
      requestFriendsPresenceSync();
    }
  }

  Future<void> _refreshSubnetBroadcastAddresses({bool force = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && (now - _lastInterfacesRefreshMs) < 10000) return;
    _lastInterfacesRefreshMs = now;
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final discovered = <String>{
        '255.255.255.255',
        '192.168.43.255', // Android Wi-Fi Hotspot standard
        '192.168.49.255', // Android Wi-Fi Direct / P2P group
        '172.20.10.15', // iOS Personal Hotspot standard
        '172.20.10.255',
      };
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            discovered.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
          }
        }
      }
      _cachedBroadcastAddresses =
          discovered.map(InternetAddress.new).toList(growable: false);
    } catch (_) {}
  }

  Future<void> _initLocalUdpSocket() async {
    if (_udpSocket != null || _disposed) return;
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _p2pPort,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;
      _udpSocket = socket;
      socket.listen(
        _onUdpSocketEvent,
        onError: (_) {},
        cancelOnError: false,
      );
      broadcastLivePresence(isOnline: true);
    } catch (_) {
      // Fallback silenzioso su piattaforme/sandbox senza permessi UDP raw
    }
  }

  Future<void> _connectCloudMqttBroker() async {
    if (_isConnectingMqtt ||
        _disposed ||
        Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    final existing = _mqttClient;
    if (existing != null &&
        existing.connectionStatus?.state == MqttConnectionState.connected) {
      _resubscribeAllTopics();
      _flushPendingMqttOutbox();
      return;
    }
    _isConnectingMqtt = true;

    try {
      try {
        existing?.disconnect();
      } catch (_) {}

      final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
      final myAvatar =
          ProfileIconsCatalog.getById(storage.selectedProfileIconId).emoji;
      final clientId =
          'ink_${myCode.replaceAll('-', '')}_${DateTime.now().millisecondsSinceEpoch % 1000000}';
      final client =
          MqttServerClient.withPort(_canonicalCloudBroker, clientId, 1883);
      client.logging(on: false);
      client.keepAlivePeriod = 20;
      client.connectTimeoutPeriod = 6000;
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true;

      client.onConnected = () {
        if (_disposed) return;
        cloudConnectedNotifier.value = true;
        _resubscribeAllTopics();
        _flushPendingMqttOutbox();
        broadcastProfileUpdate();
        requestFriendsPresenceSync();
      };
      client.onAutoReconnect = () {
        if (_disposed) return;
        cloudConnectedNotifier.value = false;
      };
      client.onAutoReconnected = () {
        if (_disposed) return;
        cloudConnectedNotifier.value = true;
        _resubscribeAllTopics();
        _flushPendingMqttOutbox();
        broadcastProfileUpdate();
        requestFriendsPresenceSync();
      };
      client.onDisconnected = () {
        if (_disposed) return;
        cloudConnectedNotifier.value = false;
      };

      final willPayload = jsonEncode(<String, dynamic>{
        't': 'PRESENCE',
        'code': myCode,
        'online': false,
        'name': storage.playerName,
        'avatar': myAvatar,
        'skin': storage.selectedBallSkinId,
      });

      final connMess = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillTopic(buildPresenceTopic(myCode))
          .withWillMessage(willPayload)
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMess;

      await client.connect().timeout(const Duration(milliseconds: 6500));
      if (!_disposed &&
          client.connectionStatus?.state == MqttConnectionState.connected) {
        _mqttClient = client;
        cloudConnectedNotifier.value = true;
        await _mqttSub?.cancel();
        _mqttSub = client.updates?.listen(
          _onMqttMessages,
          onError: (_) {},
          cancelOnError: false,
        );
        _resubscribeAllTopics();
        _flushPendingMqttOutbox();
        broadcastProfileUpdate();
        requestFriendsPresenceSync();
      } else {
        try {
          client.disconnect();
        } catch (_) {}
      }
    } catch (_) {
      // In assenza di Internet continua il canale offline LAN/Hotspot UDP 45888
    } finally {
      _isConnectingMqtt = false;
    }
  }

  /// Forza la sottoscrizione a tutti i topic personali, degli amici e della stanza attiva
  void _resubscribeAllTopics() {
    final client = _mqttClient;
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    try {
      client.subscribe(buildInboxTopic(myCode), MqttQos.atLeastOnce);
      client.subscribe(
        buildFriendReqWildcardTopic(myCode),
        MqttQos.atLeastOnce,
      );
      client.subscribe(
        buildFriendAckWildcardTopic(myCode),
        MqttQos.atLeastOnce,
      );
      for (final f in storage.friendsList) {
        _subscribeToFriendTopics(f.code);
      }
      if (_subscribedRoomTopic != null && _subscribedRoomTopic!.isNotEmpty) {
        client.subscribe(_subscribedRoomTopic!, MqttQos.atLeastOnce);
      }
    } catch (_) {}
  }

  void _subscribeToFriendTopics(String friendCode) {
    final client = _mqttClient;
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }
    final norm = StorageService.normalizeFriendCode(friendCode);
    if (norm.isEmpty) return;
    try {
      client.subscribe(buildPresenceTopic(norm), MqttQos.atLeastOnce);
      client.subscribe(buildProfileTopic(norm), MqttQos.atLeastOnce);
    } catch (_) {}
  }

  void _subscribeToDuelRoom(String peerCode) {
    final room = buildRoomTopic(storage.myFriendCode, peerCode);
    _subscribedRoomTopic = room;
    final client = _mqttClient;
    if (client != null &&
        client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        client.subscribe(room, MqttQos.atLeastOnce);
      } catch (_) {}
    }
  }

  /// Trasmette istantaneamente il cambio di Nome, Avatar o Skin a tutti gli amici (anche offline via retained `PROFILE`)
  void broadcastProfileUpdate() {
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final myAvatar =
        ProfileIconsCatalog.getById(storage.selectedProfileIconId).emoji;
    final profilePacket = <String, dynamic>{
      't': 'PROFILE',
      'code': myCode,
      'name': storage.playerName,
      'avatar': myAvatar,
      'skin': storage.selectedBallSkinId,
    };
    _publishMqtt(
      buildProfileTopic(myCode),
      profilePacket,
      retain: true,
      qos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
    broadcastLivePresence(isOnline: true, notifyFriendsInboxes: true);
  }

  /// Trasmette lo stato live Online/Offline su MQTT e sottorete UDP locale
  void broadcastLivePresence({
    required bool isOnline,
    bool notifyFriendsInboxes = false,
  }) {
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final myAvatar =
        ProfileIconsCatalog.getById(storage.selectedProfileIconId).emoji;
    final packet = <String, dynamic>{
      't': 'PRESENCE',
      'code': myCode,
      'online': isOnline,
      'name': storage.playerName,
      'avatar': myAvatar,
      'skin': storage.selectedBallSkinId,
    };
    _sendUdpPacket(packet);
    _publishMqtt(
      buildPresenceTopic(myCode),
      packet,
      qos: MqttQos.atMostOnce,
    );
    if (notifyFriendsInboxes) {
      for (final f in storage.friendsList) {
        _publishMqtt(
          buildInboxTopic(f.code),
          packet,
          qos: MqttQos.atMostOnce,
        );
      }
    }
  }

  /// Richiede attivamente stato online reale e profilo aggiornato a tutti gli amici salvati
  void requestFriendsPresenceSync() {
    _pruneStaleOnlineFriends();
    unawaited(_refreshSubnetBroadcastAddresses());
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final myAvatar =
        ProfileIconsCatalog.getById(storage.selectedProfileIconId).emoji;
    final pingPacket = <String, dynamic>{
      't': 'PING',
      'code': myCode,
      'name': storage.playerName,
      'avatar': myAvatar,
      'skin': storage.selectedBallSkinId,
    };
    _sendUdpPacket(pingPacket);
    for (final f in storage.friendsList) {
      _subscribeToFriendTopics(f.code);
      _publishMqtt(
        buildInboxTopic(f.code),
        pingPacket,
        qos: MqttQos.atMostOnce,
      );
    }
    broadcastLivePresence(isOnline: true);
  }

  void _sendPresenceReplyToPeer(String peerCode) {
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final myAvatar =
        ProfileIconsCatalog.getById(storage.selectedProfileIconId).emoji;
    final reply = <String, dynamic>{
      't': 'PRESENCE',
      'code': myCode,
      'target': StorageService.normalizeFriendCode(peerCode),
      'online': true,
      'name': storage.playerName,
      'avatar': myAvatar,
      'skin': storage.selectedBallSkinId,
    };
    _sendUdpPacket(reply, targetCode: peerCode);
    _publishMqtt(
      buildInboxTopic(peerCode),
      reply,
      qos: MqttQos.atMostOnce,
    );
  }

  void _markPeerSeenOnline(
    String peerCode, {
    String? name,
    String? avatar,
    String? skin,
  }) {
    final norm = StorageService.normalizeFriendCode(peerCode);
    if (norm.isEmpty) return;
    _peerLastSeenMs[norm] = DateTime.now().millisecondsSinceEpoch;

    if (opponent.code.toUpperCase() == norm) {
      if (name != null && name.trim().isNotEmpty) {
        opponent.name = name.trim();
      }
      if (avatar != null && avatar.trim().isNotEmpty) {
        opponent.avatarEmoji = avatar.trim();
      }
      if (skin != null && skin.trim().isNotEmpty) {
        opponent.skinId = skin.trim();
      }
    }

    unawaited(
      storage
          .syncFriendProfile(
        code: norm,
        name: name,
        avatarEmoji: avatar,
        skinId: skin,
        isOnline: true,
      )
          .then((changed) {
        if (changed && !_disposed) {
          friendsUpdatedNotifier.value += 1;
        }
      }),
    );
  }

  void _markPeerOffline(
    String peerCode, {
    String? name,
    String? avatar,
    String? skin,
  }) {
    final norm = StorageService.normalizeFriendCode(peerCode);
    if (norm.isEmpty) return;
    _peerLastSeenMs.remove(norm);
    unawaited(
      storage
          .syncFriendProfile(
        code: norm,
        name: name,
        avatarEmoji: avatar,
        skinId: skin,
        isOnline: false,
      )
          .then((changed) {
        if (changed && !_disposed) {
          friendsUpdatedNotifier.value += 1;
        }
      }),
    );
  }

  void _syncPeerProfileMetadataOnly(
    String peerCode, {
    String? name,
    String? avatar,
    String? skin,
  }) {
    final norm = StorageService.normalizeFriendCode(peerCode);
    if (norm.isEmpty) return;
    if (opponent.code.toUpperCase() == norm) {
      if (name != null && name.trim().isNotEmpty) {
        opponent.name = name.trim();
      }
      if (avatar != null && avatar.trim().isNotEmpty) {
        opponent.avatarEmoji = avatar.trim();
      }
      if (skin != null && skin.trim().isNotEmpty) {
        opponent.skinId = skin.trim();
      }
    }
    unawaited(
      storage
          .syncFriendProfile(
        code: norm,
        name: name,
        avatarEmoji: avatar,
        skinId: skin,
      )
          .then((changed) {
        if (changed && !_disposed) {
          friendsUpdatedNotifier.value += 1;
        }
      }),
    );
  }

  void _pruneStaleOnlineFriends() {
    final now = DateTime.now().millisecondsSinceEpoch;
    bool anyChanged = false;
    for (var i = 0; i < storage.friendsList.length; i++) {
      final f = storage.friendsList[i];
      final norm = StorageService.normalizeFriendCode(f.code);
      final lastSeen = _peerLastSeenMs[norm];
      final onlineNow =
          lastSeen != null && (now - lastSeen) <= presenceTimeoutMs;
      if (f.isOnline != onlineNow) {
        if (!onlineNow) {
          _peerLastSeenMs.remove(norm);
        }
        storage.friendsList[i] = f.copyWith(isOnline: onlineNow);
        anyChanged = true;
      }
    }
    if (anyChanged && !_disposed) {
      friendsUpdatedNotifier.value += 1;
    }
  }

  void _onMqttMessages(List<MqttReceivedMessage<MqttMessage?>> events) {
    for (final event in events) {
      final msg = event.payload;
      if (msg is! MqttPublishMessage) continue;
      try {
        final payloadStr =
            MqttPublishPayload.bytesToStringAsString(msg.payload.message);
        if (payloadStr.trim().isEmpty) continue;
        processIncomingJsonPayload(
          payloadStr,
          isRetainedMqtt: msg.header?.retain ?? false,
        );
      } catch (_) {}
    }
  }

  void _onUdpSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    var dg = _udpSocket?.receive();
    while (dg != null) {
      try {
        final msg = utf8.decode(dg.data);
        processIncomingJsonPayload(
          msg,
          udpAddress: dg.address,
          udpPort: dg.port,
        );
      } catch (_) {}
      dg = _udpSocket?.receive();
    }
  }

  /// Invia una Richiesta di Amicizia al Codice Amico a 8 cifre inserito:
  /// l'amicizia diventa effettiva solo dopo che il destinatario la accetta.
  Future<FriendRequestSendStatus> sendFriendRequest(
      String rawTargetCode) async {
    final trimmed = rawTargetCode.trim();
    if (trimmed.length < 3) return FriendRequestSendStatus.invalidCode;
    final targetCode = StorageService.normalizeFriendCode(trimmed);
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    if (targetCode == myCode) return FriendRequestSendStatus.cannotAddSelf;
    if (storage.isAlreadyFriend(targetCode)) {
      return FriendRequestSendStatus.alreadyFriends;
    }

    final existingIdx = storage.incomingFriendRequests
        .indexWhere((r) => r.code.toUpperCase() == targetCode);
    if (existingIdx >= 0) {
      await acceptFriendRequest(storage.incomingFriendRequests[existingIdx]);
      return FriendRequestSendStatus.autoAcceptedMutual;
    }

    await storage.addOutgoingFriendRequest(code: targetCode);
    final myAvatar =
        ProfileIconsCatalog.getById(storage.selectedProfileIconId).emoji;
    final packet = <String, dynamic>{
      't': 'FRIEND_REQ',
      'code': myCode,
      'target': targetCode,
      'name': storage.playerName,
      'avatar': myAvatar,
      'skin': storage.selectedBallSkinId,
    };

    _sendUdpPacket(packet, targetCode: targetCode);
    _publishMqtt(
      buildInboxTopic(targetCode),
      packet,
      qos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
    _publishMqtt(
      buildFriendReqTopic(targetCode, myCode),
      packet,
      retain: true,
      qos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
    friendsUpdatedNotifier.value += 1;
    return FriendRequestSendStatus.sent;
  }

  /// Accetta una Richiesta di Amicizia ricevuta e notifica il mittente (online o via retained MQTT).
  Future<void> acceptFriendRequest(FriendRequestRecord req) async {
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final peerCode = StorageService.normalizeFriendCode(req.code);
    await storage.removeIncomingFriendRequest(peerCode);
    await storage.removeOutgoingFriendRequest(peerCode);
    await storage.addFriend(
      code: peerCode,
      name: req.name,
      avatarEmoji: req.avatarEmoji,
      skinId: req.skinId,
      isOnline: isFriendOnline(peerCode),
    );
    _subscribeToFriendTopics(peerCode);

    _clearRetainedMqttTopic(buildFriendReqTopic(myCode, peerCode));
    final myAvatar =
        ProfileIconsCatalog.getById(storage.selectedProfileIconId).emoji;
    final ackPacket = <String, dynamic>{
      't': 'FRIEND_ACCEPT',
      'code': myCode,
      'target': peerCode,
      'name': storage.playerName,
      'avatar': myAvatar,
      'skin': storage.selectedBallSkinId,
    };

    _sendUdpPacket(ackPacket, targetCode: peerCode);
    _publishMqtt(
      buildInboxTopic(peerCode),
      ackPacket,
      qos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
    _publishMqtt(
      buildFriendAckTopic(peerCode, myCode),
      ackPacket,
      retain: true,
      qos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
    _sendPresenceReplyToPeer(peerCode);

    _refreshIncomingRequestBanner();
    friendsUpdatedNotifier.value += 1;
  }

  /// Rifiuta una Richiesta di Amicizia ricevuta.
  Future<void> declineFriendRequest(FriendRequestRecord req) async {
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final peerCode = StorageService.normalizeFriendCode(req.code);
    await storage.removeIncomingFriendRequest(peerCode);
    _clearRetainedMqttTopic(buildFriendReqTopic(myCode, peerCode));

    final declinePacket = <String, dynamic>{
      't': 'FRIEND_DECLINE',
      'code': myCode,
      'target': peerCode,
    };
    _sendUdpPacket(declinePacket, targetCode: peerCode);
    _publishMqtt(
      buildInboxTopic(peerCode),
      declinePacket,
      qos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
    _publishMqtt(
      buildFriendAckTopic(peerCode, myCode),
      declinePacket,
      retain: true,
      qos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );

    _refreshIncomingRequestBanner();
    friendsUpdatedNotifier.value += 1;
  }

  /// Annulla una Richiesta di Amicizia precedentemente inviata e ancora in attesa.
  Future<void> cancelOutgoingFriendRequest(String rawTargetCode) async {
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final peerCode = StorageService.normalizeFriendCode(rawTargetCode);
    await storage.removeOutgoingFriendRequest(peerCode);
    _clearRetainedMqttTopic(buildFriendReqTopic(peerCode, myCode));
    friendsUpdatedNotifier.value += 1;
  }

  /// Analizza ed esegue un pacchetto JSON P2P in ingresso (da Cloud Broker MQTT o Socket UDP locale).
  bool processIncomingJsonPayload(
    String rawJson, {
    InternetAddress? udpAddress,
    int? udpPort,
    bool isRetainedMqtt = false,
  }) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return false;
      return handleIncomingPacketMap(
        decoded,
        udpAddress: udpAddress,
        udpPort: udpPort,
        isRetainedMqtt: isRetainedMqtt,
      );
    } catch (_) {
      return false;
    }
  }

  bool handleIncomingPacketMap(
    Map<String, dynamic> map, {
    InternetAddress? udpAddress,
    int? udpPort,
    bool isRetainedMqtt = false,
  }) {
    final rawSenderCode = (map['code'] as String?) ?? '';
    if (rawSenderCode.isEmpty) return false;
    final senderCode = StorageService.normalizeFriendCode(rawSenderCode);
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    if (senderCode == myCode) return false;

    if (udpAddress != null) {
      _lastPeerAddress = udpAddress;
      _peerAddressesByCode[senderCode] = udpAddress;
    }
    if (udpPort != null) {
      _lastPeerPort = udpPort;
      _peerPortsByCode[senderCode] = udpPort;
    }

    final type = map['t'] as String?;

    if (type == 'HELLO' || type == 'PING') {
      final targetCode = (map['target'] as String?) ?? '';
      if (targetCode.isNotEmpty &&
          StorageService.normalizeFriendCode(targetCode) != myCode) {
        return false;
      }
      _markPeerSeenOnline(
        senderCode,
        name: map['name'] as String?,
        avatar: map['avatar'] as String?,
        skin: map['skin'] as String?,
      );
      if (storage.isAlreadyFriend(senderCode) || targetCode.isNotEmpty) {
        _sendPresenceReplyToPeer(senderCode);
      }
      return true;
    } else if (type == 'PRESENCE') {
      final targetCode = (map['target'] as String?) ?? '';
      if (targetCode.isNotEmpty &&
          StorageService.normalizeFriendCode(targetCode) != myCode) {
        return false;
      }
      final onlineFlag = (map['online'] as bool?) ?? true;
      if (onlineFlag && !isRetainedMqtt) {
        _markPeerSeenOnline(
          senderCode,
          name: map['name'] as String?,
          avatar: map['avatar'] as String?,
          skin: map['skin'] as String?,
        );
      } else if (!onlineFlag) {
        _markPeerOffline(
          senderCode,
          name: map['name'] as String?,
          avatar: map['avatar'] as String?,
          skin: map['skin'] as String?,
        );
        if (opponent.code.isNotEmpty &&
            senderCode == StorageService.normalizeFriendCode(opponent.code) &&
            opponent.isRemoteSocketPeer &&
            !opponent.hasLeftMatch) {
          _triggerRemoteOpponentLeftInternal();
        }
      }
      return true;
    } else if (type == 'PROFILE') {
      // Aggiorna nome/avatar/skin (anche da messaggio retained) senza segnare falsamente online!
      _syncPeerProfileMetadataOnly(
        senderCode,
        name: map['name'] as String?,
        avatar: map['avatar'] as String?,
        skin: map['skin'] as String?,
      );
      return true;
    } else if (type == 'FRIEND_REQ') {
      final targetCode = (map['target'] as String?) ?? '';
      if (targetCode.isEmpty ||
          StorageService.normalizeFriendCode(targetCode) != myCode) {
        return false;
      }
      final senderName = (map['name'] as String?) ?? 'Climber';
      final senderAvatar = (map['avatar'] as String?) ?? '🥷';
      final senderSkin = (map['skin'] as String?) ?? 'shinobi_star';
      if (!isRetainedMqtt) {
        _markPeerSeenOnline(
          senderCode,
          name: senderName,
          avatar: senderAvatar,
          skin: senderSkin,
        );
      }

      final hadOutgoing = storage.outgoingFriendRequests
          .any((r) => r.code.toUpperCase() == senderCode);
      if (storage.isAlreadyFriend(senderCode) || hadOutgoing) {
        unawaited(
          acceptFriendRequest(
            FriendRequestRecord(
              code: senderCode,
              name: senderName,
              avatarEmoji: senderAvatar,
              skinId: senderSkin,
            ),
          ),
        );
        return true;
      }

      unawaited(
        storage.addIncomingFriendRequest(
          code: senderCode,
          name: senderName,
          avatarEmoji: senderAvatar,
          skinId: senderSkin,
        ),
      );
      _refreshIncomingRequestBanner();
      friendsUpdatedNotifier.value += 1;
      return true;
    } else if (type == 'FRIEND_ACCEPT') {
      final targetCode = (map['target'] as String?) ?? '';
      if (targetCode.isEmpty ||
          StorageService.normalizeFriendCode(targetCode) != myCode) {
        return false;
      }
      final acceptorName = (map['name'] as String?) ?? 'Friend';
      final acceptorAvatar = (map['avatar'] as String?) ?? '🥷';
      final acceptorSkin = (map['skin'] as String?) ?? 'shinobi_star';
      if (!isRetainedMqtt) {
        _markPeerSeenOnline(
          senderCode,
          name: acceptorName,
          avatar: acceptorAvatar,
          skin: acceptorSkin,
        );
      }

      _clearRetainedMqttTopic(buildFriendAckTopic(myCode, senderCode));
      unawaited(storage.removeOutgoingFriendRequest(senderCode));
      unawaited(storage.removeIncomingFriendRequest(senderCode));
      unawaited(
        storage
            .addFriend(
          code: senderCode,
          name: acceptorName,
          avatarEmoji: acceptorAvatar,
          skinId: acceptorSkin,
          isOnline: !isRetainedMqtt || isFriendOnline(senderCode),
        )
            .then((_) {
          _subscribeToFriendTopics(senderCode);
          if (_networkRuntimeActive) {
            final myAvatar = ProfileIconsCatalog.getById(
              storage.selectedProfileIconId,
            ).emoji;
            final ping = <String, dynamic>{
              't': 'PING',
              'code': myCode,
              'target': senderCode,
              'name': storage.playerName,
              'avatar': myAvatar,
              'skin': storage.selectedBallSkinId,
            };
            _sendUdpPacket(ping, targetCode: senderCode);
            _publishMqtt(buildInboxTopic(senderCode), ping);
          }
          if (!_disposed) {
            friendsUpdatedNotifier.value += 1;
          }
        }),
      );
      _refreshIncomingRequestBanner();
      friendsUpdatedNotifier.value += 1;
      return true;
    } else if (type == 'FRIEND_DECLINE') {
      final targetCode = (map['target'] as String?) ?? '';
      if (targetCode.isEmpty ||
          StorageService.normalizeFriendCode(targetCode) != myCode) {
        return false;
      }
      _clearRetainedMqttTopic(buildFriendAckTopic(myCode, senderCode));
      unawaited(storage.removeOutgoingFriendRequest(senderCode));
      friendsUpdatedNotifier.value += 1;
      return true;
    } else if (type == 'INVITE') {
      final targetCode = (map['target'] as String?) ?? '';
      if (targetCode.isNotEmpty &&
          StorageService.normalizeFriendCode(targetCode) != myCode) {
        return false;
      }
      if (isRetainedMqtt) return false;

      final fmtStr = (map['fmt'] as String?) ?? 'race100m';
      final challengerName = (map['name'] as String?) ?? 'Friend';
      final challengerAvatar = (map['avatar'] as String?) ?? '🥷';
      final challengerSkin = (map['skin'] as String?) ?? 'shinobi_star';
      final seed = (map['seed'] as int?) ?? 421984;
      final inviteId =
          (map['id'] as String?) ?? '${senderCode}_$seed';

      _markPeerSeenOnline(
        senderCode,
        name: challengerName,
        avatar: challengerAvatar,
        skin: challengerSkin,
      );

      if (_dismissedInviteIds.contains(inviteId)) {
        return true;
      }
      final currentInvite = incomingInviteNotifier.value;
      if (currentInvite != null &&
          currentInvite.inviteId.isNotEmpty &&
          currentInvite.inviteId == inviteId) {
        // Retry dello stesso invito già visibile a schermo: non ricreare per evitare sfarfallio
        return true;
      }

      incomingInviteNotifier.value = P2PChallengeInvite(
        inviteId: inviteId,
        challengerCode: senderCode,
        challengerName: challengerName,
        challengerAvatar: challengerAvatar,
        challengerSkinId: challengerSkin,
        format: fmtStr == 'infiniteSurvival'
            ? P2PDuelFormat.infiniteSurvival
            : P2PDuelFormat.race100m,
        towerSeed: seed,
      );
      return true;
    } else if (type == 'INVITE_CANCEL') {
      final targetCode = (map['target'] as String?) ?? '';
      if (targetCode.isNotEmpty &&
          StorageService.normalizeFriendCode(targetCode) != myCode) {
        return false;
      }
      final currentInvite = incomingInviteNotifier.value;
      if (currentInvite != null &&
          StorageService.normalizeFriendCode(currentInvite.challengerCode) ==
              senderCode) {
        incomingInviteNotifier.value = null;
      }
      return true;
    } else if (type == 'INVITE_DECLINE') {
      final targetCode = (map['target'] as String?) ?? '';
      if (targetCode.isNotEmpty &&
          StorageService.normalizeFriendCode(targetCode) != myCode) {
        return false;
      }
      final waitingFriend = outgoingInviteFriendNotifier.value;
      if (waitingFriend != null &&
          StorageService.normalizeFriendCode(waitingFriend.code) ==
              senderCode) {
        _stopInviteRetryTimer();
        outgoingInviteFriendNotifier.value = null;
        final declinerName = (map['name'] as String?) ?? waitingFriend.name;
        inviteDeclinedByNotifier.value = declinerName;
      }
      return true;
    } else if (type == 'ACCEPT') {
      final targetCode = (map['target'] as String?) ?? '';
      if (targetCode.isNotEmpty &&
          StorageService.normalizeFriendCode(targetCode) != myCode) {
        return false;
      }
      final acceptSeed = (map['seed'] as int?) ?? activeMatchSeed;
      final acceptKey = '$senderCode:$acceptSeed';
      if (_lastAcceptedMatchKey == acceptKey) {
        return true;
      }
      _lastAcceptedMatchKey = acceptKey;
      _stopInviteRetryTimer();
      outgoingInviteFriendNotifier.value = null;

      final fmtStr = map['fmt'] as String?;
      if (fmtStr != null) {
        activeDuelFormat = fmtStr == 'infiniteSurvival'
            ? P2PDuelFormat.infiniteSurvival
            : P2PDuelFormat.race100m;
      }
      activeMatchSeed = acceptSeed;

      opponent.isRemoteSocketPeer = true;
      opponent.hasLeftMatch = false;
      opponentLeftNotifier.value = false;
      final peerName = (map['name'] as String?) ?? opponent.name;
      opponent.code = senderCode;
      opponent.name = peerName;
      if (map['avatar'] is String && (map['avatar'] as String).isNotEmpty) {
        opponent.avatarEmoji = map['avatar'] as String;
      }
      if (map['skin'] is String && (map['skin'] as String).isNotEmpty) {
        opponent.skinId = map['skin'] as String;
      }

      _markPeerSeenOnline(
        senderCode,
        name: peerName,
        avatar: opponent.avatarEmoji,
        skin: opponent.skinId,
      );

      final friendRecord = FriendRecord(
        code: senderCode,
        name: peerName,
        avatarEmoji: opponent.avatarEmoji,
        skinId: opponent.skinId,
        isOnline: true,
      );
      onChallengeAcceptedByPeer?.call(senderCode, peerName);
      onHandshakeLaunchMatch?.call(
        friendRecord,
        activeDuelFormat,
        acceptSeed,
      );
      return true;
    } else if (type == 'STATE') {
      // Se eravamo ancora in attesa di ACCEPT da questo sfidante e arriva già STATE, avvia subito!
      final waitingFriend = outgoingInviteFriendNotifier.value;
      if (waitingFriend != null &&
          StorageService.normalizeFriendCode(waitingFriend.code) ==
              senderCode) {
        final acceptKey = '$senderCode:$activeMatchSeed';
        if (_lastAcceptedMatchKey != acceptKey) {
          _lastAcceptedMatchKey = acceptKey;
          _stopInviteRetryTimer();
          outgoingInviteFriendNotifier.value = null;
          opponent.isRemoteSocketPeer = true;
          onChallengeAcceptedByPeer?.call(senderCode, waitingFriend.name);
          onHandshakeLaunchMatch?.call(
            waitingFriend,
            activeDuelFormat,
            activeMatchSeed,
          );
        }
      }

      if (opponent.code.isNotEmpty &&
          senderCode != StorageService.normalizeFriendCode(opponent.code)) {
        return false;
      }
      if (opponent.hasLeftMatch) return false;

      _peerLastSeenMs[senderCode] = DateTime.now().millisecondsSinceEpoch;
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
        onRemoteOpponentFinishedOrDied?.call(false);
      }
      final wonNow = (map['won'] as bool?) ?? false;
      if (wonNow && !opponent.hasReachedGoal) {
        opponent.hasReachedGoal = true;
        onRemoteOpponentFinishedOrDied?.call(true);
      }
      return true;
    } else if (type == 'PAUSE') {
      if (opponent.code.isNotEmpty &&
          senderCode != StorageService.normalizeFriendCode(opponent.code)) {
        return false;
      }
      final seq = map['seq'] as int?;
      if (seq != null) {
        final prevSeq = _lastRemotePauseSeqByPeer[senderCode];
        if (prevSeq != null && seq <= prevSeq) {
          return true;
        }
        _lastRemotePauseSeqByPeer[senderCode] = seq;
      }
      _peerLastSeenMs[senderCode] = DateTime.now().millisecondsSinceEpoch;
      opponent.isRemoteSocketPeer = true;
      final isPausedVal = (map['v'] as bool?) ?? false;
      final byName = (map['by'] as String?) ?? opponent.name;
      onIncomingPauseChanged?.call(isPausedVal, byName);
      return true;
    } else if (type == 'SABOTAGE') {
      if (opponent.code.isNotEmpty &&
          senderCode != StorageService.normalizeFriendCode(opponent.code)) {
        return false;
      }
      onIncomingSabotage?.call();
      return true;
    } else if (type == 'LEAVE') {
      if (opponent.code.isNotEmpty &&
          senderCode != StorageService.normalizeFriendCode(opponent.code)) {
        return false;
      }
      _triggerRemoteOpponentLeftInternal();
      return true;
    } else if (type == 'REMATCH_REQ') {
      if (opponent.code.isNotEmpty &&
          senderCode != StorageService.normalizeFriendCode(opponent.code)) {
        return false;
      }
      if (opponent.hasLeftMatch) return false;
      _peerLastSeenMs[senderCode] = DateTime.now().millisecondsSinceEpoch;
      final theirSeed = (map['seed'] as int?) ?? 777123;
      final fmtStr = (map['fmt'] as String?) ?? activeDuelFormat.name;
      final theirFmt = fmtStr == 'infiniteSurvival'
          ? P2PDuelFormat.infiniteSurvival
          : P2PDuelFormat.race100m;

      // Se entrambi i giocatori hanno cliccato "Proponi Rivincita" insieme -> 2/2 immediato con seed deterministico!
      if (rematchStatusNotifier.value ==
          P2PRematchVoteStatus.waitingPeerAccept) {
        final agreedSeed = myCode.compareTo(senderCode) < 0
            ? _pendingRematchSeed
            : theirSeed;
        _stopRematchRetryTimer();
        _sendRematchAcceptPacket(agreedSeed, activeDuelFormat);
        if (_lastRematchLaunchedSeed != agreedSeed) {
          _lastRematchLaunchedSeed = agreedSeed;
          rematchStatusNotifier.value = P2PRematchVoteStatus.acceptedLaunching;
          onRematchAgreed?.call(agreedSeed, activeDuelFormat);
        }
        return true;
      }

      _incomingRematchSeed = theirSeed;
      _incomingRematchFormat = theirFmt;
      if (rematchStatusNotifier.value !=
          P2PRematchVoteStatus.acceptedLaunching) {
        rematchStatusNotifier.value = P2PRematchVoteStatus.incomingPeerRequest;
      }
      return true;
    } else if (type == 'REMATCH_ACCEPT') {
      if (opponent.code.isNotEmpty &&
          senderCode != StorageService.normalizeFriendCode(opponent.code)) {
        return false;
      }
      _stopRematchRetryTimer();
      final agreedSeed = (map['seed'] as int?) ?? _pendingRematchSeed;
      final fmtStr = (map['fmt'] as String?) ?? activeDuelFormat.name;
      final agreedFmt = fmtStr == 'infiniteSurvival'
          ? P2PDuelFormat.infiniteSurvival
          : P2PDuelFormat.race100m;
      if (_lastRematchLaunchedSeed == agreedSeed) {
        return true;
      }
      _lastRematchLaunchedSeed = agreedSeed;
      rematchStatusNotifier.value = P2PRematchVoteStatus.acceptedLaunching;
      onRematchAgreed?.call(agreedSeed, agreedFmt);
      return true;
    } else if (type == 'REMATCH_DECLINE') {
      if (opponent.code.isNotEmpty &&
          senderCode != StorageService.normalizeFriendCode(opponent.code)) {
        return false;
      }
      _stopRematchRetryTimer();
      rematchStatusNotifier.value = P2PRematchVoteStatus.peerDeclined;
      return true;
    }
    return false;
  }

  void _triggerRemoteOpponentLeftInternal() {
    if (opponent.hasLeftMatch) return;
    opponent.hasLeftMatch = true;
    opponentLeftNotifier.value = true;
    _stopRematchRetryTimer();
    rematchStatusNotifier.value = P2PRematchVoteStatus.peerLeft;
    onRemoteOpponentLeft?.call();
  }

  void _flushPendingMqttOutbox() {
    final client = _mqttClient;
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected ||
        _pendingMqttOutbox.isEmpty) {
      return;
    }
    final copy = List<_QueuedMqttMessage>.from(_pendingMqttOutbox);
    _pendingMqttOutbox.clear();
    for (final item in copy) {
      _publishMqtt(
        item.topic,
        item.payload,
        retain: item.retain,
        qos: item.qos,
      );
    }
  }

  void _publishMqtt(
    String topic,
    Map<String, dynamic> payload, {
    bool retain = false,
    MqttQos qos = MqttQos.atMostOnce,
    bool queueIfOffline = false,
  }) {
    final client = _mqttClient;
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      if (queueIfOffline && _networkRuntimeActive && !_disposed) {
        if (_pendingMqttOutbox.length >= 32) {
          _pendingMqttOutbox.removeAt(0);
        }
        _pendingMqttOutbox.add(
          _QueuedMqttMessage(
            topic: topic,
            payload: payload,
            retain: retain,
            qos: qos,
          ),
        );
        unawaited(_connectCloudMqttBroker());
      }
      return;
    }
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addUTF8String(jsonEncode(payload));
      final data = builder.payload;
      if (data != null) {
        client.publishMessage(
          topic,
          qos,
          data,
          retain: retain,
        );
      }
    } catch (_) {}
  }

  void _clearRetainedMqttTopic(String topic) {
    final client = _mqttClient;
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }
    try {
      final builder = MqttClientPayloadBuilder();
      final data = builder.payload;
      if (data != null) {
        client.publishMessage(
          topic,
          MqttQos.atLeastOnce,
          data,
          retain: true,
        );
      }
    } catch (_) {}
  }

  void _sendUdpPacket(Map<String, dynamic> payload, {String? targetCode}) {
    final socket = _udpSocket;
    if (socket == null) return;
    List<int> bytes;
    try {
      bytes = utf8.encode(jsonEncode(payload));
    } catch (_) {
      return;
    }

    if (targetCode != null && targetCode.isNotEmpty) {
      final norm = StorageService.normalizeFriendCode(targetCode);
      final peerAddr = _peerAddressesByCode[norm];
      final peerPort = _peerPortsByCode[norm] ?? _p2pPort;
      if (peerAddr != null) {
        try {
          socket.send(bytes, peerAddr, peerPort);
        } catch (_) {}
      }
    } else if (_lastPeerAddress != null) {
      try {
        socket.send(bytes, _lastPeerAddress!, _lastPeerPort);
      } catch (_) {}
    }

    for (final bcast in _cachedBroadcastAddresses) {
      try {
        socket.send(bytes, bcast, _p2pPort);
      } catch (_) {
        // Ogni interfaccia è isolata: un'interfaccia offline non blocca mai l'Hotspot o il Wi-Fi locale!
      }
    }
  }

  void _sendHybridRoomPacket(
    Map<String, dynamic> payload, {
    String? explicitTargetInboxCode,
    MqttQos inboxQos = MqttQos.atMostOnce,
    MqttQos roomQos = MqttQos.atMostOnce,
    bool queueIfOffline = false,
  }) {
    final target = explicitTargetInboxCode ?? opponent.code;
    _sendUdpPacket(payload, targetCode: target);
    if (explicitTargetInboxCode != null && explicitTargetInboxCode.isNotEmpty) {
      _publishMqtt(
        buildInboxTopic(explicitTargetInboxCode),
        payload,
        qos: inboxQos,
        queueIfOffline: queueIfOffline,
      );
    }
    if (opponent.code.isNotEmpty) {
      final room = _subscribedRoomTopic ??
          buildRoomTopic(storage.myFriendCode, opponent.code);
      _publishMqtt(
        room,
        payload,
        qos: roomQos,
        queueIfOffline: queueIfOffline,
      );
    }
  }

  void _stopInviteRetryTimer() {
    _inviteRetryTimer?.cancel();
    _inviteRetryTimer = null;
  }

  void _stopRematchRetryTimer() {
    _rematchRetryTimer?.cancel();
    _rematchRetryTimer = null;
  }

  /// Annulla l'invito P2P attualmente in attesa e rimuove il popup sul dispositivo dell'amico
  void cancelOutgoingInvite() {
    _stopInviteRetryTimer();
    final target = outgoingInviteFriendNotifier.value;
    outgoingInviteFriendNotifier.value = null;
    if (target == null) return;
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final cancelPacket = <String, dynamic>{
      't': 'INVITE_CANCEL',
      'code': myCode,
      'target': target.code,
      'id': _activeOutgoingInviteId,
    };
    _sendHybridRoomPacket(
      cancelPacket,
      explicitTargetInboxCode: target.code,
      inboxQos: MqttQos.atLeastOnce,
      roomQos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
  }

  /// Lancia o accetta una sfida 1-Tap (con retry automatico su Cloud MQTT QoS 1 + Subnet UDP)
  void prepareDirectChallenge({
    required FriendRecord friend,
    required P2PDuelFormat format,
    int? customSeed,
    bool isAcceptingInvite = false,
    bool alreadyHandshaked = false,
  }) {
    _stopInviteRetryTimer();
    _stopRematchRetryTimer();
    _lastRemotePauseSeqByPeer.clear();

    activeDuelFormat = format;
    activeMatchSeed =
        customSeed ?? (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);
    opponent.resetForMatch(
      friendCode: friend.code,
      friendName: friend.name,
      friendAvatar: friend.avatarEmoji,
      friendSkinId: friend.skinId,
    );
    if (isAcceptingInvite || alreadyHandshaked) {
      opponent.isRemoteSocketPeer = true;
      outgoingInviteFriendNotifier.value = null;
    }
    opponentMetersNotifier.value = 0.0;
    opponentDeadNotifier.value = false;
    opponentLeftNotifier.value = false;
    rematchStatusNotifier.value = P2PRematchVoteStatus.idle;
    _lastRematchLaunchedSeed = null;

    _subscribeToDuelRoom(friend.code);
    _subscribeToFriendTopics(friend.code);
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final myAvatar =
        ProfileIconsCatalog.getById(storage.selectedProfileIconId).emoji;

    if (alreadyHandshaked) {
      broadcastPlayerState(
        x: 0.0,
        y: 0.0,
        vx: 0.0,
        vy: 0.0,
        meters: 0.0,
        isStuck: true,
        hasShield: false,
        isShadowPhase: false,
        isDead: false,
        hasWon: false,
        force: true,
      );
    } else if (isAcceptingInvite) {
      final acceptPacket = <String, dynamic>{
        't': 'ACCEPT',
        'code': myCode,
        'target': friend.code,
        'name': storage.playerName,
        'avatar': myAvatar,
        'skin': storage.selectedBallSkinId,
        'fmt': format.name,
        'seed': activeMatchSeed,
      };
      void sendAcceptBurst() {
        _sendHybridRoomPacket(
          acceptPacket,
          explicitTargetInboxCode: friend.code,
          inboxQos: MqttQos.atLeastOnce,
          roomQos: MqttQos.atLeastOnce,
          queueIfOffline: true,
        );
      }

      sendAcceptBurst();
      // Doppio reinvio rapido per garantire che anche lo sfidante entri sempre in partita
      _scheduleDelayed(const Duration(milliseconds: 320), sendAcceptBurst);
      _scheduleDelayed(const Duration(milliseconds: 850), sendAcceptBurst);

      broadcastPlayerState(
        x: 0.0,
        y: 0.0,
        vx: 0.0,
        vy: 0.0,
        meters: 0.0,
        isStuck: true,
        hasShield: false,
        isShadowPhase: false,
        isDead: false,
        hasWon: false,
        force: true,
      );
    } else {
      _lastAcceptedMatchKey = null;
      inviteDeclinedByNotifier.value = null;
      outgoingInviteFriendNotifier.value = friend;
      _activeOutgoingInviteId = '${myCode}_$activeMatchSeed';

      Map<String, dynamic> buildInvitePacket() => <String, dynamic>{
            't': 'INVITE',
            'id': _activeOutgoingInviteId,
            'code': myCode,
            'target': friend.code,
            'name': storage.playerName,
            'avatar': myAvatar,
            'skin': storage.selectedBallSkinId,
            'fmt': format.name,
            'seed': activeMatchSeed,
          };

      void dispatchInvite() {
        _sendHybridRoomPacket(
          buildInvitePacket(),
          explicitTargetInboxCode: friend.code,
          inboxQos: MqttQos.atLeastOnce,
          roomQos: MqttQos.atLeastOnce,
          queueIfOffline: true,
        );
      }

      dispatchInvite();
      if (_networkRuntimeActive && !_disposed) {
        int retries = 0;
        _inviteRetryTimer = Timer.periodic(
          const Duration(milliseconds: 1800),
          (timer) {
            retries += 1;
            if (_disposed ||
                outgoingInviteFriendNotifier.value == null ||
                retries > 16) {
              timer.cancel();
              if (retries > 16 &&
                  outgoingInviteFriendNotifier.value?.code == friend.code) {
                outgoingInviteFriendNotifier.value = null;
              }
              return;
            }
            dispatchInvite();
          },
        );
      }
    }
  }

  /// Simula la ricezione di un invito in tempo reale da parte di un amico della lista (usato nei test)
  void simulateIncomingInviteFromFriend({
    FriendRecord? friend,
    P2PDuelFormat format = P2PDuelFormat.race100m,
  }) {
    final chosen = friend ??
        (storage.friendsList.isNotEmpty
            ? storage.friendsList.first
            : const FriendRecord(
                code: 'INK-90428173',
                name: 'Kenji_Zen',
                avatarEmoji: '🥷',
                skinId: 'shinobi_star',
              ));
    final seed = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
    incomingInviteNotifier.value = P2PChallengeInvite(
      inviteId: '${chosen.code}_$seed',
      challengerCode: chosen.code,
      challengerName: chosen.name,
      challengerAvatar: chosen.avatarEmoji,
      challengerSkinId: chosen.skinId,
      format: format,
      towerSeed: seed,
    );
  }

  void simulateIncomingInviteFrom(
    FriendRecord friend, {
    P2PDuelFormat format = P2PDuelFormat.race100m,
  }) =>
      simulateIncomingInviteFromFriend(friend: friend, format: format);

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

  /// Rifiuta l'invito ricevuto e notifica immediatamente lo sfidante
  void declineIncomingInvite() {
    final current = incomingInviteNotifier.value;
    incomingInviteNotifier.value = null;
    if (current == null) return;
    if (current.inviteId.isNotEmpty) {
      _dismissedInviteIds.add(current.inviteId);
    }
    final myCode = StorageService.normalizeFriendCode(storage.myFriendCode);
    final packet = <String, dynamic>{
      't': 'INVITE_DECLINE',
      'code': myCode,
      'target': current.challengerCode,
      'name': storage.playerName,
      'id': current.inviteId,
    };
    _sendHybridRoomPacket(
      packet,
      explicitTargetInboxCode: current.challengerCode,
      inboxQos: MqttQos.atLeastOnce,
      roomQos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
  }

  /// Invia con throttling a 20Hz (`0.050s`) lo stato del giocatore locale sulla stanza di duello P2P
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
    if (_networkSyncAccumulator < 0.050 && !isDead && !hasWon) return;
    _networkSyncAccumulator = 0.0;

    final isTerminalEvent = isDead || hasWon;
    _sendHybridRoomPacket(
      <String, dynamic>{
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
      },
      explicitTargetInboxCode: isTerminalEvent ? opponent.code : null,
      inboxQos: isTerminalEvent ? MqttQos.atLeastOnce : MqttQos.atMostOnce,
      roomQos: isTerminalEvent ? MqttQos.atLeastOnce : MqttQos.atMostOnce,
    );
  }

  /// Invia il pacchetto di Pausa Condivisa (`PAUSE`) con QoS 1 + reinvio rapido per bloccare entrambi i giocatori
  void sendPauseState({
    required bool isPaused,
    required String byPlayerName,
  }) {
    if (opponent.code.isEmpty || opponent.hasLeftMatch) return;
    _pauseSeq += 1;
    final currentSeq = _pauseSeq;
    final packet = <String, dynamic>{
      't': 'PAUSE',
      'code': storage.myFriendCode,
      'target': opponent.code,
      'v': isPaused,
      'by': byPlayerName,
      'seq': currentSeq,
    };

    void sendOnce() {
      _sendHybridRoomPacket(
        packet,
        explicitTargetInboxCode: opponent.code,
        inboxQos: MqttQos.atLeastOnce,
        roomQos: MqttQos.atLeastOnce,
        queueIfOffline: true,
      );
    }

    sendOnce();
    _scheduleDelayed(const Duration(milliseconds: 240), () {
      if (_pauseSeq == currentSeq && !opponent.hasLeftMatch) {
        sendOnce();
      }
    });
  }

  /// Notifica l'avversario che abbiamo abbandonato la partita (dal menu Pausa o tornando al Menu Principale)
  void sendLeaveMatch() {
    if (opponent.code.isEmpty) return;
    _stopInviteRetryTimer();
    _stopRematchRetryTimer();
    final targetCode = opponent.code;
    final packet = <String, dynamic>{
      't': 'LEAVE',
      'code': storage.myFriendCode,
      'target': targetCode,
      'seed': activeMatchSeed,
    };
    _sendHybridRoomPacket(
      packet,
      explicitTargetInboxCode: targetCode,
      inboxQos: MqttQos.atLeastOnce,
      roomQos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
  }

  // --- SISTEMA DI RIVINCITA A VOTAZIONE (1/2 -> 2/2) ---

  void resetRematchVote({bool peerLeft = false}) {
    _stopRematchRetryTimer();
    _pendingRematchSeed = 0;
    _incomingRematchSeed = 0;
    rematchStatusNotifier.value = peerLeft
        ? P2PRematchVoteStatus.peerLeft
        : P2PRematchVoteStatus.idle;
  }

  /// Invia la proposta di Rivincita (Voto 1/2) e attende l'accettazione dell'avversario
  void proposeRematch() {
    if (opponent.hasLeftMatch) {
      rematchStatusNotifier.value = P2PRematchVoteStatus.peerLeft;
      return;
    }
    if (rematchStatusNotifier.value ==
        P2PRematchVoteStatus.incomingPeerRequest) {
      acceptRematch();
      return;
    }
    if (rematchStatusNotifier.value ==
            P2PRematchVoteStatus.waitingPeerAccept ||
        rematchStatusNotifier.value == P2PRematchVoteStatus.acceptedLaunching) {
      return;
    }

    _pendingRematchSeed =
        ((DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF) ^ 0x13579BDF) &
            0x7FFFFFFF;
    if (_pendingRematchSeed == 0 || _pendingRematchSeed == activeMatchSeed) {
      _pendingRematchSeed = (activeMatchSeed + 918273) & 0x7FFFFFFF;
    }
    rematchStatusNotifier.value = P2PRematchVoteStatus.waitingPeerAccept;

    final reqPacket = <String, dynamic>{
      't': 'REMATCH_REQ',
      'code': storage.myFriendCode,
      'target': opponent.code,
      'name': storage.playerName,
      'seed': _pendingRematchSeed,
      'fmt': activeDuelFormat.name,
    };

    void sendReq() {
      _sendHybridRoomPacket(
        reqPacket,
        explicitTargetInboxCode: opponent.code,
        inboxQos: MqttQos.atLeastOnce,
        roomQos: MqttQos.atLeastOnce,
        queueIfOffline: true,
      );
    }

    sendReq();
    if (_networkRuntimeActive && !_disposed) {
      _stopRematchRetryTimer();
      _rematchRetryTimer = Timer.periodic(
        const Duration(milliseconds: 1800),
        (timer) {
          if (_disposed ||
              opponent.hasLeftMatch ||
              rematchStatusNotifier.value !=
                  P2PRematchVoteStatus.waitingPeerAccept) {
            timer.cancel();
            return;
          }
          sendReq();
        },
      );
    }
  }

  void _sendRematchAcceptPacket(int agreedSeed, P2PDuelFormat fmt) {
    final packet = <String, dynamic>{
      't': 'REMATCH_ACCEPT',
      'code': storage.myFriendCode,
      'target': opponent.code,
      'seed': agreedSeed,
      'fmt': fmt.name,
    };
    void sendAcc() {
      _sendHybridRoomPacket(
        packet,
        explicitTargetInboxCode: opponent.code,
        inboxQos: MqttQos.atLeastOnce,
        roomQos: MqttQos.atLeastOnce,
        queueIfOffline: true,
      );
    }

    sendAcc();
    _scheduleDelayed(const Duration(milliseconds: 320), sendAcc);
  }

  /// Accetta la proposta di Rivincita dell'avversario (Voto 2/2) e lancia la nuova torre per entrambi
  void acceptRematch() {
    if (opponent.hasLeftMatch) {
      rematchStatusNotifier.value = P2PRematchVoteStatus.peerLeft;
      return;
    }
    _stopRematchRetryTimer();
    final agreedSeed = _incomingRematchSeed != 0
        ? _incomingRematchSeed
        : ((activeMatchSeed + 104729) & 0x7FFFFFFF);
    final fmt = _incomingRematchFormat;

    _sendRematchAcceptPacket(agreedSeed, fmt);
    if (_lastRematchLaunchedSeed != agreedSeed) {
      _lastRematchLaunchedSeed = agreedSeed;
      rematchStatusNotifier.value = P2PRematchVoteStatus.acceptedLaunching;
      onRematchAgreed?.call(agreedSeed, fmt);
    }
  }

  /// Rifiuta la proposta di Rivincita ricevuta dall'avversario
  void declineRematch() {
    _stopRematchRetryTimer();
    rematchStatusNotifier.value = P2PRematchVoteStatus.idle;
    if (opponent.code.isEmpty || opponent.hasLeftMatch) return;
    final packet = <String, dynamic>{
      't': 'REMATCH_DECLINE',
      'code': storage.myFriendCode,
      'target': opponent.code,
    };
    _sendHybridRoomPacket(
      packet,
      explicitTargetInboxCode: opponent.code,
      inboxQos: MqttQos.atLeastOnce,
      roomQos: MqttQos.atLeastOnce,
      queueIfOffline: true,
    );
  }

  /// Invia il pacchetto di disturbo "Spruzzo d'Inchiostro" all'avversario P2P
  void sendSabotageToOpponent() {
    if (opponent.code.isEmpty || opponent.hasLeftMatch) return;
    _sendHybridRoomPacket(
      <String, dynamic>{
        't': 'SABOTAGE',
        'code': storage.myFriendCode,
        'target': opponent.code,
      },
      explicitTargetInboxCode: opponent.code,
      inboxQos: MqttQos.atLeastOnce,
      roomQos: MqttQos.atLeastOnce,
    );
  }

  void dispose() {
    _disposed = true;
    _networkRuntimeActive = false;
    _stopInviteRetryTimer();
    _stopRematchRetryTimer();
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    for (final t in _transientTimers) {
      t.cancel();
    }
    _transientTimers.clear();

    try {
      _mqttSub?.cancel();
      _mqttClient?.disconnect();
    } catch (_) {}
    _mqttSub = null;
    _mqttClient = null;
    try {
      _udpSocket?.close();
    } catch (_) {}
    _udpSocket = null;
    incomingInviteNotifier.dispose();
    outgoingInviteFriendNotifier.dispose();
    inviteDeclinedByNotifier.dispose();
    incomingFriendRequestNotifier.dispose();
    friendsUpdatedNotifier.dispose();
    opponentMetersNotifier.dispose();
    opponentDeadNotifier.dispose();
    opponentLeftNotifier.dispose();
    rematchStatusNotifier.dispose();
    cloudConnectedNotifier.dispose();
  }
}
