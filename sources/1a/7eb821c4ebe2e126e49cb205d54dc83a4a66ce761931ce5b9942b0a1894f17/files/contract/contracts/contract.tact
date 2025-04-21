import "@stdlib/ownable";
import "./messages";
import "./wallet";

struct UnlockDetail {
    unlockTime: Int;
    unlockAmount: Int;
    unlockType: String;
}

contract Iceberg with Jetton {
    total_supply: Int as coins;  
    max_supply: Int as coins;
    mintable: Bool;
    owner: Address;
    content: Cell;
    decimals: Int;
    
    tgeStartTime: Int;
    team_vesting: VestingSchedule;
    round_a_vesting: VestingSchedule;
    project_dev_vesting: VestingSchedule;
    advisors_vesting: VestingSchedule;
    kol_vesting: VestingSchedule;
    marketing_vesting: VestingSchedule;
    market_makers_vesting: VestingSchedule;
    
    init(owner: Address, content: Cell) {
        self.total_supply = 0;
        self.max_supply = 100_000_000_000_000_000_000;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.tgeStartTime = 0;
        self.decimals = 9;

        self.team_vesting = VestingSchedule{
            amount: 10_000_000_000,
            cliffMonths: 6,
            totalMonths: 25,
            claimed: 0,
            address: address("UQBmKK-HOinKu8EqSayu0FWg-ntYqdz8iv3jNXAEE34kn1Pl"),
            tgeUnlock: 0
        };

        self.round_a_vesting = VestingSchedule{
            amount: 15_000_000_000,
            cliffMonths: 0,
            totalMonths: 12,
            claimed: 0,
            address: address("UQAOozWya4IF8G77n8SSpQMkiRg2H-X5Fgue6qJ4ULaqYFps"),
            tgeUnlock: 3_000_000_000
        };

        self.project_dev_vesting = VestingSchedule{
            amount: 8_000_000_000,
            cliffMonths: 0,
            totalMonths: 19,
            claimed: 0,
            address: address("UQDzKpSXGxA0ryme_T5Er29KJgqZ3Y_JKhwD6YBYf04g8_1o"),
            tgeUnlock: 400_000_000
        };

        self.marketing_vesting = VestingSchedule{
            amount: 3_000_000_000,
            cliffMonths: 0,
            totalMonths: 0,
            claimed: 0,
            address: address("UQBtJggZ20hO_7ugjtbBeU2NEUKZdAT0Hx20qcC7Bq6NTYOU"),
            tgeUnlock: 3_000_000_000
        };

        self.advisors_vesting = VestingSchedule{
            amount: 5_000_000_000,
            cliffMonths: 6,
            totalMonths: 12,
            claimed: 0,
            address: address("UQDfjwtuPDbyPsa7T1oJWsGyEVW_NMCn7iJPVxG0fHFzy_ul"),
            tgeUnlock: 500_000_000
        };

        self.market_makers_vesting = VestingSchedule{
            amount: 5_000_000_000,
            cliffMonths: 0,
            totalMonths: 0,
            claimed: 0,
            address: address("UQCVEDcmYtTRt8u1fXuqE1U9zsg2PRGa3sArgK5CVKNyQLQS"),
            tgeUnlock: 5_000_000_000
        };

        self.kol_vesting = VestingSchedule{
            amount: 4_000_000_000,
            cliffMonths: 0,
            totalMonths: 6,
            claimed: 0,
            address: address("UQCQCK61eFpJH6armvR0sLTksoRoEL4NIDcln_EOQtr7DsXi"),
            tgeUnlock: 800_000_000
        };
    }

    receive(msg: Mint) { 
        require(self.mintable, "Minting is closed");
        require(sender() == self.owner, "Not owner");
        self.mint(msg.receiver, msg.amount, self.owner); 
        self.mintable = false;
    }

    receive(msg: SetTGEStartTime) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.tgeStartTime == 0, "TGE time already set");
        
        self.tgeStartTime = msg.time;
    }
    
    /**
     * Рассчитывает количество токенов, доступных для получения в данный момент
     */
    fun calculateClaimableAmount(schedule: VestingSchedule, currentTime: Int): Int {
        // Проверяем, был ли установлен TGE
        if (self.tgeStartTime == 0) {
            return 0;
        }
        
        // Проверяем, наступило ли время TGE
        if (currentTime < self.tgeStartTime) {
            return 0;
        }

        // Вычисляем, сколько "месяцев" (10 минут) прошло с начала TGE
        let monthInSeconds: Int = 10 * 60; // 10 минут вместо месяца для тестирования
        let monthsSinceStart: Int = (currentTime - self.tgeStartTime) / monthInSeconds;
        
        // Если нет ежемесячных разблокировок, возвращаем всю сумму минус уже полученное
        if (schedule.totalMonths == 0) {
            return schedule.amount - schedule.claimed;
        }

        // Инициализируем доступную сумму
        let availableAmount: Int = 0;
        
        // Если это первый клейм, добавляем TGE разблокировку
        if (schedule.claimed == 0) {
            availableAmount = schedule.tgeUnlock;
        }

        // Если cliff период еще не закончился, возвращаем только TGE разблокировку
        if (monthsSinceStart < schedule.cliffMonths) {
            return availableAmount;
        }

        // Вычисляем, сколько "месяцев" прошло после cliff периода
        let monthsAfterCliff: Int = monthsSinceStart - schedule.cliffMonths;
        
        // Вычисляем оставшуюся сумму для ежемесячных разблокировок
        let remainingAmount: Int = schedule.amount - schedule.tgeUnlock;
        // Вычисляем сумму ежемесячной разблокировки
        let monthlyAmount: Int = remainingAmount / schedule.totalMonths;
        
        // Вычисляем общую доступную сумму: TGE + (месячная сумма * прошедшие месяцы)
        let totalAvailable: Int = schedule.tgeUnlock + (monthlyAmount * monthsAfterCliff);
        
        // Ограничиваем доступную сумму общей суммой вестинга
        availableAmount = min(totalAvailable, schedule.amount);
        
        // Возвращаем доступную сумму минус уже полученное
        return availableAmount - schedule.claimed;
    }
    
    /**
     * Получает информацию о разблокировках для конкретной группы
     */
    get fun getVestingInfo(name: String, schedule: VestingSchedule, currentTime: Int): UnlockInfo {
        // 10 минут вместо месяца для тестирования
        let monthInSeconds: Int = 10 * 60;
        // Вычисляем время окончания cliff периода
        let cliffEnd: Int = self.tgeStartTime + (schedule.cliffMonths * monthInSeconds);
        // Вычисляем время окончания всех разблокировок
        let unlockEnd: Int = cliffEnd + (schedule.totalMonths * monthInSeconds);
        
        // Инициализируем сумму ежемесячной разблокировки
        let monthlyAmount: Int = 0;
        if (schedule.totalMonths > 0) {
            // Вычисляем оставшуюся сумму после TGE разблокировки
            let remainingAmount: Int = schedule.amount - schedule.tgeUnlock;
            // Вычисляем сумму ежемесячной разблокировки
            monthlyAmount = remainingAmount / schedule.totalMonths;
        }
        
        // Инициализируем время следующей разблокировки
        let nextUnlock: Int = 0;
        if (currentTime < cliffEnd) {
            // Если cliff период не закончился, следующая разблокировка будет при его окончании
            nextUnlock = cliffEnd;
        } else if (schedule.totalMonths > 0) {
            // Вычисляем, сколько "месяцев" прошло после cliff периода
            let monthsSinceCliff: Int = (currentTime - cliffEnd) / monthInSeconds;
            // Вычисляем время следующей разблокировки
            nextUnlock = cliffEnd + ((monthsSinceCliff + 1) * monthInSeconds);
            // Если следующая разблокировка после окончания вестинга, устанавливаем 0
            if (nextUnlock > unlockEnd) {
                nextUnlock = 0;
            }
        }

        // Возвращаем структуру с полной информацией о вестинге
        return UnlockInfo{
            name: name,                  // Название группы
            totalAmount: schedule.amount, // Общая сумма токенов
            claimedAmount: schedule.claimed, // Уже полученная сумма
            cliffEnds: cliffEnd,         // Время окончания cliff периода
            nextUnlock: nextUnlock,      // Время следующей разблокировки
            monthlyUnlock: monthlyAmount, // Сумма ежемесячной разблокировки
            unlockEnds: unlockEnd,       // Время окончания всех разблокировок
            unlockedAmount: self.calculateClaimableAmount(schedule, currentTime), // Доступная сумма
            tgeUnlock: schedule.tgeUnlock // Сумма TGE разблокировки
        };
    }

    get fun getUnlockSchedule(msg: GetUnlockInfo): UnlockSchedule {
        return UnlockSchedule{
            team: self.getVestingInfo("Team", self.team_vesting, msg.time),
            roundA: self.getVestingInfo("Round A", self.round_a_vesting, msg.time),
            projectDev: self.getVestingInfo("Project Dev", self.project_dev_vesting, msg.time),
            marketing: self.getVestingInfo("Marketing", self.marketing_vesting, msg.time),
            advisors: self.getVestingInfo("Advisors", self.advisors_vesting, msg.time),
            marketMakers: self.getVestingInfo("Market Makers", self.market_makers_vesting, msg.time),
            kol: self.getVestingInfo("KOL", self.kol_vesting, msg.time)
        };
    }

    get fun getTgeStartTime(): Int {
        return self.tgeStartTime;
    }

    receive("Claim: Team") {
        require(sender() == self.owner, "Not owner");
        let amount: Int = self.calculateClaimableAmount(self.team_vesting, now());
        require(amount > 0, "No tokens to claim");
        self.team_vesting.claimed = self.team_vesting.claimed + amount;
        self.mint(self.team_vesting.address, self.scaleAmount(amount), self.owner);
    }

    receive("Claim: RoundA") {
        require(sender() == self.owner, "Not owner");
        let amount: Int = self.calculateClaimableAmount(self.round_a_vesting, now());
        require(amount > 0, "No tokens to claim");
        self.round_a_vesting.claimed = self.round_a_vesting.claimed + amount;
        self.mint(self.round_a_vesting.address, self.scaleAmount(amount), self.owner);
    }

    receive("Claim: ProjectDev") {
        require(sender() == self.owner, "Not owner");
        let amount: Int = self.calculateClaimableAmount(self.project_dev_vesting, now());
        require(amount > 0, "No tokens to claim");
        self.project_dev_vesting.claimed = self.project_dev_vesting.claimed + amount;
        self.mint(self.project_dev_vesting.address, self.scaleAmount(amount), self.owner);
    }

    receive("Claim: Marketing") {
        require(sender() == self.owner, "Not owner");
        let amount: Int = self.calculateClaimableAmount(self.marketing_vesting, now());
        require(amount > 0, "No tokens to claim");
        self.marketing_vesting.claimed = self.marketing_vesting.claimed + amount;
        self.mint(self.marketing_vesting.address, self.scaleAmount(amount), self.owner);
    }

    receive("Claim: Advisors") {
        require(sender() == self.owner, "Not owner");
        let amount: Int = self.calculateClaimableAmount(self.advisors_vesting, now());
        require(amount > 0, "No tokens to claim");
        self.advisors_vesting.claimed = self.advisors_vesting.claimed + amount;
        self.mint(self.advisors_vesting.address, self.scaleAmount(amount), self.owner);
    }

    receive("Claim: MarketMakers") {
        require(sender() == self.owner, "Not owner");
        let amount: Int = self.calculateClaimableAmount(self.market_makers_vesting, now());
        require(amount > 0, "No tokens to claim");
        self.market_makers_vesting.claimed = self.market_makers_vesting.claimed + amount;
        self.mint(self.market_makers_vesting.address, self.scaleAmount(amount), self.owner);
    }

    receive("Claim: KOL") {
        require(sender() == self.owner, "Not owner");
        let amount: Int = self.calculateClaimableAmount(self.kol_vesting, now());
        require(amount > 0, "No tokens to claim");
        self.kol_vesting.claimed = self.kol_vesting.claimed + amount;
        self.mint(self.kol_vesting.address, self.scaleAmount(amount), self.owner);
    }

    receive("Owner: MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.mintable = false;
    }
    
    /**
     * Получает все даты разблокировок с суммами для указанной группы
     */
    get fun getUnlockDates(msg: GetUnlockDates): map<Int, UnlockDetail> {
        // 10 минут вместо месяца для тестирования
        let monthInSeconds: Int = 10 * 60;
        // Устанавливаем расписание по умолчанию
        let schedule: VestingSchedule = self.team_vesting;
        // Создаем пустую карту для хранения дат разблокировок
        let unlockDetails: map<Int, UnlockDetail> = emptyMap();

        // Определяем расписание вестинга в зависимости от категории
        if (msg.category == "Team") {
            schedule = self.team_vesting;
        } else if (msg.category == "RoundA") {
            schedule = self.round_a_vesting;
        } else if (msg.category == "ProjectDev") {
            schedule = self.project_dev_vesting;
        } else if (msg.category == "Marketing") {
            schedule = self.marketing_vesting;
        } else if (msg.category == "Advisors") {
            schedule = self.advisors_vesting;
        } else if (msg.category == "MarketMakers") {
            schedule = self.market_makers_vesting;
        } else if (msg.category == "KOL") {
            schedule = self.kol_vesting;
        }

        // Добавляем TGE разблокировку, если она есть
        if (schedule.tgeUnlock > 0) {
            unlockDetails.set(self.tgeStartTime, UnlockDetail{
                unlockTime: self.tgeStartTime,    // Время TGE
                unlockAmount: schedule.tgeUnlock, // Сумма TGE разблокировки
                unlockType: "TGE Unlock"          // Тип разблокировки
            });
        }

        // Если есть ежемесячные разблокировки
        if (schedule.totalMonths > 0) {
            // Вычисляем время окончания cliff периода
            let cliffEnd: Int = self.tgeStartTime + (schedule.cliffMonths * monthInSeconds);
            // Вычисляем оставшуюся сумму после TGE
            let remainingAmount: Int = schedule.amount - schedule.tgeUnlock;
            // Вычисляем сумму ежемесячной разблокировки
            let monthlyAmount: Int = remainingAmount / schedule.totalMonths;
            // Счетчик месяцев
            let currentMonth: Int = 0;

            // Добавляем все ежемесячные разблокировки
            while (currentMonth < schedule.totalMonths) {
                // Вычисляем время разблокировки для текущего месяца
                let unlockTime: Int = cliffEnd + (currentMonth * monthInSeconds);
                // Добавляем информацию о разблокировке в карту
                unlockDetails.set(unlockTime, UnlockDetail{
                    unlockTime: unlockTime,      // Время разблокировки
                    unlockAmount: monthlyAmount, // Сумма разблокировки
                    unlockType: "Monthly Unlock" // Тип разблокировки
                });
                // Увеличиваем счетчик месяцев
                currentMonth = currentMonth + 1;
            }
        } else if (schedule.tgeUnlock == 0) {
            // Если нет ни TGE, ни ежемесячных разблокировок,
            // добавляем полную разблокировку при TGE
            unlockDetails.set(self.tgeStartTime, UnlockDetail{
                unlockTime: self.tgeStartTime, // Время разблокировки
                unlockAmount: schedule.amount, // Полная сумма
                unlockType: "Full Unlock"      // Тип разблокировки
            });
        }

        // Возвращаем карту с датами и деталями разблокировок
        return unlockDetails;
    }

    get fun getDecimals(): Int {
        return self.decimals;
    }

    // Функция для конвертации суммы с учетом decimals
    fun scaleAmount(amount: Int): Int {
        return amount * pow(10, self.decimals);
    }
} 


