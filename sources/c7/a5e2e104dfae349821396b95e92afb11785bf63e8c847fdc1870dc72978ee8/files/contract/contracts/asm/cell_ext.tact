import "./cell_ext.fc";

@name(store_true)
native sTrue(src: Builder): Builder;
extends mutates fun storeTrue(self: Builder): Builder {
    return sTrue(self);
}

@name(store_zeroes)
native sZeroes(src: Builder, bits: Int): Builder;
extends mutates fun storeZeroes(self: Builder, bits: Int): Builder {
    return sZeroes(self, bits);
}
