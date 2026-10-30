import 'package:flutter/material.dart';
import '../core/palette_theme.dart';
import '../game/ink_sling_game.dart';

/// Overlay modale di Pausa in-game (Punto 5):
/// - Congela il game loop (`timeScale = 0` / `isPaused = true`) e attenua l'audio (ducking)
/// - Riprendi partita
/// - Cambio Tema con selezione visiva immediata (Sabbia, Notte, Salvia)
/// - Toggle Audio indipendenti (Master, SFX, Musica)
/// - Uscita al Menù Principale con conferma rapida anti-errore
class PauseOverlay extends StatefulWidget {
  final InkSlingGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  bool _confirmingExit = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.game.paletteNotifier,
        widget.game.languageNotifier,
        widget.game.masterAudioNotifier,
        widget.game.soundNotifier,
        widget.game.musicNotifier,
      ]),
      builder: (context, _) {
        final p = widget.game.paletteNotifier.value;
        final s = widget.game.strings;
        final volumeOn = widget.game.soundNotifier.value;

        return Material(
          color: Colors.black.withAlpha(148),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 370),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                        // Header Pausa
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: p.ochreSeal,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: p.inkPrimary,
                                  width: 1.8,
                                ),
                              ),
                              child: Icon(
                                Icons.pause_rounded,
                                color: p.onOchreSeal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.pauseTitle,
                                    style: TextStyle(
                                      color: p.inkPrimary,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.pauseSubtitle,
                                    style: TextStyle(
                                      color: p.inkSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Pulsante Primario: RIPRENDI / RESUME
                        _PauseTactileButton(
                          onTap: () {
                            widget.game.audioHaptics.onButtonTap();
                            widget.game.resumeGame();
                          },
                          backgroundColor: p.matchaSafe,
                          borderColor: p.inkPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: p.onMatchaSafe,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    s.resumeBtn,
                                    style: TextStyle(
                                      color: p.onMatchaSafe,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sezione: Cambio Tema (Selezione visiva immediata)
                        Text(
                          s.themeSectionLabel,
                          style: TextStyle(
                            color: p.inkSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: RisographPalette.all.map((paletteOpt) {
                            final isSelected = paletteOpt.id == p.id;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: paletteOpt != RisographPalette.all.last
                                      ? 8
                                      : 0,
                                ),
                                child: _PauseTactileButton(
                                  onTap: () {
                                    widget.game.audioHaptics.onButtonTap();
                                    widget.game.selectPaletteById(paletteOpt.id);
                                  },
                                  backgroundColor: isSelected
                                      ? p.inkPrimary
                                      : p.paperBg,
                                  borderColor: isSelected
                                      ? p.matchaSafe
                                      : p.inkPrimary,
                                  borderWidth: isSelected ? 2.2 : 1.5,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                    horizontal: 6,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Anteprima cromatica immediata della palette
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _ColorSwatchDot(
                                            color: paletteOpt.paperBg,
                                            borderColor: paletteOpt.inkPrimary,
                                          ),
                                          const SizedBox(width: 4),
                                          _ColorSwatchDot(
                                            color: paletteOpt.matchaSafe,
                                            borderColor: paletteOpt.inkPrimary,
                                          ),
                                          const SizedBox(width: 4),
                                          _ColorSwatchDot(
                                            color: paletteOpt.vermilionHazard,
                                            borderColor: paletteOpt.inkPrimary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          s.paletteName(paletteOpt.id),
                                          style: TextStyle(
                                            color: isSelected
                                                ? p.paperCard
                                                : p.inkPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Sezione: Controllo Volume Singolo Unificato
                        Text(
                          s.audioSectionLabel,
                          style: TextStyle(
                            color: p.inkSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: p.paperBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: p.inkPrimary,
                              width: 1.6,
                            ),
                          ),
                          child: _AudioToggleRow(
                            icon: volumeOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            label: s.volumeAudioLabel,
                            value: volumeOn,
                            palette: p,
                            onChanged: () {
                              widget.game.toggleVolume();
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Uscita al Menù Principale con conferma rapida anti-errore
                        if (!_confirmingExit)
                          _PauseTactileButton(
                            onTap: () {
                              widget.game.audioHaptics.onButtonTap();
                              setState(() => _confirmingExit = true);
                            },
                            backgroundColor: p.paperBg,
                            borderColor: p.vermilionHazard,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.exit_to_app_rounded,
                                  color: p.vermilionHazard,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      s.exitToMenuBtn,
                                      style: TextStyle(
                                        color: p.vermilionHazard,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: p.vermilionHazard.withAlpha(24),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: p.vermilionHazard,
                                width: 2.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  s.exitConfirmTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: p.vermilionHazard,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.exitConfirmSub,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: p.inkPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _PauseTactileButton(
                                        onTap: () {
                                          widget.game.audioHaptics.onButtonTap();
                                          setState(
                                            () => _confirmingExit = false,
                                          );
                                        },
                                        backgroundColor: p.paperCard,
                                        borderColor: p.inkPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 9,
                                        ),
                                        child: Center(
                                          child: Text(
                                            s.cancelBtn,
                                            style: TextStyle(
                                              color: p.inkPrimary,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _PauseTactileButton(
                                        onTap: () {
                                          widget.game.audioHaptics.onButtonTap();
                                          widget.game.returnToMainMenu();
                                        },
                                        backgroundColor: p.vermilionHazard,
                                        borderColor: p.inkPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 9,
                                        ),
                                        child: Center(
                                          child: Text(
                                            s.confirmExitBtn,
                                            style: TextStyle(
                                              color: p.onVermilionHazard,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorSwatchDot extends StatelessWidget {
  final Color color;
  final Color borderColor;

  const _ColorSwatchDot({
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
      ),
    );
  }
}

class _AudioToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final RisographPalette palette;
  final VoidCallback onChanged;

  const _AudioToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = value ? palette.matchaSafe : palette.inkSecondary;

    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: effectiveColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: palette.inkPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: value ? palette.matchaSafe : palette.paperCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: palette.inkPrimary,
                  width: 1.5,
                ),
              ),
              child: Text(
                value ? 'ON' : 'OFF',
                style: TextStyle(
                  color: value
                      ? palette.onMatchaSafe
                      : palette.inkSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseTactileButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _PauseTactileButton({
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 2.0,
    required this.padding,
    required this.child,
  });

  @override
  State<_PauseTactileButton> createState() => _PauseTactileButtonState();
}

class _PauseTactileButtonState extends State<_PauseTactileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: widget.borderColor,
              width: widget.borderWidth,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
