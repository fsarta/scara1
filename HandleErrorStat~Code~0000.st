(*
FUNCTION: State handler for ERROR state
DESCRIPTION: 
Implements error recovery mechanism with diagnostics.
*)

DATA_Delta.Command.GroupControl.En_Power        := FALSE;

DATA_Delta.Command.En_GroupJogJoint             := FALSE;
DATA_Delta.Command.En_GroupJogLinear            := FALSE;
DATA_Delta.Command.En_MoveLinearAbsolute        := FALSE;
DATA_Delta.Command.En_MoveLinearRelative        := FALSE;
DATA_Delta.Command.En_MoveLinearAbsolute_Blend1 := FALSE;
DATA_Delta.Command.En_MoveLinearAbsolute_Blend2 := FALSE;
DATA_Delta.Command.En_MoveLinearAbsolute_Blend3 := FALSE;

DATA_DELTA.Command.TestGroupBlend   := FALSE;

DATA_FeedInAxis.Command.Enable      := FALSE;
DATA_FeedOutAxis.Command.Enable     := FALSE;
DATA_VirtAxis.Command.Enable        := FALSE;

DATA_Delta.Command.GroupControl.AlarmClear := FALSE;
DATA_FeedInAxis.Command.ResetFault  := FALSE;
DATA_FeedOutAxis.Command.ResetFault := FALSE;

PowerUp := FALSE;

CycleControls.StartCycle := FALSE;
CycleControls.StopCycle := FALSE;

DATA_Axes.Command.AutoAxes.Start := FALSE;

// Return to IDLE on reset
IF G_bResetAllErrors THEN
    
    MovementAllowed := FALSE;

    NextState := E_MachineState#INIT;
    bTransition := TRUE;
    fbErrorHandler.LogEvent(0, 'FB_MachineControl - ErrorState', 'Error acknowledged, returning to INIT', E_ErrorSeverity#Info);
END_IF;
