import "@stdlib/deploy";
import "@stdlib/stoppable";
import "./jetton_example";
import "./nft_example";
import "./packages/traits/taxable";
import "./packages/errcodes";


message WithdrawMessage {
    amount: Int as coins;
    receiver: Address;
}

contract NAP with Deployable,OwnableTransferable,Stoppable,Taxable {
    const MinTonForStorage: Int = ton("0.001"); // TODO change in PROD
    owner: Address; // Ownalbe train requiers you to add this state variable
    stopped: Bool;  // Stoppable trait requires you to add this exact state variable
    staticTax: Int; // Taxable trait requires you to add this exact state variable

    nfts: map<Int as uint16, Address>;
    totalNFTsHeld: Int as uint16 = 0;
    totalNFTSupply: Int;
    jettonWalletBalance: Int = 0;
    jettonMasterAddress: Address;
    nftCollectionAddress: Address;
    nftCollectionOwnerAddress: Address;
    nftCollectionContent: Cell;
    myJettonWalletAddress: Address;
    napRoyaltiesReceiverAddress: Address;
    napRoyaltyFeePercentage: Int;
    treasuryFeeReceiverAddress: Address;
    treasuryFeePercentage: Int;
    uiFeeReceiverAddress: Address;
    const UIFeePercentage: Int = 150;
    napRoyaltyFeeCollected: Int = 0;
    treasuryFeeCollected: Int = 0;
    uiFeeCollected: Int = 0;


    init(
        seed: Int, // Do we even need seed?
        owner: Address,
        jettonMasterAddress: Address,
        nftCollectionAddress: Address,
        nftCollectionOwnerAddress: Address,
        nftCollectionContent: Cell,
        totalNFTSupply: Int,
        napRoyaltiesReceiverAddress: Address,
        napRoyaltyFeePercentage: Int,
        treasuryFeeReceiverAddress: Address,
        treasuryFeePercentage: Int,
        uiFeeReceiverAddress: Address
        ){
        self.owner = owner;
        self.stopped = false;
        self.staticTax = 0;
        self.jettonMasterAddress = jettonMasterAddress;
        self.nftCollectionAddress = nftCollectionAddress;
        self.myJettonWalletAddress = contractAddress(initOf ExampleJettonWallet(myAddress(), jettonMasterAddress));
        self.nftCollectionOwnerAddress = nftCollectionOwnerAddress;
        self.nftCollectionContent = nftCollectionContent;
        self.totalNFTSupply = totalNFTSupply;
        self.napRoyaltiesReceiverAddress = napRoyaltiesReceiverAddress;
        self.napRoyaltyFeePercentage = napRoyaltyFeePercentage;
        self.treasuryFeeReceiverAddress = treasuryFeeReceiverAddress;
        self.treasuryFeePercentage = treasuryFeePercentage;
        self.uiFeeReceiverAddress = uiFeeReceiverAddress;

    }

    receive(msg: Excesses) {
        dump("Shall I be here?");
    }

    receive(msg: WithdrawMessage) {
        self.requireOwner();
        let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        nativeThrowUnless(codeInflowValueNotSufficient, amount > 0);

        send(SendParameters{
            to: msg.receiver,
            bounce: true,
            value: amount,
            mode: SendIgnoreErrors
        });
    }

    receive("FeesWithdraw") {
        // NAP royalties withdraw
        let ctx: Context = context();
        nativeThrowUnless(codeInflowValueNotSufficient, ctx.value >= ton("0.15"));
        
        // NAP royalty
        if(self.napRoyaltyFeeCollected > 0) {
            send(SendParameters{
                    to: self.myJettonWalletAddress,
                    value: ton("0.05"), // TODO , do I need value here? Me later, yeah, also min is 0.04
                    body: JettonTransfer{
                        query_id: 1337,
                        amount: self.napRoyaltyFeeCollected, // jetton amount you want to transfer
                        destination: self.napRoyaltiesReceiverAddress, // address you want transfer jettons TO. Note that this is address of jetton wallet owner, not jetton wallet itself
                        response_destination: self.napRoyaltiesReceiverAddress, //  address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins
                        custom_payload: null, // in most cases will be null and can be omitted. Needed for custom logic on Jetton Wallets itself
                        forward_ton_amount: 0, // amount that will be transferred with JettonTransferNotification. Needed for custom logic execution like in example below. If the amount is 0 notification won't be sent
                        forward_payload: beginCell().endCell().beginParse() // rawSlice("F") // precomputed beginCell().endCell().beginParse(). This works for simple transfer, if needed any struct can be used as `forwardPayload`
                    }.toCell()
                }
            );

            self.napRoyaltyFeeCollected = 0;
        }


        // Treasury fee
        if(self.treasuryFeeCollected > 0) {
            send(SendParameters{
                    to: self.myJettonWalletAddress,
                    value: ton("0.05"), // TODO , do I need value here? Me later, yeah, also min is 0.04
                    body: JettonTransfer{
                        query_id: 1337,
                        amount: self.treasuryFeeCollected, // jetton amount you want to transfer
                        destination: self.treasuryFeeReceiverAddress, // address you want transfer jettons TO. Note that this is address of jetton wallet owner, not jetton wallet itself
                        response_destination: self.treasuryFeeReceiverAddress, //  address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins
                        custom_payload: null, // in most cases will be null and can be omitted. Needed for custom logic on Jetton Wallets itself
                        forward_ton_amount: 0, // amount that will be transferred with JettonTransferNotification. Needed for custom logic execution like in example below. If the amount is 0 notification won't be sent
                        forward_payload: beginCell().endCell().beginParse() // rawSlice("F") // precomputed beginCell().endCell().beginParse(). This works for simple transfer, if needed any struct can be used as `forwardPayload`
                    }.toCell()
                }
            );
            self.treasuryFeeCollected = 0;
        }

        // UI Fee
        if(self.uiFeeCollected > 0) {
            send(SendParameters{
                    to: self.myJettonWalletAddress,
                    value: ton("0.05"), // TODO , do I need value here? Me later, yeah, also min is 0.04
                    body: JettonTransfer{
                        query_id: 1337,
                        amount: self.uiFeeCollected, // jetton amount you want to transfer
                        destination: self.uiFeeReceiverAddress, // address you want transfer jettons TO. Note that this is address of jetton wallet owner, not jetton wallet itself
                        response_destination: self.uiFeeReceiverAddress, //  address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins
                        custom_payload: null, // in most cases will be null and can be omitted. Needed for custom logic on Jetton Wallets itself
                        forward_ton_amount: 0, // amount that will be transferred with JettonTransferNotification. Needed for custom logic execution like in example below. If the amount is 0 notification won't be sent
                        forward_payload: beginCell().endCell().beginParse() // rawSlice("F") // precomputed beginCell().endCell().beginParse(). This works for simple transfer, if needed any struct can be used as `forwardPayload`
                    }.toCell()
                }
            );
            self.uiFeeCollected = 0;
        }

    }

    // Activation of NFT
    receive(msg: JettonTransferNotification){
        dump("Inside JettonTransferNotification");
        self.requireNotStopped();

        let ctx: Context = context();


        let msgTonValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgTonValue;
        let storageFee: Int = self.MinTonForStorage + min(tonBalanceBeforeMsg, self.MinTonForStorage);
        let totalFee = storageFee + self.staticTax;

        nativeThrowUnless(codeInflowValueNotSufficient, msgTonValue >= totalFee);
        msgTonValue -= storageFee;

        nativeThrowUnless(codeUnauthorizedWallet, ctx.sender == self.myJettonWalletAddress);

        // Get nft ID from JettonTransferNotification payload
        // I believe msg JettonTransferNotification is already parsing this for me, so I can work with remaining part of payload, MUST test
        // @audit can I even sent it on transfer? Me later: Yes you can sent it
        let nftID: Int = msg.forward_payload.loadInt(16);

        if(!msg.forward_payload.dataEmpty()){
            let isForDeposit: Bool = msg.forward_payload.loadBool();
            if(isForDeposit) {
                // keeping jettom without giving nft back
                self.jettonWalletBalance += msg.amount;
                let ans = beginString()
                          .concat("Received ")
                          .concat(msg.amount.toString())
                          .concat(" jettons")
                          .toString();
                self.reply(ans.asComment());
                return;
            } else {
                // We should not be here
                throw(1337);
            }
        }

        if(msg.amount < self.NFTPrice()) {
            send(SendParameters{
                to: self.myJettonWalletAddress,
                value: msgTonValue,
                body: JettonTransfer{
                    query_id: msg.query_id,
                    amount: msg.amount, // jetton amount you want to transfer
                    destination: msg.sender, // address you want to transfer jettons. Note that this is address of jetton wallet owner, not jetton wallet itself
                    response_destination: msg.sender, //  address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins
                    custom_payload: null, // in most cases will be null and can be omitted. Needed for custom logic on Jetton Wallets itself
                    forward_ton_amount: 0, // amount that will be transferred with JettonTransferNotification. Needed for custom logic execution like in example below. If the amount is 0 notification won't be sent
                    forward_payload: beginCell().endCell().beginParse() // rawSlice("F") // precomputed beginCell().endCell().beginParse(). This works for simple transfer, if needed any struct can be used as `forwardPayload`
                    }.toCell()
                }
            );
            return;
        }

        self.jettonWalletBalance += msg.amount;

        // Check that nft exists in dictionary
        let nftAddr: Address? = self.nfts.get(nftID);
        if(nftAddr == null) {
            // If selected NFT is not on NAP, return funds back
            send(SendParameters{
                to: self.myJettonWalletAddress,
                value: msgTonValue, // TODO what would happen if it is less than 0.04??
                body: JettonTransfer{
                    query_id: msg.query_id,
                    amount: msg.amount, // jetton amount you want to transfer
                    destination: msg.sender, // address you want to transfer jettons. Note that this is address of jetton wallet owner, not jetton wallet itself
                    response_destination: msg.sender, //  address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins
                    custom_payload: null, // in most cases will be null and can be omitted. Needed for custom logic on Jetton Wallets itself
                    forward_ton_amount: 0, // amount that will be transferred with JettonTransferNotification. Needed for custom logic execution like in example below. If the amount is 0 notification won't be sent
                    forward_payload: beginCell().endCell().beginParse() // rawSlice("F") // precomputed beginCell().endCell().beginParse(). This works for simple transfer, if needed any struct can be used as `forwardPayload`
                    }.toCell()
                }
            );
            return; 
        }

        self.totalNFTsHeld -= 1;

        // Send nft to new owner
        send(SendParameters{
                to: nftAddr!!,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: Transfer{
                    query_id: msg.query_id,
                    new_owner: msg.sender, 
                    response_destination: msg.sender,
                    custom_payload: null,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell()
            }
        );
    }

    // Deactivation of NFT
    receive(msg: OwnershipAssigned){
        dump("Inside NAPs OwnershipAssigned");
        self.requireNotStopped();

        let ctx: Context = context();
        
        let msgTonValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgTonValue;
        let storageFee: Int = self.MinTonForStorage + min(tonBalanceBeforeMsg, self.MinTonForStorage);
        let totalFee = storageFee + self.staticTax;

        nativeThrowUnless(codeInflowValueNotSufficient, msgTonValue >= totalFee);
        msgTonValue -= storageFee;


        let nftIndex: Int = msg.forward_payload.loadInt(16);

        require(sender() == self.getRealNFTAddress(nftIndex), "Message is not from real NFT"); // TODO add return funds here

        self.nfts.set(nftIndex, ctx.sender); // Id -> address
        self.totalNFTsHeld = self.totalNFTsHeld + 1;

        // check is there a data left in msg.payload
        if(!msg.forward_payload.dataEmpty()){
            let isForDeposit: Bool = msg.forward_payload.loadBool();
            if(isForDeposit) {
                // keeping nft without giving funds back
                let ans = beginString()
                          .concat("Deposited nft ")
                          .concat(nftIndex.toString())
                          .toString();
                self.reply(ans.asComment());
                return;
            } else {
                // We should not be here
                throw(codeNotImplemented);
            }
        }

        // NFT is received, need to send corresponding amount of provided jetton
        let deactivationAmount = self.NFTPrice();
        let deactivationProfitAmount = self.processFees(deactivationAmount);

        // Deduct sent amount
        self.jettonWalletBalance = self.jettonWalletBalance - deactivationAmount;

        // Process transfer from jetton wallet
        send(SendParameters{
                to: self.myJettonWalletAddress,
                value: msgTonValue, // TODO , do I need value here? Me later, yeah, also min is 0.04
                body: JettonTransfer{
                    query_id: msg.query_id,
                    amount: deactivationProfitAmount, // jetton amount you want to transfer
                    destination: msg.prev_owner, // address you want to transfer jettons. Note that this is address of jetton wallet owner, not jetton wallet itself
                    response_destination: msg.prev_owner, //  address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins
                    custom_payload: null, // in most cases will be null and can be omitted. Needed for custom logic on Jetton Wallets itself
                    forward_ton_amount: 0, // amount that will be transferred with JettonTransferNotification. Needed for custom logic execution like in example below. If the amount is 0 notification won't be sent
                    forward_payload: beginCell().endCell().beginParse() // rawSlice("F") // precomputed beginCell().endCell().beginParse(). This works for simple transfer, if needed any struct can be used as `forwardPayload`
                }.toCell()
            }
        );
    }

    inline fun processFees(totalNFTPrice: Int): Int {
        let royaltyFee = (totalNFTPrice * self.napRoyaltyFeePercentage) / 10000;
        self.napRoyaltyFeeCollected += royaltyFee;
        let treasuryFee = (totalNFTPrice * self.treasuryFeePercentage) / 10000;
        self.treasuryFeeCollected += treasuryFee;
        let uiFee = (totalNFTPrice * self.UIFeePercentage) / 10000;
        self.uiFeeCollected += uiFee;
        return totalNFTPrice - royaltyFee - treasuryFee - uiFee;
    }

    inline fun getRealNFTAddress(index: Int): Address 
        {
        let expectedAddr: Address = contractAddress(
            initOf ExampleNFTItem(
                self.nftCollectionAddress,                   // collection addr
                index,                                       // index of an NFT
                self.nftCollectionOwnerAddress,              // collectionOwner  (?)
                self.nftCollectionContent                    // NFT content      (?)
                )
            );
        return expectedAddr;
    }

    get fun walletAmount(): Int {
        return self.jettonWalletBalance;
    }

    get fun walletAddress(): Address {
        return self.myJettonWalletAddress;
    }

    get fun NFTsCount(): Int {
        return self.totalNFTsHeld;
    }

    get fun NFTsTotalSupply(): Int {
        return self.totalNFTSupply;
    }

    get fun GetNFTAt(nftID: Int): Address {
        return self.nfts.get(nftID)!!;
    }

    get fun NFTPrice(): Int {
        return self.jettonWalletBalance / (self.totalNFTSupply - self.totalNFTsHeld); // (self.totalSupply - self.totalNFTsHeld) - amount NFTs in market
    }

    get fun NFTDeactivationPrice(): Int {
        return self.processFees(self.NFTPrice());
    }
}