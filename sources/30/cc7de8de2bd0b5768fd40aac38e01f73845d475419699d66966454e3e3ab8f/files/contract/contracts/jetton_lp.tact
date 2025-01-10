import "./tep74/messages.tact";
import "./base_lp.tact";
import "./messages.tact";
import "./events.tact";
import "./constants.tact";

contract JettonLP with BaseLP {

    admin:                      Address;        // Contract admin address
    available_underlying:       Int;            // Total amount of the staked underlying jetton
    bridge:                     Address;        // The address of the bridge role
    boost_query_id:             Int;            // query_id that should NOT transfer underlying
    cfo:                        Address;        // This contract's Chief Financial Officer
    content:                    Cell;           // TEP-64 Token Data
    decimals:                   Int;            // Underlying asset's decimal points
    deployed:                   Int;            // Deployment timestamp
    deposits:                   map<Address, Position>; // User deposits hashmap
    fee_growth_global:          Int;            // Global fee counter
    gas_cost:                   Int;            // Configurable gas cost for operations
    query_id:                   Int;            // Transaction counter
    mintable:                   Bool;           // Flag indicating whether minting is allowed
    owner:                      Address;        // Trait "JettonMaster" requires field "owner"
    protocolFee:                Int;            // Protocol share of the fee
    protocol_fee_amount:        Int;            // Protocol fee storage slot
    roles:                      map<Int, RoleData>; // Roles hashmap
    stake_token:                Address;        // Address of the underlying Jetton Master
    tokenFee:                   Int;            // Underlying token usage fee
    token_wallet:               Address;        // LP's wallet of the Jetton
    total_supply:               Int;            // The total number of issued LP jettons

    init(
        admin:                  Address,
        cfo:                    Address,
        bridge:                 Address,
        stake_token:            Address,
        decimals:               Int,
        protocolFee:            Int,
        tokenFee:               Int,
        content:                Cell
    ) {
        require(protocolFee <= tokenFee, "Protocol fee cannot exceed the token fee.");

        self.admin = admin;
        self.bridge = bridge;
        self.boost_query_id = 0;
        self.cfo = cfo;
        self.content = content;
        self.owner = sender();
        self.total_supply = 0;
        self.query_id = 0;
        self.mintable = true;
        self.available_underlying = 0;
        self.stake_token = stake_token;
        self.deployed = now();
        self.fee_growth_global = 0;
        self.protocol_fee_amount = 0;
        self.token_wallet = newAddress(0, 0);
        self.decimals = decimals;
        self.protocolFee = protocolFee;
        self.tokenFee = tokenFee;
        self.gas_cost = ton("0.03");
        self._grant_role(self.admin_role_id(), admin);
        self._grant_role(self.bridge_role_id(), bridge);
        self._grant_role(self.cfo_role_id(), cfo);
    }

    /// @dev Accept TON without any message
    receive(){}

    /// @dev Convert deposited amount to rewards
    receive(msg: Boost) {
        require(
            self.deposits.get(sender()) != null, 
            "Boost: no deposit to convert to rewards"
        );

        require(
            self.get_balance(sender()) >= msg.amount, 
            "Insufficient staker's balance to withdraw the amount."
        );

        // self.query_id will be incremented in self.burn
        self.boost_query_id = self.query_id + 1;

        // Burn LP tokens (in sender's JettonWallet & Jettonmaster)
        self.burn(sender(), msg.amount);

        // Update rewards
        self.boost(msg.amount);
    }

    /// @dev CFO can withdraw excess of TON if any
    receive(msg: WithdrawGas) {
        self.only_cfo();

        let amount: Int = myBalance() >= msg.amount
            ? msg.amount
            : myBalance();

        // Transfer TON
        send(SendParameters{
            to:         self.cfo,
            value:      amount,
            mode:       SendRemainingValue,
            bounce:     false
        });
    }

    /// @dev CFO withdraws the Emmet.Community fee if any
    receive(msg: WithdrawProtocolFee) {
        self.only_cfo();

        require(
            self.protocol_fee_amount > 0,
            "WithdrawProtocolFee: No protocol fee to withdraw"
        );

        let amount: Int = self.available_underlying >= self.protocol_fee_amount
            ? self.protocol_fee_amount
            : self.available_underlying;

        self.query_id += 1;

        let withdrawBody: Cell = beginCell()
            .storeUint(0xf8a7ea5, 32)       // op::transfer
            .storeUint(self.query_id, 64)   // query_id
            .storeCoins(amount)             // amount
            .storeAddress(self.cfo)         // to
            .storeAddress(self.cfo)         // response_destinaiton
            .storeMaybeRef(null)            // custom payload
            .storeCoins(self.gas_cost)      // forward_ton_amount
            .storeMaybeRef(null)            // forward_payload
            .endCell();

        send(SendParameters{
                to:         self.token_wallet,
                body:       withdrawBody,
                value:      self.gas_cost * 2,
                mode:       SendPayGasSeparately,
                bounce:     true
            }
        );

        emit(RewardsPaid{user: self.cfo, amount: amount}.toCell());

        self.available_underlying -= amount;
        self.protocol_fee_amount -= amount;
    }

    receive(msg: WithdrawRebalance) {
        self.only_cfo();

        require(self.available_underlying >= msg.amount, "WithdrawRebalance: Insufficient balance for rebalancing");

        self.available_underlying -= msg.amount;


    }

    // Called on Jetton transfer to the JettonLP contract
    receive(msg: TokenNotification){

        require(
            sender() == self.token_wallet, 
            "TokenNotification: Unauthorised call"
        );

        self.deposit(msg.amount, msg.from);

    }

    // Use liquidity (by Bridge only)
    receive(msg: ReleaseTokens){

       let brb: BridgeBoilerplate = self.bridge_release_boilerplate(msg);

        self.query_id += 1;

        let releaseBody: Cell = beginCell()
            .storeUint(0xf8a7ea5, 32)       // op::transfer
            .storeUint(self.query_id, 64)   // query_id
            .storeCoins(brb.amount)         // amount
            .storeAddress(msg.to)           // to
            .storeAddress(msg.to)           // response_destinaiton
            .storeMaybeRef(null)            // custom payload
            .storeCoins(self.gas_cost)      // forward_ton_amount
            .storeMaybeRef(brb.payload)     // forward_payload
            .endCell();

        emit(LPTransfer{amount: brb.amount, to: msg.to}.toCell());

        send(SendParameters{
                to:         self.token_wallet,
                body:       releaseBody,
                value:      self.gas_cost * 2,
                mode:       SendPayGasSeparately,
                bounce:     true
            }
        );
        
    }

    /// @dev Called by the LP wallet to update the position & trasnfer underlying
    receive(msg: TokenBurnNotification){

        self.token_burn_boilerplate(msg);

        self.available_underlying -= msg.amount;

        if(msg.query_id != self.boost_query_id){

            let transferMessage: Cell = beginCell()
                .storeUint(0xf8a7ea5, 32)       // op::transfer
                .storeUint(msg.query_id, 64)    // query_id
                .storeCoins(msg.amount)         // amount
                .storeAddress(msg.sender)       // to
                .storeAddress(msg.sender)       // response_destinaiton
                .storeMaybeRef(null)            // custom payload
                .storeCoins(self.gas_cost)      // forward_ton_amount
                .storeMaybeRef(null)            // forward_payload
                .endCell();

            // Transfer Jettons
            send(SendParameters{
                to:                         self.token_wallet,
                body:                       transferMessage,
                value:                      self.gas_cost * 2,
                mode:                       SendPayGasSeparately,
                bounce:                     true
            });
        } else {
            self.boost_query_id = 0;
        }

        // Cashback
        send(SendParameters{
                to: msg.sender,
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: TokenExcesses{query_id: self.query_id}.toCell()
            }
        );
    }

    // Withdraw Jettons
    receive(msg: WithdrawRewards) {

        let rewards: Int = self.withdraw_rewards_boilerplate(msg);

        if(rewards > 0){
            
            self.query_id += 1;

            self.available_underlying -= rewards;

            let withdrawBody: Cell = beginCell()
                .storeUint(0xf8a7ea5, 32)       // op::transfer
                .storeUint(self.query_id, 64)   // query_id
                .storeCoins(rewards)            // amount
                .storeAddress(sender())         // to
                .storeAddress(sender())         // response_destinaiton
                .storeMaybeRef(null)            // custom payload
                .storeCoins(self.gas_cost)      // forward_ton_amount
                .storeMaybeRef(null)            // forward_payload
            .endCell();

            // Transfer Jettons
            send(SendParameters{
                to:                         self.token_wallet,
                body:                       withdrawBody,
                value:                      self.gas_cost * 2,
                mode:                       SendPayGasSeparately,
                bounce:                     true
            });

        }
    }

    /// @dev Fetches the Underlying Jetton address
    get fun underlying(): Address {
        return self.stake_token;
    }

}