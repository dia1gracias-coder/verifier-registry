message SetOwner {
    owner: Address; // 设置owner
}

message AddToWhitelist {
    address: Address; // 添加到白名单
}

message RemoveFromWhitelist {
    address: Address; // 从白名单中移除
}

message Seed {
    recordId: String; // 投注编号
    serverHash: String; // 服务器哈希
}

message Withdraw {
    to: Address; // 提现地址
    amount: Int; // 提取金额
}

const RESERVED_TON: Int = ton("1"); // 保留的TON数量

contract Megano{
   owner: Address; // 合约所有者
   whitelist: map<Address, Bool>; // 白名单地址
   const gasConsumption: Int = ton("0.01"); // 预估的gas消耗

   init() {
    self.owner = sender(); // 初始化所有者
    self.whitelist = emptyMap(); // 初始化白名单
   }

   fun checkAuthorized() {
    // 检查调用者是否为所有者或者白名单中的地址
    let senderAddress: Address = sender();
    require(senderAddress == self.owner || self.whitelist.get(senderAddress) == true, "Unauthorized access");
   }

    // Forwards the remaining value in the
    // incoming message back to the sender
    receive() { cashback(sender()) }

   // 设置所有者,仅当前owner可以调用
   receive (msg: SetOwner) {
       self.checkAuthorized();
       self.owner = msg.owner;  
   }

   // 添加地址到白名单,仅当前owner或者白名单地址可以调用
    receive (msg: AddToWhitelist) {
         self.checkAuthorized();
         self.whitelist.set(msg.address, true);
    }

    // 从白名单中移除地址,仅当前owner或者白名单地址可以调用
    receive (msg: RemoveFromWhitelist) {
         self.checkAuthorized();
         require(self.whitelist.get(msg.address) == true, "Address not in whitelist");
         let _ = self.whitelist.del(msg.address);    
    }

    // 处理Seed消息,仅当前owner或者白名单地址可以调用
    receive (msg: Seed) {
         self.checkAuthorized();
         let random: Int = randomInt(); // 生成随机数
         let randomStr : String = random.toString(); // 转换为字符串
         
         let result : StringBuilder = beginString();
         result.append("{");
         result.append("\"recordId\":");
         result.append("\"");
         result.append(msg.recordId); // 将recordId添加到结果中
         result.append("\",");


         result.append("\"serverHash\":");
         result.append("\"");
         result.append(msg.serverHash); // 将服务器种子hash加到结果中
         result.append("\",");

         result.append("\"tonSeed\":");
         result.append("\"");
         result.append(randomStr); // 将随机数添加到结果中
         result.append("\"");
         result.append("}");

         send(SendParameters {
            to: sender(), // 将种子发送回调用者
            value: 0, // 发送0.01 TON作为确认
            bounce: false,
            mode: SendIgnoreErrors | SendRemainingBalance,
            body: result.toString().asComment(), // 返回结果
         });
    }

    // 提现功能,仅当前owner或者白名单地址可以调用
    receive (msg: Withdraw) {
         self.checkAuthorized();
         let balance: Int = myBalance(); // 获取合约余额
         let toSend: Int = msg.amount;
         if (toSend == 0 ){
            toSend = balance - RESERVED_TON - self.gasConsumption; // 如果未指定金额，则提取所有余额减去保留的TON和手续费
         }else{
            require(toSend <= balance - RESERVED_TON, "Insufficient balance for withdrawal");
         }

         // 发送TON到指定地址
         send(SendParameters {
            to: msg.to,
            value: toSend,
            bounce: false,
            mode: SendIgnoreErrors | SendRemainingBalance,
         });
         emit (Withdraw{to: msg.to, amount: toSend}.toCell());
    }

    get fun getOwner(): String {
        return self.owner.toString();
    }
}