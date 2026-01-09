// METHOD: M_Step_CalcPickOffset
// DESCRIPTION: Applies the gripper offset to the raw vision coordinates.

// No entry action needed for pure calculation
IF iGripperForThisCycle = 0 THEN
    // Use Gripper 1 Offset 
    ActProdX_Pick := ActProdX_Raw + stGripper1_Offset[0]; // [0] = X
    ActProdY_Pick := ActProdY_Raw + stGripper1_Offset[1]; // [1] = Y
ELSE
    // Use Gripper 2 Offset
    ActProdX_Pick := ActProdX_Raw + stGripper2_Offset[0];
    ActProdY_Pick := ActProdY_Raw + stGripper2_Offset[1];
END_IF;

ActProdRZ_Pick := ActProdRZ_Raw; // Rotation remains the same

// Calculation done immediately
M_Step_CalcPickOffset := E_StepStatus#DONE;