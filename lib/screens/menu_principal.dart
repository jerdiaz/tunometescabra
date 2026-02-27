// FILE: lib/screens/menu_principal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'juego_screen.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Logo con glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 180,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ECDC4), Color(0xFF44B3AA)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.4),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.extension, size: 80, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Título
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFFFFD93D)],
                    ).createShader(bounds),
                    child: const Text(
                      'TUNOMETESCABRA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dominó con Trampa y Castigo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Subtítulo
                  Row(
                    children: [
                      Container(height: 1, width: 40, color: const Color(0xFF4ECDC4).withValues(alpha: 0.5)),
                      const SizedBox(width: 12),
                      Text(
                        'NUEVA PARTIDA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Container(height: 1, color: const Color(0xFF4ECDC4).withValues(alpha: 0.5))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Botones de jugadores
                  _PlayerButton(playerCount: 2, color: const Color(0xFF4ECDC4), icon: Icons.people),
                  const SizedBox(height: 16),
                  _PlayerButton(playerCount: 3, color: const Color(0xFFFFD93D), icon: Icons.group),
                  const SizedBox(height: 16),
                  _PlayerButton(playerCount: 4, color: const Color(0xFFFF6B6B), icon: Icons.groups),
                  const SizedBox(height: 40),
                  // Reglas
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF4ECDC4), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'REGLAS ESPECIALES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ruleItem('🎭', 'Puedes jugar fichas inválidas (trampa)'),
                        _ruleItem('⚖️', 'Acusa al rival antes de jugar tu turno'),
                        _ruleItem('✅', 'Trampa correcta → rival roba 1 ficha'),
                        _ruleItem('❌', 'Acusación falsa → tú robas 1 ficha'),
                        _ruleItem('⏰', '30 segundos por turno'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _ruleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerButton extends StatelessWidget {
  final int playerCount;
  final Color color;
  final IconData icon;

  const _PlayerButton({required this.playerCount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Provider.of<GameProvider>(context, listen: false).startGame(playerCount);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JuegoScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  '$playerCount Jugadores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.6), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}