// import "./jetton";

// 设置奖励发送jetton地址
// message JettonAddress{
//     jetton_address: Address;

// }

// message TransferToOwner{
//     query_id: Int as uint64;
//     amount: Int as coins; // 数量
// }

// message IdoEveryoneTokenTransfer {
//     query_id: Int as uint64;
//     amount: Int as coins;
//     custom_payload: Cell?;
//     forward_ton_amount: Int as coins;
//     forward_payload: Slice as remaining;
// }


contract Ido
{
    owner: Address; // 当前所有者地址
    // jettonAddress: Address; // ton上 jettion 代币合约地址
    addressIntMap: map<Address, Int>;  // 地址和转账数量，最大上限3w条
    isIdo: Bool;    // 是否继续ido
 
    init(owner: Address){
        // let zero : Int = 0;
        
        self.owner = owner;
        // self.jettonAddress = newAddress(0,zero); // 初始化为空 // “0QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACkT”
        self.addressIntMap = emptyMap();
        self.isIdo = true;
    }

//    receive(msg: JettonAddress){
//         let ctx: Context = context();
//         require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
//         self.jettonAddress = msg.jetton_address;
//         send(SendParameters{
//                 to: ctx.sender, // 发消息的地址
//                 value: 0,
//                 mode: SendRemainingValue, // 返回剩余gas
//                 bounce: false // messages 没有成功执行，是否退回给发送者。发送者接收到后，可以执行恢复状态等操作
//             });

//     }

    // 个人ido
    receive("Ido"){
        let ctx: Context = context();
         require(self.isIdo, "Not mintable"); // 判断是否可ido
        // 获取地址
        let receiver: Address = ctx.sender; // 获取发送者地址
        let amount: Int = ctx.value; // 获取转账金额

        // 直接发送转账给 self.jettonAddress
        // send(SendParameters{
        //         to: self.jettonAddress,
        //         value: 0,
        //         mode: SendRemainingValue, //发送剩余值
        //         bounce: false,
        //         body: TokenTransfer{ // 0x178d4519 // 发送转账成功消息
        //             query_id: msg.query_id,
        //             amount: amount,   // 需要转账的金额——查询金额
        //             sender: receiver,   // 目标的地址——发送者地址
        //             response_destination: ctx.sender,// 转账成功后的回调wallet地址
        //             custom_payload: msg.custom_payload, // beginCell().endCell()    // emptyCell(),
        //             forward_ton_amount: msg.forward_ton_amount,
        //             forward_payload: msg.forward_payload // 转账附加信息 // beginCell().endCell().asSlice() // emptySlice()
        //         }.toCell()
        //     });
        if(self.addressIntMap.get(receiver) == null){
            self.addressIntMap.set(receiver, amount);
        }else{
            amount += self.addressIntMap.get(receiver)!!;
            self.addressIntMap.set(receiver, amount);
        }
    }


   // 将钱包中的ton余额给拥有者
    receive("TransferAll"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        send(SendParameters{
                to: ctx.sender, // 发消息的地址
                value: 0,
                mode: SendRemainingBalance, // 返回合约中所有余额给拥有者
                bounce: false // messages 没有成功执行，是否退回给发送者。发送者接收到后，可以执行恢复状态等操作
            });
    }
    

    // // 获取jetton代币地址
    // get fun get_AirdropJetton_info(): Address{
    //     return self.jettonAddress;
    // }

    // 关闭ido
    receive("Owner: IdoClose"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        self.isIdo = false;
         send(SendParameters{
                to: ctx.sender, // 发消息的地址
                value: 0,
                mode: SendRemainingValue, // 返回剩余gas
                bounce: false // messages 没有成功执行，是否退回给发送者。发送者接收到后，可以执行恢复状态等操作
            });
    }

    // 开启ido
    receive("Owner: IdoOpen"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner"); // 判断合约所有者才能调用这个消息
        self.isIdo = true;
         send(SendParameters{
                to: ctx.sender, // 发消息的地址
                value: 0,
                mode: SendRemainingValue, // 返回剩余gas
                bounce: false // messages 没有成功执行，是否退回给发送者。发送者接收到后，可以执行恢复状态等操作
            });
    }

    get fun get_idoEveryone_info(): map<Address, Int>{
        return self.addressIntMap;
    }

}