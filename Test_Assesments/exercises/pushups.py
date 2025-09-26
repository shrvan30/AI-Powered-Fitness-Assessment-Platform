"""
Push-ups Exercise Implementation (Corrected + Feedback)
"""

import numpy as np
from collections import deque
import time
import cv2
from base_exercise import BaseExercise, FitnessComponent
from utils.pose_utils import angle_3pt, pick_side_visibility, lm_xy

class Pushups(BaseExercise):
    def __init__(self, name, component, ideal_reps=12):
        super().__init__(name, component, ideal_reps=ideal_reps)
        self.down_thresh = 90.0
        self.up_thresh = 160.0
        self.min_interval = 1.0
        self.smooth_n = 5
        self.elbow_angles = deque(maxlen=self.smooth_n)
        self.stage = 'up'
        self.last_rep_t = 0.0

        # form tracking
        self.hip_error_count = 0
        self.rep_frame_count = 0
        self.consecutive_error_frames = 0
        self.error_threshold = 0.12   # relaxed threshold (12%)

        # feedback tracking
        self.rep_depths = []   # stores min elbow angle per rep
        self.rep_extensions = []  # stores max elbow angle per rep

    def calculate_score(self):
        if self.ideal_reps:
            completion = min(1.0, self.reps / self.ideal_reps)
            form_penalty = max(0, 1 - (self.form_errors / (self.reps + 1)) * 0.3)
            self.score = round(completion * form_penalty * 100, 1)
        return self.score

    def update(self, landmarks, frame_width, frame_height):
        side = pick_side_visibility(landmarks)

        if side == 'L':
            shoulder = landmarks[11]  # LEFT_SHOULDER
            elbow = landmarks[13]     # LEFT_ELBOW
            wrist = landmarks[15]     # LEFT_WRIST
        else:
            shoulder = landmarks[12]  # RIGHT_SHOULDER
            elbow = landmarks[14]     # RIGHT_ELBOW
            wrist = landmarks[16]     # RIGHT_WRIST

        # Calculate elbow angle
        sx, sy = lm_xy(shoulder, frame_width, frame_height)
        ex, ey = lm_xy(elbow, frame_width, frame_height)
        wx, wy = lm_xy(wrist, frame_width, frame_height)
        elbow_angle = angle_3pt((sx, sy), (ex, ey), (wx, wy))

        # Check hip alignment
        lshoulder = landmarks[11]
        rshoulder = landmarks[12]
        lhip = landmarks[23]
        rhip = landmarks[24]
        lankle = landmarks[27]
        rankle = landmarks[28]

        shoulder_y = (lshoulder.y + rshoulder.y) / 2
        hip_y = (lhip.y + rhip.y) / 2
        ankle_y = (lankle.y + rankle.y) / 2

        hip_alignment_error = (
            abs(shoulder_y - hip_y) > self.error_threshold or
            abs(hip_y - ankle_y) > self.error_threshold
        )

        if np.isnan(elbow_angle):
            return

        self.elbow_angles.append(elbow_angle)
        avg = np.nanmean(self.elbow_angles)

        # update frame counters
        self.rep_frame_count += 1
        if hip_alignment_error:
            self.consecutive_error_frames += 1
        else:
            self.consecutive_error_frames = 0

        # only count error if sustained bad posture
        if self.consecutive_error_frames >= 10:  # ~⅓ sec at 30fps
            self.hip_error_count += 1
            self.consecutive_error_frames = 0  # avoid overcounting

        # rep logic
        now = time.time()
        if self.stage == 'up' and avg <= self.down_thresh:
            self.stage = 'down'
            self.current_min_angle = avg  # start tracking depth
        elif self.stage == 'down' and avg >= self.up_thresh:
            if now - self.last_rep_t >= self.min_interval:
                self.reps += 1
                self.last_rep_t = now

                # decide rep-level error
                if self.hip_error_count > (0.3 * self.rep_frame_count):
                    self.form_errors += 1

                # record depth/extension feedback
                self.rep_depths.append(self.current_min_angle)
                self.rep_extensions.append(avg)

                # reset per-rep counters
                self.hip_error_count = 0
                self.rep_frame_count = 0
                self.consecutive_error_frames = 0

            self.stage = 'up'

    def draw_feedback(self, frame, landmarks, frame_width, frame_height):
        cv2.putText(frame, f"Reps: {self.reps}", (10, 90),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

        # Check hip alignment (real-time feedback)
        lshoulder = landmarks[11]
        rshoulder = landmarks[12]
        lhip = landmarks[23]
        rhip = landmarks[24]
        lankle = landmarks[27]
        rankle = landmarks[28]

        shoulder_y = (lshoulder.y + rshoulder.y) / 2
        hip_y = (lhip.y + rhip.y) / 2
        ankle_y = (lankle.y + rankle.y) / 2

        hip_alignment_error = (
            abs(shoulder_y - hip_y) > self.error_threshold or
            abs(hip_y - ankle_y) > self.error_threshold
        )

        if hip_alignment_error:
            cv2.putText(frame, "FORM ERROR: Keep body straight!",
                        (frame_width // 2 - 150, 90),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

    def generate_feedback(self):
        """Generate descriptive feedback after test ends"""
        feedback = []
        feedback.append(f"Total Reps: {self.reps}")
        feedback.append(f"Score: {self.score}/100")
        feedback.append(f"Form Errors: {self.form_errors}")

        if self.rep_depths:
            avg_depth = np.mean(self.rep_depths)
            if avg_depth <= 95:
                feedback.append("Depth: Excellent (chest low enough)")
            elif avg_depth <= 110:
                feedback.append("Depth: Acceptable, try to go lower")
            else:
                feedback.append("Depth: Too shallow, bend elbows more")

        if self.rep_extensions:
            avg_extension = np.mean(self.rep_extensions)
            if avg_extension >= 160:
                feedback.append("Lockout: Full extension at top")
            else:
                feedback.append("Lockout: Incomplete, extend arms fully")

        if self.form_errors == 0:
            feedback.append("Hip Alignment: Excellent, body stayed straight")
        else:
            feedback.append(f"Hip Alignment: Broke form {self.form_errors} times")

        return "\n".join(feedback)

    def reset(self):
        super().reset()
        self.elbow_angles.clear()
        self.stage = 'up'
        self.last_rep_t = 0.0
        self.hip_error_count = 0
        self.rep_frame_count = 0
        self.consecutive_error_frames = 0
        self.rep_depths = []
        self.rep_extensions = []
