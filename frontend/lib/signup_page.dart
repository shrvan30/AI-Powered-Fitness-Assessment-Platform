import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io';
import 'dart:typed_data'; // For web image handling
import 'package:image_picker/image_picker.dart';
import 'dashboard_page.dart'; // Import your dashboard page

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final contactController = TextEditingController();
  final sportController = TextEditingController();
  final goalsController = TextEditingController();

  String gender = 'Male';
  String experience = 'Beginner';

  // Handle both mobile and web image storage
  File? _selfieFile; // For mobile
  Uint8List? _selfieBytes; // For web
  String? _selfieName; // For web filename

  bool _isLoading = false;
  bool _agreedToTerms = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Sports suggestions
  final List<String> sportSuggestions = [
    'Basketball', 'Football', 'Soccer', 'Tennis', 'Swimming',
    'Track & Field', 'Baseball', 'Volleyball', 'Boxing', 'Cricket'
  ];

  // Focus nodes for field animations
  final Map<String, FocusNode> _focusNodes = {
    'name': FocusNode(),
    'age': FocusNode(),
    'height': FocusNode(),
    'weight': FocusNode(),
    'contact': FocusNode(),
    'sport': FocusNode(),
    'goals': FocusNode(),
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    contactController.dispose();
    sportController.dispose();
    goalsController.dispose();
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!kIsWeb) // Camera only available on mobile
                    _buildPhotoOption(
                      'Camera',
                      Icons.camera_alt,
                          () => _takePicture(ImageSource.camera),
                    ),
                  _buildPhotoOption(
                    kIsWeb ? 'Choose File' : 'Gallery',
                    kIsWeb ? Icons.file_upload : Icons.photo_library,
                        () => _takePicture(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoOption(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        if (kIsWeb) {
          // For web, store as bytes
          final bytes = await picked.readAsBytes();
          setState(() {
            _selfieBytes = bytes;
            _selfieName = picked.name;
            _selfieFile = null; // Clear mobile file
          });
        } else {
          // For mobile, store as file
          setState(() {
            _selfieFile = File(picked.path);
            _selfieBytes = null; // Clear web bytes
            _selfieName = null;
          });
        }
        _showSnackbar('Photo selected successfully!', Colors.green);
      }
    } catch (e) {
      _showSnackbar('Unable to access ${source == ImageSource.camera ? 'camera' : 'gallery'}', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool get _hasProfilePhoto => _selfieFile != null || _selfieBytes != null;

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Please fill in all required fields', Colors.red);
      return;
    }

    if (!_hasProfilePhoto) {
      _showSnackbar('Please add a profile photo', Colors.orange);
      return;
    }

    if (!_agreedToTerms) {
      _showSnackbar('Please agree to terms and conditions', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    _showSnackbar('Profile created successfully!', Colors.green);

    // Navigate to dashboard
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage())
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age < 13 || age > 100) {
      return 'Enter a valid age (13-100)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required';
    }
    if (value.length < 10) {
      return 'Enter a valid contact number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Black overlay for dark theme
          Container(color: Colors.black.withOpacity(0.9)),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated Header
                      const Center(
                        child: Text(
                          "Create Your Athlete Profile",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          "Join the sports talent assessment platform.\nFill in your details to get started.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Personal Information Section
                      _buildSectionHeader('Personal Information', Icons.person),
                      const SizedBox(height: 16),

                      _buildAnimatedField(
                        "Full Name",
                        nameController,
                        _focusNodes['name']!,
                        validator: (value) => _validateRequired(value, 'Full name'),
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildAnimatedField(
                              "Age",
                              ageController,
                              _focusNodes['age']!,
                              keyboardType: TextInputType.number,
                              validator: _validateAge,
                              prefixIcon: Icons.cake_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInteractiveDropdown("Gender", ['Male', 'Female', 'Other'], gender, (val) {
                              setState(() {
                                gender = val!;
                              });
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildAnimatedField(
                              "Height (cm)",
                              heightController,
                              _focusNodes['height']!,
                              keyboardType: TextInputType.number,
                              validator: (value) => _validateRequired(value, 'Height'),
                              prefixIcon: Icons.height,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnimatedField(
                              "Weight (kg)",
                              weightController,
                              _focusNodes['weight']!,
                              keyboardType: TextInputType.number,
                              validator: (value) => _validateRequired(value, 'Weight'),
                              prefixIcon: Icons.monitor_weight_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildAnimatedField(
                        "Contact Number",
                        contactController,
                        _focusNodes['contact']!,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                        prefixIcon: Icons.phone_outlined,
                      ),

                      const SizedBox(height: 24),

                      // Sports Information Section
                      _buildSectionHeader('Sports Information', Icons.sports_basketball),
                      const SizedBox(height: 16),

                      _buildSportField(),
                      const SizedBox(height: 16),

                      _buildInteractiveDropdown("Experience Level", ['Beginner', 'Intermediate', 'Advanced'], experience, (val) {
                        setState(() {
                          experience = val!;
                        });
                      }),
                      const SizedBox(height: 16),

                      _buildAnimatedField(
                        "Fitness Goals",
                        goalsController,
                        _focusNodes['goals']!,
                        validator: (value) => _validateRequired(value, 'Fitness goals'),
                        prefixIcon: Icons.track_changes,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      // Profile Photo Section
                      _buildSectionHeader('Profile Photo', Icons.camera_alt),
                      const SizedBox(height: 16),

                      Center(
                        child: GestureDetector(
                          onTap: _pickSelfie,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 160,
                            width: 160,
                            decoration: BoxDecoration(
                              color: !_hasProfilePhoto ? Colors.white.withOpacity(0.05) : Colors.transparent,
                              border: Border.all(
                                color: !_hasProfilePhoto ? Colors.white30 : Colors.green,
                                width: !_hasProfilePhoto ? 1 : 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _hasProfilePhoto ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ] : [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: !_hasProfilePhoto
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Add Profile Photo",
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                                : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: kIsWeb && _selfieBytes != null
                                      ? Image.memory(
                                    _selfieBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                      : !kIsWeb && _selfieFile != null
                                      ? Image.file(
                                    _selfieFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                      : Container(
                                    color: Colors.grey,
                                    child: const Icon(
                                      Icons.error,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Terms and Conditions
                      Row(
                        children: [
                          AnimatedScale(
                            scale: _agreedToTerms ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              },
                              activeColor: Colors.green,
                              checkColor: Colors.white,
                              side: BorderSide(color: Colors.white54),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreedToTerms = !_agreedToTerms;
                                });
                              },
                              child: Text(
                                'I agree to the Terms & Conditions and Privacy Policy',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Register button with loading animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () {
                              _scaleController.forward().then((_) {
                                _scaleController.reverse();
                              });
                              _handleRegistration();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                            ),
                            child: _isLoading
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Creating Profile...",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                                : const Text(
                              "Create Athlete Profile",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedField(
      String label,
      TextEditingController controller,
      FocusNode focusNode,
      {
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
        IconData? prefixIcon,
        int maxLines = 1,
      }
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: focusNode.hasFocus ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focusNode.hasFocus ? Colors.white60 : Colors.white30,
              width: focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            validator: validator,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.white60, size: 20)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSportField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Sport',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30),
          ),
          child: TextFormField(
            controller: sportController,
            focusNode: _focusNodes['sport']!,
            style: const TextStyle(color: Colors.white),
            validator: (value) => _validateRequired(value, 'Primary sport'),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(Icons.sports_basketball, color: Colors.white60, size: 20),
              hintText: 'e.g., Basketball, Football, Tennis',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sportSuggestions.take(5).map((sport) {
            return GestureDetector(
              onTap: () {
                sportController.text = sport;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  sport,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInteractiveDropdown(String label, List<String> options, String currentValue, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: currentValue,
            dropdownColor: Colors.black87,
            isExpanded: true,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white60),
            onChanged: onChanged,
            items: options
                .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ))
                .toList(),
          ),
        ),
      ],
    );
  }
}