(*
FUNCTION: State handler for STOPPING state
DESCRIPTION: 
Implements safe stop sequence with error handling.
*)

bServoError_Stopping := NOT(S_Axis.Status.ServoOn AND L_Axis.Status.ServoOn AND U_Axis.Status.ServoOn AND 
                   T_Axis.Status.ServoOn AND FeedIn_Axis.Status.ServoOn AND FeedOut_Axis.Status.ServoOn);
                   
//fbErrorHandler.AddUpdateError(NOT(S_Axis.Status.ServoOn), 0, 'FB_MachineControl - StoppingState', 'S Axis Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(L_Axis.Status.ServoOn), 0, 'FB_MachineControl - StoppingState', 'L Axis Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(U_Axis.Status.ServoOn), 0, 'FB_MachineControl - StoppingState', 'U Axis Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(T_Axis.Status.ServoOn), 0, 'FB_MachineControl - StoppingState', 'T Axis Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(FeedIn_Axis.Status.ServoOn), 0, 'FB_MachineControl - StoppingState', 'CI Axis (Infeed) Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(FeedOut_Axis.Status.ServoOn), 0, 'FB_MachineControl - StoppingState', 'CO Axis (Outfeed) Servo is not ON (SVON).', E_ErrorSeverity#MajorError);                   


IF bServoError_Stopping THEN
    NextState := E_MachineState#ERROR;
    bTransition := TRUE;
    //fbErrorHandler.AddUpdateError(TRUE, 0, 'FB_MachineControl - StoppingState', 'Error/Alarm', E_ErrorSeverity#MajorError); 
END_IF;

// Activate group stop
DATA_Delta.Command.En_EmergencyGroupStop := TRUE;

DATA_FeedInAxis.Command.EmergencyStop := TRUE;
DATA_FeedOutAxis.Command.EmergencyStop := TRUE;
DATA_VirtAxis.Command.EmergencyStop := TRUE;

// Monitor stop completion
IF DATA_Delta.Status.EmergencyGroupStop.Done THEN
    NextState := E_MachineState#UNPOWERING;
    bTransition := TRUE;
    fbErrorHandler.LogEvent(0, 'FB_MachineControl - StoppingState', 'Movement stopped successfully, entering to UNPOWERING mode.', E_ErrorSeverity#Info);
//ELSIF G_stOverallErrorStatus.bAnyErrorActive THEN
//    NextState := E_MachineState#ERROR;
//    bTransition := TRUE;
//    fbErrorHandler.AddUpdateError(TRUE, 0, 'FB_MachineControl - StoppingState', 'Movement stop failed', E_ErrorSeverity#MajorError);
END_IF;