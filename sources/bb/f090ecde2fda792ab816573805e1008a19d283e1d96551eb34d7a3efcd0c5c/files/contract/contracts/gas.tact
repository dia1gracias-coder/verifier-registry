import "@stdlib/deploy";

/**
 * newGas.tact
 * Упрощенная утилита для управления газом в проекте Pyramida
 */

// Период хранения контрактов в секундах
// 10 лет = 10 * 365 * 24 * 3600 секунд
const STORAGE_PERIOD: Int = 10 * 365 * 24 * 3600;

/**
 * Структура с информацией о вычтенном газе и оставшейся сумме
 */
 
struct GasDeductionResult {
    initialAmount: Int;     // Исходная сумма 
    gasAmount: Int;  // Количество TON, отложенное на газ
    remainingAmount: Int;   // Оставшаяся сумма для бизнес-логики
    isEnough: Bool;         // Достаточно ли было средств
}

struct GasReserve {
    amount: Int;   
}

/**
 * Структура для хранения статистики использования контракта
 * Используется для адаптивного расчета стоимости хранения
 */
struct StorageStats {
    lastUpdateTime: Int;             // Время последнего обновления статистики
    transactionCount: Int;           // Всего учтённых транзакций
    totalTimeInterval: Int;          // Суммарное время между транзакциями
    totalStorageDueCollected: Int;   // Сумма собранных myStorageDue()
    reservedStorage: Int;            // Уже зарезервированные средства на хранение
    storageLimit: Int;               // Предел резервирования, рассчитаный на 10 лет хранения контракта
    lastTonsReserve: Int;            // Последний резерв TON
    storageTonsDeficit: Int;         // Дефицит резерва
}

/**
 * Трейт для расчета и вычитания газа из входящих сообщений
 */
trait GasManager {
    // Абстрактное состояние, которое должны реализовать контракты
    abstract fun getStorageStats(): StorageStats;
    abstract fun setStorageStats(stats: StorageStats): Bool;
    abstract fun getGasResults(incomingTons: Int): GasDeductionResult;
    
    /**
     * Главная функция - вычитает газ из входящей суммы TON
     * 
     * @param incomingTons - входящая сумма TON (обычно context().value)
     * @returns структура с информацией о вычтенном газе и оставшейся сумме
     */
    virtual fun deductGas(
        incomingTons: Int
    ): GasDeductionResult {
        // 0. Обновляем статистику использования
        let stats: StorageStats = self.getStorageStats();
        let updatedStats: StorageStats = self.updateStorageStats(stats);

        // 0.1. Вычисляем ускоренный в 10 раз период хранения
        let acceleratedTime = max(1, STORAGE_PERIOD/10);

        // 1. Вычисляем текущие потребности в газе для хранения контракта в течение 10 лет
        let storageLimit: Int = self.calculateAdaptiveStorageFee(updatedStats);
        updatedStats.storageLimit = storageLimit;
                
        // 3. Вычисляем, сколько нужно дополнительно средств на хранение
        let storageTonsDeficit: Int = max(1, storageLimit - updatedStats.reservedStorage);
        updatedStats.storageTonsDeficit = storageTonsDeficit;

        let avgStorageDuePerTransaction: Int = max(1, updatedStats.totalStorageDueCollected / updatedStats.transactionCount);
        let avgInterval: Int = max(1, updatedStats.totalTimeInterval / updatedStats.transactionCount);
        
        let needTransactionCount: Int = max(1, storageTonsDeficit / max(1,avgStorageDuePerTransaction));
        let storagePeriodPercent: Int = max(1, ((needTransactionCount*avgInterval)*100) / (acceleratedTime));
        let storageLimitPercent: Int = max(1, storageTonsDeficit*100 / max(1,storageLimit));
        let myStorageDue: Int = myStorageDue();

        let additionalStorageNeeded: Int = max(myStorageDue, avgStorageDuePerTransaction) * (max(120, 100 + (((storagePeriodPercent+storageLimitPercent)/2) * (myStorageDue / avgStorageDuePerTransaction))))/100;
        
        // 5. Сколько нужно всего газа: дополнительное хранение + операция
        let totalGasNeeded: Int = additionalStorageNeeded+self.getComputeGas();
        
        // 6. Проверяем, достаточно ли входящих TON для покрытия газа
        let isEnough: Bool = incomingTons >= totalGasNeeded;
        
        // 7. Определяем, сколько можно вычесть
        let gasToDeduct: Int = min(incomingTons, totalGasNeeded);
        
        // 8. Обновляем зарезервированную сумму для хранения
        if (additionalStorageNeeded > 0 && isEnough) {
            updatedStats.reservedStorage += additionalStorageNeeded;
            updatedStats.lastTonsReserve = additionalStorageNeeded;
        }
                
        // 9. Расcчитываем остаток
        let remainingAmount: Int = max(0, incomingTons - gasToDeduct);
        self.setStorageStats(updatedStats);
        
        return GasDeductionResult {
            initialAmount: incomingTons,
            gasAmount: gasToDeduct,
            remainingAmount: remainingAmount,
            isEnough: isEnough
        };
    }
    

