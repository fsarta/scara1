// --- 1. Call the Vision Application ---
// This one function call runs the entire vision system.
fbVisionApp(
    // --- Link Commands ---
    xStartSequence    := xPartInPosition OR xHMI_StartCycle,
    xResetError       := xHMI_Reset,
    
    // --- Link Trigger Configuration ---
    xEnableCyclicTrigger := xEnableCyclicMode,
    tCyclicTriggerTime   := tMyCyclicTime,
    
    // --- Link Global I/O Variables ---
    Visor_Receive        := VisorEIP_Receive,
    i_stConnectionStatus := eip_1_ConnectionState,
    Visor_Transmit       => VisorEIP_Transmit // Write back to the GVL
);


// --- 2. Use the Results in Machine Logic ---
// Get status and results back from the application FB
xVisionCycleDone := fbVisionApp.xDone;

IF fbVisionApp.xDone THEN
    // A cycle just finished, save the results
    stMyVisionResults := fbVisionApp.stLastGoodResult;
    
    // TODO: Add logic here
    // e.g., IF stMyVisionResults.Part_Count > 0 THEN ...
END_IF;

IF fbVisionApp.xError THEN
    // TODO: Add logic here
    // e.g., SetMachineAlarm( 'Vision System Error' );
END_IF;