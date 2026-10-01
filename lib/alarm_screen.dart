import 'dart:math' as math;

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

class AlarmRingingScreen extends StatefulWidget {
  final int alarmId;
  final String title;
  final String body;
  final String stopLabel;

  const AlarmRingingScreen({
    super.key,
    required this.alarmId,
    required this.title,
    required this.body,
    required this.stopLabel,
  });

  @override
  State<AlarmRingingScreen> createState() =>
      _AlarmRingingScreenState();
}

class _AlarmRingingScreenState
    extends State<AlarmRingingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late AnimationController _successController;

  double _dragX = 0;
  bool _stopping = false;
  bool _stopped = false;

  static const double _horizontalPadding = 24;
  static const double _handleSize = 58;

  @override
  void initState() {
    super.initState();

    // Main alarm pulse.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    // Expanding alarm waves.
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Stop success animation.
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _successController.dispose();
    super.dispose();
  }

  double _maxDrag(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return math.max(
      0,
      width -
          (_horizontalPadding * 2) -
          _handleSize -
          12,
    );
  }

  void _onDragUpdate(
    DragUpdateDetails details,
    BuildContext context,
  ) {
    if (_stopping || _stopped) return;

    final maxDrag = _maxDrag(context);

    setState(() {
      _dragX += details.delta.dx;
      _dragX = _dragX.clamp(0.0, maxDrag);
    });
  }

  Future<void> _onDragEnd(BuildContext context) async {
    if (_stopping || _stopped) return;

    final maxDrag = _maxDrag(context);

    // User must swipe around 72% of the track.
    final threshold = maxDrag * 0.72;

    if (_dragX >= threshold) {
      await _stopAlarm();
    } else {
      // Smoothly return the handle.
      await _animateBack();
    }
  }

  Future<void> _animateBack() async {
    final start = _dragX;

    for (int i = 1; i <= 12; i++) {
      if (!mounted) return;

      final progress = i / 12;

      setState(() {
        _dragX = start * (1 - Curves.easeOut.transform(progress));
      });

      await Future.delayed(
        const Duration(milliseconds: 12),
      );
    }

    if (mounted) {
      setState(() {
        _dragX = 0;
      });
    }
  }

  Future<void> _stopAlarm() async {
    if (_stopping || _stopped) return;

    setState(() {
      _stopping = true;
    });

    try {
      await Alarm.stop(widget.alarmId);
    } catch (e) {
      debugPrint('Failed to stop alarm: $e');
    }

    if (!mounted) return;

    setState(() {
      _stopped = true;
    });

    await _successController.forward();

    if (!mounted) return;

    await Future.delayed(
      const Duration(milliseconds: 450),
    );

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1211),
        body: SafeArea(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _stopped ? 0.35 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
                vertical: 26,
              ),
              child: Column(
                children: [
                  const Spacer(),

                  // =====================================================
                  // ANIMATED ALARM ICON
                  // =====================================================

                  SizedBox(
                    width: 220,
                    height: 220,
                    child: AnimatedBuilder(
                      animation: _ringController,
                      builder: (context, child) {
                        final wave =
                            _ringController.value;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer wave.
                            Transform.scale(
                              scale: 1.0 + (wave * 0.48),
                              child: Opacity(
                                opacity:
                                    (1 - wave) * 0.16,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration:
                                      BoxDecoration(
                                    shape:
                                        BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          const Color(
                                        0xFF19C37D,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Second wave.
                            Transform.scale(
                              scale:
                                  1.0 +
                                  (((wave + 0.5) % 1) *
                                      0.38),
                              child: Opacity(
                                opacity:
                                    (1 -
                                            ((wave +
                                                    0.5) %
                                                1)) *
                                        0.10,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration:
                                      BoxDecoration(
                                    shape:
                                        BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          const Color(
                                        0xFF19C37D,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Main pulsing circle.
                            AnimatedBuilder(
                              animation:
                                  _pulseController,
                              builder:
                                  (context, child) {
                                final scale =
                                    1.0 +
                                    (_pulseController
                                            .value *
                                        0.07);

                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 170,
                                    height: 170,
                                    decoration:
                                        BoxDecoration(
                                      shape:
                                          BoxShape.circle,
                                      color:
                                          const Color(
                                        0xFF151C1A,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              const Color(
                                            0xFF19C37D,
                                          ).withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: 40,
                                          spreadRadius: 8,
                                        ),
                                        const BoxShadow(
                                          color:
                                              Color(
                                            0xFF080B0A,
                                          ),
                                          blurRadius: 25,
                                          offset:
                                              Offset(
                                            12,
                                            12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      margin:
                                          const EdgeInsets
                                              .all(22),
                                      decoration:
                                          BoxDecoration(
                                        shape:
                                            BoxShape.circle,
                                        color:
                                            const Color(
                                          0xFF101715,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color:
                                                Color(
                                              0xFF202A26,
                                            ),
                                            blurRadius:
                                                12,
                                            offset:
                                                Offset(
                                              -5,
                                              -5,
                                            ),
                                          ),
                                          BoxShadow(
                                            color:
                                                Color(
                                              0xFF080B0A,
                                            ),
                                            blurRadius:
                                                12,
                                            offset:
                                                Offset(
                                              5,
                                              5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _stopped
                                            ? Icons
                                                .check_rounded
                                            : Icons
                                                .notifications_active_rounded,
                                        color:
                                            const Color(
                                          0xFF19C37D,
                                        ),
                                        size: 72,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // =====================================================
                  // TITLE
                  // =====================================================

                  AnimatedSwitcher(
                    duration:
                        const Duration(milliseconds: 300),
                    child: _stopped
                        ? const Text(
                            'ALARM STOPPED',
                            key: ValueKey(
                              'stopped',
                            ),
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color:
                                  Color(0xFF19C37D),
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: 3,
                            ),
                          )
                        : const Text(
                            'DESTINATION',
                            key: ValueKey(
                              'destination',
                            ),
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color:
                                  Color(0xFF19C37D),
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: 3,
                            ),
                          ),
                  ),

                  const SizedBox(height: 8),

                  AnimatedSwitcher(
                    duration:
                        const Duration(milliseconds: 350),
                    child: Text(
                      _stopped
                          ? 'DONE ✓'
                          : 'REACHED!',
                      key: ValueKey(
                        _stopped,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF2F7F5),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8C9994),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Your destination is nearby.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF2F7F5),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  // =====================================================
                  // SLIDE TO STOP
                  // =====================================================

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final trackWidth =
                          constraints.maxWidth;

                      final maxDrag =
                          math.max(
                        0,
                        trackWidth -
                            _handleSize -
                            12,
                      );

                      final progress =
                          maxDrag == 0
                              ? 0.0
                              : (_dragX / maxDrag)
                                  .clamp(
                                  0.0,
                                  1.0,
                                );

                      return Column(
                        children: [
                          AnimatedBuilder(
                            animation:
                                _pulseController,
                            builder:
                                (context, child) {
                              return Container(
                                height: 76,
                                width: double.infinity,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFF151C1A,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    25,
                                  ),
                                  border:
                                      Border.all(
                                    color:
                                        const Color(
                                      0xFF25332E,
                                    ),
                                  ),
                                  boxShadow: [
                                    const BoxShadow(
                                      color:
                                          Color(
                                        0xFF080B0A,
                                      ),
                                      blurRadius: 18,
                                      offset:
                                          Offset(
                                        7,
                                        7,
                                      ),
                                    ),
                                    BoxShadow(
                                      color:
                                          const Color(
                                        0xFF19C37D,
                                      ).withValues(
                                        alpha: 0.04 +
                                            (_pulseController
                                                    .value *
                                                0.04),
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment:
                                      Alignment.centerLeft,
                                  children: [
                                    // Progress glow.
                                    Positioned(
                                      left: 6,
                                      top: 6,
                                      bottom: 6,
                                      child:
                                          AnimatedContainer(
                                        duration:
                                            const Duration(
                                          milliseconds:
                                              80,
                                        ),
                                        width:
                                            _dragX +
                                                _handleSize,
                                        decoration:
                                            BoxDecoration(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            20,
                                          ),
                                          color:
                                              const Color(
                                            0xFF19C37D,
                                          ).withValues(
                                            alpha: 0.08 +
                                                (progress *
                                                    0.14),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Center instruction.
                                    Center(
                                      child:
                                          AnimatedOpacity(
                                        duration:
                                            const Duration(
                                          milliseconds:
                                              120,
                                        ),
                                        opacity:
                                            progress >
                                                    0.12
                                                ? 0
                                                : 1,
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                          children: const [
                                            Icon(
                                              Icons
                                                  .arrow_forward_rounded,
                                              color:
                                                  Color(
                                                0xFF19C37D,
                                              ),
                                              size: 21,
                                            ),
                                            SizedBox(
                                              width: 8,
                                            ),
                                            Text(
                                              'SLIDE TO STOP',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Color(
                                                  0xFFDCE8E3,
                                                ),
                                                fontSize:
                                                    14,
                                                fontWeight:
                                                    FontWeight
                                                        .w800,
                                                letterSpacing:
                                                    1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Release text.
                                    Center(
                                      child:
                                          AnimatedOpacity(
                                        duration:
                                            const Duration(
                                          milliseconds:
                                              120,
                                        ),
                                        opacity:
                                            progress >
                                                    0.12
                                                ? 1
                                                : 0,
                                        child:
                                            const Text(
                                          'RELEASE TO STOP',
                                          style:
                                              TextStyle(
                                            color:
                                                Color(
                                              0xFF19C37D,
                                            ),
                                            fontSize:
                                                14,
                                            fontWeight:
                                                FontWeight
                                                    .w900,
                                            letterSpacing:
                                                1.2,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // =================================================
                                    // DRAG HANDLE
                                    // =================================================

                                    Positioned(
                                      left: 6 + _dragX,
                                      top: 9,
                                      child:
                                          GestureDetector(
                                        behavior:
                                            HitTestBehavior
                                                .opaque,
                                        onHorizontalDragUpdate:
                                            (details) =>
                                                _onDragUpdate(
                                          details,
                                          context,
                                        ),
                                        onHorizontalDragEnd:
                                            (_) =>
                                                _onDragEnd(
                                          context,
                                        ),
                                        child:
                                            AnimatedContainer(
                                          duration:
                                              const Duration(
                                            milliseconds:
                                                100,
                                          ),
                                          width:
                                              _handleSize,
                                          height:
                                              _handleSize,
                                          decoration:
                                              BoxDecoration(
                                            shape:
                                                BoxShape
                                                    .circle,
                                            color:
                                                const Color(
                                              0xFF19C37D,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    const Color(
                                                  0xFF19C37D,
                                                ).withValues(
                                                  alpha: 0.28 +
                                                      (progress *
                                                          0.25),
                                                ),
                                                blurRadius:
                                                    18 +
                                                        (progress *
                                                            10),
                                                spreadRadius:
                                                    2,
                                              ),
                                              const BoxShadow(
                                                color:
                                                    Color(
                                                  0xFF080B0A,
                                                ),
                                                blurRadius:
                                                    10,
                                                offset:
                                                    Offset(
                                                  4,
                                                  5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          child:
                                              Icon(
                                            progress >
                                                    0.72
                                                ? Icons
                                                    .check_rounded
                                                : Icons
                                                    .arrow_forward_rounded,
                                            color:
                                                const Color(
                                              0xFF07110D,
                                            ),
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          AnimatedSwitcher(
                            duration:
                                const Duration(
                              milliseconds: 200,
                            ),
                            child: Text(
                              _stopped
                                  ? 'Alarm stopped successfully'
                                  : 'Swipe the button all the way to the right',
                              key: ValueKey(
                                _stopped,
                              ),
                              style:
                                  const TextStyle(
                                color:
                                    Color(0xFF68736F),
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}