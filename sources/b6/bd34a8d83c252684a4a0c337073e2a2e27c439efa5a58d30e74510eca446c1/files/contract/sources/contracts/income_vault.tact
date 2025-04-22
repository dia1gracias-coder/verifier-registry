import "@stdlib/ownable";
import "@stdlib/deploy";
import "./messages.tact";


contract IncomeVault with Deployable, Ownable {
    owner: Address;
    box_manager: Address?;
    gas_required: Int as coins;

    init (owner: Address) {
        require(sender() == owner, "Only owner allowed");
        self.owner = owner;
        self.box_manager = null;
        self.gas_required = ton("0.01");
    }

    fun onlyBoxManager() {
        require(self.box_manager != null, "Box Manager not set");
        require(sender() == self.box_manager, "Only for Box Manager");
    }

    fun checkTonValue(expected: Int) {
        let ctx: Context = context();
        require(ctx.value >= self.gas_required + expected, "Not enough TON [checkTonValue]");
    }

    fun checkTonBalance(expected: Int) {
        require(myBalance() >= self.gas_required + expected, "Not enough TON [checkTonBalance]");
    }

    get fun getVaultData(): VaultData {
        return VaultData {
            owner: self.owner,
            box_manager: self.box_manager,
            gas_required: self.gas_required,
            balance: myBalance(),
        }
    }

    fun reserveTonValue(expected: Int) {
        let ctx: Context = context();
        nativeReserve(myBalance() - ctx.value + expected, ReserveExact);
    }

    receive(msg: SetBoxManager) {
        self.requireOwner();
        self.box_manager = msg.box_manager;
        send(SendParameters {
            bounce: false,
            to: sender(),
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
        });
    }

    receive(msg: PayForBoxConfirm) {
        self.onlyBoxManager();
        self.checkTonValue(msg.box_price);
        self.reserveTonValue(msg.box_price);
        
        emit(msg.toCell());
        
        send(SendParameters {
            bounce: false,
            to: msg.initiator,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive(msg: ClaimIncomeConfirm) {
        self.onlyBoxManager();
        self.checkTonBalance(msg.amount);
        
        send(SendParameters {
            bounce: false,
            to: msg.initiator,
            value: msg.amount,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: "Here is your Income!".asComment(),
        });

        emit(msg.toCell());
    }

}