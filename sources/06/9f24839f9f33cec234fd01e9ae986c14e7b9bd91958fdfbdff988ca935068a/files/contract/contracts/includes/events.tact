import "./struct";
message(0x7bfa4800) CountryTokenDeployed {
    id: Int as uint16;
    content: Cell;
    timestamp: Int as uint32;
}
message(0x7bfa4801) BatchAddedUserHoldings {
    country: Int as uint16;
    user_amount: map<Address, Int>;
    timestamp: Int as uint32;
}
message(0x7bfa4802) BatchRemovedUserHoldings {
    country: Int as uint16;
    user_amount: map<Address, Int>;
    timestamp: Int as uint32;
}
message(0x7bfa4803) TransactionFeeChanged {
    tx_fee: Int as uint16;
    timestamp: Int as uint32;
}
message(0x7bfa4804) FeeWalletChanged {
    fee_wallet: Address;
    timestamp: Int as uint32;
}
message(0x7bfa4805) TokenBought {
    country: Int as uint16;
    amount: Int as coins;
    buyer: Address;
    timestamp: Int as uint32;
}
message(0x7bfa4806) TokenSold {
    country: Int as uint16;
    amount: Int as coins;
    seller: Address;
    timestamp: Int as uint32;
}
message(0x7bfa4807) AsymptoteChanged {
    country: Int as uint16;
    asymptote: Int;
    timestamp: Int as uint32;
}
message(0x7bfa4808) ScaleParamChanged {
    country: Int as uint16;
    scale_param: Int;
    timestamp: Int as uint32;
}
message(0x7bfa4809) CountryTokenLockStatusChanged {
    country: Int as uint16;
    status: Bool;
    timestamp: Int as uint32;
}
message(0x7bfa480a) TokensRedeemed {
    country: Int as uint16;
    amount: Int as coins;
    receiver: Address;
    timestamp: Int as uint32;
}
message(0x7bfa480b) TokensStaked {
    country: Int as uint16;
    amount: Int as coins;
    staker: Address;
    timestamp: Int as uint32;
}
message(0x7bfa480c) AttackCostRemoved {
    nonce: Int;
    country: Int as uint16;
    user_amount: map<Address, Int>;
    timestamp: Int as uint32;
}
message(0x7bfa480d) CountryDeployed {
    id: Int as uint16;
    token_address: Address;
    timestamp: Int as uint32;
}
message(0x7bfa480e) CountryHoldingRemoved {
    country: Int as uint16;
    amount: Int as coins;
    timestamp: Int as uint32;
}
message(0x7bfa480f) BatchCountryHoldingRemoved {
    query_id: Int;
    country_percentage: map<Int as uint16, Int as uint32>;
    timestamp: Int as uint32;
}
message(0x7bfa4810) CountryHoldingAdded {
    country: Int as uint16;
    amount: Int as coins;
    timestamp: Int as uint32;
}
message(0x7bfa4811) BatchCountryHoldingAdded {
    query_id: Int;
    country_amount: map<Int as uint16, Int>;
    timestamp: Int as uint32;
}
message(0x7bfa4812) CustomAttackMinted {
    minter: Address;
    item_id: Int as uint64;
    timestamp: Int as uint32;
}
message(0x7bfa4813) GrowthRateChanged {
    country: Int as uint16;
    growth_rate: Int;
    timestamp: Int as uint32;
}