import 'dart:async';
import 'package:flutter/material.dart';

/// Servizio di Monetizzazione non invasiva:
/// 1. Rewarded Video Ad per:
///    - "Riparti con Scudo" dal metro in cui sei caduto (1 volta a partita)
///    - "+1 Tentativo Ufficiale" quando esaurisci i 3 tentativi del giorno
/// 2. Singolo In-App Purchase ("Versione Pro") che rimuove l'attesa dei video.
class MonetizationService {
  bool isAdReady = true;

  Future<bool> showRewardedAd({
    required BuildContext context,
    required String rewardTitle,
    required bool isProUnlocked,
  }) async {
    if (isProUnlocked) {
      return true;
    }

    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SimulatedRewardedAdDialog(rewardTitle: rewardTitle),
    );

    return completed ?? false;
  }
}

class _SimulatedRewardedAdDialog extends StatefulWidget {
  final String rewardTitle;
  const _SimulatedRewardedAdDialog({required this.rewardTitle});

  @override
  State<_SimulatedRewardedAdDialog> createState() =>
      _SimulatedRewardedAdDialogState();
}

class _SimulatedRewardedAdDialogState
    extends State<_SimulatedRewardedAdDialog> {
  int _secondsLeft = 2;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E1E24), width: 2.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VIDEO PREMIO • SECONDA CHANCE',
                style: TextStyle(
                  color: Color(0xFFF4EFE6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.rewardTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E1E24),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '(Simulazione rapida: in produzione mostra un RewardedAd AdMob)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B665E), fontSize: 11.5),
            ),
            const SizedBox(height: 18),
            if (_secondsLeft > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF1D3557),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Bonus pronto tra $_secondsLeft s...',
                      style: const TextStyle(
                        color: Color(0xFF1E1E24),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Color(0xFF1E1E24),
                        width: 2,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'RISCATTA BONUS E CONTINUA',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Annulla',
                style: TextStyle(color: Color(0xFF6B665E), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
