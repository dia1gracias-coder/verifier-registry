import "@stdlib/deploy";
 // struct User {
//     deposit: map
//     this_contract_jettonWallet: Address;
//     total_score: Int as coins;
//     parameter: Int as uint16;
// }


// message(0x7362d09c) TokenNotification {
//     query_id: Int as uint64;
//     amount: Int as coins;
//     from: Address;
//     forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton 
// }


struct Array {
    list: map<Int as uint16, Int>; // array of Int values as a map of Ints to Ints,
                                  // with serialization of its keys to uint16 to save space
    length: Int = 0;              // length of the array, defaults to 0
}



extends mutates fun append(self: Array, item: Int) {
    self.list.set(self.length, item); // set the entry (key-value pair)
    self.length += 1;                // increase the length field
}

fun emptyArray(): Array {
    return Array{list: emptyMap(), length: 0}; // length defaults to 0
}

extends fun toInt(self: Slice): Int {
 
    let acc: Int = 0;
 
    // Loop until the String is empty
    while (!self.empty()) {
        let char: Int = self.loadUint(8); // load 8 bits (1 byte) from the Slice
        acc = (acc * 10) + (char - 48);     // using ASCII table to get numeric value
        // Note, that this approach would produce unexpected results
        //   when the starting String contains non-numeric characters!
    }
 
    // Produce the resulting number
    return acc;
}





// deposit -------------------------------------------------------------------------------------------------------

message Deposit {
    txId: Int;
    jetton: Address;
    userAddr: Address;
    userId: Int as uint64;
    refId: Int as uint64;
    amount: Int as coins;
}

message Withdraw {
    jetton: Address;
    userId: Int as uint64;
}