CASE IDX_PickPlace_Delta OF

    E_PickPlace_State#InitializeFinalParking: // 3000
        IDX_Prev_PickPlace_Delta := 3000;
        
        // Stop all executions
        TrackConveyorBelt_FeedIn.Execute := FALSE;
        TrackConveyorBelt_FeedOut.Execute := FALSE;
        MoveLinearAbsolute_Blend1.Execute := FALSE;
        MoveLinearAbsolute_Blend2.Execute := FALSE;
        MoveLinearAbsolute_Blend3.Execute := FALSE;
        MoveLinearAbsolute_Blend4.Execute := FALSE;
        
        bActivateGripper1 := FALSE;
        bActivateGripper2 := FALSE;
        
        IDX_PickPlace_Delta := E_PickPlace_State#MoveToParking_SafePosition; // 3100

    E_PickPlace_State#MoveToParking_SafePosition: // 3100
        IDX_Prev_PickPlace_Delta := 3100;
        
        // Setup final move with Aborting buffer mode
        // Configure movement to final parking position (puoi modificare le coordinate secondo le tue esigenze)
		MoveLinearAbsolute_Blend4.Position[1] := 150.0;  // X parking position
		MoveLinearAbsolute_Blend4.Position[2] := 290.0;  // Y parking position  
		MoveLinearAbsolute_Blend4.Position[3] := Frame_FeedOut.OO.Z;  // Z parking position
		MoveLinearAbsolute_Blend2.Position[5] := 0.0;
		MoveLinearAbsolute_Blend4.Position[6] := 0.0;    // Rotation
		MoveLinearAbsolute_Blend4.Velocity := DATA_Machine.Setting.MinVelocity_Delta;
		MoveLinearAbsolute_Blend4.Acceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend4.Deceleration := DATA_Machine.Setting.MinRamp_Delta;
		MoveLinearAbsolute_Blend4.CoordSystem := MC_CoordinateSystem#MCS; // Use Machine Coordinate System
		MoveLinearAbsolute_Blend4.BufferMode := MC_BufferMode#Aborting;   // Abort any previous movement
		MoveLinearAbsolute_Blend4.MoveOptions.VelocityUnit := 2;
        MoveLinearAbsolute_Blend4.Execute := TRUE;
        
        IF MoveLinearAbsolute_Blend4.Done THEN
            MoveLinearAbsolute_Blend4.Execute := FALSE;
            IDX_PickPlace_Delta := E_PickPlace_State#FinalParkingCompletition; // 3200
        END_IF;
        
        IF MoveLinearAbsolute_Blend4.Error THEN IDX_PickPlace_Delta := E_PickPlace_State#Error; END_IF;

    E_PickPlace_State#FinalParkingCompletition: // 3200
        IDX_Prev_PickPlace_Delta := 3200;
        
        // Clean up
        FrameTypeTransform_FeedIn.Execute := FALSE;
        FrameTypeTransform_FeedOut.Execute := FALSE;
        CalcFrameOffset_Group.Enable := FALSE;
        GroupSetFrameOffset_FeedIn.Execute := FALSE;
        GroupSetFrameOffset_FeedOut.Execute := FALSE;
        
        IDX_PickPlace_Delta := 0; // Ready for restart

END_CASE;