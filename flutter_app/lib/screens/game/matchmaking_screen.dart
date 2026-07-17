import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'dart:async';
import 'dart:math' as math;

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _pollingTimer;
  String _status = 'Joining Queue...';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _joinQueue();
  }

  Future<void> _joinQueue() async {
    try {
      final auth = context.read<AuthProvider>();
      final api = ApiService(auth);
      
      await api.joinMatchmaking('all'); // default difficulty
      
      setState(() {
        _status = 'Searching for players...';
      });

      // Polling for demo if Socket.IO isn't wired fully on client
      // In a real app, Socket.IO 'matchmaking:matched' event would push to lobby.
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        // Mock success after a few seconds for now to show UI flow
        if (timer.tick > 2) {
          timer.cancel();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/lobby');
          }
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Error joining queue.';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pollingTimer?.cancel();
    _leaveQueue();
    super.dispose();
  }

  void _leaveQueue() {
    final auth = context.read<AuthProvider>();
    ApiService(auth).leaveMatchmaking().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 120 + (_pulseController.value * 40),
                          height: 120 + (_pulseController.value * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accentPrimary.withOpacity(1 - _pulseController.value),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentPrimary.withOpacity((1 - _pulseController.value) * 0.5),
                                blurRadius: 20,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.search_rounded, size: 48, color: AppTheme.accentPrimary),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Estimated wait: 0:15',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 60),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Cancel'),
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
}
