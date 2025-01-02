import "@stdlib/deploy";
import "./LpJetton.tact";
import "./wallet_lp.tact";
import "./utils/access_control.tact";
import "./messages.tact";
import "./events.tact";
import "./constants.tact";

/// @dev Common TON & Jetton LP logic
trait BaseLP with Deployable, LPJetton, AccessControl {

    admin:                      Address;        // Contract admin address
    available_underlying:       Int;            // Total amount of the staked underlying jetton
    bridge:                     Address;        // The address of the bridge role
    cfo:                        Address;        // This contract's Chief Financial Officer
    content:                    Cell;           // TEP-64 Token Data
    decimals:                   Int;            // Underlying asset's decimal points
    deployed:                   Int;            // Deployment timestamp
    deposits:                   map<Address, Position>; // User deposits hashmap
    fee_growth_global:          Int;            // Global fee counter
    virtual const  feeDecimals: Int = 10_000;   // 100.00%
    gas_cost:                   Int;            // Configurable gas cost for operations
    query_id:                   Int;            // Transaction counter
    mintable:                   Bool;           // Flag indicating whether minting is allowed
    owner:                      Address;        // Trait "JettonMaster" requires field "owner"
    protocolFee:                Int;            // Protocol share of the fee
    protocol_fee_amount:        Int;            // Protocol fee storage slot
    roles:                      map<Int, RoleData>; // Roles hashmap
    tokenFee:                   Int;            // Underlying token usage fee
    token_wallet:               Address;        // LP's wallet of the Jetton
    total_supply:               Int;            // The total number of issued jettons

    //********************************************//
    //              Common functions              //
    //********************************************//

    // Notifies the JettonMaster (by the Wallet) upon transfer between users
    receive(msg: UpdateDeposits) {

        let jetton_wallet: Address = self.get_wallet_address(msg.receiver);
        require(sender() == jetton_wallet, "UpdateDeposit must originate from the LP wallet.");

        // Update or delete the sender's position
        let position_s: Position = self.deposits.get(msg.sender)!!;
        position_s.rewards += self.compute_rewards_for(msg.sender);
        position_s.balance -= msg.amount;
        self.update_position(msg.sender, position_s);

        // Create or update the receiver's position
        if(self.deposits.get(msg.receiver) == null){
            self.create_position(msg.receiver, msg.amount);
        } else {
            let position_r: Position = self.deposits.get(msg.receiver)!!;
            position_r.rewards += self.compute_rewards_for(msg.receiver);
            position_r.balance += msg.amount;
            self.update_position(msg.receiver, position_r);
        }
    }

    // Withdraw Deposits
    receive(msg: Withdraw) {
        
        require(msg.amount > 0, "Withdraw amount must be greater than zero.");
        if(self.deposits.get(sender()) == null){
            require(false, "The caller has no staking position to withdraw");
        }
        require(
            self.get_balance(sender()) >= msg.amount, 
            "Insufficient staker's balance to withdraw the amount."
        );

        // Burn LP tokens (in sender's JettonWallet & Jettonmaster)
        self.burn(sender(), msg.amount);
    }

    //********************************************//
    //              Admin functions               //
    //********************************************//

    receive(msg: SetAdmin) {
        self.only_admin();
        self._grant_role(self.admin_role_id(), msg.newAdmin);
        self._revoke_role(self.admin_role_id(), self.admin);
        self.admin = msg.newAdmin;
    }

    receive(msg: SetCFO) {
        self.only_admin();
        self._grant_role(self.cfo_role_id(), msg.newCFO);
        self._revoke_role(self.cfo_role_id(), self.cfo);
        self.cfo = msg.newCFO;
    }

    receive(msg: SetBridge) {
        self.only_admin();
        self._grant_role(self.bridge_role_id(), msg.newBridge);
        self._revoke_role(self.bridge_role_id(), self.bridge);
        self.bridge = msg.newBridge;
    }

    receive(msg: SetWalletAddress){
        self.only_admin();
        self.token_wallet = msg.token_wallet;
    }

    //********************************************//
    //               CFO functions                //
    //********************************************//

    receive(msg: UpdateFees) {
        self.only_cfo();
        require(msg.protocol_fee <= msg.token_fee, "Protocol fee cannot exceed token fee.");
        self.protocolFee = msg.protocol_fee;
        self.tokenFee = msg.token_fee;
    }

    receive(msg: UpdateGasCost) {
        self.only_cfo();
        require(msg.newGasCost > 0, "Gas cost must be positive.");
        self.gas_cost = msg.newGasCost;
    }

    //********************************************//
    //             Internal functions             //
    //********************************************//

