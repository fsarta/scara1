// METHOD: M_Step_SetPlaceOffsetAndPCS_Tracking

// 1. Entry
IF NOT bStepInitialized THEN
    GroupSetFrameOffset_FeedOut.Offset := PCS_Frame_FeedOut;
    GroupSetFrameOffset_FeedOut.ExecutionMode := MC_ExecutionMode#Immediately;
    GroupSetFrameOffset_FeedOut.RefCoordSystem := MC_CoordinateSystem#MCS;
    GroupSetFrameOffset_FeedOut.SetCoordSystem := MC_CoordinateSystem#PCS;
    GroupSetFrameOffset_FeedOut.Execute := TRUE;
    
    bStepInitialized := TRUE;
    M_Step_SetPlaceOffsetAndPCS_Tracking := E_StepStatus#BUSY;
    RETURN;
END_IF;

// 2. Cyclic
IF GroupSetFrameOffset_FeedOut.Done THEN
    GroupSetFrameOffset_FeedIn.Execute := FALSE;
    TrackConveyorBelt_FeedIn.Execute := FALSE;
    M_Step_SetPlaceOffsetAndPCS_Tracking := E_StepStatus#DONE;
ELSE
    M_Step_SetPlaceOffsetAndPCS_Tracking := E_StepStatus#BUSY;
END_IF;