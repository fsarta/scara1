(*
====================================================================================================
 METHOD Update
====================================================================================================
 This method must be called once per PLC scan (e.g., in the main program).
 It is responsible for handling user commands (Reset, Acknowledge).
 It does NOT scan the buffer every cycle, making it very fast.
====================================================================================================
*)

// Get system microseconds (if needed for high-res timing)
Y_YA_PLC_uSec1(
    Enable := TRUE, 
    //Valid => BOOL, 
    //Error => BOOL, 
    //ErrorID => UINT, 
    uSec => SysTimestamp1
    );
    
// --- 1. Handle Reset Errors Command ---
// Detect rising edge for reset command
xResetErrorsR_TRIG(CLK := bResetErrors OR G_bResetAllErrors);
IF xResetErrorsR_TRIG.Q THEN
    
    // Call the private helper method to clear the buffer and reset all counters
    THIS.ResetBufferAndCounters();
    
    G_bResetAllErrors := FALSE; // Clear the global command flag
END_IF

// --- 2. Handle Acknowledge Errors Command ---
// Detect rising edge for acknowledge command
xAcknowledgeErrorsR_TRIG(CLK := bAcknowledgeErrors OR G_bAcknowledgeAllErrors);
IF xAcknowledgeErrorsR_TRIG.Q THEN
    FOR i := 1 TO C_ERROR_BUFFER_SIZE DO
        IF G_ErrorBuffer[i].IsActive THEN
            G_ErrorBuffer[i].Acknowledged := TRUE; // Acknowledge all *currently active* errors
        END_IF
    END_FOR
    G_bAcknowledgeAllErrors := FALSE; // Clear the global command flag
END_IF
