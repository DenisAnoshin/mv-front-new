import 'package:flutter/material.dart';
import '../theme/telegram_colors.dart';

class AudioMessage extends StatelessWidget {
  final int durationSec;
  final int sizeBytes;
  final bool isMine;
  final List<int> waveform; // 0..15 values

  const AudioMessage({super.key, required this.durationSec, required this.sizeBytes, required this.isMine, this.waveform = const <int>[]});

  String _formatDuration(int sec) {
    final int m = (sec ~/ 60);
    final int s = (sec % 60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    const int kb = 1024;
    const int mb = 1024 * 1024;
    if (bytes >= mb) {
      final double val = bytes / mb;
      return '${val.toStringAsFixed(1)} MB';
    }
    final double val = bytes / kb;
    return '${val.toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = isMine ? Colors.white : TelegramColors.primary;
    final Color accent = isMine ? Colors.white70 : const Color(0xFF90CAF9);

    // Fallback simple waveform if none provided
    final List<int> bars = waveform.isNotEmpty ? waveform : List<int>.generate(30, (i) => (i % 4 == 0) ? 14 : 8 + (i % 6));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: TelegramColors.primary, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.play_arrow, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (final h in bars)
                      Container(width: 3, height: (h.toDouble()).clamp(4.0, 18.0), margin: const EdgeInsets.symmetric(horizontal: 1.2), color: accent),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDuration(durationSec)}, ${_formatSize(sizeBytes)}',
                style: const TextStyle(fontSize: 12, color: TelegramColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}





