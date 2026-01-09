(****************************************************************************************************************)
(************************************************** DISTRIBUTION **************************************************)
(****************************************************************************************************************)

(*	appena abbiamo il done della formattazione precedente, diamo l'execute alla sequence distribution dopo aver selezionato 
	le seguenti caratteristiche*)

(*	sequence *)
(*	si vuole alternare il prelievo dal medesimo conveyor con 3 robot *)
(*	viene indicala la lunghezza della sequenza *)
stDistributionConfig_Pick[0].SequenceDistribution.SequenceLength := INT#1;

(*	Viene indicata la sequenza, in questo caso un prelievo alternato *)
(*
stDistributionConfig_Pick[0].SequenceDistribution.SequencePattern[0] := INT#0;
stDistributionConfig_Pick[0].SequenceDistribution.SequencePattern[1] := INT#1;
stDistributionConfig_Pick[0].SequenceDistribution.SequencePattern[2] := INT#2;
*)
(*	viene indicato il buffer size di entrambi i gruppi *)
stPickPlaceProductData_Pick[0].BufferSize := INT#30;
(*
stMultiGroupProductData[1].BufferSize := INT#30;
stMultiGroupProductData[2].BufferSize := INT#30;
*)
(*	axis number of conveyor in distribution *)
stDistributionConfig_Pick[0].ConveyorBelt := FeedIn_Axis;

CMD_SequenceDistribution_Pick := TRUE;


(****************************************************************************************************************)
(***************************************************** PICK *****************************************************)
(****************************************************************************************************************)

IF DATA_Machine.Command.PickPlace_Delta THEN
	STS_PickPlaceConvTrack := TRUE;
	
	CASE IDX_PickPlaceConvTrack of
		0:
            FOR i := 0 TO 24 DO
                IF SetMarble[i].Present THEN                    
                    arrProductX[j] := SetMarble[i].X_Coord;
                    arrProductY[j] := SetMarble[i].Y_Coord;
                    j := j + 1;                    
                    // number of products detected
                    rDetectedProducts := TO_REAL(j);	
                END_IF;
                GetMarbleLIN[i].Present := TRUE;
                GetMarbleROT[i].Present := FALSE;
            END_FOR
            
			stPickPlaceProductData_Pick[0].UsePointer := 0;
			stPickPlaceProductData_Pick[0].StorePointer := 0;
            
			xiFormattedProductData := TRUE;
			IDX_PickPlaceConvTrack := 1;
			
		1:		(*	 *)
			IF xoFormatProdDataDone THEN
				IF CMD_SequenceDistribution_Pick THEN
					IDX_PickPlaceConvTrack := 100;
				END_IF;
				xiFormattedProductData := FALSE;
			END_IF;
		100:	(*	 *)
			ConveyorBeltRef_Pick := FeedIn_Axis;
			lrTriggerConveyorPosition_Pick := 10.0; // TrigConveyorPosition;
			xiSequenceDistribution_Pick := TRUE;
			IDX_PickPlaceConvTrack := 101;
		101:
			IF xoSequenceDistrDone_Pick THEN
				xiSequenceDistribution_Pick := FALSE;
				IDX_PickPlaceConvTrack := 9999;
			END_IF;
		9999:
		    DATA_Machine.Command.PickPlace_Delta := FALSE;
            IDX_PickPlaceConvTrack := 0;
	END_CASE;       
ELSE    
	IF STS_PickPlaceConvTrack THEN
		IDX_PickPlaceConvTrack := 0;
		STS_PickPlaceConvTrack := FALSE;
		xiFormattedProductData := FALSE;
		xiSequenceDistribution_Pick := FALSE;
		i := 0;
		j := 0;
	END_IF;
END_IF;



(****************************************************************************************************************)
