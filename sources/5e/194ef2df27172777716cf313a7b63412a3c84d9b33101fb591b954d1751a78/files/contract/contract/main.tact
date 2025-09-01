import "@stdlib/deploy";


message(0x7362d09c) JettonTransferNotification {
    // Unique identifier used to trace transactions across multiple contracts
    // Defaults to 0, which means we don't mark messages to trace their chains
    // Amount of Jettons transferred
    amount: Int as coins;
    // Address of the sender of the Jettons
    sender: Address;
    // Optional custom payload
    forwardPayload: Slice as remaining;
}
message(0xf8a7ea5) JettonTransfer {
    amount: Int as coins;   
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message AdminActionProposed {
    action_id: Int;
    proposer: Address;
    target_admin: Address;
    is_adding: Bool;
    action_type: String;
}

message AdminActionEvent {
    action_id: Int;
    proposer: Address;
    current_signatures: Int;
}

message AdminActionExecuted {
    action_id: Int;
    target_admin: Address; 
    is_adding: Bool; 
    action_type: String;
}

message  AddressWhitelisted{
    address: Address; 
}
message  AddressBlacklisted{
    address: Address; 
}

// Message for creating a Ucpi (self-registration)
message(0x01) CreateUcpi {
    ucpi_id: Int as uint256;
}

// Message for getting wallet address by Ucpi ID
message(0x02) GetAddress {
    ucpi_id: Int as uint256;
}

// Message for paying a Ucpi
message(0x03) PayUcpi {
    ucpi_id: Int as uint256;
}

// Message for admin to withdraw fees
message(0x04) WithdrawFees {
    amount: Int as coins;
}

// Response messages
message(0x11) UcpiCreated {
    ucpi_id: Int as uint256;
    wallet_address: Address;
}

message(0x12) AddressResponse {
    ucpi_id: Int as uint256;
    wallet_address: Address;
}

message(0x13) PaymentSent {
    ucpi_id: Int as uint256;
    wallet_address: Address;
    amount: Int as coins;
}

message(0x14) FeesWithdrawn {
    amount: Int as coins;
    remaining_balance: Int as coins;
}

message(0x15) Error {
    error_message: String;
}

struct AdminAction {
    target_admin: Address;
    is_adding: Bool;
    signatures: Int;
    signed_by: map<Address, Bool>;
    action_type: String;
    timestamp: Int;
}

contract PaymentRouter with Deployable {
    ucpi_to_wallet: map<Int as uint256, Address>; 
    MIN_SIGNATURES: Int = 2;
    admin_count: Int;
    wallet_to_ucpi: map<Address, Int as uint256>; 
    pending_admin_actions: map<Int, AdminAction>;
    wallet_blocklist: map<Address, Bool>;
    admin_list: map<Address, Bool>;
    next_action_id: Int;
    
    init(owner1: Address, owner2: Address, owner3: Address) {
        self.admin_list.set(owner1, true);
        self.admin_list.set(owner2, true);
        self.admin_list.set(owner3, true);
        self.next_action_id = 0;
        self.admin_count = 3;
    }
    
    get fun get_wallet_status(wallet_opt: Address?): Bool? {
        if (wallet_opt != null) {
            return self.wallet_blocklist.get(wallet_opt!!);
        } else {
            return null;
        }
    }
    
    get fun is_active_admin(addr: Address): Bool {
        let status = self.admin_list.get(addr);
        return status != null ? status!! : false;
    }
    
    receive(msg: CreateUcpi) {
        let ctx: Context = context();
        require(msg.ucpi_id > 0, "Ucpi ID must be greater than 0");
        // Check if Ucpi ID already exists
        let existing_wallet: Address? = self.ucpi_to_wallet.get(msg.ucpi_id);
        if (existing_wallet != null) {
            // Send error response
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: Error{
                    error_message: "Ucpi ID already exists"
                }.toCell()
            });
            return;
        }

        // Check if wallet is already mapped to another Ucpi
        let existing_ucpi: Int? = self.wallet_to_ucpi.get(ctx.sender);
        if (existing_ucpi != null) {
            // Send error response
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: Error{
                    error_message: "Wallet already mapped to another ucpi"
                }.toCell()
            });
            return;
        }
        
        // Store mappings (ucpi registers their own wallet)
        self.ucpi_to_wallet.set(msg.ucpi_id, ctx.sender);
        self.wallet_to_ucpi.set(ctx.sender, msg.ucpi_id);
        
        // Send confirmation
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            body: UcpiCreated{
                ucpi_id: msg.ucpi_id,
                wallet_address: ctx.sender
            }.toCell()
        });
    }

    // Function to pay a ucpi
    receive(msg: PayUcpi) {
        let ctx: Context = context();
        require(ctx.value >= ton("0.1"), "Minimum payment is 0.1 TON");
        require(msg.ucpi_id > 0, "Ucpi ID must be greater than 0");
        
        // Check if ucpi ID exists
        let ucpi_wallet: Address? = self.ucpi_to_wallet.get(msg.ucpi_id);
        if (ucpi_wallet == null) {
            // Send error response
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: Error{
                    error_message: "Ucpi ID not found"
                }.toCell()
            });
            return;
        }
        
        let blocklist_status_receiver = self.get_wallet_status(ucpi_wallet);
        if (blocklist_status_receiver == true) {
            // Send error response
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: Error{
                    error_message: "Receiver Ucpi Black Listed"
                }.toCell()
            });
            return;
        }
        
        let blocklist_status_sender = self.get_wallet_status(ctx.sender);
        if (blocklist_status_sender == true) {
            // Send error response
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: Error{
                    error_message: "Sender Ucpi Black Listed"
                }.toCell()
            });
            return;
        }

    
        
        send(SendParameters{
            to: ucpi_wallet!!,
            value: 0,
            mode: SendRemainingValue,
            body: "Payment from campus router".asComment()
        });
        
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            body: PaymentSent{
                ucpi_id: msg.ucpi_id,
                wallet_address: ucpi_wallet!!,
                amount: SendRemainingValue
            }.toCell()
        });
    }
    
    // Getter functions    
    get fun getUcpiWallet(ucpi_id: Int): Address? {
        return self.ucpi_to_wallet.get(ucpi_id);
    }
    
    get fun getUcpiByWallet(wallet_address: Address): Int? {
        return self.wallet_to_ucpi.get(wallet_address);
    }
    
    get fun getContractBalance(): Int {
        return myBalance();
    }
    
    get fun is_admin(addr: Address): Bool {
        return self.admin_list.exists(addr) && self.admin_list.get(addr)!!;
    }

    // Handle incoming jetton transfer notifications and route tokens to ucpi's
    receive(msg: JettonTransferNotification) {
        let ctx: Context = context();
        
        // Parse the forward payload to get ucpi ID
        let forward_payload: Slice = msg.forwardPayload;
        
        // Try to read ucpi ID from forward payload (64 bits)
        let ucpi_id: Int? = forward_payload.loadUint(64);
        
        if (ucpi_id == null) {
            // If no ucpi ID in payload, send error response
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: "Ucpi id not found".asComment()
            });
            return;
        }
        
        // Check if ucpi ID exists
        let ucpi_wallet: Address? = self.ucpi_to_wallet.get(ucpi_id!!);
        if (ucpi_wallet == null) {
            // Send error response
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: "ucpi_wallet id not found".asComment()
            });
            return;
        }
        
        let blocklist_status_receiver = self.get_wallet_status(ucpi_wallet);
        if (blocklist_status_receiver == true) {
            // Send error response
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: Error{
                    error_message: "Receiver Ucpi Black Listed"
                }.toCell()
            });
            return;
        }
        
        let blocklist_status_sender = self.get_wallet_status(ctx.sender);
        if (blocklist_status_sender == true) {
            // Send error response
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: Error{
                    error_message: "Sender Ucpi Black Listed"
                }.toCell()
            });
            return;
        }
        
        // Forward the jetton to the ucpi's wallet
        let forward_message: Cell = JettonTransfer{
            amount: msg.amount,
            destination: ucpi_wallet!!,
            responseDestination: ctx.sender,
            customPayload: null,
            forwardTonAmount: ton("0.0001"),
            forwardPayload: "Token payment from campus router".asComment().beginParse()
        }.toCell();
        
        send(SendParameters{
            to: ctx.sender,
            value: ton("0.1"),
            mode: SendPayGasSeparately,
            body: forward_message
        });
        
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            body: "unused fees refund".asComment()
        });
    }
    
    get fun zero_address(): Address {
        return newAddress(0, 0);
    }
    
    fun propose_admin_action(target_admin: Address, is_adding: Bool) {
        let ctx: Context = context();
        require(self.is_admin(ctx.sender), "Only admin can propose");
        require(target_admin != self.zero_address(), "Invalid admin address");
        let action_id = self.next_action_id;
        self.next_action_id = self.next_action_id + 1;
        require(!self.pending_admin_actions.exists(action_id), "Action already proposed");
        let wallet_signed_by: map<Address, Bool> = emptyMap();
        wallet_signed_by.set(ctx.sender, true);
        let action = AdminAction{
            target_admin: target_admin,
            is_adding: is_adding,
            signatures: 1,
            signed_by: wallet_signed_by,
            action_type: "admin",
            timestamp: now()
        };
        self.pending_admin_actions.set(action_id, action);
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: AdminActionProposed{
                action_id: action_id,
                proposer: ctx.sender,
                target_admin: target_admin,
                is_adding: true,
                action_type: "admin"
            }.toCell()
        });
    }

    // Sign admin action
    fun sign_admin_action(action_id: Int) {
        let ctx: Context = context();
        require(self.is_admin(ctx.sender), "Only admin can sign");
        let action = self.pending_admin_actions.get(action_id);
        require(action != null, "Action does not exist");
        let action_val = action!!;
        require(!action_val.signed_by.exists(ctx.sender), "Already signed");
        action_val.signatures = action_val.signatures + 1;
        action_val.signed_by.set(ctx.sender, true);
        self.pending_admin_actions.set(action_id, action_val);
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendIgnoreErrors,
            bounce: false,
            body: AdminActionEvent{
                action_id: action_id,
                proposer: ctx.sender,
                current_signatures: action_val.signatures

            }.toCell()
        });
        if (action_val.signatures >= self.MIN_SIGNATURES) {
            self.execute_admin_action(action_id);
        }
    }

    // Execute admin action
    fun execute_admin_action(action_id: Int) {
        let action_opt = self.pending_admin_actions.get(action_id);
        if (action_opt == null) {
            return;
        }
        let action = action_opt!!;
        if (action.action_type == "admin") {
            if (action.is_adding) {
                require(!self.wallet_blocklist.exists(action.target_admin) || !self.wallet_blocklist.get(action.target_admin)!!, "Blacklisted user cannot be admin");
                // Add or activate admin
                if (self.admin_list.exists(action.target_admin)) {
                    self.admin_list.set(action.target_admin, true);
                } else {
                    self.admin_list.set(action.target_admin, true);
                    self.admin_count = self.admin_count + 1;
                }
            } else {
                // Deactivate admin
                if (self.admin_list.exists(action.target_admin)) {
                    self.admin_list.set(action.target_admin, false);
                    self.admin_count = self.admin_count - 1;
                }
            }
        } else if (action.action_type == "blacklist") {
            self.wallet_blocklist.set(action.target_admin, true);
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: AddressBlacklisted{
                    address: action.target_admin
                }.toCell()
            });
        } else if (action.action_type == "whitelist") {
            self.wallet_blocklist.set(action.target_admin, false);
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: AddressWhitelisted{
                    address: action.target_admin
                }.toCell()
            });
        }
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: AdminActionExecuted{
                action_id: action_id,
                target_admin:  action.target_admin, 
                is_adding: action.is_adding, 
                action_type: action.action_type
            }.toCell()
        });
        self.pending_admin_actions.set(action_id, null);
    }
}