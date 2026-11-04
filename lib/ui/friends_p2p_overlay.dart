import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/climb_abilities.dart';
import '../game/ink_sling_game.dart';
import '../services/p2p_multiplayer_service.dart';
import '../services/storage_service.dart';

Future<void> showFriendsAndP2PDialog(
  BuildContext context,
  InkSlingGame game,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (_) => FriendsAndP2PDialog(game: game),
  );
}

Future<void> showClimbAbilitiesDialog(
  BuildContext context,
  InkSlingGame game,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (_) => ClimbAbilitiesDialog(game: game),
  );
}

class FriendsAndP2PDialog extends StatefulWidget {
  final InkSlingGame game;

  const FriendsAndP2PDialog({super.key, required this.game});

  @override
  State<FriendsAndP2PDialog> createState() => _FriendsAndP2PDialogState();
}

class _FriendsAndP2PDialogState extends State<FriendsAndP2PDialog> {
  final TextEditingController _codeController = TextEditingController();
  P2PDuelFormat _selectedFormat = P2PDuelFormat.race100m;
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.game.p2pService.activeDuelFormat;
    widget.game.p2pService.initNetworkSocket();
    widget.game.p2pService.requestFriendsPresenceSync();
    widget.game.p2pService.inviteDeclinedByNotifier
        .addListener(_onInviteDeclinedByPeer);
  }

  void _onInviteDeclinedByPeer() {
    final decliner = widget.game.p2pService.inviteDeclinedByNotifier.value;
    if (decliner == null || !mounted) return;
    widget.game.p2pService.inviteDeclinedByNotifier.value = null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.game.strings.inviteDeclinedBySnack(decliner)),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  @override
  void dispose() {
    widget.game.p2pService.inviteDeclinedByNotifier
        .removeListener(_onInviteDeclinedByPeer);
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _copyMyCode() async {
    await Clipboard.setData(
      ClipboardData(text: widget.game.storage.myFriendCode),
    );
    if (!mounted) return;
    setState(() => _codeCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.game.strings.friendCodeCopied),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<void> _sendFriendRequest() async {
    final rawCode = _codeController.text.trim().toUpperCase();
    if (rawCode.length < 3) return;
    final s = widget.game.strings;
    final normalized = StorageService.normalizeFriendCode(rawCode);
    final status =
        await widget.game.p2pService.sendFriendRequest(rawCode);
    if (!mounted) return;

    String? feedback;
    switch (status) {
      case FriendRequestSendStatus.sent:
      case FriendRequestSendStatus.autoAcceptedMutual:
        _codeController.clear();
        feedback = s.friendRequestSentSnack(normalized);
        break;
      case FriendRequestSendStatus.alreadyFriends:
        _codeController.clear();
        feedback = s.friendRequestAlreadyFriendsSnack;
        break;
      case FriendRequestSendStatus.cannotAddSelf:
        feedback = s.friendRequestSelfErrorSnack;
        break;
      case FriendRequestSendStatus.invalidCode:
        break;
    }

    setState(() {});
    if (feedback != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedback),
          duration: const Duration(milliseconds: 1600),
        ),
      );
    }
  }

  Future<void> _confirmAndRemoveFriend(FriendRecord friend) async {
    final p = widget.game.palette;
    final s = widget.game.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => _buildConfirmDialog(
        ctx: ctx,
        palette: p,
        title: s.removeFriendTitle(friend.name),
        message: s.removeFriendMessage,
        cancelLabel: s.cancelBtn,
        confirmLabel: s.removeFriendConfirmBtn,
      ),
    );

    if (confirmed == true && mounted) {
      await widget.game.storage.removeFriend(friend.code);
      widget.game.p2pService.friendsUpdatedNotifier.value += 1;
      if (mounted) setState(() {});
    }
  }

  Future<void> _confirmAndClearAllFriends() async {
    final p = widget.game.palette;
    final s = widget.game.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => _buildConfirmDialog(
        ctx: ctx,
        palette: p,
        title: s.removeAllFriendsTitle,
        message: s.removeAllFriendsMessage,
        cancelLabel: s.cancelBtn,
        confirmLabel: s.removeFriendConfirmBtn,
      ),
    );

    if (confirmed == true && mounted) {
      await widget.game.storage.clearAllFriends();
      widget.game.p2pService.friendsUpdatedNotifier.value += 1;
      if (mounted) setState(() {});
    }
  }

  Widget _buildConfirmDialog({
    required BuildContext ctx,
    required dynamic palette,
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
  }) {
    final p = palette;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.paperCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.inkPrimary, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: p.shadowColor,
              offset: const Offset(4, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.inkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.inkSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.inkPrimary,
                      side: BorderSide(color: p.inkPrimary, width: 1.8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.vermilionHazard,
                      foregroundColor: p.paperBg,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: p.inkPrimary, width: 1.8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _challengeFriend(FriendRecord friend) {
    widget.game.audioHaptics.onButtonTap();
    widget.game.p2pService.prepareDirectChallenge(
      friend: friend,
      format: _selectedFormat,
    );
  }

  void _startStandaloneBotTraining() {
    widget.game.audioHaptics.onButtonTap();
    widget.game.p2pService.cancelOutgoingInvite();
    final route = ModalRoute.of(context);
    if (widget.game.navigatorKey == null &&
        route != null &&
        route.isCurrent) {
      Navigator.of(context).pop();
    }
    widget.game.startBotTrainingDuel(format: _selectedFormat);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.game.palette;
    final s = widget.game.strings;

    return ValueListenableBuilder<int>(
      valueListenable: widget.game.p2pService.friendsUpdatedNotifier,
      builder: (context, _, __) {
        final friends = widget.game.storage.friendsList;
        final incomingReqs = widget.game.storage.incomingFriendRequests;
        final outgoingReqs = widget.game.storage.outgoingFriendRequests;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: RepaintBoundary(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 410, maxHeight: 650),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: p.paperBg,
                border: Border.all(color: p.inkPrimary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: p.inkPrimary.withValues(alpha: 0.25),
                    offset: const Offset(6, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.friendsAndP2PTitle,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: p.inkPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: p.inkPrimary),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Box Codice Amico Personale
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: p.paperGrid.withValues(alpha: 0.32),
                      border: Border.all(color: p.inkPrimary, width: 1.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.yourFriendCodeLabel,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: p.inkPrimary.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.game.storage.myFriendCode,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.6,
                                  color: p.vermilionHazard,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _copyMyCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _codeCopied ? p.matchaSafe : p.inkPrimary,
                              border:
                                  Border.all(color: p.inkPrimary, width: 1.5),
                            ),
                            child: Text(
                              _codeCopied ? '✓' : 'COPIA',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: p.paperBg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Selettore Formato Duello P2P (rettangoli fissi e identici per tutte le lingue)
                  Text(
                    s.p2pFormatLabel,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: p.inkPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: _FormatChoiceChip(
                          label: s.p2pFormat100m,
                          selected: _selectedFormat == P2PDuelFormat.race100m,
                          palette: p,
                          onTap: () {
                            setState(
                              () => _selectedFormat = P2PDuelFormat.race100m,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FormatChoiceChip(
                          label: s.p2pFormatInfinite,
                          selected: _selectedFormat ==
                              P2PDuelFormat.infiniteSurvival,
                          palette: p,
                          onTap: () {
                            setState(
                              () => _selectedFormat =
                                  P2PDuelFormat.infiniteSurvival,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Modalità Allenamento dedicata (unica modalità in cui il Bot è visibile)
                  InkWell(
                    onTap: _startStandaloneBotTraining,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: p.paperCard,
                        border: Border.all(color: p.inkPrimary, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: p.inkPrimary.withValues(alpha: 0.18),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          s.trainingVsBotStandaloneBtn,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: p.inkPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Form Invio Richiesta di Amicizia (Codice a 8 cifre)
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: p.paperBg,
                      border: Border.all(
                        color: p.inkPrimary.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (_) => _sendFriendRequest(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: p.inkPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: s.addFriendCodeHint,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: p.inkPrimary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _sendFriendRequest,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: p.matchaSafe,
                              border:
                                  Border.all(color: p.inkPrimary, width: 1.5),
                            ),
                            child: Text(
                              s.sendFriendRequestBtn,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: p.paperBg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  ValueListenableBuilder<FriendRecord?>(
                    valueListenable:
                        widget.game.p2pService.outgoingInviteFriendNotifier,
                    builder: (context, waitingFriend, _) {
                      if (waitingFriend == null) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: p.ochreSeal.withValues(alpha: 0.22),
                          border: Border.all(color: p.inkPrimary, width: 1.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              s.waitingForFriendAccept(waitingFriend.name),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: p.inkPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                widget.game.audioHaptics.onButtonTap();
                                widget.game.p2pService.cancelOutgoingInvite();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 7,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: p.paperCard,
                                  border: Border.all(
                                    color: p.vermilionHazard,
                                    width: 1.6,
                                  ),
                                ),
                                child: Text(
                                  s.cancelInviteBtn,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: p.vermilionHazard,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Area scorrevole: Richieste Ricevute + Richieste Inviate + Lista Amici Confermati
                  Expanded(
                    child: (incomingReqs.isEmpty &&
                            outgoingReqs.isEmpty &&
                            friends.isEmpty)
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                s.friendsEmptyHint,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.3,
                                  color: p.inkPrimary.withValues(alpha: 0.72),
                                ),
                              ),
                            ),
                          )
                        : ListView(
                            children: [
                              // 1. RICHIESTE DI AMICIZIA RICEVUTE (da accettare o rifiutare)
                              if (incomingReqs.isNotEmpty) ...[
                                Text(
                                  s.incomingFriendRequestsTitle,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: p.vermilionHazard,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                for (final req in incomingReqs) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.matchaSafe.withValues(
                                        alpha: 0.16,
                                      ),
                                      border: Border.all(
                                        color: p.matchaSafe,
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${req.avatarEmoji} ${req.name}',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                  color: p.inkPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                req.code,
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: p.inkPrimary
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            widget.game.audioHaptics
                                                .onButtonTap();
                                            await widget.game.p2pService
                                                .acceptFriendRequest(req);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: p.matchaSafe,
                                              border: Border.all(
                                                color: p.inkPrimary,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              s.acceptChallengeBtn,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w900,
                                                color: p.paperBg,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () async {
                                            widget.game.audioHaptics
                                                .onButtonTap();
                                            await widget.game.p2pService
                                                .declineFriendRequest(req);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: p.paperBg,
                                              border: Border.all(
                                                color: p.inkPrimary,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              '✕',
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                color: p.vermilionHazard,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                              ],

                              // 2. RICHIESTE INVIATE (in attesa di accettazione del destinatario)
                              if (outgoingReqs.isNotEmpty) ...[
                                Text(
                                  s.outgoingFriendRequestsTitle,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: p.inkPrimary.withValues(alpha: 0.72),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                for (final req in outgoingReqs) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.ochreSeal.withValues(alpha: 0.14),
                                      border: Border.all(
                                        color:
                                            p.inkPrimary.withValues(alpha: 0.6),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                req.code,
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: p.inkPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                s.friendRequestPendingLabel,
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: p.inkPrimary
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            widget.game.audioHaptics
                                                .onButtonTap();
                                            await widget.game.p2pService
                                                .cancelOutgoingFriendRequest(
                                              req.code,
                                            );
                                          },
                                          icon: Icon(
                                            Icons.close_rounded,
                                            size: 19,
                                            color: p.vermilionHazard,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                              ],

                              // 3. AMICI CONFERMATI (tutti rimovibili fino a 0)
                              if (friends.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${s.confirmedFriendsListTitle} (${friends.length})',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: p.inkPrimary
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _confirmAndClearAllFriends,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          s.removeAllFriendsBtn,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: p.vermilionHazard,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                for (final friend in friends) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          p.paperGrid.withValues(alpha: 0.22),
                                      border: Border.all(
                                        color: p.inkPrimary,
                                        width: 1.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      '${friend.avatarEmoji} ${friend.name}',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 13.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: p.inkPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Builder(
                                                    builder: (_) {
                                                      final isOnline = widget
                                                          .game.p2pService
                                                          .isFriendOnline(
                                                        friend.code,
                                                      );
                                                      return Text(
                                                        isOnline
                                                            ? s.friendOnlineReady
                                                            : s.friendOfflineStatus,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'monospace',
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: isOnline
                                                              ? p.matchaSafe
                                                              : p.inkSecondary,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${friend.code}  •  🏆 ${friend.winsAgainst}V - ${friend.lossesAgainst}S',
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: p.inkPrimary
                                                      .withValues(alpha: 0.68),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => _challengeFriend(friend),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 11,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: p.vermilionHazard,
                                              border: Border.all(
                                                color: p.inkPrimary,
                                                width: 1.8,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: p.inkPrimary
                                                      .withValues(alpha: 0.25),
                                                  offset: const Offset(2, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              s.challengeOneTapBtn,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w900,
                                                color: p.paperBg,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () =>
                                              _confirmAndRemoveFriend(friend),
                                          icon: Icon(
                                            Icons.close_rounded,
                                            size: 20,
                                            color: p.vermilionHazard,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FormatChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final dynamic palette;
  final VoidCallback onTap;

  const _FormatChoiceChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? palette.inkPrimary : palette.paperBg,
            border: Border.all(color: palette.inkPrimary, width: 1.8),
          ),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: selected ? palette.paperBg : palette.inkPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class ClimbAbilitiesDialog extends StatefulWidget {
  final InkSlingGame game;

  const ClimbAbilitiesDialog({super.key, required this.game});

  @override
  State<ClimbAbilitiesDialog> createState() => _ClimbAbilitiesDialogState();
}

class _ClimbAbilitiesDialogState extends State<ClimbAbilitiesDialog> {
  @override
  Widget build(BuildContext context) {
    final p = widget.game.palette;
    final s = widget.game.strings;
    final playerLevel = widget.game.storage.currentTowerLevel;
    final equippedId = widget.game.storage.selectedAbilityId;
    final abilities = ClimbAbilitiesCatalog.allAbilities;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: RepaintBoundary(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 410, maxHeight: 640),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: p.paperBg,
            border: Border.all(color: p.inkPrimary, width: 3),
            boxShadow: [
              BoxShadow(
                color: p.inkPrimary.withValues(alpha: 0.25),
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.abilitiesSectionTitle,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: p.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.abilitiesSectionSubtitle,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            color: p.inkPrimary.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: p.inkPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: abilities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final ability = abilities[index];
                    final unlocked = ability.isUnlocked(playerLevel);
                    final isEquipped = ability.id == equippedId;

                    return InkWell(
                      onTap: unlocked
                          ? () async {
                              await widget.game.storage.setSelectedAbility(
                                ability.id,
                              );
                              if (mounted) setState(() {});
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: isEquipped
                              ? p.ochreSeal.withValues(alpha: 0.22)
                              : unlocked
                              ? p.paperBg
                              : p.paperGrid.withValues(alpha: 0.3),
                          border: Border.all(
                            color: isEquipped
                                ? p.ochreSeal
                                : p.inkPrimary.withValues(
                                    alpha: unlocked ? 1.0 : 0.45,
                                  ),
                            width: isEquipped ? 2.5 : 1.6,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: unlocked
                                    ? p.inkPrimary
                                    : p.inkPrimary.withValues(alpha: 0.35),
                                border: Border.all(
                                  color: p.inkPrimary,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                unlocked ? ability.icon : '🔒',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ability.getName(s),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: p.inkPrimary.withValues(
                                              alpha: unlocked ? 1.0 : 0.55,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        color: p.inkPrimary.withValues(
                                          alpha: 0.12,
                                        ),
                                        child: Text(
                                          s.abilityCooldownBadge(
                                            ability.cooldownSeconds.toInt(),
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: p.inkPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ability.getDescription(s),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      height: 1.25,
                                      color: p.inkPrimary.withValues(
                                        alpha: unlocked ? 0.82 : 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      !unlocked
                                          ? '🔒 ${s.abilityUnlockLevelLabel(ability.unlockTowerLevel)}'
                                          : isEquipped
                                          ? '✓ ${s.abilityEquippedBadge}'
                                          : s.abilityEquipAction,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: !unlocked
                                            ? p.vermilionHazard
                                            : isEquipped
                                            ? p.matchaSafe
                                            : p.inkPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
