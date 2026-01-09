IF PickPlace_Status THEN
    PickPlace_Status := FALSE;
    IDX_PickPlace_Delta := 0;
    
    DATA_Group.Command.TestGroupBlend := FALSE;
            
    // Stop all FBs
    FrameTypeTransform_FeedIn.Execute := FALSE;
    FrameTypeTransform_FeedOut.Execute := FALSE;        
    MoveLinearAbsolute_Blend1.Execute := FALSE;
    MoveLinearAbsolute_Blend2.Execute := FALSE;
    MoveLinearAbsolute_Blend3.Execute := FALSE;
    MoveLinearAbsolute_Blend4.Execute := FALSE;
    TrackConveyorBelt_FeedIn.Execute := FALSE;
    TrackConveyorBelt_FeedOut.Execute := FALSE;
    CalcFrameOffset_Group.Enable := FALSE;
    GroupSetFrameOffset_FeedIn.Execute := FALSE;
    GroupSetFrameOffset_FeedOut.Execute := FALSE;
    
    // Reset Data
    stPickPlaceProductData_Pick[GroupNumber].UsePointer := 0;
    stPickPlaceProductData_Place[GroupNumber].UsePointer := 0;
    stPickPlaceProductData_Pick[GroupNumber].StorePointer := 0;
    stPickPlaceProductData_Place[GroupNumber].StorePointer := 0;
    
    StopCycleEnabled := FALSE;
    
    // Deactivate grippers
    bActivateGripper1 := FALSE;
    bActivateGripper2 := FALSE;
    
    PickPlace_Error := FALSE;
END_IF;