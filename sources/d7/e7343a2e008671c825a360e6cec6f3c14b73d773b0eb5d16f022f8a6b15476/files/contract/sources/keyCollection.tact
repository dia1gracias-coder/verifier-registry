import "@stdlib/deploy";

// todo
// 权限问题

message PurchaseOnekey {
    keyNum: Int as uint8;  // keyItem的序号
}

message Redeem {
    keyId: Int as uint128;
}

struct KeyInfo {
    owner: Address;
    keyNum: Int as uint8;
    // subKeyId: Int as uint256;
    price: Int as uint256;
}

struct UserInfo {
    walletAmount: Int as uint128 = 0;
}


contract KeyCollection with Deployable {

    // keyPrice: Int as uint128 = 0;
    keySupply: Int as uint128 = 0; // 所有key的发行量
    keyShares: Int as uint128 = 0; // 所有key的在持份额
    subKeySharesMap: map<Int, Int>;    // 每个格子key的份额数量
    owner: Address;
    vLuckShares: Int as uint256 = 0;    // 总投入ton值
    vLuckMap: map<Int, Int>;           // 记录每个格子(一共8个格子)的vluck值
    // 计算每一份vlcok的奖励
    rewardPreVluck: Int as uint256 = 0;
    uservLuckMap: map<Address, Int>;      // 记录用户的vlock值
    userAwardMap: map<Address, Int>;     // 用户奖励
    keyInfoMap: map<Int, KeyInfo>;  // 记录每个key的具体信息
    // keysOwnerMap: map<Int, Address>; // 记录每个key的拥有者
    luckNum: Int as uint8 = 0;

    userWalletMap: map<Address, Int>;

    init(owner: Address) {
		self.owner = owner;
        let i: Int = 0;
        repeat (8) {
            i = i + 1;
            self.subKeySharesMap.set(i, 0);
            self.vLuckMap.set(i, 0);
        }
    }

    fun calcPrice(shares: Int): Int {
        let tmp: Int = shares * shares;
        tmp = tmp * 1000000;
        return tmp;
    }

    fun getVLuckByAddr(user: Address): Int {
        let vLuck: Int = 0;

        if (self.uservLuckMap.get(user) != null) {
            vLuck = self.uservLuckMap.get(user)!!;
        }
        return vLuck;
    }

    fun updateSubKeySharesMap(keyNum: Int, count: Int) {     // +1 or -1
        let subKeyNum: Int = self.subKeySharesMap.get(keyNum)!!;
        subKeyNum = subKeyNum + count;
        self.subKeySharesMap.set(keyNum, subKeyNum);   // 设置对应key的发行量
    }

    fun updateVLuckMap(keyNum: Int, vlock: Int) {
        let totalVlock: Int = self.vLuckMap.get(keyNum)!!;
        totalVlock = totalVlock + vlock;
        self.vLuckMap.set(keyNum, totalVlock);
    }

    fun updateUserVLuckMap(user: Address, vlock: Int) {
        if (self.uservLuckMap.get(user) != null) {
            let userVlock: Int = self.uservLuckMap.get(user)!!;
            userVlock = userVlock + vlock;
            self.uservLuckMap.set(user, userVlock);
        }
    }

    fun updateUserAwardMap(user: Address, reward: Int) {
        let totalReward: Int = reward;
        if (self.userAwardMap.get(user) != null) {
            let haveReward: Int = self.userAwardMap.get(user)!!;
            totalReward = totalReward + haveReward;
        }
        self.userAwardMap.set(user, totalReward);
    }

    fun updateUserWalletMap(user: Address, amount: Int) {

        let totalAmout: Int = amount;
        if (self.userWalletMap.get(user) != null) {
            let currentAmount: Int = self.userWalletMap.get(user)!!;
            totalAmout = totalAmout + currentAmount;
        }
        self.userWalletMap.set(user, totalAmout);
    }

    // receive("increment") {
    //     self.keySupply = self.keySupply + 1;
    // }


    receive(msg: PurchaseOnekey) {
        self.keySupply = self.keySupply + 1;  // 总发行量+1
        self.keyShares = self.keyShares + 1;
        self.updateSubKeySharesMap(msg.keyNum, 1);
        let price: Int = self.calcPrice(self.keyShares);  // 计算当前key的price
        self.vLuckShares = self.vLuckShares + price;       // 计算总的vlock
        self.keyInfoMap.set(self.keySupply, KeyInfo{owner:sender(), keyNum:msg.keyNum, price: price}); // 记录key的信息
        self.updateUserVLuckMap(sender(), price);
        self.updateVLuckMap(msg.keyNum, price);
        // let vLuck: Int = self.getVLuckByAddr(sender());
        // vLuck = vLuck + price;
        // self.uservLuckMap.set(sender(), vLuck);
        // self.keyId
        // send(SendParameters{
        //     to: msg.keyItemAddress,
        //     value: 0,
        //     bounce: false,
        //     mode: SendRemainingValue,
        //     body: KeyMint{owner: sender(), price: 0}.toCell()
        // });
    }


    receive(msg: Redeem) {
        let ctx: Context = context();
        let keyInfo: KeyInfo = self.keyInfoMap.get(msg.keyId)!!;   // 获取当前key的信息
        require(ctx.sender == keyInfo.owner, "Only owner can redeem");
        // todo 增加权限
        let cPrice: Int = self.calcPrice(self.keyShares);  // 计算当前的价格
        self.updateUserWalletMap(keyInfo.owner, cPrice);
        // userWalletMap
        self.keyShares = self.keyShares - 1;
        // let subKeyNum: Int = self.subKeySharesMap.get(msg.keyNum)!!;
        // subKeyNum = subKeyNum - 1;
        // self.subKeySharesMap.set(msg.keyNum, subKeyNum);
        // self.vLuckShares = self.vLuckShares + price;
        self.vLuckShares = self.vLuckShares - keyInfo.price;         // 总的vluck值要减去原来的价格
        self.updateSubKeySharesMap(keyInfo.keyNum, -1);              // 减去
        self.updateUserVLuckMap(keyInfo.owner, -keyInfo.price);
        self.keyInfoMap.set(msg.keyId, null);                        // 删除key的信息



    }


    // receive(msg: Claim) {

    // }

    // receive(msg: Withdraw) {

    // }

    receive("openLuck") {
        // let luckNum: Int = random(1,8);
        self.luckNum = random(1,8);
        // burn all keyItem(num==luckNum)
        let vluck: Int = self.vLuckMap.get(self.luckNum)!!;
        self.vLuckShares = self.vLuckShares - vluck;
        self.vLuckMap.set(self.luckNum, 0);


        self.rewardPreVluck = vluck * 10;
        self.rewardPreVluck = self.rewardPreVluck/self.vLuckShares;
        let i: Int = 0;

        repeat(self.keySupply) {
            i = i + 1;
            if (self.keyInfoMap.get(i) !=null ){
                let keyInfo: KeyInfo = self.keyInfoMap.get(i)!!;
                let reward: Int = self.rewardPreVluck * keyInfo.price;
                reward = reward / 10;
                self.updateUserAwardMap(keyInfo.owner, reward);
            }
        }
    }

    // receive(msg: Withdraw) {

    // }


    // receive(msg: KeyMint) {
    //     self.keySupply = self.keySupply + 1;
    //     self.keyOwnerMap.set(self.keySupply, KeyInfo{owner: msg.owner, price: msg.price});
    // }


    // receive(msg: KeyBurn) {
    //     self.keySupply = self.keySupply - 1;
    //     self.keyOwnerMap.set(msg.keyId, null);
    // }

    // get fun keyInfo(keyId: Int): KeyInfo {
    //     let item: KeyInfo = self.keyOwnerMap.get(keyId)!!;
    //     return item;
    // }

    // get fun keySupply(): Int {
    //     return self.keySupply;
    // }

    // receive("increment") {
    //     self.keySupply = self.keySupply + 1;
    //     // self.add(1);
    //     // self.reply("incremented".asComment());
    // }

    // receive("CalcRewardById") {

    // }


    get fun currentPrice(): Int {
        let shares: Int = self.keyShares + 1;
        return self.calcPrice(shares);
    }

    get fun random(): Int {
        // return nativeRandom();
        // return nativeRandomInterval(8);
        return random(1,8);
    }

    get fun uservLuck(user: Address): Int {
        return self.getVLuckByAddr(user);
    }

    get fun keySupply(): Int {
        return self.keySupply;
    }

    get fun keyInfoById(id: Int): KeyInfo? {
        return self.keyInfoMap.get(id);
    }

    get fun vLuckShares(): Int {
        return self.vLuckShares;
    }

    get fun vLuckByNum(num: Int): Int {
        return self.vLuckMap.get(num)!!;
    }

    get fun luckNum(): Int {
        return self.luckNum;
    }

    get fun userAward(user: Address): Int? {
        return self.userAwardMap.get(user);
    }

    get fun rewardPreVluck(): Int {
        return self.rewardPreVluck;
    }

    get fun userWallet(user: Address): Int? {
        return self.userWalletMap.get(user);
    }
}