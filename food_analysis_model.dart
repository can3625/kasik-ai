class UserProfile {
  final int? age;
  final double? weight;
  final double? height;

  UserProfile({this.age, this.weight, this.height});
}

enum FoodStatus { success, not_food, uncertain, error }

class FoodPortion {
  final double amount;
  final String unit;

  FoodPortion({required this.amount, required this.unit});

  factory FoodPortion.fromJson(Map<String, dynamic> json) {
    return FoodPortion(
      amount: (json['amount'] as num?)?.toDouble() ?? 1.0,
      unit: (json['unit'] as String?) ?? 'porsiyon',
    );
  }
}

class NutritionEstimate {
  final double? energyKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  NutritionEstimate({
    this.energyKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  factory NutritionEstimate.fromJson(Map<String, dynamic> json) {
    return NutritionEstimate(
      energyKcal: (json['energy_kcal'] as num?)?.toDouble(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
    );
  }
}

class FoodAnalysisResponse {
  final FoodStatus status;
  final String? message;
  final String? foodName;
  final FoodPortion? portion;
  final double? confidence;
  final NutritionEstimate? nutritionEstimate;

  FoodAnalysisResponse({
    required this.status,
    this.message,
    this.foodName,
    this.portion,
    this.confidence,
    this.nutritionEstimate,
  });

  factory FoodAnalysisResponse.fromJson(Map<String, dynamic> json) {
    FoodStatus parseStatus(String? statusStr) {
      switch (statusStr) {
        case 'success':
          return FoodStatus.success;
        case 'not_food':
          return FoodStatus.not_food;
        case 'uncertain':
          return FoodStatus.uncertain;
        default:
          return FoodStatus.error;
      }
    }

    try {
      return FoodAnalysisResponse(
        status: parseStatus(json['status'] as String?),
        message: json['message'] as String?,
        foodName: json['food_name'] as String?,
        portion: json['portion'] != null && json['portion'] is Map<String, dynamic>
            ? FoodPortion.fromJson(json['portion'] as Map<String, dynamic>)
            : null,
        confidence: (json['confidence'] as num?)?.toDouble(),
        nutritionEstimate: json['nutrition_estimate'] != null && json['nutrition_estimate'] is Map<String, dynamic>
            ? NutritionEstimate.fromJson(json['nutrition_estimate'] as Map<String, dynamic>)
            : null,
      );
    } catch (_) {
      return FoodAnalysisResponse(
        status: FoodStatus.error,
        message: 'Gelen veriler işlenirken hata oluştu.',
      );
    }
  }
}
