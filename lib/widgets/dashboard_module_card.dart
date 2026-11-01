import 'package:flutter/material.dart';

class DashboardModuleCard extends StatelessWidget {
  const DashboardModuleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  static const Color _borderColor = Color(0xFF052B52);
  static const LinearGradient _cardGradient = LinearGradient(
    colors: [Color(0xFF073B6F), Color(0xFF0B6EAA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient _accentGradient = LinearGradient(
    colors: [Color(0xFF9FE5FF), Color(0xFFE5F7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(gradient: _cardGradient),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: ShaderMask(
                    shaderCallback: _accentGradient.createShader,
                    child: Icon(icon, color: Colors.white, size: 27),
                  ),
                ),
                const SizedBox(height: 10),
                ShaderMask(
                  shaderCallback: _accentGradient.createShader,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
