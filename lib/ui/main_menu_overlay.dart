import 'package:flutter/material.dart';
import '../core/daily_seed.dart';
import '../core/palette_theme.dart';
import '../game/ink_sling_game.dart';

/// Menu Principale pulito, senza scritte superflue o simboli orientali,
/// con protezione totale dagli overflow di testo e transizioni di colore fluide.
class MainMenuOverlay extends StatefulWidget {
  final InkSlingGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RisographPalette>(
      valueListenable: widget.game.paletteNotifier,
      builder: (context, p, _) {
        final storage = widget.game.storage;
        final issue = DailySeedEngine.getIssueNumber();
        final dateStr = DailySeedEngine.getFormattedDate();

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: p.paperCard,
                  borderRadius: BorderRadius.circular(18),
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
                    // Riga superiore: Sfida del giorno + Bottone cambio tema
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: p.inkPrimary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'SFIDA #$issue • $dateStr',
                                  style: TextStyle(
                                    color: p.paperCard,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => widget.game.cyclePalette(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: p.paperBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: p.inkPrimary,
                                width: 1.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.palette_outlined,
                                  size: 14,
                                  color: p.inkPrimary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Tema: ${p.name}',
                                  style: TextStyle(
                                    color: p.inkPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Titolo + Badge 100m
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'DAILY SLING',
                                  style: TextStyle(
                                    color: p.inkPrimary,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1 TORRE AL GIORNO • ARRIVA A 100 METRI',
                                style: TextStyle(
                                  color: p.matchaSafe,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: p.matchaSafe,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: p.inkPrimary, width: 2),
                          ),
                          child: const Text(
                            '100\nMETRI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Box Statistiche Giornaliere
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: p.paperBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.inkPrimary, width: 1.8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatColumn(
                              label: 'RECORD OGGI',
                              value: storage.completedToday
                                  ? '100m 🏆'
                                  : '${storage.bestMetersToday.toStringAsFixed(1)}m',
                              p: p,
                            ),
                          ),
                          Container(width: 1.5, height: 28, color: p.paperGrid),
                          Expanded(
                            child: _buildStatColumn(
                              label: 'SERIE',
                              value: '${storage.currentStreak} GG',
                              p: p,
                            ),
                          ),
                          Container(width: 1.5, height: 28, color: p.paperGrid),
                          Expanded(
                            child: _buildStatColumn(
                              label: 'VITE OGGI',
                              value:
                                  '${storage.officialAttemptsLeft}/${DailySeedEngine.maxOfficialAttemptsPerDay}',
                              p: p,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Regole chiare del gameplay con incollaggio
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: p.paperGrid, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRuleRow(
                            icon: '🟩',
                            text:
                                'Le piattaforme verdi INCOLLANO la palla: fermati, respira e mira con calma!',
                            p: p,
                          ),
                          const SizedBox(height: 6),
                          _buildRuleRow(
                            icon: '🎯',
                            text:
                                'Trascina ovunque per mirare in slow-motion e rilascia per saltare.',
                            p: p,
                          ),
                          const SizedBox(height: 6),
                          _buildRuleRow(
                            icon: '⚡',
                            text:
                                'Hai 3 lanci per ogni salto (si ricaricano sempre sulle piattaforme verdi).',
                            p: p,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Pulsante Principale "GIOCA"
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.playerFill,
                        foregroundColor: p.paperCard,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: p.inkPrimary, width: 2.2),
                        ),
                      ),
                      onPressed: widget.game.startRun,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          storage.officialAttemptsLeft > 0
                              ? 'GIOCA LA TORRE DI OGGI (${storage.officialAttemptsLeft} VITE)'
                              : 'ALLENAMENTO LIBERO SULLA TORRE DI OGGI',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),

                    if (storage.officialAttemptsLeft == 0) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: p.vermilionHazard,
                          side: BorderSide(color: p.vermilionHazard, width: 1.8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final ok =
                              await widget.game.monetization.showRewardedAd(
                            context: context,
                            rewardTitle: 'Ottieni +1 Tentativo Ufficiale Oggi',
                            isProUnlocked: storage.proUnlocked,
                          );
                          if (ok && mounted) {
                            await storage.grantExtraOfficialAttempt();
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'SBLOCCA +1 VITA UFFICIALE (VIDEO)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required RisographPalette p,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: p.inkSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: p.inkPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow({
    required String icon,
    required String text,
    required RisographPalette p,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: p.inkPrimary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
