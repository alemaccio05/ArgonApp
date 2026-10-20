import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/ball_skins.dart';
import '../core/palette_theme.dart';
import '../core/profile_icons.dart';
import '../game/ink_sling_game.dart';
import '../services/storage_service.dart';
import 'ball_skins_overlay.dart';

/// Schermata/Dialog del Profilo Giocatore in perfetto stile Risograph:
/// - Personalizzazione Nome Giocatore
/// - Avatar grande con icona selezionata e titolo onorifico
/// - Tab 1: Statistiche Dettagliate (Rimbalzi totali, Streak, #1 Livelli, #1 Giornaliera, Top 3, Metri totali...)
/// - Tab 2: Griglia delle Icone Profilo sbloccabili con stato, requisiti e avanzamento
class ProfileDialog extends StatefulWidget {
  final InkSlingGame game;
  const ProfileDialog({super.key, required this.game});

  static Future<void> show(BuildContext context, InkSlingGame game) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ProfileDialog(game: game),
    );
  }

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  int _selectedTab = 0; // 0 = Statistiche, 1 = Icone Profilo
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.game.storage.playerName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _savePlayerName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      await widget.game.storage.setPlayerName(newName);
      setState(() {
        _isEditingName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.game.paletteNotifier,
        widget.game.languageNotifier,
      ]),
      builder: (context, _) {
        final p = widget.game.paletteNotifier.value;
        final s = widget.game.strings;
        final storage = widget.game.storage;
        final currentIcon = ProfileIconsCatalog.getById(storage.selectedProfileIconId);
        final currentSkin = BallSkinsCatalog.getById(storage.selectedBallSkinId);
        final honorTitle = ProfileIconsCatalog.getPlayerHonorTitle(storage, s);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 660),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.paperCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.inkPrimary, width: 2.6),
                boxShadow: [
                  BoxShadow(
                    color: p.shadowColor,
                    offset: const Offset(5, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Intestazione con Titolo e Bottone Chiusura (X)
                  Row(
                    children: [
                      Icon(Icons.person_pin_rounded, color: p.matchaSafe, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.profileTitle,
                          style: TextStyle(
                            color: p.inkPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: p.inkPrimary, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Scheda Superiore Profilo: Avatar Grande + Nome + Titolo Onorifico
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.paperBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.inkPrimary, width: 1.8),
                    ),
                    child: Row(
                      children: [
                        // Avatar Circolare con Icona Attuale
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: p.paperCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.matchaSafe, width: 2.5),
                          ),
                          child: Center(
                            child: Icon(
                              currentIcon.iconData,
                              size: 30,
                              color: p.inkPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Nome Giocatore (con modifica inline) + Titolo + Badge Livello
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isEditingName)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _nameController,
                                        maxLength: 14,
                                        style: TextStyle(
                                          color: p.inkPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          filled: true,
                                          fillColor: p.paperCard,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: p.inkPrimary,
                                              width: 1.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: p.matchaSafe,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: _savePlayerName,
                                      child: Text(
                                        s.saveNameBtn,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          storage.playerName,
                                          style: TextStyle(
                                            color: p.inkPrimary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _isEditingName = true;
                                      }),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.edit_note_rounded,
                                          size: 20,
                                          color: p.inkSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 3),

                              // Titolo Onorifico e Badge
                              Row(
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        honorTitle,
                                        style: TextStyle(
                                          color: p.ochreSeal,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.inkPrimary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${s.levelShort} ${storage.currentTowerLevel}',
                                      style: TextStyle(
                                        color: p.paperCard,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Miniatura Skin Attuale con tap per aprire studio
                        GestureDetector(
                          onTap: () async {
                            await BallSkinsDialog.show(context, widget.game);
                            setState(() {});
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: p.paperCard,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.ochreSeal, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                currentSkin.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selettore Tab: STATISTICHE vs ICONE vs SKIN SFERA
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: p.paperBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.inkPrimary, width: 1.6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? p.inkPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.query_stats_rounded,
                                    size: 14,
                                    color: _selectedTab == 0 ? p.paperCard : p.inkSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      s.tabStats,
                                      style: TextStyle(
                                        color: _selectedTab == 0
                                            ? p.paperCard
                                            : p.inkSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? p.inkPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 14,
                                    color: _selectedTab == 1 ? p.paperCard : p.inkSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      s.tabIcons,
                                      style: TextStyle(
                                        color: _selectedTab == 1
                                            ? p.paperCard
                                            : p.inkSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTab == 2 ? p.inkPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.palette_outlined,
                                    size: 14,
                                    color: _selectedTab == 2 ? p.paperCard : p.inkSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      s.tabSkins,
                                      style: TextStyle(
                                        color: _selectedTab == 2
                                            ? p.paperCard
                                            : p.inkSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Contenuto Dinamico del Tab
                  Expanded(
                    child: _selectedTab == 0
                        ? _buildStatsView(storage, p, s)
                        : (_selectedTab == 1
                            ? _buildIconsView(storage, p, s)
                            : _buildSkinsView(storage, p, s)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Vista Tab 1: Statistiche Dettagliate
  Widget _buildStatsView(StorageService storage, RisographPalette p, AppStrings s) {
    final stats = [
      _StatItem(
        icon: Icons.bolt_rounded,
        label: s.totalBouncesStat,
        value: '${storage.totalBouncesAllTime}',
        accentColor: p.ochreSeal,
      ),
      _StatItem(
        icon: Icons.local_fire_department_rounded,
        label: s.dayStreakStat,
        value: s.streakDays(storage.currentStreak),
        accentColor: p.vermilionHazard,
      ),
      _StatItem(
        icon: Icons.emoji_events_rounded,
        label: s.levelFirstPlaceStat,
        value: '${storage.levelFirstPlaceCount}',
        accentColor: p.matchaSafe,
      ),
      _StatItem(
        icon: Icons.workspace_premium_rounded,
        label: s.dailyFirstPlaceStat,
        value: '${storage.dailyFirstPlaceCount}',
        accentColor: p.ochreSeal,
      ),
      _StatItem(
        icon: Icons.military_tech_rounded,
        label: s.dailyTop3Stat,
        value: '${storage.dailyTop3Count}',
        accentColor: p.matchaSafe,
      ),
      _StatItem(
        icon: Icons.flag_rounded,
        label: s.totalDailyWonStat,
        value: '${storage.totalDailyTowersCompleted}',
        accentColor: p.ochreSeal,
      ),
      _StatItem(
        icon: Icons.terrain_rounded,
        label: s.highestLevelStat,
        value: '${s.levelShort} ${storage.currentTowerLevel}',
        accentColor: p.matchaSafe,
      ),
      _StatItem(
        icon: Icons.straighten_rounded,
        label: s.totalMetersStat,
        value: '${storage.totalMetersClimbed.toStringAsFixed(0)}m',
        accentColor: p.inkPrimary,
      ),
    ];

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, index) {
        final item = stats[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: p.paperBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.paperGrid, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.accentColor.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 18, color: item.accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: p.inkSecondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.value,
                        style: TextStyle(
                          color: p.inkPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Vista Tab 2: Griglia Icone Profilo & Avatar Sbloccabili
  Widget _buildIconsView(StorageService storage, RisographPalette p, AppStrings s) {
    final icons = ProfileIconsCatalog.allIcons;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: icons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isEquipped = storage.selectedProfileIconId == icon.id;
        final isUnlocked = icon.isUnlocked(storage);
        final progress = icon.getProgress(storage, s);

        return Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isEquipped
                ? p.matchaSafe.withAlpha((0.12 * 255).round())
                : p.paperBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEquipped
                  ? p.matchaSafe
                  : (isUnlocked ? p.inkPrimary : p.paperGrid),
              width: isEquipped ? 2.2 : 1.4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icona / Emoji
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isUnlocked ? p.paperCard : p.paperBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEquipped
                            ? p.matchaSafe
                            : (isUnlocked ? p.inkPrimary : p.paperGrid),
                        width: 1.6,
                      ),
                    ),
                    child: Center(
                      child: isUnlocked
                          ? Icon(
                              icon.iconData,
                              size: 24,
                              color: isEquipped ? p.matchaSafe : p.inkPrimary,
                            )
                          : Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: p.inkSecondary.withAlpha(160),
                            ),
                    ),
                  ),
                  if (isEquipped)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: p.matchaSafe,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),

              // Nome Icona
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  icon.getName(s),
                  style: TextStyle(
                    color: isUnlocked ? p.inkPrimary : p.inkSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              // Requisito / Progresso o Pulsante Equipaggia
              if (isEquipped)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.matchaSafe,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    s.equippedBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else if (isUnlocked)
                SizedBox(
                  height: 22,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.inkPrimary,
                      side: BorderSide(color: p.inkPrimary, width: 1.4),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () async {
                      await storage.setSelectedProfileIcon(icon.id);
                      setState(() {});
                    },
                    child: Text(
                      s.equipBtn,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        icon.getRequirement(s),
                        maxLines: 1,
                        style: TextStyle(
                          color: p.inkSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      progress,
                      style: TextStyle(
                        color: p.vermilionHazard,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  /// Vista Tab 3: Selezione Skin Sfera sbloccabili ed equipaggiabili
  Widget _buildSkinsView(StorageService storage, RisographPalette p, AppStrings s) {
    final skins = BallSkinsCatalog.allSkins;
    final equippedSkin = BallSkinsCatalog.getById(storage.selectedBallSkinId);

    return Column(
      children: [
        // Banner Sfera Attuale + Pulsante Studio Animato
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: p.paperBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.inkPrimary, width: 1.4),
          ),
          child: Row(
            children: [
              Text(
                equippedSkin.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equippedSkin.getName(s),
                      style: TextStyle(
                        color: p.inkPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      s.skinsHeader,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.inkSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 26,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.ochreSeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  onPressed: () async {
                    await BallSkinsDialog.show(context, widget.game);
                    setState(() {});
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        s.openStudioBtn,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Griglia Skin
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: skins.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.15,
            ),
            itemBuilder: (context, index) {
              final skin = skins[index];
              final isEquipped = storage.selectedBallSkinId == skin.id;
              final isUnlocked = skin.isUnlocked(storage);
              final progress = skin.getProgress(storage, s);

              return GestureDetector(
                onTap: isUnlocked
                    ? () async {
                        await storage.setSelectedBallSkin(skin.id);
                        setState(() {});
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isEquipped
                        ? p.matchaSafe.withAlpha((0.14 * 255).round())
                        : p.paperBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isEquipped
                          ? p.matchaSafe
                          : (isUnlocked ? p.inkPrimary : p.paperGrid),
                      width: isEquipped ? 2.0 : 1.3,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Emoji / Thumbnail
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: p.paperCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isEquipped
                                ? p.matchaSafe
                                : (isUnlocked ? p.inkPrimary : p.paperGrid),
                            width: 1.4,
                          ),
                        ),
                        child: Center(
                          child: isUnlocked
                              ? Text(
                                  skin.emoji,
                                  style: const TextStyle(fontSize: 16),
                                )
                              : Icon(
                                  Icons.lock_rounded,
                                  size: 14,
                                  color: p.inkSecondary.withAlpha(160),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Dettagli
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                skin.getName(s),
                                style: TextStyle(
                                  color: isUnlocked ? p.inkPrimary : p.inkSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isEquipped)
                              Text(
                                s.equippedBadge,
                                style: TextStyle(
                                  color: p.matchaSafe,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            else if (isUnlocked)
                              Text(
                                s.equipBtn,
                                style: TextStyle(
                                  color: p.inkPrimary,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            else
                              Text(
                                progress,
                                style: TextStyle(
                                  color: p.vermilionHazard,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
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
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });
}