@interface("org.ton.ownable.transferable.v2")
trait Jetton with OwnableTransferable  {

    total_supply: Int; 
    max_supply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;

    receive(msg: TokenBurnNotification) {
        self.requireSenderAsWalletOwner(msg.response_destination!!);       
        self.total_supply = self.total_supply - msg.amount; 
        if (msg.send_excess && msg.response_destination != null) { 
            send(SendParameters{
                to: msg.response_destination!!, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: TokenExcesses{ query_id: msg.query_id }.toCell()
            });
        }
    }

    receive(msg: ProvideWalletAddress) {
        require(context().value >= ton("0.0061"), "Insufficient gas");
        let init: StateInit = initOf JettonDefaultWallet(msg.owner_address, myAddress());
        if (msg.include_address) {
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: TakeWalletAddress{
                    query_id: msg.query_id,
                    wallet_address: contractAddress(init),
                    owner_address: beginCell().storeBool(true).storeAddress(msg.owner_address).endCell().asSlice()
                }.toCell()
            });
        } else {
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: TakeWalletAddress { 
                    query_id: msg.query_id,
                    wallet_address: contractAddress(init),
                    owner_address: beginCell().storeBool(false).endCell().asSlice()
                }.toCell()
            });
        }
    }

    fun mint(to: Address, amount: Int, response_destination: Address) {
        require(self.total_supply + amount <= self.max_supply, "Exceeds max supply");
        self.total_supply = self.total_supply + amount; 
        let winit: StateInit = self.getJettonWalletInit(to); 
        send(SendParameters{
            to: contractAddress(winit), 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                query_id: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: 0,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    fun requireSenderAsWalletOwner(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(address, myAddress());
    }

    get fun get_jetton_data(): JettonData {
        return JettonData{ 
            total_supply: self.total_supply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            wallet_code: initOf JettonDefaultWallet(self.owner, myAddress()).code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(initOf JettonDefaultWallet(owner, myAddress()));
    }
}