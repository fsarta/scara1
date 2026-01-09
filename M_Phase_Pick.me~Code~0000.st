CASE IDX_PickPlace_Delta OF

    // --- CHECK LIMITS ---
    E_PickPlace_State#CheckPickLimits: // 100
        IDX_Prev_PickPlace_Delta := 100;
        
        UsePointer_Pick := stPickPlaceProductData_Pick[GroupNumber].UsePointer;
        StorePointer_Pick := stPickPlaceProductData_Pick[GroupNumber].StorePointer;
        
        // Get Raw Coordinates
        ActProdX_Raw := stPickPlaceProductData_Pick[GroupNumber].ProductDetails[UsePointer_Pick].ProductPosition[1];
        ActProdY_Raw := stPickPlaceProductData_Pick[GroupNumber].ProductDetails[UsePointer_Pick].ProductPosition[2];
        ActProdRZ_Raw := stPickPlaceProductData_Pick[GroupNumber].ProductDetails[UsePointer_Pick].ProductPosition[6];
        
        // Validation Logic
        IF (ActProdX_Raw >= DATA_Machine.Setting.LimitPos[0].X_Limits[GroupNumber].PosMin) AND
           (ActProdX_Raw <= DATA_Machine.Setting.LimitPos[0].X_Limits[GroupNumber].PosMax) AND
           (ActProdY_Raw >= DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMin) AND
           (ActProdY_Raw <= DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMax) AND
           UsePointer_Pick <= StorePointer_Pick THEN
            
            IDX_PickPlace_Delta := E_PickPlace_State#CalculatePickGripperOffset; // 150
        ELSE
            PickPlace_Error := TRUE;
            IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
        END_IF;

    // --- CALCULATE OFFSET ---
    E_PickPlace_State#CalculatePickGripperOffset: // 150
        IDX_Prev_PickPlace_Delta := 150;
        
        IF iGripperForThisCycle = 0 THEN
            ActProdX_Pick := ActProdX_Raw + stGripper1_Offset[0];
            ActProdY_Pick := ActProdY_Raw + stGripper1_Offset[1];
        ELSE
            ActProdX_Pick := ActProdX_Raw + stGripper2_Offset[0];
            ActProdY_Pick := ActProdY_Raw + stGripper2_Offset[1];
        END_IF;
        ActProdRZ_Pick := ActProdRZ_Raw;
        
        IDX_PickPlace_Delta := E_PickPlace_State#SetPickFrame_Tracking; // 200

    // --- SET FRAME ---
    E_PickPlace_State#SetPickFrame_Tracking: // 200
        IDX_Prev_PickPlace_Delta := 200;
        
        // Copy Frame Data
        FrameTypeTransform_FeedIn.OO := Frame_FeedIn.OO;
        FrameTypeTransform_FeedIn.XX := Frame_FeedIn.XX;
        FrameTypeTransform_FeedIn.XY := Frame_FeedIn.XY;
        FrameTypeTransform_FeedIn.Execute := TRUE;
        
        IF FrameTypeTransform_FeedIn.Done THEN
            FrameTypeTransform_FeedOut.Execute := FALSE; 
            IDX_PickPlace_Delta := E_PickPlace_State#ConvertPickToCartesian_Tracking; // 300
        END_IF;

    // --- CONVERT TO CARTESIAN ---
    E_PickPlace_State#ConvertPickToCartesian_Tracking: // 300
        IDX_Prev_PickPlace_Delta := 300;
        VECTOR_TO_CARTESIANREF1(Vector := FrameTypeTransform_FeedIn.FrameCoordinates, CartesianRef => PCS_Frame_FeedIn);
        IDX_PickPlace_Delta := E_PickPlace_State#SetPickOffsetAndPCS_Tracking; // 350

    // --- SET OFFSET PCS ---
    E_PickPlace_State#SetPickOffsetAndPCS_Tracking: // 350
        IDX_Prev_PickPlace_Delta := 350;
        
        GroupSetFrameOffset_FeedIn.Offset := FeedIn_FrameOffset;
        GroupSetFrameOffset_FeedIn.ExecutionMode := MC_ExecutionMode#Immediately;
        GroupSetFrameOffset_FeedIn.RefCoordSystem := MC_CoordinateSystem#MCS;
        GroupSetFrameOffset_FeedIn.SetCoordSystem := MC_CoordinateSystem#PCS;
        GroupSetFrameOffset_FeedIn.Execute := TRUE;
        
        IF GroupSetFrameOffset_FeedIn.Done THEN
            GroupSetFrameOffset_FeedOut.Execute := FALSE;
            IDX_PickPlace_Delta := E_PickPlace_State#EnablePickTracking; // 400
        END_IF;

    // --- ENABLE TRACKING ---
    E_PickPlace_State#EnablePickTracking: // 400
        IDX_Prev_PickPlace_Delta := 400;
        
        TrackConveyorBelt_FeedIn.ConveyorBeltOrigin := FrameTypeTransform_FeedIn.FrameCoordinates;
        // ... (Other Tracking Configs kept same) ...
        TrackConveyorBelt_FeedIn.Execute := TRUE;
        
        IF TrackConveyorBelt_FeedIn.Active THEN
            IDX_PickPlace_Delta := E_PickPlace_State#ApproachPick_Tracking; // 500
        END_IF;
        IF TrackConveyorBelt_FeedIn.Error THEN
            IDX_PickPlace_Delta := E_PickPlace_State#Error;
        END_IF;

    // --- APPROACH PICK ---
    E_PickPlace_State#ApproachPick_Tracking: // 500
        IDX_Prev_PickPlace_Delta := 500;
        
        // Configure the movement to be ready to tracking the conveyor belt
		MoveLinearAbsolute_Blend1.Position[1] := ActProdX_Pick;
		MoveLinearAbsolute_Blend1.Position[2] := ActProdY_Pick;
		MoveLinearAbsolute_Blend1.Position[3] := 0.0;
		MoveLinearAbsolute_Blend1.Position[5] := 0.0; 
		MoveLinearAbsolute_Blend1.Position[6] := ActProdRZ_Pick;
		MoveLinearAbsolute_Blend1.Velocity := DATA_Machine.Setting.MinVelocity_Delta;
		MoveLinearAbsolute_Blend1.Acceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend1.Deceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend1.CoordSystem := MC_CoordinateSystem#PCS; (* INT#2 *)
		MoveLinearAbsolute_Blend1.BufferMode := MC_BufferMode#BlendingPrevious;
		MoveLinearAbsolute_Blend1.TransitionMode := MC_TransitionMode#TMStartVelocity;
		MoveLinearAbsolute_Blend1.TransitionParameter[1] := 100.0;
		MoveLinearAbsolute_Blend1.MoveOptions.VelocityUnit := 2;
        MoveLinearAbsolute_Blend1.Execute := TRUE;
        
        IF MoveLinearAbsolute_Blend1.Active THEN
            MoveLinearAbsolute_Blend4.Execute := FALSE;
            IDX_PickPlace_Delta := E_PickPlace_State#WaitForPickSync; // 600
        END_IF;
        
        IF MoveLinearAbsolute_Blend1.Error THEN IDX_PickPlace_Delta := E_PickPlace_State#Error; END_IF;

    // --- WAIT SYNC ---
    E_PickPlace_State#WaitForPickSync: // 600
        IDX_Prev_PickPlace_Delta := 600;
        IF TrackConveyorBelt_FeedIn.InSync THEN
            DATA_Machine.Status.InSync_Delta := TRUE;
            IDX_PickPlace_Delta := E_PickPlace_State#DescendAndPick; // 700
        END_IF;

    // --- DESCEND ---
    E_PickPlace_State#DescendAndPick: // 700
        IDX_Prev_PickPlace_Delta := 700;
        
        // Gripper Logic
        bActivateGripper1 := (iGripperForThisCycle = 0); // Activate gripper 1
        bActivateGripper2 := (iGripperForThisCycle <> 0); // Activate gripper 2
        
        // Configure the movement to be ready to lower the Z-axis
		MoveLinearAbsolute_Blend2.Position[1] := ActProdX_Pick;
		MoveLinearAbsolute_Blend2.Position[2] := ActProdY_Pick;
		MoveLinearAbsolute_Blend2.Position[3] := DATA_Machine.Setting.Delta_Z_Pick;
		MoveLinearAbsolute_Blend2.Position[5] := 0.0;
		MoveLinearAbsolute_Blend2.Position[6] := ActProdRZ_Pick;
		MoveLinearAbsolute_Blend2.Velocity := DATA_Machine.Setting.ZPickPlaceSpeed;
		MoveLinearAbsolute_Blend2.Acceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend2.Deceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend2.CoordSystem := MC_CoordinateSystem#PCS;
		MoveLinearAbsolute_Blend2.BufferMode := MC_BufferMode#BlendingPrevious;
		MoveLinearAbsolute_Blend2.TransitionMode := MC_TransitionMode#TMStartVelocity;
		MoveLinearAbsolute_Blend2.TransitionParameter[1] := 100.0;
		MoveLinearAbsolute_Blend2.MoveOptions.VelocityUnit := 2;
        MoveLinearAbsolute_Blend2.Execute := TRUE;
        
        IF MoveLinearAbsolute_Blend2.Active OR MoveLinearAbsolute_Blend2.Done THEN
            MoveLinearAbsolute_Blend1.Execute := FALSE;
            TempPosConv := DATA_FeedInAxis.Feedback.ActualPosition;
            IDX_PickPlace_Delta := E_PickPlace_State#WaitAfterPick_Tracking; // 750
        END_IF;
        
        IF MoveLinearAbsolute_Blend2.Error THEN IDX_PickPlace_Delta := E_PickPlace_State#Error; END_IF;

    // --- WAIT AFTER PICK ---
    E_PickPlace_State#WaitAfterPick_Tracking: // 750
        IDX_Prev_PickPlace_Delta := 750;
        IF (DATA_FeedInAxis.Feedback.ActualPosition - TempPosConv) >= 50.0 THEN
            IDX_PickPlace_Delta := E_PickPlace_State#AscendAfterPick; // 800
        END_IF;

    // --- ASCEND ---
    E_PickPlace_State#AscendAfterPick: // 800
        IDX_Prev_PickPlace_Delta := 800;
        
        // Configure the movement to be ready to raise the Z-axis
		MoveLinearAbsolute_Blend3.Position[1] := ActProdX_Pick;
		MoveLinearAbsolute_Blend3.Position[2] := ActProdY_Pick;
		MoveLinearAbsolute_Blend3.Position[3] := 0.0;
		MoveLinearAbsolute_Blend3.Position[5] := 0.0;
		MoveLinearAbsolute_Blend3.Position[6] := ActProdRZ_Pick;
		MoveLinearAbsolute_Blend3.Velocity := DATA_Machine.Setting.MinVelocity_Delta;
		MoveLinearAbsolute_Blend3.Acceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend3.Deceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend3.CoordSystem := MC_CoordinateSystem#PCS;
		MoveLinearAbsolute_Blend3.BufferMode := MC_BufferMode#BlendingPrevious;
		MoveLinearAbsolute_Blend3.TransitionMode := MC_TransitionMode#TMStartVelocity;
		MoveLinearAbsolute_Blend3.TransitionParameter[1] := 100.0;
		MoveLinearAbsolute_Blend3.MoveOptions.VelocityUnit := 2;
        MoveLinearAbsolute_Blend3.Execute := TRUE;
        
        IF MoveLinearAbsolute_Blend3.Active THEN
            DATA_Machine.Status.InSync_Delta := FALSE;
            MoveLinearAbsolute_Blend2.Execute := FALSE;
            IDX_PickPlace_Delta := E_PickPlace_State#MoveToParking_AfterPick; // 850
        END_IF;
        
        IF MoveLinearAbsolute_Blend3.Error THEN IDX_PickPlace_Delta := E_PickPlace_State#Error; END_IF;

    // --- PARKING AFTER PICK ---
    E_PickPlace_State#MoveToParking_AfterPick: // 850
        IDX_Prev_PickPlace_Delta := 850;
        
        // Configure the movement to be ready to raise the Z-axis
		MoveLinearAbsolute_Blend4.Position[1] := 150.0;
		MoveLinearAbsolute_Blend4.Position[2] := 290.0;
		MoveLinearAbsolute_Blend4.Position[3] := Frame_FeedOut.OO.Z;
		MoveLinearAbsolute_Blend4.Position[5] := 0.0; 
		MoveLinearAbsolute_Blend4.Position[6] := ActProdRZ_Pick;
		MoveLinearAbsolute_Blend4.Velocity := DATA_Machine.Setting.MinVelocity_Delta;
		MoveLinearAbsolute_Blend4.Acceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend4.Deceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend4.CoordSystem := MC_CoordinateSystem#MCS;
		MoveLinearAbsolute_Blend4.BufferMode := MC_BufferMode#BlendingPrevious;
		MoveLinearAbsolute_Blend4.TransitionMode := MC_TransitionMode#TMStartVelocity;
		MoveLinearAbsolute_Blend4.TransitionParameter[1] := 100.0;
		MoveLinearAbsolute_Blend4.MoveOptions.VelocityUnit := 2;
        MoveLinearAbsolute_Blend4.Execute := TRUE;
        
        IF MoveLinearAbsolute_Blend4.Active THEN
            DATA_Machine.Status.InSync_Delta := FALSE;
            MoveLinearAbsolute_Blend3.Execute := FALSE;
            IDX_PickPlace_Delta := E_PickPlace_State#SelectNextProduct_Pick; // 900
        END_IF;
        
        IF MoveLinearAbsolute_Blend4.Error THEN IDX_PickPlace_Delta := E_PickPlace_State#Error; END_IF;

    // --- SELECT NEXT PRODUCT ---
    E_PickPlace_State#SelectNextProduct_Pick: // 900
        IDX_Prev_PickPlace_Delta := 900;
        
        // Selection Logic
        IF UsePointer_Pick < (TO_INT(rDetectedProducts) - 1) THEN 
            iGroupNumber_Pick := GroupNumber;
            xiSelectNextProduct_Pick := TRUE;
            IF xoSelectNextProductDone_Pick THEN
                xiSelectNextProduct_Pick := FALSE;
            ELSIF xoSelectNextProductError_Pick THEN
                PickPlace_Error := TRUE;
                IDX_PickPlace_Delta := E_PickPlace_State#Error; 
            END_IF;
        ELSE 
            stPickPlaceProductData_Pick[GroupNumber].UsePointer := 0;
            bGoToNextPhase := TRUE;
        END_IF;  
        
        // Mode Check for Transition
        IF bDoubleModeForThisCycle THEN
            IF iGripperForThisCycle = 0 THEN
                IDX_PickPlace_Delta := E_PickPlace_State#Initialize; // Loop Back
            ELSE
                IDX_PickPlace_Delta := E_PickPlace_State#InitializePlace; // Go to Place
            END_IF;
        ELSE
            IDX_PickPlace_Delta := E_PickPlace_State#InitializePlace; // Go to Place
        END_IF;

END_CASE;