(* -------- START OF FB_PickPlace_SM IMPLEMENTATION -------- *)

// 1. Error Handler & External Calls
//fbErrorHandler(bResetErrors := bResetAllErrors, bAcknowledgeErrors := bAcknowledgeAllErrors);
FB_Distribution1();

// 2. Update Global Status
bSM_isIdle := (IDX_PickPlace_Delta = E_PickPlace_State#Initialize); 
bPlaceCycleComplete := FALSE; // Default
DATA_Machine.Status.InSync_Delta := TrackConveyorBelt_FeedIn.InSync OR TrackConveyorBelt_FeedOut.InSync;

// 3. Update Velocity Settings
IF RobotJog.Fast_Speed THEN
    DATA_Machine.Setting.MinVelocity_Delta := 1200.0;
ELSIF RobotJog.Medium_Speed THEN
    DATA_Machine.Setting.MinVelocity_Delta := 500.0;
ELSIF RobotJog.Slow_Speed THEN
    DATA_Machine.Setting.MinVelocity_Delta := 300.0;
END_IF;

// 4. Default Initialization
GroupNumber := INT#0;
ConveyorNumber := INT#0;

// 5. Main State Machine Logic
IF StartPickPlace THEN
    PickPlace_Status := TRUE;

    // Dispatcher: Calls the correct method based on the current State Index
    CASE IDX_PickPlace_Delta OF
        
        // --- INITIALIZATION ---
        E_PickPlace_State#Initialize: // 0
            THIS.M_Phase_Initialize();

        // --- PICK SEQUENCE (100 - 999) ---
        100..999:
            THIS.M_Phase_Pick();

        // --- PLACE SEQUENCE (2000 - 2999) ---
        2000..2999:
            THIS.M_Phase_Place();

        // --- FINAL PARKING (3000+) ---
        3000..3200:
            THIS.M_Phase_Parking();

        // --- ERROR STATE ---
        9999:
            // Error handling logic here (or create M_Phase_Error)
             IDX_Prev_PickPlace_Delta := 9999;
             // Add your specific error logic here
             
    END_CASE;

ELSE
    // If Machine is disabled, run the Reset Method
    THIS.M_ResetMachine();
END_IF;

(* -------- END OF FB_PickPlace_SM IMPLEMENTATION -------- *)