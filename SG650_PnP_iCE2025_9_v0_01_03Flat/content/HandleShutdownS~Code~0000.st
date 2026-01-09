(*
FUNCTION: State handler for SHUTDOWN state
DESCRIPTION: 
Final state that resets system to safe condition.
*)

// Final shutdown actions
DATA_Delta.Command.GroupControl.En_Group := FALSE;
DATA_Delta.Command.GroupControl.Enable := FALSE;

DATA_Delta.Command.En_EmergencyGroupStop := FALSE;
DATA_FeedInAxis.Command.EmergencyStop := FALSE;
DATA_FeedOutAxis.Command.EmergencyStop := FALSE;
DATA_VirtAxis.Command.EmergencyStop := FALSE;

// Return to idle when disabled or error detected
IF NOT(DATA_Delta.Status.GroupControl.GroupStatus) THEN
    NextState := E_MachineState#INIT;
    bTransition := TRUE;
    fbErrorHandler.LogEvent(0, 'FB_MachineControl - ShutdownState', 'System safely shutdown', E_ErrorSeverity#Info);
END_IF;