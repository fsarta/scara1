IF TrackConveyorBelt_FeedIn.InSync THEN
    DATA_Machine.Status.InSync_Delta := TRUE;
    M_Step_WaitForPickSync := E_StepStatus#DONE;
ELSE
    M_Step_WaitForPickSync := E_StepStatus#BUSY;
END_IF