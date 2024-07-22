import "@stdlib/deploy";
import "@stdlib/ownable";
// 池子彩票逻辑
// 1、任何人都可以创建彩票池子，创建池子需要手续费[0.1Ton]（池子有大[100Ton]中[10Ton]小[1Ton]之分）
//  池子创建者如果没有中奖,会返还一半钱，中奖则获取70%
// （池子创建后，只要有10个人参与，就会有一个人获奖，得到总奖池的50%奖金,40%平分未获奖者）
// 2、用户调用父合约购买彩票（彩票会提供十个数字，用户选择一个【可能只会有一个数字可选，但中奖概率是一样的】）
// 用户购买之后，当人数达到10时，会自动开奖


// 新建彩票池的message 
message NewLotteryPool {
    creator: Address;
    pool_type: Int as uint8;
    expire_time: Int;
}

// 购买彩票消息
message BuyTicket {
    buyer: Address;
    lottery_pool_id: Int as uint256;
    select_number: Int as uint32;
    value: Int as coins;
}

// 查看是否获奖消息
message CheckTicket {
    lottery_pool_id: Int as uint256;
    select_number: Int as uint32;
}

contract Lottery with Deployable ,Ownable{
    owner: Address;
    lottery_pool_nums: Int as uint256 = 0;
    init (){
        self.owner = sender();
    }
    // 创建新彩票池子
    receive(msg: NewLotteryPool){
        // 彩票池序号加一
        self.lottery_pool_nums = (self.lottery_pool_nums + 1);
        // 生成10个随机数，并且将其中一个作为lucky number
        // 创建一个map，包含10个数，再取出这十个数，随机出一个数作为lucky number 
        let nums: map<Int as uint8, Int as uint32> = emptyMap();
        repeat(10){
            let index:Int  = 0;
            let random_number: Int = random(1,100);
            nums.set(index,random_number);
            index = index + 1;
        }
        let lucky_number_index: Int = random(0,10);
        let final_lucky_number: Int? = nums.get(lucky_number_index);
        let init: StateInit = initOf LotteryPoolContract(myAddress(),self.lottery_pool_nums);
        // 创建彩票池子合约
        send(SendParameters{
                to: contractAddress(init),
                body: InternalNewLotteryPool{
                    creator: msg.creator,
                    pool_type: msg.pool_type,
                    expire_time: msg.expire_time,
                    lucky_number: final_lucky_number,
                    nums: nums
                }.toCell(),
                value: ton("0.02"), // pay for the deployment and leave some TON in the child for storage
                mode: SendIgnoreErrors,
                code: init.code, // prepare the initial code when deploying the child contract
                data: init.data
            }
        );
        self.reply("Lottery Pool Create Successfully!".asComment());
    }

    // 购买彩票
    receive(msg: BuyTicket){
        require(msg.lottery_pool_id <= self.lottery_pool_nums, "Lottery pool does not exist");
        send(SendParameters{ 
                to: contractAddress(initOf LotteryPoolContract(myAddress(),msg.lottery_pool_id)),
                body: InternalBuy{
                    buyer: msg.buyer,
                    lottery_pool_id: msg.lottery_pool_id,
                    select_number: msg.select_number,
                    value: msg.value
                }.toCell(),
                value: msg.value, 
                mode: SendRemainingValue,
            }
        );
        self.reply("Buy Ticket Successfully!".asComment());
    }

    get fun numPools(): Int {
        return self.lottery_pool_nums;
    }

    get fun poolAddress(lottery_pool_id: Int): Address {
        return contractAddress(initOf LotteryPoolContract(myAddress(), lottery_pool_id));
    }
}

message InternalNewLotteryPool{
    creator: Address;
    pool_type: Int as uint8;
    expire_time: Int;
    lucky_number: Int? as uint32;
    nums: map<Int as uint8, Int as uint32>;
}
message InternalBuy{
    buyer: Address;
    lottery_pool_id: Int as uint256;
    select_number: Int as uint32;
    value: Int as coins;
}

// 彩票池子结构
struct LotteryPool {
    id: Int as uint256;
    creator: Address?;
    pool_type: Int as uint8;
    is_valid: Bool;
    lucky_address: Address?;
    lucky_number: Int? as uint32;
    total_value: Int as coins;
}

