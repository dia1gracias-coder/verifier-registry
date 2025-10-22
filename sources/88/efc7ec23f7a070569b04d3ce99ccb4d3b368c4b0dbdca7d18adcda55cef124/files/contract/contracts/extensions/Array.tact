struct Array {
    array: map<Int as uint8, Int as uint64>;
    length: Int as uint8;
}

extends fun getIndex(self: Array, index: Int): Int {
    require(self.length > 0, "No items in the array!");
    require(index >= 0, "Index of the item cannot be negative!");
    require(index < self.length, "Index is out of array bounds!");
    
    return self.array.get(index)!!;
}

extends mutates fun decrementIndex(self: Array, index: Int) {
    require(self.length > 0, "No items in the array!");
    require(index >= 0, "Index of the item cannot be negative!");
    require(index < self.length, "Index is out of array bounds!");
    require(self.getIndex(index) != 0, "Underflow");

    self.array.replace(index, self.getIndex(index) - 1);
}