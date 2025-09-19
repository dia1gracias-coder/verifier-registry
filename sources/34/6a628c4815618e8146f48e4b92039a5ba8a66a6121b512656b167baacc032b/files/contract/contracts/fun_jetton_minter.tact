import "./fun_jetton_wallet.tact";
import "./fun_messages.tact";
import "./fun_constants.tact";
import "./fun_utils.tact";
const Workchain: Int = 0;
struct JettonMinterState {
    totalSupply: Int as coins;    
    mintable: Bool;               
    adminAddress: Address;        
    jettonContent: Cell;          
    jettonWalletCode: Cell;       
}
contract GovernanceJettonMinter(
    totalSupply: Int as coins,              
    adminAddress: Address,                  
    nextAdminAddress: Address?,             
    jettonContent: Cell,                    
    locked: Bool,                           
    paused: Bool,                           
    fee: Int,                               
    maxTotalSupplyLimit: Int as coins,      
    baseTokenPrice: Int as coins,           
) {
    inline fun nonReentrant() {
        require(!self.locked, "Contract is locked");
        self.locked = true;
    }
    inline fun unlockContract() {
        self.locked = false;
    }
    inline fun requireNotPaused() {
        require(!self.paused, "Contract is paused");
    }
    inline fun getBaseTokenPrice(): Int {
        if (self.totalSupply == 0) {
            return self.baseTokenPrice; 
        }
        return myBalance() / self.totalSupply;
    }
    inline fun getTokenPriceBuyInternal(): Int {
        return self.getBaseTokenPrice();
    }
    inline fun getTokenPriceSellInternal(): Int {
        let basePrice = self.getBaseTokenPrice();
        if (basePrice == 0) {
            return 0;
        }
        return basePrice * (1000 - self.fee) / 1000;
    }
    receive(msg: Mint) {
        self.nonReentrant();
        self.requireNotPaused();
        require(sender() == self.adminAddress, "Incorrect sender");
        require(msg.masterMsg.amount > 0, "Amount must be positive");
        require(msg.masterMsg.amount <= maxMintAmount, "Mint amount too large");
        let newTotalSupply = self.totalSupply + msg.masterMsg.amount;
        require(newTotalSupply >= self.totalSupply, "Total supply overflow");
        require(newTotalSupply <= self.maxTotalSupplyLimit, "Max total supply exceeded");
        require(parseStdAddress(msg.toAddress.asSlice()).workchain == Workchain, "Wrong workchain");
        checkEitherForwardPayload(msg.masterMsg.forwardPayload);
        let fwdCount = 1 + sign(msg.masterMsg.forwardTonAmount);
        let ctx = context();
        require(ctx.value >= minTonForMint, "Insufficient TON for mint");
        require(
        ctx.value >
        msg.masterMsg.forwardTonAmount +
        fwdCount * ctx.readForwardFee() +
        (2 * getComputeFee(gasForTransfer, false) + minTonsForStorage),
        "Insufficient amount of TON attached",
        );
        self.totalSupply = newTotalSupply;
        deploy(DeployParameters {
            value: 0,                                    
            bounce: true,                                
            mode: SendRemainingValue | SendBounceIfActionFail,  
            body: msg.masterMsg.toCell(),               
            init: getJettonWalletInit(msg.toAddress, self.adminAddress),   
        });
        self.unlockContract();
    }
    receive(msg: JettonBurnNotification) {
        let sender = parseStdAddress(sender().asSlice());
        let wallet = getJettonBasechainWalletByOwner(msg.sender, self.adminAddress);
        require(sender.workchain == Workchain && sender.address == wallet.hash!!, "Unauthorized burn");
        require(msg.amount > 0, "Burn amount must be positive");
        require(msg.amount <= maxBurnAmount, "Burn amount too large");
        require(self.totalSupply >= msg.amount, "Cannot burn more than total supply");
        self.totalSupply -= msg.amount;
        if (msg.responseDestination != null) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors, 
            });
        }
    }
    receive(msg: ProvideWalletAddress) {
        let ownerWorkchain: Int = parseStdAddress(msg.ownerAddress.asSlice()).workchain;
        let targetJettonWallet: BasechainAddress = (ownerWorkchain == Workchain)
        ? contractBasechainAddress(getJettonWalletInit(msg.ownerAddress, self.adminAddress))
        : emptyBasechainAddress();
        message(MessageParameters {
            bounce: false,
            body: makeTakeWalletAddressMsg(targetJettonWallet, msg),
            to: sender(),
            value: 0,
            mode: SendRemainingValue | SendBounceIfActionFail,
        });
    }
    receive(msg: ChangeAdmin) {
        require(sender() == self.adminAddress, "Incorrect sender");
        self.nextAdminAddress = msg.newAdminAddress;
    }
    receive(msg: ClaimAdmin) {
        require(sender() == self.nextAdminAddress, "Not next admin");
        self.adminAddress = sender();
        self.nextAdminAddress = null;
    }
    receive(msg: CallTo) {
        self.nonReentrant();
        self.requireNotPaused();
        require(sender() == self.adminAddress, "Incorrect sender");
        let ctx = context();
        require(ctx.value >= minTonForCallTo, "Insufficient TON for CallTo");
        let msgInfo = calculateSliceBitsAndRefs(msg.masterMsg.asSlice());
        require(msgInfo.refs <= maxCellRefs, "Too many refs in masterMsg");
        require(msgInfo.bits <= maxCellBits, "Message too large");
        let masterMsgSlice = msg.masterMsg.beginParse();
        let op = masterMsgSlice.preloadUint(32);  
        if (op == JettonTransferOpcode) {
            let msgToSend = JettonTransfer.fromSlice(masterMsgSlice);
            require(msgToSend.amount > 0, "Transfer amount must be positive");
            require(msgToSend.amount <= maxTransferAmount, "Transfer amount too large");
            forceBasechainValidation(msgToSend.destination);
            checkEitherForwardPayload(msgToSend.forwardPayload);
            let fwdCount = 1 + sign(msgToSend.forwardTonAmount);
            require(ctx.value >= minTonForTransfer, "Insufficient TON for transfer");
            require(
            ctx.value >
            msgToSend.forwardTonAmount +
            fwdCount * ctx.readForwardFee() +
            (2 * getComputeFee(gasForTransfer, false) + minTonsForStorage),
            "Insufficient amount of TON attached",
            );
            deploy(DeployParameters {
                bounce: false,
                value: 0,  
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, self.adminAddress),
            });
            self.unlockContract();
        } else if (op == JettonBurnOpcode) {
            let msgToSend = JettonBurn.fromSlice(masterMsgSlice);
            require(msgToSend.amount > 0, "Burn amount must be positive");
            require(msgToSend.amount <= maxBurnAmount, "Burn amount too large");
            require(ctx.value >= minTonForBurn, "Insufficient TON for burn");
            require(
            ctx.value > (ctx.readForwardFee() + 2 * getComputeFee(gasForBurn, false)),
            "Insufficient amount of TON attached",
            );
            deploy(DeployParameters {
                bounce: false,
                value: 0,  
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, self.adminAddress),
            });
            self.unlockContract();
        } else if (op == SetStatusOpcode) {
            let msgToSend = SetStatus.fromSlice(masterMsgSlice);
            require(msgToSend.status <= 15, "Invalid status value");
            deploy(DeployParameters {
                bounce: false,
                value: 0,  
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, self.adminAddress),
            });
            self.unlockContract();
        } else {
            self.unlockContract();
            require(false, "Unsupported operation in CallTo");
        }
    }
    receive(msg: ChangeMetadataUri) {
        require(sender() == self.adminAddress, "Incorrect sender");
        let metadataInfo = calculateSliceBitsAndRefs(msg.metadata);
        let metadataSize = metadataInfo.bits / 8 + metadataInfo.refs * 32;
        require(metadataSize <= maxMetadataSize, "Metadata too large");
        self.jettonContent = msg.metadata.asCell();
    }
    receive(msg: Upgrade) {
        require(sender() == self.adminAddress, "Incorrect sender");
        setData(msg.newData);  
        setCode(msg.newCode);  
    }
    receive(msg: PauseContract) {
        require(sender() == self.adminAddress, "Incorrect sender");
        self.paused = msg.pause;
    }
    receive(msg: SetFee) {
        require(sender() == self.adminAddress, "Incorrect sender");
        require(msg.newFee <= 1000, "Fee cannot exceed 100%");
        self.fee = msg.newFee;
    }
    receive(msg: SetMaxTotalSupply) {
        require(sender() == self.adminAddress, "Incorrect sender");
        require(msg.newMaxTotalSupply > 0, "Max total supply must be positive");
        require(msg.newMaxTotalSupply >= self.totalSupply, "Max total supply cannot be less than current total supply");
        self.maxTotalSupplyLimit = msg.newMaxTotalSupply;
    }
    receive(msg: SetBasePrice) {
        require(sender() == self.adminAddress, "Incorrect sender");
        require(msg.newBasePrice > 0, "Base price must be positive");
        self.baseTokenPrice = msg.newBasePrice;
    }
    receive(_: TopUp) {}
    bounced(msg: bounced<JettonTransferInternal>) {
        self.totalSupply -= msg.amount;
    }
    get fun get_jetton_data(): JettonData {
        return JettonData {
            totalSupply: self.totalSupply,
            mintable: true,
            owner: self.adminAddress,           
            content: self.jettonContent,        
            jettonWalletCode: codeOf JettonWalletGovernance,
        };
    }
    get fun get_wallet_address(ownerAddress: Address): Address {
        return getJettonWalletByOwner(ownerAddress, self.adminAddress);
    }
    get fun get_next_admin_address(): Address? {
        return self.nextAdminAddress;
    }
    get fun get_fee(): Int {
        return self.fee;
    }
    get fun get_token_price_buy(): Int {
        return self.getTokenPriceBuyInternal();
    }
    get fun get_token_price_sell(): Int {
        return self.getTokenPriceSellInternal();
    }
    get fun get_base_token_price(): Int {
        return self.getBaseTokenPrice();
    }
    get fun get_contract_balance(): Int {
        return myBalance();
    }
    get fun get_max_total_supply(): Int {
        return self.maxTotalSupplyLimit;
    }
    get fun get_base_price(): Int {
        return self.baseTokenPrice;
    }
}
inline fun getJettonWalletInit(address: Address, owner: Address): StateInit {
    let minTransAmount = minTransferAmount;
    if (address == owner) {
        minTransAmount = 0;
    }
    return initOf JettonWalletGovernance(0, 0, address, myAddress(), minTransAmount);
}
inline fun getJettonWalletByOwner(jettonWalletOwner: Address, ownerAddress: Address): Address {
    return contractAddress(getJettonWalletInit(jettonWalletOwner, ownerAddress));
}
inline fun getJettonBasechainWalletByOwner(jettonWalletOwner: Address, ownerAddress: Address): BasechainAddress {
    return contractBasechainAddress(getJettonWalletInit(jettonWalletOwner, ownerAddress));
}
asm fun setData(newData: Cell) {
c4 POP
}
asm fun setCode(newCode: Cell) {
SETCODE
}
