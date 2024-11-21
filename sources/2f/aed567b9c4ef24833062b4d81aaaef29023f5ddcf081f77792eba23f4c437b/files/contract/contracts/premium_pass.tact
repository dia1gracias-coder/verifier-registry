import "@stdlib/deploy";
import "@stdlib/ownable";
message SetPassPrice {
    newPrice: Int as uint128;
}
message SetCheckInPrice {
    newCheckInPrice: Int as uint128;
}
message SetVipMaxCheckIns {
    newLimit: Int;
}
message PurchasePass {
    chatId: Int;
}
message CheckIn {
    chatId: Int;
}
message WithdrawAll {
}
message WithdrawSafe {
}
struct PassInfo {
    hasPass: Bool;
    joinDate: Int;
    lastCheckInDate: Int;
    lastCheckInTimestamp: Int;
    checkInCountToday: Int;
}

contract PremiumPass with Deployable, Ownable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years
    owner: Address;
    passPrice: Int as uint128;
    checkInPrice: Int as uint128;
    vipMaxCheckIns: Int = 2; // Default value for VIP max check-ins
    passHolders: map<Int, PassInfo>;
    init(initialOwner: Address, initialPassPrice: Int, initialCheckInPrice: Int){
        require(initialPassPrice > 0, "Initial price must be greater than 0");
        self.owner = initialOwner;
        self.passPrice = initialPassPrice;
        self.checkInPrice = initialCheckInPrice;
    }

    // Only the owner can set the vip pass price
    receive(msg: SetPassPrice){
        dump(msg.newPrice);
        self.requireOwner();
        require(msg.newPrice > 0, "Price must be greater than 0");
        self.passPrice = msg.newPrice;
        self.notify("Set new price successfully".asComment());
    }

    // Only the owner can set the check-in price
    receive(msg: SetCheckInPrice) {
        self.requireOwner();
        require(msg.newCheckInPrice > 0, "Check-in price must be greater than 0");
        self.checkInPrice = msg.newCheckInPrice;
        self.notify("Set new check-in price successfully".asComment());
    }

    // Only the owner can set the maximum VIP check-in limit
    receive(msg: SetVipMaxCheckIns){
        self.requireOwner();
        require(msg.newLimit > 0, "VIP check-in limit must be greater than 0");
        self.vipMaxCheckIns = msg.newLimit;
        self.notify("Set new check-in max count successfully".asComment());
    }

    receive(msg: PurchasePass){
        let ctx: Context = context();
        let chatId = msg.chatId; 

        require(!self.passHolders.exists(chatId) || !self.passHolders.get(chatId)!!.hasPass,
            "User already owns a pass"
        );
        require(ctx.value >= self.passPrice, "Insufficient funds to purchase pass");
        
        if (self.passHolders.exists(chatId)) {
            let passInfo = self.passHolders.get(chatId)!!;
            
            self.passHolders.set(chatId,
            PassInfo{
                hasPass: true,
                joinDate: now(),
                lastCheckInDate: passInfo.lastCheckInDate,
                lastCheckInTimestamp: passInfo.lastCheckInTimestamp,
                checkInCountToday: passInfo.checkInCountToday
            });
        } else {
            self.passHolders.set(chatId,
            PassInfo{
                hasPass: true,
                joinDate: now(),
                lastCheckInDate: 0,
                lastCheckInTimestamp: 0,
                checkInCountToday: 0
            });
        }
    }

    receive(msg: CheckIn){
        let ctx: Context = context();
        let chatId = msg.chatId; 

        require(ctx.value >= self.checkInPrice, "Insufficient funds to check in");

        // Convert the current timestamp to day-based format
        let today = now() / 86400; 

        if (self.passHolders.exists(chatId)) {
            let passInfo = self.passHolders.get(chatId)!!;

            if (passInfo.lastCheckInDate != today) {
                passInfo.checkInCountToday = 0;
            }

            // Check if SuperPass users can check in up to twice per day
            if (passInfo.hasPass) {
                require(passInfo.checkInCountToday < self.vipMaxCheckIns, "SuperPass users can only check in twice per day");
            } else {
                require(passInfo.checkInCountToday < 1, "Regular users can only check in once per day");
            } 

            passInfo.lastCheckInDate = today;
            passInfo.lastCheckInTimestamp = now();
            passInfo.checkInCountToday += 1;
            self.passHolders.set(chatId, passInfo);
        } else {
            self.passHolders.set(chatId,
            PassInfo{
                hasPass: false,
                joinDate: 0,
                lastCheckInDate: today,
                lastCheckInTimestamp: now(),
                checkInCountToday: 1
            });
        }
    }

    receive(msg: WithdrawAll){
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        send(SendParameters{to: sender(), bounce: true, value: 0, mode: SendRemainingBalance + SendIgnoreErrors});
    }

    // this will withdraw the entire balance but leave 0.01 for storage rent costs
    receive(msg: WithdrawSafe){
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        send(SendParameters{
                to: sender(),
                bounce: true,
                value: (myBalance() - context().value) - self.MinTonForStorage,
                mode: SendRemainingValue + SendIgnoreErrors
            }
        );
    }

    get fun passPrice(): Int {
        return self.passPrice;
    }

    get fun checkInPrice(): Int {
        return self.checkInPrice;
    }

    get fun vipMaxCheckIns(): Int {
        return self.vipMaxCheckIns;
    }

    get fun passInfo(chatId: Int): PassInfo {
        if (self.passHolders.exists(chatId)) {
            let info: PassInfo = self.passHolders.get(chatId)!!;
            return info;
        } else {
            let info = PassInfo{hasPass: false, joinDate: 0,lastCheckInDate: 0, lastCheckInTimestamp: 0, checkInCountToday: 0};
            return info;
        }
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }
}