import 'package:flutter/material.dart';
import 'ers_models.dart';

class ERSPercentileWidget extends StatelessWidget {
  final ERSResult ersResult;
  final String ageGroup;

  const ERSPercentileWidget({
    super.key,
    required this.ersResult,
    required this.ageGroup,
  });

  Color get _riskColor => switch (ersResult.riskLevel) {
    'red' => const Color(0xFFD14343),
    'yellow' => const Color(0xFFF5A623),
    _ => const Color(0xFF0ABFBC),
  };

  @override
  Widget build(BuildContext context) {
    final score = ersResult.adjustedERS;
    final percentile = _calculatePercentile(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _riskColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ersResult.riskLabel,
                  style: TextStyle(
                    color: _riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'ERS ${score.toStringAsFixed(0)}',
                style: TextStyle(
                  color: _riskColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_riskColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '你的心理負荷感高於$ageGroup同齡者的 $percentile%',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StreamBadge('語言', ersResult.streamScores['language'] ?? 0),
              const SizedBox(width: 8),
              _StreamBadge('生理', ersResult.streamScores['physical'] ?? 0),
              const SizedBox(width: 8),
              _StreamBadge('行為', ersResult.streamScores['behavior'] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  int _calculatePercentile(double score) {
    if (score >= 90) return 95;
    if (score >= 70) return 80;
    if (score >= 50) return 60;
    if (score >= 30) return 35;
    return 15;
  }
}

class _StreamBadge extends StatelessWidget {
  final String label;
  final double score;

  const _StreamBadge(this.label, this.score);

  Color get _color {
    if (score >= 70) return const Color(0xFFD14343);
    if (score >= 45) return const Color(0xFFF5A623);
    return const Color(0xFF0ABFBC);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: _color, fontSize: 12)),
            Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
