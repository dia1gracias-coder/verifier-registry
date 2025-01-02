import "./tep74/messages.tact";
import "./base_lp.tact";
import "./messages.tact";
import "./events.tact";
import "./constants.tact";

contract JettonLP with BaseLP {

    admin:                      Address;        // Contract admin address
    available_underlying:       Int;            // Total amount of the staked underlying jetton
    bridge:                     Address;        // The address of the bridge role
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

    receive(){}

    /// @dev CFO can withdraw excess of TON if any
    receive(msg: WithdrawGas) {
        self.only_cfo();
        require(myBalance() >= msg.amount, "WithdrawGas: Insufficient TON balance");
        // Transfer TON
        send(SendParameters{
            to:         self.cfo,
            value:      msg.amount,
            mode:       SendPayGasSeparately,
            bounce:     false
        });
    }

    // Called on Jetton transfer to the JettonLP contract
    receive(msg: TokenNotification){

        // If there is payload and it equals boost=1
        if(
            msg.forward_payload.bits() >= 8 
            && msg.forward_payload.loadUint(8) == BOOST
        ){
            self.boost(msg.amount);
        } else { // Deposit by default
            self.deposit(msg.amount, msg.from);
        }

    }

    // Use liquidity (by Bridge only)
    receive(msg: ReleaseTokens){

       let brb: BridgeBoilerplate = self.bridge_release_boilerplate(msg);

        self.query_id += 1;

        send(SendParameters{
                to:                         self.token_wallet,
                body: TokenTransfer{
                    amount:                 brb.amount,
                    sender:                 msg.to,
                    response_destination:   msg.to,
                    custom_payload:         null,
                    forward_ton_amount:     0,
                    forward_payload:        brb.payload.asSlice(),
                    query_id:               self.query_id
                }.toCell(),
                value:      0,
                mode:       SendRemainingValue,
                bounce:     true
            }
        );

        emit(LPTransfer{amount: brb.amount, to: msg.to}.toCell());
    }

    receive(msg: TokenBurnNotification){

        self.token_burn_boilerplate(msg);

        self.available_underlying -= msg.amount;

        self.query_id += 1;

        // Transfer Jettons
        send(SendParameters{
            to:                         self.token_wallet,
            body: TokenTransfer{
                amount:                 msg.amount,
                sender:                 msg.sender,
                response_destination:   msg.sender,
                custom_payload:         null,
                forward_ton_amount:     0,
                forward_payload:        beginCell().asSlice(),
                query_id:               self.query_id
            }.toCell(),
            value:                      self.gas_cost,
            mode:                       SendPayGasSeparately,
            bounce:                     true
        });

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

            // Transfer Jettons
            send(SendParameters{
                to:                         self.token_wallet,
                body: TokenTransfer{
                    amount:                 rewards,
                    sender:                 sender(),
                    response_destination:   sender(),
                    custom_payload:         null,
                    forward_ton_amount:     self.gas_cost,
                    forward_payload:        beginCell().asSlice(),
                    query_id:               self.query_id
                }.toCell(),
                value:                      self.gas_cost,
                mode:                       SendPayGasSeparately,
                bounce:                     true
            });

        }
    }

    get fun underlying(): Address {
        return self.stake_token;
    }

}