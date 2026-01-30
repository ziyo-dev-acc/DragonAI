import 'package:flutter/material.dart';

class AssistantPill extends StatelessWidget {
  const AssistantPill({
    super.key,
    required this.status,
    required this.onMute,
    required this.onStop,
    required this.onSettings,
  });

  final String status;
  final VoidCallback onMute;
  final VoidCallback onStop;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2A2B),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onMute,
            icon: const Icon(Icons.mic_off, color: Colors.white),
            tooltip: 'Mute',
          ),
          IconButton(
            onPressed: onStop,
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
            tooltip: 'Stop',
          ),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}
