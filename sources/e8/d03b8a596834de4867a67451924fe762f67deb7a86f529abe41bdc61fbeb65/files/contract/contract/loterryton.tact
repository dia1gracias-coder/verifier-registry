import "@stdlib/deploy";

// ----------------- Constantes -----------------
const DAILY: Int = 1;
const WEEKLY: Int = 2;
const MONTHLY: Int = 3;
const MICRO: Int = 4;
const REFERRAL: Int = 5;

const DOMAIN_MAGIC: Int = 1416586322; // domain separation constant
const MAX_TICKETS_PER_TX: Int = 100;  // limite por transação
const WINDOW_SECONDS: Int = 86400;    // 24h window for per-address rate limiting

// ----------------- Mensagens -----------------
message BuyTickets {
  ltype: Int as uint8;
  qty:   Int as uint32;
}

message PerformDraw {
  payload:   Cell;   // conforme especificado no PRD
  signature: Slice;  // assinatura Ed25519 sobre hash(payload)
}

message WithdrawTaxes { amount: Int as coins; }
message WithdrawOwnerReserve { amount: Int as coins; to: Address; }
message WithdrawFailedPayout { to: Address; }
message SetAppKey { new_key: Int as uint256; }
message SetTaxAddress { new_addr: Address; }
message SetPause { paused: Bool; }
message SetPerAddressLimit { max_per_window: Int as uint32; } // admin opcional

message GrantTickets {
  ltype: Int as uint8;
  qty:   Int as uint32;
  target: Address; // O endereço do usuário que vai receber os bilhetes
}

message RetryFailedPayout {
    winner_address: Address;
}

// ----------------- Estruturas -----------------
struct Pool {
  tickets:        map<Int as uint256, Address>;
  total_tickets:  Int as uint256;
  prize_pool:     Int as coins;
  last_draw_id:   Int as uint64;
}

struct DrawLog {
  payload_hash:   Int as uint256;
  winner:         Address;
  ltype:          Int as uint8;
  prize:          Int as coins;
  timestamp:      Int as uint32;
}

struct PurchaseWindow {
  count:       Int as uint32;
  window_start:Int as uint32; // epoch seconds
}

