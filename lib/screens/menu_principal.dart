// FILE: lib/screens/menu_principal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'juego_screen.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;
  String? _errorMessage;

  // Lobby state — un provider que mantenemos mientras estamos en la sala de espera.
  GameProvider? _lobbyProvider;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _lobbyProvider?.dispose();
    super.dispose();
  }

  String? _validateName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Escribe tu nombre para continuar');
      return null;
    }
    if (name.length > 16) {
      setState(
          () => _errorMessage = 'El nombre debe tener máximo 16 caracteres');
      return null;
    }
    return name;
  }

  Future<void> _createRoom() async {
    final name = _validateName();
    if (name == null) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final provider = GameProvider();
      _lobbyProvider = provider;
      await provider.createRoom(name);

      if (!mounted) return;

      setState(() => _isCreating = false);

      // Escuchar cambios para saber cuándo arranca el juego
      provider.addListener(_onLobbyUpdate);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _errorMessage = 'Error al crear la sala: $e';
      });
    }
  }

  Future<void> _joinRoom() async {
    final name = _validateName();
    if (name == null) return;

    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Ingresa un código de sala');
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final provider = GameProvider();
      final success = await provider.joinRoom(code, name);

      if (!mounted) return;

      if (success) {
        _lobbyProvider = provider;
        setState(() => _isJoining = false);
        // Escuchar para saber cuándo el host inicie la partida
        provider.addListener(_onLobbyUpdate);
      } else {
        provider.dispose();
        setState(() {
          _isJoining = false;
          _errorMessage = 'Sala "$code" no encontrada, llena o ya comenzó';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _errorMessage = 'Error al unirse: $e';
      });
    }
  }

  void _onLobbyUpdate() {
    if (!mounted || _lobbyProvider == null) return;
    final provider = _lobbyProvider!;

    // Si el status cambió a 'playing', navegar al juego
    if (provider.isGameStarted) {
      _navigateToGame(provider);
    }

    // Re-render para actualizar la lista de jugadores
    if (mounted) setState(() {});
  }

  Future<void> _hostStartGame() async {
    if (_lobbyProvider == null || !_lobbyProvider!.isHost) return;
    if (_lobbyProvider!.playerNames.length < 2) {
      setState(() => _errorMessage = 'Se necesitan al menos 2 jugadores');
      return;
    }
    await _lobbyProvider!.startGame();
  }

  void _navigateToGame(GameProvider provider) {
    provider.removeListener(_onLobbyUpdate);
    _lobbyProvider = null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: JuegoScreen(
            roomCode: provider.roomCode,
            localPlayerIndex: provider.localPlayerIndex,
          ),
        ),
      ),
    );
  }

  void _cancelLobby() {
    _lobbyProvider?.removeListener(_onLobbyUpdate);
    _lobbyProvider?.leaveRoom();
    _lobbyProvider?.dispose();
    _lobbyProvider = null;
    setState(() {
      _isCreating = false;
      _isJoining = false;
    });
  }

  bool get _inLobby => _lobbyProvider != null;

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
                  const SizedBox(height: 20),
                  // ── Logo ──
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
                        height: 140,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ECDC4), Color(0xFF44B3AA)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4ECDC4)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.extension,
                                size: 60, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Título ──
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFFFFD93D)],
                    ).createShader(bounds),
                    child: const Text(
                      'TUNOMETESCABRA',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi,
                          size: 14,
                          color:
                              const Color(0xFF4ECDC4).withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'Multijugador Online',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  if (_inLobby)
                    _buildLobbyCard()
                  else ...[
                    // ── Nombre ──
                    _buildNameField(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('CREAR SALA'),
                    const SizedBox(height: 12),
                    _buildCreateButton(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('UNIRSE A SALA'),
                    const SizedBox(height: 12),
                    _buildJoinSection(),
                  ],

                  // Error
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFFF6B6B), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Color(0xFFFF6B6B), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!_inLobby) ...[
                    const SizedBox(height: 24),
                    _buildRulesCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _nameController,
        maxLength: 16,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          icon: Icon(Icons.person_outline,
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.7)),
          hintText: 'Tu nombre',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontWeight: FontWeight.w400,
          ),
          counterText: '',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
            height: 1,
            width: 40,
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Container(
                height: 1,
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [
          const Color(0xFF4ECDC4).withValues(alpha: 0.2),
          const Color(0xFF4ECDC4).withValues(alpha: 0.05)
        ]),
        border:
            Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isCreating ? null : _createRoom,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF4ECDC4)))
                      : const Icon(Icons.add_circle_outline,
                          color: Color(0xFF4ECDC4), size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  _isCreating ? 'Creando...' : 'Crear Nueva Sala',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.6),
                    size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: Color(0xFFFFD93D),
            ),
            decoration: InputDecoration(
              hintText: 'CÓDIGO',
              hintStyle: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              counterText: '',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFFFD93D), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFD93D), Color(0xFFF0C929)]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD93D).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isJoining ? null : _joinRoom,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isJoining)
                          const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF1A1A2E)))
                        else
                          const Icon(Icons.login_rounded,
                              color: Color(0xFF1A1A2E), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _isJoining ? 'Conectando...' : 'Unirse',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyCard() {
    final provider = _lobbyProvider!;
    final names = provider.playerNames;
    final isHost = provider.isHost;
    final code = provider.roomCode;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        children: [
          // Código
          Text(
            'Sala',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                const Color(0xFFFFD93D).withValues(alpha: 0.1),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.5)),
            ),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: Color(0xFF4ECDC4),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Lista de jugadores
          Text(
            'JUGADORES (${names.length}/4)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(names.length, (i) {
            final isMe = i == provider.localPlayerIndex;
            final isHostPlayer = i == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMe
                      ? const Color(0xFF4ECDC4).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _playerColor(i).withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        names[i][0].toUpperCase(),
                        style: TextStyle(
                          color: _playerColor(i),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      names[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                        color: Colors.white.withValues(alpha: isMe ? 1.0 : 0.7),
                      ),
                    ),
                  ),
                  if (isHostPlayer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'HOST',
                        style: TextStyle(
                          color: Color(0xFFFFD93D),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  if (isMe)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'TÚ',
                        style: TextStyle(
                          color: Color(0xFF4ECDC4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          // Slots vacíos
          ...List.generate(4 - names.length, (i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Icon(Icons.person_add_outlined,
                        size: 14, color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Esperando jugador...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.2),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Spinner si no es host O si esperando
          if (!isHost)
            Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF4ECDC4)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esperando a que el host inicie...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),

          // Botón Comenzar (solo host, mín 2 jugadores)
          if (isHost) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: names.length >= 2
                      ? const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44B3AA)])
                      : null,
                  color: names.length < 2
                      ? Colors.white.withValues(alpha: 0.08)
                      : null,
                  boxShadow: names.length >= 2
                      ? [
                          BoxShadow(
                              color: const Color(0xFF4ECDC4)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: names.length >= 2 ? _hostStartGame : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: names.length >= 2
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              size: 22),
                          const SizedBox(width: 8),
                          Text(
                            names.length >= 2
                                ? '¡Comenzar Partida!'
                                : 'Esperando jugadores...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: names.length >= 2
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _cancelLobby,
            icon: const Icon(Icons.close, color: Color(0xFFFF6B6B), size: 16),
            label: const Text(
              'Salir de la sala',
              style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _playerColor(int index) {
    const colors = [
      Color(0xFF4ECDC4),
      Color(0xFFFFD93D),
      Color(0xFFFF6B6B),
      Color(0xFFA29BFE),
    ];
    return colors[index % colors.length];
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(Icons.info_outline,
                  color: Color(0xFF4ECDC4), size: 16),
              const SizedBox(width: 8),
              Text(
                'REGLAS ESPECIALES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ruleItem('🎭', 'Puedes jugar fichas inválidas (trampa)'),
          _ruleItem('⚖️', 'Acusa al rival antes de jugar tu turno'),
          _ruleItem('✅', 'Trampa descubierta → ficha devuelta + pierde turno'),
          _ruleItem('❌', 'Acusación falsa → tú robas 1 ficha'),
          _ruleItem('⏰', '30 segundos por turno'),
          _ruleItem('👥', 'De 2 a 4 jugadores'),
        ],
      ),
    );
  }

  static Widget _ruleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
  }
}
