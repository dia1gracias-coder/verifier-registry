import "./structs.tact";

// ------------------ FtMaster ------------------ //

message SetupMaster{

}

message SetupJoinPrice{
    newJoinPrice: Int as coins;
}

message SetupSquadPrice{
    newSquadPrice: Int as coins;
}

message UpdateProgramAddress{
    programIndex: Int as uint8;
    programAddress: Address;
}

message GiftJoin{
    userAddress: Address;
    invitedId: Int as uint64;
}

message Join{
    userAddress: Address?;
    invitedId: Int as uint64;
}

message CreateSquad{
    owner: Address?;
}

message ProgramAddresses{
    programs: map<Int as uint8, Address>;
}


// ------------------------ FtSquad ------------------ //

message PayForSquadCreation{
    receiver: Address;
    price: Int as coins;
}


// ------------------ FtUserStorage ------------------ //

message SetupUserStorage{
    userId: Int as uint64;
    forwardPayload: Cell;
}

message VerifyExistence{
    invitedId: Int as uint64;
}

// ------------------ FtUserMain ------------------ //

message SetupUserMain{
    owner: Address;
    invitedId: Int as uint64;
    programs: map<Int as uint8, Address>;
}

message AddReferral{
    userId: Int as uint64;
    userAddress: Address;
}

message Buy{
    programId: Int as uint8;
    levelNumber: Int as uint8;
}

message (0x61ca6eeb) GetInvitedId{
    forwardPayload: Cell;
}

message (0x985aee35) UpdateInvitedId{
    invitedId: Int as uint64;
    forwardPayload: Cell;
}

// ------------------ FtBaseProgramMain ------------------ //

message SetupBaseProgramMain{
    owner: Address;
}

message (0xd587100b) BuyLevel{
    owner: Address;
    userId: Int as uint64;
    invitedId: Int as uint64;
    levelNumber: Int as uint8;
    recipientExcesses: Address;
}

message UpdateLevelPrice{
    levelNumber: Int as uint8;
    levelPrice: Int as coins;
}

message UpdateLevelFee{
    levelNumber: Int as uint8;
    levelFee: Int as coins;
}

message UpdateGasMultiplier{
    newValue: Int as coins;
}

message UpdateRecipientAddress{
    newAddress: Address;
}

// ------------------ FtBaseProgramUser ------------------ //

message(0xb5b23017) ActivateLevel{
    owner: Address;
    invitedId: Int as uint64;
    levelNumber: Int as uint8;
    levelPrice: Int as coins;
    recipientExcesses: Address;
}

message(0x974dd3f0) UpdateMatrix{
    id: Int as uint64;
    fromId: Int as uint64;
    levelNumber: Int as uint8;
    levelPrice: Int as coins;
    recipientExcesses: Address;
}

message(0x8a0257f4) OverflowDown{
    id: Int as uint64;
    fromId: Int as uint64;
    levelNumber: Int as uint8;
    levelPrice: Int as coins;
    recipientExcesses: Address;
}

message(0x390258fe) OverflowUp{
    id: Int as uint64;
    fromId: Int as uint64;
    levelNumber: Int as uint8;
    levelPrice: Int as coins;
    recipientExcesses: Address;
}

message(0x9472532d) Gift{
    id: Int as uint64;
    fromId: Int as uint64;
    levelPrice: Int as coins;
    recipientExcesses: Address;
}

message(0x399aaa57) UpdateUpperAddress{
    fromId: Int as uint64;
    upperAddress: Address;
    levelNumber: Int;
    recipientExcesses: Address;
}

// ------------------ FtBaseProgramUser - emit ------------------ //

message(0x52afa0af) Overtook{
    levelNumber: Int as uint8;
    newValue: Int as uint16;
}

message(0xcc565556) ReinvestNumber{
    reinvestNumber: Int as uint16;
    statusCode: Int? as uint8;
}

message(0xf0f50a5) FinishCycle{
    matrix: Matrix;
    levelNumber: Int as uint8;
    reinvestNumber: Int as uint16;
}

// FOR TEST

message MakeUpperAddressNull{
    levelNumber: Int as uint8;
}
