(* -------- START OF FB_PickPlace_Sequencer IMPLEMENTATION -------- *)
Group_Ref := GroupRef;
FeedIn_Ref := FeedInRef;
FeedOut_Ref := FeedOutRef;
stPickPlaceProductData_Pick := IO_stPickPlaceProductData_Pick;
stPickPlaceProductData_Place := IO_stPickPlaceProductData_Place;

// 1. General Updates (Error Handlers, Velocity settings, etc.)
FB_Distribution1();
DATA_Machine.Status.InSync_Delta := TrackConveyorBelt_FeedIn.InSync OR TrackConveyorBelt_FeedOut.InSync;

// 2. Start / Reset Logic
IF StartPickPlace AND NOT PickPlace_Status THEN
    // >> FIRST START: Load the sequence <<
    THIS.M_ConfigSequence_Run(); // Loads the Pick & Place Playlist
    PickPlace_Status := TRUE;
    iCurrentStepIndex := 0;
    bStepInitialized := FALSE; // Reset entry trigger
    PickPlace_Error := FALSE;
ELSIF NOT StartPickPlace THEN
    PickPlace_Status := FALSE;
END_IF;

// 3. THE SEQUENCER ENGINE
IF PickPlace_Status AND NOT PickPlace_Error THEN

    // Check if we are within the playlist bounds
    IF iCurrentStepIndex < iTotalSteps THEN
        
        eCurrentStepName := SequenceList[iCurrentStepIndex];
        
        // --- CALL THE DISPATCHER ---
        // It looks at the ID in the list (e.g., "CheckPickLimits") and calls the specific Method.
        // It returns BUSY, DONE, or ERROR.
        eStepResult := THIS.M_Dispatcher(SequenceList[iCurrentStepIndex]);

        // --- MANAGE TRANSITIONS ---
        CASE eStepResult OF
            
            E_StepStatus#BUSY:
                // Step is running. Do nothing, wait for next scan.
                ;
                
            E_StepStatus#DONE:
                bStepInitialized := FALSE; // Reset entry trigger for the NEW step
                
                IF eRequestedJumpState <> E_PickPlace_State#Unknown THEN
                    // If the step required a jump, let's look for where to go
                    iCurrentStepIndex := THIS.M_Helper_FindStepIndex(eRequestedJumpState);
                    
                    // Request reset
                    eRequestedJumpState := E_PickPlace_State#Unknown;
                    
                    // Error handling if the step does not exist in the list
                    IF iCurrentStepIndex = -1 THEN
                        PickPlace_Error := TRUE; // "Jump Target Not Found"
                    END_IF
                ELSE
                
                    // Advance to next step.
                    iCurrentStepIndex := iCurrentStepIndex + 1;
                END_IF
                
            E_StepStatus#ERROR:
                // Step failed. Handle Error.
                PickPlace_Error := TRUE;
                // Optionally: Load an error sequence or stop.
                
        END_CASE;

    ELSE
        // --- END OF SEQUENCE REACHED ---
        
        IF StopCycleEnabled THEN
            // User requested stop: Load Parking Sequence
             THIS.M_ConfigSequence_Parking();
             iCurrentStepIndex := 0;
             bStepInitialized := FALSE;
             // IMPORTANT: Disable StopCycleEnabled so we don't loop parking forever
             StopCycleEnabled := FALSE; 
        ELSE
            // Normal Cycle: Loop back to start (Reload Pick & Place)
            THIS.M_ConfigSequence_Run(); 
            iCurrentStepIndex := 0;
            bStepInitialized := FALSE;
        END_IF;
        
    END_IF;

ELSIF NOT StartPickPlace THEN
    // Machine Disabled: Reset everything
    THIS.M_ResetMachine();
END_IF;

// 4. Global Error Handling
IF PickPlace_Error THEN
    // Execute Error Logic (or call M_Step_Error)
END_IF;

bSM_isIdle := (SequenceList[iCurrentStepIndex] = E_PickPlace_State#Initialize);