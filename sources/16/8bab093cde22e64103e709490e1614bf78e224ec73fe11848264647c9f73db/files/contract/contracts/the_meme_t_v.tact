import "@stdlib/deploy";
import "@stdlib/ownable";

message Mint {
    amount: Int as coins;
    receiver: Address;
}

message MintPublic {
    amount: Int;
}

// Message for closing minting
message MintCloseOrOpen {
    status: Bool;
}

// Message for minting liquidity tokens
message MintLiquidityAndTreasuryTokens {
    receiver: Address;
}

// Message for minting community activation and cultivation tokens
message MintActivationAndCultivationTokens {
    receiver: Address;
}

// Message for minting ecosystem development tokens
message MintEcosystemDevelopmentTokens {
    receiver: Address;
}

// Message for minting Team tokens
message MintTeamTokens {
    receiver: Address;
}

// Message for minting Company tokens
message MintCompanyTokens {
    receiver: Address;
}

// Message for minting Strategic partnerships tokens
message MintPartnershipTokens{
    receiver: Address;
}

// Message for minting Smart future reserves tokens
message MintSmartFutureReserveTokens{
    receiver: Address;
}

// Message for signature-based minting
message VerifySignatureMint {
    userAddress: Address;
    reward: Int;
    signature: Slice;
}

// Message for adding addresses to the whitelist
message AddToWhitelist {
    data: Slice; // Encoded data containing a list of addresses and their corresponding points
}

// Message for whitelist-based minting
message WhitelistedMint {

}


