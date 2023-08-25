struct Balance {
	starting: Int as coins;
	current: Int as coins;
}

struct HolderDto {
	address: Address;
	starting: Int as coins;
}

struct HolderInfo {
	common: Int as coins;
	current: Int as coins;
	available: Int as coins;
	currentPeriod: Period?;
}

struct Period {
	startTime: Int as uint32;
	percent: Int as uint16;
}

struct PeriodsSet {
	count: Int as uint8;
	periods: map<Int, Period>;
}