// 1. Entry Action: Trigger Movement
IF NOT bStepInitialized THEN
    
    stMoveOption.VelocityUnit := 2;     
    
    // Call the Driver to Setup and Execute Block #1
    THIS.M_Driver_Motion_Cmd(
         ActualBlockMoveID, // iBlockID
         ActProdX_Pick, // fX
         ActProdY_Pick, // fY   
         0.0, // fZ
         0.0, // fRx
         0.0, // fRy
         ActProdRZ_Pick, // fRz
         DATA_Machine.Setting.MinVelocity_Delta, // fVel
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
    M_Step_ApproachPick_Tracking := E_StepStatus#BUSY;
    RETURN;
END_IF;

// 2. Cyclic Check: Ask the Driver for status of Block #1
M_Step_ApproachPick_Tracking := THIS.M_Driver_Motion_Check(ActualBlockMoveID);

// 3. Exit Cleanup (If needed)
IF M_Step_ApproachPick_Tracking = E_StepStatus#ACTIVE THEN
     // Reset the Execute flag for this block to be clean for next time
     THIS.M_Driver_Motion_Cmd(
        PreviousBlockMoveID,
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
        1, // param
        0.0, // eTransParam
        stMoveOption, // stMoveOption
        FALSE // bExecute
    ); 
    M_Step_ApproachPick_Tracking := E_StepStatus#DONE;
    
END_IF