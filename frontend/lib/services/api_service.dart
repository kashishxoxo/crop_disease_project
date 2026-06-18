import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/prediction_model.dart';

class ApiService {
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');
  static const Duration _predictionTimeout = Duration(seconds: 18);
  static const Duration _standardTimeout = Duration(seconds: 12);
  static String? _lastSuccessfulBaseUrl;

  // Default order: current laptop LAN IP, hostname, emulator, then loopback fallbacks.
  static const List<String> _fallbackBaseUrls = [
    'http://192.168.18.198:5000',
    'http://10.186.59.219:5000',
    'http://192.168.18.159:5000',
    'http://Kashishs-Macbook-Air.local:5000',
    'http://192.168.18.224:5000',
    'http://192.168.18.8:5000',
    'http://10.0.2.2:5000',
    'http://127.0.0.1:5000',
  ];

  static List<String> get _baseUrls {
    final ordered = <String>[
      if (_lastSuccessfulBaseUrl != null &&
          _lastSuccessfulBaseUrl!.trim().isNotEmpty)
        _lastSuccessfulBaseUrl!.trim(),
      if (_configuredBaseUrl.trim().isNotEmpty) _configuredBaseUrl.trim(),
      ..._fallbackBaseUrls,
    ];
    return ordered.toSet().toList();
  }

  static Future<PredictionModel> predictDisease(
    File imageFile, {
    String? uid,
  }) async {
    Object? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/predict'),
        );
        request.files
            .add(await http.MultipartFile.fromPath('image', imageFile.path));
        if (uid != null && uid.isNotEmpty) {
          request.fields['uid'] = uid;
        }

        final response = await request.send().timeout(_predictionTimeout);
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode != 200) {
          throw HttpException('Prediction failed (${response.statusCode})');
        }

        final Map<String, dynamic> data =
            jsonDecode(responseBody) as Map<String, dynamic>;
        _lastSuccessfulBaseUrl = baseUrl;
        return PredictionModel.fromJson(data);
      } on SocketException catch (e) {
        lastError = e;
        continue;
      } on TimeoutException catch (e) {
        lastError = e;
        continue;
      }
    }
    throw lastError ?? const SocketException('Backend unreachable.');
  }

  static Future<Map<String, dynamic>> getVoiceAdvisory({
    required String transcript,
    String? uid,
  }) async {
    Object? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/voice-advisory'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'transcript': transcript,
                if (uid != null && uid.isNotEmpty) 'uid': uid,
              }),
            )
            .timeout(_standardTimeout);

        if (response.statusCode != 200) {
          throw HttpException('Voice advisory failed (${response.statusCode})');
        }

        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        _lastSuccessfulBaseUrl = baseUrl;
        return data;
      } on SocketException catch (e) {
        lastError = e;
        continue;
      } on TimeoutException catch (e) {
        lastError = e;
        continue;
      }
    }
    throw lastError ?? const SocketException('Backend unreachable.');
  }

  static Future<Map<String, dynamic>> getOutbreakRisk({
    required String uid,
    Map<String, dynamic>? weather,
    String? soilType,
  }) async {
    Object? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/outbreak-risk'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'uid': uid,
                if (weather != null) 'weather': weather,
                if (soilType != null && soilType.trim().isNotEmpty)
                  'soil_type': soilType.trim(),
              }),
            )
            .timeout(_standardTimeout);

        if (response.statusCode != 200) {
          throw HttpException('Outbreak risk failed (${response.statusCode})');
        }

        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        _lastSuccessfulBaseUrl = baseUrl;
        return data;
      } on SocketException catch (e) {
        lastError = e;
        continue;
      } on TimeoutException catch (e) {
        lastError = e;
        continue;
      }
    }
    throw lastError ?? const SocketException('Backend unreachable.');
  }

  static Future<Map<String, dynamic>> verifyReportRecord({
    required String uid,
    required String recordId,
  }) async {
    Object? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/verify-record'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'uid': uid, 'record_id': recordId}),
            )
            .timeout(_standardTimeout);

        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode != 200) {
          throw HttpException(data['reason']?.toString() ??
              data['error']?.toString() ??
              'Verify record failed (${response.statusCode})');
        }
        _lastSuccessfulBaseUrl = baseUrl;
        return data;
      } on SocketException catch (e) {
        lastError = e;
        continue;
      } on TimeoutException catch (e) {
        lastError = e;
        continue;
      }
    }
    throw lastError ?? const SocketException('Backend unreachable.');
  }
}
