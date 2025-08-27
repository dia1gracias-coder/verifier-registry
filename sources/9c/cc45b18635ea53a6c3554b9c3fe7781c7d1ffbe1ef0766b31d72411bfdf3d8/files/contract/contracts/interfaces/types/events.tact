message(0x2ddcbe3) JettonDeposited {
    // The address of the sender
    sender: Address;
    // The address of the receiver (624 bits)
    receiver: Slice;
    // The amount being deposited
    amount: Int;
    // The name of the destination network
    network: Slice;
    //  The type of the operation
    isWrapped: Bool;
    // The address of the Master Jetton contract
    token: Address; // the address of the master jetton contract
}

message(0xe858a993) NativeDeposited {
    // The address of the sender
    sender: Address;
    // The address of the recipient (624 bits)
    receiver: Slice;
    // The name of the destination network, used as an informational field for the event.
    network: Slice;
    // The amount being deposited
    amount: Int;
}       

message(0xc01d9831) WithdrawError {
    // The address of the sender
    // sender: Address;
    // The address of the recipient
    receiver: Address;
    // The name of the destination network, used as an informational field for the event.
    // network: Slice;
    // // The amount being deposited
    // amount: Int;
    // // The type of the message
    // messageType: Int; // 0 - native withdraw, 1 - jetton withdraw,  2 - wrapped withdraw
    // The error code
    errorCode: Int; 
    hash: Int;
}

message (0x1389787) Excessed{
    queryId: Int as uint64;
}

//DEBUG EVENTST
message (0x1111112) AfterDuplicationCheck{
    hash: Int;
}

message(0x11112222) BeforeSignatureCheck{
    hash: Int;
}

message(0x22222221) AfterSignatureCheck{
    hash: Int ;
}

message(0x33333333) BeforeWithdraw{
    hash: Int;
}

message(0x44444444) AfterWithdraw{
    fee: Int as coins; 
    balance: Int as coins;   
}

message (0x55555555) AfterExcess{
    fee: Int as coins; 
    balance: Int as coins;   
}