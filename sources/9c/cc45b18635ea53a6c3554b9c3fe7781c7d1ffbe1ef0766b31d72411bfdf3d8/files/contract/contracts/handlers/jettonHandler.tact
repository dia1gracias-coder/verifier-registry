import "../interfaces/types/events";
import "../interfaces/tokens/jetton";
import "../gas";

trait JettonHandler {
    get fun jettonHash(
        amount_: Int,
        receiver_: Address, // receiver is already a jetton-wallet address on the TON network
        txHash_: Int,
        txNonce_: Int,
        network_: Slice,
        isWrapped_: Bool,
        token_: Address, // jetton master address
    ): Int {
        return self.buildHashJetton(
            amount_,
            receiver_,
            txHash_,
            txNonce_,
            network_,
            isWrapped_,
            token_,
        );
    }

    // Generates a unique hash identifier based on the provided parameters.
    fun buildHashJetton(
        amount_: Int,
        receiver_: Address, // receiver is already a jetton-wallet address
        txHash_: Int,
        txNonce_: Int,
        network: Slice, // 128 bits for the network name or id (EVM only)
        isWrapped_: Bool,
        token_: Address, // jetton master address
    ): Int {
        // the receiver address is 267 bits because it is a tvm internal address(288 bits off-chain and 267 bits on-chain)
        // to use keccak256, data must be divisible by 8
        let addressCell = beginCell()
            .storeAddress(myAddress())
            .storeUint(1, 5)
            .endCell();

        let data = beginCell()
            .storeRef(addressCell)
            .storeAddress(receiver_)
            .storeUint(1, 5)
            .storeUint(txHash_,  256)
            .storeUint(amount_, 256)
            .endCell();

        // add the bridge address 
        let combinedData = beginCell()
            .storeRef(data)
            .storeInt(txNonce_, 256)
            .storeBool(isWrapped_)
            .storeSlice(network)
            .storeAddress(token_)
            .storeUint(0, 4)
            .endCell();

        return keccak256(combinedData.asSlice());
    }

    fun withdrawJetton(
        amount_:Int,
        receiver_:Address, 
        isWrapped_: Bool,
        forwardTonAmount: Int,
        totalTonAmount: Int,

        token_: Address, // jetton master address
        requestHash: Int,
        bridgeJettonAddress: Address, // the jetton contract address
        sender: Address, // the sender address

        value: Int, // the value of the message in nanoTONs
    ): Int{
        require(amount_ > 0, "JettonHandler: amount is zero");
        require(totalTonAmount > forwardTonAmount,  "JettonHandler: totalTonAmount must be greater than forwardTonAmount");
        require(JETTON_FEE < totalTonAmount,  "JettonHandler: JETTON_FEE must be less than totalTonAmount");
        require(requestHash != 0, "JettonHandler: zero requestHash");

        let mask64  = (1 << 64) - 1;  
        let id = (requestHash >> 192) & mask64;


        if !isWrapped_ { // default jetton
            let msg = MsgJettonTransfer{
                queryId: id,
                amount: amount_,
                destination: receiver_, 
                responseDestination: sender, 
                customPayload: emptyCell(), 
                forwardPayload: emptyCell().asSlice(),
                forwardTonAmount: forwardTonAmount,
            };

            require(value >= JETTON_FEE + forwardTonAmount, "JettonHandler: insufficient value for message");

            message(
                MessageParameters{
                    to: bridgeJettonAddress,
                    value: JETTON_FEE + forwardTonAmount,  
                    body: msg.toCell(),
                    bounce: true,
                }
            );  

            return JETTON_FEE + forwardTonAmount; // return the change
        } 

        // wrapped jetton
        let mintMsg = MsgInternalTransfer{
            queryId: id,
            amount: amount_,
            destination: newAddress(0, 0), 
            responseDestination: sender,
            forwardTonAmount: forwardTonAmount, // the amount of TON to be sent to the receiver
        };
        
        let msg = MsgMintTokens{
            queryId: id,
            destination: receiver_,
            totalTonAmount: totalTonAmount,
            jettonAmount: amount_,
            mintMsg: mintMsg.toCell(),
        };

        require(value >= JETTON_FEE, "JettonHandler: insufficient value for message ");
        message(
            MessageParameters{
                to: token_,
                value: JETTON_FEE,
                body: msg.toCell(),
                bounce: true,
            }
        );

        return JETTON_FEE; // return the change
    }

    // This function is called when a jetton sends transaction notification to bridge contract
    fun depositJetton(
        amount_:Int,
        receiver_:Slice,
        network_: Slice,
        isWrapped_: Bool,
        sender_:Address,
        token_: Address,
    ){
        require(amount_ > 0, "JettonHandler: amount is zero");
        // Emit the deposit event
        let event = JettonDeposited{
            amount: amount_,
            receiver: receiver_,
            network: network_,
            isWrapped: isWrapped_,
            sender: sender_,
            token: token_,
        }.toCell();
        emit(event);
    }
}