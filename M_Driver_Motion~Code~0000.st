// Centralized "Switchboard" to route parameters to the correct FB
CASE iBlockID OF
    1: // --- MAPPING FOR BLOCK 1 ---        
        MoveLinearAbsolute_Blend1.Position[1] := fX;
		MoveLinearAbsolute_Blend1.Position[2] := fY;
		MoveLinearAbsolute_Blend1.Position[3] := fZ;
		MoveLinearAbsolute_Blend1.Position[4] := fRx; 
		MoveLinearAbsolute_Blend1.Position[5] := fRy; 
		MoveLinearAbsolute_Blend1.Position[6] := fRz;
		MoveLinearAbsolute_Blend1.Velocity := fVel;
		MoveLinearAbsolute_Blend1.Acceleration := fAcc;
		MoveLinearAbsolute_Blend1.Deceleration := fDec;
		MoveLinearAbsolute_Blend1.CoordSystem := eCoordSys;
		MoveLinearAbsolute_Blend1.BufferMode := eBufferMode;
		MoveLinearAbsolute_Blend1.TransitionMode := eTransMode;
		MoveLinearAbsolute_Blend1.TransitionParameter[param] := aTransParam;
		MoveLinearAbsolute_Blend1.MoveOptions := stMoveOption;
		MoveLinearAbsolute_Blend1.Execute := bExecute;

    2: // --- MAPPING FOR BLOCK 2 ---
        MoveLinearAbsolute_Blend2.Position[1] := fX;
		MoveLinearAbsolute_Blend2.Position[2] := fY;
		MoveLinearAbsolute_Blend2.Position[3] := fZ;
		MoveLinearAbsolute_Blend2.Position[4] := fRx; 
		MoveLinearAbsolute_Blend2.Position[5] := fRy; 
		MoveLinearAbsolute_Blend2.Position[6] := fRz;
		MoveLinearAbsolute_Blend2.Velocity := fVel;
		MoveLinearAbsolute_Blend2.Acceleration := fAcc;
		MoveLinearAbsolute_Blend2.Deceleration := fDec;
		MoveLinearAbsolute_Blend2.CoordSystem := eCoordSys;
		MoveLinearAbsolute_Blend2.BufferMode := eBufferMode;
		MoveLinearAbsolute_Blend2.TransitionMode := eTransMode;
		MoveLinearAbsolute_Blend2.TransitionParameter[param] := aTransParam;
		MoveLinearAbsolute_Blend2.MoveOptions := stMoveOption;
		MoveLinearAbsolute_Blend2.Execute := bExecute;

    3: // --- MAPPING FOR BLOCK 3 ---
        MoveLinearAbsolute_Blend3.Position[1] := fX;
		MoveLinearAbsolute_Blend3.Position[2] := fY;
		MoveLinearAbsolute_Blend3.Position[3] := fZ;
		MoveLinearAbsolute_Blend3.Position[4] := fRx; 
		MoveLinearAbsolute_Blend3.Position[5] := fRy; 
		MoveLinearAbsolute_Blend3.Position[6] := fRz;
		MoveLinearAbsolute_Blend3.Velocity := fVel;
		MoveLinearAbsolute_Blend3.Acceleration := fAcc;
		MoveLinearAbsolute_Blend3.Deceleration := fDec;
		MoveLinearAbsolute_Blend3.CoordSystem := eCoordSys;
		MoveLinearAbsolute_Blend3.BufferMode := eBufferMode;
		MoveLinearAbsolute_Blend3.TransitionMode := eTransMode;
		MoveLinearAbsolute_Blend3.TransitionParameter[param] := aTransParam;
		MoveLinearAbsolute_Blend3.MoveOptions := stMoveOption;
		MoveLinearAbsolute_Blend3.Execute := bExecute;

    4: // --- MAPPING FOR BLOCK 4 ---
        MoveLinearAbsolute_Blend4.Position[1] := fX;
		MoveLinearAbsolute_Blend4.Position[2] := fY;
		MoveLinearAbsolute_Blend4.Position[3] := fZ;
		MoveLinearAbsolute_Blend4.Position[4] := fRx; 
		MoveLinearAbsolute_Blend4.Position[5] := fRy; 
		MoveLinearAbsolute_Blend4.Position[6] := fRz;
		MoveLinearAbsolute_Blend4.Velocity := fVel;
		MoveLinearAbsolute_Blend4.Acceleration := fAcc;
		MoveLinearAbsolute_Blend4.Deceleration := fDec;
		MoveLinearAbsolute_Blend4.CoordSystem := eCoordSys;
		MoveLinearAbsolute_Blend4.BufferMode := eBufferMode;
		MoveLinearAbsolute_Blend4.TransitionMode := eTransMode;
		MoveLinearAbsolute_Blend4.TransitionParameter[param] := aTransParam;
		MoveLinearAbsolute_Blend4.MoveOptions := stMoveOption;
		MoveLinearAbsolute_Blend4.Execute := bExecute;
		
END_CASE			
			