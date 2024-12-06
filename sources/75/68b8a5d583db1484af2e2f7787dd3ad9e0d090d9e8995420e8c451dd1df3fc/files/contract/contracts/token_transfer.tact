import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";
import "./jetton_default_wallet.tact";
import "./messages.tact";

// const codeForwardPayloadInvalid: Int = 50007;
// const codeAmountMustBePositive: Int = 50303;
const codeInsufficientAmountForTransaction: Int = 50001;

// Jetton transfer gas
const JettonTransferGas: Int = ton("0.5");
const MinimalGas: Int = ton("0.01");

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;
    walletCode: Cell;
}

// put StakeJetton as the forwardPayload in TokenTransfer.
// and the forwardAmount of TokenTransfer should be greater than
// the sum of the tonAmount and forwardAmount of StakeJetton.
struct DepositJetton {
    tonAmount: Int as coins;
    tokenTransferJettonWallet: Address; 
    // address to send the response to
    responseDestination: Address;
    // amount of TON to forward
    forwardAmount: Int as coins;
    // payload to forward
    forwardPayload: Cell?;
}

// helpers
fun calculateJettonWalletAddress(
    ownerAddress: Address,
    jettonMasterAddress: Address,
    jettonWalletCode: Cell
): Address {
    let initData = JettonWalletData {
        balance: 0,
        owner: ownerAddress,
        master: jettonMasterAddress,
        walletCode: jettonWalletCode
    };

    return contractAddress(StateInit {
        code: jettonWalletCode,
        data: initData.toCell()
    })
}

contract BitgiftyTokenTransfer with 
    Deployable, 
    Resumable,
{
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    owner: Address;
    master: Address;
    stopped: Bool;
    internalJettonAmount: Int as coins = 0;

    receivedJettons: map<Address, ReceivedJettonInfo> = emptyMap();

    init(master: Address, owner: Address) {
        self.owner = owner; // Set super admin as the owner
        self.master = master;  // set master address
        self.stopped = false; // set stop state
    }

    receive() {}

    receive(msg: Deposit) {
        self.requireNotStopped();

        send(SendParameters{
            to: self.master(),
            bounce: true,
            value: msg.amount,
            mode: SendRemainingValue + SendIgnoreErrors,
        })
    }

    receive(msg: TransferNotification) {
       self. receiveTransferNotification(msg);
    }

    fun receiveTransferNotification(msg: TransferNotification) {
        let ctx = context();
        nativeThrowUnless(codeForwardPayloadInvalid, msg.forwardPayload != null);
        nativeThrowUnless(codeDepositAmountShouldBePositive, msg.amount >= 0);

        let depositMsg = DepositJetton.fromCell(msg.forwardPayload!!);
        nativeThrowUnless(codeInflowValueNotSufficient,
            ctx.value > depositMsg.tonAmount + depositMsg.forwardAmount + self.gasConsumption + MinimalGas);
        nativeThrowUnless(codeDepositAmountShouldBePositive, depositMsg.tonAmount >= 0);
        
        // transfer jettons from contract to master
        send(SendParameters{
            to: depositMsg.tokenTransferJettonWallet,
            value: JettonTransferGas,
            body: TokenTransfer {
                // To prevent replay attacks
                queryId: msg.queryId,
                // Jetton amount to transfer
                amount: msg.amount,
                // Where to transfer Jettons:
                // this is an address of the Jetton wallet
                // owner and not the Jetton wallet itself
                destination: self.master(),
                // Where to send a confirmation notice of a successful transfer
                // and the rest of the incoming message value
                responseDestination: myAddress(),
                // Can be used for custom logic of Jettons themselves,
                // and without such can be set to null
                customPayload: null,
                // Amount to transfer with JettonTransferNotification,
                // which is needed for the execution of custom logic
                forwardAmount: depositMsg.forwardAmount, // if its 0, the notification won't be sent!
                // Compile-time way of expressing:
                //     beginCell().storeUint(0xF, 4).endCell().beginParse()
                // For more complicated transfers, adjust accordingly
                forwardPayload: depositMsg.forwardPayload,
            }.toCell(),
        });
    }

    // change master address
    receive(msg: ChangeMaster) {
        dump(msg.newMaster);

        self.requireOwner();
        self.requireNotStopped();

        self.master = msg.newMaster;
        emit("Master changed".asComment());
    }
    

    // Return the currently set master address
    get fun master(): Address {
        return self.master;
    }

    // Modifiers
    fun notMasterOrOwner() {
        let ctx: Context = context();

        require(ctx.sender != self.master, "Invaid sender");
        require(ctx.sender != self.owner, "Invalid sender")
    }

    get fun balance(): String {
        return myBalance().toCoinsString()
    }

    // receive("Resume") is added automatically to allow owner to resume the contract
    // receive("Stop") is added automatically to allow owner to stop the contract
    // get fun stopped(): Bool is added automatically to query if contract is stopped
    // get fun owner(): Address is added automatically to query who the owner is
}
