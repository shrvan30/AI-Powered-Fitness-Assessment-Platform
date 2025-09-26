"""
Base Exercise Class - Defines the interface for all exercises
"""

from enum import Enum
import time

class FitnessComponent(Enum):
    STRENGTH = 1
    ENDURANCE = 2
    POWER = 3
    BALANCE = 4

class BaseExercise:
    def __init__(self, name, component, ideal_reps=None, ideal_time=None):
        self.name = name
        self.component = component
        self.ideal_reps = ideal_reps
        self.ideal_time = ideal_time
        self.reps = 0
        self.duration = 0.0
        self.score = 0.0
        self.form_errors = 0
        self.start_time = None
        
    def update(self, landmarks, frame_width, frame_height):
        """Update exercise state based on pose landmarks"""
        raise NotImplementedError("Subclasses must implement update()")
        
    def draw_feedback(self, frame, landmarks, frame_width, frame_height):
        """Draw real-time feedback on the frame"""
        raise NotImplementedError("Subclasses must implement draw_feedback()")
        
    def calculate_score(self):
        """Calculate the exercise score"""
        if self.ideal_reps:
            completion = min(1.0, self.reps / self.ideal_reps) if self.ideal_reps > 0 else 0
            form_penalty = max(0.7, 1 - (self.form_errors / (self.reps + 1)) * 0.3)
            self.score = round(completion * form_penalty * 100, 1)
        elif self.ideal_time:
            completion = min(1.0, self.duration / self.ideal_time) if self.ideal_time > 0 else 0
            form_penalty = max(0.7, 1 - (self.form_errors / (self.duration + 1)) * 0.1)
            self.score = round(completion * form_penalty * 100, 1)
        else:
            self.score = 0
        return self.score
    
    def generate_feedback(self):
        """Generate descriptive feedback after the exercise is completed"""
        return f"{self.name}: Score {self.score}/100 - {self.reps} reps, {self.form_errors} form errors"
    
    def finalize_score(self):
        """Finalize the score calculation (override in subclasses if needed)"""
        return self.calculate_score()
    
    def reset(self):
        """Reset exercise state"""
        self.reps = 0
        self.duration = 0.0
        self.score = 0.0
        self.form_errors = 0
        self.start_time = None
    
    def display_details(self):
        """Display exercise details"""
        if self.ideal_reps:
            print(f"  Target: {self.ideal_reps} reps")
        elif self.ideal_time:
            print(f"  Target: {self.ideal_time} seconds")
        print(f"  Completed: {self.reps} reps, {self.duration:.1f}s")
        print(f"  Score: {self.score}/100")
        print(f"  Form errors: {self.form_errors}")