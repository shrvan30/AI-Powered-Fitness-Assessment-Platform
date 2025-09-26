"""
Squats Exercise Implementation (More Forgiving Form Detection)
"""

import numpy as np
from collections import deque
import time
import cv2
from base_exercise import BaseExercise, FitnessComponent
from utils.pose_utils import angle_3pt, pick_side_visibility, lm_xy


class Squats(BaseExercise):
    def __init__(self, name, component, ideal_reps=15):
        super().__init__(name, component, ideal_reps=ideal_reps)
        self.down_thresh = 100.0
        self.up_thresh = 160.0
        self.min_interval = 1.0
        self.smooth_n = 5
        self.knee_angles = deque(maxlen=self.smooth_n)
        self.stage = 'up'
        self.last_rep_t = 0.0

        # form tracking - MORE FORGIVING parameters
        self.knee_valgus_frames = 0  # Count frames with valgus
        self.rep_frame_count = 0
        self.rep_depths = []   # store min knee angle per rep
        self.score = 0.0
        
        # MORE FORGIVING form error thresholds
        self.valgus_threshold = 0.7  # Increased from 0.6 to 0.7 (70% of frames)
        self.valgus_tolerance_frames = 5  # Allow brief valgus without penalty

    def update(self, landmarks, frame_width, frame_height):
        side = pick_side_visibility(landmarks)

        if side == 'L':
            hip = landmarks[23]  # LEFT_HIP
            knee = landmarks[25]  # LEFT_KNEE
            ankle = landmarks[27]  # LEFT_ANKLE
        else:
            hip = landmarks[24]  # RIGHT_HIP
            knee = landmarks[26]  # RIGHT_KNEE
            ankle = landmarks[28]  # RIGHT_ANKLE

        # Calculate knee angle
        hx, hy = lm_xy(hip, frame_width, frame_height)
        kx, ky = lm_xy(knee, frame_width, frame_height)
        ax, ay = lm_xy(ankle, frame_width, frame_height)
        knee_angle = angle_3pt((hx, hy), (kx, ky), (ax, ay))

        if np.isnan(knee_angle):
            return

        self.knee_angles.append(knee_angle)
        avg = np.nanmean(self.knee_angles)

        # Check for knee valgus (knees collapsing inward)
        knee_valgus = False
        
        # Valgus detection (knees inward relative to ankles)
        if side == 'L' and kx < ax - 25:  # Left knee inside left ankle
            knee_valgus = True
        elif side == 'R' and kx > ax + 25:  # Right knee inside right ankle
            knee_valgus = True

        # Count frames
        self.rep_frame_count += 1
        
        # Count valgus frames
        if knee_valgus:
            self.knee_valgus_frames += 1

        now = time.time()
        if self.stage == 'up' and avg <= self.down_thresh:
            self.stage = 'down'
            self.current_rep_min_angle = avg
        elif self.stage == 'down' and avg >= self.up_thresh:
            if now - self.last_rep_t >= self.min_interval:
                self.reps += 1
                self.last_rep_t = now

                # record depth for feedback
                self.rep_depths.append(self.current_rep_min_angle)

                # Check if valgus was persistent (MORE FORGIVING calculation)
                if self.rep_frame_count > 0:
                    valgus_ratio = self.knee_valgus_frames / self.rep_frame_count
                    
                    # Only count form error if valgus was very persistent
                    if valgus_ratio > self.valgus_threshold:
                        self.form_errors += 1
                        print(f"Form note: valgus ratio {valgus_ratio:.2f} > {self.valgus_threshold}")

                # Reset counters for next rep
                self.knee_valgus_frames = 0
                self.rep_frame_count = 0

            self.stage = 'up'

    def draw_feedback(self, frame, landmarks, frame_width, frame_height):
        cv2.putText(frame, f"Reps: {self.reps}", (10, 90),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

        side = pick_side_visibility(landmarks)
        if side == 'L':
            knee = landmarks[25]  # LEFT_KNEE
            ankle = landmarks[27]  # LEFT_ANKLE
        else:
            knee = landmarks[26]  # RIGHT_KNEE
            ankle = landmarks[28]  # RIGHT_ANKLE

        kx, ky = lm_xy(knee, frame_width, frame_height)
        ax, ay = lm_xy(ankle, frame_width, frame_height)

        knee_valgus = False
        
        if side == 'L' and kx < ax - 25:
            knee_valgus = True
        elif side == 'R' and kx > ax + 25:
            knee_valgus = True

        if knee_valgus:
            cv2.putText(frame, "FORM NOTE: Knees slightly inward",
                        (frame_width // 2 - 150, 90),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)  # Yellow note

    def finalize_score(self):
        """Compute final score for squats with relaxed form scoring"""
        if self.reps > 0:
            # More generous scoring - form errors have less impact
            accuracy = (self.reps - (self.form_errors * 0.5)) / self.reps  # Reduced penalty
            accuracy = max(0.4, accuracy)  # Give at least 40% credit for effort
            self.score = round(accuracy * 100, 1)
        else:
            self.score = 0.0

    def generate_feedback(self):
        """Descriptive feedback after squats"""
        if self.reps == 0:
            return f"No squats recorded. Try again making sure you are fully visible."

        avg_depth = np.mean(self.rep_depths) if self.rep_depths else 0
        min_depth = np.min(self.rep_depths) if self.rep_depths else 0
        max_depth = np.max(self.rep_depths) if self.rep_depths else 0

        feedback = [f"Squats Feedback:",
                    f"- Total reps: {self.reps}",
                    f"- Score: {self.score}/100",
                    f"- Form notes: {self.form_errors}",
                    f"- Average squat depth (knee angle): {avg_depth:.1f}°",
                    f"- Deepest squat: {min_depth:.1f}° (smaller is deeper)",
                    f"- Highest squat: {max_depth:.1f}°"]

        if self.form_errors > 0:
            feedback.append("💡 Minor knee alignment notes - keep practicing!")
        else:
            feedback.append("✅ Excellent knee alignment!")
            
        if avg_depth > 120:
            feedback.append("💡 Go a bit deeper for more effective squats (target <110°).")
        elif avg_depth > 100:
            feedback.append("✅ Good depth achieved!")
        else:
            feedback.append("⭐ Excellent depth - great range of motion!")

        return "\n".join(feedback)

    def reset(self):
        super().reset()
        self.knee_angles.clear()
        self.stage = 'up'
        self.last_rep_t = 0.0
        self.knee_valgus_frames = 0
        self.rep_frame_count = 0
        self.rep_depths.clear()
        self.score = 0.0