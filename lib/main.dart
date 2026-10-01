import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'alarm_screen.dart';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize alarm package
  await Alarm.init();

  // Initialize background GPS service
  await initializeBackgroundService();

  runApp(const DestinationAlarmApp());
}

// ============================================================
// BACKGROUND SERVICE INITIALIZATION
// ============================================================

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: backgroundService,
      autoStart: false,
      autoStartOnBoot: false,
      isForegroundMode: true,
      initialNotificationTitle: 'Destination Alarm',
      initialNotificationContent:
          'Waiting to start journey...',
      foregroundServiceNotificationId: 777,
      foregroundServiceTypes: [
        AndroidForegroundType.location,
      ],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: backgroundService,
      onBackground: iosBackground,
    ),
  );
}

// ============================================================
// IOS BACKGROUND
// ============================================================

@pragma('vm:entry-point')
Future<bool> iosBackground(
  ServiceInstance service,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

// ============================================================
// DESTINATION ALARM
// ============================================================

Future<void> triggerDestinationAlarm() async {
  try {
    final alarmSettings = AlarmSettings(
      id: 999,

      // alarm package requires at least 30 seconds
      dateTime: DateTime.now().add(
        const Duration(seconds: 30),
      ),

      // Use phone default alarm sound
      assetAudioPath: null,

      // Keep ringing
      loopAudio: true,

      // Vibrate
      vibrate: true,

      warningNotificationOnKill: false,

      // Full-screen alarm when supported
      androidFullScreenIntent: true,

      // Keep alarm alive after termination when supported
      androidStopAlarmOnTermination: false,

      // Maximum volume
      volumeSettings: const VolumeSettings.fixed(
        volume: 0.90,
        volumeEnforced: false,
        showSystemUI: true,
      ),

      notificationSettings:
          const NotificationSettings(
        title: 'Destination Reached! 🚨',
        body:
            'You are inside your destination radius.',
        stopButton: 'STOP ALARM',
        androidStopAlarmOnDismiss: true,
      ),
    );

    final result = await Alarm.set(
      alarmSettings: alarmSettings,
    );

    debugPrint(
      'Destination alarm scheduled: $result',
    );
  } catch (e) {
    debugPrint(
      'ALARM ERROR: $e',
    );
  }
}

// ============================================================
// BACKGROUND SERVICE
// ============================================================

@pragma('vm:entry-point')
void backgroundService(
  ServiceInstance service,
) async {
  DartPluginRegistrant.ensureInitialized();

  Timer? locationTimer;

  double? destinationLatitude;
  double? destinationLongitude;

  double radius = 1000;

  bool tracking = false;

  bool alarmTriggered = false;

  // ----------------------------------------------------------
  // START TRACKING
  // ----------------------------------------------------------

  service.on('startTracking').listen(
    (event) {
      if (event == null) return;

      destinationLatitude =
          (event['latitude'] as num?)
              ?.toDouble();

      destinationLongitude =
          (event['longitude'] as num?)
              ?.toDouble();

      radius =
          (event['radius'] as num?)
              ?.toDouble() ??
          1000;

      tracking = true;

      alarmTriggered = false;

      service.invoke(
        'serviceStatus',
        {
          'status': 'tracking',
        },
      );

      locationTimer?.cancel();

      locationTimer = Timer.periodic(
        const Duration(seconds: 5),
        (timer) async {
          if (!tracking ||
              destinationLatitude == null ||
              destinationLongitude == null) {
            return;
          }

          try {
            final position =
                await Geolocator
                    .getCurrentPosition(
              locationSettings:
                  const LocationSettings(
                accuracy:
                    LocationAccuracy.high,
              ),
            );

            final distance =
                Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              destinationLatitude!,
              destinationLongitude!,
            );

            // Send location to Flutter UI
            service.invoke(
              'locationUpdate',
              {
                'latitude':
                    position.latitude,
                'longitude':
                    position.longitude,
                'accuracy':
                    position.accuracy,
                'distance':
                    distance,
                'radius':
                    radius,
              },
            );

            // ------------------------------------------------
            // DESTINATION DETECTED
            // ------------------------------------------------

            if (distance <= radius &&
                !alarmTriggered) {
              alarmTriggered = true;

              tracking = false;

              locationTimer?.cancel();

              service.invoke(
                'destinationReached',
                {
                  'distance':
                      distance,
                },
              );

              service.invoke(
                'serviceStatus',
                {
                  'status':
                      'destinationReached',
                },
              );

              // Start alarm
              await triggerDestinationAlarm();
            }
          } catch (e) {
            service.invoke(
              'locationError',
              {
                'error': e.toString(),
              },
            );
          }
        },
      );
    },
  );

  // ----------------------------------------------------------
  // STOP TRACKING
  // ----------------------------------------------------------

  service.on('stopTracking').listen(
    (event) {
      tracking = false;

      alarmTriggered = false;

      locationTimer?.cancel();

      service.invoke(
        'serviceStatus',
        {
          'status': 'stopped',
        },
      );
    },
  );

  // ----------------------------------------------------------
  // STOP SERVICE
  // ----------------------------------------------------------

  service.on('stopService').listen(
    (event) {
      tracking = false;

      locationTimer?.cancel();

      service.stopSelf();
    },
  );
}

