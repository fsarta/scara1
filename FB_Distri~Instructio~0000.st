(*****************************************************************************************************************)
(************************************************** SENSOR DATA **************************************************)
(*****************************************************************************************************************)

(*	Function block takes input data from a sensor and outputs FormattedProductData [REAL_ARRAY401] 
	for use in distribution function blocks (as InputProductData).
	User must ensure that the sensor being used will output data in the format of input expected by this function block.	*)
FormatProductData_1(
	FormattedProductData := arrFormattedProductData,(* FormatProductData_Distr.FormattedProductData, *)
	Execute := xiFormattedProductData,
	DetectedProducts := rDetectedProducts,
	ProductX := arrProductX,
	ProductY := arrProductY,
	ProductZ := arrProductZ,
	ProductRx := arrProductRx,
	ProductRy := arrProductRy,
	ProductRz := arrProductRz,
	ProductType := arrProductType,
	ProductUserData := arrProductUserData,
	Done => xoFormatProdDataDone,
	Busy => xoFormatProdDataBusy,
	Error => xoFormatProdDataError,
	ErrorID => uiFormatProdDataErrorId
	);

(******************************************************************************************************************)
(************************************************** DISTRIBUTION **************************************************)
(******************************************************************************************************************)

(*	Distribution based on a defined sequence. For example, group 1 gets first part, group 2 gets second, repeat, etc. 
	Takes InputProductData and distributes it to each group's buffer. 
	InputProductData sorting and duplicate check are optional.	*)
SequenceDistribution_Pick(
    MultiGroupProductData := stPickPlaceProductData_Pick, 
	ConveyorBelt := ConveyorBeltRef_Pick,
	InputProductData := arrFormattedProductData,
	DistributionConfig := stDistributionConfig_Pick,
	Execute := xiSequenceDistribution_Pick,
	TriggerConveyorPosition := lrTriggerConveyorPosition_Pick,
	ProductOptions := stProductOptions_Pick,
	Done => xoSequenceDistrDone_Pick,
    Busy => xoSequenceDistrBusy_Pick,
    Error => xoSequenceDistrError_Pick,
    ErrorID => uiSequenceDistrErrorID_Pick
	);
		
(***********************************************************************************************************************)
(************************************************** BUFFER MANAGEMENT **************************************************)
(***********************************************************************************************************************)

(*	Increment the product buffer of the group by incrementing the UsePointer in the circular buffer. 
	Indicates the product is processed.	*)
SelectNextProduct_Pick(
	MultiGroupProductData := stPickPlaceProductData_Pick,
	Execute := xiSelectNextProduct_Pick,
	GroupNumber := iGroupNumber_Pick,
	Done => xoSelectNextProductDone_Pick,
    Busy => xoSelectNextProductBusy_Pick,
    Error => xoSelectNextProductError_Pick,
    ErrorID => uiSelectNextProductErrorID_Pick
	);
	
(*	Move the current product indicated by UsePointer to the end of the new Group's product buffer (specified by new Group's StorePointer). 
	Update UsePointer for current Group product buffer and update StorePointer for new Group part buffer. 
	This can be used for overflow type distribution.	*)
TransferProductToGroup_Pick(
	MultiGroupProductData := stPickPlaceProductData_Pick,
	Execute := xiTransfProductToGrp_Pick,
	GroupNumber := iGroupNumber_Pick,
	NewGroupNumber := iNewGroupNumber_Pick,
	Done => xoTransfProductToGrpDone_Pick,
    Busy => xoTransfProductToGrpBusy_Pick,
    Error => xoTransfProductToGrpError_Pick,
    ErrorID => uiTransfProductToGrpErrorID_Pick
	);
	
(****************************************************************************************************************)
(************************************************** MONITORING **************************************************)
(****************************************************************************************************************)

(*	Monitoring function blocks report status of the MultiGrpProductBuffer.
	For each buffer within MultiGrpProductBuffer that has a non zero buffersize (indicates it is being used), it provides following:
	-- Number of products in buffer not yet processed;
	-- Distance from origin of the product at UsePointer;
	-- Distance between product at StorePointer and previous product;
	-- Distance between product at StorePointer and next product;
	-- Provide flags for each if a threshhold is reached;
     	-- Flag for if number of unprocessed products in buffer is greater than threshold;
     	-- Flag for if current product (indicated by UsePointer) is greater than some distance in X away from origin of product (usually indicates X distance away from CBO).	*)
MultiGrpProductMonitor_Pick(
	MultiGroupProductData := stPickPlaceProductData_Pick,
	MonitorThreshholdData := stPickMonitorThresholdData_Pick,
	MonitorStatusData := stPickMonitorStatusData_Pick,
	Enable := xiMultiGrpProductMonitor_Pick,
    Valid => xoMultiGrpProductMonValid_Pick,
    Error => xoMultiGrpProductMonError_Pick,
    ErrorID => uiMultiGrpProductMonErrorID_Pick
	);