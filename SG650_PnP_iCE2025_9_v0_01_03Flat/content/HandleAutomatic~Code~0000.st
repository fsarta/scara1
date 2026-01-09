(*
FUNCTION: State handler for OPERATIONAL_AUTOMATIC state
DESCRIPTION: 
Implements automatic mode logic with motion control and safety monitoring.
*)


bServoError_Automatic := NOT(S_Axis.Status.ServoOn AND L_Axis.Status.ServoOn AND U_Axis.Status.ServoOn AND 
                   T_Axis.Status.ServoOn AND FeedIn_Axis.Status.ServoOn AND FeedOut_Axis.Status.ServoOn);
                   
//fbErrorHandler.AddUpdateError(NOT(S_Axis.Status.ServoOn), 0, 'FB_MachineControl - AutomaticState', 'S Axis Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(L_Axis.Status.ServoOn), 0, 'FB_MachineControl - AutomaticState', 'L Axis Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(U_Axis.Status.ServoOn), 0, 'FB_MachineControl - AutomaticState', 'U Axis Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(T_Axis.Status.ServoOn), 0, 'FB_MachineControl - AutomaticState', 'T Axis Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(B_Axis.Status.ServoOn), 0, 'FB_MachineControl - AutomaticState', 'B Axis Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(FeedIn_Axis.Status.ServoOn), 0, 'FB_MachineControl - AutomaticState', 'CI Axis (Infeed) Servo is not ON (SVON).', E_ErrorSeverity#MajorError);
//fbErrorHandler.AddUpdateError(NOT(FeedOut_Axis.Status.ServoOn), 0, 'FB_MachineControl - AutomaticState', 'CO Axis (Outfeed) Servo is not ON (SVON).', E_ErrorSeverity#MajorError);                   

IF bServoError_Automatic THEN
    NextState := E_MachineState#ERROR;
    bTransition := TRUE;
    //fbErrorHandler.AddUpdateError(TRUE, 0, 'FB_MachineControl - AutomaticState', 'Error/Alarm', E_ErrorSeverity#MajorError); 
    RETURN;   
END_IF;

// Enable automatic movement
MovementAllowed := TRUE;

// Monitor for stop conditions
IF E_Stop OR PowerDown THEN
    NextState := E_MachineState#STOPPING;
    PowerDown := FALSE;
    bTransition := TRUE;
    fbErrorHandler.LogEvent(0, 'FB_MachineControl - AutomaticState', 'Emergency stop or manual power down, entering STOPPING mode', E_ErrorSeverity#Warning);
ELSIF NOT(bAutoModeSelected) AND bManualModeSelected AND Safety_Button THEN
    NextState := E_MachineState#OPERATIONAL_MANUAL;
    bTransition := TRUE;
    fbErrorHandler.LogEvent(0, 'FB_MachineControl - AutomaticState', 'Entering to MANUAL mode', E_ErrorSeverity#Info);
END_IF;