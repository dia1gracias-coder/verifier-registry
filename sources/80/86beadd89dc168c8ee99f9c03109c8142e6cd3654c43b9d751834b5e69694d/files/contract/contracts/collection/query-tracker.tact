// Constants for query tracking
trait QueryTrackerConstants {
    const ShiftKeySize: Int = 13; // For shift value (map key)
    const BitKeySize: Int = 10; // For bit position in cell
    const CellBitsSize: Int = 1023; // Maximum bits in cell
    const QueryIdBitsSize: Int = 64;
}

struct QueryParams {
    shift: Int as uint13;
    bit: Int as uint10;
}

// Query tracking trait for replay protection
trait QueryTracker with QueryTrackerConstants {
    oldQueries: map<Int as uint13, Cell>;
    queries: map<Int as uint13, Cell>;
    lastCleanTime: Int as uint64;
    timeoutSeconds: Int as uint22;

    fun extractQueryParams(queryId: Int): QueryParams {
        let dataSlice = beginCell().storeUint(queryId, 64).endCell().asSlice();

        dataSlice.skipBits(self.QueryIdBitsSize - (self.ShiftKeySize + self.BitKeySize));

        let shift = dataSlice.loadUint(self.ShiftKeySize);
        let bit = dataSlice.loadUint(self.BitKeySize);

        require(shift >= 0 && shift < (1 << self.ShiftKeySize), "Invalid shift value");

        require(bit >= 0 && bit < self.CellBitsSize, "Invalid bit number");

        return QueryParams { shift, bit };
    }

    fun isQueryProcessed(queryParams: QueryParams): Bool {
        self.cleanOldQueries();
        // Check if already executed in old queries
        if (self.oldQueries.get(queryParams.shift) != null) {
            let oldValue: Cell = self.oldQueries.get(queryParams.shift)!!;
            let oldSlice: Slice = oldValue.beginParse();

            oldSlice.skipBits(queryParams.bit);
            if (oldSlice.loadBit()) {
                return true;
            }
        }
        // Check if already executed in current queries
        if (self.queries.get(queryParams.shift) != null) {
            let currentValue: Cell = self.queries.get(queryParams.shift)!!;
            let currentSlice: Slice = currentValue.beginParse();

            if (queryParams.bit > 0) {
                currentSlice.skipBits(queryParams.bit);
            }
            if (currentSlice.loadBit()) {
                return true;
            }
        }

        return false;
    }

    fun markQueryIdAsProcessed(queryParams: QueryParams) {
        let bitfield: Cell = beginCell().endCell();
        if (self.queries.get(queryParams.shift) != null) {
            let currentValue = self.queries.get(queryParams.shift)!!;

            let currentSlice: Slice = currentValue.beginParse();

            let head: Slice = currentSlice.loadBits(queryParams.bit);

            let _ = currentSlice.loadBit(); // Skip the bit we're setting
            let tail: Slice = currentSlice;

            bitfield = beginCell()
                .storeSlice(head)
                .storeBool(true)
                .storeSlice(tail)
                .endCell();
        } else {
            let currentSlice = beginCell().storeUint(0, 256).storeUint(0, 256).storeUint(0, 256).storeUint(0, 255).endCell().asSlice().asCell().beginParse();

            let head: Slice = currentSlice.loadBits(queryParams.bit);

            let _ = currentSlice.loadBit(); // Skip the bit we're setting
            let tail: Slice = currentSlice;

            bitfield = beginCell()
                .storeSlice(head)
                .storeBool(true)
                .storeSlice(tail)
                .endCell();
        }
        self.queries.set(queryParams.shift, bitfield);
    }

    inline fun cleanOldQueries() {
        if (self.lastCleanTime < now() - self.timeoutSeconds) {
            if (self.lastCleanTime < now() - (self.timeoutSeconds * 2)) {
                self.oldQueries = emptyMap();
            } else {
                self.oldQueries = self.queries;
            }

            self.queries = emptyMap();

            self.lastCleanTime = now();
        }
    }
}
