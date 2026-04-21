// TCA Token — TON Capital Arena
// Совмещает TEP-74 Jetton + прозрачный леджер игровой экономики.
//
// Каждые 12 часов бэкенд делает 2 вызова:
//
//   1. BatchMint(portfolioAmount, profitAmount)
//      - Минтит portfolioAmount + profitAmount на adminWallet (все токены там)
//      - Минтит 5% от суммы на marketingWallet
//      - Обновляет счётчики: portfolioLocked, profitCirculating
//
//   2. BatchBurn(amount)
//      - Сжигает amount с adminWallet (портфельные взносы: уровни, фонд, арена)
//      - Обновляет: portfolioLocked -= amount, totalBurned += amount
//
// Вывод пользователем:
//      Бэкенд переводит токены с adminWallet на кошелёк пользователя.
//      Потом вызывает RecordWithdrawal(amount) чтобы обновить леджер.
//
// Роли:
//   owner   — холодный кошелёк. Меняет minter/marketing/adminWallet.
//   minter  — горячий кошелёк бэкенда. Вызывает BatchMint, BatchBurn, RecordWithdrawal.
//   adminWallet — хранит все токены (портфельные + профитные).

import "@stdlib/deploy";

// ── Сообщения ──────────────────────────────────────────────────────────────

message BatchMint {
    portfolioAmount: Int as coins;   // сколько сминтить в портфели (заблокировано)
    profitAmount:    Int as coins;   // сколько сминтить в профит (свободные)
}

message BatchBurn {
    amount: Int as coins;            // сжечь с портфельного пула (взносы уровней, фонд, арена)
}

message RecordWithdrawal {
    amount: Int as coins;            // пользователь вывел столько из профита
}

// TEP-74 стандартные сообщения
message TokenTransfer {
    queryId:             Int as uint64;
    amount:              Int as coins;
    destination:         Address;
    responseDestination: Address?;
    customPayload:       Cell?;
    forwardTonAmount:    Int as coins;
    forwardPayload:      Slice as remaining;
}

message ProvideWalletAddress {
    queryId:        Int as uint64;
    ownerAddress:   Address;
    includeAddress: Bool;
}

message TakeWalletAddress {
    queryId:       Int as uint64;
    walletAddress: Address;
    ownerAddress:  Slice as remaining;
}

message JettonExcesses { queryId: Int as uint64; }

message InternalTransfer {
    queryId:          Int as uint64;
    amount:           Int as coins;
    from:             Address;
    responseAddress:  Address?;
    forwardTonAmount: Int as coins;
    forwardPayload:   Slice as remaining;
}

message BurnNotification {
    queryId:             Int as uint64;
    amount:              Int as coins;
    sender:              Address;
    responseDestination: Address?;
}

message Burn {
    queryId:             Int as uint64;
    amount:              Int as coins;
    responseDestination: Address?;
}

// Управление
message SetMinter      { newMinter:      Address; }
message SetAdminWallet { newAdminWallet: Address; }
message SetMarketing   { newWallet: Address; newPct: Int as uint8; }
message DisableMinting {}

// ── Основной контракт ──────────────────────────────────────────────────────

