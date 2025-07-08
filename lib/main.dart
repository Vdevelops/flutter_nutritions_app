import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    runApp(MyApp(camera: firstCamera));
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Error initializing app: $e\n$stackTrace');
    }
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Nutrition Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF333333),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      home: SplashScreen(camera: camera),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child:
              Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
class SplashScreen extends StatefulWidget {
  final CameraDescription camera;
  const SplashScreen({super.key, required this.camera});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomePage(camera: widget.camera),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/logo.png',
                            width: 80, height: 80),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Food Nutrition Scanner',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Analyze your food with AI',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SpinKitPulse(
                        color: Theme.of(context).colorScheme.primary,
                        size: 40.0,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final CameraDescription camera;
  const HomePage({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        radius: 24,
                        child: Image.asset('assets/logo.png',
                            width: 30, height: 30),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Food Scanner',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Analyze your meals',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Discover the nutritional value of your food',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What would you like to do?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(
                      context,
                      title: 'Scan Food',
                      description: 'Take a photo to analyze your food',
                      icon: Icons.camera_alt_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraPage(camera: camera),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      context,
                      title: 'About',
                      description: 'Learn how the app works',
                      icon: Icons.info_outline_rounded,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => _buildAboutModal(context),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutModal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'About Food Scanner',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This application uses AI to identify food from photos and provide nutritional information. The app analyzes the image, identifies the food item, and fetches nutritional data from the Nutritionix API.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  final CameraDescription camera;
  const CameraPage({super.key, required this.camera});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late AnimationController _flashAnimationController;
  bool _isProcessing = false;
  Interpreter? _interpreter;
  List<String>? _labels;
  List<Map<String, dynamic>>? _foodMapping;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    _loadModel();
    _loadLabels();
    _loadFoodMapping();

    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _flashAnimationController.dispose();
    _controller.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/food_classifier.tflite');
      _interpreter!.allocateTensors();
      if (kDebugMode) {
        print('Model loaded successfully.');
        print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
        print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error loading model: $e\n$stackTrace');
      }
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData =
          await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      if (kDebugMode) {
        print('Labels loaded: ${_labels?.length}');
        print('Labels: $_labels');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error loading labels: $e\n$stackTrace');
      }
    }
  }

  Future<void> _loadFoodMapping() async {
    try {
      final csvData = await DefaultAssetBundle.of(context)
          .loadString('assets/food_mapping.csv');
      final List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvData);
      _foodMapping = csvTable.skip(1).map((row) {
        final isHealthyRaw = row[1].toString().trim().toLowerCase();
        final isHealthy = isHealthyRaw == 'true' || isHealthyRaw == '1';
        return <String, dynamic>{
          'food_name': row[0].toString().trim(),
          'is_healthy': isHealthy,
          'nutritionix_query': row[2].toString().trim(),
        };
      }).toList();
      if (kDebugMode) {
        print('Food mapping loaded: ${_foodMapping?.length}');
        print('Food mapping: $_foodMapping');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error loading food mapping: $e\n$stackTrace');
      }
    }
  }

  bool _determineHealthiness(
      Map<String, dynamic>? nutritionData, bool fallbackIsHealthy) {
    if (nutritionData == null) {
      if (kDebugMode) {
        print(
            'No nutrition data available, using fallback is_healthy: $fallbackIsHealthy');
      }
      return fallbackIsHealthy;
    }

    // Normalkan data nutrisi ke per 100g jika serving_qty dan serving_unit tersedia
    double servingWeight =
        nutritionData['serving_weight_grams']?.toDouble() ?? 100.0;
    double calories =
        (nutritionData['calories']?.toDouble() ?? 0) * 100 / servingWeight;
    double fat = (nutritionData['fat']?.toDouble() ?? 0) * 100 / servingWeight;
    double carbs =
        (nutritionData['carbs']?.toDouble() ?? 0) * 100 / servingWeight;
    double protein =
        (nutritionData['protein']?.toDouble() ?? 0) * 100 / servingWeight;

    if (kDebugMode) {
      print(
          'Normalized nutrition (per 100g): calories=$calories, fat=$fat, carbs=$carbs, protein=$protein');
    }

    // Kriteria kesehatan
    int healthScore = 0;
    if (calories < 200) healthScore++;
    if (fat < 10) healthScore++;
    if (carbs < 30) healthScore++;
    if (protein >= 5) healthScore++;

    // Makanan sehat jika memenuhi setidaknya 3 dari 4 kriteria
    bool isHealthy = healthScore >= 3;

    if (kDebugMode) {
      print('Health score: $healthScore/4, is_healthy: $isHealthy');
    }

    return isHealthy;
  }

  Future<Map<String, dynamic>?> _classifyImage(XFile image) async {
    if (_interpreter == null || _labels == null || _foodMapping == null) {
      if (kDebugMode) {
        print(
            'Classifier not ready: interpreter=$_interpreter, labels=$_labels, foodMapping=$_foodMapping');
      }
      return null;
    }
    try {
      // Baca dan decode gambar
      final imageBytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        if (kDebugMode) {
          print('Failed to decode image');
        }
        return null;
      }

      // Resize gambar ke 224x224
      final resizedImage =
          img.copyResize(decodedImage, width: 224, height: 224);

      // Cetak bentuk input model untuk debugging
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      if (kDebugMode) {
        print('Model expects input shape: $inputShape');
        print('Model output shape: $outputShape');
      }

      // Buat input dengan bentuk [1, 224, 224, 3]
      final input = List.generate(
        1,
        (_) => List.generate(
          224,
          (_) => List.generate(
            224,
            (_) => List.filled(3, 0.0),
          ),
        ),
      );

      // Isi data piksel dengan normalisasi [-1, 1]
      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[0][y][x][0] = (pixel.r / 255.0 - 0.5) / 0.5; // R
          input[0][y][x][1] = (pixel.g / 255.0 - 0.5) / 0.5; // G
          input[0][y][x][2] = (pixel.b / 255.0 - 0.5) / 0.5; // B
        }
      }

      // Debugging: Cetak dimensi input
      if (kDebugMode) {
        print('Input dimensions: ${input.length}');
        print('Input[0] dimensions: ${input[0].length}');
        print('Input[0][0] dimensions: ${input[0][0].length}');
        print('Input[0][0][0] dimensions: ${input[0][0][0].length}');
      }

      // Buat buffer output sesuai jumlah kelas
      final output = List.generate(1, (_) => List.filled(_labels!.length, 0.0));

      // Jalankan inferensi
      _interpreter!.run(input, output);

      // Proses hasil
      final maxScore = output[0].reduce((a, b) => a > b ? a : b);
      final maxIndex = output[0].indexOf(maxScore);
      final predictedLabel = _labels![maxIndex];

      // Debugging: Cetak semua skor untuk top 3 prediksi
      final scoresWithIndices = output[0].asMap().entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (kDebugMode) {
        print('Top 3 predictions:');
        for (var i = 0; i < 3 && i < scoresWithIndices.length; i++) {
          print(
              'Label: ${_labels![scoresWithIndices[i].key]}, Score: ${scoresWithIndices[i].value}');
        }
      }

      // Ambang batas untuk kepercayaan
      const confidenceThreshold = 0.5;
      if (maxScore < confidenceThreshold) {
        if (kDebugMode) {
          print('Confidence too low: $maxScore < $confidenceThreshold');
        }
        return {
          'food_name': 'Unknown',
          'is_healthy': false,
          'confidence': maxScore,
          'nutritionix_query': 'unknown',
        };
      }

      final foodInfo = _foodMapping!.firstWhere(
        (map) => map['food_name'].toLowerCase() == predictedLabel.toLowerCase(),
        orElse: () => <String, dynamic>{
          'food_name': predictedLabel,
          'is_healthy': false,
          'nutritionix_query': predictedLabel,
        },
      );

      if (kDebugMode) {
        print('Predicted label: $predictedLabel');
        print('Food mapping entry: $foodInfo');
      }

      // Ambil data nutrisi
      final nutritionData =
          await _getNutritionData(foodInfo['nutritionix_query']);

      // Tentukan status kesehatan berdasarkan data nutrisi
      final isHealthy =
          _determineHealthiness(nutritionData, foodInfo['is_healthy'] as bool);

      if (kDebugMode) {
        print(
            'Classification result: {food_name: ${foodInfo['food_name']}, is_healthy: $isHealthy, confidence: $maxScore, nutrition_data: $nutritionData}');
      }

      return {
        'food_name': foodInfo['food_name'],
        'is_healthy': isHealthy,
        'confidence': maxScore,
        'nutritionix_query': foodInfo['nutritionix_query'],
        'nutrition_data': nutritionData,
      };
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error classifying image: $e\n$stackTrace');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getNutritionData(String query) async {
    final String _nutritionixAppId = 'e2136996';
    final String _nutritionixApiKey = '54aa150d987947fcb9fe041cbc71b816';
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'nutrition_$query';
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      return jsonDecode(cachedData);
    }

    try {
      final response = await http.post(
        Uri.parse('https://trackapi.nutritionix.com/v2/natural/nutrients'),
        headers: {
          'x-app-id': _nutritionixAppId,
          'x-app-key': _nutritionixApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nutritionData = {
          'calories': data['foods'][0]['nf_calories'] ?? 0,
          'protein': data['foods'][0]['nf_protein'] ?? 0,
          'fat': data['foods'][0]['nf_total_fat'] ?? 0,
          'carbs': data['foods'][0]['nf_total_carbohydrate'] ?? 0,
          'serving_qty': data['foods'][0]['serving_qty'] ?? 1,
          'serving_unit': data['foods'][0]['serving_unit'] ?? 'serving',
          'serving_weight_grams':
              data['foods'][0]['serving_weight_grams'] ?? 100,
        };
        await prefs.setString(cacheKey, jsonEncode(nutritionData));
        if (kDebugMode) {
          print('Nutrition data for $query: $nutritionData');
        }
        return nutritionData;
      } else {
        if (kDebugMode) {
          print('Nutrition API error: ${response.statusCode} ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error fetching nutrition data: $e\n$stackTrace');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan Food'),
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CameraPreview(_controller),
                    // Flash animation overlay
                    AnimatedBuilder(
                      animation: _flashAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _flashAnimationController.value,
                          child: Container(
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    // Camera guide frame
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isProcessing)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Analyzing...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Camera error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Initializing camera...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          // Camera instructions
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Center the food in the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isProcessing
          ? null
          : Container(
              height: 80.0,
              width: 80.0,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: _isProcessing
                    ? null
                    : () async {
                        setState(() {
                          _isProcessing = true;
                        });

                        try {
                          // Flash animation
                          _flashAnimationController.forward();
                          await Future.delayed(
                              const Duration(milliseconds: 100));
                          _flashAnimationController.reverse();

                          await _initializeControllerFuture;
                          final image = await _controller.takePicture();
                          final result = await _classifyImage(image);

                          setState(() {
                            _isProcessing = false;
                          });

                          if (result != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultPage(
                                  imagePath: image.path,
                                  result: result,
                                  nutritionData: result['nutrition_data']
                                      as Map<String, dynamic>?,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to classify image')),
                            );
                          }
                        } catch (e, stackTrace) {
                          setState(() {
                            _isProcessing = false;
                          });
                          if (kDebugMode) {
                            print('Error taking picture: $e\n$stackTrace');
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                elevation: 5,
                child: Icon(
                  Icons.camera_alt,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String imagePath;
  final Map<String, dynamic> result;
  final Map<String, dynamic>? nutritionData;

  const ResultPage({
    super.key,
    required this.imagePath,
    required this.result,
    this.nutritionData,
  });

  Map<String, dynamic> calculateHealthScore() {
    // Default return if no nutrition data available
    if (nutritionData == null) {
      return {
        'isHealthy': result['is_healthy'],
        'healthScore': 0,
        'details': [
          'No nutrition data available'
        ] // Ubah menjadi list dengan 1 element
      };
    }

    // Extract nutrition values
    final calories = nutritionData!['calories'] as num;
    final protein = nutritionData!['protein'] as num;
    final fat = nutritionData!['fat'] as num;
    final carbs = nutritionData!['carbs'] as num;

    // Calculate macronutrient calories
    final proteinCalories = protein * 4; // 4 calories per gram of protein
    final fatCalories = fat * 9; // 9 calories per gram of fat
    final carbCalories = carbs * 4; // 4 calories per gram of carbs

    // Calculate percentages of macronutrients
    final proteinPercentage =
        calories > 0 ? (proteinCalories / calories) * 100 : 0;
    final fatPercentage = calories > 0 ? (fatCalories / calories) * 100 : 0;
    final carbPercentage = calories > 0 ? (carbCalories / calories) * 100 : 0;

    // Initialize score and details
    int score = 0;
    List<String> details = [];

    // Protein score
    if (proteinPercentage >= 20) {
      score += 3;
      details.add(
          'High protein content (${proteinPercentage.toStringAsFixed(1)}%)');
    } else if (proteinPercentage >= 12) {
      score += 2;
      details.add(
          'Moderate protein content (${proteinPercentage.toStringAsFixed(1)}%)');
    } else {
      score -= 1;
      details.add(
          'Low protein content (${proteinPercentage.toStringAsFixed(1)}%)');
    }

    // Fat score
    if (fatPercentage > 40) {
      score -= 2;
      details.add('High fat content (${fatPercentage.toStringAsFixed(1)}%)');
    } else if (fatPercentage > 35) {
      score -= 1;
      details.add(
          'Moderately high fat content (${fatPercentage.toStringAsFixed(1)}%)');
    } else if (fatPercentage < 10) {
      score += 1;
      details.add('Low fat content (${fatPercentage.toStringAsFixed(1)}%)');
    } else {
      score += 2;
      details
          .add('Balanced fat content (${fatPercentage.toStringAsFixed(1)}%)');
    }

    // Carbs evaluation
    if (carbPercentage > 70) {
      score -= 1;
      details.add('High carb content (${carbPercentage.toStringAsFixed(1)}%)');
    } else if (carbPercentage >= 20 && carbPercentage <= 50) {
      score += 1;
      details
          .add('Balanced carb content (${carbPercentage.toStringAsFixed(1)}%)');
    }

    // Calorie density evaluation
    if (calories > 400) {
      score -= 1;
      details.add('High calorie content (${calories.toInt()} kcal)');
    } else if (calories < 150) {
      score += 1;
      details.add('Low calorie content (${calories.toInt()} kcal)');
    }

    // Determine if the food is healthy based on score
    final isHealthy = score >= 2;

    return {'isHealthy': isHealthy, 'healthScore': score, 'details': details};
  }

  @override
  Widget build(BuildContext context) {
    final healthAssessment = calculateHealthScore();
    final isHealthy = healthAssessment['isHealthy'] as bool;
    final healthScore = healthAssessment['healthScore'] as int;
    final details = healthAssessment['details'] as List<String>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Food Analysis'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food image with gradient overlay
            Stack(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    result['food_name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Health status card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        isHealthy ? Colors.green.shade100 : Colors.red.shade100,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isHealthy
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isHealthy ? Icons.check_circle : Icons.warning,
                              color: isHealthy ? Colors.green : Colors.red,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHealthy
                                      ? 'Healthy Choice'
                                      : 'Less Healthy Choice',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isHealthy ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  'Health Score: $healthScore',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: isHealthy ? Colors.green : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                healthScore.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isHealthy ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        ...details.map((detail) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      detail,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Nutrition facts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition Facts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (nutritionData != null) ...[
                    _buildNutritionRow(
                      'Calories',
                      '${nutritionData!['calories']} kcal',
                      Icons.local_fire_department_outlined,
                      Colors.orange,
                    ),
                    _buildNutritionRow(
                      'Protein',
                      '${nutritionData!['protein']} g',
                      Icons.fitness_center_outlined,
                      Colors.red,
                    ),
                    _buildNutritionRow(
                      'Carbs',
                      '${nutritionData!['carbs']} g',
                      Icons.grain_outlined,
                      Colors.brown,
                    ),
                    _buildNutritionRow(
                      'Fat',
                      '${nutritionData!['fat']} g',
                      Icons.opacity_outlined,
                      Colors.yellow[800]!,
                    ),
                    _buildNutritionRow(
                      'Serving Size',
                      '${nutritionData!['serving_qty']} ${nutritionData!['serving_unit']} (${nutritionData!['serving_weight_grams']} g)',
                      Icons.scale_outlined,
                      Colors.blue,
                    ),
                  ] else
                    Card(
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No nutrition data available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Confidence indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detection Confidence',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: result['confidence'] as double,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(result['confidence'] * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
