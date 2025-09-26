"""
Results Manager - Handles saving and loading assessment results
"""

import csv
from datetime import datetime
import os


def save_assessment_results(exercises, filename="fitness_assessment_results.csv"):
    """Save assessment results to a CSV file with feedback"""
    # Only create directory if filename contains a path
    if os.path.dirname(filename) and not os.path.exists(os.path.dirname(filename)):
        os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    header = ["timestamp", "exercise", "component", "reps", "duration", "score", "form_errors", "feedback"]
    rows = []

    for exercise in exercises:
        # Ensure score is finalized before saving
        if hasattr(exercise, "finalize_score"):
            exercise.finalize_score()
        elif not hasattr(exercise, "score"):
            exercise.score = 0.0

        # Generate feedback if available
        feedback_text = ""
        if hasattr(exercise, "generate_feedback"):
            feedback_text = exercise.generate_feedback()
        else:
            feedback_text = f"{exercise.name}: Score {exercise.score}/100"

        rows.append([
            datetime.now().isoformat(timespec='seconds'),
            exercise.name,
            exercise.component.name,
            exercise.reps,
            round(exercise.duration, 1),
            exercise.score,
            exercise.form_errors,
            feedback_text.replace('\n', ' | ')  # Replace newlines for CSV
        ])

    try:
        # Check if file exists to determine if we need to write header
        file_exists = os.path.isfile(filename)
        
        with open(filename, "a", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            if not file_exists:
                writer.writerow(header)
            writer.writerows(rows)
        return True, f"Results saved to {filename}"
    except Exception as e:
        return False, f"Save failed: {e}"