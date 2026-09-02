import "@stdlib/deploy";
import "@stdlib/ownable";

message BatchAnchoredEvent {
    merkle_root_msg: String;
    timestamp: Int as uint32;
    sender: Address;
}

contract ProofRegistry with Deployable, Ownable {

    owner: Address;
    total_batches: Int as uint32;

    init(owner: Address) {
        self.owner = owner;
        self.total_batches = 0;
    }

    // 1. Фиксация батча (Оставляем String ради красивого TONViewer!)
    receive(msg: String) {
        self.requireOwner();
        self.total_batches = self.total_batches + 1;

        emit(BatchAnchoredEvent{
            merkle_root_msg: msg,
            timestamp: now(),
            sender: sender()
        }.toCell());
    }

    // 2. Сбор урожая (Оставляем резерв, чтобы контракт жил вечно!)
    receive("withdraw") {
        self.requireOwner();

        // Резервируем 0.05 TON на вечную оплату хранения (Storage fee)
        let reserve: Int = ton("0.05");
        let amount_to_send: Int = myBalance() - reserve - ton("0.01"); // Минус газ на саму транзакцию вывода

        // Выводим только если накопилось больше резерва
        require(amount_to_send > 0, "Insufficient funds to withdraw");

        send(SendParameters{
            to: self.owner,
            value: amount_to_send,
            mode: SendIgnoreErrors, // Переводим конкретно высчитанную сумму (amount_to_send)
            body: "ProofCore Yield".asComment()
        });
    }

    get fun getTotalBatches(): Int {
        return self.total_batches;
    }
}