import 'package:flutter/material.dart';

class NutritionPlanCard extends StatelessWidget {
  final String calories;
  final String protein;
  final String water;
  final String bmi;

  const NutritionPlanCard({
    super.key,
    required this.calories,
    required this.protein,
    required this.water,
    required this.bmi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Calories', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 6),
              Text(
                calories,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Protein', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 6),
              Text(
                protein,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Water', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 6),
              Text(
                water,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BMI', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 6),
              Text(
                bmi,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
