// METHOD: M_Step_AscendAfterPick
// DESCRIPTION: Raises Z-axis after picking.

// 1. Entry Action
IF NOT bStepInitialized THEN
    
    stMoveOption.VelocityUnit := 2;     
    
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
    M_Step_AscendAfterPick := E_StepStatus#BUSY;
    RETURN;
END_IF;

// 2. Cyclic Check
M_Step_AscendAfterPick := THIS.M_Driver_Motion_Check(ActualBlockMoveID);

// 3. Exit Logic
IF M_Step_AscendAfterPick = E_StepStatus#ACTIVE THEN
    DATA_Machine.Status.InSync_Delta := FALSE;
    
    // Clean previous
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
    
    M_Step_AscendAfterPick := E_StepStatus#DONE;
END_IF;