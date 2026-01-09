// METHOD: M_Step_InitParking

TrackConveyorBelt_FeedIn.Execute := FALSE;
TrackConveyorBelt_FeedOut.Execute := FALSE;

stMoveOption.VelocityUnit := 2;

THIS.M_Driver_Motion_Cmd(
        E_MotionChannel#Blend1,
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
    
THIS.M_Driver_Motion_Cmd(
        E_MotionChannel#Blend2,
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
    
THIS.M_Driver_Motion_Cmd(
        E_MotionChannel#Blend3,
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
    
THIS.M_Driver_Motion_Cmd(
        E_MotionChannel#Blend4,
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

bActivateGripper1 := FALSE;
bActivateGripper2 := FALSE;

M_Step_InitParking := E_StepStatus#DONE;