"""
Angle Calculator - Utility functions for calculating angles
"""

import math
import numpy as np

def calculate_angle(a, b, c):
    """
    Calculate the angle between three points
    Points should be in format (x, y)
    """
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    
    ba = a - b
    bc = c - b
    
    if np.linalg.norm(ba) < 1e-6 or np.linalg.norm(bc) < 1e-6:
        return np.nan
        
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    cosine_angle = np.clip(cosine_angle, -1.0, 1.0)
    
    return math.degrees(math.acos(cosine_angle))

def calculate_slope(point1, point2):
    """
    Calculate slope between two points
    """
    if abs(point2[0] - point1[0]) < 1e-6:
        return float('inf')
    return (point2[1] - point1[1]) / (point2[0] - point1[0])