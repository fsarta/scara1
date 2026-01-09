CASE IDX_PickPlace_Delta OF

    E_PickPlace_State#InitializePlace: // 2000
        IDX_Prev_PickPlace_Delta := 2000;
        TrackConveyorBelt_FeedOut.Execute := FALSE;
        IDX_PickPlace_Delta := E_PickPlace_State#CheckPlaceLimits; // 2100

    E_PickPlace_State#CheckPlaceLimits: // 2100
        IDX_Prev_PickPlace_Delta := 2100;
        
        UsePointer_Place := stPickPlaceProductData_Place[GroupNumber].UsePointer;
        StorePointer_Place := stPickPlaceProductData_Place[GroupNumber].StorePointer;
        ActProdX_Place := stPickPlaceProductData_Place[GroupNumber].ProductDetails[UsePointer_Place].ProductPosition[1];
        ActProdY_Place := stPickPlaceProductData_Place[GroupNumber].ProductDetails[UsePointer_Place].ProductPosition[2];

        // Limit Check
        IF (ActProdX_Place > DATA_Machine.Setting.LimitPos[0].X_Limits[GroupNumber].PosMin) AND
           (ActProdX_Place < DATA_Machine.Setting.LimitPos[0].X_Limits[GroupNumber].PosMax) AND
           (ActProdY_Place > DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMin) AND
           (ActProdY_Place < DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMax) AND
           UsePointer_Place <= StorePointer_Place THEN
            
            IDX_PickPlace_Delta := E_PickPlace_State#SetPlaceFrame_Tracking; // 2200
        ELSE
            PickPlace_Error := TRUE;
            IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
        END_IF;

    E_PickPlace_State#SetPlaceFrame_Tracking: // 2200
        IDX_Prev_PickPlace_Delta := 2200;
        FrameTypeTransform_FeedOut.OO := Frame_FeedOut.OO; // (Simplified assignment for brevity)
        // ... Assign XX, XY ...
        FrameTypeTransform_FeedOut.Execute := TRUE;
        
        IF FrameTypeTransform_FeedOut.Done THEN
            FrameTypeTransform_FeedIn.Execute := FALSE;
            IDX_PickPlace_Delta := E_PickPlace_State#ConvertPlaceToCartesian_Tracking; // 2300
        END_IF;

    E_PickPlace_State#ConvertPlaceToCartesian_Tracking: // 2300
        IDX_Prev_PickPlace_Delta := 2300;
        VECTOR_TO_CARTESIANREF2(Vector := FrameTypeTransform_FeedOut.FrameCoordinates, CartesianRef => PCS_Frame_FeedOut);
        IDX_PickPlace_Delta := E_PickPlace_State#SetPlaceOffsetAndPCS_Tracking; // 2350

    E_PickPlace_State#SetPlaceOffsetAndPCS_Tracking: // 2350
        IDX_Prev_PickPlace_Delta := 2350;
        GroupSetFrameOffset_FeedOut.Offset := PCS_Frame_FeedOut;
        GroupSetFrameOffset_FeedOut.ExecutionMode := MC_ExecutionMode#Immediately;
        GroupSetFrameOffset_FeedOut.RefCoordSystem := MC_CoordinateSystem#MCS;
        GroupSetFrameOffset_FeedOut.SetCoordSystem := MC_CoordinateSystem#PCS;
        GroupSetFrameOffset_FeedOut.Execute := TRUE;
        
        IF GroupSetFrameOffset_FeedOut.Done THEN
            GroupSetFrameOffset_FeedIn.Execute := FALSE;
            TrackConveyorBelt_FeedIn.Execute := FALSE;
            IDX_PickPlace_Delta := E_PickPlace_State#EnablePlaceTracking; // 2400
        END_IF;

    E_PickPlace_State#EnablePlaceTracking: // 2400
        IDX_Prev_PickPlace_Delta := 2400;
        TrackConveyorBelt_FeedOut.ConveyorBeltOrigin := FrameTypeTransform_FeedOut.FrameCoordinates;
        // ... (Configs) ...
        TrackConveyorBelt_FeedOut.Execute := TRUE;
        
        IF TrackConveyorBelt_FeedOut.Active THEN
            IDX_PickPlace_Delta := E_PickPlace_State#ApproachPlace_Tracking; // 2500
        END_IF;
        IF TrackConveyorBelt_FeedOut.Error THEN IDX_PickPlace_Delta := E_PickPlace_State#Error; END_IF;

    E_PickPlace_State#ApproachPlace_Tracking: // 2500
        IDX_Prev_PickPlace_Delta := 2500;
        
        // Configure the movement to be ready to tracking the conveyor belt
		MoveLinearAbsolute_Blend1.Position[1] := ActProdX_Place;
		MoveLinearAbsolute_Blend1.Position[2] := ActProdY_Place;
		MoveLinearAbsolute_Blend1.Position[3] := 0.0;
		MoveLinearAbsolute_Blend1.Position[6] := 0.0;
		MoveLinearAbsolute_Blend1.Velocity := DATA_Machine.Setting.MinVelocity_Delta;
		MoveLinearAbsolute_Blend1.Acceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend1.Deceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend1.CoordSystem := MC_CoordinateSystem#PCS; (* INT#2 *)
		MoveLinearAbsolute_Blend1.BufferMode := MC_BufferMode#BlendingPrevious;
		MoveLinearAbsolute_Blend1.TransitionMode := MC_TransitionMode#TMStartVelocity;
		MoveLinearAbsolute_Blend1.TransitionParameter[1] := 100.0;
		MoveLinearAbsolute_Blend1.MoveOptions.VelocityUnit := 2;
		MoveLinearAbsolute_Blend1.Execute := TRUE;
        MoveLinearAbsolute_Blend1.Execute := TRUE;
        
        IF MoveLinearAbsolute_Blend1.Active THEN
            MoveLinearAbsolute_Blend4.Execute := FALSE;
            IDX_PickPlace_Delta := E_PickPlace_State#WaitForPlaceSync; // 2600
        END_IF;

    E_PickPlace_State#WaitForPlaceSync: // 2600
        IDX_Prev_PickPlace_Delta := 2600;
        IF TrackConveyorBelt_FeedOut.InSync THEN
            DATA_Machine.Status.InSync_Delta := TRUE;
            IDX_PickPlace_Delta := E_PickPlace_State#DescendAndPlace; // 2700
        END_IF;

    E_PickPlace_State#DescendAndPlace: // 2700
        IDX_Prev_PickPlace_Delta := 2700;
        
        // Configure the movement to be ready to lower the Z-axis
		MoveLinearAbsolute_Blend2.Position[1] := ActProdX_Place;
		MoveLinearAbsolute_Blend2.Position[2] := ActProdY_Place;
		MoveLinearAbsolute_Blend2.Position[3] := DATA_Machine.Setting.Delta_Z_Pick;
		MoveLinearAbsolute_Blend2.Position[5] := 90.0;
		MoveLinearAbsolute_Blend2.Position[6] := 0.0;
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
            TempPosConv := DATA_FeedOutAxis.Feedback.ActualPosition;
            IDX_PickPlace_Delta := E_PickPlace_State#WaitAfterPlace_Tracking; // 2750
        END_IF;

    E_PickPlace_State#WaitAfterPlace_Tracking: // 2750
        IDX_Prev_PickPlace_Delta := 2750;
        
        IF (DATA_FeedOutAxis.Feedback.ActualPosition - TempPosConv) >= 50.0 THEN
             bActivateGripper1 := FALSE;
             bActivateGripper2 := FALSE;
        END_IF;
        
        IF (DATA_FeedOutAxis.Feedback.ActualPosition - TempPosConv) >= 100.0 THEN
             IDX_PickPlace_Delta := E_PickPlace_State#AscendAfterPlace; // 2800
        END_IF;

    E_PickPlace_State#AscendAfterPlace: // 2800
        IDX_Prev_PickPlace_Delta := 2800;
        
        // Configure the movement to be ready to raise the Z-axis
		MoveLinearAbsolute_Blend3.Position[1] := ActProdX_Place;
		MoveLinearAbsolute_Blend3.Position[2] := ActProdY_Place;
		MoveLinearAbsolute_Blend3.Position[3] := 0.0;
		MoveLinearAbsolute_Blend2.Position[5] := 90.0;
		MoveLinearAbsolute_Blend3.Position[6] := 0.0;
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
            TempPosConv := DATA_FeedOutAxis.Feedback.ActualPosition;
            IDX_PickPlace_Delta := E_PickPlace_State#MoveToParking_AfterPlace; // 2850
        END_IF;

    E_PickPlace_State#MoveToParking_AfterPlace: // 2850
        IDX_Prev_PickPlace_Delta := 2850;
        
        // Configure the movement to be ready to raise the Z-axis
		MoveLinearAbsolute_Blend4.Position[1] := 150.0;
		MoveLinearAbsolute_Blend4.Position[2] := 290.0;
		MoveLinearAbsolute_Blend4.Position[3] := Frame_FeedOut.OO.Z;
		MoveLinearAbsolute_Blend2.Position[5] := 0.0;
		MoveLinearAbsolute_Blend4.Position[6] := 0.0;
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
            IDX_PickPlace_Delta := E_PickPlace_State#CycleCompletitionAndChangeMode; // 2900
        END_IF;

    E_PickPlace_State#CycleCompletitionAndChangeMode: // 2900
        IDX_Prev_PickPlace_Delta := 2900;
        bPlaceCycleComplete := TRUE;
        
        IF StopCycleEnabled THEN
             IDX_PickPlace_Delta := E_PickPlace_State#InitializeFinalParking; // 3000
        ELSE
             IDX_PickPlace_Delta := 0; // Restart
        END_IF;

END_CASE;