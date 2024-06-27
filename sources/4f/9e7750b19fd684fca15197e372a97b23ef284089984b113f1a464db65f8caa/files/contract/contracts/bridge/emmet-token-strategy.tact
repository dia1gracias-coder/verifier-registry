const NOTHING: Int = 0;
// CCTP options (not available on TON)
// const cctpBurn: Int = 0;
// const cctpClaim: Int = 0;
// Conventional options (possible and available)
const LOCK: Int = 1;
const MINT: Int = 2;
const BURN: Int = 3;
// Liquidity Pool options (not implemented for now)
// const passToLP: Int = 0;
// const transferFromLP: Int = 0;
// Swap Options (not implemented for now)
// const balancer: Int = 0;
// const pancakeSwap: Int = 0;
// const sushiSwap: Int = 0;
// const uiswapV2: Int = 0;
// const uniswapV3: Int = 0;
// Bridge Utils
const SAVE_IN_TX: Int = 4;
const VERIFY_SIGNATURE: Int = 5;
const UNLOCK: Int = 6;

const UPDATION: Int = 1;
const ADDITION: Int = 2;
struct Strategies {
    strategies: map<Int, Steps>;
}
struct ToTokenCrossChainStrategy {
    to_token: map<Int, CrossChainStrategy>;
}
struct CrossChainTokenStrategy {
    from_token: map<Int, ToTokenCrossChainStrategy>;
}

struct FromTokenToTargetTokenToSteps {
    i: map<Int, TargetTokenToSteps>;
}
struct TargetTokenToSteps {
    // TargetToken -> Steps
    i: map<Int, Steps>;
}
struct Steps {
    // Int -> Steps
    steps: map<Int, Int>;
    size: Int;
}
struct CrossChainStrategy {
    local_steps: Steps;
    foreign_steps: Steps;
}
struct TargetTokenToCrossChainStrategy {
    // Target Token -> Cross Chain Strategy
    i: map<Int, CrossChainStrategy>;
}
struct FromTokenToTargetTokenToCrossChainStrategy {
    // From Token -> TargetTokenToCrossChainStrategy
    i: map<Int, TargetTokenToCrossChainStrategy>;
}
trait EmmetTokenStrategy {
    // From Chain -> Struct {  i: From Token -> TargetTokenToSteps  }
    incoming_token_strategy: map<Int, FromTokenToTargetTokenToSteps>;
    // Target Chain -> Struct { i: From Token -> Struct { i: Target Token -> CrossChainStrategy } } }
    cross_chain_token_storage: map<Int, FromTokenToTargetTokenToCrossChainStrategy>;

    fun get_incoming_strategy(from_chain_id: Int, from_token: Int, target_token: Int): Steps {
        let from_token_strats_opt: FromTokenToTargetTokenToSteps? = self.incoming_token_strategy.get(from_chain_id);
        require(from_token_strats_opt != null, "Unsupported incoming token strategy for from chain id");
        let target_token_strats_opt: TargetTokenToSteps? = (from_token_strats_opt!!).i.get(from_token);
        require(target_token_strats_opt != null, "Unsupported incoming token strategy for from_token");
        let steps_opt: Steps? = (target_token_strats_opt!!).i.get(target_token);
        require(steps_opt != null, "Unsupported incoming token strategy for from_token -> target_token");
        return steps_opt!!;
    }

    fun get_cross_chain_strategy(target_chain: Int, from_token: Int, target_token: Int): CrossChainStrategy {
        let from_token_to_target_token_to_cross_chain_strategy_opt: FromTokenToTargetTokenToCrossChainStrategy? = self.cross_chain_token_storage.get(target_chain
        );
        require(from_token_to_target_token_to_cross_chain_strategy_opt != null,
            "Unsupported to chain for cross chain token strategy storage"
        );
        let from_token_to_target_token_to_cross_chain_strategy: FromTokenToTargetTokenToCrossChainStrategy = from_token_to_target_token_to_cross_chain_strategy_opt!!;
        let target_token_to_cross_chain_strategy_opt: TargetTokenToCrossChainStrategy? = from_token_to_target_token_to_cross_chain_strategy.i.get(from_token
        );
        require(target_token_to_cross_chain_strategy_opt != null,
            "Unsupported from_token for cross chain token strategy storage"
        );
        let target_token_to_cross_chain_strategy: TargetTokenToCrossChainStrategy = target_token_to_cross_chain_strategy_opt!!;
        let cross_chain_strategy_opt: CrossChainStrategy? = target_token_to_cross_chain_strategy.i.get(target_token);
        require(cross_chain_strategy_opt != null, "Unsupported target_token for cross chain token strategy storage");
        return cross_chain_strategy_opt!!;
    }

