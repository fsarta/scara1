if CMD_TestGroupBlend then
	STS_TestGroupRunningBlend := true;

	DATA_Delta.Command.Gripper := TestGroup[IDX_TestGroup002_Blend].Gripper;
	case IDX_TestGroup001_Blend of
		0:		(*	Load Index Data And Set The Mission *)
			MoveLinearAbsolute_Blend1.Position := TestGroup[IDX_TestGroup002_Blend].Position;
			MoveLinearAbsolute_Blend1.Velocity := TestGroup[IDX_TestGroup002_Blend].Speed;
			MoveLinearAbsolute_Blend1.Acceleration :=TestGroup[IDX_TestGroup002_Blend].Acc;
			MoveLinearAbsolute_Blend1.Deceleration :=TestGroup[IDX_TestGroup002_Blend].Dec;
			MoveLinearAbsolute_Blend1.CoordSystem := TestGroup[IDX_TestGroup002_Blend].CoordSystem;
			MoveLinearAbsolute_Blend1.BufferMode := TestGroup[IDX_TestGroup002_Blend].BufferMode;
			MoveLinearAbsolute_Blend1.TransitionMode := TestGroup[IDX_TestGroup002_Blend].TransitionMode;
			MoveLinearAbsolute_Blend1.TransitionParameter := TestGroup[IDX_TestGroup002_Blend].TransitionParameter;
			MoveLinearAbsolute_Blend1.MoveOptions.VelocityUnit := TestGroup[IDX_TestGroup002_Blend].MoveOptions_VelocityUnit; (* VERY IMPORTANT *)(* UseNSpaceScalers *)

			MoveLinearAbsolute_Blend2.Position := TestGroup[IDX_TestGroup002_Blend].Position;
			MoveLinearAbsolute_Blend2.Velocity := TestGroup[IDX_TestGroup002_Blend].Speed;
			MoveLinearAbsolute_Blend2.Acceleration :=TestGroup[IDX_TestGroup002_Blend].Acc;
			MoveLinearAbsolute_Blend2.Deceleration :=TestGroup[IDX_TestGroup002_Blend].Dec;
			MoveLinearAbsolute_Blend2.CoordSystem := TestGroup[IDX_TestGroup002_Blend].CoordSystem;
			MoveLinearAbsolute_Blend2.BufferMode := TestGroup[IDX_TestGroup002_Blend].BufferMode;
			MoveLinearAbsolute_Blend2.TransitionMode := TestGroup[IDX_TestGroup002_Blend].TransitionMode;
			MoveLinearAbsolute_Blend2.TransitionParameter := TestGroup[IDX_TestGroup002_Blend].TransitionParameter;
			MoveLinearAbsolute_Blend2.MoveOptions.VelocityUnit := TestGroup[IDX_TestGroup002_Blend].MoveOptions_VelocityUnit; (* VERY IMPORTANT *)(* UseNSpaceScalers *)

			MoveLinearAbsolute_Blend3.Position := TestGroup[IDX_TestGroup002_Blend].Position;
			MoveLinearAbsolute_Blend3.Velocity := TestGroup[IDX_TestGroup002_Blend].Speed;
			MoveLinearAbsolute_Blend3.Acceleration :=TestGroup[IDX_TestGroup002_Blend].Acc;
			MoveLinearAbsolute_Blend3.Deceleration :=TestGroup[IDX_TestGroup002_Blend].Dec;
			MoveLinearAbsolute_Blend3.CoordSystem := TestGroup[IDX_TestGroup002_Blend].CoordSystem;
			MoveLinearAbsolute_Blend3.BufferMode := TestGroup[IDX_TestGroup002_Blend].BufferMode;
			MoveLinearAbsolute_Blend3.TransitionMode := TestGroup[IDX_TestGroup002_Blend].TransitionMode;
			MoveLinearAbsolute_Blend3.TransitionParameter := TestGroup[IDX_TestGroup002_Blend].TransitionParameter;
			MoveLinearAbsolute_Blend3.MoveOptions.VelocityUnit := TestGroup[IDX_TestGroup002_Blend].MoveOptions_VelocityUnit; (* VERY IMPORTANT *)(* UseNSpaceScalers *)

			(* DigitalInput := TestGroup[IDX_TestGroup002_Blend].Gripper; *)

			if VAR_FirstTime then
				IDX_TestGroup001_Blend := 101;	(*	State Machine 101 *)
			else
				IDX_TestGroup001_Blend := 100;	(*	It's first time *) (*	State Machine 100 *)
			end_if;

		100: 	(*	Execute Positioning *)
			if not(VAR_FirstTime) then
				VAR_FirstTime := true;
			end_if;
			MoveLinearAbsolute_Blend2.Execute := false;
			MoveLinearAbsolute_Blend3.Execute := false;
			MoveLinearAbsolute_Blend1.Execute := true;
			if MoveLinearAbsolute_Blend1.Active xor MoveLinearAbsolute_Blend1.Done then (*	Usually is used on "Active" bit, but if the actual position is equal of the command position, the bit Active doesn't get high, then we create the blend with the "Done" bit *)
				IDX_TestGroup001_Blend := 200; 	(*	go to state Wait For Delay *) (*	State Machine 200 *)
			end_if;

		101:	(*	First Time? *)	
				(*	 				 ________		 ________		 ________
									| BLEND1 |		| BLEND2 |		| BLEND3 |			
						________>___|		 |___>__|		 |___>__|		 |___>___
							|  100	|		 |	400	|		 |	500	|		 |	100	 |
							|		|________|		|________|		|________|		 |
							|														 |
							|														 |
							|___<________________<_______________<_______________<___|
				*)
			if MoveLinearAbsolute_Blend1.Execute then
				IDX_TestGroup001_Blend := 400;	(*	State Machine 400 *)
			elsif MoveLinearAbsolute_Blend2.Execute then
				IDX_TestGroup001_Blend := 500;	(*	State Machine 500 *)
			elsif MoveLinearAbsolute_Blend3.Execute then
				IDX_TestGroup001_Blend := 100;	(*	State Machine 100 *)
			end_if;

		200: 	(*	Wait For Delay (ticks releated to the communication cycle) *)
			IDX_Count001_Blend := IDX_Count001_Blend + 1;
			if IDX_Count001_Blend >= TestGroup[IDX_TestGroup002_Blend].Delay then
				IDX_Count001_Blend := 0;
				IDX_TestGroup001_Blend := 300;	(*	State Machine 300 *)
			end_if;

		300: 	(*	Increase The Index and check if the actual index is the last And Restart *)
			IDX_TestGroup002_Blend := IDX_TestGroup002_Blend + 1;	(*	Increase index of array *)
			if IDX_TestGroup002_Blend >= 1000 or TestGroup[IDX_TestGroup002_Blend].LastItem then	(*	Array Size *)
				IDX_TestGroup002_Blend := 0;
			end_if;
			TestLastItem := TestGroup[IDX_TestGroup002_Blend + 1].LastItem;
			IDX_TestGroup001_Blend := 0;	(*	State Machine 0 *)

		400: 	(*	Execute Positioning *)
				MoveLinearAbsolute_Blend1.Execute := false;
				MoveLinearAbsolute_Blend2.Execute := true;
				MoveLinearAbsolute_Blend3.Execute := false;
			if MoveLinearAbsolute_Blend2.Active xor MoveLinearAbsolute_Blend2.Done then (*	Usually is used on "Active" bit, but if the actual position is equal of the command position, the bit Active doesn't get high, then we create the blend with the "Done" bit *)
				(**)
				IDX_TestGroup001_Blend := 200;	(*	State Machine 200 *)
			end_if;

		500: 	(*	Execute Positioning *)
				MoveLinearAbsolute_Blend1.Execute := false;
				MoveLinearAbsolute_Blend2.Execute := false;
				MoveLinearAbsolute_Blend3.Execute := true;
			if MoveLinearAbsolute_Blend3.Active xor MoveLinearAbsolute_Blend3.Done then (*	Usually is used on "Active" bit, but if the actual position is equal of the command position, the bit Active doesn't get high, then we create the blend with the "Done" bit *)
				(**)
				IDX_TestGroup001_Blend := 200;	(*	State Machine 200 *)
			end_if;
	end_case;
else
	if STS_TestGroupRunningBlend then
		STS_TestGroupRunningBlend := false;
		MoveLinearAbsolute_Blend1.Execute := false;
		MoveLinearAbsolute_Blend2.Execute := false;
		MoveLinearAbsolute_Blend3.Execute := false;
	end_if;
	IDX_TestGroup001_Blend := 0;	(*	State Machine 0 *)
	IDX_Count001_Blend := 0;		(*	Reset variable for delay *)
	IDX_TestGroup002_Blend := 0;	(*	Reset index array *)
	VAR_FirstTime := false;
end_if;