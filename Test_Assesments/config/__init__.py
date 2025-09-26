"""
Configuration package - Contains configuration constants
"""

# MediaPipe pose landmarks indices
POSE_LANDMARKS = {
    'NOSE': 0,
    'LEFT_SHOULDER': 11,
    'RIGHT_SHOULDER': 12,
    'LEFT_ELBOW': 13,
    'RIGHT_ELBOW': 14,
    'LEFT_WRIST': 15,
    'RIGHT_WRIST': 16,
    'LEFT_HIP': 23,
    'RIGHT_HIP': 24,
    'LEFT_KNEE': 25,
    'RIGHT_KNEE': 26,
    'LEFT_ANKLE': 27,
    'RIGHT_ANKLE': 28,
    'LEFT_HEEL': 29,
    'RIGHT_HEEL': 30,
    'LEFT_FOOT_INDEX': 31,
    'RIGHT_FOOT_INDEX': 32
}

# Exercise thresholds
SQUAT_DOWN_THRESH = 100.0
SQUAT_UP_THRESH = 160.0
PUSHUP_DOWN_THRESH = 90.0
PUSHUP_UP_THRESH = 160.0
SITUP_UP_THRESH = 80.0
SITUP_DOWN_THRESH = 150.0

# Visual settings
HUD_COLOR = (32, 32, 32)
TEXT_COLOR = (255, 255, 255)
SUCCESS_COLOR = (0, 255, 0)
ERROR_COLOR = (0, 0, 255)
WARNING_COLOR = (0, 255, 255)