    fun bridge_release_boilerplate(msg: ReleaseTokens): BridgeBoilerplate {

        let isBridge: Bool = self.has_role(context().sender, self.bridge_role_id());

        require(isBridge, "ReleaseTokens: Unauthorized release tokens call.");

        let rs: RewardSplit = self.split_rewards(msg.amount);

        self.protocol_fee_amount += rs.protocolFeeShare;

        self.fee_growth_global += rs.lpProvidersShare - rs.protocolFeeShare;

        let payload: Cell = beginCell().endCell();

        if (msg.body != null) {
            payload = (msg.body!!);
        }

        return BridgeBoilerplate{
            amount: msg.amount - rs.lpProvidersShare,
            payload: payload
        };
    }

    fun boost(amount: Int) {
        self.fee_growth_global += amount;
        self.available_underlying += amount;
    }

    fun calculateAPY(start: Int, token_decimals: Int, total_supply: Int, rewards: Int): Int {

        if(total_supply == 0 || rewards == 0) {
            return 0;
        }

        let decimals_amount: Int = pow(10, token_decimals);

        self.ensure_scale(decimals_amount, total_supply, rewards);

        let periods: Int = self.compounding_periods(start);

        let periodic_return_rate: Int = (
            (
                (rewards * decimals_amount * APY_DECIMALS) / total_supply
            ) / periods
        ) / APY_DECIMALS;

        let base: Int = decimals_amount + periodic_return_rate;

        let result : Int = decimals_amount;

        let i: Int = 0;

        repeat(periods) {
            result = (result * base) / decimals_amount;
            i = i + 1;
        }

        return ((result - decimals_amount ) * APY_DECIMALS) / decimals_amount;
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf LPWallet(owner_address, myAddress());
    }

    fun compounding_periods( start: Int): Int {
        // How many days elapsed since the contract deployment (min 0, max 365)
        let elapsedDays_: Int = self.elapsedDays(start);

        if (elapsedDays_ < 1) {
            elapsedDays_ = 1;
        } 
        return 
            elapsedDays_ > DAYS_IN_YEAR
                ? 1 
                : DAYS_IN_YEAR / elapsedDays_;
    }

    fun create_position(
        staker: Address,
        amount: Int
    ){
        self.deposits.set(staker, Position{
            balance: amount,
            last_fee_growth: self.fee_growth_global,
            rewards: 0
        });
    }

    /// @dev Deposit Jettons & creates or updates the position
    fun deposit(amount: Int, sender: Address) {
        require(amount > 0, "Deposit amount must be greater than zero.");

        // Increase staked value
        self.available_underlying += amount;

        // Mint LP tokens for the user
        self.mint(sender, amount, myAddress());

        if(self.deposits.get(sender) == null){
            self.create_position(sender, amount);
        } else {
            let position: Position = self.deposits.get(sender)!!;
            position.balance += amount;
            position.rewards += self.compute_rewards_for(sender);
            self.update_position(sender, position);
        }
    }

    fun elapsedDays( start: Int) : Int {
        let now_: Int = now();

        // May occur in tests or forked chain
        if (start > now_) {
            return 0;
        }

        // ElapsedDays = (Now - Start) / secondsInDay
        let inDays: Int = (now_ - start) / SECONDS_IN_DAY;


        // Limit the loop cycles
        if (inDays > DAYS_IN_YEAR) {
            inDays = DAYS_IN_YEAR;
        }
        return inDays;
    }

    fun ensure_scale(decimalsAmount: Int, totalSupply: Int, rewards: Int) {

        require(totalSupply > 0, "APY: totalSupply == 0");

        require(rewards > 0, "APY: rewards == 0");

        require((totalSupply / decimalsAmount > 0) && (rewards / decimalsAmount > 0),
            "APY: totalSupply and rewards are not on the same decimal scale"
        );
    }

    fun split_rewards(
         amount: Int
    ): RewardSplit
    {
        let protocolFeeShare: Int = (self.protocolFee > 0)
            ? (amount * self.protocolFee) / (self.feeDecimals)
            : 0;

        let lpProvidersShare: Int = (self.tokenFee > 0)
            ? (amount * self.tokenFee)/(self.feeDecimals)
            : 0;
        return RewardSplit {
            protocolFeeShare: protocolFeeShare,
            lpProvidersShare: lpProvidersShare
        };
    }

    fun token_burn_boilerplate(msg: TokenBurnNotification){

        self.requireSenderAsWalletOwner(msg.sender); // Check wallet

        if(self.deposits.get(msg.sender) == null){
            require(false, "TokenBurnNotification: Missing staker position");
        }

        require(
            self.total_supply >= msg.amount,
            "TokenBurnNotification: Amount exceeds total supply"
        );
        
        require(
            self.available_underlying >= msg.amount,
            "TokenBurnNotification: Amount exceeds underlying balance"
        );

        let position: Position = self.deposits.get(msg.sender)!!;

        self.total_supply -= msg.amount; // Update supply

        position.balance -= msg.amount;

        position.rewards += self.compute_rewards_for(msg.sender);

        self.update_position(msg.sender, position);

    }

