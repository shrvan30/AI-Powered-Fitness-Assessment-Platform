"""
Utility functions for pose processing
"""

import math
import numpy as np
import cv2

import numpy as np

def distance_2d(point1, point2):
    """
    Calculate Euclidean distance between two 2D points
    
    Args:
        point1: Tuple (x1, y1)
        point2: Tuple (x2, y2)
    
    Returns:
        float: Euclidean distance between the points
    """
    return np.sqrt((point2[0] - point1[0])**2 + (point2[1] - point1[1])**2)

def angle_3pt(a, b, c):
    a = np.array(a, dtype=np.float64)
    b = np.array(b, dtype=np.float64)
    c = np.array(c, dtype=np.float64)
    ba = a - b
    bc = c - b
    if np.linalg.norm(ba) < 1e-6 or np.linalg.norm(bc) < 1e-6:
        return np.nan
    cosang = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    cosang = np.clip(cosang, -1.0, 1.0)
    return math.degrees(math.acos(cosang))

def lm_xy(landmark, w, h):
    return int(landmark.x * w), int(landmark.y * h)

def pick_side_visibility(landmarks):
    left_visibility = landmarks[11].visibility + landmarks[23].visibility + landmarks[25].visibility
    right_visibility = landmarks[12].visibility + landmarks[24].visibility + landmarks[26].visibility
    return 'L' if left_visibility >= right_visibility else 'R'

def draw_hud(frame, assessment, info_text=""):
    h, w = frame.shape[:2]
    
    # Draw semi-transparent overlay for HUD
    overlay = frame.copy()
    cv2.rectangle(overlay, (0, 0), (w, 100), (32, 32, 32), -1)
    cv2.rectangle(overlay, (0, h-100), (w, h), (32, 32, 32), -1)
    cv2.addWeighted(overlay, 0.7, frame, 0.3, 0, frame)
    
    # Draw current exercise info
    if assessment.current_exercise:
        ex = assessment.current_exercise
        cv2.putText(frame, f"Exercise: {ex.name}", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
        
        if hasattr(ex, 'ideal_reps') and ex.ideal_reps:
            cv2.putText(frame, f"Target: {ex.ideal_reps} reps", (10, 60), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        elif hasattr(ex, 'ideal_time') and ex.ideal_time:
            cv2.putText(frame, f"Target: {ex.ideal_time} seconds", (10, 60), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
    
    # Draw progress
    progress = f"Exercise {assessment.current_exercise_idx + 1} of {len(assessment.exercises)}"
    cv2.putText(frame, progress, (w - 250, 30), 
               cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
    
    # Draw instructions at the bottom
    cv2.putText(frame, "Press 'q' to quit, 'n' for next exercise, 's' to save results", 
               (10, h - 60), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
    
    # Draw info text if provided
    if info_text:
        cv2.putText(frame, info_text, (10, h - 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 1)