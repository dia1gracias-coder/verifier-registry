message(0x12dd3d08) MsgIsUsed {
    destination: Address;
    // recipient (jetton or wallet)(268 bits) -> signatur(the first reference) ->  
    // amount(jetton or ton)(256bits) -> isWrapped(if jetton)(bool 1bit) -> 
    // tokenAddress(268bits)  -> the forwardTonAmount and  totalTonAmount stored in the second reference
    destinationPayload: Slice;
    hash: Int;
    messageType: Int; // 0 - native withdraw, 1 - jetton withdraw,  2 - wrapped withdraw
    sender: Address; // the sender address, used to send the response back
}

message (0x1c3b2f8d) MsgIsUsedResponse {
    // recipient (jetton or wallet)(268 bits) -> signatur(the first reference) ->  
    // amount(jetton or ton)(256bits) -> isWrapped(if jetton)(bool 1bit) -> 
    // tokenAddress(268bits)  -> the forwardTonAmount and  totalTonAmount stored in the second reference
    destinationPayload: Slice; 
    isUsed: Bool;
    requestHash: Int;
    messageType: Int; // 0 - native withdraw, 1 - jetton withdraw,  2 - wrapped withdraw
    sender: Address; // the sender address, used to send the response back
}
