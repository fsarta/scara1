// METHOD: M_ConfigSequence_Run
// DESCRIPTION: Builds the standard Pick & Place list.

iTotalSteps := 0; // Clear list

// --- PICK PHASE ---
THIS.AddStep(E_PickPlace_State#Initialize);
THIS.AddStep(E_PickPlace_State#CheckPickLimits);
THIS.AddStep(E_PickPlace_State#CalculatePickGripperOffset);
THIS.AddStep(E_PickPlace_State#SetPickFrame_Tracking);
THIS.AddStep(E_PickPlace_State#ConvertPickToCartesian_Tracking);
THIS.AddStep(E_PickPlace_State#SetPickOffsetAndPCS_Tracking);
THIS.AddStep(E_PickPlace_State#EnablePickTracking);
THIS.AddStep(E_PickPlace_State#ApproachPick_Tracking);
THIS.AddStep(E_PickPlace_State#WaitForPickSync);
THIS.AddStep(E_PickPlace_State#DescendAndPick);
THIS.AddStep(E_PickPlace_State#WaitAfterPick_Tracking);
THIS.AddStep(E_PickPlace_State#AscendAfterPick);
THIS.AddStep(E_PickPlace_State#MoveToParking_AfterPick);
THIS.AddStep(E_PickPlace_State#SelectNextProduct_Pick);

// --- PLACE PHASE ---
// You can logic here: IF bDoubleMode THEN ...
THIS.AddStep(E_PickPlace_State#InitializePlace);
//THIS.AddStep(E_PickPlace_State#CheckPlaceLimits);
THIS.AddStep(E_PickPlace_State#SetPlaceFrame_Tracking);
THIS.AddStep(E_PickPlace_State#ConvertPlaceToCartesian_Tracking);
THIS.AddStep(E_PickPlace_State#SetPlaceOffsetAndPCS_Tracking);
THIS.AddStep(E_PickPlace_State#EnablePlaceTracking);
THIS.AddStep(E_PickPlace_State#ApproachPlace_Tracking);
THIS.AddStep(E_PickPlace_State#WaitForPlaceSync);
THIS.AddStep(E_PickPlace_State#DescendAndPlace);
THIS.AddStep(E_PickPlace_State#WaitAfterPlace_Tracking);
THIS.AddStep(E_PickPlace_State#AscendAfterPlace);
THIS.AddStep(E_PickPlace_State#MoveToParking_AfterPlace);
THIS.AddStep(E_PickPlace_State#CycleCompletitionAndChangeMode);