// ----------------- Contract -----------------
contract Lottery_v2_4 with Deployable {
  // Config
  owner_address:    Address;         // recebe 10% nas compras (com fallback)
  tax_address:      Address;         // saque dos 5%
  app_pubkey:       Int as uint256;  // chave Ed25519 do app
  network_id:       Int as uint32;   // 0=testnet / 1=mainnet (set no init)
  paused:           Bool;

  // Fundos / Reserves
  tax_reserve:      Int as coins;       // 5% acumulado
  owner_reserve:    Int as coins;       // comissões que não puderam ser enviadas
  failed_payouts:   map<Address, Int as coins>; // prêmios a reenviar

  // Pools e logs
  pools:            map<Int as uint8, Pool>;
  draw_logs:        map<Int as uint64, DrawLog>;

  // Rate limiting simples por endereço
  per_address_window: map<Address, PurchaseWindow>;
  max_per_window:      Int as uint32;

  // Anti-reentrância
  locked:           Bool;

  // -------- init --------
  init(owner: Address, tax: Address, app_key: Int, net_id: Int, max_per_window_param: Int as uint32) {
    self.owner_address = owner;
    self.tax_address   = tax;
    self.app_pubkey    = app_key;
    self.network_id    = net_id;
    self.tax_reserve   = 0;
    self.owner_reserve = 0;
    self.failed_payouts = emptyMap();
    self.pools         = emptyMap();
    self.draw_logs     = emptyMap();
    self.per_address_window = emptyMap();
    self.max_per_window = max_per_window_param;
    self.paused        = false;
    self.locked        = false;
  }

  // --------- Utils ----------
  fun isValidType(ltype: Int): Bool {
    return ltype == DAILY || ltype == WEEKLY || ltype == MONTHLY || ltype == MICRO || ltype == REFERRAL;
  }

  fun getPrice(ltype: Int): Int {
    if (ltype == DAILY) {
      return 100000000;     // 0.1 TON
    }
    if (ltype == WEEKLY) {
      return 300000000;     // 0.3 TON
    }
    if (ltype == MONTHLY) {
      return 1000000000;   // 1.0 TON
    }
    if (ltype == MICRO) {
      return 10000000;      // 0.01 TON
    }
    if (ltype == REFERRAL) {
      return 0;              // Bilhete de indicação é grátis
    }
    require(false, "invalid ltype");
    return 0; // This line will never be reached but satisfies the compiler
  }

  fun loadOrInitPool(ltype: Int): Pool {
    let p = self.pools.get(ltype);
    if (p == null) {
      return Pool{ tickets: emptyMap(), total_tickets: 0, prize_pool: 0, last_draw_id: 0 };
    }
    return p!!;
  }

  // helper de envio "seguro": tenta enviar, se falhar retorna false
  fun trySend(to: Address, amount: Int): Bool {
    if (amount <= 0) { return false; }
    try {
      send(SendParameters{ to: to, value: amount, bounce: false });
      return true;
    } catch (e) {
      return false;
    }
  }

  // registra compra no window do endereço e valida limite
  fun checkAndUpdateWindow(addr: Address, qty: Int) {
    let now_ts = now();
    let pw = self.per_address_window.get(addr);

    if (pw == null) {
      // primeira compra
      self.per_address_window.set(addr, PurchaseWindow{ count: qty, window_start: now_ts });
      return;
    }

    let window_p = pw!!;
    let elapsed = now_ts - window_p.window_start;

    if (elapsed >= WINDOW_SECONDS) {
      // reset window
      self.per_address_window.set(addr, PurchaseWindow{ count: qty, window_start: now_ts });
    } else {
      // dentro do window atual
      let new_count = window_p.count + qty;
      require(new_count <= self.max_per_window, "rate limit");
      self.per_address_window.set(addr, PurchaseWindow{ count: new_count, window_start: window_p.window_start });
    }
  }

  // Compra de tickets (checks → effects → interactions)
  receive(msg: BuyTickets) {
    require(!self.paused, "paused");
    require(!self.locked, "locked");
    self.locked = true;

    require(self.isValidType(msg.ltype), "invalid type");
    require(msg.qty > 0 && msg.qty <= MAX_TICKETS_PER_TX, "qty");

    // Checks: valor recebido
    let price_per = self.getPrice(msg.ltype);
    let total_price = price_per * msg.qty;

    if (msg.ltype != REFERRAL) {
      require(context().value >= total_price, "insufficient funds");
    }

    // Rate limiting
    self.checkAndUpdateWindow(sender(), msg.qty);

    // Effects: atualizar estado
    let pool = self.loadOrInitPool(msg.ltype);

    // add tickets to pool
    repeat(msg.qty) {
      pool.tickets.set(pool.total_tickets, sender());
      pool.total_tickets = pool.total_tickets + 1;
    }

    // Distribuição dos fundos
    if (msg.ltype != REFERRAL) {
      let tax_share = total_price * 5 / 100;   // 5%
      let owner_share = total_price * 10 / 100; // 10%
      let prize_share = total_price - tax_share - owner_share; // 85%

      pool.prize_pool = pool.prize_pool + prize_share;
      self.tax_reserve = self.tax_reserve + tax_share;

      // Interactions: tentar enviar 10% para owner
      let sent = self.trySend(self.owner_address, owner_share);
      if (!sent) {
        self.owner_reserve = self.owner_reserve + owner_share;
      }
    }

    self.pools.set(msg.ltype, pool);
    self.locked = false;
  }

  // -------- Getters --------
  get fun poolInfo(ltype: Int): Pool? {
    return self.pools.get(ltype);
  }

  get fun drawLog(draw_id: Int): DrawLog? {
    return self.draw_logs.get(draw_id);
  }

  get fun failedPayout(addr: Address): Int {
    let payout = self.failed_payouts.get(addr);
    if (payout == null) {
      return 0;
    }
    return payout!!;
  }

  get fun taxReserve(): Int {
    return self.tax_reserve;
  }

  get fun ownerReserve(): Int {
    return self.owner_reserve;
  }

  get fun ownerAddress(): Address {
    return self.owner_address;
  }

  get fun taxAddress(): Address {
    return self.tax_address;
  }

  get fun appPubkey(): Int {
    return self.app_pubkey;
  }

  get fun networkId(): Int {
    return self.network_id;
  }

  get fun isPaused(): Bool {
    return self.paused;
  }

  get fun rateLimitInfo(addr: Address): PurchaseWindow? {
    return self.per_address_window.get(addr);
  }
}