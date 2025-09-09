import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _ballController;
  late Animation<double> _ballAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 🔹 Basketball drop controller
    _ballController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _ballAnimation = CurvedAnimation(
      parent: _ballController,
      curve: Curves.easeInOut,
    );

    // Scale animation (small → big → small)
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.6)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.6, end: 0.4)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_ballController);

    // Rotation animation for ball spin
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_ballController);

    // Trigger drop
    _ballController.forward().whenComplete(() {
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _slideController.forward();
      });
    });

    // 🔹 Fade + slide controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _ballController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Dark overlay to keep theme consistent
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 🔹 Basketball falling + dodging animation
            AnimatedBuilder(
              animation: _ballAnimation,
              builder: (context, child) {
                double dodgeOffset =
                    (((_ballAnimation.value * 6) % 2) - 1).abs() * 200 - 100;

                return Positioned(
                  top: _ballAnimation.value * (screenHeight + 150) - 100,
                  left: (screenWidth / 2 - 50) + dodgeOffset,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Image.asset(
                        "assets/images/basketball.png",
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Main content (only appears after ball drops)
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildMainContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          const Text(
            'NextChampions',
            style: TextStyle(
              fontSize: 26,  // Changed from 42 to match signup page main title
              fontWeight: FontWeight.bold,  // Changed from w300 to bold
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Journey to Excellence Begins Here',
            style: TextStyle(
              fontSize: 14,  // Changed from 16 to match signup page descriptions
              color: Colors.white70,
              fontWeight: FontWeight.normal,  // Changed from w300 to normal
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Text(
              'Welcome to NextChampions!\n\nDiscover your potential, track your progress, and become the champion you were meant to be.',
              style: TextStyle(
                fontSize: 14,  // Changed from 16 to match signup page descriptions
                color: Colors.white70,
                height: 1.6,
                fontWeight: FontWeight.normal,  // Changed from w300 to normal
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(flex: 2),

          // 🔹 Two identical smaller buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 140, // smaller width
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16), // Changed from 12 to match signup page
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Changed from 8 to match signup page
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 16,  // Added explicit font size to match signup page buttons
                      fontWeight: FontWeight.bold,  // Added bold weight
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140, // smaller width
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16), // Changed from 12 to match signup page
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Changed from 8 to match signup page
                    ),
                  ),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 16,  // Added explicit font size to match signup page buttons
                      fontWeight: FontWeight.bold,  // Added bold weight
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),
          const Text(
            '© 2024 NextChampions. All rights reserved.',
            style: TextStyle(fontSize: 12, color: Colors.white38), // Kept same as it matches signup page small text
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}