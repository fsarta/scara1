fbErrorHandlerInstance(bResetErrors := G_bResetAllErrors, bAcknowledgeErrors := G_bAcknowledgeAllErrors);

// Gestione Start ciclo
CASE IDX_StartCycle OF
    0:
        IF CycleControls.StartCycle THEN
            IF StartCycleEnabled THEN
                StartCycleEnabled := FALSE;
            ELSE
                StartCycleEnabled := TRUE;
            END_IF;
            IDX_StartCycle := 1;
        END_IF;
    1:
        IF NOT(CycleControls.StartCycle) THEN
            IDX_StartCycle := 0;
        END_IF;
END_CASE;

// Gestione Start ciclo
CASE IDX_StopCycle OF
    0:
        IF CycleControls.StopCycle THEN
            IF StopCycleEnabled THEN
                StopCycleEnabled := FALSE;
            ELSE
                StopCycleEnabled := TRUE;
            END_IF;
            IDX_StopCycle := 1;
        END_IF;
    1:
        IF NOT(CycleControls.StopCycle) THEN
            IDX_StopCycle := 0;
        END_IF;
END_CASE;

SB_do1_6.Out.PIQ6 := DATA_Delta.Command.Gripper; // Out for the gripper

IF RobotJog.Fast_Speed THEN
    DATA_Machine.Setting.MinVelocity_Delta := 1200.0;
ELSIF RobotJog.Medium_Speed THEN
    DATA_Machine.Setting.MinVelocity_Delta := 500.0;
ELSIF RobotJog.Slow_Speed THEN
    DATA_Machine.Setting.MinVelocity_Delta := 300.0;
END_IF;
