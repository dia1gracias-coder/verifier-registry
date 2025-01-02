import "@stdlib/deploy";

message EmitEvent {
    value: Int;
}

message MakeDeal {
    id: Int as uint128;
    producer: Address;
    producerResponsibility: Int as coins;
    expirationTime: Int as uint64;
    amount: Int as coins;
    fee: Int as coins;
}

message JudgeDeal {
    id: Int as uint128;
    isProducerFault: Bool;
}

message PayResponsibility {
    id: Int as uint128;
}

message ProducerGiveUpDeal {
    id: Int as uint128;
}

message ConsumerReturnMoneyDueToNotLockedResponsibility {
    id: Int as uint128;
}

message CompleteTheDeal {
    id: Int as uint128;
}

message SystemFailureWithdraw {
    id: Int as uint128;
}

message ChangeMinimalDealAmount {
    minimalDealAmount: Int as coins;
}

message ChangeFeePart {
    feePart: Int as uint8;
}

message ChangeSystemFailureFreezeTime {
    systemFailureFreezeTime: Int as uint64;
}

message ChangeMinimalContractBalance {
    minimalContractBalance: Int as coins;
}

struct Deal {
    id: Int as uint128;
    consumer: Address;
    producer: Address;
    amount: Int as coins;
    producerResponsibility: Int as coins;
    expirationTime: Int as uint64;
    producerPayed: Bool;
}

