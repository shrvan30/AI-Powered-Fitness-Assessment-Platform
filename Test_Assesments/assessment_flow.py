"""
Assessment Flow Manager - Controls the exercise sequence
"""

import time
from exercises import Squats, Pushups, Situps, Plank, VerticalJump, OneLegStand
# Add this import since BaseExercise and FitnessComponent are now in root
from base_exercise import BaseExercise, FitnessComponent

class FitnessAssessment:
    def __init__(self, user_height_cm=170):
        self.user_height_cm = user_height_cm
        self.exercises = []
        self.current_exercise = None
        self.current_exercise_idx = -1
        self.assessment_score = 0
        self.custom_flow = False
        self.selected_exercises = []  # Added for tracking selected exercises

    def setup_default_flow(self):
        """Setup the default scientific flow recommended by fitness coaches"""
        self.exercises = [
            Squats("Squats", FitnessComponent.STRENGTH, ideal_reps=15),
            Pushups("Push-ups", FitnessComponent.STRENGTH, ideal_reps=12),
            Situps("Sit-ups", FitnessComponent.ENDURANCE, ideal_reps=20),
            Plank("Plank", FitnessComponent.ENDURANCE, ideal_time=60),
            VerticalJump("Vertical Jump", FitnessComponent.POWER, user_height_cm=self.user_height_cm),
            OneLegStand("One-Leg Stand", FitnessComponent.BALANCE, ideal_time=30)
        ]
        self.selected_exercises = self.exercises.copy()  # Track selected exercises
        self.custom_flow = False

    def setup_custom_flow(self, selected_exercise_types):
        """Setup a custom flow based on user selection"""
        self.exercises = []
        self.custom_flow = True

        for ex_type in selected_exercise_types:
            try:
                if ex_type == 'squats':
                    reps_input = input("How many squats would you like to do? (Default 15): ") or "15"
                    reps = int(reps_input) if reps_input.isdigit() else 15
                    self.exercises.append(Squats("Squats", FitnessComponent.STRENGTH, ideal_reps=reps))
                elif ex_type == 'pushups':
                    reps_input = input("How many push-ups would you like to do? (Default 12): ") or "12"
                    reps = int(reps_input) if reps_input.isdigit() else 12
                    self.exercises.append(Pushups("Push-ups", FitnessComponent.STRENGTH, ideal_reps=reps))
                elif ex_type == 'situps':
                    reps_input = input("How many sit-ups would you like to do? (Default 20): ") or "20"
                    reps = int(reps_input) if reps_input.isdigit() else 20
                    self.exercises.append(Situps("Sit-ups", FitnessComponent.ENDURANCE, ideal_reps=reps))
                elif ex_type == 'plank':
                    time_input = input("How long would you like to plank (seconds)? (Default 60): ") or "60"
                    time_sec = int(time_input) if time_input.isdigit() else 60
                    self.exercises.append(Plank("Plank", FitnessComponent.ENDURANCE, ideal_time=time_sec))
                elif ex_type == 'vertical_jump':
                    self.exercises.append(VerticalJump("Vertical Jump", FitnessComponent.POWER, user_height_cm=self.user_height_cm))
                elif ex_type == 'one_leg_stand':
                    time_input = input("How long would you like to balance (seconds)? (Default 30): ") or "30"
                    time_sec = int(time_input) if time_input.isdigit() else 30
                    self.exercises.append(OneLegStand("One-Leg Stand", FitnessComponent.BALANCE, ideal_time=time_sec))
            except ValueError:
                print("Invalid input, using default value.")
        
        self.selected_exercises = self.exercises.copy()  # Track selected exercises

    def next_exercise(self):
        """Move to the next exercise in the flow"""
        if self.current_exercise_idx < len(self.exercises) - 1:
            self.current_exercise_idx += 1
            self.current_exercise = self.exercises[self.current_exercise_idx]
            return True
        return False

    def calculate_overall_score(self):
        """Calculate the overall assessment score"""
        if not self.exercises:
            return 0

        total_score = sum(exercise.calculate_score() for exercise in self.exercises)
        self.assessment_score = total_score / len(self.exercises)
        return self.assessment_score

    def display_results(self):
        """Display final results with detailed feedback"""
        print("\n" + "="*50)
        print("FITNESS ASSESSMENT RESULTS")
        print("="*50)
        
        for i, exercise in enumerate(self.exercises):
            print(f"{i+1}. {exercise.name}: {exercise.score}/100")
            
            # Display detailed feedback if available
            if hasattr(exercise, 'generate_feedback'):
                feedback = exercise.generate_feedback()
                print(f"   Feedback: {feedback}")
            else:
                exercise.display_details()
            
            print()
        
        print(f"OVERALL SCORE: {self.assessment_score:.1f}/100")
        print("="*50)

    def save_results(self):
        """Save results to CSV with feedback"""
        from utils.results_manager import save_assessment_results
        success, msg = save_assessment_results(self.exercises)
        print(msg)

    def run_assessment(self, args):
        """Main assessment execution method"""
        from utils.assessment_runner import run_exercises

        print("FITNESS ASSESSMENT SYSTEM")
        print("="*40)
        print("Choose your assessment flow:")
        print("1. Default scientific flow (recommended by fitness coaches)")
        print("2. Custom flow (choose your own exercises)")

        choice = input("Enter your choice (1 or 2): ").strip()

        if choice == "2":
            print("\nAvailable exercises:")
            print("1. Squats (Strength)")
            print("2. Push-ups (Strength)")
            print("3. Sit-ups (Endurance)")
            print("4. Plank (Endurance)")
            print("5. Vertical Jump (Power)")
            print("6. One-Leg Stand (Balance)")

            selected = input("Enter exercise numbers separated by commas (e.g., 1,3,5): ").strip()
            exercise_nums = []
            for x in selected.split(","):
                if x.strip().isdigit():
                    exercise_nums.append(int(x.strip()))

            selected_types = []
            for num in exercise_nums:
                mapping = {1:'squats', 2:'pushups', 3:'situps', 4:'plank', 5:'vertical_jump', 6:'one_leg_stand'}
                if num in mapping:
                    selected_types.append(mapping[num])

            if selected_types:
                self.setup_custom_flow(selected_types)
            else:
                print("No valid exercises selected. Using default flow.")
                self.setup_default_flow()
        else:
            self.setup_default_flow()

        print("\nStarting assessment...")
        print("Instructions:")
        print("- Make sure you have enough space around you")
        print("- Position yourself so your whole body is visible in the camera")
        print("- Follow the on-screen instructions for each exercise")
        print("- Press 'n' to move to the next exercise")
        print("- Press 'q' to quit the assessment")
        print("- Press 's' to save your results")
        input("\nPress Enter to begin...")

        # Run the exercises
        run_exercises(self, args)

        # Calculate and display results
        self.calculate_overall_score()
        self.display_results()

        # Save results automatically
        self.save_results()