
import "@stdlib/deploy";

// ========================= SIMPLE LOTTERY V2 - SISTEMA CORRIGIDO =========================
// 🎲 Contrato COMPLETO: Compras + Sorteios + Distribuição Automática
// ✅ Sintaxe TACT corrigida, SEM maps aninhados, SEM duplicatas
// ========================================================================

// 📋 Constantes
const MICRO: Int = 1;   // 0.2 TON
const DAILY: Int = 2;   // 0.5 TON  
const WEEKLY: Int = 3;  // 1.0 TON
const MONTHLY: Int = 4; // 3.0 TON

// 💰 Distribuição de fundos
const PRIZE_PERCENT: Int = 85;  // 85% para prêmios
const OWNER_PERCENT: Int = 10;  // 10% para owner
const TAX_PERCENT: Int = 5;     // 5% para taxa

// 🔧 Configurações
const MAX_TICKETS_PER_TX: Int = 100;
const MIN_GAS_RESERVE: Int = 50000000; // 0.05 TON reserve

// 📍 Endereços fixos
const OWNER_ADDRESS: Address = address("0QCctqBWGMxl2zfTs3hSXtkYX4yXEUHMoqQPlmCE2Gf_2RPU");
const TAX_ADDRESS: Address = address("0QCctqBWGMxl2zfTs3hSXtkYX4yXEUHMoqQPlmCE2Gf_2RPU");

// 📦 Estrutura para ticket
struct Ticket {
  owner: Address;
  lottery_type: Int as uint8;
  created_at: Int as uint32;
}

// 📨 Mensagens para sorteios
message StartDraw {
  lottery_type: Int as uint8;
}

message FinalizeDraw {
  lottery_type: Int as uint8;
  external_seed: Int as uint256;
}

