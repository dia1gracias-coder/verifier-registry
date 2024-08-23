const INITIAL_VIRTUAL_TOKEN_RESERVE: Int = ton("450660000000");
const VIRTUAL_TOKEN_RESERVE_WHEN_ADD_LIQUIDITY: Int = ton("117550000000");
const TOTAL_SUPPLY: Int = ton("420000000000");
const INITIAL_VIRTUAL_TON_RESERVE: Int = ton("29");
const BONDING_CURVE_FEE_BIPS: Int = 100;
const FEE_BIPS_FOR_CREATOR: Int = 1000;
const PRECISION: Int = 10000;
const DEX_FEE_BIPS: Int = 25;
const ZERO_ADDRESS: Address = newAddress(0, 0);
const BUY_GAS_FEE: Int = ton("0.02");
// this needs to be updated when deploying 
const FACTORY_DEPLOYER: Address = address("EQDIQ1YYmJoUS1EB9WmO6_9-GyWsN-V_pGMQ5C8g2V0SKQun");