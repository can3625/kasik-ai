import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/food_analysis_model.dart';

class ApiService {
  static const String baseUrl = 'https://kasik-ai-backend.onrender.com';

  static Future<FoodAnalysisResponse> analyzeFood(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'));
      
      int length = await imageFile.length();
      if (length > 5 * 1024 * 1024) {
        return FoodAnalysisResponse(
          status: FoodStatus.error,
          message: 'Dosya boyutu 5 MB sınırını aşmaktadır.',
        );
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 75),
        onTimeout: () {
          throw TimeoutException('İstek zaman aşımına uğradı.');
        },
      );

      var response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Yanıt okunurken zaman aşımı oluştu.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return FoodAnalysisResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        return FoodAnalysisResponse(
          status: FoodStatus.error,
          message: 'Geçersiz istek veya desteklenmeyen dosya.',
        );
      } else if (response.statusCode == 429) {
        return FoodAnalysisResponse(
          status: FoodStatus.error,
          message: 'Çok fazla istek gönderildi. Lütfen biraz bekleyin.',
        );
      } else if (response.statusCode >= 500) {
        return FoodAnalysisResponse(
          status: FoodStatus.error,
          message: 'Sunucu tarafında bir hata oluştu. Lütfen tekrar deneyin.',
        );
      } else {
        return FoodAnalysisResponse(
          status: FoodStatus.error,
          message: 'Beklenmeyen sunucu yanıtı: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      return FoodAnalysisResponse(
        status: FoodStatus.error,
        message: 'Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.',
      );
    } on SocketException {
      return FoodAnalysisResponse(
        status: FoodStatus.error,
        message: 'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.',
      );
    } catch (e) {
      return FoodAnalysisResponse(
        status: FoodStatus.error,
        message: 'Bağlantı kurulamadı.',
      );
    }
  }
}
