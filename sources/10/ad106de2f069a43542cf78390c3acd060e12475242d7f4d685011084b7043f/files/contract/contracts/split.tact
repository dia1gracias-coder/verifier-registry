// ========== EVENTOS ==========
message(0x02) PaymentProcessed {
    from: Address;
    to: Address;
    amount: Int;
    groupId: String;
    timestamp: Int;
}

message(0x03) SettlementCompleted {
    groupId: String;
    totalSettlements: Int;
    timestamp: Int;
}

// ========== MENSAGENS PRINCIPAIS ==========
message(0x04) DirectPayment {
    to: Address;
    amount: Int;
    groupId: String;
}

message(0x05) BatchSettlement {
    recipients: map<Address, Int>;
    groupId: String;
}

// ========== MENSAGENS ADMINISTRATIVAS ==========
message(0x01) Deploy {
    queryId: Int;
}

message(0x06) PauseContract {}

message(0x07) ResumeContract {}

message(0x08) WithdrawFees {
    amount: Int;
}

message(0x09) EmergencyWithdraw {}

struct ContractInfo {
    owner: Address;
    totalVolume: Int;
    totalFees: Int;
    isActive: Bool;
}

// ========== CONTRATO SPLITPAYMENT OTIMIZADO ==========
contract SplitPayment {
    owner: Address;
    totalVolume: Int;
    totalFees: Int;
    isActive: Bool;
    
    init(owner: Address) {
        self.owner = owner;
        self.totalVolume = 0;
        self.totalFees = 0;
        self.isActive = true;
    }
    
    // ========== DEPLOY HANDLER ==========
    receive(msg: Deploy) {
        // Contract deployed successfully
        emit(PaymentProcessed{
            from: sender(),
            to: self.owner,
            amount: 0,
            groupId: "contract-deployed",
            timestamp: now()
        }.toCell());
    }
    
    // ========== PAGAMENTO DIRETO ==========
    receive(msg: DirectPayment) {
        require(self.isActive, "Contract is paused");
        require(msg.amount > 0, "Amount must be positive");
        require(msg.amount <= ton("100"), "Amount too large");
        
        let fee: Int = ton("0.05"); // Taxa fixa de processamento
        let totalRequired: Int = msg.amount + fee;
        
        require(context().value >= totalRequired, "Insufficient funds sent");
        
        // Envia o pagamento
        send(SendParameters{
            to: msg.to,
            value: msg.amount,
            mode: SendPayGasSeparately,
            body: beginCell()
                .storeUint(0x11111111, 32)
                .storeAddress(sender())
                .storeUint(now(), 32)
                .endCell()
        });
        
        // Atualiza estatísticas
        self.totalVolume += msg.amount;
        self.totalFees += fee;
        
        // Emite evento
        emit(PaymentProcessed{
            from: sender(),
            to: msg.to,
            amount: msg.amount,
            groupId: msg.groupId,
            timestamp: now()
        }.toCell());
    }
    
    // ========== LIQUIDAÇÃO EM LOTE ==========
    receive(msg: BatchSettlement) {
        require(sender() == self.owner, "Only backend can trigger settlement");
        require(self.isActive, "Contract is paused");
        
        let totalAmount: Int = 0;
        let settlementCount: Int = 0;
        
        // Processa todos os pagamentos
        foreach(recipient, amount in msg.recipients) {
            if (amount > 0) {
                send(SendParameters{
                    to: recipient,
                    value: amount,
                    mode: SendPayGasSeparately,
                    body: beginCell()
                        .storeUint(0x12345678, 32)
                        .storeUint(now(), 32)
                        .endCell()
                });
                totalAmount += amount;
                settlementCount += 1;
            }
        }
        
        // Atualiza volume total
        self.totalVolume += totalAmount;
        
        // Emite evento de conclusão
        emit(SettlementCompleted{
            groupId: msg.groupId,
            totalSettlements: settlementCount,
            timestamp: now()
        }.toCell());
    }
    
    // ========== FUNÇÕES ADMINISTRATIVAS ==========
    receive(msg: PauseContract) {
        require(sender() == self.owner, "Only owner");
        self.isActive = false;
    }

    receive(msg: ResumeContract) {
        require(sender() == self.owner, "Only owner");
        self.isActive = true;
    }
    
    receive(msg: WithdrawFees) {
        require(sender() == self.owner, "Only owner");
        require(msg.amount > 0, "Amount must be positive");
        require(msg.amount <= self.totalFees, "Insufficient fees available");
        
        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            mode: SendPayGasSeparately,
            body: beginCell()
                .storeUint(0x31, 32)
                .storeUint(now(), 32)
                .endCell()
        });
        
        self.totalFees -= msg.amount;
    }
    
    // ========== EMERGENCY FUNCTIONS ==========
    receive(msg: EmergencyWithdraw) {
        require(sender() == self.owner, "Only owner");
        require(!self.isActive, "Contract must be paused first");
        
        // Saca todos os fundos restantes
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
            body: beginCell()
                .storeUint(0x33, 32)
                .storeUint(now(), 32)
                .endCell()
        });
    }
    
    // ========== QUERIES OTIMIZADAS ==========
    get fun getTotalVolume(): Int {
        return self.totalVolume;
    }
    
    get fun isContractActive(): Bool {
        return self.isActive;
    }
    
    get fun getOwner(): Address {
        return self.owner;
    }
    
    get fun getTotalFees(): Int {
        return self.totalFees;
    }
    
    get fun getContractBalance(): Int {
        return myBalance();
    }
    
    get fun getContractInfo(): ContractInfo {
        return ContractInfo{
            owner: self.owner,
            totalVolume: self.totalVolume,
            totalFees: self.totalFees,
            isActive: self.isActive
        };
    }
    
    // ========== VALIDAÇÃO DE PAGAMENTO ==========
    get fun validatePayment(amount: Int): Bool {
        if (!self.isActive) { return false; }
        if (amount <= 0) { return false; }
        if (amount > ton("100")) { return false; }
        return true;
    }
}