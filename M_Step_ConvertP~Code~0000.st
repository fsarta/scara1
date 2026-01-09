// METHOD: M_Step_ConvertPickToCartesian_Tracking
// DESCRIPTION: Converts vector to Cartesian Reference.

// Assuming VECTOR_TO_CARTESIANREF1 is a Function (synchronous)
VECTOR_TO_CARTESIANREF1(Vector := FrameTypeTransform_FeedIn.FrameCoordinates, CartesianRef => PCS_Frame_FeedIn);

M_Step_ConvertPickToCartesian_Tracking := E_StepStatus#DONE;