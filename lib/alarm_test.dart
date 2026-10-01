import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

class AlarmTestPage extends StatefulWidget {
  const AlarmTestPage({super.key});

  @override
  State<AlarmTestPage> createState() => _AlarmTestPageState();
}

class _AlarmTestPageState extends State<AlarmTestPage> {
  bool scheduled = false;

  static const Color background = Color(0xFF101615);
  static const Color surface = Color(0xFF161D1B);
  static const Color green = Color(0xFF19C37D);

  Future<void> testAlarm() async {
    try {
      final alarmSettings = AlarmSettings(
        id: 999,

        dateTime: DateTime.now().add(
          const Duration(seconds: 30),
        ),

        assetAudioPath: null,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: false,
        androidFullScreenIntent: true,
        androidStopAlarmOnTermination: false,

        volumeSettings: const VolumeSettings.fixed(
          volume: 1.0,
          volumeEnforced: true,
          showSystemUI: true,
        ),

        notificationSettings: const NotificationSettings(
          title: '🚨 DESTINATION ALARM TEST',
          body: 'Your alarm is working correctly!',
          stopButton: 'STOP ALARM',
          androidStopAlarmOnDismiss: false,
        ),
      );

      final result = await Alarm.set(
        alarmSettings: alarmSettings,
      );

      debugPrint('ALARM RESULT: $result');

      if (!mounted) return;

      setState(() {
        scheduled = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Text(
            '🔔 Alarm scheduled — ringing in 30 seconds',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      debugPrint('ALARM ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF241515),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(
            'Alarm error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> stopAlarm() async {
    try {
      await Alarm.stop(999);

      if (!mounted) return;

      setState(() {
        scheduled = false;
      });
    } catch (e) {
      debugPrint('STOP ALARM ERROR: $e');
    }
  }

  // ------------------------------------------------------------
  // NEUMORPHIC RAISED CONTAINER
  // ------------------------------------------------------------

  Widget _neuContainer({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    double radius = 24,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF080B0A),
            offset: Offset(7, 7),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0xFF222B28),
            offset: Offset(-5, -5),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // NEUMORPHIC PRESSED CONTAINER
  // ------------------------------------------------------------

  Widget _neuPressed({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    double radius = 24,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF080B0A),
            offset: Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0xFF222B28),
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
        ],
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // ALARM ICON
  // ------------------------------------------------------------

  Widget _buildAlarmIcon() {
    return _neuContainer(
      padding: const EdgeInsets.all(28),
      radius: 100,
      child: Container(
        width: 105,
        height: 105,
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF080B0A),
              offset: Offset(6, 6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: Color(0xFF222B28),
              offset: Offset(-5, -5),
              blurRadius: 11,
            ),
          ],
        ),
        child: Icon(
          scheduled
              ? Icons.notifications_active_rounded
              : Icons.alarm_rounded,
          size: 50,
          color: green,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TEST BUTTON
  // ------------------------------------------------------------

  Widget _buildTestButton() {
    return GestureDetector(
      onTap: scheduled ? null : testAlarm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: scheduled
              ? const Color(0xFF121816)
              : green,
          borderRadius: BorderRadius.circular(20),
          boxShadow: scheduled
              ? const [
                  BoxShadow(
                    color: Color(0xFF080B0A),
                    offset: Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Color(0xFF222B28),
                    offset: Offset(-3, -3),
                    blurRadius: 7,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0xFF080B0A),
                    offset: Offset(6, 6),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Color(0xFF26332F),
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              scheduled
                  ? Icons.schedule_rounded
                  : Icons.notifications_active_rounded,
              color: scheduled
                  ? Colors.white38
                  : Colors.black87,
            ),
            const SizedBox(width: 10),
            Text(
              scheduled
                  ? 'ALARM SCHEDULED'
                  : 'TEST ALARM',
              style: TextStyle(
                color: scheduled
                    ? Colors.white38
                    : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // STOP BUTTON
  // ------------------------------------------------------------

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: stopAlarm,
      child: _neuPressed(
        padding: EdgeInsets.zero,
        radius: 20,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.stop_circle_outlined,
                color: Colors.redAccent,
                size: 23,
              ),
              SizedBox(width: 10),
              Text(
                'STOP ALARM',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // STATUS
  // ------------------------------------------------------------

  Widget _buildStatus() {
    return _neuPressed(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: scheduled
                  ? green
                  : Colors.white24,
              shape: BoxShape.circle,
              boxShadow: scheduled
                  ? const [
                      BoxShadow(
                        color: green,
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              scheduled
                  ? 'Alarm is waiting to ring'
                  : 'Alarm system ready',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            scheduled ? 'ACTIVE' : 'READY',
            style: TextStyle(
              color: scheduled
                  ? green
                  : Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Alarm Test',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            22,
            20,
            22,
            35,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              _buildAlarmIcon(),

              const SizedBox(height: 30),

              const Text(
                'Destination Alarm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                scheduled
                    ? 'The alarm is scheduled'
                    : 'Test your alarm before starting the journey',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              _neuContainer(
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: green,
                      size: 25,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Test delay',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      '30 sec',
                      style: TextStyle(
                        color: green,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              _buildTestButton(),

              const SizedBox(height: 14),

              _buildStopButton(),

              const SizedBox(height: 22),

              _buildStatus(),

              const SizedBox(height: 25),

              const Text(
                'TEST CHECKLIST',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              _neuPressed(
                padding: const EdgeInsets.all(18),
                radius: 20,
                child: const Column(
                  children: [
                    _CheckItem(
                      icon: Icons.volume_up_rounded,
                      text: 'Phone volume is ON',
                    ),
                    SizedBox(height: 13),
                    _CheckItem(
                      icon: Icons.vibration_rounded,
                      text: 'Phone vibration is ON',
                    ),
                    SizedBox(height: 13),
                    _CheckItem(
                      icon: Icons.notifications_active_rounded,
                      text: 'Alarm notification is allowed',
                    ),
                    SizedBox(height: 13),
                    _CheckItem(
                      icon: Icons.lock_clock_rounded,
                      text: 'Wait 30 seconds after testing',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CHECK ITEM
// ================================================================

class _CheckItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CheckItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF19C37D),
          size: 18,
        ),
        const SizedBox(width: 10),
        Icon(
          icon,
          color: Colors.white38,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}