contract SolomonDeal with Deployable {

    const version: String = "0.2 alpha";

    judgeSystem: Address;
    minimalDealAmount: Int as coins = ton("0.1");
    feePart: Int as uint8 = 50;
    feeFound: Int as coins = 0;
    systemFailureFreezeTime: Int as uint64 = 3600*24*10;
    minimalContractBalance: Int as coins = ton("0.1");
    minimalAdditionAmountForFee: Int as coins = ton("0.1");
    totalClientMoney: Int as coins = 0;

    test_var: Int as uint128 = 0;

    currentDeals: map<Int, Deal>;

    init() {
        require(context().value >= self.minimalContractBalance, "Minimal contract balance required");
        self.judgeSystem = sender();
        nativeReserve(ton("0.1"), 4);
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    receive(msg: MakeDeal) {
        require(context().value >= self.minimalDealAmount, "Minimal deal amount required");
        require(context().value >= msg.amount + msg.fee + self.minimalAdditionAmountForFee, "Minimal value required");
        require(msg.amount > 0, "Amount should be positive");
        require(msg.producerResponsibility >= 0, "Producer responsibility should be positive");
        require(msg.fee == (msg.amount / self.feePart), "Fee should be equal");
        self.feeFound += msg.fee;
        self.currentDeals.set(
            msg.id,
            Deal{
                id: msg.id,
                consumer: sender(),
                producer: msg.producer,
                amount: msg.amount,
                producerResponsibility: msg.producerResponsibility,
                expirationTime: msg.expirationTime,
                producerPayed: false
            }
        );
        self.totalClientMoney += msg.amount;
        nativeReserve(msg.amount + msg.fee, 4);
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    receive(msg: CompleteTheDeal) {
        let deal : Deal = (self.currentDeals.get(msg.id))!!;
        require(sender() == self.judgeSystem || sender() == deal.consumer, "Only judge system or consumer can complete deal");
        if (deal.producerPayed == true) {
            self.currentDeals.set(msg.id, null);
            self.totalClientMoney -= deal.amount;
            self.totalClientMoney -= deal.producerResponsibility;
            send(SendParameters{
                to: deal.producer,
                bounce: true,
                value: deal.amount + deal.producerResponsibility,
                mode: SendIgnoreErrors
            });
        } else {
            self.currentDeals.set(msg.id, null);
            self.totalClientMoney -= deal.amount;
            send(SendParameters{
                to: deal.producer,
                bounce: true,
                value: deal.amount,
                mode: SendIgnoreErrors
            });
        }
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: PayResponsibility) {
        let deal : Deal = self.currentDeals.get(msg.id)!!;
        require(sender() == deal.producer, "Only producer can pay responsibility");
        require(deal.producerPayed == false, "Producer already payed");
        require(context().value >= deal.producerResponsibility, "Producer responsibility should be equal to value");
        deal.producerPayed = true;
        nativeReserve(deal.producerResponsibility, 4);
        self.totalClientMoney += deal.producerResponsibility;
        self.currentDeals.set(msg.id, deal);
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }
    
    receive(msg: ProducerGiveUpDeal) {
        let deal : Deal = (self.currentDeals.get(msg.id))!!;
        require(sender() == deal.producer, "Only producer can give up deal");
        self.currentDeals.set(msg.id, null);
        if (deal.producerPayed == false) {
            self.totalClientMoney -= deal.amount;
            send(SendParameters{
                to: deal.consumer,
                bounce: true,
                value: deal.amount,
                mode: SendIgnoreErrors
            });
        } else {
            self.totalClientMoney -= deal.amount;
            self.totalClientMoney -= deal.producerResponsibility;
            send(SendParameters{
                to: deal.consumer,
                bounce: true,
                value: deal.amount + deal.producerResponsibility,
                mode: SendIgnoreErrors
            });
        }
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: ConsumerReturnMoneyDueToNotLockedResponsibility) {
        let deal : Deal = (self.currentDeals.get(msg.id))!!;
        require(sender() == deal.consumer, "Only consumer can return money due to not locked responsibility");
        require(deal.producerPayed == false && deal.producerResponsibility > 0, "Producer already payed");
        self.currentDeals.set(msg.id, null);
        self.totalClientMoney -= deal.amount;
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: deal.amount,
            mode: SendIgnoreErrors
        });

        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: JudgeDeal) {
        let deal : Deal = (self.currentDeals.get(msg.id))!!;
        require(sender() == self.judgeSystem, "Only judge system can judge deal");
        require(deal.expirationTime < now(), "Deal is not expired yet");
        self.currentDeals.set(msg.id, null);
        if (msg.isProducerFault) {
            if (deal.producerPayed == true) {
                self.totalClientMoney -= deal.producerResponsibility;
                self.totalClientMoney -= deal.amount;
                send(SendParameters{
                    to: deal.consumer,
                    bounce: true,
                    value: deal.amount + deal.producerResponsibility,
                    mode: SendIgnoreErrors
                });
            } else {
                self.totalClientMoney -= deal.amount;
                send(SendParameters{
                    to: deal.consumer,
                    bounce: true,
                    value: deal.amount,
                    mode: SendIgnoreErrors
                });
            }
        } else {
            if (deal.producerPayed == true) {
                self.totalClientMoney -= deal.producerResponsibility;
                self.totalClientMoney -= deal.amount;
                send(SendParameters{
                    to: deal.producer,
                    bounce: true,
                    value: deal.amount + deal.producerResponsibility,
                    mode: SendIgnoreErrors
                });
            } else {
                self.totalClientMoney -= deal.amount;
                send(SendParameters{
                    to: deal.producer,
                    bounce: true,
                    value: deal.amount,
                    mode: SendIgnoreErrors
                });
            }
        }
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: SystemFailureWithdraw) {
        let deal : Deal = (self.currentDeals.get(msg.id))!!;
        require(sender() == deal.consumer, "Only consumer can withdraw in case of system failure");
        require(deal.expirationTime + self.systemFailureFreezeTime < now(), "Deal is not expired yet or freeze time is not passed");
        self.currentDeals.set(msg.id, null);
        if (deal.producerPayed == true) {
            send(SendParameters{
                to: deal.producer,
                bounce: true,
                value: deal.producerResponsibility,
                mode: SendIgnoreErrors
            });
        } else {
            send(SendParameters{
                to: deal.consumer,
                bounce: true,
                value: deal.amount - context().value,
                mode: SendIgnoreErrors + SendRemainingValue
            });
        }
        self.totalClientMoney -= deal.amount;
        self.totalClientMoney -= deal.producerResponsibility;
    }

    receive("withdraw safe") {
        require(sender() == self.judgeSystem, "Only judge system can withdraw");
        let amountToWithdraw: Int = myBalance() - self.totalClientMoney - self.minimalContractBalance;
        emit(EmitEvent{value: amountToWithdraw}.toCell());
        require(amountToWithdraw > self.minimalContractBalance, "Not enough money to withdraw");
        send(SendParameters{
            to: self.judgeSystem,
            bounce: true,
            value: amountToWithdraw,
            mode: SendIgnoreErrors
        });

        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: ChangeMinimalDealAmount) {
        require(sender() == self.judgeSystem, "Only judge system can change minimal deal amount");
        self.minimalDealAmount = msg.minimalDealAmount;
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: ChangeFeePart) {
        require(sender() == self.judgeSystem, "Only judge system can change fee part");
        self.feePart = msg.feePart;
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: ChangeSystemFailureFreezeTime) {
        require(sender() == self.judgeSystem, "Only judge system can change system failure freeze time");
        self.systemFailureFreezeTime = msg.systemFailureFreezeTime;
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: ChangeMinimalContractBalance) {
        require(sender() == self.judgeSystem, "Only judge system can change minimal found balance");
        self.minimalContractBalance = msg.minimalContractBalance;
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun allDeals(): map<Int, Deal> {
        return self.currentDeals;
    }

    get fun feeFound(): Int {
        return self.feeFound;
    }

    get fun minimalDealAmount(): Int {
        return self.minimalDealAmount;
    }

    get fun feePart(): Int {
        return self.feePart;
    }

    get fun systemFailureFreezeTime(): Int {
        return self.systemFailureFreezeTime;
    }

    get fun minimalContractBalance(): Int {
        return self.minimalContractBalance;
    }

    get fun totalClientMoney(): Int {
        return self.totalClientMoney;
    }


}
