(*
====================================================================================================
 METHOD LogEvent 
====================================================================================================
 This is a lightweight method for logging STATELESS events (e.g., "Info", "Debug", "Homing Done").
 It does NOT check the buffer for existing entries.
 It simply adds a new entry to the circular buffer.
 It does NOT affect the G_stOverallErrorStatus (as it sets IsActive=FALSE).

 !! IMPORTANT !!
 This method MUST be called using an R_TRIG (Rising Edge Trigger) in the
 calling code to prevent it from flooding the log buffer in a single scan.

 Example in FB_GroupController:
   rtHomingDone(CLK := STS_HomeDone);
   IF rtHomingDone.Q THEN
       fbErrorHandler.LogEvent(100, 'Axis_1', 'Homing Complete', E_ErrorSeverity#Info);
   END_IF;
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

// --- 2. Determine final message ---
IF LEN(sEventMessage) > 0 THEN
    sFinalEventMessage := sEventMessage;
ELSE
    sFinalEventMessage := THIS.GetErrorMessage(udiEventID);
END_IF;

// --- 3. Add Event to Buffer (no checking, just add) ---
G_ErrorBuffer[G_udiErrorHead].ErrorCode := udiEventID;
G_ErrorBuffer[G_udiErrorHead].ErrorSource := sEventSource;
G_ErrorBuffer[G_udiErrorHead].ErrorMessage := sFinalEventMessage;
G_ErrorBuffer[G_udiErrorHead].Severity := eEventSeverity;
G_ErrorBuffer[G_udiErrorHead].IsActive := FALSE; // <-- Key difference: Events are not "active"
G_ErrorBuffer[G_udiErrorHead].Timestamp := SysTimestamp;
G_ErrorBuffer[G_udiErrorHead].Acknowledged := TRUE; // <-- Key difference: Events are pre-acknowledged

// --- 4. Increment circular buffer head pointer ---
G_udiErrorHead := G_udiErrorHead + 1;
IF G_udiErrorHead > C_ERROR_BUFFER_SIZE THEN
    G_udiErrorHead := 1;
END_IF;

// --- 5. Check for buffer overflow ---
IF G_udiErrorHead = G_udiErrorTail THEN
    G_bBufferFull := TRUE;
    G_udiErrorTail := G_udiErrorTail + 1; // Overwrite the oldest item
    IF G_udiErrorTail > C_ERROR_BUFFER_SIZE THEN
        G_udiErrorTail := 1;
    END_IF;
END_IF;