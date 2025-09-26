"""
Vertical Jump Exercise Implementation (Scientific Framework)
"""

import time
import cv2
import numpy as np
from base_exercise import BaseExercise, FitnessComponent
from utils.pose_utils import lm_xy, angle_3pt

class VerticalJump(BaseExercise):
    def __init__(self, name, component, user_height_cm=170):
        super().__init__(name, component)
        self.user_height_cm = user_height_cm
        self.calibrated = False
        self.cm_per_px = None
        self.baseline_hip_y = None
        
        # Flight time method tracking
        self.takeoff_time = None
        self.landing_time = None
        self.in_air = False
        self.flight_time = 0.0
        
        # CoM method tracking
        self.min_hip_y = None
        self.max_hip_y = None
        
        # Biomechanics tracking
        self.knee_angles = []
        self.hip_angles = []
        self.takeoff_symmetry = 0.0
        
        # Performance metrics
        self.jump_heights_flight = []  # Flight time method
        self.jump_heights_com = []     # CoM displacement method
        self.best_jump = 0.0
        self.form_errors = 0
        self.min_jump_threshold_cm = 15  # minimal jump considered valid
        
        # Calibration
        self.calibration_frames = 0
        self.baseline_knee_angle = None

    def calculate_score(self):
        if self.jump_heights_flight:
            # Use flight time method as primary measurement
            avg_jump = sum(self.jump_heights_flight) / len(self.jump_heights_flight)
            ideal_height = 50  # 50cm ideal jump height
            completion = min(1.0, avg_jump / ideal_height)
            
            # Form penalty based on biomechanics and symmetry
            form_penalty = max(0.7, 1 - (self.form_errors / len(self.jump_heights_flight)) * 0.3)
            
            # Additional penalty for poor symmetry
            symmetry_penalty = max(0.8, self.takeoff_symmetry / 100)
            
            self.score = round(completion * form_penalty * symmetry_penalty * 100, 1)
        else:
            self.score = 0
        return self.score

    def calibrate(self, frame_width, frame_height, landmarks):
        """Calibrate using user height and establish baseline"""
        # Use nose to heels for height calibration
        nose = landmarks[0]  # NOSE
        lheel = landmarks[29]  # LEFT_HEEL
        rheel = landmarks[30]  # RIGHT_HEEL

        if lheel.visibility < 0.4 or rheel.visibility < 0.4:
            lheel = landmarks[27]  # LEFT_ANKLE
            rheel = landmarks[28]  # RIGHT_ANKLE

        nx, ny = lm_xy(nose, frame_width, frame_height)
        lx, ly = lm_xy(lheel, frame_width, frame_height)
        rx, ry = lm_xy(rheel, frame_width, frame_height)
        heel_y = int((ly + ry) / 2)

        pixel_height = abs(heel_y - ny)
        if pixel_height < 50:
            return False, "Calibration failed: ensure full body visible."

        self.cm_per_px = self.user_height_cm / float(pixel_height)

        # Establish baseline hip position
        lhip = landmarks[23]  # LEFT_HIP
        rhip = landmarks[24]  # RIGHT_HIP
        hx = (lhip.x + rhip.x) / 2.0
        hy = (lhip.y + rhip.y) / 2.0
        _, hip_y = lm_xy(type('obj', (), {'x': hx, 'y': hy})(), frame_width, frame_height)
        self.baseline_hip_y = hip_y
        
        # Establish baseline knee angle
        self.calculate_knee_angles(landmarks, frame_width, frame_height)
        if self.knee_angles:
            self.baseline_knee_angle = np.mean(self.knee_angles[-5:])  # Average last 5 frames
        
        self.calibration_frames += 1
        if self.calibration_frames >= 30:  # 30 frames of calibration
            self.calibrated = True
            return True, "Calibration complete. Ready to jump!"
        
        return False, f"Calibrating... {self.calibration_frames}/30 frames"

    def calculate_knee_angles(self, landmarks, frame_width, frame_height):
        """Calculate knee angles for both legs"""
        # Left knee angle
        l_hip = landmarks[23]  # LEFT_HIP
        l_knee = landmarks[25]  # LEFT_KNEE
        l_ankle = landmarks[27]  # LEFT_ANKLE
        
        lhx, lhy = lm_xy(l_hip, frame_width, frame_height)
        lkx, lky = lm_xy(l_knee, frame_width, frame_height)
        lax, lay = lm_xy(l_ankle, frame_width, frame_height)
        left_angle = angle_3pt((lhx, lhy), (lkx, lky), (lax, lay))
        
        # Right knee angle
        r_hip = landmarks[24]  # RIGHT_HIP
        r_knee = landmarks[26]  # RIGHT_KNEE
        r_ankle = landmarks[28]  # RIGHT_ANKLE
        
        rhx, rhy = lm_xy(r_hip, frame_width, frame_height)
        rkx, rky = lm_xy(r_knee, frame_width, frame_height)
        rax, ray = lm_xy(r_ankle, frame_width, frame_height)
        right_angle = angle_3pt((rhx, rhy), (rkx, rky), (rax, ray))
        
        if not np.isnan(left_angle) and not np.isnan(right_angle):
            self.knee_angles.append((left_angle, right_angle))
            return left_angle, right_angle
        return None, None

    def detect_takeoff(self, landmarks, frame_width, frame_height):
        """Detect when feet leave the ground"""
        l_ankle = landmarks[27]  # LEFT_ANKLE
        r_ankle = landmarks[28]  # RIGHT_ANKLE
        
        # Check if ankles are visible and moving upward rapidly
        if l_ankle.visibility > 0.6 and r_ankle.visibility > 0.6:
            lax, lay = lm_xy(l_ankle, frame_width, frame_height)
            rax, ray = lm_xy(r_ankle, frame_width, frame_height)
            
            # Simple heuristic: rapid upward movement indicates takeoff
            if self.baseline_hip_y is not None:
                current_ankle_y = (lay + ray) / 2
                if current_ankle_y < self.baseline_hip_y - 20:  # Ankles above hips
                    return True
        return False

    def detect_landing(self, landmarks, frame_width, frame_height):
        """Detect when feet touch the ground"""
        l_ankle = landmarks[27]  # LEFT_ANKLE
        r_ankle = landmarks[28]  # RIGHT_ANKLE
        
        if l_ankle.visibility > 0.7 and r_ankle.visibility > 0.7:
            lax, lay = lm_xy(l_ankle, frame_width, frame_height)
            rax, ray = lm_xy(r_ankle, frame_width, frame_height)
            
            # Landed when ankles return near baseline position
            if self.baseline_hip_y is not None:
                current_ankle_y = (lay + ray) / 2
                if abs(current_ankle_y - self.baseline_hip_y) < 30:
                    return True
        return False

    def update(self, landmarks, frame_width, frame_height):
        if not self.calibrated:
            success, msg = self.calibrate(frame_width, frame_height, landmarks)
            return

        # Calculate current hip position (CoM approximation)
        lhip = landmarks[23]  # LEFT_HIP
        rhip = landmarks[24]  # RIGHT_HIP
        hx = (lhip.x + rhip.x) / 2.0
        hy = (lhip.y + rhip.y) / 2.0
        _, hip_y = lm_xy(type('obj', (), {'x': hx, 'y': hy})(), frame_width, frame_height)
        
        # Calculate knee angles for biomechanics
        left_knee, right_knee = self.calculate_knee_angles(landmarks, frame_width, frame_height)
        
        now = time.time()
        
        # Detect takeoff
        if not self.in_air and self.detect_takeoff(landmarks, frame_width, frame_height):
            self.in_air = True
            self.takeoff_time = now
            self.min_hip_y = hip_y  # Start tracking lowest hip position
            
            # Record takeoff symmetry
            if left_knee is not None and right_knee is not None:
                self.takeoff_symmetry = 100 - abs(left_knee - right_knee)
        
        # During jump
        if self.in_air:
            # Track minimum hip position (highest point in jump)
            if hip_y < self.min_hip_y:
                self.min_hip_y = hip_y
            
            # Detect landing
            if self.detect_landing(landmarks, frame_width, frame_height):
                self.in_air = False
                self.landing_time = now
                
                # Calculate jump height using flight time method (primary)
                self.flight_time = self.landing_time - self.takeoff_time
                jump_height_flight = (9.81 * (self.flight_time ** 2)) / 8  # in meters
                jump_height_flight_cm = jump_height_flight * 100  # convert to cm
                
                # Calculate jump height using CoM method (validation)
                delta_px = self.baseline_hip_y - self.min_hip_y
                jump_height_com_cm = max(0.0, delta_px * self.cm_per_px)
                
                # Use flight time as primary, validate with CoM
                if abs(jump_height_flight_cm - jump_height_com_cm) < 10:  # Within 10cm difference
                    final_height = jump_height_flight_cm
                else:
                    final_height = jump_height_com_cm  # Fallback to CoM
                
                # Check for valid jump
                if final_height >= self.min_jump_threshold_cm:
                    self.jump_heights_flight.append(final_height)
                    self.jump_heights_com.append(jump_height_com_cm)
                    self.best_jump = max(self.best_jump, final_height)
                    
                    # Check form: proper knee extension at takeoff
                    if left_knee is not None and right_knee is not None:
                        avg_takeoff_angle = (left_knee + right_knee) / 2
                        if avg_takeoff_angle < 160:  # Should be near full extension (~180°)
                            self.form_errors += 1
                else:
                    self.form_errors += 1  # Jump too shallow

    def draw_feedback(self, frame, landmarks, frame_width, frame_height):
        if not self.calibrated:
            cv2.putText(frame, "Calibrating... Stand straight", (10, 90), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
            cv2.putText(frame, f"Progress: {self.calibration_frames}/30", (10, 120), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        else:
            status = "READY" if not self.in_air else "IN AIR"
            status_color = (0, 255, 0) if not self.in_air else (0, 255, 255)
            cv2.putText(frame, f"Status: {status}", (10, 90), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, status_color, 2)
            
            if self.jump_heights_flight:
                last_jump = self.jump_heights_flight[-1]
                cv2.putText(frame, f"Last Jump: {last_jump:.1f}cm", (10, 120), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            
            cv2.putText(frame, f"Best Jump: {self.best_jump:.1f}cm", (10, 150), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
            cv2.putText(frame, f"Total Jumps: {len(self.jump_heights_flight)}", (10, 180), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            
            # Show flight time if available
            if self.flight_time > 0:
                cv2.putText(frame, f"Flight Time: {self.flight_time:.2f}s", (10, 210), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
            
            # Show symmetry score
            cv2.putText(frame, f"Symmetry: {self.takeoff_symmetry:.1f}%", (10, 240), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

    def generate_feedback(self):
        if not self.jump_heights_flight:
            return "No valid jumps recorded. Try jumping higher with proper form."
        
        avg_jump = sum(self.jump_heights_flight) / len(self.jump_heights_flight)
        max_flight_time = max([(9.81 * (t**2)) / 8 * 100 for t in [self.flight_time]]) if self.flight_time > 0 else 0
        
        feedback = [
            f"Vertical Jump Assessment (Scientific Measurement):",
            f"- Total jumps: {len(self.jump_heights_flight)}",
            f"- Best jump: {self.best_jump:.1f}cm",
            f"- Average jump: {avg_jump:.1f}cm",
            f"- Flight time: {self.flight_time:.2f}s",
            f"- Takeoff symmetry: {self.takeoff_symmetry:.1f}%",
            f"- Score: {self.score}/100",
            f"- Form errors: {self.form_errors}"
        ]
        
        # Biomechanical feedback
        if self.takeoff_symmetry < 85:
            feedback.append("💡 Work on symmetrical leg extension during takeoff")
        else:
            feedback.append("✅ Excellent symmetry in jump execution!")
        
        if self.form_errors > 0:
            feedback.append("⚠️ Some jumps had incomplete leg extension or were too shallow")
        else:
            feedback.append("✅ Good jumping technique maintained!")
        
        # Performance categorization
        if self.best_jump > 60:
            feedback.append("🎯 Elite jumping power!")
        elif self.best_jump > 45:
            feedback.append("🔥 Excellent jumping ability!")
        elif self.best_jump > 35:
            feedback.append("👍 Good vertical jump performance!")
        else:
            feedback.append("💪 Keep practicing to improve your vertical!")
        
        return "\n".join(feedback)

    def reset(self):
        super().reset()
        self.calibrated = False
        self.cm_per_px = None
        self.baseline_hip_y = None
        self.takeoff_time = None
        self.landing_time = None
        self.in_air = False
        self.flight_time = 0.0
        self.min_hip_y = None
        self.max_hip_y = None
        self.knee_angles.clear()
        self.hip_angles.clear()
        self.takeoff_symmetry = 0.0
        self.jump_heights_flight.clear()
        self.jump_heights_com.clear()
        self.best_jump = 0.0
        self.form_errors = 0
        self.calibration_frames = 0
        self.baseline_knee_angle = None