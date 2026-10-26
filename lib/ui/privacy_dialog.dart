import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/palette_theme.dart';
import '../game/ink_sling_game.dart';

/// Dialog dedicato alle Norme sulla Privacy (Privacy Policy) in perfetto stile Risograph.
/// Rispetta le linee guida di Google Play Store fornendo:
/// 1. Trasparenza immediata in-game sulle modalità di salvataggio e assenza di tracciamento.
/// 2. Link diretto e funzionante alle Norme complete ospitate su URL pubblico HTTPS.
class PrivacyDialog extends StatelessWidget {
  final InkSlingGame game;
  const PrivacyDialog({super.key, required this.game});

  /// URL pubblico ufficiale ospitato con certificato SSL valido
  static const String privacyPolicyUrl =
      'https://alemaccio05.github.io/ArgonApp/privacy.html';

  static Future<void> show(BuildContext context, InkSlingGame game) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrivacyDialog(game: game),
    );
  }

  static Future<void> launchPrivacyUrl(BuildContext context, InkSlingGame game) async {
    final langCode = game.languageNotifier.value.code;
    final uri = Uri.parse('$privacyPolicyUrl?lang=$langCode');
    final s = game.strings;
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${s.privacyErrorOpenUrl}: $uri',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${s.privacyErrorOpenUrl}: $uri',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        game.paletteNotifier,
        game.languageNotifier,
      ]),
      builder: (context, _) {
        final p = game.paletteNotifier.value;
        final s = game.strings;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
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
                  // Intestazione con Icona Scudo, Titolo e Pulsante Chiusura (X)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: p.matchaSafe.withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.matchaSafe, width: 1.5),
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          color: p.matchaSafe,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.privacyTitle,
                              style: TextStyle(
                                color: p.inkPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              'com.alemaccio.inktower',
                              style: TextStyle(
                                color: p.inkSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: p.inkPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Lista Punti Privacy
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPointCard(
                            icon: Icons.person_off_rounded,
                            iconColor: p.matchaSafe,
                            title: s.privacyPoint1Title,
                            desc: s.privacySummaryLine1,
                            p: p,
                          ),
                          const SizedBox(height: 8),
                          _buildPointCard(
                            icon: Icons.phone_android_rounded,
                            iconColor: p.ochreSeal,
                            title: s.privacyPoint2Title,
                            desc: s.privacySummaryLine2,
                            p: p,
                          ),
                          const SizedBox(height: 8),
                          _buildPointCard(
                            icon: Icons.wifi_off_rounded,
                            iconColor: p.playerFill,
                            title: s.privacyPoint3Title,
                            desc: s.privacySummaryLine3,
                            p: p,
                          ),
                          const SizedBox(height: 12),

                          // Contatto Sviluppatore
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: p.paperBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: p.paperGrid,
                                width: 1.4,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 16,
                                  color: p.inkSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    s.privacyContactDeveloper,
                                    style: TextStyle(
                                      color: p.inkPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Pulsanti Azione: Apri Online + Chiudi
                  Row(
                    children: [
                      // Pulsante Apri nel Web
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.matchaSafe,
                            foregroundColor: p.onMatchaSafe,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: p.inkPrimary, width: 2),
                            ),
                          ),
                          onPressed: () => launchPrivacyUrl(context, game),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              s.privacyOpenWeb,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Pulsante Chiudi
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: p.inkPrimary,
                          backgroundColor: p.paperBg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: p.inkPrimary, width: 2),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          s.closeBtn,
                          style: TextStyle(
                            color: p.inkPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPointCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required RisographPalette p,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.paperBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.paperGrid, width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.inkPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: p.inkSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
