import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/drawing_submission.dart';

/// Service for drawing submission and evaluation.
class DrawingService {
  final String baseUrl;
  final String Function() getToken;

  DrawingService({required this.baseUrl, required this.getToken});

  /// Check the initialization status of the AI model on the backend.
  Future<Map<String, dynamic>> checkAiStatus() async {
    final uri = Uri.parse('$baseUrl/api/drawings/ai-status');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body);
    if (data['success'] != true) throw Exception(data['error']?['message'] ?? 'Failed to fetch AI status');
    return data['data'] as Map<String, dynamic>;
  }

  /// Submit a drawing for multiplayer AI evaluation.
  /// Returns immediately after upload. Results come via socket events.
  Future<DrawingResult> submitDrawing({
    required String gameId,
    required Uint8List drawingBytes,
  }) async {
    try {
      debugPrint('[DrawingService] Submitting drawing for game $gameId (${drawingBytes.length} bytes)');
      final uri = Uri.parse('$baseUrl/api/drawings/submit');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${getToken()}'
        ..fields['gameId'] = gameId
        ..files.add(http.MultipartFile.fromBytes(
          'drawing',
          drawingBytes,
          filename: 'drawing.png',
          contentType: MediaType('image', 'png'),
        ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[DrawingService] Submit response: ${response.statusCode}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint('[DrawingService] Drawing submitted successfully. allSubmitted=${data['data']?['allSubmitted']}');
        return DrawingResult.fromJson(data['data']);
      } else {
        final errorMsg = data['error']?['message'] ?? 'Failed to submit drawing';
        debugPrint('[DrawingService] Submit failed: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[DrawingService] Submission error: $e');
      rethrow;
    }
  }

  /// Retry AI evaluation for a multiplayer game using already-stored drawings.
  /// Does NOT require re-uploading the drawing.
  Future<void> retryEvaluation({required String gameId}) async {
    try {
      debugPrint('[DrawingService] Retrying evaluation for game $gameId');
      final uri = Uri.parse('$baseUrl/api/drawings/retry-evaluation');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${getToken()}',
        },
        body: jsonEncode({'gameId': gameId}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint('[DrawingService] Retry evaluation started successfully');
      } else {
        final errorMsg = data['error']?['message'] ?? 'Failed to retry evaluation';
        debugPrint('[DrawingService] Retry failed: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[DrawingService] Retry evaluation error: $e');
      rethrow;
    }
  }

  /// Evaluate a solo drawing for practice mode.
  /// Throws on failure — NEVER returns fabricated scores.
  Future<DrawingResult> evaluateSoloDrawing({
    required String prompt,
    required Uint8List drawingBytes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/drawings/evaluate-solo');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${getToken()}'
        ..fields['prompt'] = prompt
        ..files.add(http.MultipartFile.fromBytes(
          'drawing',
          drawingBytes,
          filename: 'drawing.png',
          contentType: MediaType('image', 'png'),
        ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return DrawingResult.fromJson(data['data']);
      } else {
        final errorMsg = data['error']?['message'] ?? 'AI evaluation failed';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[DrawingService] Solo evaluation error: $e');
      rethrow;
    }
  }

  /// Get all drawings and rankings for a completed game.
  Future<Map<String, dynamic>> getGameDrawings(String gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/drawings/$gameId'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return data['data'];
  }

  /// Analyze intermediate drawing for live AI assistant tips.
  Future<Map<String, dynamic>> analyzeLiveDrawing({
    required String prompt,
    required Uint8List drawingBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/drawings/analyze');
    final request = http.MultipartRequest('POST', uri)
      ..fields['prompt'] = prompt
      ..files.add(http.MultipartFile.fromBytes(
        'drawing',
        drawingBytes,
        filename: 'canvas.png',
        contentType: MediaType('image', 'png'),
      ));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception('Failed to analyze sketch');
    return data['data'] as Map<String, dynamic>;
  }
}
