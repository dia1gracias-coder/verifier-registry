import "@stdlib/deploy";
import "./messages";



message TokenWithdraw {
    amount: Int as uint256;
    jettonWalletAddress: Address;
    receiver: Address;
}

struct WhiteListMint {
    seqno: Int as uint32;
    amount: Int as uint256;
    receiver: Address;
    jettonWalletAddress: Address;
}

message WhiteListMintMessage {
    signature: Slice;
    whiteListMint: WhiteListMint;
}

message PublicMintMessage {
    amount: Int as uint256;
    receiver: Address;
    jettonWalletAddress: Address;
}


message UpdateWlSignKey {
    pKey: Int as uint256;
}


struct MintInfo {
    owner: Address;
    wlSignKey: Int as uint256;
    totalWlMintAmount: Int as uint256;
    totalPublicMintAmount: Int as uint256;
    totalMintAmount: Int as uint256;
    wlMintMinAmount: Int as uint32;
    wlMintMaxAmount: Int as uint32;
    publicMintMinAmount: Int as uint32;
    wlMintTonPrice: Int;
    publicMintTonPrice: Int;
}
//单价一个0.0005Ton

contract CTonMint with Deployable {
    const minTonsForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03");

    // const wlMintTonPrice: Int = ton("0.0005");
    // const publicMintTonPrice: Int = ton("0.0005");

    wlMintTonPrice: Int = ton("0.0005");
    publicMintTonPrice: Int = ton("0.0005");

    owner: Address;
    wlSignKey: Int as uint256;
    
    seqnoMap: map<Address, Int>;
    wlMintAmountMap: map<Address, Int>;
    publicMintAmountMap: map<Address, Int>;

    totalWlMintAmount: Int as uint256 = 0;
    totalPublicMintAmount: Int as uint256 = 0;
    totalMintAmount: Int as uint256 = 0;

    wlMintMinAmount: Int as uint32 = 10000;
    wlMintMaxAmount: Int as uint32 = 20000;

    publicMintMinAmount: Int as uint32 = 100;
    publicMintMaxAmount: Int as uint32 = 20000;



    init(owner: Address, wlSignKey: Int) {
        self.owner = owner;
        self.wlSignKey = wlSignKey;
    }

    fun msgValue(msgValue: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);
        return msgValue;
    }

    fun mintToken(jettonWalletAddress: Address, to: Address, amount: Int) {
        send(SendParameters{
            to: jettonWalletAddress,
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransfer{
                query_id: 0,
                amount: amount,
                sender: to,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: beginCell().storeUint(0, 1).storeUint(0, 32).endCell().asSlice()
            }.toCell()
        });
    }

    receive (msg: UpdateWlSignKey) {
        require(sender() == self.owner, "Only owner can update public key");
        self.wlSignKey = msg.pKey;
    }

    receive (msg: WhiteListMintMessage) {
        let ctx: Context = context();
        // let value: Int = ctx.value;
        let sender: Address = ctx.sender;

        let opHash: Int = msg.whiteListMint.toCell().hash();
        require(checkSignature(opHash, msg.signature, self.wlSignKey), "Invalid signature");
        require(msg.whiteListMint.receiver == sender, "wrong receiver");

        require(msg.whiteListMint.amount >= self.wlMintMinAmount, "Min amount limit");
        require(msg.whiteListMint.amount <= self.wlMintMaxAmount, "Max amount limit");


        if (self.seqnoMap.get(sender) == null) {
            require(msg.whiteListMint.seqno == 0, "wrong seqno");
            self.seqnoMap.set(sender, 1);
        } else {
            let seqno: Int = self.seqnoMap.get(sender)!!;
            require(msg.whiteListMint.seqno == seqno, "wrong seqno");
            self.seqnoMap.set(sender, seqno + 1);
        }


        if (self.wlMintAmountMap.get(sender) == null) {
            self.wlMintAmountMap.set(sender, msg.whiteListMint.amount);
        } else {
            let wlMintAmount: Int = self.wlMintAmountMap.get(sender)!!;
            let totalWlMintAmount: Int = wlMintAmount + msg.whiteListMint.amount;
            require(totalWlMintAmount <= self.wlMintMaxAmount, "Max total amount limit");
            self.wlMintAmountMap.set(sender, totalWlMintAmount);
        }

        self.totalWlMintAmount = self.totalWlMintAmount + msg.whiteListMint.amount;
        self.totalMintAmount = self.totalMintAmount + msg.whiteListMint.amount;
        let value: Int = self.msgValue(ctx.value);
        let totalTonAmount: Int = self.wlMintTonPrice * msg.whiteListMint.amount;
        require(value >= totalTonAmount, "Invalid value");
        self.mintToken(msg.whiteListMint.jettonWalletAddress, msg.whiteListMint.receiver, msg.whiteListMint.amount);
    }

    receive (msg: PublicMintMessage) {
        let ctx: Context = context();
        let sender: Address = ctx.sender;

        require(msg.amount >= self.publicMintMinAmount, "Min amount limit");
        require(msg.amount <= self.publicMintMaxAmount, "Max amount limit");

        if (self.publicMintAmountMap.get(sender) == null) {
            self.publicMintAmountMap.set(sender, msg.amount);
        } else {
            let publicMintAmount: Int = self.publicMintAmountMap.get(sender)!!;
            let totalPublicMintAmount: Int = publicMintAmount + msg.amount;
            require(totalPublicMintAmount <= self.publicMintMaxAmount, "Max total amount limit");
            self.publicMintAmountMap.set(sender, totalPublicMintAmount);
        }


        self.totalPublicMintAmount = self.totalPublicMintAmount + msg.amount;
        self.totalMintAmount = self.totalMintAmount + msg.amount;
        let value: Int = self.msgValue(ctx.value);
        let totalTonAmount: Int = self.publicMintTonPrice * msg.amount;
        require(value >= totalTonAmount, "Invalid value");
        self.mintToken(msg.jettonWalletAddress, msg.receiver, msg.amount);
    }



    // int check_data_signature(slice data, slice signature, int public_key)
    // receive (msg: SignVerify) {
    //     // fun sha256(data: String): Int;
    //     // let publicKey: Int =  sha256(msg.publicKey);
    //     // let data: Slice = publicKey.asSlice();
    //     require(checkDataSignature(msg.data, msg.signature, msg.publicKey), "Invalid Signature");
    //     self.totalAmountLocked = 888;
    //     // check_signature(msg.data, msg.signature, msg.publicKey);
    // }

    // receive (msg: WhiteListMint) {
    // }

    receive (msg: TokenWithdraw) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");

        send(SendParameters{
            to: msg.jettonWalletAddress,
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransfer{
                query_id: 0,
                amount: msg.amount,
                sender: msg.receiver,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: beginCell().storeUint(0, 1).storeUint(0, 32).endCell().asSlice()
            }.toCell()
        });
    }

    receive("ClaimFee") {
        require(sender() == self.owner, "Only owner can claim fee");
        send(SendParameters{
            to: self.owner,
            value: myBalance() - ton("0.1"),
            bounce: false,
            mode: SendPayGasSeparately
        });
    }


    get fun mintInfo(): MintInfo {
        return MintInfo{
            owner: self.owner,
            wlSignKey: self.wlSignKey,
            totalWlMintAmount: self.totalWlMintAmount,
            totalPublicMintAmount: self.totalPublicMintAmount,
            totalMintAmount: self.totalMintAmount,
            wlMintMinAmount: self.wlMintMinAmount,
            wlMintMaxAmount: self.wlMintMaxAmount,
            publicMintMinAmount: self.publicMintMinAmount,
            wlMintTonPrice: self.wlMintTonPrice,
            publicMintTonPrice: self.publicMintTonPrice
        };
    }

    get fun whitelistAmountByAddress(userAddr: Address): Int {
        if (self.wlMintAmountMap.get(userAddr) == null) {
            return 0;
        }
        return self.wlMintAmountMap.get(userAddr)!!;
    }

    get fun publicAmountByAddress(userAddr: Address): Int {
        if (self.publicMintAmountMap.get(userAddr) == null) {
            return 0;
        }
        return self.publicMintAmountMap.get(userAddr)!!;
    }


}
