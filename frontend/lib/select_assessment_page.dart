import 'package:flutter/material.dart';

class SelectAssessmentPage extends StatefulWidget {
  const SelectAssessmentPage({super.key});

  @override
  State<SelectAssessmentPage> createState() => _SelectAssessmentPageState();
}

class _SelectAssessmentPageState extends State<SelectAssessmentPage>
    with TickerProviderStateMixin {
  int? selectedFlow; // 1 = default, 2 = custom

  final List<Map<String, dynamic>> exercises = [
    {'name': 'Squats', 'type': 'Strength', 'defaultCount': 15},
    {'name': 'Push-ups', 'type': 'Strength', 'defaultCount': 15},
    {'name': 'Sit-ups', 'type': 'Endurance', 'defaultCount': 20},
    {'name': 'Plank', 'type': 'Endurance', 'defaultCount': 60}, // seconds
    {'name': 'Vertical Jump', 'type': 'Power', 'defaultCount': 3},
    {'name': 'One-Leg Stand', 'type': 'Balance', 'defaultCount': 30}, // seconds
  ];

  final Set<int> selectedExercises = {};
  final Map<int, TextEditingController> countControllers = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    for (var controller in countControllers.values) {
      controller.dispose();
    }
    _fadeController.dispose();
    super.dispose();
  }

  void _startTest() {
    if (selectedFlow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a flow first.")),
      );
      return;
    }

    if (selectedFlow == 2 && selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one exercise.")),
      );
      return;
    }

    // Gather results
    if (selectedFlow == 1) {
      debugPrint("Starting default flow with exercises:");
      for (var ex in exercises) {
        debugPrint("${ex['name']} - ${ex['defaultCount']}");
      }
    } else {
      debugPrint("Starting custom flow with:");
      for (var index in selectedExercises) {
        final ex = exercises[index];
        final input = countControllers[index]?.text.trim();
        final count = (input?.isNotEmpty ?? false)
            ? int.tryParse(input!) ?? ex['defaultCount']
            : ex['defaultCount'];
        debugPrint("${ex['name']} - $count");
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Test started! (next step pending)")),
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
          Container(color: Colors.black.withOpacity(0.9)),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      "Choose Your Assessment Flow",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Select default or create your own routine",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Flow options
                    Card(
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<int>(
                            activeColor: Colors.orange,
                            title: const Text("Default scientific flow (recommended)",
                                style: TextStyle(color: Colors.white)),
                            value: 1,
                            groupValue: selectedFlow,
                            onChanged: (val) => setState(() => selectedFlow = val),
                          ),
                          RadioListTile<int>(
                            activeColor: Colors.orange,
                            title: const Text("Custom flow (choose your own exercises)",
                                style: TextStyle(color: Colors.white)),
                            value: 2,
                            groupValue: selectedFlow,
                            onChanged: (val) => setState(() => selectedFlow = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Expanded area for flow details
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: selectedFlow == 1
                            ? ListView.builder(
                          key: const ValueKey(1),
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            final ex = exercises[index];
                            return Card(
                              color: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.fitness_center,
                                    color: Colors.orange),
                                title: Text(ex['name'],
                                    style: const TextStyle(
                                        color: Colors.white)),
                                subtitle: Text(
                                  "${ex['type']} • ${ex['defaultCount']}",
                                  style: TextStyle(
                                      color:
                                      Colors.white.withOpacity(0.7)),
                                ),
                              ),
                            );
                          },
                        )
                            : selectedFlow == 2
                            ? ListView.builder(
                          key: const ValueKey(2),
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            final ex = exercises[index];
                            final isSelected =
                            selectedExercises.contains(index);

                            return Card(
                              color: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    activeColor: Colors.orange,
                                    title: Text(
                                        "${ex['name']} (${ex['type']})",
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    value: isSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          selectedExercises.add(index);
                                          countControllers[index] =
                                              TextEditingController();
                                        } else {
                                          selectedExercises
                                              .remove(index);
                                          countControllers[index]
                                              ?.dispose();
                                          countControllers
                                              .remove(index);
                                        }
                                      });
                                    },
                                  ),
                                  if (isSelected)
                                    Padding(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 8),
                                      child: TextField(
                                        key: ValueKey("count_$index"),
                                        controller:
                                        countControllers[index],
                                        keyboardType:
                                        TextInputType.number,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16),
                                        cursorColor: Colors.orange,
                                        decoration: InputDecoration(
                                          labelText:
                                          "How many ${ex['name']}? (Default ${ex['defaultCount']})",
                                          labelStyle:
                                          const TextStyle(
                                              color:
                                              Colors.white70),
                                          filled: true,
                                          fillColor: Colors.black
                                              .withOpacity(0.4),
                                          focusedBorder:
                                          OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(
                                                12),
                                            borderSide:
                                            const BorderSide(
                                                color:
                                                Colors.orange,
                                                width: 1.5),
                                          ),
                                          enabledBorder:
                                          OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(
                                                12),
                                            borderSide: BorderSide(
                                                color: Colors.white
                                                    .withOpacity(0.5)),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        )
                            : const SizedBox.shrink(),
                      ),
                    ),

                    // Start Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Start Test",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
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
