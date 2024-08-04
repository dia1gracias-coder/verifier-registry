
// address array ----------------------------------------------------------------------------------------------------
struct AddrArray {
    list: map<Int as uint16, Address>;
    length: Int as uint16 = 0;
}

fun emptyAddrArray(): AddrArray {
    return AddrArray{list: emptyMap(), length: 0};
}

extends fun addrIsInList(self: AddrArray, item: Address) : Bool {
    let list = self.list;
    foreach (key, value in list) { // or just k, v
        if item == value {
            return true;
        }
    }
    return false;
}


extends mutates fun addrArrayAppend(self: AddrArray, item: Address) {
    self.list.set(self.length, item); // set the entry (key-value pair)
    self.length += 1;                // increase the length field
}

extends mutates fun addrArrayDeleteIdx(self: AddrArray, idx: Int): Address {
    require(self.length > 0, "No items in the array to delete!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");
 
    // Remember the value, which is going to be deleted
    let memorized: Address = self.list.get(idx)!!;
 
    // Move all items from idx and including to the left
    let i: Int = idx;
    while (i + 1 < self.length) {
        // Note, that we use !! operator as we know for sure that the value would be there
        self.list.set(i, self.list.get(i + 1)!!);
        i += 1;
    }
 
    self.list.set(self.length - 1, null); // delete the last entry
    self.length -= 1;                    // decrease the length field
 
    return memorized;
}

extends fun addrArrayLast(self: AddrArray): Address {
    require(self.length > 0, "No items in the array!");
 
    // Note, that we use !! operator as we know for sure that the value would be there
    return self.list.get(self.length - 1)!!;
}

// uint array ------------------------------------------------------------------------------------------------------------

struct Uint16Array {
    list: map<Int as uint16, Int as uint16>;
    length: Int as uint16 = 0;
}

fun emptyUint16Array(): Uint16Array {
    return Uint16Array{list: emptyMap(), length: 0};
}

extends fun numIsInList(self: Uint16Array, item: Int) : Bool {
    let list = self.list;
    foreach (key, value in list) { // or just k, v
        if item == value {
            return true;
        }
    }
    return false;
}

extends mutates fun uint16ArrayAppend(self: Uint16Array, item: Int) {
    self.list.set(self.length, item); // set the entry (key-value pair)
    self.length += 1;                // increase the length field
}

extends mutates fun uint16ArrayDeleteIdx(self: Uint16Array, idx: Int): Int {
    require(self.length > 0, "No items in the array to delete!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");
 
    // Remember the value, which is going to be deleted
    let memorized: Int = self.list.get(idx)!!;
 
    // Move all items from idx and including to the left
    let i: Int = idx;
    while (i + 1 < self.length) {
        // Note, that we use !! operator as we know for sure that the value would be there
        self.list.set(i, self.list.get(i + 1)!!);
        i += 1;
    }
 
    self.list.set(self.length - 1, null); // delete the last entry
    self.length -= 1;                    // decrease the length field
 
    return memorized;
}

extends fun uint16ArrayLast(self: Uint16Array): Int {
    require(self.length > 0, "No items in the array!");
 
    // Note, that we use !! operator as we know for sure that the value would be there
    return self.list.get(self.length - 1)!!;
}


// payment array -----------------------------------------------------------------------------------------------

struct Payment {
    amount: Int = 0;
    profit: Int = 0;
    timestamp: Int = 0;
}

struct PaymentArray {
    amount: map<Int as uint16, Int>;
    profit: map<Int as uint16, Int>;
    timestamp: map<Int as uint16, Int>;
    length: Int as uint16 = 0;
}

fun emptyPaymentArray(): PaymentArray {
    return PaymentArray{amount: emptyMap(), profit: emptyMap(), timestamp: emptyMap(), length: 0};
}

extends mutates fun paymentArrayAppend(self: PaymentArray, newPayment: Payment) {
    self.amount.set(self.length, newPayment.amount); // set the entry (key-value pair)
    self.profit.set(self.length, newPayment.profit); // set the entry (key-value pair)
    self.timestamp.set(self.length, newPayment.timestamp); // set the entry (key-value pair)
    self.length += 1;                // increase the length field
}

extends fun paymentArrayLast(self: PaymentArray): Payment {
    require(self.length > 0, "No items in the array!");
 
    // Note, that we use !! operator as we know for sure that the value would be there
    let amount = self.amount.get(self.length - 1)!!;
    let profit = self.profit.get(self.length - 1)!!;
    let timestamp = self.timestamp.get(self.length - 1)!!;

    return Payment{amount: amount, profit: profit, timestamp: timestamp};
}


// cont plan array ------------------------------------------------------------------------------------------------


struct ContPlan {
    minValue: Int;
    profit: Int as uint16;
    limit: Int as uint16;
}

struct ContPlanArray {
    minValue: map<Int as uint16, Int>;
    profit: map<Int as uint16, Int as uint16>;
    limit: map<Int as uint16, Int as uint16>;
    length: Int as uint16 = 0;
}

fun emptyContPlansArray(): ContPlanArray {
    return ContPlanArray{minValue: emptyMap(), profit: emptyMap(), limit: emptyMap(), length: 0};
}

// Extension function for getting the value at the given index
extends fun contPlanGetIdx(self: ContPlanArray, idx: Int): ContPlan {
    require(self.length > 0, "No items in the array!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");
 
    let minValue = self.minValue.get(idx)!!;
    let profit = self.profit.get(idx)!!;
    let limit = self.limit.get(idx)!!;

    // Note, that we use !! operator as we know for sure that the value would be there
    return ContPlan{minValue: minValue, profit: profit, limit: limit};
}

// share array ------------------------------------------------------------------------------------------------

struct Share {
    receiver: Address;
    fraction: Int as uint16;
}

struct ShareArray {
    receiver: map<Int as uint16, Address>;
    fraction: map<Int as uint16, Int as uint16>;
    length: Int as uint16 = 0;
}

extends mutates fun shareArrayAppend(self: ShareArray, share: Share) {
    self.receiver.set(self.length, share.receiver); // set the entry (key-value pair)
    self.fraction.set(self.length, share.fraction); // set the entry (key-value pair)
    self.length += 1;                // increase the length field
}