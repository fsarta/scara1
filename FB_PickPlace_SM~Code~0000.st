(* -------- START OF FB_PickPlace_SM IMPLEMENTATION -------- *)

// 1. Call Error Handler (passed as IN_OUT)
//fbErrorHandler(bResetErrors := bResetAllErrors, bAcknowledgeErrors := bAcknowledgeAllErrors);

// 2. Set default status outputs
bSM_isIdle := (IDX_PickPlace_Delta = E_PickPlace_State#Initialize); // TRUE only if in state 0
bPlaceCycleComplete := FALSE; // Default to FALSE, will be set TRUE for one scan in state 2900
DATA_Machine.Status.InSync_Delta := TrackConveyorBelt_FeedIn.InSync OR TrackConveyorBelt_FeedOut.InSync;

// 3. Update local velocity settings
IF RobotJog.Fast_Speed THEN
    DATA_Machine.Setting.MinVelocity_Delta := 1200.0;
ELSIF RobotJog.Medium_Speed THEN
    DATA_Machine.Setting.MinVelocity_Delta := 500.0;
ELSIF RobotJog.Slow_Speed THEN
    DATA_Machine.Setting.MinVelocity_Delta := 300.0;
END_IF;

// 4. Call external function block for distribution
FB_Distribution1();

// 5. Initialize group and conveyor numbers
GroupNumber := INT#0;
ConveyorNumber := INT#0;

// 6. The state machine for Pick AND Place is activated by 'StartPickPlace_Delta' flag
IF StartPickPlace THEN
    PickPlace_Status := TRUE;
    
    CASE IDX_PickPlace_Delta of
        
(**********************************************************************************************)
(*                                           PICK                                             *)
(**********************************************************************************************)
        
        E_PickPlace_State#Initialize: // 0        // Initialize variables
            // Reset grippers command
            bActivateGripper1 := FALSE;
            bActivateGripper2 := FALSE;
            
            // Check the StartCycle input from the Manager
            IF StartCycle AND (bAutoModeSelected OR NOT(bManualModeSelected)) THEN
                               
                IDX_Prev_PickPlace_Delta := 0;
                CalcFrameOffset_Group.Enable := FALSE;        
                
                // Latch all commands from the Manager for this cycle
                iGripperForThisCycle := iGripperToUse; 
                bDoubleModeForThisCycle := bDoubleMode; // Latch the mode
                                
                // Go to the next state
                IDX_PickPlace_Delta := E_PickPlace_State#CheckPickLimits; // 100
            END_IF;


        E_PickPlace_State#CheckPickLimits: // 100    // Check for mission availability and verify if elements are within X and Y limits
            IDX_Prev_PickPlace_Delta := 100;
            
            UsePointer_Pick := stPickPlaceProductData_Pick[GroupNumber].UsePointer;
            StorePointer_Pick := stPickPlaceProductData_Pick[GroupNumber].StorePointer;
            
            // Store raw coordinates from vision
            ActProdX_Raw := stPickPlaceProductData_Pick[GroupNumber].ProductDetails[UsePointer_Pick].ProductPosition[1];
            ActProdY_Raw := stPickPlaceProductData_Pick[GroupNumber].ProductDetails[UsePointer_Pick].ProductPosition[2];
            ActProdRZ_Raw := stPickPlaceProductData_Pick[GroupNumber].ProductDetails[UsePointer_Pick].ProductPosition[6];
            
            // Check limits on raw coordinates 
            IF (ActProdX_Raw >= DATA_Machine.Setting.LimitPos[0].X_Limits[GroupNumber].PosMin) AND
                (ActProdX_Raw <= DATA_Machine.Setting.LimitPos[0].X_Limits[GroupNumber].PosMax) AND
                (ActProdY_Raw >= DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMin) AND
                (ActProdY_Raw <= DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMax) AND
                UsePointer_Pick <= StorePointer_Pick THEN
                
                // Go to new state for offset calculation
                IDX_PickPlace_Delta := E_PickPlace_State#CalculatePickGripperOffset; // 150
            ELSE
                PickPlace_Error := TRUE; // ERROR
                IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
            END_IF;

        E_PickPlace_State#CalculatePickGripperOffset: // 150    // Apply gripper offset to raw coordinates
            IDX_Prev_PickPlace_Delta := 150;
            
            // Apply the offset based on the gripper latched for this cycle
            IF iGripperForThisCycle = 0 THEN
                // Use Gripper 1 Offset 
                ActProdX_Pick := ActProdX_Raw + stGripper1_Offset[0]; // [0] = X
                ActProdY_Pick := ActProdY_Raw + stGripper1_Offset[1]; // [1] = Y
            ELSE
                // Use Gripper 2 Offset (iGripperForThisCycle = 1)
                ActProdX_Pick := ActProdX_Raw + stGripper2_Offset[0];
                ActProdY_Pick := ActProdY_Raw + stGripper2_Offset[1];
            END_IF;
            
            ActProdRZ_Pick := ActProdRZ_Raw; // Rotation remains the same
            
            IDX_PickPlace_Delta := E_PickPlace_State#SetPickFrame_Tracking; // 200    

		E_PickPlace_State#SetPickFrame_Tracking: // 200	// Set frame for pick
			IDX_Prev_PickPlace_Delta := 200;
			
		    // Set the origin (OO) and orientation (XX, XY) of the frame transformation from Frame_FeedIn
			FrameTypeTransform_FeedIn.OO.X := Frame_FeedIn.OO.X;
			FrameTypeTransform_FeedIn.OO.Y := Frame_FeedIn.OO.Y;
			FrameTypeTransform_FeedIn.OO.Z := Frame_FeedIn.OO.Z;
			FrameTypeTransform_FeedIn.XX.X := Frame_FeedIn.XX.X;
			FrameTypeTransform_FeedIn.XX.Y := Frame_FeedIn.XX.Y;
			FrameTypeTransform_FeedIn.XX.Z := Frame_FeedIn.XX.Z;
			FrameTypeTransform_FeedIn.XY.X := Frame_FeedIn.XY.X;
			FrameTypeTransform_FeedIn.XY.Y := Frame_FeedIn.XY.Y;
			FrameTypeTransform_FeedIn.XY.Z := Frame_FeedIn.XY.Z;
			
		    FrameTypeTransform_FeedIn.Execute := TRUE;
			
			IF FrameTypeTransform_FeedIn.Done THEN			    
			    FrameTypeTransform_FeedOut.Execute := FALSE; // Ensure the second frame transformation is deactivated
				
				// If the frame transformation is done, go to the next state
				IDX_PickPlace_Delta := E_PickPlace_State#ConvertPickToCartesian_Tracking; // 300
			END_IF;

		E_PickPlace_State#ConvertPickToCartesian_Tracking: // 300	// Convert the transformed frame coordinates into a Cartesian reference for PCS
			IDX_Prev_PickPlace_Delta := 300;
            VECTOR_TO_CARTESIANREF1(Vector := FrameTypeTransform_FeedIn.FrameCoordinates, CartesianRef => PCS_Frame_FeedIn);

			// Go to the next state          
			IDX_PickPlace_Delta := E_PickPlace_State#SetPickOffsetAndPCS_Tracking; // 350

		E_PickPlace_State#SetPickOffsetAndPCS_Tracking: //350 	// Sets an offset between the Coordinate Systems MCS and PCS
			IDX_Prev_PickPlace_Delta := 350;
			
			// Configure and execute the GroupSetFrameOffset function block to set the PCS frame
			GroupSetFrameOffset_FeedIn.Offset := FeedIn_FrameOffset;
			GroupSetFrameOffset_FeedIn.ExecutionMode := MC_ExecutionMode#Immediately;
			GroupSetFrameOffset_FeedIn.RefCoordSystem := MC_CoordinateSystem#MCS;
			GroupSetFrameOffset_FeedIn.SetCoordSystem := MC_CoordinateSystem#PCS;
			GroupSetFrameOffset_FeedIn.Execute := TRUE;
			IF GroupSetFrameOffset_FeedIn.Done THEN 
               GroupSetFrameOffset_FeedOut.Execute := FALSE;
               
               // Go to the next state
			   IDX_PickPlace_Delta := E_PickPlace_State#EnablePickTracking; // 400
            END_IF       
			
		E_PickPlace_State#EnablePickTracking: // 400	// Enable Conveyor Tracking
			IDX_Prev_PickPlace_Delta := 400;
			
			// Configure the conveyor tracking function block
			TrackConveyorBelt_FeedIn.ConveyorBeltOrigin := FrameTypeTransform_FeedIn.FrameCoordinates;
			TrackConveyorBelt_FeedIn.InitialObjectPosition[1] := 0.0; // Initial object position, x-coordinate
			TrackConveyorBelt_FeedIn.InitialObjectPosition[2] := 0.0; // Initial object position, y-coordinate
			TrackConveyorBelt_FeedIn.InitialObjectPosition[3] := 0.0; // Initial object position, z-coordinate
			// Configure synchronization options for tracking
			TrackConveyorBelt_FeedIn.TrackOptions.SyncIn.Mode := Yt_TrackProfileMode#MasterDistance;
			TrackConveyorBelt_FeedIn.TrackOptions.SyncIn.ConveyorDistance := 30.0; // Defines the distance traveled by conveyor during SyncIn
			TrackConveyorBelt_FeedIn.TrackOptions.SyncIn.TCPDistance := TrackConveyorBelt_FeedIn.TrackOptions.SyncIn.ConveyorDistance / 2.0; // Defines the distance the TCP travels during SyncIn
			TrackConveyorBelt_FeedIn.TrackOptions.SyncOut.ConveyorDistance := 60.0;
						
			// Select the conveyor belt axis and tracking distances based on the active mode
		    TrackConveyorBelt_FeedIn.ConveyorBelt := FeedInRef;
			TrackConveyorBelt_FeedIn.StartDistance := 10.0; // Start tracking distance on the conveyor
		    TrackConveyorBelt_FeedIn.EndDistance := 265.0; // End tracking distance on the conveyor
			TrackConveyorBelt_FeedIn.RecordedPosition := 17.0; // Use the actual linear axis position as the recorded position
            
			TrackConveyorBelt_FeedIn.Execute := TRUE;
			
		    // If conveyor tracking is active, go to the next state
			IF TrackConveyorBelt_FeedIn.Active THEN
				IDX_PickPlace_Delta := E_PickPlace_State#ApproachPick_Tracking; // 500
			END_IF;
			
			// If there's an error with conveyor tracking, go to the error state
			IF TrackConveyorBelt_FeedIn.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;

		E_PickPlace_State#ApproachPick_Tracking: // 500	// Approach to Pick position
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
			
			// If the movement is active, go to the next state
			IF MoveLinearAbsolute_Blend1.Active THEN
				MoveLinearAbsolute_Blend4.Execute := FALSE;			    
				IDX_PickPlace_Delta := E_PickPlace_State#WaitForPickSync; // 600
			END_IF;	
			
			// If there's an error with movement, go to the error state
			IF MoveLinearAbsolute_Blend1.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;

		E_PickPlace_State#WaitForPickSync: // 600	// Pick when in sync and mission tagged
			IDX_Prev_PickPlace_Delta := 600;
			
			// If the conveyor tracking is in sync, go to the next state
			IF TrackConveyorBelt_FeedIn.InSync THEN	
				DATA_Machine.Status.InSync_Delta := TRUE;
				IDX_PickPlace_Delta := E_PickPlace_State#DescendAndPick; // 700
			END_IF;

        E_PickPlace_State#DescendAndPick: // 700    // Activate gripper and bring robot to position
            IDX_Prev_PickPlace_Delta := 700;
            
            // Activate the correct gripper
            IF iGripperForThisCycle = 0 THEN
                bActivateGripper1 := TRUE; // Activate gripper 1
                bActivateGripper2 := FALSE;
            ELSE
                bActivateGripper1 := FALSE;
                bActivateGripper2 := TRUE; // Activate gripper 2
            END_IF;
            
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
			MoveLinearAbsolute_Blend2.Execute:= TRUE;
			
			// If the movement is active, go to the next state			
			IF MoveLinearAbsolute_Blend2.Active OR MoveLinearAbsolute_Blend2.Done THEN
				MoveLinearAbsolute_Blend1.Execute := FALSE; // Ensure movement1 is deactivated
				// Store the current conveyor position based on the active mode
                TempPosConv := DATA_FeedInAxis.Feedback.ActualPosition;
                                
				IDX_PickPlace_Delta := E_PickPlace_State#WaitAfterPick_Tracking; // 750
			END_IF;	
			
			// If there's an error with movement, go to the error state
			IF MoveLinearAbsolute_Blend2.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;
			
		E_PickPlace_State#WaitAfterPick_Tracking: // 750	// Stay in sync before raising Z
			IDX_Prev_PickPlace_Delta := 750;

            // Wait for the conveyor to move a certain distance after picking, depending on the active mode
			IF (DATA_FeedInAxis.Feedback.ActualPosition - TempPosConv) >= 50.0 THEN
                IDX_PickPlace_Delta := E_PickPlace_State#AscendAfterPick; // 800
            END_IF;
			
		E_PickPlace_State#AscendAfterPick: // 800	// Raise the Z-axis
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
			
			// If the movement is active, go to the next state	
			IF MoveLinearAbsolute_Blend3.Active THEN
				DATA_Machine.Status.InSync_Delta := FALSE; // Reset the in-sync status
				MoveLinearAbsolute_Blend2.Execute := FALSE; // Ensure movement2 is deactivated
				IDX_PickPlace_Delta := E_PickPlace_State#MoveToParking_AfterPick; // 850
			END_IF;	
			
			// If there's an error with movement, go to the error state
			IF MoveLinearAbsolute_Blend3.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;
			
		E_PickPlace_State#MoveToParking_AfterPick: // 850	// Go to the parking point
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
			
			// If the movement is active, go to the next state	
			IF MoveLinearAbsolute_Blend4.Active THEN
				DATA_Machine.Status.InSync_Delta := FALSE; // Reset the in-sync status
				MoveLinearAbsolute_Blend3.Execute := FALSE; // Ensure movement2 is deactivated
				IDX_PickPlace_Delta := E_PickPlace_State#SelectNextProduct_Pick; // 900
			END_IF;	
			
			// If there's an error with movement, go to the error state
			IF MoveLinearAbsolute_Blend4.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;
			
        E_PickPlace_State#SelectNextProduct_Pick: // 900    // Select Next Product
            IDX_Prev_PickPlace_Delta := 900;
            
            // ... (Your logic for UsePointer_Pick and xiSelectNextProduct_Pick) ...
            IF UsePointer_Pick < (TO_INT(rDetectedProducts) - 1) THEN 
                iGroupNumber_Pick := GroupNumber;
                xiSelectNextProduct_Pick := TRUE;
                IF xoSelectNextProductDone_Pick THEN
                    xiSelectNextProduct_Pick := FALSE;
                ELSIF xoSelectNextProductError_Pick THEN
                    PickPlace_Error := TRUE;
                    IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
                END_IF;
            ELSE 
                stPickPlaceProductData_Pick[GroupNumber].UsePointer := 0;
                bGoToNextPhase := TRUE;
            END_IF;  
            
            IF bDoubleModeForThisCycle THEN
                IF iGripperForThisCycle = 0 THEN
                    // This was Pick 1 of 2. Go back to idle and wait for Manager.
                    IDX_PickPlace_Delta := E_PickPlace_State#Initialize; // 0
                ELSE // iGripperForThisCycle = 1
                    // This was Pick 2 of 2. Go to Place.
                    IDX_PickPlace_Delta := E_PickPlace_State#InitializePlace; // 2000 
                END_IF;
            ELSE
                // --- Single Pick Mode ---
                // This was Pick 1 of 1. Go to Place.
                IDX_PickPlace_Delta := E_PickPlace_State#InitializePlace; // 2000 
            END_IF;

(**********************************************************************************************)
(* PLACE                                             *)
(**********************************************************************************************)

		E_PickPlace_State#InitializePlace: // 2000	// Initialize variables
			IDX_Prev_PickPlace_Delta := 2000;

    		TrackConveyorBelt_FeedOut.Execute := FALSE; // Ensure the second conveyor tracking is deactivated
    		//IDX_PickPlace_Delta := E_PickPlace_State#CheckPlaceLimits; // 2100
    		IDX_PickPlace_Delta := E_PickPlace_State#SetPlaceFrame_Tracking; // 2200

		E_PickPlace_State#CheckPlaceLimits: // 2100	// Check for mission availability and verify if elements are within X and Y limits
			IDX_Prev_PickPlace_Delta := 2100;
			
			// `UsePointer_Place` is the pointer to the current item to be placed in the mission
			UsePointer_Place := stPickPlaceProductData_Place[GroupNumber].UsePointer;
			// `StorePointer_Place` is the pointer to the last valid item to be placed
			StorePointer_Place := stPickPlaceProductData_Place[GroupNumber].StorePointer;
			// X and Y positions (in PCS) of the item to place. X considers the maximum pattern dimension
			ActProdX_Place := stPickPlaceProductData_Place[GroupNumber].ProductDetails[UsePointer_Place].ProductPosition[1];
			ActProdY_Place := stPickPlaceProductData_Place[GroupNumber].ProductDetails[UsePointer_Place].ProductPosition[2];
			
			// Check if the item is within the robot's working area (X and Y limits) and if the `UsePointer_Place` is valid.
			IF (ActProdX_Place > DATA_Machine.Setting.LimitPos[0].X_Limits[GroupNumber].PosMin) and
				(ActProdX_Place < DATA_Machine.Setting.LimitPos[0].X_Limits[GroupNumber].PosMax) and
				(ActProdY_Place > DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMin) and
				(ActProdY_Place < DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMax) and
				UsePointer_Place <= StorePointer_Place THEN
				
				// If the item is within limits, go to the next state
				IDX_PickPlace_Delta := E_PickPlace_State#SetPlaceFrame_Tracking; // 2200

			// If the item is outside the Y limits or X is less than the minimum limit, go to an error state
			ELSIF (ActProdY_Place < DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMin) or
				(ActProdY_Place > DATA_Machine.Setting.LimitPos[0].Y_Limits.PosMax) or
				(ActProdX_Place < DATA_Machine.Setting.LimitPos[0].X_Limits[GroupNumber].PosMin) THEN

				PickPlace_Error := TRUE;// ERROR
				
				// Go to the error state
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;

		E_PickPlace_State#SetPlaceFrame_Tracking: // 2200	// Set Frame for Place
			IDX_Prev_PickPlace_Delta := 2200;
			
		    // Set the origin (OO) and orientation (XX, XY) of the frame transformation from Frame_FeedOut
			FrameTypeTransform_FeedOut.OO.X := Frame_FeedOut.OO.X;
			FrameTypeTransform_FeedOut.OO.Y := Frame_FeedOut.OO.Y;
			FrameTypeTransform_FeedOut.OO.Z := Frame_FeedOut.OO.Z;
			FrameTypeTransform_FeedOut.XX.X := Frame_FeedOut.XX.X;
			FrameTypeTransform_FeedOut.XX.Y := Frame_FeedOut.XX.Y;
			FrameTypeTransform_FeedOut.XX.Z := Frame_FeedOut.XX.Z;
			FrameTypeTransform_FeedOut.XY.X := Frame_FeedOut.XY.X;
			FrameTypeTransform_FeedOut.XY.Y := Frame_FeedOut.XY.Y;
			FrameTypeTransform_FeedOut.XY.Z := Frame_FeedOut.XY.Z;
		    FrameTypeTransform_FeedOut.Execute := TRUE;		
			
			IF FrameTypeTransform_FeedOut.Done THEN 	
			    FrameTypeTransform_FeedIn.Execute := FALSE; // Ensure the first frame transformation is deactivated	
				
				// If the frame transformation is done, go to the next state
				IDX_PickPlace_Delta := E_PickPlace_State#ConvertPlaceToCartesian_Tracking; // 2300
			END_IF;

		E_PickPlace_State#ConvertPlaceToCartesian_Tracking: // 2300 	// Convert the transformed frame coordinates into a Cartesian reference for PCS
			IDX_Prev_PickPlace_Delta := 2300;
            VECTOR_TO_CARTESIANREF2(Vector := FrameTypeTransform_FeedOut.FrameCoordinates, CartesianRef => PCS_Frame_FeedOut);
			          
			IDX_PickPlace_Delta := E_PickPlace_State#SetPlaceOffsetAndPCS_Tracking; // 2350

		E_PickPlace_State#SetPlaceOffsetAndPCS_Tracking: // 2350 	// Sets an offset between the Coordinate Systems MCS and PCS
			IDX_Prev_PickPlace_Delta := 2350;
			
			// Configure and execute the GroupSetFrameOffset function block to set the PCS frame
			GroupSetFrameOffset_FeedOut.Offset := PCS_Frame_FeedOut;
			GroupSetFrameOffset_FeedOut.ExecutionMode := MC_ExecutionMode#Immediately;
			GroupSetFrameOffset_FeedOut.RefCoordSystem := MC_CoordinateSystem#MCS;
			GroupSetFrameOffset_FeedOut.SetCoordSystem := MC_CoordinateSystem#PCS;
			GroupSetFrameOffset_FeedOut.Execute := TRUE;
			IF GroupSetFrameOffset_FeedOut.Done THEN
    			GroupSetFrameOffset_FeedIn.Execute := FALSE;
    			TrackConveyorBelt_FeedIn.Execute := FALSE;
    			// Go to the next state
			    IDX_PickPlace_Delta := E_PickPlace_State#EnablePlaceTracking; // 2400
			END_IF;					

		E_PickPlace_State#EnablePlaceTracking: // 2400	// Enable Conveyor Tracking
			IDX_Prev_PickPlace_Delta := 2400;
			
			// Configure the conveyor tracking function block
			TrackConveyorBelt_FeedOut.ConveyorBeltOrigin := FrameTypeTransform_FeedOut.FrameCoordinates;
			TrackConveyorBelt_FeedOut.InitialObjectPosition[1] := 0.0; // Initial object position, x-coordinate
			TrackConveyorBelt_FeedOut.InitialObjectPosition[2] := 0.0; // Initial object position, y-coordinate
			TrackConveyorBelt_FeedOut.InitialObjectPosition[3] := 0.0; // Initial object position, z-coordinate

			// Configure synchronization options for tracking
			TrackConveyorBelt_FeedOut.TrackOptions.SyncIn.Mode := Yt_TrackProfileMode#MasterDistance;
			TrackConveyorBelt_FeedOut.TrackOptions.SyncIn.ConveyorDistance := 30.0; // Defines the distance traveled by conveyor during SyncIn
			TrackConveyorBelt_FeedOut.TrackOptions.SyncIn.TCPDistance := TrackConveyorBelt_FeedOut.TrackOptions.SyncIn.ConveyorDistance / 2.0; // Defines the distance the TCP travels during SyncIn
			TrackConveyorBelt_FeedOut.TrackOptions.SyncOut.ConveyorDistance := 60.0;
			
			// Select the conveyor belt axis and tracking distances based on the active mode
    		TrackConveyorBelt_FeedOut.ConveyorBelt := FeedOutRef;
    		TrackConveyorBelt_FeedOut.StartDistance := 100.0; // Start tracking distance on the conveyor
    		TrackConveyorBelt_FeedOut.EndDistance := 425.0; // End tracking distance on the conveyor
    		TrackConveyorBelt_FeedOut.RecordedPosition := -2.0; // Use the actual rotary axis position as the recorded position
        	
			TrackConveyorBelt_FeedOut.Execute := TRUE;
			
			// If conveyor tracking is active, go to the next state
			IF TrackConveyorBelt_FeedOut.Active THEN
				IDX_PickPlace_Delta := E_PickPlace_State#ApproachPlace_Tracking; // 2500
			END_IF;
			
			// If there's an error with conveyor tracking, go to the error state
			IF TrackConveyorBelt_FeedOut.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;

		E_PickPlace_State#ApproachPlace_Tracking: // 2500	// Approach to Place position
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
			
			// If the movement is active, go to the next state
			IF MoveLinearAbsolute_Blend1.Active THEN
				MoveLinearAbsolute_Blend4.Execute := FALSE;
				IDX_PickPlace_Delta := E_PickPlace_State#WaitForPlaceSync; // 2600
			END_IF;	
			
			// If there's an error with movement, go to the error state
			IF MoveLinearAbsolute_Blend1.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;

		E_PickPlace_State#WaitForPlaceSync: // 2600	// Place when in sync and mission tagged
			IDX_Prev_PickPlace_Delta := 2600;
			
			// If the conveyor tracking is in sync, go to the next state
			IF TrackConveyorBelt_FeedOut.InSync THEN	
				DATA_Machine.Status.InSync_Delta := TRUE;
				IDX_PickPlace_Delta := E_PickPlace_State#DescendAndPlace; // 2700
			END_IF;

		E_PickPlace_State#DescendAndPlace: // 2700	// Deactivate gripper and bring robot to position (xn, yn, Z_Pick)
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
			MoveLinearAbsolute_Blend2.Execute:= TRUE;
			
			// If the movement is active, go to the next state
			IF MoveLinearAbsolute_Blend2.Active OR MoveLinearAbsolute_Blend2.Done THEN
        		MoveLinearAbsolute_Blend1.Execute := FALSE;	// Ensure movement1 is deactivated
        		// Store the current conveyor position based on the active mode
        	    TempPosConv := DATA_FeedOutAxis.Feedback.ActualPosition;
        		        		
        		IDX_PickPlace_Delta := E_PickPlace_State#WaitAfterPlace_Tracking; // 2750
        	END_IF;	
        	
        	// If there's an error with movement, go to the error state
			IF MoveLinearAbsolute_Blend2.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;

        E_PickPlace_State#WaitAfterPlace_Tracking: // 2750    // Stay in sync before raising Z
            IDX_Prev_PickPlace_Delta := 2750;
            
            IF (DATA_FeedOutAxis.Feedback.ActualPosition - TempPosConv) >= 50.0 THEN
                 // Deactivate both grippers
                 bActivateGripper1 := FALSE;
                 bActivateGripper2 := FALSE;
            END_IF;
            
            IF (DATA_FeedOutAxis.Feedback.ActualPosition - TempPosConv) >= 100.0 THEN
                IDX_PickPlace_Delta := E_PickPlace_State#AscendAfterPlace; // 2800
            END_IF;
            
		E_PickPlace_State#AscendAfterPlace: // 2800	// Raise the Z-axis
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
			
			// If the movement is active, go to the next state	
			IF MoveLinearAbsolute_Blend3.Active THEN
				DATA_Machine.Status.InSync_Delta := FALSE; // Reset the in-sync status
				MoveLinearAbsolute_Blend2.Execute := FALSE; // Ensure movement2 is deactivated
				IDX_PickPlace_Delta := E_PickPlace_State#MoveToParking_AfterPlace; // 2850
				TempPosConv := DATA_FeedOutAxis.Feedback.ActualPosition;
			END_IF;	
			
			// If there's an error with movement, go to the error state
			IF MoveLinearAbsolute_Blend3.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;
			
		E_PickPlace_State#MoveToParking_AfterPlace: // 2850	// Go to the parking point
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
			
			// If the movement is active, go to the next state	
			IF MoveLinearAbsolute_Blend4.Active THEN
				DATA_Machine.Status.InSync_Delta := FALSE; // Reset the in-sync status
				MoveLinearAbsolute_Blend3.Execute := FALSE; // Ensure movement2 is deactivated
				IDX_PickPlace_Delta := E_PickPlace_State#CycleCompletitionAndChangeMode; // 2900
			END_IF;	
			
			// If there's an error with movement, go to the error state
			IF MoveLinearAbsolute_Blend4.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;
						
        E_PickPlace_State#CycleCompletitionAndChangeMode: // 2900    // Cycle Completion
            IDX_Prev_PickPlace_Delta := 2900;
            
            // Signal to the Manager that the Place is done so it can reset its counter
            bPlaceCycleComplete := TRUE;
            
            // Parking condition
            IF StopCycleEnabled THEN // TODO
                 IDX_PickPlace_Delta := E_PickPlace_State#InitializeFinalParking; // 3000
            ELSE
                 // Default: Loop back to Initialize to wait for Manager
                 IDX_PickPlace_Delta := 0;
            END_IF;         
        
(**********************************************************************************************)
(*                                        FINAL PARKING                                       *)
(**********************************************************************************************)

        E_PickPlace_State#InitializeFinalParking: // 3000
            IDX_Prev_PickPlace_Delta := 3000;

            // Ensure all movements and tracking are stopped
			TrackConveyorBelt_FeedIn.Execute := FALSE;
			TrackConveyorBelt_FeedOut.Execute := FALSE;    
			MoveLinearAbsolute_Blend1.Execute := FALSE;
			MoveLinearAbsolute_Blend2.Execute := FALSE;
			MoveLinearAbsolute_Blend3.Execute := FALSE;
			MoveLinearAbsolute_Blend4.Execute := FALSE;
			                        
            // Deactivate grippers
            bActivateGripper1 := FALSE;
            bActivateGripper2 := FALSE;
            
            IDX_PickPlace_Delta := E_PickPlace_State#MoveToParking_SafePosition; // 3100

		E_PickPlace_State#MoveToParking_SafePosition: // 3100	// Final Parking - Move to safe parking position
			IDX_Prev_PickPlace_Delta := 3100;
			
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
			
			// Wait for movement to complete
			IF MoveLinearAbsolute_Blend4.Done THEN
				MoveLinearAbsolute_Blend4.Execute := FALSE;
				IDX_PickPlace_Delta := E_PickPlace_State#FinalParkingCompletition; // 3200
			END_IF;
			
			// Handle movement error
			IF MoveLinearAbsolute_Blend4.Error THEN
				IDX_PickPlace_Delta := E_PickPlace_State#Error; // 9999
			END_IF;

        E_PickPlace_State#FinalParkingCompletition: // 3200
            IDX_Prev_PickPlace_Delta := 3200;

            // Clean up all frame transformations and settings
			FrameTypeTransform_FeedIn.Execute := FALSE;
			FrameTypeTransform_FeedOut.Execute := FALSE;		
			CalcFrameOffset_Group.Enable := FALSE;
			GroupSetFrameOffset_FeedIn.Execute := FALSE;
			GroupSetFrameOffset_FeedOut.Execute := FALSE;			                        
            
            IDX_PickPlace_Delta := 0; // Reset to initial state
            
(**********************************************************************************************)
(* ERROR STATE                                           *)
(**********************************************************************************************)

        9999:    // Error state
            IDX_Prev_PickPlace_Delta := 9999;
            // ... existing error handling ...

    END_CASE;
ELSE // If 'StartPickPlace_Delta' is FALSE, deactivate the state machine
    IF PickPlace_Status THEN
        PickPlace_Status := FALSE;
        IDX_PickPlace_Delta := 0;
        
        DATA_Group.Command.TestGroupBlend := FALSE;
				
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
		
		stPickPlaceProductData_Pick[GroupNumber].UsePointer := 0;
		stPickPlaceProductData_Place[GroupNumber].UsePointer := 0;
		stPickPlaceProductData_Pick[GroupNumber].StorePointer := 0;
		stPickPlaceProductData_Place[GroupNumber].StorePointer := 0;
		
        StopCycleEnabled := FALSE;
        
        // Deactivate grippers on disable
        bActivateGripper1 := FALSE;
        bActivateGripper2 := FALSE;
        
        PickPlace_Error := FALSE;
    end_IF;
end_IF;

(* -------- END OF FB_PickPlace_SM IMPLEMENTATION -------- *)