(*
FUNCTION: State handler for UNPOWERING state
DESCRIPTION: 
Implements controlled power-down sequence.
*)

// Deactivate axes
DATA_Delta.Command.GroupControl.En_Power:= FALSE;
DATA_FeedInAxis.Command.Enable := FALSE;
DATA_FeedOutAxis.Command.Enable := FALSE;
DATA_VirtAxis.Command.Enable := FALSE;

// Monitor power-down completion
IF NOT(DATA_Delta.Status.GroupControl.PowerStatus) AND 
   NOT(DATA_FeedInAxis.Status.Enabled) AND 
   NOT(DATA_FeedOutAxis.Status.Enabled) AND 
   NOT(DATA_VirtAxis.Status.Enabled) THEN
    NextState := E_MachineState#SHUTDOWN;
    bTransition := TRUE;
    fbErrorHandler.LogEvent(0, 'FB_MachineControl - UnpoweringState', 'Power down completed, entering to SHUTDOWN mode.', E_ErrorSeverity#Info);
END_IF;