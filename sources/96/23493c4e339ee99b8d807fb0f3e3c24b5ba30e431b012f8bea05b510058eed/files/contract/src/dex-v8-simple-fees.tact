import "@stdlib/ownable";
import "@stdlib/deploy";

// ============================================================================================================
// DEX MESSAGES
// ============================================================================================================

// Buy tokens with TON
message BuyTokens {
    min_taxs_out: Int as coins; // Minimum tokens expected (slippage protection)
    current_taxs_balance: Int as coins; // Current DEX TAXSTR balance (for accurate pricing)
}

// Set DEX's TAXS wallet address (must be called after deployment)
message SetDEXWallet {
    dex_taxs_wallet: Address; // DEX's TAXS wallet address
}

// Request to sell tokens (validation before transfer)
message RequestSell {
    amount: Int as coins; // Amount of TAXSTR to sell
    current_taxs_balance: Int as coins; // Current DEX TAXSTR balance (for accurate pricing)
}

// Response to sell request
message SellResponse {
    approved: Bool; // Whether sell is approved
    max_amount: Int as coins; // Maximum amount that can be sold
    expected_ton: Int as coins; // Expected TON output
    reason: String; // Reason if not approved
}

// Internal message when receiving tokens
message(0x178d4519) TokenTransferInternal {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

// Token transfer message
message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

// ============================================================================================================
// SMART TAXS DEX CONTRACT (V8 - SIMPLE FEES)
// ============================================================================================================

contract SmartTAXSDEX with Deployable, Ownable {
    // State (no internal reserve - use actual wallet balance)
    ton_fees_collected: Int = 0;     // Total TON fees collected
    
    // Contract addresses
    owner: Address;                  // DEX owner (deployer)
    treasury: Address;               // TAXSTR treasury address (same as TAXSTR dev_address)
    taxs_master: Address;            // TAXS token master contract
    dex_taxs_wallet: Address?;       // DEX's own TAXS wallet address
    
    // Pricing (bonding curve)
    base_price: Int;                 // Base price in nanoTON per token
    price_multiplier: Int;           // Price multiplier for bonding curve
    
    // Fee configuration (ONLY on TON transfers)
    ton_fee_percent: Int = 10;       // 10% fee on TON transactions ONLY
    
    // Gas configuration
    gas_reserve: Int = 100000000;    // 0.1 TON gas reserve
    transfer_gas: Int = 250000000;   // 0.25 TON for transfers (increased)
    forward_gas: Int = 30000000;    // 0.03 TON forwarded with transfers (increased)
    
    // Constants
    percentage_base: Int = 100;      // Base for percentage calculations
    decimals_divisor: Int = 1000000000; // 10^9 for token decimals

    init(treasury_address: Address, taxs_master_address: Address, base_price: Int, price_multiplier: Int) {
        self.owner = sender();
        self.treasury = treasury_address; // SAME as TAXSTR treasury
        self.taxs_master = taxs_master_address;
        self.base_price = base_price;
        self.price_multiplier = price_multiplier;
    }

    // ============================================================================================================
    // CORE FUNCTIONS
    // ============================================================================================================
    
    // Calculate current price based on supply
    fun calculate_current_price(current_supply: Int): Int {
        if (current_supply == 0) {
            return self.base_price;
        }
        
        // Simple bonding curve with small price increases
        let large_divisor: Int = self.decimals_divisor * 1000000; // 1e15
        let price_increase: Int = (current_supply * self.price_multiplier) / large_divisor;
        return self.base_price + price_increase;
    }
    
    // Calculate TAXS output for TON input (accounting for transfer tax)
    fun calculate_taxs_output(ton_amount: Int, current_supply: Int, is_treasury_buyer: Bool): Int {
        let current_price: Int = self.calculate_current_price(current_supply);
        let gross_taxs: Int = (ton_amount * self.decimals_divisor) / current_price;
        
        // All transfers from DEX incur 10% tax, but:
        // - Treasury: Gets 90% directly + 10% as tax = 100% total
        // - Regular users: Get 90% directly, 10% goes to treasury
        return gross_taxs; // Same calculation for both, but treasury gets tax back
    }
    
    // Calculate TON output for TAXS input (accounting for transfer tax)
    fun calculate_ton_output(taxs_amount: Int, current_supply: Int, is_treasury_seller: Bool): Int {
        let current_price: Int = self.calculate_current_price(current_supply);
        
        // Account for the fact that if it's NOT treasury, the DEX will receive 90% of TAXS
        let actual_taxs_received: Int = 0;
        if (is_treasury_seller) {
            actual_taxs_received = taxs_amount; // 100% received from treasury
        } else {
            actual_taxs_received = (taxs_amount * 90) / 100; // 90% received from regular user
        }
        
        return (actual_taxs_received * current_price) / self.decimals_divisor;
    }
    
    // Calculate maximum sellable amount based on available TON
    fun calculate_max_sellable(current_taxs_balance: Int): Int {
        let dex_ton_balance: Int = myBalance();
        let available_ton: Int = dex_ton_balance - self.gas_reserve;
        
        if (available_ton <= 0) {
            return 0;
        }
        
        let current_price: Int = self.calculate_current_price(current_taxs_balance);
        return (available_ton * self.decimals_divisor) / current_price;
    }

    // ============================================================================================================
    // MESSAGE HANDLERS
    // ============================================================================================================

    // Set DEX's TAXS wallet address
    receive(msg: SetDEXWallet) {
        require(sender() == self.owner, "Only owner can set wallet");
        self.dex_taxs_wallet = msg.dex_taxs_wallet;
    }

    // Buy TAXS tokens with TON
    receive(msg: BuyTokens) {
        require(self.dex_taxs_wallet != null, "DEX wallet not set");
        
        let ton_amount: Int = context().value - self.gas_reserve;
        require(ton_amount > 0, "Insufficient TON sent");
        
        let current_balance: Int = msg.current_taxs_balance;
        require(current_balance > 0, "No TAXSTR liquidity");
        
        // Check if buyer is treasury
        let is_treasury_buyer: Bool = (sender() == self.treasury);
        
        let taxs_output: Int = self.calculate_taxs_output(ton_amount, current_balance, is_treasury_buyer);
        require(taxs_output >= msg.min_taxs_out, "Slippage exceeded");
        require(taxs_output > 0, "Amount too small");
        require(taxs_output <= current_balance, "Insufficient TAXSTR reserves");
        
        // Calculate TON fee (ONLY fee the DEX takes)
        let ton_fee: Int = (ton_amount * self.ton_fee_percent) / self.percentage_base;
        let net_ton_after_fee: Int = ton_amount - ton_fee;
        
        // Update fee collection
        self.ton_fees_collected = self.ton_fees_collected + ton_fee;
        
        // Send TON fee to treasury
        if (ton_fee > 0) {
            send(SendParameters{
                to: self.treasury,
                value: ton_fee,
                mode: SendPayGasSeparately,
                body: "DEX TON fee".asComment()
            });
        }
        
        // Send TAXS to buyer (the amount already accounts for transfer tax)
        self.send_taxs_to_buyer(sender(), taxs_output, is_treasury_buyer);
    }
    
    // Send TAXS tokens to buyer
    fun send_taxs_to_buyer(buyer: Address, amount: Int, is_treasury_buyer: Bool) {
        require(self.dex_taxs_wallet != null, "DEX wallet not set");
        
        // Treasury buyers get extra forward gas to ensure 100% delivery
        let forward_ton_amount: Int = self.forward_gas;
        if (is_treasury_buyer) {
            forward_ton_amount = self.forward_gas + 20000000; // Extra 0.02 TON
        }
        
        send(SendParameters{
            to: self.dex_taxs_wallet!!,
            value: self.transfer_gas,
            mode: SendPayGasSeparately,
            body: TokenTransfer{
                query_id: now(),
                amount: amount,
                destination: buyer,
                response_destination: null,
                custom_payload: null,
                forward_ton_amount: forward_ton_amount,
                forward_payload: "DEX buy".asSlice()
            }.toCell()
        });
    }

    // Pre-validate sell request
    receive(msg: RequestSell) {
        let current_balance: Int = msg.current_taxs_balance;
        let max_sellable: Int = self.calculate_max_sellable(current_balance);
        let can_sell: Bool = msg.amount <= max_sellable && msg.amount > 0;
        
        if (can_sell) {
            let is_treasury_seller: Bool = (sender() == self.treasury);
            let expected_ton: Int = self.calculate_ton_output(msg.amount, current_balance, is_treasury_seller);
            let ton_fee: Int = (expected_ton * self.ton_fee_percent) / self.percentage_base;
            let net_ton: Int = expected_ton - ton_fee;
            
            send(SendParameters{
                to: sender(),
                value: 20000000, // 0.02 TON for response
                mode: SendPayGasSeparately,
                body: SellResponse{
                    approved: true,
                    max_amount: max_sellable,
                    expected_ton: net_ton,
                    reason: "Approved"
                }.toCell()
            });
        } else {
            let reason: String = max_sellable == 0 ? "No TON liquidity" : "Amount too large";
            send(SendParameters{
                to: sender(),
                value: 20000000, // 0.02 TON for response
                mode: SendPayGasSeparately,
                body: SellResponse{
                    approved: false,
                    max_amount: max_sellable,
                    expected_ton: 0,
                    reason: reason
                }.toCell()
            });
        }
    }

    // Handle incoming TAXS token transfers (sells)
    receive(msg: TokenTransferInternal) {
        let dex_ton_balance: Int = myBalance();
        let available_ton: Int = dex_ton_balance - self.gas_reserve;
        
        // Check if seller is treasury
        let is_treasury_seller: Bool = (msg.from == self.treasury);
        
        // Calculate TON output (accounting for transfer tax)
        let estimated_balance: Int = msg.amount * 100; // Simple estimate
        let gross_ton: Int = self.calculate_ton_output(msg.amount, estimated_balance, is_treasury_seller);
        let ton_fee: Int = (gross_ton * self.ton_fee_percent) / self.percentage_base;
        let net_ton: Int = gross_ton - ton_fee;
        
        // Validate sell conditions
        if (net_ton <= 0 || net_ton > available_ton || msg.amount == 0) {
            self.return_tokens_to_seller(msg.from, msg.amount, "Sell failed");
            return;
        }
        
        // Execute sell
        self.ton_fees_collected = self.ton_fees_collected + ton_fee;
        
        // Send TON fee to treasury
        if (ton_fee > 0) {
            send(SendParameters{
                to: self.treasury,
                value: ton_fee,
                mode: SendPayGasSeparately,
                body: "DEX sell fee".asComment()
            });
        }
        
        // Send net TON to seller
        send(SendParameters{
            to: msg.from,
            value: net_ton,
            mode: SendPayGasSeparately,
            body: "TAXSTR sold".asComment()
        });
    }
    
    // Return tokens to seller on failed sell
    fun return_tokens_to_seller(seller: Address, amount: Int, reason: String) {
        send(SendParameters{
            to: self.dex_taxs_wallet!!,
            value: self.transfer_gas,
            mode: SendPayGasSeparately,
            body: TokenTransfer{
                query_id: now(),
                amount: amount,
                destination: seller,
                response_destination: null,
                custom_payload: null,
                forward_ton_amount: self.forward_gas,
                forward_payload: reason.asSlice()
            }.toCell()
        });
    }

    // ============================================================================================================
    // GETTER FUNCTIONS
    // ============================================================================================================
    
    get fun get_ton_fees_collected(): Int {
        return self.ton_fees_collected;
    }
    
    get fun get_price(): Int {
        return self.calculate_current_price(100000000000000000);
    }
    
    get fun get_price_for_balance(current_balance: Int): Int {
        return self.calculate_current_price(current_balance);
    }
    
    get fun get_dex_taxs_wallet(): Address? {
        return self.dex_taxs_wallet;
    }
    
    get fun get_treasury(): Address {
        return self.treasury;
    }
    
    get fun get_taxs_master(): Address {
        return self.taxs_master;
    }
}