// ============================================================
// DESTINATION RESULT
// ============================================================

class DestinationResult {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;

  const DestinationResult({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

// ============================================================
// APP
// ============================================================

class DestinationAlarmApp
    extends StatelessWidget {
  const DestinationAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Destination Alarm',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor:
            const Color(0xFF07110D),
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(0xFF19C37D),
          brightness:
              Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home:
          const DestinationHomePage(),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class DestinationHomePage
    extends StatefulWidget {
  const DestinationHomePage({
    super.key,
  });

  @override
  State<DestinationHomePage>
      createState() =>
          _DestinationHomePageState();
}

class _DestinationHomePageState
    extends State<
        DestinationHomePage>
    with SingleTickerProviderStateMixin {
  Position? currentPosition;

  Position? destinationPosition;

  StreamSubscription?
      locationUpdateSubscription;

  StreamSubscription?
      serviceStatusSubscription;

  StreamSubscription?
      destinationReachedSubscription;

  StreamSubscription?
      locationErrorSubscription;

  // Listen for alarms that actually start ringing.
  StreamSubscription?
      alarmRingingSubscription;

  late AnimationController
      _trackingPulseController;

  bool loadingLocation = false;

  bool trackingLocation = false;

  bool searchingDestination = false;

  double distanceToDestination = 0;

  double journeyStartDistance = 0;

  // Default alarm radius = 1 km
  int selectedRadius = 1000;

  String journeyType =
      'Home → Bus Stop';

  String serviceStatus = 'Ready';

  String selectedDestinationName =
      '';

  String selectedDestinationAddress =
      '';

  List<DestinationResult>
      searchResults = [];

  final TextEditingController
      destinationSearchController =
      TextEditingController();

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _trackingPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _listenToBackgroundService();

    _getCurrentLocation();

    // Listen for the alarm actually starting to ring.
    // Do not type this subscription as AlarmSet because AlarmSet is
    // not exported by the top-level alarm package API.
    alarmRingingSubscription = Alarm.ringing.listen((alarmSet) {
      if (!mounted || alarmSet.alarms.isEmpty) return;

      final alarm = alarmSet.alarms.first;

      // Avoid pushing the same screen repeatedly.
      if (ModalRoute.of(context)?.isCurrent != true) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AlarmRingingScreen(
            alarmId: alarm.id,
            title: alarm.notificationSettings.title,
            body: alarm.notificationSettings.body,
            stopLabel:
                alarm.notificationSettings.stopButton ??
                'STOP ALARM',
          ),
        ),
      );
    });

    // Check whether Android launched this activity
    // because the destination alarm is ringing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAlarmLaunch();
    });
  }

  // ==========================================================
  // ALARM FULL-SCREEN LAUNCH
  // ==========================================================

  Future<void> _checkForAlarmLaunch() async {
    try {
      const channel = MethodChannel(
        'destination_alarm/alarm',
      );

      final data = await channel.invokeMethod(
        'getAlarmIntent',
      );

      if (!mounted || data == null) {
        return;
      }

      final alarmId =
          (data['alarmId'] as num?)?.toInt();

      if (alarmId == null || alarmId < 0) {
        return;
      }

      final title =
          data['title']?.toString() ??
              'Destination Reached!';

      final body =
          data['body']?.toString() ??
              'You are inside your destination radius.';

      final stopLabel =
          data['stopLabel']?.toString() ??
              'STOP ALARM';

      // Avoid opening the alarm screen more than once.
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AlarmRingingScreen(
            alarmId: alarmId,
            title: title,
            body: body,
            stopLabel: stopLabel,
          ),
        ),
      );
    } on PlatformException catch (e) {
      debugPrint(
        'Alarm launch check failed: ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'Alarm launch check error: $e',
      );
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    locationUpdateSubscription
        ?.cancel();

    serviceStatusSubscription
        ?.cancel();

    destinationReachedSubscription
        ?.cancel();

    locationErrorSubscription
        ?.cancel();

    alarmRingingSubscription
        ?.cancel();

    destinationSearchController
        .dispose();

    _trackingPulseController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BACKGROUND SERVICE LISTENERS
  // ==========================================================

  void _listenToBackgroundService() {
    final service =
        FlutterBackgroundService();

    // --------------------------------------------------------
    // LOCATION UPDATE
    // --------------------------------------------------------

    locationUpdateSubscription =
        service
            .on('locationUpdate')
            .listen(
      (event) {
        if (event == null) {
          return;
        }

        final latitude =
            (event['latitude'] as num?)
                ?.toDouble();

        final longitude =
            (event['longitude'] as num?)
                ?.toDouble();

        final accuracy =
            (event['accuracy'] as num?)
                ?.toDouble();

        final distance =
            (event['distance'] as num?)
                ?.toDouble();

        if (!mounted) return;

        if (latitude != null &&
            longitude != null &&
            accuracy != null) {
          setState(() {
            currentPosition =
                Position(
              longitude:
                  longitude,
              latitude:
                  latitude,
              timestamp:
                  DateTime.now(),
              accuracy:
                  accuracy,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          });
        }

        if (distance != null) {
          setState(() {
            distanceToDestination =
                distance;
          });
        }
      },
    );

    // --------------------------------------------------------
    // SERVICE STATUS
    // --------------------------------------------------------

    serviceStatusSubscription =
        service
            .on('serviceStatus')
            .listen(
      (event) {
        if (event == null) {
          return;
        }

        final status =
            event['status']
                ?.toString();

        if (!mounted ||
            status == null) {
          return;
        }

        setState(() {
          if (status ==
              'tracking') {
            serviceStatus =
                'Tracking';

            trackingLocation =
                true;
          } else if (status ==
              'stopped') {
            serviceStatus =
                'Stopped';

            trackingLocation =
                false;
            _trackingPulseController.stop();
            _trackingPulseController.reset();
          } else if (status ==
              'destinationReached') {
            serviceStatus =
                'Destination reached';

            trackingLocation =
                false;
            _trackingPulseController.stop();
            _trackingPulseController.reset();
          }
        });
      },
    );

    // --------------------------------------------------------
    // DESTINATION REACHED
    // --------------------------------------------------------

    destinationReachedSubscription =
        service
            .on(
                'destinationReached')
            .listen(
      (event) {
        if (!mounted) return;

        setState(() {
          trackingLocation =
              false;

          serviceStatus =
              'Destination reached';
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              '🚨 Destination detected!',
            ),
            duration:
                Duration(seconds: 6),
          ),
        );
      },
    );

    // --------------------------------------------------------
    // LOCATION ERROR
    // --------------------------------------------------------

    locationErrorSubscription =
        service
            .on('locationError')
            .listen(
      (event) {
        if (event == null) {
          return;
        }

        debugPrint(
          'Background location error: '
          '${event['error']}',
        );
      },
    );
  }

  // ==========================================================
  // PERMISSION
  // ==========================================================

  Future<bool>
      _checkLocationPermission() async {
    final serviceEnabled =
        await Geolocator
            .isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Location is disabled',
            ),
            content:
                const Text(
              'Please enable GPS/location '
              'on your phone.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                ),
                child:
                    const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(
                    context,
                  );

                  await Geolocator
                      .openLocationSettings();
                },
                child:
                    const Text(
                  'OPEN SETTINGS',
                ),
              ),
            ],
          );
        },
      );

      return false;
    }

    LocationPermission permission =
        await Geolocator
            .checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
          await Geolocator
              .requestPermission();
    }

    if (permission ==
        LocationPermission.denied) {
      return false;
    }

    if (permission ==
        LocationPermission.deniedForever) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Location permission required',
            ),
            content:
                const Text(
              'Please enable location '
              'permission from Android settings.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                ),
                child:
                    const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(
                    context,
                  );

                  await Geolocator
                      .openAppSettings();
                },
                child:
                    const Text(
                  'APP SETTINGS',
                ),
              ),
            ],
          );
        },
      );

      return false;
    }

    return true;
  }

  // ==========================================================
  // GET CURRENT LOCATION
  // ==========================================================

  Future<void>
      _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        loadingLocation =
            true;
      });
    }

    try {
      final permission =
          await _checkLocationPermission();

      if (!permission) {
        if (mounted) {
          setState(() {
            loadingLocation =
                false;
          });
        }

        return;
      }

      final position =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        currentPosition =
            position;

        loadingLocation =
            false;
      });

      _calculateDistance();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingLocation =
            false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Location error: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // SEARCH DESTINATIONS
  // ==========================================================

  Future<void>
      _searchDestinations() async {
    final originalQuery =
        destinationSearchController
            .text
            .trim();

    if (originalQuery.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a destination first.',
          ),
        ),
      );

      return;
    }

    FocusScope.of(context)
        .unfocus();

    setState(() {
      searchingDestination =
          true;

      searchResults = [];
    });

    try {
      /*
       * Add India to the query.
       *
       * Example:
       *
       * Dhule Bus Stand
       *
       * becomes:
       *
       * Dhule Bus Stand, India
       */

      String query =
          originalQuery;

      final lowerQuery =
          originalQuery
              .toLowerCase();

      if (!lowerQuery
          .contains('india')) {
        query =
            '$query, India';
      }

      // ------------------------------------------------------
      // Build Nominatim parameters
      // ------------------------------------------------------

      final Map<String, String>
          parameters = {
        'q': query,
        'format': 'jsonv2',
        'limit': '10',
        'countrycodes': 'in',
        'addressdetails': '1',
        'accept-language': 'en',
      };

      // ------------------------------------------------------
      // Focus search around current GPS position
      // ------------------------------------------------------

      if (currentPosition !=
          null) {
        final lat =
            currentPosition!
                .latitude;

        final lon =
            currentPosition!
                .longitude;

        // Approximately 55 km in each direction.
        const double offset =
            0.5;

        final left =
            lon - offset;

        final right =
            lon + offset;

        final top =
            lat + offset;

        final bottom =
            lat - offset;

        parameters['viewbox'] =
            '$left,$top,$right,$bottom';
      }

      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        parameters,
      );

      debugPrint(
        'Nominatim URL: $uri',
      );

      final response =
          await http.get(
        uri,
        headers: {
          /*
           * Nominatim requires
           * an identifying User-Agent.
           */
          'User-Agent':
              'DestinationAlarm/1.0 '
              '(Flutter Android app)',
          'Accept':
              'application/json',
        },
      );

      debugPrint(
        'Nominatim status: '
        '${response.statusCode}',
      );

      if (response.statusCode !=
          200) {
        throw Exception(
          'Search failed: '
          '${response.statusCode}',
        );
      }

      final decoded =
          jsonDecode(
        response.body,
      );

      if (decoded is! List) {
        throw Exception(
          'Invalid search response.',
        );
      }

      final results =
          decoded
              .map<
                  DestinationResult>(
        (item) {
          final map =
              item as Map<
                  String,
                  dynamic>;

          return DestinationResult(
            name:
                _extractPlaceName(
              map,
            ),
            displayName:
                map['display_name']
                        ?.toString() ??
                    '',
            latitude:
                double.parse(
              map['lat']
                  .toString(),
            ),
            longitude:
                double.parse(
              map['lon']
                  .toString(),
            ),
          );
        },
      ).toList();

      if (!mounted) return;

      setState(() {
        searchResults =
            results;

        searchingDestination =
            false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'No exact result found for '
              '"$originalQuery". '
              'Try adding the city name.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        searchingDestination =
            false;
      });

      debugPrint(
        'NOMINATIM SEARCH ERROR: $e',
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Search error: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // EXTRACT PLACE NAME
  // ==========================================================

  String _extractPlaceName(
    Map<String, dynamic> map,
  ) {
    final address =
        map['address'];

    if (address
        is Map<String, dynamic>) {
      final possibleNames = [
        address['amenity'],
        address['bus_station'],
        address['train_station'],
        address['station'],
        address['shop'],
        address['school'],
        address['college'],
        address['hospital'],
        address['road'],
        address['village'],
        address['town'],
        address['city'],
        address['municipality'],
      ];

      for (final value
          in possibleNames) {
        if (value != null &&
            value
                .toString()
                .trim()
                .isNotEmpty) {
          return value
              .toString();
        }
      }
    }

    final displayName =
        map['display_name']
            ?.toString();

    if (displayName != null &&
        displayName.isNotEmpty) {
      return displayName
          .split(',')
          .first
          .trim();
    }

    return 'Selected destination';
  }

  // ==========================================================
  // SELECT DESTINATION
  // ==========================================================

  void _selectDestination(
    DestinationResult result,
  ) {
    setState(() {
      destinationPosition =
          Position(
        longitude:
            result.longitude,
        latitude:
            result.latitude,
        timestamp:
            DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      selectedDestinationName =
          result.name;

      selectedDestinationAddress =
          result.displayName;

      distanceToDestination =
          0;

      searchResults = [];

      destinationSearchController
          .text = result.name;
    });

    _calculateDistance();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          'Destination selected: '
          '${result.name}',
        ),
      ),
    );
  }

  // ==========================================================
  // DISTANCE CALCULATION
  // ==========================================================

  void _calculateDistance() {
    if (currentPosition == null ||
        destinationPosition ==
            null) {
      return;
    }

    final distance =
        Geolocator
            .distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      destinationPosition!
          .latitude,
      destinationPosition!
          .longitude,
    );

    if (!mounted) return;

    setState(() {
      distanceToDestination =
          distance;
    });
  }

  // ==========================================================
  // START JOURNEY
  // ==========================================================

  Future<void>
      _startJourney() async {
    if (destinationPosition ==
        null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'First select a destination.',
          ),
        ),
      );

      return;
    }

    final permission =
        await _checkLocationPermission();

    if (!permission) {
      return;
    }

    final service =
        FlutterBackgroundService();

    final running =
        await service.isRunning();

    if (!running) {
      await service.startService();

      await Future.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );
    }

    service.invoke(
      'startTracking',
      {
        'latitude':
            destinationPosition!
                .latitude,
        'longitude':
            destinationPosition!
                .longitude,
        'radius':
            selectedRadius,
      },
    );

    if (!mounted) return;

    setState(() {
      journeyStartDistance =
          distanceToDestination > 0
              ? distanceToDestination
              : 0;

      trackingLocation = true;

      serviceStatus =
          'Starting tracking...';
    });

    _trackingPulseController.repeat();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Background journey tracking started.',
        ),
      ),
    );
  }

  // ==========================================================
  // STOP JOURNEY
  // ==========================================================

  Future<void>
      _stopJourney() async {
    final service =
        FlutterBackgroundService();

    service.invoke(
      'stopTracking',
    );

    if (!mounted) return;

    setState(() {
      trackingLocation = false;

      serviceStatus =
          'Stopped';
    });

    _trackingPulseController.stop();
    _trackingPulseController.reset();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Journey stopped.',
        ),
      ),
    );
  }

  // ==========================================================
  // RADIUS TEXT
  // ==========================================================

  String _radiusText(
    int radius,
  ) {
    if (radius >= 1000) {
      final km =
          radius / 1000;

      if (km ==
          km.roundToDouble()) {
        return '${km.toInt()} km';
      }

      return '$km km';
    }

    return '$radius m';
  }

  // ==========================================================
  // DISTANCE TEXT
  // ==========================================================

  String _distanceText(
    double distance,
  ) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    }

    return '${(distance / 1000).toStringAsFixed(2)} km';
  }

  // ==========================================================
  // PREMIUM DARK NEUMORPHIC UI
  // ==========================================================

  static const Color _neoBg = Color(0xFF0B0F0E);
  static const Color _neoSurface = Color(0xFF171A19);
  static const Color _neoSurface2 = Color(0xFF121615);
  static const Color _neoHighlight = Color(0xFF242927);
  static const Color _neoShadow = Color(0xFF070909);
  static const Color _neoGreen = Color(0xFF20C878);
  static const Color _neoText = Color(0xFFF4F5F4);
  static const Color _neoMuted = Color(0xFF9A9F9C);
  static const Color _neoDim = Color(0xFF6F7773);

  // Clean dark-card visual language inspired by the reference UI.
  // Green is the product accent; depth stays subtle.
  BoxDecoration _raisedDecoration({
    double radius = 22,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? _neoSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0xFF202523),
        width: 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x50000000),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    );
  }

  BoxDecoration _pressedDecoration({
    double radius = 18,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? _neoSurface2,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0xFF202523),
        width: 1,
      ),
    );
  }

  Widget _neoCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 22,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: _raisedDecoration(
        radius: radius,
        color: color,
      ),
      child: child,
    );
  }

  Widget _neoIcon({
    required IconData icon,
    double size = 44,
    double iconSize = 21,
    bool active = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF123A27)
            : const Color(0xFF1D211F),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: active ? _neoGreen : const Color(0xFFB3B8B5),
      ),
    );
  }

  Widget _neoPill({
    required String text,
    required IconData icon,
    bool active = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF123725)
            : const Color(0xFF1C211F),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active ? _neoGreen : _neoMuted,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: active ? _neoGreen : _neoMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neoBg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: trackingLocation
              ? _buildActiveJourneyScreen()
              : _buildSetupScreen(),
        ),
      ),
    );
  }

  // ==========================================================
  // SETUP SCREEN
  // ==========================================================

  Widget _buildSetupScreen() {
    return RefreshIndicator(
      key: const ValueKey('setup'),
      onRefresh: _getCurrentLocation,
      color: _neoGreen,
      backgroundColor: _neoSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNeoTopBar(),

            const SizedBox(height: 30),

            const Text(
              'NEVER MISS YOUR STOP.',
              style: TextStyle(
                color: _neoDim,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.7,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Where are you going?',
              style: TextStyle(
                color: _neoText,
                fontSize: 29,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 24),

            _buildNeoLocationCard(),

            const SizedBox(height: 18),

            _buildNeoDestinationCard(),

            const SizedBox(height: 18),

            _buildNeoRadiusCard(),

            const SizedBox(height: 22),

            _buildNeoStartButton(),

            const SizedBox(height: 16),

            _buildNeoReadyStatus(),

            const SizedBox(height: 18),

            const Center(
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  color: Color(0xFF46534D),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ACTIVE JOURNEY
  // ==========================================================

  Widget _buildActiveJourneyScreen() {
    return Column(
      key: const ValueKey('active'),
      children: [
        _buildNeoActiveHeader(),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
            child: Column(
              children: [
                _buildNeoDistanceCard(),

                const SizedBox(height: 18),

                _buildNeoJourneyProgress(),

                const SizedBox(height: 18),

                _buildNeoMetrics(),

                const SizedBox(height: 18),

                _buildNeoActiveDestination(),

                const SizedBox(height: 24),

                _buildNeoStopButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _buildNeoTopBar() {
    return Row(
      children: [
        _neoIcon(
          icon: Icons.notifications_active_rounded,
          size: 52,
          iconSize: 25,
          active: true,
        ),

        const SizedBox(width: 15),

        const Expanded(
          child: Text(
            'Destination Alarm',
            style: TextStyle(
              color: _neoText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),

        GestureDetector(
          onTap: loadingLocation ? null : _getCurrentLocation,
          child: _neoIcon(
            icon: Icons.my_location_rounded,
            size: 46,
            iconSize: 21,
          ),
        ),
      ],
    );
  }

  Widget _buildNeoActiveHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          _neoIcon(
            icon: Icons.navigation_rounded,
            size: 48,
            iconSize: 23,
            active: true,
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JOURNEY ACTIVE',
                  style: TextStyle(
                    color: _neoGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Destination Alarm',
                  style: TextStyle(
                    color: _neoText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          AnimatedBuilder(
            animation: _trackingPulseController,
            builder: (context, child) {
              final opacity =
                  0.45 + (_trackingPulseController.value * 0.55);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: _pressedDecoration(
                  radius: 20,
                  color: const Color(0xFF0C2017),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: opacity,
                      child: const Icon(
                        Icons.circle,
                        size: 7,
                        color: _neoGreen,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: _neoGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LOCATION CARD
  // ==========================================================

  Widget _buildNeoLocationCard() {
    final accuracy = currentPosition?.accuracy ?? 0;

    return _neoCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Row(
        children: [
          _neoIcon(
            icon: Icons.gps_fixed_rounded,
            size: 48,
            iconSize: 22,
            active: true,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT LOCATION',
                  style: TextStyle(
                    color: _neoDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currentPosition == null
                      ? 'Location unavailable'
                      : accuracy > 0
                          ? 'GPS ready · ±${accuracy.toStringAsFixed(0)} m'
                          : 'GPS location ready',
                  style: const TextStyle(
                    color: Color(0xFFD5E0DB),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: loadingLocation ? null : _getCurrentLocation,
            child: _neoIcon(
              icon: loadingLocation
                  ? Icons.hourglass_top_rounded
                  : Icons.refresh_rounded,
              size: 43,
              iconSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DESTINATION CARD
  // ==========================================================

  Widget _buildNeoDestinationCard() {
    return _neoCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _neoIcon(
                icon: Icons.location_on_rounded,
                size: 42,
                iconSize: 20,
                active: true,
              ),
              const SizedBox(width: 11),
              const Text(
                'DESTINATION',
                style: TextStyle(
                  color: _neoDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            decoration: _pressedDecoration(
              radius: 18,
              color: const Color(0xFF0C1813),
            ),
            child: TextField(
              controller: destinationSearchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchDestinations(),
              style: const TextStyle(
                color: _neoText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Search destination',
                hintStyle: const TextStyle(
                  color: Color(0xFF63716A),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _neoGreen,
                  size: 21,
                ),
                suffixIcon:
                    destinationSearchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              destinationSearchController.clear();
                              setState(() {
                                searchResults = [];
                              });
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _neoMuted,
                            ),
                          )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 16,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 14),

          _buildNeoSearchButton(),

          if (searchResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNeoSearchResults(),
          ],

          if (destinationPosition != null) ...[
            const SizedBox(height: 14),
            _buildNeoSelectedDestination(),
          ],
        ],
      ),
    );
  }

  Widget _buildNeoSearchButton() {
    final busy = searchingDestination;

    return GestureDetector(
      onTap: busy ? null : _searchDestinations,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        width: double.infinity,
        decoration: busy
            ? _pressedDecoration(
                radius: 17,
                color: const Color(0xFF123323),
              )
            : BoxDecoration(
                color: _neoGreen,
                borderRadius: BorderRadius.circular(17),
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _neoGreen,
                    ),
                  )
                : const Icon(
                    Icons.travel_explore_rounded,
                    color: Color(0xFF07110D),
                    size: 20,
                  ),
            const SizedBox(width: 9),
            Text(
              busy ? 'SEARCHING...' : 'SEARCH DESTINATION',
              style: const TextStyle(
                color: Color(0xFF07110D),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeoSearchResults() {
    return Container(
      decoration: _pressedDecoration(
        radius: 18,
        color: const Color(0xFF0B1712),
      ),
      child: Column(
        children: [
          ...searchResults.map(_buildNeoSearchResult),
        ],
      ),
    );
  }

  Widget _buildNeoSearchResult(DestinationResult result) {
    return InkWell(
      onTap: () => _selectDestination(result),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: _neoGreen,
              size: 20,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _neoText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _neoDim,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF4D5B53),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeoSelectedDestination() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _pressedDecoration(
        radius: 17,
        color: const Color(0xFF0B1B14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: _neoGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedDestinationName.isEmpty
                      ? 'Destination selected'
                      : selectedDestinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDCE8E3),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (selectedDestinationAddress.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    selectedDestinationAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _neoDim,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _distanceText(distanceToDestination),
            style: const TextStyle(
              color: _neoGreen,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RADIUS
  // ==========================================================

  Widget _buildNeoRadiusCard() {
    const values = [
      500,
      1000,
      2000,
      3000,
      5000,
    ];

    return _neoCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ALARM RADIUS',
                  style: TextStyle(
                    color: _neoDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              _neoPill(
                text: _radiusText(selectedRadius),
                icon: Icons.radar_rounded,
                active: true,
              ),
            ],
          ),

          const SizedBox(height: 17),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: values.map((value) {
                final selected = selectedRadius == value;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRadius = value;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      decoration: selected
                          ? BoxDecoration(
                              color: _neoGreen,
                              borderRadius: BorderRadius.circular(15),
                            )
                          : _raisedDecoration(
                              radius: 15,
                              color: const Color(0xFF1A1E1D),
                            ),
                      child: Text(
                        _radiusText(value),
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF07110D)
                              : const Color(0xFFB4C0BA),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Alarm activates when you enter this distance from the destination.',
            style: TextStyle(
              color: _neoDim,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // START BUTTON
  // ==========================================================

  Widget _buildNeoStartButton() {
    final enabled = destinationPosition != null && !loadingLocation;

    return GestureDetector(
      onTap: enabled ? _startJourney : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 62,
        decoration: enabled
            ? BoxDecoration(
                color: _neoGreen,
                borderRadius: BorderRadius.circular(20),
              )
            : _pressedDecoration(
                radius: 20,
                color: const Color(0xFF171A19),
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              size: 25,
              color: enabled ? const Color(0xFF07110D) : const Color(0xFF59615D),
            ),
            const SizedBox(width: 9),
            Text(
              'START JOURNEY',
              style: TextStyle(
                color: enabled ? const Color(0xFF07110D) : const Color(0xFF737A76),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeoReadyStatus() {
    final hasDestination = destinationPosition != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      decoration: _pressedDecoration(
        radius: 18,
        color: const Color(0xFF0B1712),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: hasDestination ? _neoGreen : const Color(0xFF68756E),
              shape: BoxShape.circle,
              boxShadow: hasDestination
                  ? const [
                      BoxShadow(
                        color: Color(0x3019C37D),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              hasDestination
                  ? 'Ready to monitor your journey in background'
                  : 'Select a destination to continue',
              style: const TextStyle(
                color: _neoMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIVE DISTANCE
  // ==========================================================

  Widget _buildNeoDistanceCard() {
    final accuracy = currentPosition?.accuracy ?? 0;

    return _neoCard(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
      radius: 24,
      color: const Color(0xFF11201A),
      child: Column(
        children: [
          const Text(
            'DISTANCE TO DESTINATION',
            style: TextStyle(
              color: _neoDim,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _distanceText(distanceToDestination),
            style: const TextStyle(
              color: _neoText,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.7,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            selectedDestinationName.isEmpty
                ? 'Destination'
                : selectedDestinationName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _neoMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 19),

          Container(
            height: 1,
            color: const Color(0xFF1A2922),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gps_fixed_rounded,
                size: 15,
                color: _neoGreen,
              ),
              const SizedBox(width: 7),
              Text(
                accuracy > 0
                    ? 'GPS accuracy ${accuracy.toStringAsFixed(0)} m'
                    : 'GPS accuracy unavailable',
                style: const TextStyle(
                  color: _neoMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // JOURNEY PROGRESS
  // ==========================================================

  Widget _buildNeoJourneyProgress() {
    final start = journeyStartDistance > 0
        ? journeyStartDistance
        : distanceToDestination;

    double progress = 0;

    if (start > 0) {
      progress =
          ((start - distanceToDestination) / start).clamp(0.0, 1.0);
    }

    final insideRadius =
        distanceToDestination <= selectedRadius.toDouble();

    return _neoCard(
      padding: const EdgeInsets.all(18),
      radius: 23,
      color: insideRadius
          ? const Color(0xFF10251B)
          : const Color(0xFF101C17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'JOURNEY PROGRESS',
                  style: TextStyle(
                    color: _neoDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _neoGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            height: 12,
            padding: const EdgeInsets.all(3),
            decoration: _pressedDecoration(
              radius: 10,
              color: const Color(0xFF0A1511),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _neoGreen,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x6619C37D),
                          blurRadius: 7,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 15,
                color: _neoMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Alarm zone: ${_radiusText(selectedRadius)}',
                  style: const TextStyle(
                    color: _neoMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _neoPill(
                text: insideRadius ? 'ALARM ZONE' : 'TRACKING',
                icon: insideRadius
                    ? Icons.notifications_active_rounded
                    : Icons.radar_rounded,
                active: insideRadius,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // METRICS
  // ==========================================================

  Widget _buildNeoMetrics() {
    final accuracy = currentPosition?.accuracy ?? 0;

    String gpsState;

    if (accuracy <= 0) {
      gpsState = 'SEARCHING';
    } else if (accuracy <= 20) {
      gpsState = 'GOOD';
    } else if (accuracy <= 50) {
      gpsState = 'FAIR';
    } else {
      gpsState = 'WEAK';
    }

    return Row(
      children: [
        Expanded(
          child: _buildNeoMetricCard(
            icon: Icons.gps_fixed_rounded,
            label: 'GPS',
            value: accuracy > 0
                ? '${accuracy.toStringAsFixed(0)} m'
                : '--',
            state: gpsState,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildNeoMetricCard(
            icon: Icons.radar_rounded,
            label: 'ALARM',
            value: _radiusText(selectedRadius),
            state: 'RADIUS',
          ),
        ),
      ],
    );
  }

  Widget _buildNeoMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String state,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _raisedDecoration(
        radius: 20,
        color: const Color(0xFF101C17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _neoIcon(
            icon: icon,
            size: 38,
            iconSize: 18,
            active: true,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: _neoDim,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _neoText,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            state,
            style: const TextStyle(
              color: _neoMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIVE DESTINATION
  // ==========================================================

  Widget _buildNeoActiveDestination() {
    return _neoCard(
      padding: const EdgeInsets.all(17),
      radius: 22,
      child: Row(
        children: [
          _neoIcon(
            icon: Icons.location_on_rounded,
            size: 46,
            iconSize: 22,
            active: true,
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESTINATION',
                  style: TextStyle(
                    color: _neoDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  selectedDestinationName.isEmpty
                      ? 'Selected destination'
                      : selectedDestinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _neoText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const Icon(
            Icons.check_circle_rounded,
            color: _neoGreen,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STOP JOURNEY
  // ==========================================================

  Widget _buildNeoStopButton() {
    return GestureDetector(
      onTap: _stopJourney,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: _raisedDecoration(
          radius: 20,
          color: const Color(0xFF191615),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.stop_circle_rounded,
              color: Color(0xFFE66A63),
              size: 24,
            ),
            const SizedBox(width: 9),
            const Text(
              'STOP JOURNEY',
              style: TextStyle(
                color: Color(0xFFE58A83),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

