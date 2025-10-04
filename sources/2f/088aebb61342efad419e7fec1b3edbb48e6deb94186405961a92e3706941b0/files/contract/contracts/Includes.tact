// CONSTANTS
const maxBeneficiaries: Int = 20;
const gasForRegister: Int = 15000;
const gasForTransfer: Int = 10500;
const gasForWdEnable: Int = 10500;
const gasForWdSupplyExecutorGas: Int = 10500;
const gasForWdSupplyRolling: Int = 10500;
const gasForWdPayout: Int = 12500;
const gasForDepFundoutTon: Int = 15000;
const gasForDepFundout: Int = 15000;
const gasNanoForTransfer: Int = ton("0.04"); // https://docs.ton.org/v3/documentation/smart-contracts/transaction-fees/fees#fees-for-sending-jettons
const gasNanoForTonTransfer: Int = ton("0.0055"); //https://docs.ton.org/v3/documentation/smart-contracts/transaction-fees/fees#fees-for-sending-toncoin
const minTonsForStorage: Int = ton("0.01"); // This should use https://github.com/tact-lang/tact/issues/2336 in the future
const Basechain: Int = 0;
const depositStateInitCells: Int = 34; 
const depositStateInitBits: Int = 15096;
const withdrawStateInitCells: Int = 36;
const withdrawStateInitBits: Int = 16643;
const zeroAccount: Address = newAddress(0, 0x0000000000000000000000000000000000000000000000000000000000000000);

// MESSAGES 

message(0xce72f9b0) ClaimTON {


}
message(0x351e7f92) UpgradeDepositCode {
    depositContracts: map<Int as uint16, Address>;
    version: Int as uint32;
    value: Int as coins;
    queryId: Int as uint64;
}

message(0xa050bd14) UpgradeWithdrawCode {
    withdrawContracts: map<Int as uint16, Address>;
    version: Int as uint32;
    value: Int as coins;
    queryId: Int as uint64;
}

message(0x98dbc64f) AddNewMinter {
    queryId: Int as uint64;
    jettonMinter: Address;
    jettonWalletCode: Cell;
    dataLayoutId: Int;
}
message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x92e509d2) Register {
    queryId: Int as uint64;
    beneficiaries: map<Int as uint8, Address>;
    referral: Address;
}   

message(0x633ac051) RegisterInternal {
    queryId: Int as uint64;
    beneficiaries: map<Int as uint8, Address>;
    referral: Address;
    fees: Int as uint16;
    shareRevenue: Int as uint16;
    newCode: Cell?;
}


message(0x42f529d2) SetFees {
    queryId: Int as uint64;
    fees: Int as coins;
}   

message(0x3ff587d2) SetFeesInternal {
    queryId: Int as uint64;
    fees: Int as coins;
}

message(0x12e5fed1) SetShareRevenue {
    queryId: Int as uint64;
    shareRevenue: Int as coins;
}   

message(0x54981237) SetShareRevenueInternal {
    queryId: Int as uint64;
    shareRevenue: Int as coins;
}

message(0x2d8621a1) DepFundout {
    queryId: Int as uint64;
    jettonMinter: Address;
    beneficiaryIdxes: map<Int as uint8, Int as uint8>;
    amount: Int as coins;
}

message(0x15de600f) DepFundoutInternal {
    queryId: Int as uint64;
    jettonMinter: Address;
    depositJWallet:Address;
    wkCompany: Address;
    beneficiaryIdxes: map<Int as uint8, Int as uint8>;
    amount: Int as coins;
}

message(0xe8cdb672) DepFundoutTon {
    queryId: Int as uint64;
    beneficiaryIdxes: map<Int as uint8, Int as uint8>;
    amount: Int as coins;
}

message(0x1cb9d33a) DepFundoutTonInternal {
    queryId: Int as uint64;
    wkCompany: Address;
    beneficiaryIdxes: map<Int as uint8, Int as uint8>;
    amount: Int as coins;
}

message(0x383c10f4) SetSigners{
    queryId: Int as uint64;
    signers: map<Int as uint8, Int as uint256>;
}

message(0xc845a069) WdEnable  {
    queryId: Int as uint64;
    wdExecutor: Address;
    signature: Slice as bytes64;
}

message(0xc845a069) WdEnableInternal  {
    queryId: Int as uint64;
    wdExecutor: Address;
    newCode: Cell?;
}

message(0x956725d5) WdSupplyExecutorGas  {
    queryId: Int as uint64;
}

message(0x54891097) WdSupplyExecutorGasInternal {
    queryId: Int as uint64;
}

message(0xe75547f7) WdSupplyRollingTon {
    queryId: Int as uint64;
}


message(0x94abaac5) WdPayout {
    queryId: Int as uint64;
    jetton:Address; 
    recipients:map<Int as uint16, Address>;
    amounts:map<Int as uint16, Int as coins>;
    ids:map<Int as uint16, Int as uint256>;
    merchantExecutor:Address;
}

