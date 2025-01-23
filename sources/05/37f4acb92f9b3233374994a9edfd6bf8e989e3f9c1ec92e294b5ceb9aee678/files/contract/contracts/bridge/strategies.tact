
// Bridge Stategies

// Zero placeholder ensuring steps are non-zero
const NOTHING:      Int = 0;
// CCTP for compatibility with EVM (unused in TON)
const CCTP_BURN:    Int = 1;   // Reserved for future
const CCTP_CLAIM:   Int = 2;   // Reserved for future
// Conventonal Lock & Mint
const LOCK:         Int = 3;
const MINT:         Int = 4;
const BURN:         Int = 5;
const UNLOCK:       Int = 6;
// Liquidity Pool
const LP_LOCK:      Int = 7;
const LP_RELEASE:   Int = 8;
// SWAPs (up to 6)
const SWAP_1:       Int = 9;    // Ston.fi
const SWAP_2:       Int = 10;   // DeDust
const SWAP_3:       Int = 11;   // Reserved for future
const SWAP_4:       Int = 12;   // Reserved for future
const SWAP_5:       Int = 13;   // Reserved for future
const SWAP_6:       Int = 14;   // Reserved for future

/**
* Token strategy path
* 
* steps     - steps `path: step[]` accessed by index
* size      - number of steps AKA `path.length()`
*/
struct Steps {
    //                  Index -> Step
    path:               map<Int, Int>;
    size:               Int;
}

/**
* Storage aggregator for cross-chain strategy
* 
* local_steps   - actions required for a from_token
* foreign_steps - actions on the foreging chain (required for fee compensation calculation)
*/
struct Strategies {
    foreign:            Steps;
    incomming:          Steps;
    local:              Steps;
}

struct ToTokenMap {
    //               toTokenKey -> Strategies
    i:                  map<Int, Strategies>;
}

struct FromTokenMap {
    //              fromTokenKey -> ToTokenMap
    i:                  map<Int, ToTokenMap>;
}

/**
*  Strategy getting & setting logic
*/
trait EmmetTokenStrategy {
    //              otherChainId -> FromTokenMap
    token_strategies:   map<Int, FromTokenMap>;

    /**
    * Fetches an empty strategies struct
    */
    inline fun _empty_strategies(): Strategies {
        // Step 1:  create an empty response
        let empty_steps: Steps = Steps{path: emptyMap(), size: 0};

        // Step 2: populate & return the empty strategies
        return Strategies{
            foreign:    empty_steps,
            incomming:  empty_steps,
            local:      empty_steps
        };
    }

    /**
    * Fetches the stored token strategies if any
    * @chain_id     another chain ID
    * @from_token   original token symbol
    * @to_token     desired token symbol
    */
    inline fun _get_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int
    ): Strategies {
        
        // Step 1:  Extract the token strategies by chain
        let from_token_map: FromTokenMap? = self.token_strategies.get(chain_id);

        // Step 2:  Check the result and continue or return early
        if(from_token_map == null){return self._empty_strategies();}

        // Step 3:  Extract the target token strategies
        let to_token_map: ToTokenMap? = from_token_map!!.i.get(from_token);

        // Step 4:  Check the result and continue or return early
        if(to_token_map == null){return self._empty_strategies();}

        // Step 5:  Extract the target token strategy
        let final_strategies: Strategies? = to_token_map!!.i.get(to_token);

        // Step 6:  Check the result and continue or return early
        if(final_strategies == null){return self._empty_strategies();}

        // Step 7: return
        return final_strategies!!;
    }

    inline fun _get_foreign_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int
    ): Steps {
        let _strategies: Strategies = self._get_strategies(chain_id, from_token, to_token);
        return _strategies.foreign;
    }

    get fun get_foreign_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int
    ): Steps {
        return self._get_foreign_strategies(chain_id, from_token, to_token);
    }

    inline fun _get_incoming_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int
    ): Steps {
        let _strategies: Strategies = self._get_strategies(chain_id, from_token, to_token);
        return _strategies.incomming;
    }

    get fun get_incoming_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int
    ): Steps {
        return self._get_incoming_strategies(chain_id, from_token, to_token);
    }

    inline fun _get_local_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int
    ): Steps {
        let _strategies: Strategies = self._get_strategies(chain_id, from_token, to_token);
        return _strategies.local;
    }

    get fun get_local_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int
    ): Steps {
        return self._get_local_strategies(chain_id, from_token, to_token);
    }

    get fun get_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int
    ): Strategies {
        return self._get_strategies(chain_id, from_token, to_token);
    }

    fun delete_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int
    ) {
        // Step 1: Extract the token strategies by chain
        let from_token_map: FromTokenMap? = self.token_strategies.get(chain_id);

        // Step 2: Check if the map exists; if not, return early
        if (from_token_map == null) { return; }
        let temp_from_token_map: FromTokenMap = from_token_map!!;

        // Step 3: Extract the target token strategies
        let to_token_map: ToTokenMap? = from_token_map!!.i.get(from_token);

        // Step 4: Check if the map exists; if not, return early
        if (to_token_map == null) { return; }

        // Step 5: Set the value to null
        let temp_to_token_map: ToTokenMap = to_token_map!!;
        temp_to_token_map.i.set(to_token, null);

        // Step 6: Update the storage
        temp_from_token_map.i.set(from_token, temp_to_token_map);
        self.token_strategies.set(chain_id, temp_from_token_map);
    }

    fun set_strategies(
        chain_id:       Int,
        from_token:     Int,
        to_token:       Int,
        foreign:        Steps,
        incomming:      Steps,
        local:          Steps
    ) {
        // Step 1: Extract the token strategies by chain
        let from_token_map: FromTokenMap? = self.token_strategies.get(chain_id);
        // Allocate a temp mapping
        let temp_from_token_map: FromTokenMap = from_token_map == null
            ? FromTokenMap{i: emptyMap()} // Create an empty map
            : from_token_map!!; // Or preserve the existing ones

        // Step 2: Extract the target token strategies
        let to_token_map: ToTokenMap = ToTokenMap{i: emptyMap()};

        // Step 3: prepare the strategies struct
        let new_strategies: Strategies = Strategies{
            foreign:    foreign,
            incomming:  incomming,
            local:      local
        };

        // Step 4: save to the storage
        to_token_map.i.set(to_token, new_strategies);
        temp_from_token_map.i.set(from_token, to_token_map);
        self.token_strategies.set(chain_id, temp_from_token_map);
    }
}