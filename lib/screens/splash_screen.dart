// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/settings_provider.dart';
// import '../models/settings.dart';
// import 'home_screen.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
//       ),
//     );

//     _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
//       ),
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.5),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
//       ),
//     );

//     _controller.forward();

//     Future.delayed(const Duration(milliseconds: 2500), () {
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           PageRouteBuilder(
//             pageBuilder: (context, animation, secondaryAnimation) =>
//                 const HomeScreen(),
//             transitionsBuilder:
//                 (context, animation, secondaryAnimation, child) {
//               return FadeTransition(opacity: animation, child: child);
//             },
//             transitionDuration: const Duration(milliseconds: 500),
//           ),
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark =
//         context.watch<SettingsProvider>().brightnessMode == BrightnessMode.DARK;
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: isDark ? Colors.black : Colors.white,
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: isDark
//                 ? [Colors.black, Colors.deepPurple.shade900]
//                 : [Colors.white, Colors.deepPurple.shade50],
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Animated Icon
//               ScaleTransition(
//                 scale: _scaleAnimation,
//                 child: FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: isDark
//                           ? Colors.deepPurple.shade800
//                           : Colors.deepPurple.shade100,
//                       borderRadius: BorderRadius.circular(30),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.deepPurple.withOpacity(0.3),
//                           blurRadius: 20,
//                           spreadRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.book_rounded,
//                       size: 100,
//                       color: Colors.deepPurple,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//               // Animated Text
//               SlideTransition(
//                 position: _slideAnimation,
//                 child: FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: Column(
//                     children: [
//                       Text(
//                         'MangaReader',
//                         style: TextStyle(
//                           fontSize: 40,
//                           fontWeight: FontWeight.bold,
//                           color: isDark ? Colors.white : Colors.black,
//                           letterSpacing: 2,
//                           shadows: [
//                             Shadow(
//                               color: Colors.deepPurple.withOpacity(0.5),
//                               offset: const Offset(2, 2),
//                               blurRadius: 4,
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Powered by MangaDex',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: isDark ? Colors.white70 : Colors.black54,
//                           letterSpacing: 1,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class ParticleModel {
  Offset position;
  double speed;
  double theta;
  double radius;

  ParticleModel({
    required this.position,
    required this.speed,
    required this.theta,
    required this.radius,
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class WaveClipper extends CustomClipper<Path> {
  final double animation;

  WaveClipper(this.animation);

  @override
  Path getClip(Size size) {
    final path = Path();
    final y = sin(animation * 2 * pi) * 20 + 30;

    path.lineTo(0, size.height * 0.8 + y);

    for (var i = 0; i < size.width; i++) {
      path.lineTo(
          i.toDouble(),
          size.height * 0.8 +
              sin((i / size.width) * 4 * pi + animation * 2 * pi) * 20 +
              y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) => true;
}

// Add this new class for custom loading animation
class LoadingIndicator extends StatelessWidget {
  final Animation<double> animation;

  const LoadingIndicator({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer circle
            Transform.rotate(
              angle: animation.value * 2 * pi,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.5),
                ),
                strokeWidth: 2,
              ),
            ),
            // Inner circle
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.9),
                ),
                strokeWidth: 3,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _taglineAnimation;
  late Animation<double> _loadingAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late AnimationController _rotationController;

  final List<ParticleModel> particles = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _setupAnimations();
    _navigateToLogin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (particles.isEmpty) {
      _initializeParticles();
    }
  }

  void _initializeParticles() {
    final size = MediaQuery.of(context).size;
    for (int i = 0; i < 50; i++) {
      particles.add(
        ParticleModel(
          position: Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
          ),
          speed: 0.5 + random.nextDouble() * 2,
          theta: random.nextDouble() * 2 * pi,
          radius: 1 + random.nextDouble() * 4,
        ),
      );
    }
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _taglineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeIn),
      ),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient with animated colors
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                        _controller.value,
                      )!,
                      Color.lerp(
                        Colors.blue.shade800,
                        Colors.purple.shade800,
                        _controller.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated wave background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, _) {
                return ClipPath(
                  clipper: WaveClipper(_waveAnimation.value),
                  child: Container(
                    color: Colors.white.withOpacity(0.1),
                  ),
                );
              },
            ),
          ),

          // Enhanced particle effect
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles,
                  _particleController.value,
                  glowRadius: 20,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with animations
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Rotating glow effect
                              Transform.rotate(
                                angle: _rotationController.value * 2 * pi,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Logo icon
                              const Icon(
                                Icons.book_rounded,
                                size: 100,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // App name with enhanced shadow
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'MangaReader',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                            Shadow(
                              color: Colors.black12,
                              offset: Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tagline with enhanced animation
                    FadeTransition(
                      opacity: _taglineAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _controller,
                          curve:
                              const Interval(0.5, 0.7, curve: Curves.easeOut),
                        )),
                        child: Text(
                          'Powered by MangaDex',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Custom loading indicator
                    FadeTransition(
                      opacity: _loadingAnimation,
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: LoadingIndicator(animation: _rotationController),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Add shimmer effect to version number
          Positioned(
            bottom: 24,
            right: 24,
            child: ShimmerText(
              'Version 0.1.0',
              baseColor: Colors.white.withOpacity(0.6),
              highlightColor: Colors.white,
              duration: const Duration(seconds: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;
  final double animation;
  final double glowRadius;

  ParticlePainter(this.particles, this.animation, {this.glowRadius = 20});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      var progress = (animation * particle.speed) % 1.0;
      var offset = Offset(
        particle.position.dx + cos(particle.theta) * progress * 100,
        particle.position.dy + sin(particle.theta) * progress * 100,
      );

      // Particle glow effect
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(offset, particle.radius + glowRadius, glowPaint);

      // Particle core
      final corePaint = Paint()..color = Colors.white.withOpacity(0.6);
      canvas.drawCircle(offset, particle.radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class ShimmerText extends StatefulWidget {
  final String text;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerText(
    this.text, {
    required this.baseColor,
    required this.highlightColor,
    required this.duration,
    super.key,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = sin(_shimmerController.value * 2 * pi);
        return Text(
          widget.text,
          style: TextStyle(
            color: Color.lerp(
              widget.baseColor,
              widget.highlightColor,
              shimmerValue,
            ),
            fontSize: 12,
          ),
        );
      },
    );
  }
}
