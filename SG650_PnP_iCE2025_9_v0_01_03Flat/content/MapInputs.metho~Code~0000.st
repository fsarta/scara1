// --- Byte 0: Status_Bits ---
stInput.Status_Bits.Ready           := (Visor_Receive[0] AND BYTE#1) <> 0;
stInput.Status_Bits.Spare0_1        := (Visor_Receive[0] AND BYTE#2) <> 0;
stInput.Status_Bits.TriggerAck      := (Visor_Receive[0] AND BYTE#4) <> 0;
stInput.Status_Bits.ChangeJobAck    := (Visor_Receive[0] AND BYTE#8) <> 0;
stInput.Status_Bits.SwitchToRunAck  := (Visor_Receive[0] AND BYTE#16) <> 0;
stInput.Status_Bits.Spare0_5        := (Visor_Receive[0] AND BYTE#32) <> 0;
stInput.Status_Bits.Spare0_6        := (Visor_Receive[0] AND BYTE#64) <> 0;
stInput.Status_Bits.Spare0_7        := (Visor_Receive[0] AND BYTE#128) <> 0;

// --- Byte 1: Spare ---
stInput.Spare_Byte1                 := Visor_Receive[1];

// --- Byte 2-7: Dati di Stato ---
stInput.DigitalResults              := Visor_Receive[2];
stInput.JobNumber                   := TO_USINT(Visor_Receive[3]); // USINT
stInput.ImageId                     := TO_USINT(Visor_Receive[4]); // USINT
stInput.Status_Byte5                := Visor_Receive[5];
stInput.Data_ImageId                := TO_USINT(Visor_Receive[6]); // USINT
stInput.DataStatus_Byte7            := Visor_Receive[7];

// --- Byte 8-39: ResultData ---
//stInput.ResultData.Part_Index       := FC_BytesToInt(Visor_Receive[8], Visor_Receive[9]);
//stInput.ResultData.Part_Type        := FC_BytesToInt(Visor_Receive[10], Visor_Receive[11]);
stInput.ResultData.Pos_X[0]         := FC_BytesToReal(Visor_Receive[8], Visor_Receive[9], Visor_Receive[10], Visor_Receive[11]);
stInput.ResultData.Pos_X[1]         := FC_BytesToReal(Visor_Receive[12], Visor_Receive[13], Visor_Receive[14], Visor_Receive[15]);
stInput.ResultData.Pos_X[2]         := FC_BytesToReal(Visor_Receive[16], Visor_Receive[17], Visor_Receive[18], Visor_Receive[19]);
stInput.ResultData.Pos_X[3]         := FC_BytesToReal(Visor_Receive[20], Visor_Receive[21], Visor_Receive[22], Visor_Receive[23]);

stInput.ResultData.Pos_Y[0]         := FC_BytesToReal(Visor_Receive[24], Visor_Receive[25], Visor_Receive[26], Visor_Receive[27]);
stInput.ResultData.Pos_Y[1]         := FC_BytesToReal(Visor_Receive[28], Visor_Receive[29], Visor_Receive[30], Visor_Receive[31]);
stInput.ResultData.Pos_Y[2]         := FC_BytesToReal(Visor_Receive[32], Visor_Receive[33], Visor_Receive[34], Visor_Receive[35]);
stInput.ResultData.Pos_Y[3]         := FC_BytesToReal(Visor_Receive[36], Visor_Receive[37], Visor_Receive[38], Visor_Receive[39]);

stInput.ResultData.Angle_Rz[0]      := FC_BytesToReal(Visor_Receive[40], Visor_Receive[41], Visor_Receive[42], Visor_Receive[43]);
stInput.ResultData.Angle_Rz[1]      := FC_BytesToReal(Visor_Receive[44], Visor_Receive[45], Visor_Receive[46], Visor_Receive[47]);
stInput.ResultData.Angle_Rz[2]      := FC_BytesToReal(Visor_Receive[48], Visor_Receive[49], Visor_Receive[50], Visor_Receive[51]);
stInput.ResultData.Angle_Rz[3]      := FC_BytesToReal(Visor_Receive[52], Visor_Receive[53], Visor_Receive[54], Visor_Receive[55]);

stInput.ResultData.Part_Count       := Visor_Receive[56];

