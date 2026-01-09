// METHOD: M_Step_InitializePlace
// DESCRIPTION: Resets specific flags for Place phase.

TrackConveyorBelt_FeedOut.Execute := FALSE;
// Done immediately
M_Step_InitializePlace := E_StepStatus#DONE;