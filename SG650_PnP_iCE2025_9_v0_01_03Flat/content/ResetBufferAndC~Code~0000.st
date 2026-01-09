(*
====================================================================================================
 PRIVATE METHOD ResetBufferAndCounters
====================================================================================================
 Resets the entire error buffer and clears the global status counters.
 Called from FB_Init and the Reset command in Update.
====================================================================================================
*)

// Clear all entries in the buffer
FOR i := 1 TO C_ERROR_BUFFER_SIZE DO
    G_ErrorBuffer[i].IsActive := FALSE;
    G_ErrorBuffer[i].Acknowledged := FALSE;
    G_ErrorBuffer[i].ErrorCode := 0;
    G_ErrorBuffer[i].ErrorSource := '';
    G_ErrorBuffer[i].ErrorMessage := '';
    G_ErrorBuffer[i].Severity := E_ErrorSeverity#None;
    // Clear timestamp (optional)
END_FOR

// Reset buffer pointers
G_udiErrorHead := 1;
G_udiErrorTail := 1;
G_bBufferFull := FALSE;

// Reset the global status structure
G_stOverallErrorStatus.bAnyErrorActive := FALSE;
G_stOverallErrorStatus.udiActiveErrorCount := 0;
G_stOverallErrorStatus.eHighestSeverity := E_ErrorSeverity#None;
G_stOverallErrorStatus.bBufferFull := FALSE;