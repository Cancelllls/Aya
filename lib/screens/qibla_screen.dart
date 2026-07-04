import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';

class QiblaScreen extends StatefulWidget {
  final StorageService storage;

  const QiblaScreen({super.key, required this.storage});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  double _qiblaAngle = 0;
  double _startHeading = 0.0;
  double _endHeading = 0.0;
  double _manualHeading = 0.0;
  late AnimationController _animationController;
  late CurvedAnimation _curvedAnimation;
  String _locationName = "Cairo, Egypt";
  Map<String, dynamic>? _lastLoadedLocation;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasSensor = true;
  bool _wasAligned = false;

  double get _currentHeading {
    if (_hasSensor) {
      return _startHeading +
          (_endHeading - _startHeading) * _curvedAnimation.value;
    } else {
      return _manualHeading;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.addListener(() {
      final heading = _currentHeading;
      final relativeAngle = (_qiblaAngle - heading + 360.0) % 360.0;
      final isAligned = (relativeAngle < 5 || relativeAngle > 355);
      if (isAligned) {
        if (!_wasAligned) {
          _wasAligned = true;
          HapticFeedback.mediumImpact();
        }
      } else {
        _wasAligned = false;
      }
    });

    _calculateQiblaDirection();
    _initCompass();
  }

  void _initCompass() {
    try {
      _compassSubscription = FlutterCompass.events?.listen(
        (event) {
          if (mounted && event.heading != null) {
            final target = (event.heading! + 360.0) % 360.0;
            final current = _currentHeading;

            double diff = target - (current % 360.0);
            while (diff < -180.0) {
              diff += 360.0;
            }
            while (diff > 180.0) {
              diff -= 360.0;
            }

            _startHeading = current;
            _endHeading = current + diff;

            _animationController.forward(from: 0.0);

            if (!_hasSensor) {
              setState(() {
                _hasSensor = true;
              });
            }
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _hasSensor = false;
            });
          }
        },
      );
    } catch (_) {
      setState(() {
        _hasSensor = false;
      });
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _updateManualHeading(double newHeading) {
    final relativeAngle = (_qiblaAngle - newHeading + 360.0) % 360.0;
    final isAligned = (relativeAngle < 5 || relativeAngle > 355);
    if (isAligned) {
      if (!_wasAligned) {
        _wasAligned = true;
        HapticFeedback.mediumImpact();
      }
    } else {
      _wasAligned = false;
    }
    setState(() {
      _manualHeading = newHeading;
    });
  }

  void _calculateQiblaDirection() {
    final loc = widget.storage.getLocation();
    final double lat = loc['latitude'] ?? 30.0444;
    final double lng = loc['longitude'] ?? 31.2357;

    // Kaaba Coordinates
    const double latK = 21.4225 * pi / 180.0;
    const double lngK = 39.8262 * pi / 180.0;

    final double phi = lat * pi / 180.0;
    final double lambda = lng * pi / 180.0;

    final double deltaLambda = lngK - lambda;

    final double y = sin(deltaLambda);
    final double x = cos(phi) * tan(latK) - sin(phi) * cos(deltaLambda);

    double qiblaRad = atan2(y, x);
    double qiblaDeg = (qiblaRad * 180.0 / pi + 360.0) % 360.0;

    setState(() {
      _qiblaAngle = qiblaDeg;
      _locationName = "${loc['city']}, ${loc['country']}";
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = widget.storage.getLocation();
    if (_lastLoadedLocation == null ||
        _lastLoadedLocation!['latitude'] != currentLocation['latitude'] ||
        _lastLoadedLocation!['longitude'] != currentLocation['longitude'] ||
        _lastLoadedLocation!['city'] != currentLocation['city']) {
      _lastLoadedLocation = currentLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateQiblaDirection();
      });
    }
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          TranslationService.t('qibla'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            // Info Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.12),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildStatColumn(
                    TranslationService.t('your_location'),
                    _locationName,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).dividerColor.withOpacity(0.12),
                  ),
                  _buildStatColumn(
                    TranslationService.t('qibla_angle'),
                    "${_qiblaAngle.toStringAsFixed(1)}° N",
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final heading = _currentHeading;
                final relativeAngle = (_qiblaAngle - heading + 360.0) % 360.0;
                final isAligned = (relativeAngle < 5 || relativeAngle > 355);

                return Column(
                  children: [
                    Text(
                      isAligned
                          ? (TranslationService.isArabic
                                ? "محاذاة مع الكعبة!"
                                : "Aligned with Kaaba!")
                          : (TranslationService.isArabic
                                ? "أدر الهاتف لمحاذاة الكعبة"
                                : "Rotate device to align with Kaaba"),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isAligned
                            ? const Color(0xFF10B981)
                            : (Theme.of(context).textTheme.bodyMedium?.color ??
                                      Colors.white)
                                  .withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 40),

                    // Interactive Rotating Compass
                    GestureDetector(
                      onPanUpdate: _hasSensor
                          ? null
                          : (details) {
                              _updateManualHeading(
                                _manualHeading + details.delta.dx * 1.5,
                              );
                            },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Compass Dial Background & Text
                          Transform.rotate(
                            angle: -heading * pi / 180.0,
                            child: Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isAligned
                                      ? const Color(0xFF10B981)
                                      : const Color(
                                          0xFFE5C158,
                                        ).withOpacity(0.5),
                                  width: isAligned ? 4 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isAligned
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFE5C158))
                                            .withOpacity(isAligned ? 0.3 : 0.1),
                                    blurRadius: isAligned ? 40 : 20,
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: CompassDialPainter(
                                  theme: Theme.of(context),
                                  isAligned: isAligned,
                                ),
                              ),
                            ),
                          ),

                          // Qibla needle pointing to Makkah
                          Transform.rotate(
                            angle: (relativeAngle - 90) * pi / 180.0,
                            child: SizedBox(
                              width: 230,
                              height: 230,
                              child: Stack(
                                children: [
                                  // Pointer Arrow
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 15),
                                      child: Icon(
                                        Icons.keyboard_arrow_right,
                                        color: isAligned
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFE5C158),
                                        size: isAligned ? 36 : 32,
                                      ),
                                    ),
                                  ),
                                  // Kaaba Icon at the tip
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 42),
                                      child: Transform.rotate(
                                        angle:
                                            (90 - relativeAngle) * pi / 180.0,
                                        child: Icon(
                                          Icons.mosque,
                                          color: isAligned
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFE5C158),
                                          size: isAligned ? 28 : 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Center Pin
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isAligned
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE5C158),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isAligned
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFE5C158))
                                          .withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 30),

            // Simulation Slider for Emulator
            const Spacer(),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final heading = _currentHeading;
                return Column(
                  children: [
                    Text(
                      _hasSensor
                          ? "${TranslationService.t('compass_active')}: ${(heading % 360).toInt()}° N"
                          : "Compass Simulator (No sensor detected): ${(heading % 360).toInt()}°",
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            (Theme.of(context).textTheme.bodyMedium?.color ??
                                    Colors.white)
                                .withOpacity(0.38),
                      ),
                    ),
                    if (!_hasSensor) ...[
                      Slider(
                        value: (heading % 360.0).clamp(0.0, 360.0),
                        min: 0,
                        max: 360,
                        activeColor: const Color(0xFFE5C158),
                        onChanged: _updateManualHeading,
                      ),
                      Text(
                        "Swipe/Drag the compass or use the slider to rotate.",
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              (Theme.of(context).textTheme.bodyMedium?.color ??
                                      Colors.white)
                                  .withOpacity(0.24),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Point the top of your device in the direction of the mosque.",
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                (Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color ??
                                        Colors.white)
                                    .withOpacity(0.24),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5C158).withOpacity(0.08),
                foregroundColor: const Color(0xFFE5C158),
                side: BorderSide(color: Color(0xFFE5C158), width: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.map, size: 20),
              label: Text(
                TranslationService.t('show_map_makkah').toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 12,
                ),
              ),
              onPressed: () async {
                final loc = widget.storage.getLocation();
                final double userLat = loc['latitude'] ?? 30.0444;
                final double userLng = loc['longitude'] ?? 31.2357;

                final url = Uri.parse(
                  "https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng&destination=21.4225,39.8262&travelmode=driving",
                );
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          TranslationService.isArabic
                              ? "خطأ في فتح الخرائط: $e"
                              : "Error opening maps: $e",
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color:
                  (Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.white)
                      .withOpacity(0.38),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class CompassDialPainter extends CustomPainter {
  final ThemeData theme;
  final bool isAligned;
  CompassDialPainter({required this.theme, required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer golden ring
    final outerRingPaint = Paint()
      ..color = const Color(0xFFE5C158).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 8, outerRingPaint);

    // Draw inner golden ring
    final innerRingPaint = Paint()
      ..color = const Color(0xFFE5C158).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 24, innerRingPaint);

    final paintText = TextPainter(textDirection: TextDirection.ltr);

    void drawLabel(String text, double angle, Color color) {
      paintText.text = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 6)],
        ),
      );
      paintText.layout();
      final labelRadius = radius - 40;
      final x =
          center.dx + labelRadius * cos(angle - pi / 2) - paintText.width / 2;
      final y =
          center.dy + labelRadius * sin(angle - pi / 2) - paintText.height / 2;
      paintText.paint(canvas, Offset(x, y));
    }

    // Draw Cardinal points
    drawLabel(
      "N",
      0,
      isAligned ? const Color(0xFF10B981) : const Color(0xFFE5C158),
    );
    drawLabel(
      "E",
      pi / 2,
      (theme.textTheme.bodyMedium?.color ?? Colors.white).withOpacity(0.7),
    );
    drawLabel(
      "S",
      pi,
      (theme.textTheme.bodyMedium?.color ?? Colors.white).withOpacity(0.7),
    );
    drawLabel(
      "W",
      3 * pi / 2,
      (theme.textTheme.bodyMedium?.color ?? Colors.white).withOpacity(0.7),
    );

    // Draw dial ticks
    final tickPaint = Paint()
      ..color = const Color(0xFFE5C158).withOpacity(0.2)
      ..strokeWidth = 1.5;

    final majorTickPaint = Paint()
      ..color = const Color(0xFFE5C158).withOpacity(0.5)
      ..strokeWidth = 2.5;

    for (int i = 0; i < 360; i += 10) {
      if (i % 90 == 0) continue;
      final angle = i * pi / 180;
      final isMajor = i % 30 == 0;
      final startRadius = radius - (isMajor ? 20 : 15);
      final endRadius = radius - 8;
      final start = Offset(
        center.dx + startRadius * cos(angle),
        center.dy + startRadius * sin(angle),
      );
      final end = Offset(
        center.dx + endRadius * cos(angle),
        center.dy + endRadius * sin(angle),
      );
      canvas.drawLine(start, end, isMajor ? majorTickPaint : tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CompassDialPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned || oldDelegate.theme != theme;
  }
}
