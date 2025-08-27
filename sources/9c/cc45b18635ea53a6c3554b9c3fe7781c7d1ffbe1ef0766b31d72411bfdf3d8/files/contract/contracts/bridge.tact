import "@stdlib/deploy";
import "./utils/signature";
import "./handlers/nativeHandler";
import "./handlers/jettonHandler";
import "./interfaces/types/store";
import "./interfaces/types/events";
import "./interfaces/types/bridge";
import "./interfaces/tokens/jetton";
import "./interfaces/types/crypto";
import "./utils/upgrade";
import "./store";
import "./gas";
import "./utils/assembly_crypto";
import "@stdlib/ownable";


contract Bridge with Deployable, Signature, JettonHandler, NativeHandler, Upgradable{
    bridgeJettonWallets: map<Address, Address>; // JettonWallet: JettonMaster
    wrappedJetton: map<Address, Address>; // JettonMasteret: JettonMasteret

    owner: Address;
    adminKeys: map<Int, EcrecoverKey>;
    _version: Int;

    init(adminKeys: EcrecoverKey) {
        self.adminKeys.set(0, adminKeys);
        self.owner = sender(); // set the owner to the contract deployer
        self._version = 1; // initial version
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun code(): Cell {
        return codeOf Bridge;
    }

    get fun adminKeys(): map<Int, EcrecoverKey> {
        return self.adminKeys;
    }

    get fun bridgeJettonWallets(): map<Address, Address> {
        return self.bridgeJettonWallets;
    }

    get fun wrappedJetton(): map<Address, Address> {
         return self.wrappedJetton;
    }

    receive(msg: MsgUpdateBridgeJettonWallets) {
        require(sender() == self.owner, "Bridge: only owner can update jetton wallets");
        self.bridgeJettonWallets = msg.jettons;
    }

    receive(msg: MsgUpdateWrappedJetton) {
        require(sender() == self.owner, "Bridge: only owner can update wrapped jetton");
        self.wrappedJetton = msg.wrappedMasters
    }

    /// Checks the sender, performs an upgrade, and increments the version.
    receive(msg: Upgrade)  {
        require(sender() == self.owner, "Bridge: only owner can upgrade");
        require(context().value >= UPGARADE_GAS_USAGE, "Bridge: insufficient value for upgrade");
        
        self.validateUpgrade(context(), msg);
        self.upgrade(context(), msg);
        self._version += 1;

        cashback(sender());   // refund the change with mode 64
    }
    
    receive(msg: MsgChangeJettonMasterOwner) {
        require(sender() == self.owner, "Bridge: only owner can set admin key");

        let changeAdminOwnerMsg = MsgChangeTokenAdmin{
            queryId: 0,
            newAdmin: msg.newOwner
        };

        foreach (key, address in self.wrappedJetton) {
            message(
                MessageParameters{
                    to: address,
                    value: context().value - UPDATE_ADMIN,
                    body: changeAdminOwnerMsg.toCell(),
                    bounce: true,
                }
            );
        }
    }

    receive(msg: MsgUpdateAdminKey) {
        require(sender() == self.owner, "Bridge: only owner can set admin key");
        let adminKeys: EcrecoverKey = EcrecoverKey{
            h: msg.h,
            x1:msg.x1,
            x2: msg.x2
        };

        // keep only three keys shifting older ones down
        let i: Int = 1;
        while (i >= 0) {
        let existing = self.adminKeys.get(i);
            if (existing != null) {
                self.adminKeys.set(i + 1, existing!!);
            }
            i -= 1;
        }

        self.adminKeys.set(0, adminKeys);
        cashback(sender());   // refund the change with mode 64
    }

    receive(msg: MsgIsUsedResponse) {
        let sender: Address = sender();
        let storeAddress: Address = self.generateStoreAddress(msg.requestHash);
        require(sender == storeAddress, "Bridge: sender is not the store address");
        let recipient: Address = msg.destinationPayload.loadAddress();
        // the destinationpayload stores the signature
        if msg.isUsed {
            let event = WithdrawError{
                receiver: recipient,
                hash: msg.requestHash,
                errorCode: 1, // 1 - hash is already used 
            };
            emit(event.toCell());
            cashback(msg.sender);   // refund the change with mode 64
            return;
        }


        // the signature is stored in the destination payload as a reference
        // validate the signature
        let signatureCell = msg.destinationPayload.loadRef();        
    
        let signature = signatureCell.asSlice().loadBits(520);
        let hashData = msg.requestHash;


        let key = self.recoverPubKey(hashData, signature);
        let isSameKey: Bool = false;
        let keyIndex: Int = 2;
        while (!isSameKey && keyIndex >= 0) {
            let allowedKey = self.adminKeys.get(keyIndex);
            if (allowedKey != null) {
                isSameKey = self.compareKeys(allowedKey!!, key);
            }
            keyIndex -= 1;
        }

        if !isSameKey{
            let event = WithdrawError{
                receiver: recipient,
                hash: msg.requestHash,
                errorCode: 3, // 3 - invalid signature
            };
            emit(event.toCell());
            cashback(msg.sender);   // refund the change with mode 64
            return;
        }
    
        let withdrawChange = 0;
        if msg.messageType == 0 { // Native token
            let amount = msg.destinationPayload.loadInt(256);

            withdrawChange = self.withdrawNative(
                amount,
                recipient,
                context().value, 
            );
        }
        if msg.messageType == 1 {// Jetton token    
            let amount = msg.destinationPayload.loadInt(256);
            let isWrapped = msg.destinationPayload.loadBool();
            let token = msg.destinationPayload.loadAddress();
            let forwardInfo = msg.destinationPayload.loadRef().asSlice();
            let forwardTonAmount = forwardInfo.loadInt(256);
            let totalTonAmount = forwardInfo.loadInt(256);
            let bridgeJettonAddress = forwardInfo.loadAddress();
            withdrawChange = self.withdrawJetton(
                amount,
                recipient,
                isWrapped, 
                forwardTonAmount,
                totalTonAmount,
                token,
                msg.requestHash,
                bridgeJettonAddress,
                msg.sender, // the sender address

                context().value, //the value of the message in nanoTONs 
            );
        }

        if (context().value - withdrawChange - IS_USED_RESPONSE_GAS_USAGE) < 0 {
            return;
        }

     
        // Send the change back to the sender
        message(
            MessageParameters{
                to: msg.sender, // the sender address
                value: context().value - withdrawChange - IS_USED_RESPONSE_GAS_USAGE, // reserve some amount for storage
                body: emptyCell(),
                bounce: false,
            }
        );
    }

    receive(msg: MsgDepositNative) {
        self.depositNative(
            msg.receiver,
            msg.network,
            context().value,
            sender(),
        );
    }

    receive(msg: MsgJettonTransferNotification) {
        let masterContract = self.bridgeJettonWallets.get(sender());
        require(masterContract != null, "Bridge: sender is not a valid jetton wallet");

        let forwardpayload = msg.forwardPayload;
        let receiver = forwardpayload.loadBits(1016);
        let networkCell = forwardpayload.loadRef();
        let network = networkCell.asSlice().loadBits(256);

        let isWrapped = false;
    
        self.depositJetton(
           msg.amount, 
           receiver,
           network,
           isWrapped,
           msg.owner,
           masterContract!!
        );
    }

    receive(msg: MsgJettonBurnNotification) { 
        require(self.wrappedJetton.get(sender()) != null , "Bridge: sender is not the wrapped jetton wallet");

        let forwardpayload = msg.forwardPayload;
        let receiver = forwardpayload.loadBits(1016);
        let networkCell = forwardpayload.loadRef();
        let network = networkCell.asSlice().loadBits(256);
      
        let isWrapped = true;
        self.depositJetton(
           msg.amount, 
           receiver,
           network,
           isWrapped,
           msg.owner, 
           sender()
        );
    }

    receive(msg: MsgWithdrawNative) {
        let hash = self.buildHashNative(
            msg.amount,
            msg.receiver,
            msg.txHash,
            msg.txNonce,
            msg.network,
        );

        // Validate the signature format and content
        let signatureCell = beginCell()
            .storeSlice(msg.signature)
            .endCell();
    
        let destinationPayload = beginCell()
            .storeRef(signatureCell)
            .storeAddress(msg.receiver)
            .storeUint(msg.amount,256)
            .endCell();

        self.validateHash(
            hash,
            destinationPayload.asSlice(),
            0, // 0 - native withdraw
        );
    }

    receive(msg: MsgWithdrawJetton) {
        let hash = self.buildHashJetton(
            msg.amount,
            msg.receiver,
            msg.txHash,
            msg.txNonce,
            msg.network,
            msg.isWrapped,
            msg.token 
        );

        let forwardInfo = beginCell()
            .storeInt(msg.forwardTonAmount, 256)
            .storeInt(msg.totalTonAmount, 256)
            .storeAddress(msg.bridgeJettonAddress) // the jetton contract address
            .endCell();

        let signatureCell = beginCell()
            .storeSlice(msg.signature)
            .endCell();
    
        let destinationPayload = beginCell()
            .storeRef(signatureCell)
            .storeRef(forwardInfo)
            .storeAddress(msg.receiver)
            .storeUint(msg.amount, 256)
            .storeBool(msg.isWrapped)
            .storeAddress(msg.token)
            .endCell();

        self.validateHash(
            hash, 
            destinationPayload.asSlice(),
            1, // 1 - jetton withdraw
        );
    }

    receive(msg: WithdrawError) {
        // Emit the WithdrawError event to notify about a withdrawal error
        emit(msg.toCell());
    }

    receive(msg: MsgExcesses) {
        // Emit the Excessed event to notify about excesses
        let event = Excessed{
            queryId: msg.queryId,
        };
        emit(event.toCell());
    }

    receive(){
        cashback(sender());   // refund the change with mode 64
    }

    fun compareKeys(key1: EcrecoverKey, key2: EcrecoverKey): Bool {
        return key1.h == key2.h && key1.x1 == key2.x1 && key1.x2 == key2.x2;
    }

    fun generateStoreAddress(hash: Int): Address {
        let storeInit = initOf Store(hash, myAddress());
        let address = contractAddress(storeInit);

        return address;
    }

    fun validateHash(hash: Int, payload: Slice, messageType: Int) {
        let msg = MsgIsUsed{
            destination: myAddress(), // bridge address
            destinationPayload: payload,
            hash: hash,
            messageType: messageType, // 0 - native withdraw, 1 - jetton withdraw,  2 - wrapped withdraw
            sender: sender(), // the sender address
        }.toCell(); 

        let init = initOf Store(hash, myAddress());
        let address: Address = contractAddress(init);
        // The call back to must send some amount of TON to the destination. The user need to handle the amount
        require(context().value >= VALIDATE_HASH_GAS_USAGE + IS_USED_RESPONSE_GAS_USAGE + BUFFER_FEE_VALUE, "Bridge: insufficient value for validate hash");
        send(
            SendParameters{
                to: address,
                value: context().value - VALIDATE_HASH_GAS_USAGE , // reserve some amount for storage
                body: msg,
                mode: SendIgnoreErrors,
                code: init.code,
                data: init.data,
            }
        );  
    }
}