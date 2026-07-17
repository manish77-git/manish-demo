import 'dart:convert';
import 'dart:typed_data';
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
    final response = await http.get(uri);
    final data = jsonDecode(response.body);
    if (data['success'] != true) throw Exception('Failed to fetch AI status');
    return data['data'] as Map<String, dynamic>;
  }

  /// Submit a drawing for AI evaluation.
  Future<DrawingResult> submitDrawing({
    required String gameId,
    required Uint8List drawingBytes,
  }) async {
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return DrawingResult.fromJson(data['data']);
  }

  /// Evaluate a solo drawing for practice mode.
  Future<DrawingResult> evaluateSoloDrawing({
    required String prompt,
    required Uint8List drawingBytes,
  }) async {
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return DrawingResult.fromJson(data['data']);
  }

  /// Get all drawings and rankings for a completed game.
  Future<Map<String, dynamic>> getGameDrawings(String gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/drawings/$gameId'),
      headers: {'Content-Type': 'application/json'},
    );

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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception('Failed to analyze sketch');
    return data['data'] as Map<String, dynamic>;
  }
}
