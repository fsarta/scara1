// METHOD: M_Step_SetPlaceFrame_Tracking
// DESCRIPTION: Transforms the FeedOut Frame.

// 1. Entry
IF NOT bStepInitialized THEN
    FrameTypeTransform_FeedOut.OO := Frame_FeedOut.OO;
    FrameTypeTransform_FeedOut.XX := Frame_FeedOut.XX;
    FrameTypeTransform_FeedOut.XY := Frame_FeedOut.XY;
    FrameTypeTransform_FeedOut.Execute := TRUE;
    
    bStepInitialized := TRUE;
    M_Step_SetPlaceFrame_Tracking := E_StepStatus#BUSY;
    RETURN;
END_IF;

// 2. Cyclic
IF FrameTypeTransform_FeedOut.Done THEN
    FrameTypeTransform_FeedIn.Execute := FALSE;
    M_Step_SetPlaceFrame_Tracking := E_StepStatus#DONE;
ELSE
    M_Step_SetPlaceFrame_Tracking := E_StepStatus#BUSY;
END_IF;