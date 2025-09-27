# AI-Powered Fitness Assessment Platform

An AI-driven fitness platform that automatically evaluates workouts using computer vision and machine learning.

## 🔍 Project Overview
This platform uses ML and pose estimation to assess workouts in real-time. Users record exercises, and the system counts repetitions, evaluates form, and provides feedback.

- **Frontend:** Flutter & Dart
- **Backend/ML:** Python (pose estimation + exercise evaluation)
- **Database:** Firebase (authentication & storage)

## 💡 Key Contribution: Machine Learning & Assessment Flow
The `Test_Assessments` module contains the core ML and logic:

- **exercises/** – Defines exercises (`squats.py`, `pushups.py`, `plank.py`) inheriting from `base_exercise.py`
- **utils/** – ML helper scripts:
  - `pose_utils.py` → Processes keypoints from pose detection
  - `angle_calculator.py` → Calculates joint angles for form evaluation
  - `results_manager.py` → Logs and manages assessment results
- `assessment_flow.py` – Main ML workflow: evaluates pose data, counts repetitions, computes metrics
- `main.py` – Entry point to run assessments

✅ This module ensures **accurate exercise detection, repetition counting, and real-time feedback** using ML logic.

## 🏗️ Project Structure
<img width="889" height="626" alt="image" src="https://github.com/user-attachments/assets/c3331cd6-fc1d-491e-a832-c9df8af23ac8" />




## ⚡ How It Works
1. User records a workout video.
2. Pose estimation detects key body points.
3. `assessment_flow.py` evaluates the exercise using angles, repetitions, and form metrics.
4. Results are saved to `fitness_assessment_results.csv`.
5. Feedback is displayed in real-time to the user.

## 🚀 Technologies
- Python – Core ML logic
- TensorFlow / MediaPipe – Pose estimation
- Flutter & Dart – Mobile frontend
- Firebase – User authentication & storage

## 📈 Outcome
- Accurate exercise recognition & repetition counting
- Real-time feedback for proper exercise form
- Modular, reusable ML workflow for multiple exercises



