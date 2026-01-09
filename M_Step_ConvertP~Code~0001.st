// METHOD: M_Step_ConvertPlaceToCartesian_Tracking

VECTOR_TO_CARTESIANREF2(Vector := FrameTypeTransform_FeedOut.FrameCoordinates, CartesianRef => PCS_Frame_FeedOut);
M_Step_ConvertPlaceToCartesian_Tracking := E_StepStatus#DONE;