message(0x94abaac5) WdPayoutInternal {
    queryId: Int as uint64;
    jetton:Address; 
    recipients:map<Int as uint16, Address>;
    amounts:map<Int as uint16, Int as coins>;
    ids:map<Int as uint16, Int as uint256>;
    wdExecutor:Address;
    wdJWallet: Address;
}


// STRUCTS
struct WdSupplyRollingPayload {
    jettonMinter: Address;
}

struct WdEnableSignBody {
    sender: Address;
    contract:Address;
    wdExecutor: Address;
}

struct FactoryData {
    id: Int as uint32;
    owner: Address;
    version: Int as uint32;
    wkCompany: Address;
    shareRevenue: Int as uint16;
    fees: Int as uint16;
}

struct DepositData {
    owner: Address; //factory
    version: Int as uint32;
    merchant: Address;
    fees: Int as uint16;
    shareRevenue: Int as uint16;
    referral: Address;
    beneficiaries: map<Int as uint8, Address>;
}

struct WithdrawalData {
    owner: Address; //factory
    version: Int as uint32;
    merchant: Address;
}

asm fun _emptyAddress(): Address { b{00} PUSHSLICE }

// ===== cyclical array =====
struct CircularBuffer {
    // max size of the circular buffer
    max: Int = 0;
    
    // A circular buffer of Int values as a map of Ints to Ints,
    // with serialization of its keys to uint8 to save space
    m: map<Int as uint16, Int as uint256>;

    // Length of the circular buffer; defaults to 0
    length: Int = 0;

    // Current index into the circular buffer; defaults to 0
    start: Int = 0;
}

// Extension mutation function for putting new items into the circular buffer
extends mutates fun put(self: CircularBuffer, item: Int): Int {

    let res = 0;
    if (self.length < self.max) {
        self.m.set(self.length, item); // store the item
        self.length += 1; // increase the length field
    } else {
        res = self.m.get(self.start)!!;
        self.m.set(self.start, item); // store the item, overriding previous entry
        self.start = (self.start + 1) % self.max; // update starting position

        
    }

    return res;
}

// Extension mutation function for getting an item from the circular buffer
extends mutates fun getIdx(self: CircularBuffer, idx: Int): Int {
    require(self.length > 0, "No items in the circular buffer!");
    require(idx >= 0, "Index of the item cannot be negative!");

    if (self.length < self.max) {
        // Note that we use the !! operator as we know for sure that the value will be there
        return self.m.get(idx % self.length)!!;
    }

    // Return the value rotating around the circular buffer, also guaranteed to be there
    return self.m.get((self.start + idx) % self.max)!!;
}

// Extension function for iterating over all items in the circular buffer and dumping them to the console
extends fun printAll(self: CircularBuffer) {
    let i: Int = self.start;
    repeat (self.length) {
        dump(self.m.get(i)!!); // !! tells the compiler this can't be null
        i = (i + 1) % self.max;
    }
}

// Extension function for deleting all items from the CircularBuffer
extends mutates fun deleteAll(self: CircularBuffer) {
    self.m = emptyMap();
    self.length = 0;
    self.start = 0;
}

// Global static function for creating an empty CircularBuffer
inline fun _emptyCircularBuffer(max: Int): CircularBuffer {
    // Length and start default to 0
    return CircularBuffer { max: max, m: emptyMap(), length: 0, start: 0 };
}

inline fun _transferTonFromContract(to:Address, queryId:Int, amount:Int) {
    message(MessageParameters {
        bounce: false, 
        to: to,
        value: amount,
        mode: SendPayGasSeparately | SendIgnoreErrors,
    });
}
inline fun _transferFromContract(to:Address, queryId: Int, amount: Int, destination: Address, cashback:Address, value: Int ) {
    message(MessageParameters {
        bounce: true, /* let ton stay in caller */
        to: to,
        value: value, 
        body: JettonTransfer { 
            queryId: queryId,
            amount: amount,
            destination: destination,
            responseDestination: cashback, // cashback destination
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: beginCell().storeUint(0, 1).asSlice(),
        }.toCell(),
        mode: SendIgnoreErrors,
    });   
}

inline fun _jettonWalletAddress(dataLayoutId: Int, code: Cell, minter: Address, owner: Address): Address {

    let data:Cell = emptyCell();

    if (dataLayoutId == 0) { 
        // usdt
        data = beginCell()
            .storeUint(0,4)
            .storeCoins(0)
            .storeAddress(owner)
            .storeAddress(minter)
            .endCell();
    } else { 
        // local
        data = beginCell()
            .storeAddress(owner)
            .storeAddress(minter)
            .storeCoins(0)  
            .endCell();
    }

    return contractAddressExt(0, code, data);
}   
