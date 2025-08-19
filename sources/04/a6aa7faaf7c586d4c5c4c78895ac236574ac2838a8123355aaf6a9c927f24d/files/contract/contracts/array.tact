struct Array {
    // An array of Int values as a map of Ints to Ints,
    // with serialization of its keys to uint16 to save space
    m: map<Int as uint16, Int>;

    // Length of the array, defaults to 0
    length: Int = 0;
}

// Compile-time constant upper bound for our map representing an array.
const MaxArraySize: Int = 5_000; // 5,000 entries max, to stay reasonably far from limits

// Extension mutation function for adding new entries to the end of the array
inline extends mutates fun append(self: Array, item: Int) {
    require(self.length + 1 <= MaxArraySize, "No space in the array left for new items!");

    self.m.set(self.length, item); // set the entry (key-value pair)
    self.length += 1; // increase the length field
}

// Extension mutation function for inserting new entries at the given index
extends mutates fun insert(self: Array, item: Int, idx: Int) {
    require(self.length + 1 <= MaxArraySize, "No space in the array left for new items!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    // Move all items from idx to the right
    let i: Int = self.length; // not a typo, as we need to start from the non-existing place
    while (i > idx) {
        // Note that we use the !! operator, as we know for sure the value would be there
        self.m.set(i, self.m.get(i - 1)!!);
        i -= 1;
    }

    // Insert the new item
    self.m.set(idx, item); // set the entry (key-value pair)
    self.length += 1; // increase the length field
}

// Extension function for getting the value at the given index
extends fun getIdx(self: Array, idx: Int): Int {
    require(self.length > 0, "No items in the array!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    // Note that we use the !! operator, as we know for sure the value would be there
    return self.m.get(idx)!!;
}

// Extension function for returning the last value
inline extends fun getLast(self: Array): Int {
    require(self.length > 0, "No items in the array!");

    // Note that we use the !! operator, as we know for sure the value would be there
    return self.m.get(self.length - 1)!!;
}

// Extension mutation function for deleting an entry at the given index and returning its value
inline extends mutates fun deleteIdx(self: Array, idx: Int): Int {
    require(self.length > 0, "No items in the array to delete!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    // Remember the value that is going to be deleted
    let memorized: Int = self.m.get(idx)!!;

    // Move all items from idx onwards to the left
    let i: Int = idx;
    while (i + 1 < self.length) {
        // Note that we use the !! operator, as we know for sure the value would be there
        self.m.set(i, self.m.get(i + 1)!!);
        i += 1;
    }

    self.m.set(self.length - 1, null); // delete the last entry
    self.length -= 1; // decrease the length field

    return memorized;
}

// Extension mutation function for deleting the last entry and returning its value
inline extends fun deleteLast(self: Array): Int {
    require(self.length > 0, "No items in the array!");

    // Note that we use the !! operator, as we know for sure the value would be there
    let lastItem: Int = self.m.get(self.length - 1)!!;
    self.m.set(self.length - 1, null); // delete the entry
    self.length -= 1; // decrease the length field

    return lastItem;
}

// Extension function for deleting all items in the Array
inline extends mutates fun deleteAll(self: Array) {
    self.m = emptyMap();
    self.length = 0;
}

// Global static function for creating an empty Array
inline fun emptyArray(): Array {
    return Array { m: emptyMap(), length: 0 }; // length defaults to 0
}

// Contract emulating an Array using the map
contract MapAsArray {
    // Persistent state variables
    array: Array;

   // Constructor (initialization) function of the contract
    init() {
        self.array = emptyArray();
    }

    // Internal message receiver, which responds to a `null` message body
    // If used for deployment, forwards the remaining value back to the sender
    receive() { cashback(sender()) }

    // Internal message receiver, which responds to a String message "append"
    receive("append") {
        // Add a new item
        self.array.append(42);
    }

    // Internal message receiver, which responds to a String message "delete_5th"
    receive("delete_5th") {
        // Remove the 5th item if it exists and reply back with its value, or raise an error
        self.reply(self.array.deleteIdx(4).toCoinsString().asComment()); // index offset 0 + 4 gives the 5th item
    }

    // Internal message receiver, which responds to a String message "del_last"
    receive("del_last") {
        // Remove the last item and reply back with its value, or raise an error
        self.reply(self.array.deleteLast().toCoinsString().asComment());
    }

    // Internal message receiver, which responds to a String message "get_last"
    receive("get_last") {
        // Reply back with the latest item in the array if it exists, or raise an error
        self.reply(self.array.getLast().toCoinsString().asComment());
    }

    // Internal message receiver, which responds to a String message "delete_all"
    receive("delete_all") {
        self.array.deleteAll();
    }
}