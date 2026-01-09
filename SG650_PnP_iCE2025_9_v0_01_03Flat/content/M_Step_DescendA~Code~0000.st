// METHOD: M_Step_DescendAndPick
// DESCRIPTION: Lowers Z-axis to pick position and activates gripper.

// 1. Entry Action
IF NOT bStepInitialized THEN
    // Activate Gripper
    bActivateGripper1 := (iGripperForThisCycle = 0);
    bActivateGripper2 := (iGripperForThisCycle <> 0);
    
    stMoveOption.VelocityUnit := 2;

    // Command Motion    
    THIS.M_Driver_Motion_Cmd(
         ActualBlockMoveID, // iBlockID
         ActProdX_Pick, // fX
         ActProdY_Pick, // fY   
         DATA_Machine.Setting.Delta_Z_Pick, // fZ
         0.0, // fRx
         0.0, // fRy
         ActProdRZ_Pick, // fRz
         DATA_Machine.Setting.ZPickPlaceSpeed, // fVel
         DATA_Machine.Setting.MinRamp_Delta, // fAcc
         DATA_Machine.Setting.MinRamp_Delta, // fDec
         MC_CoordinateSystem#PCS, // eCoordSys
         MC_BufferMode#BlendingPrevious, // eBufferMode
         MC_TransitionMode#TMStartVelocity, // eTransMode
         1, // param
         100.0, // eTransParam
         stMoveOption, // stMoveOption
         TRUE // bExecute - Start Command
    );
    
    bStepInitialized := TRUE;
    M_Step_DescendAndPick := E_StepStatus#BUSY;
    RETURN;
END_IF;

// 2. Cyclic Check
M_Step_DescendAndPick := THIS.M_Driver_Motion_Check(ActualBlockMoveID);

// 3. Exit Logic: Capture Conveyor Position
IF M_Step_DescendAndPick = E_StepStatus#ACTIVE OR M_Step_DescendAndPick = E_StepStatus#DONE THEN
    
    // Reset previous motion command 
    THIS.M_Driver_Motion_Cmd(
        PreviousBlockMoveID, // iBlockID
        0.0, // fX
        0.0, // fY
        0.0, // fZ
        0.0, // fRx
        0.0, // fRy
        0.0, // fRz
        0.0, // fVel
        0.0, // fAcc
        0.0, // fDec
        MC_CoordinateSystem#PCS, // eCoordSys
        MC_BufferMode#BlendingPrevious, // eBufferMode
        MC_TransitionMode#TMStartVelocity, // eTransMode
        0, // param
        0.0, // eTransParam
        stMoveOption, // stMoveOption
        FALSE // bExecute
    ); 
    
    TempPosConv := DATA_FeedInAxis.Feedback.ActualPosition;
    
    M_Step_DescendAndPick := E_StepStatus#DONE;    
END_IF;