// ====================== CONTRATO PRINCIPAL ======================
contract SimpleLottery with Deployable {
  // 🏗️ Estado básico
  owner: Address;
  paused: Bool;
  
  // 💰 Pools de prêmios por tipo
  prize_pools: map<Int as uint8, Int as coins>;
  
  // 🎫 Tickets usando ID único global: global_ticket_id -> Ticket
  tickets: map<Int as uint64, Ticket>;
  
  // 🔢 Contador global de tickets
  global_ticket_counter: Int as uint64;
  
  // 🔢 Contador de tickets por tipo
  ticket_counters: map<Int as uint8, Int as uint64>;
  
  // 🎲 Sistema de sorteio
  active_draws: map<Int as uint8, Bool>;
  draw_winners: map<Int as uint8, Address>;
  
  // ========== INICIALIZAÇÃO ==========
  init() {
    self.owner = OWNER_ADDRESS;
    self.paused = false;
    self.prize_pools = emptyMap();
    self.tickets = emptyMap();
    self.global_ticket_counter = 0;
    self.ticket_counters = emptyMap();
    self.active_draws = emptyMap();
    self.draw_winners = emptyMap();
    
    // Inicializar contadores
    self.ticket_counters.set(MICRO, 0);
    self.ticket_counters.set(DAILY, 0);
    self.ticket_counters.set(WEEKLY, 0);
    self.ticket_counters.set(MONTHLY, 0);
    
    // Inicializar pools
    self.prize_pools.set(MICRO, 0);
    self.prize_pools.set(DAILY, 0);
    self.prize_pools.set(WEEKLY, 0);
    self.prize_pools.set(MONTHLY, 0);
  }
  
  // ========== FUNÇÕES AUXILIARES ==========
  
  // 💰 Obter preço por tipo
  fun getPrice(ltype: Int): Int {
    if (ltype == MICRO) { return ton("0.2"); }
    if (ltype == DAILY) { return ton("0.5"); }
    if (ltype == WEEKLY) { return ton("1.0"); }
    if (ltype == MONTHLY) { return ton("3.0"); }
    return 0;
  }
  
  // ✅ Validar tipo de loteria
  fun isValidType(ltype: Int): Bool {
    return ltype >= MICRO && ltype <= MONTHLY;
  }
  
  // 📤 Enviar TON com tratamento de erro
  fun safeSend(to: Address, amount: Int, bounce: Bool) {
    if (amount > 0) {
      send(SendParameters{
        to: to,
        value: amount,
        mode: SendPayGasSeparately,
        bounce: bounce,
        body: emptyCell()
      });
    }
  }
  
  // 🎫 Adicionar ticket ao pool
  fun addTicketToPool(ltype: Int, buyer: Address) {
    // Incrementar contador global
    self.global_ticket_counter += 1;
    
    // Criar ticket
    let ticket = Ticket{
      owner: buyer,
      lottery_type: ltype,
      created_at: now()
    };
    
    // Armazenar ticket com ID global
    self.tickets.set(self.global_ticket_counter, ticket);
    
    // Atualizar contador do tipo
    let current_count = self.ticket_counters.get(ltype);
    if (current_count == null) {
      self.ticket_counters.set(ltype, 1);
    } else {
      self.ticket_counters.set(ltype, current_count!! + 1);
    }
  }
  
  // ========== COMPRA DE TICKETS (SEM OPCODE) ==========
  
  receive(msg: Slice) {
    // 🔒 Verificações de segurança básicas
    require(!self.paused, "Contract paused");
    
    // 📦 Parse direto do payload (SEM OPCODE!)
    let ltype = msg.loadUint(8);      // Byte 1: tipo da loteria
    let qty = msg.loadUint(32);       // Bytes 2-5: quantidade
    msg.endParse();                   // ✅ CRÍTICO: consumir todo payload
    
    // ✅ Validações
    require(self.isValidType(ltype), "Invalid lottery type");
    require(qty > 0 && qty <= MAX_TICKETS_PER_TX, "Invalid quantity");
    
    let sender = context().sender;
    let received = context().value;
    
    // 💰 Calcular valores
    let ticket_price = self.getPrice(ltype);
    let total_cost = ticket_price * qty;
    let gas_needed = MIN_GAS_RESERVE;
    
    // 💳 Verificar pagamento
    require(received >= total_cost + gas_needed, "Insufficient payment");
    
    // 📊 Distribuir fundos automaticamente
    let prize_amount = (total_cost * PRIZE_PERCENT) / 100;
    let owner_amount = (total_cost * OWNER_PERCENT) / 100;
    let tax_amount = (total_cost * TAX_PERCENT) / 100;
    
    // 💰 Atualizar pool de prêmios
    let current_pool = self.prize_pools.get(ltype);
    if (current_pool == null) {
      self.prize_pools.set(ltype, prize_amount);
    } else {
      self.prize_pools.set(ltype, current_pool!! + prize_amount);
    }
    
    // 🎫 Adicionar tickets
    let i = 0;
    while (i < qty) {
      self.addTicketToPool(ltype, sender);
      i = i + 1;
    }
    
    // 💸 Enviar comissões imediatamente
    self.safeSend(OWNER_ADDRESS, owner_amount, false);
    self.safeSend(TAX_ADDRESS, tax_amount, false);
    
    // 💰 Refund do excesso (se houver)
    let excess = received - total_cost - gas_needed;
    if (excess > 0) {
      self.safeSend(sender, excess, false);
    }
  }
  
  // ========== SISTEMA DE SORTEIO SEGURO ==========
  
  // 🎲 Iniciar sorteio (apenas owner)
  receive(msg: StartDraw) {
    let sender = context().sender;
    require(sender == self.owner, "Unauthorized");
    require(context().value >= ton("0.1"), "Insufficient gas");
    
    let ltype = msg.lottery_type;
    require(self.isValidType(ltype), "Invalid lottery type");
    
    let is_active = self.active_draws.get(ltype);
    if (is_active != null) {
      require(is_active!! == false, "Draw already active");
    }
    
    let total_tickets = self.ticket_counters.get(ltype);
    require(total_tickets != null && total_tickets!! > 0, "No tickets sold");
    
    // Marcar sorteio como ativo
    self.active_draws.set(ltype, true);
  }
  
  // 🏆 Finalizar sorteio com seed externo
  receive(msg: FinalizeDraw) {
    let sender = context().sender;
    require(sender == self.owner, "Unauthorized");
    require(context().value >= ton("0.1"), "Insufficient gas");
    
    let ltype = msg.lottery_type;
    let external_seed = msg.external_seed;
    
    require(self.isValidType(ltype), "Invalid lottery type");
    
    let is_active = self.active_draws.get(ltype);
    require(is_active != null && is_active!! == true, "No active draw");
    
    let total_tickets = self.ticket_counters.get(ltype);
    require(total_tickets != null && total_tickets!! > 0, "No tickets");
    
    // 🎯 Encontrar tickets do tipo específico e escolher vencedor
    let winner_found = false;
    let winner_address: Address = self.owner; // default fallback
    
    // Criar lista temporária de tickets válidos para este tipo
    let tickets_of_type: map<Int, Address> = emptyMap();
    let valid_ticket_count = 0;
    
    // Iterar através de todos os tickets e filtrar por tipo
    let ticket_id = 1;
    while (ticket_id <= self.global_ticket_counter) {
      let ticket = self.tickets.get(ticket_id);
      if (ticket != null) {
        let t = ticket!!;
        if (t.lottery_type == ltype) {
          tickets_of_type.set(valid_ticket_count, t.owner);
          valid_ticket_count += 1;
        }
      }
      ticket_id += 1;
    }
    
    // Selecionar vencedor se houver tickets válidos
    if (valid_ticket_count > 0) {
      let block_time = now();
      let combined_seed = external_seed + block_time;
      let winner_index = combined_seed % valid_ticket_count;
      
      let winner = tickets_of_type.get(winner_index);
      if (winner != null) {
        winner_address = winner!!;
        winner_found = true;
      }
    }
    
    if (winner_found) {
      self.draw_winners.set(ltype, winner_address);
      
      // 💰 Transferir prêmio
      let prize = self.prize_pools.get(ltype);
      if (prize != null && prize!! > 0) {
        self.safeSend(winner_address, prize!!, false);
        self.prize_pools.set(ltype, 0);
      }
    }
    
    // 🔄 Reset do sorteio
    self.active_draws.set(ltype, false);
    self.ticket_counters.set(ltype, 0);
    
    // Limpar tickets deste tipo
    ticket_id = 1;
    while (ticket_id <= self.global_ticket_counter) {
      let ticket = self.tickets.get(ticket_id);
      if (ticket != null) {
        let t = ticket!!;
        if (t.lottery_type == ltype) {
          self.tickets.del(ticket_id);
        }
      }
      ticket_id += 1;
    }
  }
  
  // ========== FUNÇÕES DE CONSULTA (GETTERS) ==========
  
  get fun getPrizePool(ltype: Int): Int {
    if (!self.isValidType(ltype)) { return 0; }
    let pool = self.prize_pools.get(ltype);
    return pool == null ? 0 : pool!!;
  }
  
  get fun getTotalTicketsForType(ltype: Int): Int {
    if (!self.isValidType(ltype)) { return 0; }
    let tickets = self.ticket_counters.get(ltype);
    return tickets == null ? 0 : tickets!!;
  }
  
  get fun getIsDrawActive(ltype: Int): Bool {
    if (!self.isValidType(ltype)) { return false; }
    let is_active = self.active_draws.get(ltype);
    return is_active != null && is_active!!;
  }
  
  get fun getAllPrizePools(): map<Int, Int> {
    let result: map<Int, Int> = emptyMap();
    result.set(MICRO, self.getPrizePool(MICRO));
    result.set(DAILY, self.getPrizePool(DAILY));
    result.set(WEEKLY, self.getPrizePool(WEEKLY));
    result.set(MONTHLY, self.getPrizePool(MONTHLY));
    return result;
  }
  
  get fun getAllTicketCounts(): map<Int, Int> {
    let result: map<Int, Int> = emptyMap();
    result.set(MICRO, self.getTotalTicketsForType(MICRO));
    result.set(DAILY, self.getTotalTicketsForType(DAILY));
    result.set(WEEKLY, self.getTotalTicketsForType(WEEKLY));
    result.set(MONTHLY, self.getTotalTicketsForType(MONTHLY));
    return result;
  }
  
  get fun getTicketPrice(ltype: Int): Int {
    return self.getPrice(ltype);
  }
  
  get fun isPaused(): Bool {
    return self.paused;
  }
  
  get fun getOwner(): Address {
    return self.owner;
  }
  
  get fun getWinner(ltype: Int): Address? {
    return self.draw_winners.get(ltype);
  }
  
  get fun getTotalTickets(): Int {
    return self.global_ticket_counter;
  }
  
  // ========== FUNÇÕES ADMINISTRATIVAS ==========
  
  receive("pause") {
    require(context().sender == self.owner, "Unauthorized");
    self.paused = true;
  }
  
  receive("resume") {
    require(context().sender == self.owner, "Unauthorized");  
    self.paused = false;
  }
  
  // 💰 Retirar fundos de emergência (owner apenas)
  receive("withdraw") {
    require(context().sender == self.owner, "Unauthorized");
    require(context().value >= ton("0.1"), "Insufficient gas");
    
    let balance = myBalance();
    let reserve = MIN_GAS_RESERVE;
    
    if (balance > reserve) {
      let amount = balance - reserve;
      self.safeSend(self.owner, amount, false);
    }
  }
  
  // ========== TRATAMENTO DE BOUNCE ==========
  // Bounced messages são tratados automaticamente pelo sistema TON
  // Em caso de falha no envio, os fundos ficam no contrato
  // Owner pode retirar manualmente usando a função "withdraw"
}
