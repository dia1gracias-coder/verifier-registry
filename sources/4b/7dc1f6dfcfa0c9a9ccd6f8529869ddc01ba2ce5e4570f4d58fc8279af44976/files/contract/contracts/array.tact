struct BetDetails {
  player: Address;
  betKey: String;  
  symbol: String;
  amount: Int as coins;
}

struct Array {
    m: map<Int as uint16, BetDetails>; // array of Int values as a map of Ints to Bets,
                                       // with serialization of its keys to uint16 to save space
    length: Int = 0;                   // length of the array, defaults to 0
}

// Compile-time constant upper bound for our map representing an array.
const MaxArraySize: Int = 5_000; // 5,000 entries max, to stay reasonably far from limits

// Extension mutation function for adding new entries to the end of the array
extends mutates fun append(self: Array, item: BetDetails) {
    require(self.length + 1 <= MaxArraySize, "No space in the array left for new items!");

    self.m.set(self.length, item); // set the entry (key-value pair)
    self.length += 1;              // increase the length field
}

// Extension mutation function for inserting new entries at the given index
extends mutates fun insert(self: Array, item: BetDetails, idx: Int) {
    require(self.length + 1 <= MaxArraySize, "No space in the array left for new items!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    // Move all items from idx to the right
    let i: Int = self.length; // not a typo, as we need to start from the non-existing place
    while (i > idx) {
        // Note, that we use !! operator as we know for sure that the value would be there
        self.m.set(i, self.m.get(i - 1)!!);
        i -= 1;
    }

    // And put the new item in
    self.m.set(idx, item); // set the entry (key-value pair)
    self.length += 1;      // increase the length field
}

// Extension function for getting the value at the given index
extends fun getIdx(self: Array, idx: Int): BetDetails {
    require(self.length > 0, "No items in the array!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    // Note, that we use !! operator as we know for sure that the value would be there
    return self.m.get(idx)!!;
}

// Extension function for returning the last value
extends fun getLast(self: Array): BetDetails {
    require(self.length > 0, "No items in the array!");

    // Note, that we use !! operator as we know for sure that the value would be there
    return self.m.get(self.length - 1)!!;
}

// Extension mutation function for deleting and entry at the given index and returning its value
extends mutates fun deleteIdx(self: Array, idx: Int): BetDetails {
    require(self.length > 0, "No items in the array to delete!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    // Remember the value, which is going to be deleted
    let memorized: BetDetails = self.m.get(idx)!!;

    // Move all items from idx and including to the left
    let i: Int = idx;
    while (i + 1 < self.length) {
        // Note, that we use !! operator as we know for sure that the value would be there
        self.m.set(i, self.m.get(i + 1)!!);
        i += 1;
    }

    self.m.set(self.length - 1, null); // delete the last entry
    self.length -= 1;                  // decrease the length field

    return memorized;
}

// Extension mutation function for deleting the last entry and returning its value
extends fun deleteLast(self: Array): BetDetails {
    require(self.length > 0, "No items in the array!");

    // Note, that we use !! operator as we know for sure that the value would be there
    let lastItem: BetDetails = self.m.get(self.length - 1)!!;
    self.m.set(self.length - 1, null); // delete the entry
    self.length -= 1;                  // decrease the length field

    return lastItem;
}

// Extension function for deleting all items in the Array
extends mutates fun deleteAll(self: Array) {
    self.m = emptyMap();
    self.length = 0;
}

// Global static function for creating an empty Array
fun emptyArray(): Array {
    return Array{m: emptyMap(), length: 0}; // length defaults to 0
}