import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

struct ReserveConfiguration {
    // token addresses
    lTokenAddress: Address;
    dTokenAddress: Address;

    // liquidation configuration
    ltv: Int as uint16;
    liquidationThreshold: Int as uint16;
    liquidationBonus: Int as uint16;
    reserveFactor: Int as uint16;
    liquidationProtocolFee: Int as uint16;

    // interest rate configuration
    optimalUsageRatio: Int as uint16;
    slope1: Int as uint16;
    slope2: Int as uint16;

    // supply and borrow configuration
    borrowingEnabled: Bool;
    supplyCap: Int as uint32;
    borrowCap: Int as uint32;
}

// Warning: The struct value must fit in a cell or the compiler will throw an error
// So we have to split the reserve configuration out
struct ReserveData {
    liquidityIndex: Int as uint128;
    borrowIndex: Int as uint128;
    totalSupply: Int as coins;
    availableLiquidity: Int as coins;
    accruedToTreasury: Int as coins;
    totalBorrow: Int as coins;
    lastUpdateTimestamp: Int as uint32;
}

// TODO: update the message id
message(0x66660001) AddReserve {
    reserveAddress: Address;
    reserveConfiguration: ReserveConfiguration;
}

// TODO: update the message id
message(0x66660002) DropReserve {
    reserveIndex: Int as uint16;
}

contract Pool with Deployable, Ownable, Resumable {

    owner: Address;
    stopped: Bool;

    reserves: map<Int, Address>;
    reservesLength: Int = 0;
    reservesData: map<Address, ReserveData>;
    reservesConfiguration: map<Address, ReserveConfiguration>;

    init() {
        self.owner = sender();
        self.stopped = false;
    }

    receive(msg: AddReserve) {
        self.requireOwner();
        self.requireNotStopped();
        self.addReserve(msg.reserveAddress, msg.reserveConfiguration);
        self.reply("Reserve added".asComment());
    }

    receive(msg: DropReserve) {
        self.requireOwner();
        self.requireNotStopped();
        self.dropReserve(msg.reserveIndex);
        self.reply("Reserve dropped".asComment());
    }

    fun addReserve(reserveAddress: Address, reserveConfiguration: ReserveConfiguration) {
        self.validateAddReserve(reserveAddress, reserveConfiguration);
        let now: Int = now();
        let newReserveData: ReserveData = ReserveData{
        liquidityIndex: 1,
        borrowIndex: 1,
        totalSupply: 0,
        availableLiquidity: 0,
        accruedToTreasury: 0,
        totalBorrow: 0,
        lastUpdateTimestamp: now
        };
        self.reserves.set(self.reservesLength, reserveAddress);
        self.reservesConfiguration.set(reserveAddress, reserveConfiguration);
        self.reservesData.set(reserveAddress, newReserveData);
        self.reservesLength += 1;
    }

    fun dropReserve(reserveIndex: Int) {
        require(reserveIndex < self.reservesLength, "Reserve index out of bounds");
        let reserveAddress: Address = self.reserves.get(reserveIndex)!!;
        let reserveData: ReserveData = self.reservesData.get(reserveAddress)!!;
        let reserveConfiguration: ReserveConfiguration = self.reservesConfiguration.get(reserveAddress)!!;

        self.validateDropReserve(reserveData);
        let lastReserveIndex: Int = self.reservesLength - 1;
        let lastReserveAddress: Address =  self.reserves.get(lastReserveIndex)!!;
        self.reserves.set(reserveIndex, lastReserveAddress);
        self.reserves.set(lastReserveIndex, null);
        self.reservesData.set(reserveAddress, null);
        self.reservesConfiguration.set(reserveAddress, null);
        self.reservesLength -= 1;
    }

    fun validateAddReserve(reserveAddress: Address, reserveConfiguration: ReserveConfiguration) {
        // TODO: add more validation on reserveConfiguration as required
        let existingReserveData: ReserveData? = self.reservesData.get(reserveAddress);
        require(existingReserveData == null, "Reserve already exists");
    }

    fun validateDropReserve(reserveData: ReserveData) {
        require(reserveData.accruedToTreasury == 0, "Treasury share not zero");
        require(reserveData.totalSupply == 0, "Liability not zero");
        require(reserveData.totalBorrow == 0, "Debt not zero");
    }

    // ===== Get functions =====
    get fun reservesLength(): Int {
        return self.reservesLength;
    }

    get fun reserves(): map<Int, Address> {
        return self.reserves;
    }

    get fun reserveAddress(reserveIndex: Int): Address {
        return self.reserves.get(reserveIndex)!!;
    }

    get fun reserveData(reserveAddress: Address): ReserveData {
        return self.reservesData.get(reserveAddress)!!;
    }

    get fun reserveConfiguration(reserveAddress: Address): ReserveConfiguration {
        return self.reservesConfiguration.get(reserveAddress)!!;
    }
}
