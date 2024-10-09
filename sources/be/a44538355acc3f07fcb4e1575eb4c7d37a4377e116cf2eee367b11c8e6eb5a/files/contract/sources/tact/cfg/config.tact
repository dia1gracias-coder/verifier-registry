import "@stdlib/ownable";

message WithDrawConfig {
    withdrawFee:Int;
    feeReceiver:Address;
}

trait Config with OwnableTransferable {
    owner: Address; // The OwnableTransferable trait requires you to add this exact state variable
    withdrawFee: Int;
    feeReceiver:Address;

//    init(feeReceiver: Address, withdrawFee:Int) {
//        self.owner = sender();
//        self.withdrawFee = withdrawFee;
//        self.feeReceiver = feeReceiver;
//    }

    receive(msg: WithDrawConfig) {
        require(sender() == self.owner, "Not Owner");
        self.withdrawFee = msg.withdrawFee;
        self.feeReceiver = msg.feeReceiver;
    }

    receive("queryWithDrawConfig") {
        self.reply(WithDrawConfig{withdrawFee: self.withdrawFee, feeReceiver: self.feeReceiver}.toCell());
    }

    get fun withDrawFee(): Int {
        return self.withdrawFee;
    }

    get fun withDrawFeeReceiver(): Address {
        return self.feeReceiver;
    }
}