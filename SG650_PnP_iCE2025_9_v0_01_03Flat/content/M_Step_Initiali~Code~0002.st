// 1. Entry Action
IF NOT bStepInitialized THEN
    bActivateGripper1 := FALSE;
    bActivateGripper2 := FALSE;
    bStepInitialized := TRUE; // Mark as started
END_IF;

// 2. Main Logic
IF StartCycle AND (bAutoModeSelected OR NOT(bManualModeSelected)) THEN
    IDX_Prev_PickPlace_Delta := 0;
    CalcFrameOffset_Group.Enable := FALSE;
    
    iGripperForThisCycle := iGripperToUse; 
    bDoubleModeForThisCycle := bDoubleMode;
    
    TrackConveyorBelt_FeedOut.Execute := FALSE;
    TrackConveyorBelt_FeedIn.Execute := FALSE;
    
    GroupSetFrameOffset_FeedOut.Execute := FALSE;
    
    M_Step_Initialize := E_StepStatus#DONE; 
ELSE
    M_Step_Initialize := E_StepStatus#BUSY; 
END_IF