contract TheMemeTV with Jetton, Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    const minTonForStorage: Int = ton("0.01");
    // variables to show the no of tokens
    max_supply: Int as coins;
    liquidity_tokens: Int as coins;
    community_activation_cultivation_tokens: Int as coins;
    ecosystem_development_tokens: Int as coins;
    team_tokens: Int as coins;
    company_tokens: Int as coins;
    partnership_tokens: Int as coins;
    smart_future_reserve_tokens: Int as coins;

    //variable to keep track of total minted company tokens
    company_minted_tokens: Int as coins = 0;
    //variable to identify the tokens are minted or not
    liquidity_tokens_minted: Bool;
    community_activation_cultivation_tokens_minted: Bool;
    ecosystem_development_tokens_minted: Bool;
    team_first_phase_minted: Bool;
    team_tokens_minted: Bool;
    company_first_phase_minted: Bool;
    //variable to keep track of company token minted phase
    company_token_completed_phase: Int = 0;
    company_tokens_minted: Bool;
    partnership_tokens_minted: Bool;
    smart_future_reserve_tokens_minted: Bool;

    tge_timestamp: Int;
    one_year_time_in_seconds: Int = 31536000;
    three_months_in_seconds: Int = 7776000;



    const adminPublicAddress: Address = address("0QCfwXGx7kkNOCoE8QVOE5eYBMyNpcxvbMgEJ2UrDUM1TaOn");
    pub: Int;

    // Since your public key is 256 bits long, let's split it into two 128-bit integers and then reconstruct it during verification.
    // Split into smaller parts
    // const adminPublicKeyPart1: Int = 0xd1001fed507cad4c;
    // const adminPublicKeyPart2: Int = 0x0212cc114f97e69a;
    // const adminPublicKeyPart3: Int = 0x63105a4903732673;
    // const adminPublicKeyPart4: Int = 0x480a6c650f84b122;
    // const adminPublicKeyPart5: Int = 0x61189898;



    init(owner: Address, content: Cell, max_supply: Int, liquidity_tokens: Int, community_activation_cultivation_tokens: Int, ecosystem_development_tokens: Int, team_tokens: Int, company_tokens: Int, partnership_tokens: Int, smart_future_reserve_tokens: Int){
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
        self.liquidity_tokens = liquidity_tokens;
        self.community_activation_cultivation_tokens = community_activation_cultivation_tokens;
        self.ecosystem_development_tokens = ecosystem_development_tokens;
        self.team_tokens = team_tokens;
        self.company_tokens = company_tokens;
        self.partnership_tokens = partnership_tokens;
        self.smart_future_reserve_tokens = smart_future_reserve_tokens;
        self.tge_timestamp = now(); // returns unix time, the number of seconds since the epoch

        self.liquidity_tokens_minted = false;
        self.community_activation_cultivation_tokens_minted = false;
        self.ecosystem_development_tokens_minted = false;
        self.team_first_phase_minted = false;
        self.team_tokens_minted = false;
        self.company_first_phase_minted = false;
        self.company_tokens_minted = false;
        self.partnership_tokens_minted = false;
        self.smart_future_reserve_tokens_minted = false;
        self.pub = 49228862917009006389872998020341515631121757677823345354220869277083801132169;
    }


    receive(msg: Mint) {
        let ctx: Context = context();
        // require(ctx.sender == self.owner, "Only Owner can call this function");
        self.requireOwner();
        require(self.mintable, "Minting is paused, can't Mint Anymore");
        self.mint(msg.receiver, msg.amount, self.owner); //(to, amount, response_destination)
    }

    //function to get the liquidity tokens minted status
    get fun get_liquidity_tokens_minted(): Bool {
        return self.liquidity_tokens_minted;
    }
    
    //function to mint liquidity tokens
    receive(msg: MintLiquidityAndTreasuryTokens){
        let ctx: Context = context();
        // require(ctx.sender == self.owner, "Only Owner can call this function");
        self.requireOwner();
        require(!self.liquidity_tokens_minted,"liquidity tokens already minted");
        require(self.mintable, "Minting is paused, can't Mint Anymore");
        self.mint(msg.receiver, self.liquidity_tokens, self.owner); // (to, amount, response_destination)
        self.liquidity_tokens_minted = true;
    }

    //function to get ecosystem development tokens minted status
    get fun get_ecosystem_development_tokens_minted(): Bool {
        return self.ecosystem_development_tokens_minted;
    }

    //function to mint Ecosystem developmenttokens
    receive(msg: MintEcosystemDevelopmentTokens){
        let ctx: Context = context();
        // require(ctx.sender == self.owner, "Only Owner can call this function");
        self.requireOwner();
        require(!self.ecosystem_development_tokens_minted,"ecosystem development tokens already minted");
        require(self.mintable, "Minting is paused, Minting is paused, can't Mint Anymore");
        self.mint(msg.receiver, self.ecosystem_development_tokens, self.owner); // (to, amount, response_destination)
        self.ecosystem_development_tokens_minted=true;
    }

    //function to get the current unix timestamp
    get fun unixTime(): Int {
        return now();
    }

    //function to get team tokens minted status
    get fun get_team_tokens_minted(): Bool {
        return self.team_tokens_minted;
    }

    //function to mint team tokens
    receive(msg: MintTeamTokens){
        let ctx: Context = context();
        self.requireOwner();
        require(!self.team_tokens_minted,"Team tokens already minted");
        require(self.mintable, "Minting is paused, Minting is paused, can't Mint Anymore");
        if (!self.team_first_phase_minted) {
            // First 5B tokens minting
            self.mint(msg.receiver, self.team_tokens/2, self.owner);
            self.team_first_phase_minted = true;
        } else {
            // Require 1 year (31536000 seconds) to pass for the second phase
            require(self.unixTime() >= self.tge_timestamp + self.one_year_time_in_seconds, "Second phase of team minting not available yet");
            // Second 5B tokens minting
            self.mint(msg.receiver, self.team_tokens/2, self.owner);
            self.team_tokens_minted = true; // Mark as fully minted
        }
    }

    //function to get team first phase minted status
    get fun get_team_first_phase_minted(): Bool {
        return self.team_first_phase_minted;
    }

    //function to get company tokens minted status
    get fun get_company_tokens_minted(): Bool {
        return self.company_tokens_minted;
    }

    //function to mint company tokens
    receive(msg: MintCompanyTokens) {
        let ctx: Context = context();
        self.requireOwner();

        require(!self.company_tokens_minted, "Company tokens already fully minted");
        require(self.mintable, "Minting is paused, can't mint anymore");
        require(self.company_minted_tokens<=self.company_tokens, "Company tokens already fully minted");

        if (!self.company_first_phase_minted) {
            // First 1B tokens at TGE
            self.mint(msg.receiver, self.company_tokens/5, self.owner);
            self.company_first_phase_minted = true;
            self.company_minted_tokens = self.company_tokens/5;
        } else {
            // Ensure time has passed for subsequent mints
            let elapsed_time = self.unixTime() - self.tge_timestamp;
            let unlock_period = self.three_months_in_seconds; // 3 months in seconds
            let max_unlocks = elapsed_time / unlock_period >4 ? 4 : elapsed_time / unlock_period; // Number of unlockable phases
            require(self.company_token_completed_phase>=max_unlocks,"Company Token already minted for this Quater");
            if(self.company_token_completed_phase<max_unlocks){
                self.company_token_completed_phase =max_unlocks;
            }
            let unlockable_amount = max_unlocks * (self.company_tokens/5);

            // Mint the requested amount
            self.mint(msg.receiver, unlockable_amount, self.owner);
            self.company_minted_tokens += unlockable_amount;

            // Check if full company tokens has been minted
            if (self.company_minted_tokens >= self.company_tokens) {
                self.company_tokens_minted = true;
            }
        }
    }

    //function to get company first phase minted status
    get fun get_company_first_phase_minted(): Bool {
        return self.company_first_phase_minted;
    }

    //function to get company token completed phase
    get fun get_company_token_completed_phase(): Int {
        return self.company_token_completed_phase;
    }

    //function to get company minted tokens amount
    get fun get_company_minted_tokens(): Int {
        return self.company_minted_tokens;
    }

    //function to mint company tokens
    receive(msg: MintPartnershipTokens){
        let ctx: Context = context();
        // require(ctx.sender == self.owner, "Only Owner can call this function");
        self.requireOwner();
        require(!self.partnership_tokens_minted,"Partnership tokens already minted");
        require(self.mintable, "Minting is paused, Minting is paused, can't Mint Anymore");
        self.mint(msg.receiver, self.partnership_tokens, self.owner); // (to, amount, response_destination)
        self.partnership_tokens_minted= true;
    }

    //function to get partnership tokens minted status
    get fun get_partnership_tokens_minted(): Bool {
        return self.partnership_tokens_minted;
    }

    //function to mint smart future reserve tokens
    receive(msg: MintSmartFutureReserveTokens){
        let ctx: Context = context();
        self.requireOwner();
        require(!self.smart_future_reserve_tokens_minted, "Smart future reserve tokens already minted");
        require(self.mintable, "Minting is paused, can't Mint Anymore");
        require(self.unixTime() >= self.tge_timestamp + self.one_year_time_in_seconds, "Smart future reserve tokens can only be minted after 1 year from TGE");
        self.mint(msg.receiver, self.smart_future_reserve_tokens, self.owner);
        self.smart_future_reserve_tokens_minted = true;
    }

    //function to get smart future reserve tokens minted status
    get fun get_smart_future_reserve_tokens_minted(): Bool {
        return self.smart_future_reserve_tokens_minted;
    }

    receive(msg: MintPublic) { // Public Minting
        let ctx: Context = context();
        require(self.mintable, "Minting is paused, can't Mint Anymore");
        self.mint(ctx.sender, msg.amount, self.owner);
    }

    receive(msg: MintCloseOrOpen) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        self.mintable = msg.status;
    }


    // New function to verify the signature
    fun verifySignature(userAddress: Address, reward: Int, signature: Slice): Bool {
        // Recreate the message that was signed off-chain
        let message: Cell = beginCell()
            .storeAddress(userAddress)
            .storeInt(reward, 256)
            .endCell();
            
        // Combine the public key parts into a single value
        // let publicKey: Int = beginCell()
        //     .storeUint(self.adminPublicKeyPart1, 64)
        //     .storeUint(self.adminPublicKeyPart2, 64)
        //     .storeUint(self.adminPublicKeyPart3, 64)
        //     .storeUint(self.adminPublicKeyPart4, 64)
        //     .storeUint(self.adminPublicKeyPart5, 32)
        //     .endCell()
        //     .beginParse()
        //     .loadUint(256);
            
        // Verify the signature directly with the message cell
        return checkSignature(message.hash(), signature, self.pub);
    }
    
    // New handler for signature-based minting
    receive(msg: VerifySignatureMint) {
        require(self.mintable, "Can't Mint Anymore");
        // Verify the signature before minting
        require(self.verifySignature(msg.userAddress, msg.reward, msg.signature), "Invalid signature");
        // Mint tokens for the verified user
        self.mint(msg.userAddress, msg.reward, self.owner);
    }

    // handler for receiving Ton without any messages
    receive() {}

    receive("withdraw safe") {
        require(sender() == self.owner, "Only Owner is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.minTonForStorage,
            mode: SendIgnoreErrors + SendRemainingValue,
        });
    }
    //function to get ton balance
    get fun balance():String{
        return myBalance().toCoinsString();
    }
}
struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

