import "@stdlib/deploy";

// =============================================================
// Multisig (governance) — владелец основных контрактов.
// Каждая ЗАЯВКА несёт собственный порог `required` (сколько подписей нужно):
// вывод/глобальное — все N, мелкие настройки — 2-3. Порог задаётся при создании,
// но не ниже `minApprovals` (пол, защита от «задачи на 1 подпись»).
// Заявку может создать любой подписант ИЛИ `proposer` (серверный ключ из админки):
// proposer НЕ голосует (его создание = 0 подписей), нужны подписи владельцев.
// По достижении required мультисиг сам исполняет body в target.
// =============================================================

struct MsOrder {
    target: Address;
    value: Int as coins;
    body: Cell;
    submitter: Address;       // кто создал заявку (только он может её отменить)
    required: Int as uint8;   // сколько подписей нужно ИМЕННО этой заявке
    mask: Int as uint32;      // битовая маска одобривших подписантов
    approvals: Int as uint8;
    executed: Bool;
    rejected: Bool;           // отменена автором -> нужна новая заявка
    expiresAt: Int as uint64; // 0 = без срока
    epoch: Int as uint32;     // H-1: эпоха набора подписантов; при ротации старые заявки недействительны
}

message MsSubmit {
    target: Address;
    value: Int as coins;
    body: Cell;
    required: Int;            // требуемое число подписей (клампится к [minApprovals..signersCount])
    expiresAt: Int as uint64;
}
message MsApprove { orderId: Int as uint32; }
message MsReject { orderId: Int as uint32; }
// Ротация подписантов/пола/proposer. Только через исполненную заявку самого
// мультисига (= достигнут кворум), поэтому потеря ключа не окирпичивает контракт.
message MsGovern {
    signers: map<Int, Address>;
    signersCount: Int;
    minApprovals: Int;
    proposer: Address;
}

struct MsInfo {
    minApprovals: Int;
    signersCount: Int;
    orderSeq: Int;
    proposer: Address;
}

// View заявки БЕЗ поля Cell (body) — читается гет-методом на любом RPC.
struct OrderView {
    exists: Bool;
    target: Address;
    value: Int as coins;
    submitter: Address;
    required: Int;
    approvals: Int;
    mask: Int;
    executed: Bool;
    rejected: Bool;
    expiresAt: Int as uint64;
}

