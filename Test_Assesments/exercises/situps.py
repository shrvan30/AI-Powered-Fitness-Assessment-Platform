"""
Sit-ups Exercise Implementation
"""

import numpy as np
from collections import deque
import time
import cv2
from base_exercise import BaseExercise, FitnessComponent
from utils.pose_utils import angle_3pt, lm_xy, pick_side_visibility


class Situps(BaseExercise):
    def __init__(self, name, component, ideal_reps=20):
        super().__init__(name, component, ideal_reps=ideal_reps)
        
        # CORRECTED angle thresholds based on proper sit-up mechanics
        self.down_thresh = 145.0    # Lying back position (120-145° - larger angle)
        self.up_thresh = 87.0       # Sitting up position (30-45° - smaller angle)
        self.min_interval = 1.0
        self.smooth_n = 5
        self.torso_angles = deque(maxlen=self.smooth_n)
        self.stage = 'down'
        self.last_rep_t = 0.0
        self.detected_side = None

        # form tracking
        self.incomplete_up_frames = 0    # Count frames not sitting up enough
        self.incomplete_down_frames = 0  # Count frames not returning fully
        self.rep_frame_count = 0
        self.rep_depths = []   # minimum torso angle per rep (most upright)
        self.rep_returns = []  # maximum torso angle per rep (most lying down)
        self.score = 0.0
        
        # form error thresholds
        self.incomplete_up_threshold = 0.7    # 70% of frames with poor sit-up
        self.incomplete_down_threshold = 0.7  # 70% of frames with poor return
        
        # Measurement parameters
        self.measurement_data = {
            'rep_count': 0,
            'rom_angles': [],  # Range of motion angles for each rep
            'speed_data': [],  # Time taken for each rep
            'consistency_score': 0,
            'fatigue_factor': 0,
            'technique_analysis': {
                'upper_body_engagement': 0,
                'core_activation': 0,
                'hip_flexor_dominance': 0
            }
        }
        
        # Rep timing tracking
        self.rep_start_time = 0
        self.rep_times = deque(maxlen=10)
        
        # ROM consistency tracking
        self.rom_values = deque(maxlen=10)
        
        # Fatigue tracking
        self.first_half_avg_speed = 0
        self.second_half_avg_speed = 0

    def calculate_torso_angle(self, landmarks, frame_width, frame_height):
        """Calculate angle using the best visible side"""
        if self.detected_side is None:
            self.detected_side = pick_side_visibility(landmarks)
        
        if self.detected_side == 'L':
            shoulder = landmarks[11]  # LEFT_SHOULDER
            hip = landmarks[23]       # LEFT_HIP
            knee = landmarks[25]      # LEFT_KNEE
        else:
            shoulder = landmarks[12]  # RIGHT_SHOULDER
            hip = landmarks[24]       # RIGHT_HIP
            knee = landmarks[26]      # RIGHT_KNEE
        
        sx, sy = lm_xy(shoulder, frame_width, frame_height)
        hx, hy = lm_xy(hip, frame_width, frame_height)
        kx, ky = lm_xy(knee, frame_width, frame_height)
        
        return angle_3pt((sx, sy), (hx, hy), (kx, ky))
    
    def distance_2d(self, point1, point2):
        """Calculate 2D distance between two points"""
        return np.sqrt((point2[0] - point1[0])**2 + (point2[1] - point1[1])**2)
    
    def calculate_technique_metrics(self, landmarks, frame_width, frame_height):
        """Calculate technique analysis metrics"""
        # Get relevant landmarks
        if self.detected_side == 'L':
            shoulder = landmarks[11]
            opposite_shoulder = landmarks[12]
            hip = landmarks[23]
            opposite_hip = landmarks[24]
            elbow = landmarks[13]
            wrist = landmarks[15]
        else:
            shoulder = landmarks[12]
            opposite_shoulder = landmarks[11]
            hip = landmarks[24]
            opposite_hip = landmarks[23]
            elbow = landmarks[14]
            wrist = landmarks[16]
        
        # Calculate shoulder alignment
        shoulder_xy = lm_xy(shoulder, frame_width, frame_height)
        opposite_shoulder_xy = lm_xy(opposite_shoulder, frame_width, frame_height)
        shoulder_y_diff = abs(shoulder_xy[1] - opposite_shoulder_xy[1])
        
        # Calculate hip alignment
        hip_xy = lm_xy(hip, frame_width, frame_height)
        opposite_hip_xy = lm_xy(opposite_hip, frame_width, frame_height)
        hip_y_diff = abs(hip_xy[1] - opposite_hip_xy[1])
        
        # Calculate arm position
        wrist_xy = lm_xy(wrist, frame_width, frame_height)
        wrist_to_shoulder_dist = self.distance_2d(wrist_xy, opposite_shoulder_xy)
        
        # Calculate elbow bend angle
        elbow_xy = lm_xy(elbow, frame_width, frame_height)
        elbow_angle = angle_3pt(shoulder_xy, elbow_xy, wrist_xy)
        
        return {
            'shoulder_alignment': shoulder_y_diff,
            'hip_alignment': hip_y_diff,
            'arm_position': wrist_to_shoulder_dist,
            'elbow_bend': elbow_angle
        }

    def update(self, landmarks, frame_width, frame_height):
        # Calculate torso angle
        torso_angle = self.calculate_torso_angle(landmarks, frame_width, frame_height)

        if np.isnan(torso_angle):
            return

        self.torso_angles.append(torso_angle)
        avg = np.nanmean(self.torso_angles)

        # Count frames and track form issues
        self.rep_frame_count += 1
        
        # Check for incomplete sit-up (not coming up enough)
        if avg > self.up_thresh + 10:  # Should be ≤87° for good sit-up
            self.incomplete_up_frames += 1
        
        # Check for incomplete return (not going back enough)
        if avg < self.down_thresh - 10:  # Should be ≥145° for full return
            self.incomplete_down_frames += 1

        now = time.time()
        if self.stage == 'down' and avg <= self.up_thresh:  # Sat up enough (≤87°)
            self.stage = 'up'
            self.current_rep_min = avg    # Most upright position (smallest angle)
            self.current_rep_max = avg    # Start tracking return
            
            # Start timing the rep
            if self.rep_start_time == 0:
                self.rep_start_time = now
                
        elif self.stage == 'up':
            # Track the most upright and most lying positions
            self.current_rep_min = min(self.current_rep_min, avg)
            self.current_rep_max = max(self.current_rep_max, avg)

            if avg >= self.down_thresh:  # Returned to lying position (≥145°)
                if now - self.last_rep_t >= self.min_interval:
                    self.reps += 1
                    self.last_rep_t = now
                    
                    # Calculate and store rep time
                    if self.rep_start_time > 0:
                        rep_time = now - self.rep_start_time
                        self.rep_times.append(rep_time)
                        self.measurement_data['speed_data'].append(rep_time)
                        self.rep_start_time = 0
                    
                    # Calculate ROM for this rep
                    rom = self.current_rep_max - self.current_rep_min
                    self.rom_values.append(rom)
                    self.measurement_data['rom_angles'].append(rom)

                    # Record depth and return for feedback
                    self.rep_depths.append(self.current_rep_min)  # Smallest angle (most upright)
                    self.rep_returns.append(self.current_rep_max) # Largest angle (most lying down)

                    # Form error checks
                    if self.rep_frame_count > 0:
                        up_error_ratio = self.incomplete_up_frames / self.rep_frame_count
                        down_error_ratio = self.incomplete_down_frames / self.rep_frame_count
                        
                        if up_error_ratio > self.incomplete_up_threshold:
                            self.form_errors += 1
                        if down_error_ratio > self.incomplete_down_threshold:
                            self.form_errors += 1

                    # Reset counters for next rep
                    self.incomplete_up_frames = 0
                    self.incomplete_down_frames = 0
                    self.rep_frame_count = 0
                    
                    # Update measurement data
                    self.measurement_data['rep_count'] = self.reps
                    
                    # Calculate consistency score
                    if self.reps % 5 == 0 and len(self.rom_values) > 0:
                        self.measurement_data['consistency_score'] = round(
                            (1 - (np.std(self.rom_values) / np.mean(self.rom_values))) * 100, 1
                        )
                    
                    # Calculate fatigue factor
                    if self.reps >= 10:
                        half_point = self.reps // 2
                        if len(self.measurement_data['speed_data']) >= half_point:
                            first_half = self.measurement_data['speed_data'][:half_point]
                            second_half = self.measurement_data['speed_data'][half_point:]
                            
                            if len(first_half) > 0 and len(second_half) > 0:
                                first_avg = np.mean(first_half)
                                second_avg = np.mean(second_half)
                                self.measurement_data['fatigue_factor'] = round(
                                    ((second_avg - first_avg) / first_avg) * 100, 1
                                )

                self.stage = 'down'
        
        # Update technique analysis
        if self.reps > 0 and self.reps % 3 == 0:
            technique_metrics = self.calculate_technique_metrics(landmarks, frame_width, frame_height)
            # Simple scoring based on ideal values
            self.measurement_data['technique_analysis']['upper_body_engagement'] = max(0, 100 - technique_metrics['shoulder_alignment'] * 5)
            self.measurement_data['technique_analysis']['core_activation'] = max(0, 100 - technique_metrics['hip_alignment'] * 10)
            self.measurement_data['technique_analysis']['hip_flexor_dominance'] = min(100, technique_metrics['arm_position'] / 2)

    def draw_feedback(self, frame, landmarks, frame_width, frame_height):
        cv2.putText(frame, f"Reps: {self.reps}", (10, 90),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

        # Calculate current torso angle
        torso_angle = self.calculate_torso_angle(landmarks, frame_width, frame_height)

        if not np.isnan(torso_angle):
            # Display current angle for debugging
            cv2.putText(frame, f"Angle: {torso_angle:.1f}°", (10, 120),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
            
            # Stage indicator
            cv2.putText(frame, f"Stage: {self.stage.upper()}", (10, 150),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
            
            # Side detection
            side_text = f"Side: {self.detected_side}" if self.detected_side else "Side: Detecting..."
            cv2.putText(frame, side_text, (10, 180),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
            
            # Real-time form feedback
            if torso_angle > self.up_thresh + 10 and self.stage == 'up':
                cv2.putText(frame, "SIT UP HIGHER", (frame_width // 2 - 100, 210),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
            elif torso_angle < self.down_thresh - 10 and self.stage == 'down':
                cv2.putText(frame, "RETURN FULLY DOWN", (frame_width // 2 - 120, 210),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
            
            # Display measurement data if available
            if self.reps > 0:
                y_offset = 240
                cv2.putText(frame, f"Consistency: {self.measurement_data['consistency_score']}%", 
                           (10, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
                
                if self.reps >= 10:
                    cv2.putText(frame, f"Fatigue: {self.measurement_data['fatigue_factor']}%", 
                               (10, y_offset + 25), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

    def finalize_score(self):
        """Compute final score with form scoring"""
        if self.reps > 0:
            accuracy = (self.reps - (self.form_errors * 0.5)) / self.reps
            accuracy = max(0.4, accuracy)
            
            # Incorporate consistency into final score
            consistency_factor = self.measurement_data['consistency_score'] / 100
            self.score = round(accuracy * consistency_factor * 100, 1)
        else:
            self.score = 0.0

    def generate_feedback(self):
        """Descriptive feedback after sit-ups"""
        if self.reps == 0:
            return "No sit-ups recorded. Make sure your side is visible to the camera."

        avg_depth = np.mean(self.rep_depths) if self.rep_depths else 0
        avg_return = np.mean(self.rep_returns) if self.rep_returns else 0
        avg_speed = np.mean(self.measurement_data['speed_data']) if self.measurement_data['speed_data'] else 0

        feedback = [
            f"Sit-ups Feedback ({'Left' if self.detected_side == 'L' else 'Right'} Side Detection):",
            f"- Total reps: {self.reps}",
            f"- Score: {self.score}/100",
            f"- Form errors: {self.form_errors}",
            f"- Average sit-up angle: {avg_depth:.1f}° (lower is better)",
            f"- Average return angle: {avg_return:.1f}° (higher is better)",
            f"- Consistency: {self.measurement_data['consistency_score']}%",
            f"- Average speed: {avg_speed:.2f}s per rep"
        ]
        
        if self.reps >= 10:
            feedback.append(f"- Fatigue factor: {self.measurement_data['fatigue_factor']}%")

        if self.form_errors > 0:
            feedback.append("💡 Focus on full range of motion - sit all the way up and return all the way down!")
        else:
            feedback.append("✅ Excellent form throughout!")
            
        if avg_depth > self.up_thresh + 5:
            feedback.append("💡 Try to sit up higher (aim for smaller angles)")
        else:
            feedback.append("✅ Good sit-up height!")

        if avg_return < self.down_thresh - 5:
            feedback.append("💡 Return more fully to the starting position (aim for larger angles)")
        else:
            feedback.append("✅ Good return to starting position!")
            
        # Technique feedback
        tech = self.measurement_data['technique_analysis']
        if tech['upper_body_engagement'] < 80:
            feedback.append("💡 Keep shoulders level during movement")
        if tech['core_activation'] < 80:
            feedback.append("💡 Engage your core more throughout the movement")
        if tech['hip_flexor_dominance'] > 70:
            feedback.append("💡 Focus on using your abs rather than pulling with your arms")

        return "\n".join(feedback)

    def reset(self):
        super().reset()
        self.torso_angles.clear()
        self.stage = 'down'
        self.last_rep_t = 0.0
        self.incomplete_up_frames = 0
        self.incomplete_down_frames = 0
        self.rep_frame_count = 0
        self.rep_depths.clear()
        self.rep_returns.clear()
        self.score = 0.0
        self.rep_start_time = 0
        self.rep_times.clear()
        self.rom_values.clear()
        self.detected_side = None
        self.measurement_data = {
            'rep_count': 0,
            'rom_angles': [],
            'speed_data': [],
            'consistency_score': 0,
            'fatigue_factor': 0,
            'technique_analysis': {
                'upper_body_engagement': 0,
                'core_activation': 0,
                'hip_flexor_dominance': 0
            }
        }