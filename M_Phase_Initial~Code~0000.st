// Reset grippers
bActivateGripper1 := FALSE;
bActivateGripper2 := FALSE;

// Check Start Conditions
IF StartCycle AND (bAutoModeSelected OR NOT(bManualModeSelected)) THEN
    IDX_Prev_PickPlace_Delta := 0;
    CalcFrameOffset_Group.Enable := FALSE;

    // Latch commands
    iGripperForThisCycle := iGripperToUse;
    bDoubleModeForThisCycle := bDoubleMode;

    // Transition to Pick
    IDX_PickPlace_Delta := E_PickPlace_State#CheckPickLimits; // 100
END_IF;