import 'package:flutter/material.dart';
import 'select_assessment_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  String? selectedAvatar;
  final List<String> avatars = [
    'assets/avatars/avatar1.jpg',
    'assets/avatars/avatar2.jpg',
    'assets/avatars/avatar3.jpg',
    'assets/avatars/avatar4.jpg',
    'assets/avatars/avatar5.jpg',
    'assets/avatars/avatar6.jpg',
    'assets/avatars/avatar7.jpg',
    'assets/avatars/avatar8.jpg',
  ];

  // Sports talent assessment data
  int streak = 5;
  int totalAssessments = 18;
  double overallRating = 7.8;
  String athleteLevel = "Intermediate";
  String primarySport = "Basketball";
  int trainingHours = 240;

  List<int> heatmap = List.generate(30, (index) => index % 6);

  // Recent assessments data
  final List<Map<String, dynamic>> recentAssessments = [
    {'category': 'Sit Ups', 'score': 8.2, 'date': '2 days ago', 'icon': Icons.favorite},
    {'category': 'Vertical Jump', 'score': 7.5, 'date': '4 days ago', 'icon': Icons.favorite},
    {'category': 'Shuttle Run', 'score': 8.8, 'date': '1 week ago', 'icon': Icons.favorite},
    {'category': 'Endurance Run', 'score': 7.2, 'date': '1 week ago', 'icon': Icons.favorite},
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedAvatar == null) {
        _showAvatarPicker();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showAvatarPicker() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Select Your Avatar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,  // Changed from 20 to match signup section headers
              fontWeight: FontWeight.bold,  // Added bold weight
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: avatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAvatar = avatars[index];
                    });
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(avatars[index]),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Color getHeatmapColor(int level) {
    switch (level) {
      case 0:
        return Colors.grey.shade800;
      case 1:
        return Colors.green.shade900;
      case 2:
        return Colors.green.shade700;
      case 3:
        return Colors.green.shade500;
      case 4:
        return Colors.green.shade400;
      case 5:
        return Colors.green.shade300;
      default:
        return Colors.grey.shade800;
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,  // Changed from 20 to be closer to section headers
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentItem(Map<String, dynamic> assessment) {
    Color scoreColor = assessment['score'] >= 8.0
        ? Colors.green
        : assessment['score'] >= 6.0
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            assessment['icon'],
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment['category'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,  // Changed from bold to w500 to match field labels
                    fontSize: 14,
                  ),
                ),
                Text(
                  assessment['date'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,  // Changed from 11 to 12
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withOpacity(0.5)),
            ),
            child: Text(
              '${assessment['score']}/10',
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.9),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Avatar & Profile
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: selectedAvatar != null
                                  ? CircleAvatar(
                                radius: 40,
                                backgroundImage: AssetImage(selectedAvatar!),
                              )
                                  : const CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, size: 40, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back, Athlete!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.sports_basketball, color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    primarySport,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      athleteLevel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,  // Changed from 10 to 12
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Streak: ',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    '$streak Days',
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _showAvatarPicker,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text(
                            'Change Avatar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,  // Added bold weight
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Performance Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard('Overall Rating', '$overallRating/10', Icons.star, Colors.amber),
                        _buildStatCard('Assessments', '$totalAssessments', Icons.assessment, Colors.blue),
                        _buildStatCard('Training Hours', '${trainingHours}h', Icons.access_time, Colors.green),
                        _buildStatCard('This Month', '+15%', Icons.trending_up, Colors.purple),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Activity Heatmap - UPDATED SECTION
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Training Activity',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'September 2025',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Centered heatmap
                          Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Calculate optimal size for squares based on available width
                                final availableWidth = constraints.maxWidth - 32; // Account for padding
                                final optimalColumns = (availableWidth / 25).floor().clamp(7, 10); // 7-10 columns
                                final squareSize = (availableWidth / optimalColumns - 4).clamp(18.0, 28.0);

                                return Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: heatmap.asMap().entries.map((entry) {
                                    return Container(
                                      width: squareSize,
                                      height: squareSize,
                                      decoration: BoxDecoration(
                                        color: getHeatmapColor(entry.value),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Legend
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Less',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(6, (index) => Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    color: getHeatmapColor(index),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )),
                                const SizedBox(width: 8),
                                Text(
                                  'More',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Assessments
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Assessments',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Navigate to all assessments
                                },
                                child: const Text(
                                  'View All',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...recentAssessments.map((assessment) =>
                              _buildAssessmentItem(assessment)).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to start new assessment
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SelectAssessmentPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(
                              'Start Assessment',
                              style: TextStyle(
                                fontSize: 16,  // Added explicit font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {

                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white),
                              ),
                            ),
                            icon: const Icon(Icons.analytics),
                            label: const Text(
                              'View Progress',
                              style: TextStyle(
                                fontSize: 16,  // Added explicit font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}