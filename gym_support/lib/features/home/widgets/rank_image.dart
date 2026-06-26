import 'package:flutter/material.dart';

/// Widget để hiển thị rank/tier image từ assets
class RankImage extends StatelessWidget {
  final String tier;
  final double size;
  final bool isSelected;

  const RankImage({
    super.key,
    required this.tier,
    this.size = 100,
    this.isSelected = false,
  });

  String _getRankAssetPath(String tier) {
    final tierLower = tier.toLowerCase();

    switch (tierLower) {
      case 'iron':
        return 'assets/images/ranks/rank_iron.png';
      case 'bronze':
        return 'assets/images/ranks/rank_bronze.png';
      case 'silver':
        return 'assets/images/ranks/rank_silver.png';
      case 'gold':
        return 'assets/images/ranks/rank_gold.png';
      case 'platinum':
        return 'assets/images/ranks/rank_platinum.png';
      case 'diamond':
        return 'assets/images/ranks/rank_diamond.png';
      case 'champion':
      case 'legend':
        return 'assets/images/ranks/rank_legend.png';
      default:
        return 'assets/images/ranks/rank_iron.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.9,
        duration: const Duration(milliseconds: 300),
        child: Image.asset(
          _getRankAssetPath(tier),
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