contract Multisig with Deployable {
    minApprovals: Int as uint8;   // пол: заявка не может требовать меньше
    signersCount: Int as uint8;
    proposer: Address;            // серверный ключ, создаёт задачи (не голосует)
    signers: map<Int, Address>;   // индекс (0..signersCount-1) -> адрес подписанта
    orderSeq: Int as uint32;
    orders: map<Int, MsOrder>;
    epoch: Int as uint32;         // H-1: текущая эпоха набора подписантов (растёт при ротации)

    init(signers: map<Int, Address>, signersCount: Int, minApprovals: Int, proposer: Address) {
        require(signersCount >= 1 && signersCount <= 32, "bad signersCount");
        require(minApprovals >= 1 && minApprovals <= signersCount, "bad minApprovals");
        let i: Int = 0;
        while (i < signersCount) {
            let ai = signers.get(i);
            require(ai != null, "missing signer");
            let j: Int = i + 1;
            while (j < signersCount) {
                require(signers.get(j)!! != ai!!, "duplicate signer");
                j += 1;
            }
            i += 1;
        }
        self.signers = signers;
        self.signersCount = signersCount;
        self.minApprovals = minApprovals;
        self.proposer = proposer;
        self.orderSeq = 0;
        self.epoch = 0;
    }

    fun signerIndex(a: Address): Int {
        let i: Int = 0;
        while (i < self.signersCount) {
            let s = self.signers.get(i);
            if (s != null && (s!! == a)) { return i }
            i += 1;
        }
        return -1;
    }

    // клампим требуемый порог к [minApprovals .. signersCount]
    fun clampRequired(r: Int): Int {
        if (r < self.minApprovals) { return self.minApprovals }
        if (r > self.signersCount) { return self.signersCount }
        return r;
    }

    fun execute(order: MsOrder) {
        send(SendParameters { to: order.target, value: order.value, mode: SendPayGasSeparately, body: order.body });
    }

    receive(msg: MsSubmit) {
        let idx = self.signerIndex(sender());
        let isProposer = sender() == self.proposer;
        throwUnless(401, idx >= 0 || isProposer);
        if (msg.expiresAt != 0) { throwUnless(410, now() <= msg.expiresAt) }
        let req = self.clampRequired(msg.required);
        // если создал подписант — его голос сразу засчитан; если proposer — 0 голосов
        let startMask = (idx >= 0) ? (1 << idx) : 0;
        let startApprovals = (idx >= 0) ? 1 : 0;
        let order = MsOrder {
            target: msg.target, value: msg.value, body: msg.body, submitter: sender(),
            required: req, mask: startMask, approvals: startApprovals,
            executed: (startApprovals >= req), rejected: false, expiresAt: msg.expiresAt,
            epoch: self.epoch,
        };
        self.orders.set(self.orderSeq, order);
        self.orderSeq += 1;
        if (order.executed) { self.execute(order) }
    }

    receive(msg: MsApprove) {
        let idx = self.signerIndex(sender());
        throwUnless(401, idx >= 0);
        let o = self.orders.get(msg.orderId);
        throwUnless(404, o != null);
        let order = o!!;
        throwUnless(409, !order.executed);
        throwUnless(411, !order.rejected);
        throwUnless(412, order.epoch == self.epoch); // H-1: заявки из старой эпохи недействительны
        if (order.expiresAt != 0) { throwUnless(410, now() <= order.expiresAt) }
        let bit = 1 << idx;
        throwUnless(403, (order.mask & bit) == 0);
        order.mask = order.mask | bit;
        order.approvals += 1;
        if (order.approvals >= order.required) { order.executed = true }
        self.orders.set(msg.orderId, order);
        if (order.executed) { self.execute(order) }
    }

    // Отменить заявку может только её автор (submitter). Несогласные просто не подписывают.
    receive(msg: MsReject) {
        let o = self.orders.get(msg.orderId);
        throwUnless(404, o != null);
        let order = o!!;
        throwUnless(403, sender() == order.submitter);
        throwUnless(409, !order.executed);
        throwUnless(411, !order.rejected);
        order.rejected = true;
        self.orders.set(msg.orderId, order);
    }

    // Ротация — только из исполненной заявки самого мультисига (кворум).
    receive(msg: MsGovern) {
        throwUnless(401, sender() == myAddress());
        require(msg.signersCount >= 1 && msg.signersCount <= 32, "bad signersCount");
        require(msg.minApprovals >= 1 && msg.minApprovals <= msg.signersCount, "bad minApprovals");
        let i: Int = 0;
        while (i < msg.signersCount) {
            let ai = msg.signers.get(i);
            require(ai != null, "missing signer");
            let j: Int = i + 1;
            while (j < msg.signersCount) {
                require(msg.signers.get(j)!! != ai!!, "duplicate signer");
                j += 1;
            }
            i += 1;
        }
        self.signers = msg.signers;
        self.signersCount = msg.signersCount;
        self.minApprovals = msg.minApprovals;
        self.proposer = msg.proposer;
        self.epoch += 1; // H-1: все висящие заявки прошлой эпохи становятся недействительны
    }

    get fun msInfo(): MsInfo {
        return MsInfo { minApprovals: self.minApprovals, signersCount: self.signersCount, orderSeq: self.orderSeq, proposer: self.proposer };
    }
    get fun order(id: Int): MsOrder? { return self.orders.get(id); }
    get fun orderView(id: Int): OrderView {
        let o = self.orders.get(id);
        if (o == null) {
            return OrderView { exists: false, target: myAddress(), value: 0, submitter: myAddress(), required: 0, approvals: 0, mask: 0, executed: false, rejected: false, expiresAt: 0 };
        }
        let ord = o!!;
        return OrderView { exists: true, target: ord.target, value: ord.value, submitter: ord.submitter, required: ord.required, approvals: ord.approvals, mask: ord.mask, executed: ord.executed, rejected: ord.rejected, expiresAt: ord.expiresAt };
    }
    get fun signer(i: Int): Address? { return self.signers.get(i); }
    get fun isSigner(a: Address): Bool { return self.signerIndex(a) >= 0; }
}
