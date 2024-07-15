import "@stdlib/ownable";
import "./constants/Error.tact";
import "./messages/Vesting.tact";
import "./traits/Valuable.tact";

struct VestingWalletData {
    totalAmount: Int;      // Total amount of vested jettons
    releasableAmount: Int; // Releasable amount of jettons
    releasedAmount: Int;   // Released amount of jettons
    owner: Address;        // Vesting wallet's owner
    master: Address;       // Master contract bound to the vesting wallet
    start: Int;            // Vesting start timestamp (in seconds)
    end: Int;              // Vesting end timestamp (in seconds)
    duration: Int;         // Vesting duration (in seconds)
}

/**
 * @dev This contract implements the vesting wallet for Hero Coin. The contract's
 * implementation is based on a linear vesting curve.
 *
 * It is used to release vested jettons for specific users and to provide vesting
 * information.
 */
contract HeroVestingWallet with Ownable, Valuable {
    totalAmount: Int as coins;
    releasedAmount: Int as coins;
    owner: Address;
    master: Address;
    start: Int as uint32;
    duration: Int as uint32;

    /**
     * @dev Initializes the contract with the following parameters:
     * - `master` is the master contract address.
     * - `owner` is the owner address of the current contract.
     */
    init(master: Address, owner: Address) {
        self.totalAmount = 0;
        self.releasedAmount = 0;
        self.owner = owner;
        self.master = master;
        self.start = 0;
        self.duration = 0;
    }

    /**
     * @dev Handles a message to vest jettons from the master contract address to the
     * recipient's vesting wallet address. 
     *
     * It is allowed to add multiple amounts of jettons on the current vesting wallet.
     * However vesting start and duration timestamps won't be affected unless a `force`
     * flag is set to `true` in the incoming message.
     * 
     * Requirements:
     * - The sender is restricted to the master contract address.
     * - A vesting start timestamp must be a non zero value.
     * - A vesting duration must be a non zero value.
     * 
     * Actions:
     * - Sends the Excesses message with remaining Toncoins to the vesting initiator.
     */
    receive(msg: InternalVest) {
        let ctx: Context = context();
        nativeThrowUnless(ERROR_CODE_ACCESS_DENIED, ctx.sender == self.master);

        let force: Bool = msg.force == null ? false : msg.force!!;
        if (force || self.start == 0) {
            require(msg.start != 0, "Internal Vest: Zero start");
            self.start = msg.start;
        }
        if (force || self.duration == 0) {
            require(msg.duration != 0, "Internal Vest: Zero duration");
            self.duration = msg.duration;
        }

        self.totalAmount += msg.amount;

        let value: Int = self.getRemainingValue(ctx.value) - ctx.readForwardFee();
        if (value > 0) {
            send(SendParameters {
                to: msg.response_destination, 
                value: value,  
                mode: SendIgnoreErrors,
                bounce: false,
                body: Excesses { 
                    query_id: msg.query_id
                }.toCell()
            });
        }
    }

    /**
     * @dev Handles a message to release an amount of jettons for a given address. 
     * 
     * Requirements:
     * - The sender is restricted to the owner of the vesting wallet.
     * - An amount of claimed jettons must be below their releasable amount.
     * - A final released amount must be below the total amount stored on the
     *   current vesting wallet.
     *
     * Actions:
     * - Sends the Mint message to the master contract.
     */
    receive(msg: Release) {
        self.requireOwner();

        let amount: Int = self.releasableAmount();
        require(msg.amount <= amount, "Release: Too high message amount");

        self.releasedAmount += msg.amount;
        require(self.releasedAmount <= self.totalAmount, "Release: Too high released amount");

        send(SendParameters{
            to: self.master,
            value: 0, 
            mode: SendRemainingValue,
            bounce: true,
            body: Mint{ 
                query_id: msg.query_id,
                amount: msg.amount,
                to: self.owner,
                response_destination: self.owner,
            }.toCell(),
        });
    }
    
    /**
     * @dev Handles the bounced Mint message.
     */
    bounced(msg: bounced<Mint>) {
        self.releasedAmount -= msg.amount;
    }

    /**
     * @dev Gets a releable amount of jettons.
     */
    get fun releasableAmount(): Int {
        let amount: Int = self.vestedAmount(now()) - self.releasedAmount;
        return amount > 0 ? amount : 0;
    }

    /**
     * @dev Gets an amount of jettons that has already vested. The implementation is
     * based on a linear vesting curve.
     */
    get fun vestedAmount(timestamp: Int): Int {
        if (self.start == 0 || self.duration == 0 || timestamp < self.start) {
            return 0;
        }
        if (timestamp >= self.end()) {
            return self.totalAmount;
        }

        return self.totalAmount * (timestamp - self.start) / self.duration;
    }

    /**
     * @dev Gets the vesting end timestamp.
     */
    get fun end(): Int {
        return self.start + self.duration;
    }

    /**
     * @dev Get the vesting information.
     */
    get fun vestingData(): VestingWalletData {
        return VestingWalletData{
            totalAmount: self.totalAmount,
            releasableAmount: self.releasableAmount(),
            releasedAmount: self.releasedAmount,
            owner: self.owner,
            master: self.master,
            start: self.start,
            end: self.end(),
            duration: self.duration,
        };
    }
}
