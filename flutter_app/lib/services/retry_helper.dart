import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helper utility for retrying asynchronous operations with exponential backoff.
class RetryHelper {
  /// Retries [fn] up to [maxRetries] times with exponential backoff.
  static Future<T> retryAsync<T>(
    Future<T> Function() fn, {
    int maxRetries = 3,
    int initialDelayMs = 500,
    double backoffFactor = 2.0,
    String taskName = 'Operation',
  }) async {
    int attempt = 0;
    int currentDelay = initialDelayMs;

    while (true) {
      attempt++;
      try {
        return await fn();
      } catch (e) {
        if (attempt >= maxRetries) {
          debugPrint('❌ [$taskName] Failed after $maxRetries attempts: $e');
          rethrow;
        }
        debugPrint('⚠️ [$taskName] Attempt $attempt/$maxRetries failed: $e. Retrying in ${currentDelay}ms...');
        await Future.delayed(Duration(milliseconds: currentDelay));
        currentDelay = (currentDelay * backoffFactor).round();
      }
    }
  }
}
