#!/usr/bin/env python3
"""
Main entry point for Fitness Assessment System (Upgraded)
"""
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'  # Suppress TensorFlow info and warnings
import warnings
warnings.filterwarnings('ignore')  # Suppress Python warnings


import argparse
from assessment_flow import FitnessAssessment

def main():
    parser = argparse.ArgumentParser(description="Fitness Assessment with MediaPipe")
    parser.add_argument("--camera", type=int, default=0, help="Camera index")
    parser.add_argument("--height-cm", type=float, default=170.0, help="User height in cm for calibration")
    parser.add_argument("--width", type=int, default=960, help="Camera width")
    parser.add_argument("--height", type=int, default=540, help="Camera height")
    parser.add_argument("--show-skeleton", action="store_true", help="Show pose skeleton")
    args = parser.parse_args()

    # Create the assessment system
    assessment = FitnessAssessment(user_height_cm=args.height_cm)

    # Run the assessment (real-time + descriptive feedback)
    assessment.run_assessment(args)

    # After completing all exercises, show detailed summary
    print("\n==================================================")
    print("DETAILED FITNESS ASSESSMENT FEEDBACK")
    print("==================================================")
    
    for idx, exercise in enumerate(assessment.exercises, 1):
        print(f"\n{idx}. {exercise.name.upper()}: {exercise.score}/100")
        print("-" * 40)
        
        # Call descriptive feedback if available
        if hasattr(exercise, "generate_feedback"):
            feedback = exercise.generate_feedback()
            print(feedback)
    
    print("\n" + "="*50)
    print(f"OVERALL SCORE: {assessment.assessment_score:.1f}/100")
    print("="*50)

    # Note: Results are already saved in run_assessment(), no need to save again


if __name__ == "__main__":
    main()