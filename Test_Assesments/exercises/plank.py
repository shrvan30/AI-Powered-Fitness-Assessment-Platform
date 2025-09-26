"""
Plank Exercise Implementation
"""

import numpy as np
from collections import deque
import time
import cv2
from base_exercise import BaseExercise, FitnessComponent
from utils.pose_utils import angle_3pt, lm_xy, pick_side_visibility


class Plank(BaseExercise):
    def __init__(self, name, component, ideal_time=60):
        super().__init__(name, component, ideal_time=ideal_time)
        
        # Angle thresholds for proper plank form
        self.hip_angle_threshold = 180.0  # Ideal hip angle
        self.hip_angle_tolerance = 15.0   # ± tolerance
        self.torso_leg_deviation_threshold = 15.0  # Max deviation between torso and leg
        self.head_deviation_threshold = 20.0       # Max head deviation
        
        # Time tracking
        self.plank_start_time = None
        self.valid_duration = 0.0
        self.last_valid_time = None
        self.break_threshold = 2.0  # 2 seconds continuous break ends the test
        
        # Form tracking
        self.hip_angles = deque(maxlen=30)
        self.deviations = deque(maxlen=100)
        self.hip_y_positions = deque(maxlen=30)
        self.state = "calibrating"  # Changed from "not_started" to "calibrating"
        
        # Quality metrics
        self.avg_deviation = 0.0
        self.symmetry_score = 100.0
        self.stability_score = 100.0
        self.form_quality = 1.0
        
        # Side detection
        self.detected_side = None
        self.baseline_hip_angle = None
        self.calibrated = False
        self.calibration_frames = deque(maxlen=30)  # Store 30 frames for calibration
        self.calibration_start_time = None
        
    def distance_2d(self, point1, point2):
        """Calculate 2D distance between two points"""
        return np.sqrt((point2[0] - point1[0])**2 + (point2[1] - point1[1])**2)
    
    def calculate_hip_angle(self, landmarks, frame_width, frame_height):
        """Calculate hip angle using the best visible side"""
        if self.detected_side is None:
            self.detected_side = pick_side_visibility(landmarks)
        
        if self.detected_side == 'L':
            shoulder = landmarks[11]  # LEFT_SHOULDER
            hip = landmarks[23]       # LEFT_HIP
            ankle = landmarks[27]     # LEFT_ANKLE
        else:
            shoulder = landmarks[12]  # RIGHT_SHOULDER
            hip = landmarks[24]       # RIGHT_HIP
            ankle = landmarks[28]     # RIGHT_ANKLE
        
        sx, sy = lm_xy(shoulder, frame_width, frame_height)
        hx, hy = lm_xy(hip, frame_width, frame_height)
        ax, ay = lm_xy(ankle, frame_width, frame_height)
        
        return angle_3pt((sx, sy), (hx, hy), (ax, ay))
    
    def calculate_torso_leg_deviation(self, landmarks, frame_width, frame_height):
        """Calculate deviation between torso and leg vectors"""
        if self.detected_side == 'L':
            shoulder = landmarks[11]  # LEFT_SHOULDER
            hip = landmarks[23]       # LEFT_HIP
            ankle = landmarks[27]     # LEFT_ANKLE
        else:
            shoulder = landmarks[12]  # RIGHT_SHOULDER
            hip = landmarks[24]       # RIGHT_HIP
            ankle = landmarks[28]     # RIGHT_ANKLE
        
        # Calculate vectors
        sx, sy = lm_xy(shoulder, frame_width, frame_height)
        hx, hy = lm_xy(hip, frame_width, frame_height)
        ax, ay = lm_xy(ankle, frame_width, frame_height)
        
        torso_vec = np.array([sx - hx, sy - hy])
        leg_vec = np.array([hx - ax, hy - ay])
        
        # Calculate angle between vectors
        dot_product = np.dot(torso_vec, leg_vec)
        magnitude_product = np.linalg.norm(torso_vec) * np.linalg.norm(leg_vec)
        
        if magnitude_product == 0:
            return 0.0
            
        cos_angle = dot_product / magnitude_product
        cos_angle = np.clip(cos_angle, -1.0, 1.0)
        angle_rad = np.arccos(cos_angle)
        return np.degrees(angle_rad)
    
    def calculate_head_deviation(self, landmarks, frame_width, frame_height):
        """Calculate head deviation from shoulder-hip line"""
        if self.detected_side == 'L':
            shoulder = landmarks[11]  # LEFT_SHOULDER
            hip = landmarks[23]       # LEFT_HIP
            ear = landmarks[7]        # LEFT_EAR
        else:
            shoulder = landmarks[12]  # RIGHT_SHOULDER
            hip = landmarks[24]       # RIGHT_HIP
            ear = landmarks[8]        # RIGHT_EAR
        
        sx, sy = lm_xy(shoulder, frame_width, frame_height)
        hx, hy = lm_xy(hip, frame_width, frame_height)
        ex, ey = lm_xy(ear, frame_width, frame_height)
        
        return angle_3pt((sx, sy), (hx, hy), (ex, ey))
    
    def calculate_symmetry(self, landmarks, frame_width, frame_height):
        """Calculate symmetry between left and right sides"""
        try:
            # Left side
            l_shoulder = landmarks[11]
            l_hip = landmarks[23]
            l_ankle = landmarks[27]
            
            lsx, lsy = lm_xy(l_shoulder, frame_width, frame_height)
            lhx, lhy = lm_xy(l_hip, frame_width, frame_height)
            lax, lay = lm_xy(l_ankle, frame_width, frame_height)
            left_angle = angle_3pt((lsx, lsy), (lhx, lhy), (lax, lay))
            
            # Right side
            r_shoulder = landmarks[12]
            r_hip = landmarks[24]
            r_ankle = landmarks[28]
            
            rsx, rsy = lm_xy(r_shoulder, frame_width, frame_height)
            rhx, rhy = lm_xy(r_hip, frame_width, frame_height)
            rax, ray = lm_xy(r_ankle, frame_width, frame_height)
            right_angle = angle_3pt((rsx, rsy), (rhx, rhy), (rax, ray))
            
            return abs(left_angle - right_angle)
        except:
            return 0.0  # Return 0 if any landmarks are not visible
    
    def check_landmark_visibility(self, landmarks, indices):
        """Check if landmarks are visible"""
        for idx in indices:
            if landmarks[idx].visibility < 0.5:
                return False
        return True
    
    def calibrate(self, hip_angle):
        """Calibrate based on initial posture"""
        if self.calibration_start_time is None:
            self.calibration_start_time = time.time()
            
        self.calibration_frames.append(hip_angle)
        
        if len(self.calibration_frames) >= 30:  # After 30 frames
            self.baseline_hip_angle = np.mean(self.calibration_frames)
            self.calibrated = True
            self.state = "ready"  # Change state to ready after calibration
            return True
        return False
    
    def update(self, landmarks, frame_width, frame_height):
        current_time = time.time()
        
        # Calculate metrics
        hip_angle = self.calculate_hip_angle(landmarks, frame_width, frame_height)
        torso_leg_deviation = self.calculate_torso_leg_deviation(landmarks, frame_width, frame_height)
        head_deviation = self.calculate_head_deviation(landmarks, frame_width, frame_height)
        
        if np.isnan(hip_angle) or np.isnan(torso_leg_deviation) or np.isnan(head_deviation):
            return
        
        # Store metrics for analysis
        self.hip_angles.append(hip_angle)
        self.deviations.append(abs(hip_angle - self.hip_angle_threshold))
        
        # Store hip y-position for stability analysis
        if self.detected_side == 'L':
            hip = landmarks[23]
        else:
            hip = landmarks[24]
        hx, hy = lm_xy(hip, frame_width, frame_height)
        self.hip_y_positions.append(hy)
        
        # Check landmark visibility
        if self.detected_side == 'L':
            visible = self.check_landmark_visibility(landmarks, [11, 23, 27, 7])
        else:
            visible = self.check_landmark_visibility(landmarks, [12, 24, 28, 8])
        
        # Calibration phase
        if not self.calibrated:
            if self.calibrate(hip_angle):
                print("Plank calibration complete!")
            return
        
        # Check if posture is valid
        is_valid = (
            visible and
            abs(hip_angle - self.baseline_hip_angle) <= self.hip_angle_tolerance and
            torso_leg_deviation <= self.torso_leg_deviation_threshold and
            head_deviation <= self.head_deviation_threshold
        )
        
        # State machine for plank timing
        if self.state == "ready" and is_valid:
            # Start the plank timer when user gets into position after calibration
            self.state = "valid"
            self.plank_start_time = current_time
            self.last_valid_time = current_time
        
        elif self.state == "valid":
            if is_valid:
                # Continuing valid plank
                self.last_valid_time = current_time
                self.duration = current_time - self.plank_start_time
            else:
                # Check if break is longer than threshold
                if current_time - self.last_valid_time > self.break_threshold:
                    # End the plank
                    self.state = "completed"
                    self.valid_duration = self.duration
                # Still within break allowance, don't change state
        
        elif self.state == "completed":
            # Plank is already completed
            pass
    
    def draw_feedback(self, frame, landmarks, frame_width, frame_height):
        # Display current state
        status_color = (0, 255, 0)  # Green for good states
        
        if self.state == "calibrating":
            status_text = "CALIBRATING: Get into plank position"
            status_color = (0, 255, 255)  # Yellow for calibration
        elif self.state == "ready":
            status_text = "READY: Hold plank position to start"
            status_color = (0, 255, 255)  # Yellow for ready
        elif self.state == "valid":
            status_text = "PLANK: HOLD"
            status_color = (0, 255, 0)  # Green for valid
        elif self.state == "completed":
            status_text = "COMPLETED"
            status_color = (255, 0, 0)  # Red for completed
        else:
            status_text = "GET INTO POSITION"
            status_color = (255, 255, 0)  # Yellow for other states
        
        cv2.putText(frame, status_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, status_color, 2)
        
        # Display time if plank is active
        if self.state == "valid":
            time_text = f"Time: {self.duration:.1f}s / {self.ideal_time}s"
            cv2.putText(frame, time_text, (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        
        # Display calibration status
        if not self.calibrated:
            cal_progress = len(self.calibration_frames)
            cal_text = f"Calibration: {cal_progress}/30 frames"
            cv2.putText(frame, cal_text, (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 0), 2)
            cv2.putText(frame, "Hold still in plank position", (10, 120), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 0), 2)
            return
        
        # Display form metrics
        y_offset = 90
        cv2.putText(frame, f"Form Quality: {self.form_quality:.2f}", (10, y_offset), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        cv2.putText(frame, f"Deviation: {self.avg_deviation:.1f}°", (10, y_offset + 25), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        cv2.putText(frame, f"Symmetry: {self.symmetry_score:.1f}%", (10, y_offset + 50), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        cv2.putText(frame, f"Stability: {self.stability_score:.1f}%", (10, y_offset + 75), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        
        # Real-time feedback
        hip_angle = self.calculate_hip_angle(landmarks, frame_width, frame_height)
        if not np.isnan(hip_angle):
            if abs(hip_angle - self.baseline_hip_angle) > self.hip_angle_tolerance:
                cv2.putText(frame, "ADJUST HIP POSITION", (frame_width//2 - 150, 30), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
            
            torso_dev = self.calculate_torso_leg_deviation(landmarks, frame_width, frame_height)
            if torso_dev > self.torso_leg_deviation_threshold:
                cv2.putText(frame, "STRAIGHTEN BODY", (frame_width//2 - 120, 60), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
    
    def calculate_score(self):
        """Calculate final score based on duration and form quality"""
        if self.state == "completed" or (self.state == "valid" and self.duration >= self.ideal_time):
            completion = min(1.0, self.valid_duration / self.ideal_time)
            self.score = round(completion * self.form_quality * 100, 1)
        else:
            self.score = 0.0
        return self.score
    
    def generate_feedback(self):
        """Generate descriptive feedback after plank"""
        if not self.calibrated:
            return "Plank not completed. Please maintain proper form for calibration."
        
        feedback = [
            f"Plank Assessment ({'Left' if self.detected_side == 'L' else 'Right'} Side View):",
            f"- Duration: {self.valid_duration:.1f}s / {self.ideal_time}s",
            f"- Score: {self.score}/100",
            f"- Form Quality: {self.form_quality:.2f}",
            f"- Average Deviation: {self.avg_deviation:.1f}° from ideal",
            f"- Symmetry: {self.symmetry_score:.1f}%",
            f"- Stability: {self.stability_score:.1f}%"
        ]
        
        # Form-specific feedback
        if self.avg_deviation > 10:
            feedback.append("💡 Focus on maintaining a straight line from shoulders to ankles")
        else:
            feedback.append("✅ Excellent body alignment!")
        
        if self.symmetry_score < 80:
            feedback.append("💡 Work on keeping both sides of your body even")
        else:
            feedback.append("✅ Good symmetry!")
        
        if self.stability_score < 80:
            feedback.append("💡 Try to minimize hip movement for better stability")
        else:
            feedback.append("✅ Great stability!")
        
        if self.form_quality < 0.7:
            feedback.append("💡 Overall form needs improvement - focus on alignment and stability")
        else:
            feedback.append("✅ Excellent plank form overall!")
        
        return "\n".join(feedback)
    
    def reset(self):
        super().reset()
        self.plank_start_time = None
        self.valid_duration = 0.0
        self.last_valid_time = None
        self.hip_angles.clear()
        self.deviations.clear()
        self.hip_y_positions.clear()
        self.state = "calibrating"  # Reset to calibrating
        self.avg_deviation = 0.0
        self.symmetry_score = 100.0
        self.stability_score = 100.0
        self.form_quality = 1.0
        self.detected_side = None
        self.baseline_hip_angle = None
        self.calibrated = False
        self.calibration_frames.clear()
        self.calibration_start_time = None