// ============================================================================================================ //
@interface("org.ton.jetton.master")
trait Jetton with Ownable {

    totalSupply: Int; // Already set initially 
    mintable: Bool;
    owner: Address;
    content: Cell;

    max_supply: Int; // This is not in the TEP-74 interface

    receive(msg: TokenUpdateContent) {
        self.requireOwner();                // Allow changing content only by owner
        self.content = msg.content;         // Update content
    }

    receive(msg: TokenBurnNotification) {
        self.requireWallet(msg.owner);                     // Check wallet
        self.totalSupply = self.totalSupply - msg.amount; // Update supply

        if (msg.response_destination != null) { // Cashback
            send(SendParameters{
                to: msg.response_destination!!, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
    fun mint(to: Address, amount: Int, response_destination: Address) {
        require(self.totalSupply + amount <= self.max_supply, "The total supply will be overlapping.");
        self.totalSupply = self.totalSupply + amount; // Update total supply

        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
            to: contractAddress(winit), 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                queryId: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(myAddress(), address);
    }

    // ====== Get Methods ====== //
    get fun get_jetton_data(): JettonData {
        let code: Cell = self.getJettonWalletInit(myAddress()).code;
        return JettonData{ 
            totalSupply: self.totalSupply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            walletCode: code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }
}
// ============================================================ //
@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    balance: Int;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    receive(msg: TokenTransfer) { // 0xf8a7ea5
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");

        // Gas checks
        let fwdFee: Int = ctx.readForwardFee() + ctx.readForwardFee();  
        let final: Int =  2 * self.gasConsumption + self.minTonsForStorage + fwdFee;
        require(ctx.value > min(final, ton("0.01")), "Invalid value!!"); 

        // Update balance
        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Invalid balance");

        let init: StateInit = initOf JettonDefaultWallet(self.master, msg.destination);  
        let walletAddress: Address = contractAddress(init);
        send(SendParameters{
                to: walletAddress, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: false,
                body: TokenTransferInternal{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell(),
                code: init.code,
                data: init.data
            });
    }

    receive(msg: TokenTransferInternal) { // 0x178d4519
        let ctx: Context = context();

        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }

        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance"); 
        
        // Get value for gas
        let msgValue: Int = self.msgValue(ctx.value);  
        let fwdFee: Int = ctx.readForwardFee();
        msgValue = msgValue - msg.forward_ton_amount - fwdFee;
        
         // 0x7362d09c - notify the new owner of JettonToken that the transfer is complete
        if (msg.forward_ton_amount > 0) { 
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: TokenNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        // 0xd53276db -- Cashback to the original Sender
        // if (msg.response_destination != null) { 
        //     send(SendParameters {
        //         to: msg.response_destination, 
        //         value: msgValue,  
        //         bounce: false,
        //         body: TokenExcesses { 
        //             queryId: msg.queryId
        //         }.toCell(),
        //         mode: SendIgnoreErrors
        //     });
        // }
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");  // Check sender

        self.balance = self.balance - msg.amount; // Update balance
        require(self.balance >= 0, "Invalid balance");

        let fwdFee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > fwdFee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value - Burn");

        // Burn tokens
        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
    }

    get fun msgValue(value: Int): Int {
        let msgValue1: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue1;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue1 = msgValue1 - (storageFee + self.gasConsumption);
        return msgValue1;
    }

    bounced(src: bounced<TokenTransferInternal>) {
        self.balance = self.balance + src.amount;
    }

    bounced(src: bounced<TokenBurnNotification>) {
        self.balance = self.balance + src.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: (initOf JettonDefaultWallet(self.master, self.owner)).code
        };
    }
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton 
}

message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address;
}

message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message TokenUpdateContent {
    content: Cell;
}


