import "@stdlib/deploy";
import "./gas";

message Add {
    queryId: Int as uint64;
}

contract TestGas with Deployable, GasManager {
    id: Int as uint32;
    old_increment: Int as uint32;
    increment: Int as uint32;
    // Добавляем статистику для GasManager
    gasStats: StorageStats;
    gasResults: GasDeductionResult;

    init(id: Int) {
        self.id = id;
        self.increment = 0;
        self.old_increment = 0;

        self.gasResults = GasDeductionResult{
            initialAmount: 0,
            gasAmount: 0,
            remainingAmount: 0,
            isEnough: false
        };

        // Инициализируем статистику использования газа
        self.gasStats = StorageStats{
            lastUpdateTime: now(),
            transactionCount: 0,
            totalTimeInterval: 0,
            totalStorageDueCollected: 0,
            reservedStorage: 0,
            storageLimit: 0,
            lastTonsReserve: 0,
            storageTonsDeficit: 0
        };
    }

    override fun getGasResults(incomingTons: Int): GasDeductionResult {
        if (self.old_increment != self.increment) {
            self.gasResults = self.deductGas(incomingTons);
            self.old_increment = self.increment;
        }
        return self.gasResults;
    }

    // Реализация абстрактных методов GasManager
    override fun getStorageStats(): StorageStats {
        return self.gasStats;
    }
    
    override fun setStorageStats(stats: StorageStats): Bool {
        self.gasStats = stats;
        return true;
    }

    receive(msg: Add) {
        self.increment = self.increment + 1;

        // Используем GasManager для учета газа
        let incomingValue: Int = context().value;
        let gasResults = self.getGasResults(incomingValue);
        
        // Проверяем, достаточно ли средств для отправки сообщения
        let valueToSend = max(0, gasResults.remainingAmount);
        
        if (valueToSend > 0) {
            send(SendParameters{
                to: sender(),
                value: valueToSend,
                mode: SendIgnoreErrors,
                body: gasResults.gasAmount.toString().asComment()
            });
        }
    }
    
    get fun counter(): Int {
        return self.increment;
    }

    get fun id(): Int {
        return self.id;
    }
    
    // Добавляем геттер для статистики использования газа
    get fun gasStats(): StorageStats {
        return self.gasStats;
    }
}
