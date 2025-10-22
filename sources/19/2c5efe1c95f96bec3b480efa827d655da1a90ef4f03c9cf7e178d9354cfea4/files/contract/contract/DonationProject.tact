// DonationProject.tact
import "@stdlib/deploy";
import "@stdlib/ownable";

// Сообщения
message Donate {
    amount: Int as coins;
}

message Withdraw {}
message RefundAll {}

// Информация о доноре
struct DonorInfo {
    address: Address;
    amount: Int as coins;
}

// Основной контракт проекта
contract DonationProject with Deployable, Ownable {
    owner: Address;
    goalAmount: Int as coins;
    totalDonated: Int as coins = 0;
    deadline: Int as uint32;
    isFinished: Bool = false;

    // Доноры: address => amount
    donors: map<Address, Int>;

    init(owner: Address, goalAmount: Int, deadline: Int, projectId: Int) {
        self.owner = owner;
        self.goalAmount = goalAmount;
        self.deadline = deadline;
    }


    // Получение доната через сообщение
    receive(msg: Donate) {
        let ctx: Context = context();
        require(now() <= self.deadline, "Deadline has passed");
        require(!self.isFinished, "Project finished");
        require(msg.amount > 0, "Amount must be positive");

        let currentAmount: Int = self.donors.get(ctx.sender)!!;
        self.donors.set(ctx.sender, currentAmount + msg.amount);

        self.totalDonated = self.totalDonated + msg.amount;
    }

    // Получение доната через обычный перевод TON
    receive() {
        let ctx: Context = context();
        require(now() <= self.deadline, "Deadline passed");
        require(!self.isFinished, "Project finished");
        require(ctx.value > 0, "Amount must be positive");

        let currentAmount: Int = self.donors.get(ctx.sender)!!;
        self.donors.set(ctx.sender, currentAmount + ctx.value);

        self.totalDonated = self.totalDonated + ctx.value;
    }

    // Вывод средств владельцем
    receive(msg: Withdraw) {
        self.requireOwner();
        require(now() > self.deadline, "Deadline not reached");
        require(self.totalDonated >= self.goalAmount, "Goal not reached");
        require(!self.isFinished, "Already withdrawn");

        self.isFinished = true;

        send(SendParameters{
            to: self.owner,
            value: self.totalDonated,
            mode: SendRemainingBalance
        });
    }

    // Возврат средств всем донорам
    receive(msg: RefundAll) {
        require(now() > self.deadline, "Deadline not reached");
        require(self.totalDonated < self.goalAmount, "Goal was reached");
        require(!self.isFinished, "Already finished");

        self.isFinished = true;
    }

    // Getters
    get fun totalDonated(): Int { return self.totalDonated; }
    get fun goalAmount(): Int { return self.goalAmount; }
    get fun deadline(): Int { return self.deadline; }
    get fun isFinished(): Bool { return self.isFinished; }
    get fun projectOwner(): Address { return self.owner; }
    get fun donorAmount(donor: Address): Int { return self.donors.get(donor)!!; }
    get fun progress(): Int { 
        if (self.goalAmount == 0) { return 0; }
        return (self.totalDonated * 100) / self.goalAmount;
    }
    get fun timeLeft(): Int { 
        if (now() >= self.deadline) { return 0; }
        return self.deadline - now();
    }
    get fun status(): String {
        if (self.isFinished) { return "Finished"; }
        if (now() > self.deadline) {
            if (self.totalDonated >= self.goalAmount) { return "Successful - Ready to withdraw"; }
            return "Failed - Refund available";
        }
        return "Active";
    }
}
