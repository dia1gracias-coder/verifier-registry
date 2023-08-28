message PutHoldersMsg {
	count: Int as uint8;
	holders: map<Int as uint8, HolderDto>;
}

message SetPeriodsMsg {
	count: Int as uint8;
	percentFactor: Int;
	periods: map<Int, Period>;
}

message SetOwnerWallet {
	address: Address;
}

message SetVestingRound {
	vestingRound: Int as uint8;
}

message TopupBalance {}