contract LotteryPoolContract {
    const SMALLPOOL: Int = 0;
    const MIDDLEPOOL: Int = 1;
    const LARGEPOOL: Int = 2;

    id: Int as uint256 = 0;
    parent: Address;
    is_valid: Bool = true;
    pool_type: Int as uint8 = 0;
    expire_time: Int = 0;
    lucky_number: Int? as uint32 = 404;
    num_buyers: Int as uint8 = 0;
    nums: map<Int as uint8, Int as uint32>;
    select_number: Int as uint32 = 0;
    total_value: Int as coins = 0;
    lucky_address: Address?;
    creator: Address?;

    init (parent: Address , id: Int) {
        self.parent = parent;
        self.id = id;
    }

    receive(msg: InternalNewLotteryPool) { 
        self.pool_type = msg.pool_type;
        self.expire_time = msg.expire_time;
        self.lucky_number = msg.lucky_number;
        self.nums = msg.nums;
        self.creator = msg.creator;
        
    }

    receive(msg: InternalBuy) {
        // 判断池子是否有效
        // 判断是否过期
        if(self.expire_time <= now()){
            self.is_valid = false;
        } 
        require(self.is_valid,"Lottery Pool is invalid!" );
        require(self.num_buyers <= 10,"The number of buyers exceeds 10");
        // 判断池子类型，判定是否接收
        require(self.pool_type == self.SMALLPOOL || self.pool_type == self.MIDDLEPOOL || self.pool_type == self.LARGEPOOL,"Pool type is wrong!");
        if(self.pool_type == self.SMALLPOOL){
            require(msg.value == ton("1"),"value doesn't match pool type,needing 1 Ton!");
            self.total_value += msg.value;
        }
        else if(self.pool_type == self.MIDDLEPOOL){
            require(msg.value == ton("10"),"value doesn't match pool type,needing 10 Ton!");
            self.total_value += msg.value;
        }
        else if(self.pool_type == self.LARGEPOOL){
            require(msg.value == ton("100"),"value doesn't match pool type,needing 100 Ton!");
            self.total_value += msg.value;
        }
        self.select_number = msg.select_number;
        let nums_buy:map<Int as uint8, Int as uint32> = self.nums;
        // 遍历nums，找到是否有select_number，若有则删除，没有就报错
        foreach (key, value in nums_buy) {
            if (value == self.select_number) {
                // 判断是否是幸运数字
                if (self.select_number == self.lucky_number){
                    // 如果是幸运数字，就标记这个用户为幸运地址
                    self.lucky_address = msg.buyer;
                }
                nums_buy.del(key);
                self.nums = nums_buy;
            }
            else {   
                let flag: Bool = false;
                require(flag == true,"This number doesn't exist in the pool");
            }
        }
        self.num_buyers = self.num_buyers + 1; 
        // 当人数满足条件后，开奖  
        if(self.num_buyers == 10){ 
            // 给幸运用户发奖，如果是创建者，奖励总奖池的 7/10
            if (self.lucky_address != null && self.creator == self.lucky_address){
                send(SendParameters{ 
                    to: self.lucky_address!!,
                    value: self.total_value / 10 * 7,
                    mode: SendRemainingValue,
                });
                self.reply("Creator claim reward succassfully!".asComment());
            } 
            // 如果不是创建者，奖励总奖池的 1/2
            else if (self.lucky_address != null && self.creator != self.lucky_address){
                send(SendParameters{ 
                    to: self.lucky_address!!,
                    value: self.total_value / 2,
                    mode: SendRemainingValue,
                });
                self.reply("Claim reward succassfully!".asComment());
            }
            // 把池子中剩余Ton返还给合约发布者
            send(SendParameters{ 
                    to: self.parent,
                    value: 0, 
                    mode: (SendRemainingBalance + SendIgnoreErrors),
                }
            );
            self.reply("Withdraw value succassfully!".asComment());
            self.is_valid = false;
        }
    } 

    get fun getLotteryPool() : LotteryPool {
        if (!self.is_valid && (self.lucky_address!=null) && self.lucky_number != 404 ){
            return LotteryPool{
                id: self.id,
                creator: self.creator,
                pool_type: self.pool_type,
                is_valid: self.is_valid,
                lucky_address: self.lucky_address!!,
                lucky_number: self.lucky_number!!,
                total_value: self.total_value,
            };
        } else {
            return LotteryPool{
                id: self.id,
                creator: self.creator,
                pool_type: self.pool_type,
                is_valid: self.is_valid,
                lucky_address: null,
                lucky_number: 404 ,
                total_value: self.total_value
            };
        }
    }
}