contract TCAToken with Deployable {

    // ── Роли ──
    owner:           Address;   // холодный кошелёк
    minter:          Address;   // горячий кошелёк бэкенда
    adminWallet:     Address;   // держит все токены проекта
    marketingWallet: Address;   // 5% от каждого минта
    marketingPct:    Int as uint8;  // 5

    // ── TEP-74 ──
    totalSupply: Int as coins;
    content:     Cell;
    mintable:    Bool;

    // ── Леджер (портфельный пул — заблокированные токены) ──
    portfolioLocked:      Int as coins;   // сумма всех портфелей игроков прямо сейчас
    profitCirculating:    Int as coins;   // сумма всех профитов (свободные, ждут вывода)
    totalMinted:          Int as coins;   // всего сминчено за всё время
    totalBurned:          Int as coins;   // всего сожжено за всё время
    totalWithdrawn:       Int as coins;   // всего выведено пользователями
    totalMarketingMinted: Int as coins;   // 5% маркетинга от всех минтов
    lastSyncAt:           Int as uint32;
    syncCount:            Int as uint32;

    init(
        owner:           Address,
        minter:          Address,
        adminWallet:     Address,
        marketingWallet: Address,
        content:         Cell
    ) {
        self.owner           = owner;
        self.minter          = minter;
        self.adminWallet     = adminWallet;
        self.marketingWallet = marketingWallet;
        self.marketingPct    = 5;

        self.totalSupply = 0;
        self.content     = content;
        self.mintable    = true;

        self.portfolioLocked      = 0;
        self.profitCirculating    = 0;
        self.totalMinted          = 0;
        self.totalBurned          = 0;
        self.totalWithdrawn       = 0;
        self.totalMarketingMinted = 0;
        self.lastSyncAt           = 0;
        self.syncCount            = 0;
    }

    // ── BatchMint — вызывается раз в 12 часов ─────────────────────────────
    //
    // Минтит (portfolioAmount + profitAmount) на adminWallet.
    // Плюс 5% от суммы на marketingWallet.

    receive(msg: BatchMint) {
        require(sender() == self.minter, "Only minter");
        require(self.mintable, "Minting disabled");

        let total:         Int = msg.portfolioAmount + msg.profitAmount;
        let marketingCut:  Int = total * self.marketingPct / 100;

        require(total > 0, "Nothing to mint");

        // Обновляем totalSupply
        self.totalSupply = self.totalSupply + total + marketingCut;

        // Минтим на adminWallet (все портфельные + профитные)
        self._mintTo(self.adminWallet, total, 0);

        // Минтим маркетинг
        if (marketingCut > 0) {
            self._mintTo(self.marketingWallet, marketingCut, 0);
        }

        // Обновляем леджер
        self.portfolioLocked   = self.portfolioLocked + msg.portfolioAmount;
        self.profitCirculating = self.profitCirculating + msg.profitAmount;
        self.totalMinted          = self.totalMinted + total + marketingCut;
        self.totalMarketingMinted = self.totalMarketingMinted + marketingCut;
        self.lastSyncAt = now();
        self.syncCount  = self.syncCount + 1;
    }

    // ── BatchBurn — вызывается раз в 12 часов ─────────────────────────────
    //
    // Сжигает портфельные токены с adminWallet.
    // Это взносы за уровни, взносы арены, сжигание фонда.

    receive(msg: BatchBurn) {
        require(sender() == self.minter, "Only minter");
        require(msg.amount > 0, "Nothing to burn");
        require(self.portfolioLocked >= msg.amount, "Burn exceeds portfolio locked");

        // Отправляем Burn на Jetton кошелёк adminWallet
        send(SendParameters{
            to:     self._walletAddr(self.adminWallet),
            value:  ton("0.05"),
            mode:   SendPayGasSeparately,
            bounce: true,
            body:   Burn{
                queryId:             0,
                amount:              msg.amount,
                responseDestination: self.minter
            }.toCell()
        });

        // Леджер обновляем сразу (оптимистично, burn почти всегда проходит)
        self.portfolioLocked = self.portfolioLocked - msg.amount;
        self.totalBurned     = self.totalBurned + msg.amount;
    }

    // ── RecordWithdrawal — после отправки токенов пользователю ────────────
    //
    // Бэкенд переводит токены с adminWallet на кошелёк пользователя,
    // потом вызывает этот метод чтобы обновить леджер.

    receive(msg: RecordWithdrawal) {
        require(sender() == self.minter, "Only minter");
        require(self.profitCirculating >= msg.amount, "Exceeds profit circulating");

        self.profitCirculating = self.profitCirculating - msg.amount;
        self.totalWithdrawn    = self.totalWithdrawn + msg.amount;
    }

    // ── BurnNotification от JettonWallet ──────────────────────────────────

    receive(msg: BurnNotification) {
        require(
            sender() == self._walletAddr(msg.sender),
            "Unauthorized burn notification"
        );
        self.totalSupply = self.totalSupply - msg.amount;
    }

    // ── Wallet address query (TEP-74) ──────────────────────────────────────

    receive(msg: ProvideWalletAddress) {
        send(SendParameters{
            to:     sender(),
            value:  0,
            mode:   SendRemainingValue,
            bounce: false,
            body:   TakeWalletAddress{
                queryId:      msg.queryId,
                walletAddress: self._walletAddr(msg.ownerAddress),
                ownerAddress:  msg.includeAddress
                    ? beginCell().storeAddress(msg.ownerAddress).endCell().asSlice()
                    : emptySlice()
            }.toCell()
        });
    }

    // ── Управление (только owner) ──────────────────────────────────────────

    receive(msg: SetMinter) {
        require(sender() == self.owner, "Only owner");
        self.minter = msg.newMinter;
    }

    receive(msg: SetAdminWallet) {
        require(sender() == self.owner, "Only owner");
        self.adminWallet = msg.newAdminWallet;
    }

    receive(msg: SetMarketing) {
        require(sender() == self.owner, "Only owner");
        require(msg.newPct <= 20, "Max 20%");
        self.marketingWallet = msg.newWallet;
        self.marketingPct    = msg.newPct;
    }

    receive(msg: DisableMinting) {
        require(sender() == self.owner, "Only owner");
        self.mintable = false;
    }

    // ── Внутренние хелперы ─────────────────────────────────────────────────

    fun _mintTo(to: Address, amount: Int, queryId: Int) {
        send(SendParameters{
            to:     self._walletAddr(to),
            value:  ton("0.05"),
            mode:   SendPayGasSeparately,
            bounce: false,
            body:   InternalTransfer{
                queryId:          queryId,
                amount:           amount,
                from:             myAddress(),
                responseAddress:  self.owner,
                forwardTonAmount: 0,
                forwardPayload:   emptySlice()
            }.toCell()
        });
    }

    fun _walletAddr(owner: Address): Address {
        return contractAddress(initOf JettonWallet(myAddress(), owner));
    }

    // ── Геттеры (видны в TON Explorer) ────────────────────────────────────

    // Леджер
    get fun portfolioLocked(): Int      { return self.portfolioLocked; }
    get fun profitCirculating(): Int    { return self.profitCirculating; }
    get fun totalInGame(): Int          { return self.portfolioLocked + self.profitCirculating; }
    get fun totalMinted(): Int          { return self.totalMinted; }
    get fun totalBurned(): Int          { return self.totalBurned; }
    get fun totalWithdrawn(): Int       { return self.totalWithdrawn; }
    get fun totalMarketingMinted(): Int { return self.totalMarketingMinted; }
    get fun lastSyncAt(): Int           { return self.lastSyncAt; }
    get fun syncCount(): Int            { return self.syncCount; }

    // Роли
    get fun owner(): Address           { return self.owner; }
    get fun minter(): Address          { return self.minter; }
    get fun adminWallet(): Address     { return self.adminWallet; }
    get fun marketingWallet(): Address { return self.marketingWallet; }
    get fun marketingPct(): Int        { return self.marketingPct; }

    // TEP-74 стандарт
    get fun totalSupply(): Int { return self.totalSupply; }
    get fun mintable(): Bool   { return self.mintable; }

    get fun jetton_data(): JettonData {
        return JettonData{
            total_supply:       self.totalSupply,
            mintable:           self.mintable,
            admin_address:      self.owner,
            jetton_content:     self.content,
            jetton_wallet_code: initOf JettonWallet(myAddress(), myAddress()).code
        };
    }

    get fun wallet_address(ownerAddress: Address): Address {
        return self._walletAddr(ownerAddress);
    }
}

