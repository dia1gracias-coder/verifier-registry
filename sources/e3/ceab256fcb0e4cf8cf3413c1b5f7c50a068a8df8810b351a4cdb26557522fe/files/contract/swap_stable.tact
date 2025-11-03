
message(0x7362d09c) JettonTopUp {
    queryId: Int as uint64 = 0;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0x25938561) SwapToJettons {}

message(0x06112009) ChangeRate {
    rate: Int;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

const JettonTransferGas: Int = ton("0.05");

fun calculateJettonWalletAddress(
ownerAddress: Address,
jettonMasterAddress: Address,
jettonWalletCode: Cell,
): Address {
    let initData = JettonWalletData {
        balance: 0,
        ownerAddress,
        jettonMasterAddress,
        jettonWalletCode,
    };

    return contractAddress(StateInit {
        code: jettonWalletCode,
        data: initData.toCell(),
    });
}

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}
message(0x99900000) ChangeJettonWallet {
    stableJettonWalletAddress: Address;
}
contract Swap {
    stableJettonWalletAddress: Address;
    jettonAmount: Int as coins = 0;
    owner: Address;
    rate: Int as uint256;
    jettonWalletCode: Cell;


    init(jettonWalletCode: Cell, jettonMasterAddress: Address, owner: Address) {
        self.stableJettonWalletAddress = calculateJettonWalletAddress(
            myAddress(),
            jettonMasterAddress,
            jettonWalletCode,
        );
        self.jettonWalletCode = jettonWalletCode;
        self.rate = 1000000000;
        self.owner = owner;
    }

    get fun owner(): Address {
        return self.owner;
    }
    get fun jettonWalletCode(): Cell {
        return self.jettonWalletCode;
    }
    get fun getRate(): Int {
        return self.rate;
    }
    get fun getJettonBalance(): Int {
        return self.jettonAmount;
    }
    get fun getJettonAddress(): Address {
        return self.stableJettonWalletAddress;
    }


    receive() {
        cashback(sender());
    }
    receive(msg: ChangeJettonWallet) {
        throwUnless(TactExitCodeAccessDenied, context().sender == self.owner);
        self.stableJettonWalletAddress = msg.stableJettonWalletAddress;
        cashback(sender());
    }
    receive(msg: JettonTopUp) {
        require(
        sender() == self.stableJettonWalletAddress,
        "Notification not from your jetton wallet!",
        );
        self.jettonAmount += msg.amount;
        self.forward(msg.sender, null, false, null);
    }
    receive(msg: SwapToJettons) {
        let amount: Int = (self.rate * (context().value - JettonTransferGas)) / 1000000000;
        throwIf(400, amount >= self.jettonAmount);
        self.jettonAmount -=  amount;
        send(SendParameters {
            to: self.stableJettonWalletAddress,
            value: JettonTransferGas,
            body: JettonTransfer {
                queryId: 0,
                amount: amount,
                destination: sender(),
                responseDestination: sender(),
                customPayload: null,
                forwardTonAmount: 1,
                forwardPayload: rawSlice("F"),
            }.toCell(),
        });
    }

    receive(msg: ChangeRate) {
        throwUnless(TactExitCodeAccessDenied, context().sender == self.owner);
        self.rate = msg.rate;
        cashback(sender());
    }
}