
// Messages to BoxManager
// box_id  if (-1) then claim all boxes else: only box with box.id == box_id
// user Id | if (-1) then no user 


message DepositeRewardOriginal {
    signature: Slice;
    id: String;
    expire_at: Int;
    box_id: String;
    amount_reward: Int as coins;
    amount_winners: Int;
}

message PayForBoxOriginal {
    signature: Slice;
    id: String;
    expire_at: Int;
    box_price: Int as coins;
    box_id: String;
    user_id: String;
}


message ClaimRewardOriginal {
    signature: Slice;
    id: String;
    expire_at: Int;
    amount_reward: Int as coins;
    box_id: String;
}

message ClaimIncomeOriginal {
    signature: Slice;
    id: String;
    expire_at: Int;
    amount: Int as coins;
    box_id: String;  
    user_id: String; 
}


// Messages to Vault

message DepositeRewardConfirm {
    signature: Slice;
    id: String;
    expire_at: Int;
    box_id: String;
    amount_reward: Int as coins;
    amount_winners: Int;

    initiator: Address;
}

message PayForBoxConfirm {
    signature: Slice;
    id: String;
    expire_at: Int;
    box_price: Int as coins;
    box_id: String;
    user_id: String;

    initiator: Address;
}

message ClaimRewardConfirm {
    signature: Slice;
    id: String;
    expire_at: Int;
    amount_reward: Int as coins;
    box_id: String;

    initiator: Address;
}

message ClaimIncomeConfirm {
    signature: Slice;
    id: String;
    expire_at: Int;
    amount: Int as coins;
    box_id: String;
    user_id: String;

    initiator: Address;
}

// Util Messages

message SetBoxManager {
    box_manager: Address;
}

message SetUniqueIdManager {
    unique_id_manager: Address;
}

struct VaultData {
    owner: Address;
    box_manager: Address?;
    gas_required: Int as coins;
    balance: Int as coins;
}

struct BoxManagerData {
    owner: Address;
    income_vault: Address;
    reward_vault: Address;
    gas_required: Int as coins;
    unique_id_manager: Address?;
}


// UniqueIdManager Messages

message DepositeRewardInitiated {
    signature: Slice;
    id: String;
    expire_at: Int;
    box_id: String;
    amount_reward: Int as coins;
    amount_winners: Int;
    initiator: Address;
}

message PayForBoxInitiated {
    signature: Slice;
    id: String;
    expire_at: Int;
    box_price: Int as coins;
    box_id: String;
    user_id: String;
    initiator: Address;
}


message ClaimRewardInitiated {
    signature: Slice;
    id: String;
    expire_at: Int;
    amount_reward: Int as coins;
    box_id: String;
    initiator: Address;
}

message ClaimIncomeInitiated {
    signature: Slice;
    id: String;
    expire_at: Int;
    amount: Int as coins;
    box_id: String;  
    user_id: String; 
    initiator: Address;
}

struct UniqueIdManagerData {
    owner: Address;
    box_manager: Address?;
}

message DepositeRewardIdChecked {
    signature: Slice;
    id: String;
    expire_at: Int;
    box_id: String;
    amount_reward: Int as coins;
    amount_winners: Int;
    initiator: Address;
    id_checked: Bool;
}
message PayForBoxIdChecked {
    signature: Slice;
    id: String;
    expire_at: Int;
    box_price: Int as coins;
    box_id: String;
    user_id: String;
    initiator: Address;
    id_checked: Bool;
}

message ClaimRewardIdChecked {
    signature: Slice;
    id: String;
    expire_at: Int;
    amount_reward: Int as coins;
    box_id: String;
    initiator: Address;
    id_checked: Bool;
}

message ClaimIncomeIdChecked {
    signature: Slice;
    id: String;
    expire_at: Int;
    amount: Int as coins;
    box_id: String;  
    user_id: String; 
    initiator: Address;
    id_checked: Bool;
}