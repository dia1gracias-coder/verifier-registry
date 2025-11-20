import "@stdlib/ownable";
import "./Messages.tact";
import "./Errors.tact";

// ===== Messages =====
message(0x42c20f7a) Transfer { 
    req: PaymentRequest; 
    deadline: Int; 
}
message(0xeeab28d0) SetPlatformCommissionBps { 
    newBps: Int; 
}
message(0xe225cbda) WithdrawAll { 
    to: Address; 
}
message(0xc2b41d43) SetOwner { 
    newOwner: Address; 
}
// ===== Structs =====
struct PaymentRequest {
    buyer: Address;
    seller: Address;
    amount: Int;                 // in nanotons
    buyerPaysCommission: Bool;
    optionalCommissionWallet: Address?; // None if not used
}

struct Preview {
    commission: Int;
    totalPay: Int;
}

struct ConfigResponse {
    owner: Address;
    mainCommissionWallet: Address;
    nftCollection: Address;
    platformCommissionBps: Int;
}

contract PaymentProcessor with Ownable {

    owner: Address;
    platformCommissionBps: Int; // 0..10000
    mainCommissionWallet: Address;

    partnerCollection: Address;     // contract address implementing IDefNFT
    partnerShareBps: map<Address, Int>;

    // Simple per-buyer nonce storage
    nonces: map<Address, Int>;

    init(owner: Address, mainCommissionWallet: Address, partnerCollection: Address) {
        self.owner = owner;
        self.mainCommissionWallet = mainCommissionWallet;
        self.partnerCollection = partnerCollection;
        self.platformCommissionBps = 25; // 0.25%
    }

    // ==== Internal helpers ====
    inline fun onlyCollection() {
        throwIf(ExitCodeNotCollection, sender() != self.partnerCollection);
    }

    // ============ Admin ============
    receive(m: SetOwner) {
        self.requireOwner();
        self.owner = m.newOwner;
    }

    receive(m: SetPlatformCommissionBps) {
        self.requireOwner();
        throwIf(InvalidCommissionBps, !(m.newBps >= 0 && m.newBps <= 10000));
        self.platformCommissionBps = m.newBps;
    }

    receive(w: WithdrawAll) {
        self.requireOwner();
        let to = w.to;
        let bal = myBalance();
        // Minimal balance to keep contract operational (rent + small gas headroom)
        let MIN_KEEP: Int = 10_000_000; // ~0.01 TON
        throwIf(BelowReserve, !(bal > MIN_KEEP));
        // Reserve minimal operational balance, send the rest away
        nativeReserve(MIN_KEEP, 0);
        send(SendParameters{ to: to, value: 0, mode: SendRemainingBalance });
    }

    // ============ Payment entry ============
    receive(t: Transfer) {
        let req = t.req;
        
        // Базовые проверки
        throwIf(InvalidAmountValidation, req.amount <= 0);
        throwIf(InvalidSellerValidation, req.seller == req.buyer);
        throwIf(SignatureExpired, now() > t.deadline);
        throwIf(InvalidSignature, sender() != req.buyer);

        // Nonce check & consume
        let currentNonce = self.nonces.get(req.buyer);
        let nextNonce: Int = (currentNonce != null) ? (currentNonce!! + 1) : 1;
        self.nonces.set(req.buyer, nextNonce);

        let incoming: Int = context().value;
        // Compute commissions
        let commission = (req.amount * self.platformCommissionBps) / 10000;
        let sellerValue = req.buyerPaysCommission ? req.amount : (req.amount - commission);
        let commissionValue = commission > 0 ? commission : 0;

        // Validate that total payment covers amount (+ commission when buyer pays it)
        let totalRequired = req.buyerPaysCommission ? (req.amount + commission) : req.amount;
        throwIf(InvalidTotalAmountValidation, incoming < totalRequired);

        let balBefore: Int = myBalance() - incoming;
        let prev: Int = (balBefore > 0) ? balBefore : 0;
        nativeReserve(prev, 0); // фиксируем ровно prev; дальнейшие расходы — из входящего

        // Seller payout
        send(SendParameters{ 
            to: req.seller, 
            value: sellerValue,
            bounce: true,
            mode: SendPayGasSeparately // чтобы не тратить резерв на форвард-фии продавцу
        });
        // Main commission payout
        let optionalPart: Int = 0;
        // Optional partner commission (пока отключено, но структура готова)
        if (req.optionalCommissionWallet != null) {
            let optionalCommissionWallet = req.optionalCommissionWallet!!;
            let shareOpt = self.partnerShareBps.get(optionalCommissionWallet);
            let shareBps = shareOpt != null ? shareOpt!! : 0;

            if (shareBps > 0 && shareBps <= 10000) {
                optionalPart = (commission * shareBps) / 10000;
                commissionValue -= optionalPart;
            }
        }

        if (commissionValue > 0) {
            send(SendParameters{ 
                to: self.mainCommissionWallet, 
                value: commissionValue,
                bounce: true,
                mode: SendPayGasSeparately
            });
            if (optionalPart > 0) {
                send(SendParameters{ 
                    to: req.optionalCommissionWallet!!, 
                    value: optionalPart,
                    mode: SendPayGasSeparately,
                    bounce: true
                });
           
                send(SendParameters{
                    to: self.partnerCollection,
                    value: ton("0.005"),
                    mode: SendPayGasSeparately,
                    bounce: true,
                    body: IncrementSuccessfulTx{
                        wallet: req.optionalCommissionWallet!!
                    }.toCell()
                });
            }
        }
    }

    receive(msg: RegisterPartnerShare) {
        self.onlyCollection();

        // Если share <= 0 — убираем из локального реестра
        if (msg.shareBps == null || msg.shareBps!! <= 0) {
            self.partnerShareBps.set(msg.wallet, null);
            return;
        }

        self.partnerShareBps.set(msg.wallet, msg.shareBps);
    }

    receive(msg: UnregisterPartnerShare) {
        self.onlyCollection();
        self.partnerShareBps.set(msg.wallet, null);
    }

    // ============ Views ============
      // 3) Добавим get-методы для фронта
    get fun getConfig(): ConfigResponse {
        return ConfigResponse{
            owner: self.owner,
            mainCommissionWallet: self.mainCommissionWallet,
            nftCollection: self.partnerCollection,
            platformCommissionBps: self.platformCommissionBps
        };
    }

    get fun previewPayment(amount: Int, buyerPaysCommission: Bool): Preview {
        let commission = (amount * self.platformCommissionBps) / 10000;
        let totalPay = buyerPaysCommission ? (amount + commission) : amount;
        return Preview{ commission: commission, totalPay: totalPay };
    }

    get fun nonceOf(account: Address): Int {
        let n = self.nonces.get(account);
        return (n != null) ? n!! : 0;
    }
}
