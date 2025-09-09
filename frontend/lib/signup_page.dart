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
  final emailController = TextEditingController(),
      passwordController = TextEditingController(),
      confirmPasswordController = TextEditingController(),
      nameController = TextEditingController(),
      ageController = TextEditingController(),
      heightController = TextEditingController(),
      weightController = TextEditingController(),
      contactController = TextEditingController(),
      sportController = TextEditingController(),
      goalsController = TextEditingController();

  String gender = 'Male', experience = 'Beginner';
  bool _passwordVisible = false, _confirmPasswordVisible = false;
  File? _selfieFile;
  Uint8List? _selfieBytes;
  String? _selfieName;
  bool _isLoading = false, _agreedToTerms = false;

  late AnimationController _fadeController, _scaleController;
  late Animation<double> _fadeAnimation, _scaleAnimation;

  final List<String> sportSuggestions = [
    'Basketball','Football','Soccer','Tennis','Swimming',
    'Track & Field','Baseball','Volleyball','Boxing','Cricket'
  ];

  final Map<String, FocusNode> _focusNodes = {
    'email': FocusNode(),
    'password': FocusNode(),
    'confirmPassword': FocusNode(),
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
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _scaleAnimation = Tween(begin: 1.0, end: 0.95).animate(_scaleController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    for (var c in [
      emailController,passwordController,confirmPasswordController,
      nameController,ageController,heightController,weightController,
      contactController,sportController,goalsController
    ]) { c.dispose(); }
    for (var node in _focusNodes.values) { node.dispose(); }
    super.dispose();
  }

  Future<void> _pickSelfie() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 50, height: 4,
              decoration: BoxDecoration(color: Colors.white30,borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Select Photo', style: TextStyle(color: Colors.white,fontSize: 18,fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            if (!kIsWeb) _buildPhotoOption('Camera', Icons.camera_alt, ()=>_takePicture(ImageSource.camera)),
            _buildPhotoOption(kIsWeb ? 'Choose File' : 'Gallery',
                kIsWeb ? Icons.file_upload : Icons.photo_library,
                    ()=>_takePicture(ImageSource.gallery)),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildPhotoOption(String label, IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2))),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white,fontSize: 14)),
          ]),
        ),
      );

  Future<void> _takePicture(ImageSource source) async {
    Navigator.pop(context);
    try {
      final picked = await ImagePicker().pickImage(
          source: source,imageQuality: 80,maxWidth: 800,maxHeight: 800);
      if (picked != null) {
        if (kIsWeb) {
          _selfieBytes = await picked.readAsBytes();
          _selfieName = picked.name; _selfieFile = null;
        } else {
          _selfieFile = File(picked.path); _selfieBytes = null; _selfieName = null;
        }
        setState((){});
        _showSnackbar(source==ImageSource.camera ? 'Picture captured!' : 'Photo selected!', Colors.green);
      }
    } catch (_) {
      _showSnackbar(source==ImageSource.camera ? 'Camera error' : 'Gallery error', Colors.red);
    }
  }

  void _showSnackbar(String msg, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  bool get _hasProfilePhoto => _selfieFile!=null || _selfieBytes!=null;

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return _showSnackbar('Fill all fields', Colors.red);
    if (!_hasProfilePhoto) return _showSnackbar('Add profile photo', Colors.orange);
    if (!_agreedToTerms) return _showSnackbar('Agree to terms', Colors.orange);

    setState(()=>_isLoading=true);
    await Future.delayed(const Duration(seconds: 2));
    setState(()=>_isLoading=false);

    _showSnackbar('Profile created!', Colors.green);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (c)=>const DashboardPage()));
  }

  String? _validateRequired(String? v, String f) => (v==null||v.trim().isEmpty) ? '$f is required' : null;
  String? _validateEmail(String? v) {
    if (v==null||v.isEmpty) return 'Email required';
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v) ? null : 'Enter valid email';
  }
  String? _validatePassword(String? v) => v==null||v.isEmpty ? 'Password required' : v.length<6 ? 'Min 6 chars' : null;
  String? _validateConfirmPassword(String? v) => v!=passwordController.text ? 'Passwords do not match' : null;
  String? _validateAge(String? v) {
    final a=int.tryParse(v??''); return (a==null||a<13||a>100) ? 'Enter valid age (13-100)' : null;
  }
  String? _validatePhone(String? v) => (v==null||v.length<10) ? 'Enter valid contact' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/images/background.png"), fit: BoxFit.cover))),
        Container(color: Colors.black.withOpacity(0.9)),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IconButton(onPressed: ()=>Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios,color: Colors.white,size: 24)),
                    const Text('Back', style: TextStyle(color: Colors.white70,fontSize: 16)),
                  ]),
                  const SizedBox(height: 12),
                  const Center(child: Text("Create Your Athlete Profile",
                      style: TextStyle(color: Colors.white,fontSize: 26,fontWeight: FontWeight.bold))),
                  const SizedBox(height: 12),
                  const Center(child: Text(
                      "Join the sports talent assessment platform.\nFill in your details to get started.",
                      style: TextStyle(color: Colors.white70,fontSize: 14),textAlign: TextAlign.center)),
                  const SizedBox(height: 30),

                  // Account Information
                  _buildSectionHeader('Account Information', Icons.account_circle),
                  const SizedBox(height: 16),
                  _buildAnimatedField("Email Address", emailController, _focusNodes['email']!,
                      keyboardType: TextInputType.emailAddress, validator: _validateEmail, prefixIcon: Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildPasswordField("Password", passwordController, _focusNodes['password']!,
                      _passwordVisible, ()=>setState(()=>_passwordVisible=!_passwordVisible), validator: _validatePassword),
                  const SizedBox(height: 16),
                  _buildPasswordField("Confirm Password", confirmPasswordController, _focusNodes['confirmPassword']!,
                      _confirmPasswordVisible, ()=>setState(()=>_confirmPasswordVisible=!_confirmPasswordVisible),
                      validator: _validateConfirmPassword),

                  const SizedBox(height: 30),
                  _buildSectionHeader('Personal Information', Icons.person),
                  const SizedBox(height: 16),
                  _buildAnimatedField("Full Name", nameController, _focusNodes['name']!,
                      validator: (v)=>_validateRequired(v,'Full name'), prefixIcon: Icons.person_outline),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _buildAnimatedField("Age", ageController, _focusNodes['age']!,
                        keyboardType: TextInputType.number, validator: _validateAge, prefixIcon: Icons.cake_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInteractiveDropdown("Gender", ['Male','Female','Other'], gender,
                            (v)=>setState(()=>gender=v!))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _buildAnimatedField("Height (cm)", heightController, _focusNodes['height']!,
                        keyboardType: TextInputType.number, validator: (v)=>_validateRequired(v,'Height'), prefixIcon: Icons.height)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAnimatedField("Weight (kg)", weightController, _focusNodes['weight']!,
                        keyboardType: TextInputType.number, validator: (v)=>_validateRequired(v,'Weight'),
                        prefixIcon: Icons.monitor_weight_outlined)),
                  ]),
                  const SizedBox(height: 16),
                  _buildAnimatedField("Contact Number", contactController, _focusNodes['contact']!,
                      keyboardType: TextInputType.phone, validator: _validatePhone, prefixIcon: Icons.phone_outlined),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Sports Information', Icons.sports_basketball),
                  const SizedBox(height: 16),
                  _buildSportField(),
                  const SizedBox(height: 16),
                  _buildInteractiveDropdown("Experience Level", ['Beginner','Intermediate','Advanced'],
                      experience,(v)=>setState(()=>experience=v!)),
                  const SizedBox(height: 16),
                  _buildAnimatedField("Fitness Goals", goalsController, _focusNodes['goals']!,
                      validator: (v)=>_validateRequired(v,'Fitness goals'), prefixIcon: Icons.track_changes, maxLines: 3),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Profile Photo', Icons.camera_alt),
                  const SizedBox(height: 16),
                  Center(child: GestureDetector(
                    onTap: _pickSelfie,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 160, width: 160,
                      decoration: BoxDecoration(
                        color: !_hasProfilePhoto?Colors.white.withOpacity(0.05):Colors.transparent,
                        border: Border.all(color: !_hasProfilePhoto?Colors.white30:Colors.green,width: !_hasProfilePhoto?1:2),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [_hasProfilePhoto
                            ? BoxShadow(color: Colors.green.withOpacity(0.3),blurRadius: 15,spreadRadius: 2)
                            : BoxShadow(color: Colors.white.withOpacity(0.1),blurRadius: 8,spreadRadius: 1)],
                      ),
                      child: !_hasProfilePhoto ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                        Icon(Icons.add_a_photo,color: Colors.white70,size: 40),
                        SizedBox(height: 8),
                        Text("Add Profile Photo",style: TextStyle(color: Colors.white70,fontSize: 14),textAlign: TextAlign.center),
                      ]) : Stack(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(18),
                            child: kIsWeb && _selfieBytes!=null
                                ? Image.memory(_selfieBytes!,fit: BoxFit.cover,width: double.infinity,height: double.infinity)
                                : !kIsWeb && _selfieFile!=null
                                ? Image.file(_selfieFile!,fit: BoxFit.cover,width: double.infinity,height: double.infinity)
                                : Container(color: Colors.grey,child: const Icon(Icons.error,color: Colors.white))),
                        Positioned(top: 8,right: 8,child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.green,shape: BoxShape.circle),
                          child: const Icon(Icons.check,color: Colors.white,size: 16),
                        )),
                      ]),
                    ),
                  )),

                  const SizedBox(height: 24),
                  Row(children: [
                    AnimatedScale(
                        scale: _agreedToTerms ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v)=>setState(()=>_agreedToTerms=v??false),
                          activeColor: Colors.green,checkColor: Colors.white,side: const BorderSide(color: Colors.white54),
                        )),
                    Expanded(child: GestureDetector(
                      onTap: ()=>setState(()=>_agreedToTerms=!_agreedToTerms),
                      child: const Text('I agree to the Terms & Conditions and Privacy Policy',
                          style: TextStyle(color: Colors.white70,fontSize: 14)),
                    )),
                  ]),

                  const SizedBox(height: 24),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading?null:(){
                          _scaleController.forward().then((_)=>_scaleController.reverse());
                          _handleRegistration();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),elevation: 8),
                        child: _isLoading
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                          SizedBox(width: 20,height: 20,child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text("Creating Profile...",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
                        ])
                            : const Text("Create Athlete Profile",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        )
      ]),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) => Row(children: [
    Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1),borderRadius: BorderRadius.circular(8)),
        child: Icon(icon,color: Colors.white,size: 20)),
    const SizedBox(width: 12),
    Text(title, style: const TextStyle(color: Colors.white,fontSize: 18,fontWeight: FontWeight.bold)),
  ]);

  Widget _buildAnimatedField(String label, TextEditingController c, FocusNode f,
      {TextInputType keyboardType=TextInputType.text, String? Function(String?)? validator,
        IconData? prefixIcon, int maxLines=1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
              color: f.hasFocus?Colors.white.withOpacity(0.15):Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: f.hasFocus?Colors.white60:Colors.white30, width: f.hasFocus?2:1)),
          child: TextFormField(
            controller: c,focusNode: f,keyboardType: keyboardType,maxLines: maxLines,
            style: const TextStyle(color: Colors.white),validator: validator,
            decoration: InputDecoration(
                border: InputBorder.none,contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: prefixIcon!=null?Icon(prefixIcon,color: Colors.white60,size: 20):null),
          ),
        ),
      ]);

  Widget _buildPasswordField(String label, TextEditingController c, FocusNode f,
      bool isVisible, VoidCallback toggle,
      {String? Function(String?)? validator}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
              color: f.hasFocus?Colors.white.withOpacity(0.15):Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: f.hasFocus?Colors.white60:Colors.white30, width: f.hasFocus?2:1)),
          child: TextFormField(
            controller: c,focusNode: f,obscureText: !isVisible,
            style: const TextStyle(color: Colors.white),validator: validator,
            decoration: InputDecoration(
              border: InputBorder.none,contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(Icons.lock_outline,color: Colors.white60,size: 20),
              suffixIcon: IconButton(
                  icon: Icon(isVisible?Icons.visibility:Icons.visibility_off,color: Colors.white60),
                  onPressed: toggle),
            ),
          ),
        ),
      ]);

  Widget _buildInteractiveDropdown(String label, List<String> items, String value, Function(String?) onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                value: value,isExpanded: true,dropdownColor: Colors.black87,
                items: items.map((s)=>DropdownMenuItem(value: s,child: Text(s,style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: onChanged),
          ),
        ),
      ]);

  Widget _buildSportField() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Primary Sport", style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: sportController,focusNode: _focusNodes['sport'],
          style: const TextStyle(color: Colors.white),
          validator: (v)=>_validateRequired(v,"Sport"),
          decoration: InputDecoration(
            hintText: "Enter your sport",
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.sports,color: Colors.white60),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8,runSpacing: 8,children: sportSuggestions.map((sport)=>
            GestureDetector(
              onTap: ()=>setState(()=>sportController.text=sport),
              child: Chip(
                label: Text(sport,style: const TextStyle(color: Colors.black,fontSize: 12)),
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )).toList()),
      ]);
}
