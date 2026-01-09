(*
-------------------------------------------------------------------------
    FUNCTION_BLOCK FB_VisionApplication (The Manager - Level 1)
    
    Orchestrates the entire vision process.
    - Manages one instance of the FB_VisorDriver.
    - Runs a sequence (Trigger -> Wait -> Get Results).
    - Handles timeouts and errors.
    - Provides a simple interface for the main PLC program (Level 0).
-------------------------------------------------------------------------
*)

// --- 1. Call the Driver FB (Level 2) ---
fbVisor(
    // Commands from this manager
    xTrigger      := xInternalTrigger,
    xResetError   := xInternalReset,
    xChangeJob    := FALSE, 
    iJobToChange  := 0,
    xSwitchToRun  := TRUE,  // Always request RUN mode
    
    // Pass-through I/O
    Visor_Receive        := Visor_Receive,
    i_stConnectionStatus := i_stConnectionStatus,
    Visor_Transmit       => Visor_Transmit, // Pass-through output
    
    // Get status back from driver
    xConnected    => xVisorConnected, // Pass-through status
    xReady        => xVisorReady      // Pass-through status
);


// --- 2. Handle Edge Triggers & Cyclic Timer ---
rtStartSequence(CLK := xStartSequence);
rtResetError(CLK := xResetError);

tonCyclicTimer.IN := xEnableCyclicTrigger
                     AND (eInternalState = E_VisionMgr_State#IDLE)
                     AND fbVisor.xReady;
tonCyclicTimer.PT := tCyclicTriggerTime;


// --- 3. Default/Clear Outputs ---
xActive          := FALSE;
xDone            := FALSE;
xInternalTrigger := FALSE;
xInternalReset   := FALSE;
tonTimeout.IN    := FALSE;


// --- 4. Main Sequencer (State Machine) ---
CASE eInternalState OF
    
    E_VisionMgr_State#IDLE:
        xError := FALSE;
        
        IF rtResetError.Q THEN
            xInternalReset := TRUE; 
        END_IF;
        
        xStartSignal := rtStartSequence.Q OR tonCyclicTimer.Q;
        
        IF xStartSignal THEN
            // A trigger (external or cyclic) has occurred
            IF fbVisor.xReady THEN
                eInternalState := E_VisionMgr_State#TRIGGER_CAMERA;
            ELSE
                eInternalState := E_VisionMgr_State#ERROR; // Not ready or connected
            END_IF;
        END_IF;

        
    E_VisionMgr_State#TRIGGER_CAMERA:
        xActive           := TRUE;
        xInternalTrigger  := TRUE; // Send the pulse to driver
        tonTimeout.IN     := TRUE; // Start the watchdog
        tonTimeout.PT     := T#2S; 
        
        eInternalState    := E_VisionMgr_State#WAIT_FOR_RESULTS;
        
        
    E_VisionMgr_State#WAIT_FOR_RESULTS:
        xActive       := TRUE;
        tonTimeout.IN := TRUE; 
        
        IF NOT fbVisor.xTriggerBusy THEN
            tonTimeout.IN  := FALSE;
            eInternalState := E_VisionMgr_State#PROCESS_RESULTS;
            
        ELSIF tonTimeout.Q THEN
            tonTimeout.IN  := FALSE;
            eInternalState := E_VisionMgr_State#ERROR; // Timeout
        END_IF;

        
    E_VisionMgr_State#PROCESS_RESULTS:
        xActive := TRUE;
        
        IF fbVisor.xError THEN
            eInternalState := E_VisionMgr_State#ERROR; // Driver reported an error
        ELSE
            stLastGoodResult := fbVisor.o_stResultData;
            xDone            := TRUE; // Set one-shot 'Done' pulse
            eInternalState   := E_VisorControlState#IDLE; 
        END_IF;

        
    E_VisionMgr_State#ERROR:
        xError := TRUE;
        xInternalReset := TRUE; // Try to clear the driver's error
        
        IF rtResetError.Q THEN
            eInternalState := E_VisionMgr_State#IDLE;
        END_IF;
        
END_CASE;

// --- 5. Update Public State Output ---
eState := eInternalState;