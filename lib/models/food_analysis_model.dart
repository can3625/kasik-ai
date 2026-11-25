class UserProfile {
  final int? age;
  final double? weight;
  final double? height;

  UserProfile({this.age, this.weight, this.height});
}

enum FoodStatus { success, not_food, uncertain, error }

class FoodPortion {
  final String? name;
  final double amount;
  final String unit;

  FoodPortion({this.name, required this.amount, required this.unit});

  factory FoodPortion.fromJson(Map<String, dynamic> json) {
    return FoodPortion(
      name: json['name'] as String?,
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
      energyKcal: ((json['energy_kcal'] ?? json['calories']) as num?)?.toDouble(),
      proteinG: ((json['protein_g'] ?? json['protein']) as num?)?.toDouble(),
      carbsG: ((json['carbs_g'] ?? json['carbohydrates']) as num?)?.toDouble(),
      fatG: ((json['fat_g'] ?? json['fat']) as num?)?.toDouble(),
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
      final rawStatus = json['status'] as String?;
      final parsedStatus = rawStatus != null
          ? parseStatus(rawStatus)
          : (json['food_name'] != null ? FoodStatus.success : FoodStatus.error);

      FoodPortion? parsedPortion;
      if (json['portion'] is Map<String, dynamic>) {
        parsedPortion = FoodPortion.fromJson(json['portion'] as Map<String, dynamic>);
      } else if (json['portions'] is List && (json['portions'] as List).isNotEmpty) {
        final firstPortion = (json['portions'] as List).first;
        if (firstPortion is Map<String, dynamic>) {
          parsedPortion = FoodPortion.fromJson(firstPortion);
        }
      }

      NutritionEstimate? parsedNutrition;
      if (json['nutrition_estimate'] is Map<String, dynamic>) {
        parsedNutrition = NutritionEstimate.fromJson(json['nutrition_estimate'] as Map<String, dynamic>);
      } else if (json['nutrition'] is Map<String, dynamic>) {
        parsedNutrition = NutritionEstimate.fromJson(json['nutrition'] as Map<String, dynamic>);
      }

      return FoodAnalysisResponse(
        status: parsedStatus,
        message: json['message'] as String?,
        foodName: json['food_name'] as String?,
        portion: parsedPortion,
        confidence: (json['confidence'] as num?)?.toDouble(),
        nutritionEstimate: parsedNutrition,
      );
    } catch (_) {
      return FoodAnalysisResponse(
        status: FoodStatus.error,
        message: 'Gelen veriler işlenirken hata oluştu.',
      );
    }
  }
}
