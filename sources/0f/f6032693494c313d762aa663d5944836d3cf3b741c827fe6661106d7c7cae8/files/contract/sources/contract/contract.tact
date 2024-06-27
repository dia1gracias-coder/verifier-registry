import "./jetton";
struct EntData {
    total_supply: Int as coins;
    mintable: Bool; // 是否可以铸币  true -1 false 0
    max_supply: Int as coins;
}
struct RewardArray {
    // 领取奖励的地址和数量
    addressBoolMap: map<Address, Bool>; // 地址，是否已经领取
    addressIntMap: map<Address, Int>; // 地址，领取数量
    length: Int = 0; 
}
const MaxArraySize: Int = 10000; // 最大存储1w个地址，
message Mint {
    amount: Int; // 数量
    receiver: Address; // 接收者地址
}
// message RewardAddress {
//     receiver: Address; // 接收者地址
// }
message MaxSupply {
    max_supply: Int; // 最大供应量
}
// 增加一个地址的奖励
message Append {
    receiver: Address; // 领取奖励的地址和数量
    mark: Bool; // 是否已经领取
    amount: Int; // 数量
}
// 更新某个地址信息
message UpdateAddressInfo {
    receiver: Address; // 领取奖励的地址和数量
    mark: Bool; // 是否已经领取
    amount: Int; // 数量
}
message Replace {
    // rewardArray: RewardArray; // 领取奖励的地址和数量
    ddressBoolMap: map<Address, Bool>;
    addressIntMap: map<Address, Int>;
    length: Int;
}

// 由于智能合约状态大小的上限约为 65000  个 Cell 类型的项，
// 因此它将整个合约的映射存储限制限制为约 30000 个键值对。
// 两个map的总和不能超过3w，1个1w；

// 增加一个地址和数量
extends mutates fun append(self: RewardArray, receiver: Address, mark: Bool, amount: Int): Bool {
    require((self.length + 1) <= MaxArraySize, "No space in the array left for new items!");
    if(self.addressIntMap.get(receiver) == null){
        self.length += 1; // 长度+1
    }
    
    self.addressIntMap.set(receiver, amount);
    self.addressBoolMap.set(receiver, mark);
    
    return true;
}

// 获取地址对应数量

extends fun getAddressAmount(self: RewardArray, receiver: Address): Int {
    require(self.length > 0, "No items in the array!");
    return self.addressIntMap.get(receiver)!!;
}
// 获取地址领取状态

extends fun getAddressBool(self: RewardArray, receiver: Address): Bool {
    require(self.length > 0, "No items in the array!");
    return self.addressBoolMap.get(receiver)!!;
}

// 更新某个地址的奖励数量与领取状态

extends  mutates  fun updataAddress(self: RewardArray, receiver: Address, mark: Bool, amount: Int): Bool {
    require(self.length > 0, "No items in the array to update!");
    self.addressBoolMap.set(receiver, mark);
    self.addressIntMap.set(receiver, amount);
    return true;
}

// 更新所有地址

extends  mutates  fun replaceAddress(self: RewardArray,
    addressBoolMap: map<Address, Bool>,
    addressIntMap: map<Address, Int>,
    length: Int) {
    // require(self.length == 0, "No items in the array to update!");
    self.addressBoolMap = addressBoolMap;
    self.addressIntMap = addressIntMap;
    self.length = length;
}

// 删除固定地址，将领取状态改为false，领取值为null

extends  mutates  fun deleteAddress(self: RewardArray, receiver: Address): Bool {
    require(self.length > 0, "No items in the array to delete!");
    self.addressBoolMap.set(receiver, null);
    self.addressIntMap.set(receiver, null);
    return true;
}
// 删除所有

extends  mutates  fun deleteAll(self: RewardArray) {
    self.addressIntMap = emptyMap();
    self.addressBoolMap = emptyMap();
    self.length = 0;
}

// Global static function for creating an empty Array

fun emptyArray(): RewardArray {
    return RewardArray{addressIntMap: emptyMap(), addressBoolMap: emptyMap(), length: 0};
}

