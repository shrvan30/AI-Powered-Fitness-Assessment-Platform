import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false, _obscurePassword = true, _rememberMe = false;

  late AnimationController _fadeController, _scaleController;
  late Animation<double> _fadeAnimation, _scaleAnimation;

  final _focusNodes = {'email': FocusNode(), 'password': FocusNode()};

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _scaleAnimation = Tween(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    for (var n in _focusNodes.values) n.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  Future<void> _handleLogin() async {
    final email = emailController.text.trim(), pass = passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) return _showSnackbar('Please fill in all fields', Colors.red);
    if (!_isValidEmail(email)) return _showSnackbar('Enter a valid email', Colors.orange);

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    _showSnackbar('Login successful!', Colors.green);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    _showSnackbar('$provider login successful!', Colors.green);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.9)),

        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // Back
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 8),
                  const Text('Back', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ]),
                const SizedBox(height: 40),

                const Text("Welcome Back",
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  "Sign in to continue your athletic journey.\nTrack your progress and achieve your goals.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                _buildSectionHeader('Account Access', Icons.login),
                const SizedBox(height: 24),

                _buildAnimatedField("Email Address", emailController, _focusNodes['email']!,
                    keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
                const SizedBox(height: 16),

                _buildAnimatedField("Password", passwordController, _focusNodes['password']!,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white60,
                          size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )),
                const SizedBox(height: 16),

                // Remember + Forgot
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    AnimatedScale(
                      scale: _rememberMe ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        activeColor: Colors.green,
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: const Text('Remember me',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                  ]),
                  TextButton(
                    onPressed: () => _showSnackbar('Password reset link sent!', Colors.blue),
                    child: const Text("Forgot Password?",
                        style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ]),
                const SizedBox(height: 24),

                // Sign In
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        _scaleController.forward().then((_) => _scaleController.reverse());
                        _handleLogin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                      ),
                      child: _isLoading
                          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                        SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text("Signing In...",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ])
                          : const Text("Sign In",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Divider
                Row(children: [
                  Expanded(child: Container(height: 1, color: Colors.white30)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("or continue with",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  ),
                  Expanded(child: Container(height: 1, color: Colors.white30)),
                ]),
                const SizedBox(height: 24),

                // Social buttons
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _buildSocialButton('Google', 'assets/logos/google.png',
                          () => _handleSocialLogin('Google')),
                  _buildSocialButton('Apple', 'assets/logos/apple.png',
                          () => _handleSocialLogin('Apple')),
                ]),
                const SizedBox(height: 32),

                // Sign Up link
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account?",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                    child: const Text("Sign Up",
                        style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ]),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
    const SizedBox(width: 12),
    Text(title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
  ]);

  Widget _buildAnimatedField(String label, TextEditingController controller, FocusNode node,
      {TextInputType keyboardType = TextInputType.text,
        IconData? prefixIcon,
        Widget? suffixIcon,
        bool obscureText = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: node.hasFocus ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: node.hasFocus ? Colors.white60 : Colors.white30,
              width: node.hasFocus ? 2 : 1),
        ),
        child: TextField(
          controller: controller,
          focusNode: node,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.white60, size: 20)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    ]);
  }

  Widget _buildSocialButton(String label, String asset, VoidCallback onTap) => GestureDetector(
    onTap: _isLoading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 8, spreadRadius: 1)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(asset, height: 24, width: 24),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}
