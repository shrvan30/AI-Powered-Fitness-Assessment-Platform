"""
One-Leg Stand Exercise Implementation (Upgraded with Feedback)
"""

import time
import cv2
from base_exercise import BaseExercise, FitnessComponent

class OneLegStand(BaseExercise):
    def __init__(self, name, component, ideal_time=30):
        super().__init__(name, component, ideal_time=ideal_time)
        self.start_time = None
        self.balance_lost = False
        self.sway_frames = 0
        self.total_frames = 0
        self.error_threshold = 0.1  # hip deviation threshold
        self.form_errors = 0

    def calculate_score(self):
        if self.ideal_time:
            completion = min(1.0, self.duration / self.ideal_time)
            form_penalty = max(0.7, 1 - (self.form_errors / (self.duration + 1)) * 0.1)
            self.score = round(completion * form_penalty * 100, 1)
        else:
            self.score = 0
        return self.score

    def update(self, landmarks, frame_width, frame_height):
        if self.start_time is None:
            self.start_time = time.time()

        if not self.balance_lost:
            self.duration = time.time() - self.start_time

        self.total_frames += 1

        # Check if balance is lost (both feet grounded)
        lankle = landmarks[27]  # LEFT_ANKLE
        rankle = landmarks[28]  # RIGHT_ANKLE
        balance_lost_now = lankle.y < 0.8 and rankle.y < 0.8
        if balance_lost_now:
            self.balance_lost = True

        # Hip sway detection
        lhip = landmarks[23]
        rhip = landmarks[24]
        hip_x = (lhip.x + rhip.x) / 2
        sway_detected = abs(hip_x - 0.5) > self.error_threshold

        if sway_detected:
            self.sway_frames += 1
            # Add form error for sustained sway (>10 frames)
            if self.sway_frames >= 10:
                self.form_errors += 1
                self.sway_frames = 0
        else:
            self.sway_frames = 0  # reset if stable

    def draw_feedback(self, frame, landmarks, frame_width, frame_height):
        status_text = f"Time: {self.duration:.1f}s"
        if self.balance_lost:
            status_text += " (Balance lost)"
            cv2.putText(frame, status_text, (10, 90),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        else:
            cv2.putText(frame, status_text, (10, 90),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

        # Real-time sway feedback
        lhip = landmarks[23]
        rhip = landmarks[24]
        hip_x = (lhip.x + rhip.x) / 2
        if abs(hip_x - 0.5) > self.error_threshold:
            cv2.putText(frame, "SWAY DETECTED: Try to stabilize!",
                        (frame_width // 2 - 150, 90),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

    def generate_feedback(self):
        feedback = [
            f"One-Leg Stand Feedback:",
            f"- Total duration: {self.duration:.1f}s",
            f"- Form errors: {self.form_errors}",
            f"- Score: {self.score}/100"
        ]
        if self.balance_lost:
            feedback.append("⚠️ Balance lost during the test.")
        elif self.form_errors > 0:
            feedback.append("⚠️ Try to minimize hip sway for better stability.")
        else:
            feedback.append("✅ Excellent balance maintained!")
        return "\n".join(feedback)

    def reset(self):
        super().reset()
        self.start_time = None
        self.balance_lost = False
        self.sway_frames = 0
        self.total_frames = 0
        self.form_errors = 0
