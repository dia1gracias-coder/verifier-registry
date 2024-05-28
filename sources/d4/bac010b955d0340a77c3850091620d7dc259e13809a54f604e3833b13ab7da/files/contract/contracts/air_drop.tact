import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

message ChangeJettonWallet {
    address: Address;
}

message GetAnonToken {
    secret_bool: Bool;

}

message ChangeTotalValue {
    totalValue: Int as coins;
}

message ChangeJettonAmount {
    jettonsToDrop: Int as coins;
}

message ChangeMinTonsToDrop {
    minTonsToDrop: Int as coins;
}

message ClearMap {

}

// MARK: TEP64 Standard: Jetton Messages
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address; // not jetton wallet
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

contract AirDrop with Deployable, OwnableTransferable, Resumable {
    id: Int as uint32;
    totalValue: Int as coins;
    currentValue: Int as coins;
    jettonsToDrop: Int as coins;
    minTonsToDrop: Int as coins;
    jettonWallet: Address?;
    usedWallets:  map<Address, Bool>;
    walletsCount: Int as uint16;
    stopped: Bool;

    // Owner of the contract
    owner: Address;

    init(id: Int, airdropValue: Int, jettonsToDrop: Int, minTonsToDrop: Int) {
        self.id = id;
        self.totalValue = airdropValue;
        self.currentValue = airdropValue;
        self.owner = sender();
        self.jettonsToDrop = jettonsToDrop;
        self.minTonsToDrop = minTonsToDrop;
        self.walletsCount = 0;
        self.stopped = false;
    }

    receive(msg: TokenExcesses)
    {

    }

    receive(msg: GetAnonToken) {
        require(self.jettonWallet != null, "No jettons");
        require(context().value >= self.minTonsToDrop, "Amount is too small");

        self.requireNotStopped();
        require(msg.secret_bool, "Secret is not correct");

        require(self.currentValue >= self.jettonsToDrop, "Not enough jettons");
        require(self.usedWallets.get(sender()) == null, "This walled is used");

        self.currentValue = self.currentValue - self.jettonsToDrop;
        self.usedWallets.set(sender(), true);
        self.walletsCount = self.walletsCount +1;

        send(
        SendParameters{
            to: self.jettonWallet!!,
            value: 0,
            mode: SendRemainingValue | SendPayGasSeparately | SendIgnoreErrors,
            body: TokenTransfer{
                queryId: 0,
                amount: self.jettonsToDrop,
                destination: sender(),
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: ton("0.000000001"),
                forward_payload: self.GetComment("Stay $ANON")

            }.toCell()
        });
    }

    receive(msg: ChangeJettonWallet) {
        self.requireOwner();
        self.jettonWallet = msg.address;
    }

    receive(msg: ChangeTotalValue) {
        self.requireOwner();
        self.totalValue = msg.totalValue;
        self.currentValue = msg.totalValue;
    }

    receive(msg: ChangeJettonAmount) {
        self.requireOwner();
        self.jettonsToDrop = msg.jettonsToDrop;
    }

    receive(msg: ChangeMinTonsToDrop) {
        self.requireOwner();
        self.minTonsToDrop = msg.minTonsToDrop;
    }

    receive("TT"){
        self.requireOwner();
    }

    receive(msg: ClearMap){
        self.usedWallets = emptyMap();
        self.walletsCount = 0;
    }

    receive("GetTON"){
        self.requireOwner();
        send(SendParameters{
        to: sender(),
        bounce: true,
        value: 0,
        mode: SendRemainingBalance + SendIgnoreErrors
        });
    }


    receive("GetJetton"){
        self.requireOwner();
        require(self.jettonWallet != null, "No jettons");
        send(
        SendParameters{
            to: self.jettonWallet!!,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: TokenTransfer{
            queryId: 0,
            amount: self.currentValue,
            destination: sender(),
            response_destination: sender(),
            custom_payload: null,
            forward_ton_amount: ton("0.000000001"),
            forward_payload: self.GetComment("Withdraw OK.")
        }.toCell()
        });

        self.currentValue = 0;
    }

    //    receive("F"){
    //        self.requireOwner();
    //
    //        let i: Int = 0;
    //        repeat(30) {
    //            let init: StateInit = initOf AirDrop(i, 0, 0 ,0);
    //            self.usedWallets.set(contractAddress(init), true);
    //            i = i + 1;
    //
    //            self.walletsCount = self.walletsCount +1;
    //        }
    //    }

    get fun id(): Int {
        return self.id;
    }

    get fun GetTotalValue(): Int {
        return self.totalValue;
    }

    get fun GetCurrentValue(): Int {
        return self.currentValue;
    }

    get fun GetWalletsStat(): Int {
        return self.walletsCount;
    }

    fun GetComment(Comment: String): Slice {
        let sb: StringBuilder = beginTailString();
        sb.append(Comment);
        return beginCell().storeUint(0, 1 + 32).storeSlice(sb.toSlice()).endCell().asSlice();
    }
}