    fun update_position(
        staker: Address,
        position: Position?
    ){
        let pos: Position = position!!;

        if(position == null || (pos.balance == 0 && pos.rewards == 0)){
            self.deposits.set(staker, null);
        }else {
            pos.last_fee_growth = self.fee_growth_global;
            self.deposits.set(staker, pos);
        }
    }

    fun withdraw_rewards_boilerplate(msg: WithdrawRewards): Int {
        if(self.deposits.get(sender()) == null){
            require(false, "The caller has no staking position to withdraw");
        }

        // Get the staking position
        let position: Position = self.deposits.get(sender())!!;

        // Compute the previous and the new rewards
        let rewards: Int = position.rewards + self.compute_rewards_for(sender());

        if(rewards == 0){
            return 0;
        }

        require(
            self.available_underlying >= rewards,
            "Insufficient LP balance to withdraw rewards"
        );

        // Update the state

        self.fee_growth_global -= rewards;

        position.rewards = 0;
        self.update_position(sender(), position);

        return rewards;
    }

    //*********************************//
    //             Getters             //
    //*********************************//

    /// @dev Calculates the staker's rewards
    fun compute_rewards_for(staker: Address): Int {

        if(self.deposits.get(staker) == null){
            return 0;
        }

        let sender_balance: Int = self.get_balance(staker);

        let position: Position = self.deposits.get(staker)!!;

        let fee_growth_delta: Int = self.fee_growth_global - position.last_fee_growth;

        if(fee_growth_delta > 0){
            let rewards: Int = (sender_balance * fee_growth_delta) / self.total_supply;
            return rewards;
        } else {
            return 0;
        }
    }

    /// @dev The current available APY percents
    get fun currentAPY(): Int {
        return self.calculateAPY(
            self.deployed, 
            self.decimals, 
            self.total_supply, 
            self.fee_growth_global
        );
    }

    /// @dev The underlying token decimal points
    get fun decimals(): Int {
        return self.decimals;
    }

    /// @dev The latest total earned but uncollected fee
    get fun feeGrowthGlobal(): Int {
        return self.fee_growth_global;
    }

    /// @dev The Admin address
    get fun get_admin(): Address {
        return self.admin;
    }

    get fun get_available_underlying(): Int {
        return self.available_underlying;
    }

    /// @dev The staker's balance
    fun get_balance(user: Address): Int {
        if (self.deposits.get(user) == null) {
            return 0;
        } else {
            let position: Position = self.deposits.get(user)!!;
            return position.balance;
        }
    }

    /// @dev The CFO address
    get fun get_cfo(): Address {
        return self.cfo;
    }

    /// @dev Fetches the LP storage in one request
    get fun get_data(): LPData {

        return LPData{
            apy: self.calculateAPY(self.deployed, self.decimals, self.total_supply, self.fee_growth_global),
            available_underlying: self.available_underlying,
            decimals: self.decimals,
            fee_growth_global: self.fee_growth_global,
            fee_decimals: self.feeDecimals,
            protocol_fee: self.protocolFee,
            protocol_fee_amount: self.protocol_fee_amount,
            token_fee: self.tokenFee,
            total_supply: self.total_supply
        }
    }

    get fun get_query_id(): Int {
        return self.query_id;
    }

    /// @dev fetches a staker's position
    get fun get_position(staker: Address): Position {
        if (self.deposits.get(staker) == null) {
            return Position {
                balance: 0,
                last_fee_growth: 0,
                rewards: 0
            }
        } else {
            let position = self.deposits.get(staker)!!;
            return Position {
                balance: position.balance,
                last_fee_growth: self.fee_growth_global,
                rewards: self.compute_rewards_for(staker)
            }
        }
    }

    get fun get_total_supply(): Int {
        return self.total_supply;
    }

    get fun get_underlying_wallet(): Address {
        return self.token_wallet;
    }

    /// @dev The protocol fee share (percents with 4 decimals)
    get fun protocolFee(): Int {
        return self.protocolFee;
    }

    /// @dev The protocol fee amount
    get fun protocolFeeAmount(): Int {
        return self.protocol_fee_amount;
    }

    /// @dev Computes the rewards a staker is eligible for at the moment
    get fun rewards(staker: Address): Int {
        return self.compute_rewards_for(staker);
    }

    /// @dev The token fee users pay for using the liquidity
    get fun tokenFee(): Int {
        return self.tokenFee;
    }
}