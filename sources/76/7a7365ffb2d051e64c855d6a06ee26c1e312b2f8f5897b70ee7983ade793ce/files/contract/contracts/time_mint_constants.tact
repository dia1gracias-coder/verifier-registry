// TON NFT standard opcodes.
const OwnershipAssigned: Int = 0x05138d91;
const Excesses: Int = 0xd53276db;
const ReportStaticData: Int = 0x8b771735;

// TimeMint application opcodes.
const SalePayment: Int = 0x746d7061; // "tmpa"

// Exit codes.
const IncorrectSender: Int = 401;
const IncorrectIndex: Int = 402;
const IncorrectForwardPayload: Int = 708;
const InvalidDestinationWorkchain: Int = 333;
const InvalidData: Int = 65535;
const NotInit: Int = 9;
const InvalidFees: Int = 410;
const YearClosed: Int = 420;
const InvalidYearConfig: Int = 421;
const SlotOutOfRange: Int = 422;
const SlotAlreadyMinted: Int = 423;
const QuoteExpired: Int = 424;
const InvalidQuote: Int = 425;
const InvalidMintOwner: Int = 426;
const InsufficientValue: Int = 427;

// Storage and encoding constants.
const minTonsForStorage: Int = ton("0.05");
const IndexSizeBits: Int = 64;
const MaxMinuteSlotsPerLeapYear: Int = 366 * 24 * 60;