    /**
     * Обновляет статистику использования контракта используя упрощенное скользящее окно
     * для последних 100 транзакций без хранения истории каждой транзакции
     * @param stats - текущая статистика
     * @returns обновленная статистика
     */
    virtual fun updateStorageStats(stats: StorageStats): StorageStats {
        let currentTime: Int = now();
        
        // Текущие значения для обновления
        let currentStorageDue: Int = max(1, myStorageDue());
        
        // Если это первая транзакция
        if (stats.transactionCount == 0) {
            return StorageStats{
                lastUpdateTime: currentTime,
                transactionCount: 1,
                totalTimeInterval: 1,
                totalStorageDueCollected: currentStorageDue,
                reservedStorage: 0,
                storageLimit: 0,
                lastTonsReserve: 0,
                storageTonsDeficit: 0
            };
        }

        let timeInterval: Int = currentTime - stats.lastUpdateTime;
        
        // Вычисляем, сколько было потрачено средств из резерва с момента последней транзакции
        // Используем среднюю стоимость хранения за секунду (из истории)
                
        // Обрабатываем режим заполнения (меньше 100 транзакций)
        if (stats.transactionCount < 100) {
            let newCount: Int = stats.transactionCount + 1;
            let newTotalInterval: Int = max(1,stats.totalTimeInterval + timeInterval);
            let newTotalDue: Int = stats.totalStorageDueCollected + currentStorageDue;
            
            let avgStorageDuePerSecond: Int = newTotalDue / newTotalInterval;
                        
            // Примерные затраты за прошедший период
            let estimatedSpent: Int = avgStorageDuePerSecond * timeInterval;
            
            // Обновляем резерв, учитывая средний расход
            let newReservedStorage: Int = max(0, stats.reservedStorage - estimatedSpent);
            
            return StorageStats{
                lastUpdateTime: currentTime,
                transactionCount: newCount,
                totalTimeInterval: newTotalInterval,
                totalStorageDueCollected: newTotalDue,
                reservedStorage: newReservedStorage,
                storageLimit: stats.storageLimit,
                lastTonsReserve: stats.lastTonsReserve,
                storageTonsDeficit: stats.storageTonsDeficit
            };
        }
        
        // Режим скользящего окна (имитация удаления самой старой транзакции и добавления новой)
        
        // Получаем текущие средние значения
        let avgInterval: Int = 0;
        let avgStorageDuePerTransaction: Int = 0;
        
        avgInterval = stats.totalTimeInterval / max(1, stats.transactionCount);
        avgStorageDuePerTransaction = stats.totalStorageDueCollected / max(1, stats.transactionCount);
        
        // Вычитаем примерное значение для самой старой транзакции (основано на средних)
        // и добавляем значение новой транзакции

        let newTotalInterval: Int = stats.totalTimeInterval - avgInterval + timeInterval;
        let newTotalDue: Int = stats.totalStorageDueCollected - avgStorageDuePerTransaction + currentStorageDue;
        
        let avgStorageDuePerSecond: Int = newTotalDue / newTotalInterval;
        
        // Примерные затраты за прошедший период
        let estimatedSpent: Int = avgStorageDuePerSecond * timeInterval;
        
        // Обновляем резерв, учитывая средний расход
        let newReservedStorage: Int = max(0, stats.reservedStorage - estimatedSpent);
        
        return StorageStats{
            lastUpdateTime: currentTime,
            transactionCount: 100, // Сохраняем постоянный размер окна
            totalTimeInterval: newTotalInterval,
            totalStorageDueCollected: newTotalDue,
            reservedStorage: newReservedStorage,
            storageLimit: stats.storageLimit,
            lastTonsReserve: stats.lastTonsReserve,
            storageTonsDeficit: stats.storageTonsDeficit
        };
    }
    
    /**
     * Адаптивный расчет стоимости хранения на основе статистики использования
     * @param stats - статистика использования
     * @returns стоимость хранения в наноТонах на период STORAGE_PERIOD
     */
    virtual fun calculateAdaptiveStorageFee(stats: StorageStats): Int {
        let myStorageDue: Int = max(1,myStorageDue());

        // Если статистика ещё недостаточна (менее 1 транзакции)

        if (stats.transactionCount < 1) {
            // Используем стандартный расчёт
            //return (myStorageDue()+MIN_TON_FOR_STORAGE)*100;
            return myStorageDue*STORAGE_PERIOD;
        }
        
        // Рассчитываем среднее время между транзакциями (в секундах)
        let avgIntervalSeconds: Int = 1;

        if (stats.transactionCount > 0) {
            avgIntervalSeconds = max(1,stats.totalTimeInterval / stats.transactionCount);
        }
        
        // Среднее списание за хранение на одну транзакцию
        let avgStorageDuePerTransaction: Int = 0;
        if (stats.transactionCount > 0) {
            avgStorageDuePerTransaction = max(1,stats.totalStorageDueCollected / stats.transactionCount);
        }
                
        // Рассчитываем, сколько транзакций надо на указанный период
        let expectedTransactions: Int = max(1, STORAGE_PERIOD / avgIntervalSeconds);
        
        // Общая стоимость хранения за указанный период c 20% запасом
        let totalStorageCost: Int = max(avgStorageDuePerTransaction, myStorageDue) * expectedTransactions * 120 / 100;

        // Гарантируем минимальную сумму для хранения
        return totalStorageCost;
    }
    
    virtual fun getComputeGas(): Int {
        return getComputeFee(gasConsumed()*3, false);
    }
        
    /**
     * Расчет стоимости хранения данных контракта 
     * @returns стоимость хранения в наноТонах на период STORAGE_PERIOD
     */
        
}
