"""
Assessment Runner - Handles the exercise execution loop
"""

import cv2
import time
from utils.pose_utils import draw_hud

def run_exercises(assessment, args):
    cap = cv2.VideoCapture(args.camera)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)

    if not cap.isOpened():
        raise SystemExit("Could not open webcam.")

    
    import mediapipe as mp
    mp_pose = mp.solutions.pose
    mp_drawing = mp.solutions.drawing_utils
    mp_drawing_styles = mp.solutions.drawing_styles

    with mp_pose.Pose(
        model_complexity=1,
        enable_segmentation=False,
        smooth_landmarks=True,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5) as pose:
        
        info_text = "Position yourself in the frame"
        assessment.next_exercise()  # Start with the first exercise
        
        print(f"\nStarting exercise: {assessment.current_exercise.name}")
        print("Make sure you're fully visible in the camera")
        print("Press 'n' when done with this exercise")
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
                
            frame = cv2.flip(frame, 1)
            h, w = frame.shape[:2]
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            res = pose.process(rgb)
            
            current_ex = assessment.current_exercise
            
            if res.pose_landmarks:
                # Always draw skeleton if show_skeleton is enabled
                if args.show_skeleton:
                    mp_drawing.draw_landmarks(
                        frame, res.pose_landmarks, mp_pose.POSE_CONNECTIONS,
                        landmark_drawing_spec=mp_drawing_styles.get_default_pose_landmarks_style())
                
                # Update current exercise
                if current_ex:
                    current_ex.update(res.pose_landmarks.landmark, w, h)
                    current_ex.draw_feedback(frame, res.pose_landmarks.landmark, w, h)
            
            # Draw HUD with more information
            draw_hud(frame, assessment, info_text)
            
            # Add real-time feedback
            if current_ex:
                if hasattr(current_ex, 'reps'):
                    feedback_text = f"Reps: {current_ex.reps}"
                    if hasattr(current_ex, 'form_errors'):
                        feedback_text += f" | Form errors: {current_ex.form_errors}"
                    cv2.putText(frame, feedback_text, (10, h - 90), 
                               cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            
            # Show frame
            cv2.imshow("Fitness Assessment", frame)
            
            # Process key presses
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('n'):
                # Generate feedback for completed exercise
                if current_ex and hasattr(current_ex, 'generate_feedback'):
                    feedback = current_ex.generate_feedback()
                    print(f"\n{feedback}")
                
                # Move to next exercise or finish
                if not assessment.next_exercise():
                    info_text = "Assessment complete! Closing in 3 seconds..."
                    cv2.imshow("Fitness Assessment", frame)
                    cv2.waitKey(3000)
                    break
                else:
                    info_text = f"Starting {assessment.current_exercise.name}..."
                    print(f"\nStarting exercise: {assessment.current_exercise.name}")
                    time.sleep(1)
                    info_text = ""
            elif key == ord('s'):
                # Save results
                from utils.results_manager import save_assessment_results
                success, msg = save_assessment_results(assessment.exercises)
                info_text = msg
                time.sleep(2)
                info_text = ""
            elif key == ord('d'):  # Debug key
                if current_ex:
                    print(f"Debug: {current_ex.name} - Reps: {current_ex.reps}, Errors: {current_ex.form_errors}")
    
    cap.release()
    cv2.destroyAllWindows()