    fun delete_cross_chain_strategy(target_chain: Int, from_token: Int, target_token: Int) {
        let from_token_to_target_token_to_cross_chain_strategy_opt: FromTokenToTargetTokenToCrossChainStrategy? = self.cross_chain_token_storage.get(target_chain
        );
        require(from_token_to_target_token_to_cross_chain_strategy_opt != null,
            "Unsupported to chain for cross chain token strategy storage"
        );
        let from_token_to_target_token_to_cross_chain_strategy: FromTokenToTargetTokenToCrossChainStrategy = from_token_to_target_token_to_cross_chain_strategy_opt!!;
        let target_token_to_cross_chain_strategy_opt: TargetTokenToCrossChainStrategy? = from_token_to_target_token_to_cross_chain_strategy.i.get(from_token
        );
        require(target_token_to_cross_chain_strategy_opt != null,
            "Unsupported from_token for cross chain token strategy storage"
        );
        let target_token_to_cross_chain_strategy: TargetTokenToCrossChainStrategy = target_token_to_cross_chain_strategy_opt!!;
        target_token_to_cross_chain_strategy.i.set(target_token, null);
        from_token_to_target_token_to_cross_chain_strategy.i.set(from_token, target_token_to_cross_chain_strategy);
        self.cross_chain_token_storage.set(target_chain, from_token_to_target_token_to_cross_chain_strategy);
    }

    fun delete_internal_strategy(from_chain_id: Int, from_token: Int, target_token: Int) {
        let ftttts_opt: FromTokenToTargetTokenToSteps? = self.incoming_token_strategy.get(from_chain_id);
        require(ftttts_opt != null, "Unsupported incoming token strategy for from_chain_id");
        let ftttts: FromTokenToTargetTokenToSteps = ftttts_opt!!;
        let ttts_opt: TargetTokenToSteps? = ftttts.i.get(from_token);
        require(ttts_opt != null, "Unsupported incoming token strategy for from token");
        let ttts: TargetTokenToSteps = ttts_opt!!;
        ttts.i.set(target_token, null);
        ftttts.i.set(from_token, ttts);
        self.incoming_token_strategy.set(from_chain_id, ftttts);
    }

    fun set_cross_chain_strategy(target_chain: Int,
        from_token: Int,
        target_token: Int,
        local_steps: Steps,
        foreign_steps: Steps) {
        let ccs: CrossChainStrategy = CrossChainStrategy{local_steps: local_steps, foreign_steps: foreign_steps};
        let from_token_to_target_token_to_cross_chain_strategy_opt: FromTokenToTargetTokenToCrossChainStrategy? = self.cross_chain_token_storage.get(target_chain
        );
        if (from_token_to_target_token_to_cross_chain_strategy_opt == null) {
            from_token_to_target_token_to_cross_chain_strategy_opt = FromTokenToTargetTokenToCrossChainStrategy{
                i: emptyMap()
            };
        }
        let from_token_to_target_token_to_cross_chain_strategy: FromTokenToTargetTokenToCrossChainStrategy = from_token_to_target_token_to_cross_chain_strategy_opt!!;
        let target_token_to_cross_chain_strategy_opt: TargetTokenToCrossChainStrategy? = from_token_to_target_token_to_cross_chain_strategy.i.get(from_token
        );
        if (target_token_to_cross_chain_strategy_opt == null) {
            target_token_to_cross_chain_strategy_opt = TargetTokenToCrossChainStrategy{i: emptyMap()};
        }
        let target_token_to_cross_chain_strategy: TargetTokenToCrossChainStrategy = target_token_to_cross_chain_strategy_opt!!;
        target_token_to_cross_chain_strategy.i.set(target_token, ccs);
        from_token_to_target_token_to_cross_chain_strategy.i.set(from_token, target_token_to_cross_chain_strategy);
        self.cross_chain_token_storage.set(target_chain, from_token_to_target_token_to_cross_chain_strategy);
    }

    fun set_incoming_strategy(from_chain_id: Int, from_token: Int, target_token: Int, local_steps: Steps) {
        let fttttts_opt: FromTokenToTargetTokenToSteps? = self.incoming_token_strategy.get(from_chain_id);
        if (fttttts_opt == null) {
            fttttts_opt = FromTokenToTargetTokenToSteps{i: emptyMap()};
        }
        let fttttts: FromTokenToTargetTokenToSteps = fttttts_opt!!;
        let ttts_opt: TargetTokenToSteps? = fttttts.i.get(from_token);
        if (ttts_opt == null) {
            ttts_opt = TargetTokenToSteps{i: emptyMap()};
        }
        let target_tokens_to_steps: TargetTokenToSteps = ttts_opt!!;
        target_tokens_to_steps.i.set(target_token, local_steps);
        fttttts.i.set(from_token, target_tokens_to_steps);
        self.incoming_token_strategy.set(from_chain_id, fttttts);
    }

    get fun incoming_strategy(): map<Int, FromTokenToTargetTokenToSteps> {
        return self.incoming_token_strategy;
    }

    get fun cross_chain_strategy(): map<Int, FromTokenToTargetTokenToCrossChainStrategy> {
        return self.cross_chain_token_storage;
    }
}