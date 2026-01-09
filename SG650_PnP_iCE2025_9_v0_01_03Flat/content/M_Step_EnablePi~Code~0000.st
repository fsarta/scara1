// METHOD: M_Step_EnablePickTracking
// DESCRIPTION: Activates conveyor tracking for Feed In.

// 1. Entry Action
IF NOT bStepInitialized THEN
    // Configure the conveyor tracking function block
	TrackConveyorBelt_FeedIn.ConveyorBeltOrigin := FrameTypeTransform_FeedIn.FrameCoordinates;
	TrackConveyorBelt_FeedIn.InitialObjectPosition[1] := 0.0; // Initial object position, x-coordinate
	TrackConveyorBelt_FeedIn.InitialObjectPosition[2] := 0.0; // Initial object position, y-coordinate
	TrackConveyorBelt_FeedIn.InitialObjectPosition[3] := 0.0; // Initial object position, z-coordinate
	// Configure synchronization options for tracking
	TrackConveyorBelt_FeedIn.TrackOptions.SyncIn.Mode := Yt_TrackProfileMode#MasterDistance;
	TrackConveyorBelt_FeedIn.TrackOptions.SyncIn.ConveyorDistance := 30.0; // Defines the distance traveled by conveyor during SyncIn
	TrackConveyorBelt_FeedIn.TrackOptions.SyncIn.TCPDistance := TrackConveyorBelt_FeedIn.TrackOptions.SyncIn.ConveyorDistance / 2.0; // Defines the distance the TCP travels during SyncIn
	TrackConveyorBelt_FeedIn.TrackOptions.SyncOut.ConveyorDistance := 60.0;
				
	// Select the conveyor belt axis and tracking distances based on the active mode
    TrackConveyorBelt_FeedIn.ConveyorBelt := FeedIn_Ref;
	TrackConveyorBelt_FeedIn.StartDistance := 10.0; // Start tracking distance on the conveyor
    TrackConveyorBelt_FeedIn.EndDistance := 265.0; // End tracking distance on the conveyor
	TrackConveyorBelt_FeedIn.RecordedPosition := 17.0; // Use the actual linear axis position as the recorded position
    
    TrackConveyorBelt_FeedIn.Execute := TRUE;

    bStepInitialized := TRUE;
    M_Step_EnablePickTracking := E_StepStatus#BUSY;
    RETURN;
END_IF;

// 2. Cyclic Check
IF TrackConveyorBelt_FeedIn.Active THEN
    M_Step_EnablePickTracking := E_StepStatus#DONE;
ELSIF TrackConveyorBelt_FeedIn.Error THEN
    M_Step_EnablePickTracking := E_StepStatus#ERROR;
ELSE
    M_Step_EnablePickTracking := E_StepStatus#BUSY;
END_IF;