struct JettonData {
    total_supply:       Int;
    mintable:           Bool;
    admin_address:      Address;
    jetton_content:     Cell;
    jetton_wallet_code: Cell;
}

// ── Jetton Wallet (TEP-74) ─────────────────────────────────────────────────

contract JettonWallet {
    balance: Int as coins;
    owner:   Address;
    master:  Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner   = owner;
        self.master  = master;
    }

    receive(msg: TokenTransfer) {
        require(sender() == self.owner, "Only owner can transfer");
        require(self.balance >= msg.amount, "Insufficient balance");

        self.balance = self.balance - msg.amount;

        send(SendParameters{
            to:     contractAddress(initOf JettonWallet(self.master, msg.destination)),
            value:  0,
            mode:   SendRemainingValue,
            bounce: false,
            body:   InternalTransfer{
                queryId:          msg.queryId,
                amount:           msg.amount,
                from:             self.owner,
                responseAddress:  msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload:   msg.forwardPayload
            }.toCell(),
            data: initOf JettonWallet(self.master, msg.destination).data
        });
    }

    receive(msg: InternalTransfer) {
        self.balance = self.balance + msg.amount;

        if (msg.responseAddress != null) {
            send(SendParameters{
                to:     msg.responseAddress!!,
                value:  0,
                mode:   SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body:   JettonExcesses{ queryId: msg.queryId }.toCell()
            });
        }
    }

    receive(msg: Burn) {
        require(sender() == self.owner, "Only owner can burn");
        require(self.balance >= msg.amount, "Insufficient balance");

        self.balance = self.balance - msg.amount;

        send(SendParameters{
            to:     self.master,
            value:  0,
            mode:   SendRemainingValue,
            bounce: false,
            body:   BurnNotification{
                queryId:             msg.queryId,
                amount:              msg.amount,
                sender:              self.owner,
                responseDestination: msg.responseDestination
            }.toCell()
        });
    }

    get fun get_wallet_data(): WalletData {
        return WalletData{
            balance: self.balance,
            owner:   self.owner,
            master:  self.master,
            code:    myCode()
        };
    }
}

struct WalletData {
    balance: Int;
    owner:   Address;
    master:  Address;
    code:    Cell;
}
