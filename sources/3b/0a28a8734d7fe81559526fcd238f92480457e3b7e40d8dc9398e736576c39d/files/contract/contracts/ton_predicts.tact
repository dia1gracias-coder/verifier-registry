import "./Event.tact";
import "./EventFactory.tact";

// Since v1.6.0, Tact has a contract parameters syntax that can supersede
// lazy initialization by init() for all contracts that do not require specific on-chain
// deployment logic that must be run only once in the `init()` function.
//
// Note that the empty parameter list above is still a parameter list,
// meaning that the contract won't have an implicit or explicit `init(){:tact}` function
// and will enjoy storage write optimizations and use less gas overall.
//
// See: https://docs.tact-lang.org/book/contracts/#parameters

// Основной контракт TonPredicts - система прогнозирования событий
// 
// Архитектура:
// 1. EventFactory - создаёт новые события
// 2. Event - контракт отдельного события со ставками
//
// Использование:
// 1. Деплоим EventFactory с адресом админа
// 2. Админ создаёт события через EventFactory
// 3. Пользователи делают ставки в контрактах Event
// 4. Админ завершает события указывая результат
// 5. Победители получают выплаты

// Главный контракт системы (опционально)
contract TonPredicts {
    owner: Address;
    factory: Address?;
    
    init(owner: Address) {
        self.owner = owner;
    }
    
    // Деплой фабрики событий
    receive("deploy_factory") {
        require(sender() == self.owner, "Only owner");
        require(self.factory == null, "Factory already deployed");
        
        let factoryInit: StateInit = initOf EventFactory(self.owner);
        let factoryAddress: Address = contractAddress(factoryInit);
        
        send(SendParameters{
            to: factoryAddress,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            code: factoryInit.code,
            data: factoryInit.data
        });
        
        self.factory = factoryAddress;
    }
    
    get fun get_factory(): Address? {
        return self.factory;
    }
    
    get fun get_owner(): Address {
        return self.owner;
    }
}
