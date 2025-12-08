const MyWorkchain: Bool = false;

const minTonsForStorage: Int = ton("0.01");

const gasForTransfer: Int = 10200;

const gasForBurn: Int = 7500;

const maxTotalSupply: Int = ton("21000000000");
const maxMintAmount: Int = ton("1000000000");
const maxTransferAmount: Int = ton("100000000");
const maxBurnAmount: Int = ton("1000000000");

const minTransferAmount: Int = ton("1000000");

const minTonForMint: Int = ton("1.0");
const minTonForTransfer: Int = ton("0.05");
const minTonForBurn: Int = ton("0.1");
const minTonForCallTo: Int = ton("0.2");

const maxMetadataSize: Int = 1000;
const maxForwardPayloadSize: Int = 500;

const maxCellRefs: Int = 2;
const maxCellBits: Int = 1023;