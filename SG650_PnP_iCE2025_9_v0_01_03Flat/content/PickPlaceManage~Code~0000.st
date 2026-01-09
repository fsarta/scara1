(* -------- START OF PRG_Manager IMPLEMENTATION -------- *)

// 1. Read HMI and System Inputs 
bHMI_Start := CycleControls.StartCycle;
bHMI_Stop := CycleControls.StopCycle;
eHMI_OperationMode := CycleControls.OperationMode; 

// 2. Detect Start Button press
trigStart(CLK := bHMI_Start);

// 3. Reset piece counter if the FB signals Place is complete
IF FB_PickPlace_Sequencer1.bPlaceCycleComplete THEN
    iPartOnGripper := 0;
END_IF;

// 4. Handle Stop/AutoMode OFF
IF NOT(StartPickPlace_Delta) OR bHMI_Stop THEN
    // System is stopped or not in auto
    iPartOnGripper := 0;       // Reset counter
    bStartCmd := FALSE;  // Ensure no start pulse is sent
ELSE
    // --- CONTINUOUS CYCLE LOGIC (AutoMode is ON and NOT Stopped) ---
    IF FB_PickPlace_Sequencer1.bSM_isIdle THEN
        
        // --- Single Pick Mode Logic ---
        IF eHMI_OperationMode = E_PickPlaceMode#MODE_SINGLE_PICK THEN
            IF iPartOnGripper = 0 THEN // Gripper is empty, good to go
                iGripperToUseCmd := 0;
                bDoubleModeCmd := FALSE;
                bStartCmd := TRUE; // Send the pulse
            END_IF;
        
        // --- Double Pick Mode Logic ---
        ELSIF eHMI_OperationMode = E_PickPlaceMode#MODE_DOUBLE_PICK THEN
            IF iPartOnGripper = 0 THEN // Gripper empty, pick Piece 1
                iGripperToUseCmd := 0;
                bDoubleModeCmd := TRUE;
                bStartCmd := TRUE; // Send the pulse
                iPartOnGripper := 1; // We now have 1 piece
                
            ELSIF iPartOnGripper = 1 THEN // Gripper has 1, pick Piece 2
                iGripperToUseCmd := 1;
                bDoubleModeCmd := TRUE;
                bStartCmd := TRUE; // Send the pulse
                iPartOnGripper := 2; // We now have 2 pieces
            END_IF;
        END_IF;
    END_IF;
END_IF;
(*
// 5. Call the Function Block 
fbPickPlace(
    (* --- Axis & Group References --- *)
    GroupRef := DELTA,
    FeedInRef := FeedIn_Axis,
    FeedOutRef := FeedOut_Axis,

    (* --- Commands from Manager --- *)
    StartCycle := bStartCmd,
    bDoubleMode := bDoubleModeCmd,
    iGripperToUse := iGripperToUseCmd,
    StopCycleEnabled := bHMI_Stop,
    
    (* --- System & Mode Inputs --- *)
    StartPickPlace := StartPickPlace_Delta,
    bAutoModeSelected := bAutoModeSelected,
    bManualModeSelected := bManualModeSelected,
    bResetAllErrors := G_bResetAllErrors,
    bAcknowledgeAllErrors := G_bAcknowledgeAllErrors,
    
    (* --- Data & Frame Inputs --- *)
    stPickPlaceProductData_Pick := stPickPlaceProductData_Pick,
    stPickPlaceProductData_Place := stPickPlaceProductData_Place,
    Frame_FeedIn := Frame_FeedIn,
    Frame_FeedOut := Frame_FeedOut,
    rDetectedProducts := rDetectedProducts,
    
    (* --- Machine Data & Settings --- *)
    DATA_Machine := DATA_Machine,
    DATA_Group := DATA_Delta,
    DATA_FeedInAxis := DATA_FeedInAxis,
    DATA_FeedOutAxis := DATA_FeedOutAxis,
    RobotJog := RobotJog,   
        
    (* --- Gripper Offset Parameters --- *)
    stGripper1_Offset := Gripper1_Offset,
    stGripper2_Offset := Gripper2_Offset
    
    (* --- FB Outputs (Read-only) --- *)
    // bSM_isIdle => (read below)
    // bPlaceCycleComplete => (read above)
    // bActivateGripper1 => (read below)
    // bActivateGripper2 => (read below)
    // STS_PickPlace_Delta => STS_PickPlace_Delta 
    // PickPlace_Error => PickPlace_Error 
    // bInSync => bInSync 
    // bTestGroupBlendCmd => bTestGroupBlendCmd 
    // GroupNumber => GroupNumber 
    // ConveyorNumber => ConveyorNumber 
);
*)

FB_PickPlace_Sequencer1(
    (* --- Axis & Group References --- *)
    GroupRef := SCARA,
    FeedInRef := FeedIn_Axis,
    FeedOutRef := FeedOut_Axis,
    
    (* --- Machine Data & Settings --- *)
    //DATA_Machine := DATA_Machine,
    //DATA_Group := DATA_Delta,
    //DATA_FeedInAxis := DATA_FeedInAxis,
    //DATA_FeedOutAxis := DATA_FeedOutAxis,
    RobotJog := RobotJog, 
    
    (* --- Commands from Manager --- *)
    StartCycle := bStartCmd,
    bDoubleMode := bDoubleModeCmd,
    iGripperToUse := iGripperToUseCmd,
    StopCycleEnabled := bHMI_Stop,
    
    (* --- System & Mode Inputs --- *)
    StartPickPlace := StartPickPlace_Delta,
    bAutoModeSelected := bAutoModeSelected,
    bManualModeSelected := bManualModeSelected,
    bResetAllErrors := G_bResetAllErrors,
    bAcknowledgeAllErrors := G_bAcknowledgeAllErrors,
    
    (* --- Data & Frame Inputs --- *)
    IO_stPickPlaceProductData_Pick := stPickPlaceProductData_Pick,
    IO_stPickPlaceProductData_Place := stPickPlaceProductData_Place,
    Frame_FeedIn := Frame_FeedIn,
    Frame_FeedOut := Frame_FeedOut,
    rDetectedProducts := rDetectedProducts,
    
    (* --- Gripper Offset Parameters --- *)
    stGripper1_Offset := Gripper1_Offset,
    stGripper2_Offset := Gripper2_Offset
        
    (* --- FB Outputs (Read-only) --- *)
    // bSM_isIdle => 
    // bPlaceCycleComplete => 
    // bActivateGripper1 => 
    // bActivateGripper2 => 
    // PickPlace_Status => PickPlace_Status 
    // PickPlace_Error => PickPlace_Error 
    // bInSync => bInSync 
    // bTestGroupBlendCmd => bTestGroupBlendCmd 
    // GroupNumber => GroupNumber 
    // ConveyorNumber => ConveyorNumber 
);


// 6. Map FB Outputs to Physical Hardware
SB_do1.Out.PIQ0 := FB_PickPlace_Sequencer1.bActivateGripper1;
SB_do1.Out.PIQ1 := FB_PickPlace_Sequencer1.bActivateGripper2; 

