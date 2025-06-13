import "./messages.tact";



contract UniqueIdItem {
    master_contract: Address;
    id: String;
    is_initialized: Bool;

    init (master_contract: Address, id: String) {
        require(sender() == master_contract, "Only master_contract allowed [INIT]");
        self.master_contract = master_contract;
        self.id = id;
        self.is_initialized = false;

    }


    receive(msg: DepositeRewardInitiated) {
        let ctx: Context = context();

        require(ctx.sender == self.master_contract, "Only master_contract allowed");
        require(msg.id == self.id, "Check for nonsense");
        let id_checked: Bool = false;
        if (self.is_initialized == false) {
            self.is_initialized = true;
            id_checked = true;
        }

        send(SendParameters {
            to: self.master_contract,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: DepositeRewardIdChecked {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                box_id: msg.box_id,
                amount_reward: msg.amount_reward,
                amount_winners: msg.amount_winners,
                initiator: msg.initiator,
                id_checked: id_checked,
            }.toCell()
        });
    }

        receive(msg: PayForBoxInitiated) {
        let ctx: Context = context();

        require(ctx.sender == self.master_contract, "Only master_contract allowed");
        require(msg.id == self.id, "Check for nonsense");
        let id_checked: Bool = false;
        if (self.is_initialized == false) {
            self.is_initialized = true;
            id_checked = true;
        }

        send(SendParameters {
            to: self.master_contract,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: PayForBoxIdChecked {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                box_price: msg.box_price,
                box_id: msg.box_id,
                user_id: msg.user_id,
                initiator: msg.initiator,
                id_checked: id_checked,
            }.toCell()
        });
    }

        receive(msg: ClaimRewardInitiated) {
        let ctx: Context = context();

        require(ctx.sender == self.master_contract, "Only master_contract allowed");
        require(msg.id == self.id, "Check for nonsense");
        let id_checked: Bool = false;
        if (self.is_initialized == false) {
            self.is_initialized = true;
            id_checked = true;
        }

        send(SendParameters {
            to: self.master_contract,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ClaimRewardIdChecked {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                amount_reward: msg.amount_reward,
                box_id: msg.box_id,
                initiator: msg.initiator,
                id_checked: id_checked,
            }.toCell()
        });
    }

        receive(msg: ClaimIncomeInitiated) {
        let ctx: Context = context();

        require(ctx.sender == self.master_contract, "Only master_contract allowed");
        require(msg.id == self.id, "Check for nonsense");
        let id_checked: Bool = false;
        if (self.is_initialized == false) {
            self.is_initialized = true;
            id_checked = true;
            // Do we need to commit?
            // Think of different cases
            // Ask! if used but failed ID can be re-used?
            // Should check id_checked is Unique Id Manager to Fail next send?
        }

        send(SendParameters {
            to: self.master_contract,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ClaimIncomeIdChecked {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                amount: msg.amount,
                box_id: msg.box_id,
                user_id: msg.user_id,
                initiator: msg.initiator,
                id_checked: id_checked,
            }.toCell()
        });
    }

}