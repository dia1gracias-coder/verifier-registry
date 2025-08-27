import "../interfaces/types/events";
import "../gas";

trait NativeHandler {
    get fun nativeHash(
        amount_: Int,
        receiver_: Address,
        txHash_: Int,
        txNonce_: Int,
        network: Slice,
    ): Int {
        // Generate a unique hash identifier based on the provided parameters.
        return self.buildHashNative(amount_, receiver_, txHash_, txNonce_, network);
    }  
    
    // Generates a unique hash identifier based on the provided parameters.
    fun buildHashNative(
        amount_: Int,
        receiver_: Address,
        txHash_: Int,
        txNonce_: Int,
        network: Slice,
    ): Int {
        let addressCell = beginCell()
            .storeAddress(myAddress())
            .storeUint(1, 5)
            .endCell();

        // the receiver address is 267 bits because it is a tvm internal address(288 bits off-chain and 267 bits on-chain)
        // to use keccak256, data must be divisible by 8
        let data = beginCell()
            .storeRef(addressCell)
            .storeAddress(receiver_)
            .storeUint(1, 5) 
            .storeUint(txHash_, 256)
            .endCell();
  

        // add the bridge address 
        let combinedData = beginCell()
            .storeRef(data)
            .storeUint(amount_, 256)
            .storeUint(txNonce_, 256)
            .storeSlice(network) // 128 bits for the network name or id (EVM only)
            .endCell();

       
        return keccak256(combinedData.asSlice());
    }

    fun withdrawNative(
        amount_: Int,
        receiver_: Address,
        value_: Int,
    ): Int{
        require(amount_ > 0, "NativeHandler: amount is zero");
        // Send the native token to the receiver
        message(
            MessageParameters{
                to: receiver_,
                value: amount_ , // the fee for forwarding the message
                bounce: false,
                mode: 1
            }
        );

        // Return the amount that should be refunded to the caller
        return NATIVE_EXTRA_FEE;
    }

    fun depositNative (
        receiver_: Slice,  // receiver is not only tvm address
        network_: Slice,
        amount_: Int,
        sender_: Address,
    ) {
        require(amount_ > 0, "NativeHandler: zero value");

        let event = NativeDeposited{
            sender: sender_,
            receiver: receiver_,
            amount: amount_,
            network: network_,
        }.toCell();
        emit(event);
    }
}