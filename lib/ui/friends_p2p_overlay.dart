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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  P2PDuelFormat _selectedFormat = P2PDuelFormat.race100m;
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.game.p2pService.activeDuelFormat;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _addFriend() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (name.isEmpty || code.length < 3) return;
    await widget.game.storage.addFriend(name: name, code: code);
    _nameController.clear();
    _codeController.clear();
    if (mounted) {
      setState(() {});
    }
  }

  void _challengeFriend(FriendRecord friend) {
    Navigator.of(context).pop();
    widget.game.startP2PDuel(
      friend: friend,
      format: _selectedFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.game.palette;
    final s = widget.game.strings;
    final friends = widget.game.storage.friendsList;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: p.inkPrimary,
                        letterSpacing: 1.0,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          border: Border.all(color: p.inkPrimary, width: 1.5),
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

              // Selettore Formato Duello P2P (100m vs Infinita)
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
                        setState(() => _selectedFormat = P2PDuelFormat.race100m);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FormatChoiceChip(
                      label: s.p2pFormatInfinite,
                      selected:
                          _selectedFormat == P2PDuelFormat.infiniteSurvival,
                      palette: p,
                      onTap: () {
                        setState(
                          () => _selectedFormat = P2PDuelFormat.infiniteSurvival,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Form Aggiungi Amico (1 sola volta)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.paperBg,
                  border: Border.all(
                    color: p.inkPrimary.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.inkPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: s.addFriendNameHint,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: p.inkPrimary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: p.inkPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: s.addFriendCodeHint,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: p.inkPrimary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _addFriend,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            color: p.matchaSafe,
                            child: Text(
                              '+',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: p.paperBg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Lista Amici Salvati con bottone 1-Tap "⚔️ SFIDA"
              Expanded(
                child: friends.isEmpty
                    ? Center(
                        child: Text(
                          s.friendsEmptyHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: p.inkPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: friends.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: p.paperGrid.withValues(alpha: 0.22),
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
                                              friend.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w900,
                                                color: p.inkPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            s.friendOnlineReady,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: p.matchaSafe,
                                            ),
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
                                          color: p.inkPrimary.withValues(
                                            alpha: 0.68,
                                          ),
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
                                          color: p.inkPrimary.withValues(
                                            alpha: 0.25,
                                          ),
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
                                if (friends.length > 1) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () async {
                                      await widget.game.storage.removeFriend(
                                        friend.code,
                                      );
                                      if (mounted) setState(() {});
                                    },
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: p.inkPrimary.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),

              // Bottone Test: simula la ricezione di un invito rapido in cima al menu
              InkWell(
                onTap: () {
                  final targetFriend = friends.isNotEmpty
                      ? friends.first
                      : const FriendRecord(
                          code: 'INK-RONIN',
                          name: 'Maestro Kaze',
                          skinId: 'kitsune_spirit',
                        );
                  widget.game.p2pService.simulateIncomingInviteFrom(
                    targetFriend,
                    format: _selectedFormat,
                  );
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: p.ochreSeal.withValues(alpha: 0.22),
                    border: Border.all(color: p.inkPrimary, width: 1.5),
                  ),
                  child: Text(
                    s.simulateInviteBtn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: p.inkPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? palette.inkPrimary : palette.paperBg,
          border: Border.all(color: palette.inkPrimary, width: 1.8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: selected ? palette.paperBg : palette.inkPrimary,
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
