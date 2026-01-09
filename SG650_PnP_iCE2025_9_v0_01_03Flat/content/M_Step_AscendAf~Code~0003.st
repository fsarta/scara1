// METHOD: M_Step_AscendAfterPlace

// 1. Entry
IF NOT bStepInitialized THEN
    
    stMoveOption.VelocityUnit := 2;
    
    THIS.M_Driver_Motion_Cmd(
         ActualBlockMoveID, // iBlockID
         ActProdX_Place, // fX
         ActProdY_Place, // fY   
         0.0, // fZ
         0.0, // fRx
         0.0, // fRy
         0.0, // fRz
         DATA_Machine.Setting.MinVelocity_Delta, // fVel
         DATA_Machine.Setting.MinRamp_Delta, // fAcc
         DATA_Machine.Setting.MinRamp_Delta, // fDec
         MC_CoordinateSystem#PCS, // eCoordSys
         MC_BufferMode#BlendingPrevious, // eBufferMode
         MC_TransitionMode#TMStartVelocity, // eTransMode
         1, // param
         100.0, // eTransParam
         stMoveOption, // stMoveOption
         TRUE 
     );
    bStepInitialized := TRUE;
    M_Step_AscendAfterPlace := E_StepStatus#BUSY;
    RETURN;
END_IF;

// 2. Cyclic
M_Step_AscendAfterPlace := THIS.M_Driver_Motion_Check(ActualBlockMoveID);

// 3. Exit
IF M_Step_AscendAfterPlace = E_StepStatus#ACTIVE THEN
    DATA_Machine.Status.InSync_Delta := FALSE;

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
    
    TempPosConv := DATA_FeedOutAxis.Feedback.ActualPosition;

    M_Step_AscendAfterPlace := E_StepStatus#DONE;
END_IF;