contract SampleJetton with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    // 额外设置的最大供应量
    max_supply: Int as coins; // Extract parameter we set here. The Jetton Standards doesn't have this parameter.
    rewardArray: RewardArray;
    init(owner: Address, content: Cell, max_supply: Int){
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
        self.rewardArray = emptyArray();
    }

    // 合约所有者铸币
    receive(msg: Mint){
        // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        require(self.mintable, "Not mintable"); // 判断是否可铸币
        require((self.total_supply + msg.amount) <= self.max_supply, "Max supply exceeded"); // 总供应量+当前供应量 是否 超过最大供应量
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination) // 调用方法进行铸币
    }

    // 个人奖励铸币
    receive("RewardAddress"){
        let ctx: Context = context();
        // 获取地址
        let receiver: Address = ctx.sender;
        let amount: Int = self.rewardArray.getAddressAmount(receiver); // 获取地址对应数量
        let mark: Bool = self.rewardArray.getAddressBool(receiver);
        require(self.mintable, "Not mintable"); // 判断是否可铸币
        require(mark == true, "Not true"); // 判断是否已经领取
        require((self.total_supply + amount) <= self.max_supply, "Max supply exceeded"); // 总供应量+当前供应量 是否 超过最大供应量
        self.rewardArray.updataAddress(receiver, false, amount); // 领取状态改为false
        self.mint(receiver, amount, self.owner);
    }

    // 更新所有奖励地址
    receive(msg: Replace){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        self.rewardArray.replaceAddress(msg.ddressBoolMap,msg.addressIntMap,msg.length); // 更新所有地址
        // require(self.rewardArray.getAddressBool(receiver) == true, "Not true");
    }

    // 增加一个地址
    receive(msg: Append){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        self.rewardArray.append(msg.receiver, msg.mark, msg.amount); // 更新所有地址
        // let temp: Bool = self.rewardArray.append(msg.receiver, msg.mark, msg.amount); // 更新所有地址
    }

    // 更新某个地址的信息
    receive(msg: UpdateAddressInfo){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        self.rewardArray.updataAddress(msg.receiver, msg.mark, msg.amount); // 更新所有地址
        // let temp: Bool = self.rewardArray.updataAddress(msg.receiver, msg.mark, msg.amount); // 更新所有地址
    }

    // 删除所有奖励地址
    receive("deleteRewardMint"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        self.rewardArray.deleteAll();
    }

    //所有人发消息，都可以铸100币
    // receive("Mint: 100") { // Public Minting
    //     let ctx: Context = context();
    //     require(self.mintable, "Not mintable");
    //     require(self.total_supply + 100 <= self.max_supply, "Max supply exceeded");
    //     self.mint(ctx.sender, 100, self.owner); // 🔴
    // }

    // 增加最大供应量
    receive(msg: MaxSupply){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        self.max_supply += msg.max_supply;
    }

    // 打开铸币，任何人都无法铸币（默认开启）
    receive("Owner: MintOpen"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        self.mintable = true;
    }

    // 关闭铸币后，任何人都无法铸币
    receive("Owner: MintClose"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        self.mintable = false;
    }

    // 获取当前 jetton 数据
    get fun get_jetton_info(): EntData {
        return
            EntData{
                total_supply: self.total_supply,
                mintable: self.mintable, // 铸币开关
                max_supply: self.max_supply
            };
    }

    // 获取奖励地址所有的奖励信息

    get fun get_RewardArrayAll_info(): RewardArray {
        return
            RewardArray{
                addressBoolMap: self.rewardArray.addressBoolMap,
                addressIntMap: self.rewardArray.addressIntMap,
                length: self.rewardArray.length
            };
    }

    // 获取最大奖励个数

    get fun get_MaxArraySize(): Int {
        return MaxArraySize;
    }

    // 查询某个地址的奖励状态

    // get fun get_RewardArray_info(receiver: Address): Append {

    get fun get_RewardArray_info(receiver: Address): Append {
        // let receiver: Address = address("0QDiUISMHHfjHjqFgGAhT9d9OpPO5puVewBSXKCwzpG3l57p");
        // EQDiUISMHHfjHjqFgGAhT9d9OpPO5puVewBSXKCwzpG3l3im
        return
            Append{
                receiver: receiver,
                mark: self.rewardArray.addressBoolMap.get(receiver)!!, // 是否可以领取
                amount: self.rewardArray.addressIntMap.get(receiver)!!
            };
    }

    // get获取地址方法 
    // boc ——  https://test-explorer.toncoin.org/
    // address —— https://testnet.ton.cx/

    // 获取当前奖励数组长度

    get fun get_RewardArrayLenght(): Int {
        return self.rewardArray.length;
    }
}

// 0QDiUISMHHfjHjqFgGAhT9d9OpPO5puVewBSXKCwzpG3l57p
// base64 te6cckEBAQEAJAAAQ4AcShCRg478Y8dQsAwEKfrvp1J53NNyr2AKS5QWGdI28vDDuwGQ
// boc x{801C4A1091838EFC63C750B00C0429FAEFA75279DCD372AF600A4B941619D236F2F_}
// address EQDiUISMHHfjHjqFgGAhT9d9OpPO5puVewBSXKCwzpG3l3im


// int -1
// coins -0.000000001
// hex -1
// base64 /w==