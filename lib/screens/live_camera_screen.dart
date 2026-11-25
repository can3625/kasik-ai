import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/food_analysis_model.dart';

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  String? _error;
  FoodAnalysisResponse? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() => _error = 'Kamera bulunamadı.');
        return;
      }

      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Kamera başlatılamadı: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isAnalyzing) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
    });

    try {
      final picture = await _cameraController!.takePicture();
      final response = await ApiService.analyzeFood(File(picture.path));

      if (!mounted) return;

      setState(() {
        _result = response;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Analiz başarısız: $e';
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isAnalyzing) return;

    final currentDirection = _cameraController?.description.lensDirection;
    final newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != currentDirection,
      orElse: () => _cameras.first,
    );

    await _cameraController?.dispose();

    final controller = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Kamera değiştirilemedi: $e';
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _cameraController = null;
      _isCameraInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Widget _buildResult() {
    final result = _result;

    if (result == null) return const SizedBox.shrink();

    if (result.status == FoodStatus.error || result.status == FoodStatus.not_food) {
      return Card(
        margin: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            result.message ?? 'Yemek algılanamadı veya bir hata oluştu.',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.foodName ?? 'Bilinmeyen Yemek',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (result.nutritionEstimate != null) ...[
              Text('Kalori: ${result.nutritionEstimate!.energyKcal ?? "Bilinmiyor"} kcal'),
              Text('Protein: ${result.nutritionEstimate!.proteinG ?? "Bilinmiyor"} g'),
              Text('Karbonhidrat: ${result.nutritionEstimate!.carbsG ?? "Bilinmiyor"} g'),
              Text('Yağ: ${result.nutritionEstimate!.fatG ?? "Bilinmiyor"} g'),
            ],
            const SizedBox(height: 12),
            if (result.portion != null) ...[
              const Text(
                'Tahmini Ölçü',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• ${result.portion!.amount} ${result.portion!.unit}'),
            ],
            if (result.message != null) ...[
              const SizedBox(height: 8),
              Text(result.message!),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KaşıkAI Canlı Kamera'),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Kamerayı değiştir',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _error != null && !_isCameraInitialized
                ? Center(child: Text(_error!))
                : _isCameraInitialized && _cameraController != null
                    ? CameraPreview(_cameraController!)
                    : const Center(child: CircularProgressIndicator()),
          ),
          if (_error != null && _isCameraInitialized)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isAnalyzing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Yemeğiniz analiz ediliyor...'),
                ],
              ),
            ),
          if (_result != null)
            Expanded(
              child: SingleChildScrollView(child: _buildResult()),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCameraInitialized && !_isAnalyzing
                    ? _takePicture
                    : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Yemeği Analiz Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
