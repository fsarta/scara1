(*
====================================================================================================
 METHOD AddUpdateError
====================================================================================================
 This is the primary method for managing STATFUL errors.
 It is designed to be called EVERY SCAN for each potential error source.

 - bErrorDetected: The current state of the error (e.g., MC_Axis.Error)
 - udiErrorID: The error code (e.g., MC_Axis.ErrorID)
 - sErrorSource: A string identifying the source (e.g., 'Axis_1_Jog')
 - sErrorMessage: An optional custom message. If empty, GetErrorMessage(udiErrorID) is used.
 - eErrorSeverity: The severity of the error.

 This method is state-aware. It only performs actions on a state change:
  - Case 1 (NEW ERROR): bErrorDetected is TRUE, but error is not active in buffer.
  - Case 2 (STILL ACTIVE): bErrorDetected is TRUE, and error is already active. (Does nothing)
  - Case 3 (ERROR RESOLVED): bErrorDetected is FALSE, but error was active.
  - Case 4 (STILL INACTIVE): bErrorDetected is FALSE, and error was not active. (Does nothing)
  
 This method also incrementally updates the G_stOverallErrorStatus.
====================================================================================================
*)

// --- 1. Get current timestamp ---
Y_YA_RealTimeClock1(
    Enable := TRUE, 
    //Valid => BOOL, 
    //Error => BOOL, 
    //ErrorID => UINT, 
    Clock => SysTimestamp
    //RTCString => STRING
    );
    
// --- 2. Determine final error message (only if it's a new error) ---
IF bErrorDetected THEN
    IF LEN(sErrorMessage) > 0 THEN
        sFinalErrorMessage := sErrorMessage;
    ELSE
        // Get the default message from the lookup table
        sFinalErrorMessage := THIS.GetErrorMessage(udiErrorID);
    END_IF;
END_IF;

// --- 3. Find existing error in buffer ---
// This loop finds if this specific error (ID + Source) is already in the buffer
// This is the most performance-critical part.
// NOTE: This loop is still O(N). For extreme performance, a more complex
// lookup (e.g., an index-managing FB) would be needed, but that
// requires changing the API. This implementation sticks to the existing API.
FOR i := 1 TO C_ERROR_BUFFER_SIZE DO
    IF G_ErrorBuffer[i].ErrorCode = udiErrorID AND
       G_ErrorBuffer[i].ErrorSource = sErrorSource THEN
        
        IF G_ErrorBuffer[i].IsActive THEN
            udiActiveMatchIndex := i; // Found an active match
            EXIT; // Found the active error, no need to search further
        END_IF
    END_IF;
    
    // This part is for the falling edge (error disappearing)
    IF G_ErrorBuffer[i].ErrorSource = sErrorSource AND
       G_ErrorBuffer[i].IsActive AND NOT(bErrorDetected) THEN
        udiInactiveMatchIndex := i;
        EXIT; // Found the active error that needs to be deactivated
    END_IF;
END_FOR;

// --- 4. Main State Logic ---
IF bErrorDetected THEN // The error condition is currently TRUE
    
    IF udiActiveMatchIndex = 0 THEN
        // --- CASE 1: NEW ERROR (Rising Edge) ---
        // Error is not currently active in the buffer. Add it as a new entry.
        G_ErrorBuffer[G_udiErrorHead].ErrorCode := udiErrorID;
        G_ErrorBuffer[G_udiErrorHead].ErrorSource := sErrorSource;
        G_ErrorBuffer[G_udiErrorHead].ErrorMessage := sFinalErrorMessage;
        G_ErrorBuffer[G_udiErrorHead].Severity := eErrorSeverity;
        G_ErrorBuffer[G_udiErrorHead].IsActive := TRUE;
        G_ErrorBuffer[G_udiErrorHead].Timestamp := SysTimestamp;
        G_ErrorBuffer[G_udiErrorHead].Acknowledged := FALSE;

        // Increment circular buffer head pointer
        G_udiErrorHead := G_udiErrorHead + 1;
        IF G_udiErrorHead > C_ERROR_BUFFER_SIZE THEN
            G_udiErrorHead := 1;
        END_IF;

        // Check for buffer overflow
        IF G_udiErrorHead = G_udiErrorTail THEN
            G_bBufferFull := TRUE;
            G_udiErrorTail := G_udiErrorTail + 1; // Overwrite the oldest item
            IF G_udiErrorTail > C_ERROR_BUFFER_SIZE THEN
                G_udiErrorTail := 1;
            END_IF;
        END_IF;
        
        // **PERFORMANCE FIX:** Incrementally update global status
        G_stOverallErrorStatus.udiActiveErrorCount := G_stOverallErrorStatus.udiActiveErrorCount + 1;
        G_stOverallErrorStatus.bAnyErrorActive := TRUE;
        IF eErrorSeverity > G_stOverallErrorStatus.eHighestSeverity THEN
            G_stOverallErrorStatus.eHighestSeverity := eErrorSeverity;
        END_IF;
        
        bActionPerformed := TRUE;
    ELSE
        // --- CASE 2: ERROR STILL ACTIVE ---
        // The error is already active (udiActiveMatchIndex <> 0).
        // No new entry needed.
        // We can update severity in case it changed.
        G_ErrorBuffer[udiActiveMatchIndex].Severity := eErrorSeverity;
        
        // If error was acknowledged but is still active, un-acknowledge it
        IF G_ErrorBuffer[udiActiveMatchIndex].Acknowledged THEN
             G_ErrorBuffer[udiActiveMatchIndex].Acknowledged := FALSE;
             G_ErrorBuffer[udiActiveMatchIndex].Timestamp := SysTimestamp; // Update timestamp
        END_IF;
        
        // **PERFORMANCE FIX:** Check if severity changed, if so, recalculate
        IF eErrorSeverity > G_stOverallErrorStatus.eHighestSeverity THEN
            G_stOverallErrorStatus.eHighestSeverity := eErrorSeverity;
        ELSIF eErrorSeverity < G_ErrorBuffer[udiActiveMatchIndex].Severity THEN
            // Severity might have been lowered,
            // we must recalculate the "highest" in the buffer
            THIS.RecalculateHighestSeverity();
        END_IF;

        bActionPerformed := TRUE; // Action was to "keep active"
    END_IF;

ELSE // bErrorDetected is FALSE. The error condition is no longer TRUE.

    IF udiInactiveMatchIndex <> 0 THEN
        // --- CASE 3: ERROR RESOLVED (Falling Edge) ---
        // The error *was* active, but the condition is now FALSE.
        // Deactivate this specific entry.
        G_ErrorBuffer[udiInactiveMatchIndex].IsActive := FALSE;
        bActionPerformed := TRUE;
        
        // **PERFORMANCE FIX:** Incrementally update global status
        G_stOverallErrorStatus.udiActiveErrorCount := G_stOverallErrorStatus.udiActiveErrorCount - 1;

        IF G_stOverallErrorStatus.udiActiveErrorCount = 0 THEN
            // No errors left
            G_stOverallErrorStatus.bAnyErrorActive := FALSE;
            G_stOverallErrorStatus.eHighestSeverity := E_ErrorSeverity#None;
        ELSE
            // Errors are left, but we removed one.
            // We must recalculate the highest severity, in case this was the highest.
            THIS.RecalculateHighestSeverity();
        END_IF;
    ELSE
        // --- CASE 4: ERROR STILL INACTIVE ---
        // Condition is FALSE, and error was not active.
        // Do nothing.
        bActionPerformed := FALSE;
    END_IF;
END_IF;

AddUpdateError := bActionPerformed;