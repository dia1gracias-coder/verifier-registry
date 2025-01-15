import "@stdlib/deploy";

message SetAdmins {
    admins: map<Address, Bool>;
}
message PlaceBid {
    orderId: Int;
}
message FinalizeAuction {
    orderId: Int;
}
message OrderSuccessed {
    orderId: Int;
    comment: String;
}
message OrderUnsuccessed {
    orderId: Int;
    comment: String;
}
message AuctionOrderPayload {
    id: Int;
    description: String;
    minBid: Int;
    duration: Int;
}
message ConfirmOrder {
    orderId: Int;
    approve: Bool;
}
message NewMinBid {
    minBid: Int;
}
message NewMinOrderDuration {
    duration: Int;
}
message NewMinStep {
    step: Int;
}
message Withdraw {
    amount: Int;
}
message SetFounder {
    founder: Address;
}
message SetFeePercentageWinner {
    fee: Int;
}
message SetFeePercentageBidder {
    fee: Int;
}
message SetFeePercentageNoBid {
    fee: Int;
}
message SetFeePercentageUnsuccess {
    fee: Int;
}
message SetPledgePerchentage {
    percentage: Int;
}

struct Bid {
    bidder: Address;
    amount: Int;
}
struct AuctionOrder {
    id: Int;
    owner: Address;
    description: String;
    minBid: Int;
    depositPaid: Int;
    highestBid: Bid?;
    duration: Int;
    endTime: Int;
    finalized: Bool;
    active: Bool;
    successed: Bool = false;
}

contract GiftAuction with Deployable {
    const MinTonForStorage: Int = ton("0.05");

    FeePercentageWinner: Int = 500;
    FeePercentageBidder: Int = 50;
    FeePercentageNoBid: Int = 100;
    FeePercentageUnsuccess: Int = 5000;
    
    minBidRequire: Int = ton("5");
    minOrderDuration: Int = 3600;
    minStep: Int = ton("1");
    pledgePerchentage: Int = 1000;
    deployer: Address;
    orders: map<Int, AuctionOrder>;
    orderCounter: Int;
    admins: map<Address, Bool>;
    version: Int as uint32;
    founder: Address;

    init(version: Int){
        self.deployer = sender();
        self.orders = emptyMap();
        self.orderCounter = 0;
        self.admins = emptyMap();
        self.admins.set(self.deployer, true); // Deployer is an admin by default
        self.version = version;
        self.founder = sender();
    }

    // Admin management
    receive(msg: SetAdmins){
        require(sender() == self.deployer, "Only deployer can manage admins");
        self.admins = msg.admins;
    }

    // Order creation
    receive(msg: AuctionOrderPayload){
        let minRequiredDeposit = msg.minBid * (self.pledgePerchentage / 100) / 100;

        require(context().value >= minRequiredDeposit, "Insufficient deposit for order creation");
        require(msg.minBid >= self.minBidRequire, "Minimum bid is too low");
        require(msg.duration >= self.minOrderDuration, "Auction duration must be at least 1 hour");

        let orderOpt = self.orders.get(msg.id);
        require(orderOpt == null, "Order with this ID already exists");

        let endTime = now() + msg.duration;
        let newOrder: AuctionOrder = AuctionOrder{
            id: msg.id,
            owner: sender(),
            description: msg.description,
            minBid: msg.minBid,
            depositPaid: context().value,
            highestBid: null,
            duration: msg.duration,
            endTime: 0,
            finalized: false,
            active: false
        };
        self.orders.set(msg.id, newOrder);
        self.orderCounter += 1;
    }

    // Order confirmation
    receive(msg: ConfirmOrder) {
        let isAdmin = self.admins.get(sender());
        require(isAdmin != null && isAdmin == true, "Only admins can confirm orders");

        let orderOpt = self.orders.get(msg.orderId);
        require(orderOpt != null, "Order not found");

        let order = orderOpt!!;
        require(!order.active, "Order is already active");

        if (msg.approve) {
            order.active = true;
            order.endTime = now() + order.duration;
        } else {
            // Return deposit to the owner
            send(SendParameters{
                to: order.owner,
                value: order.depositPaid - self.MinTonForStorage,
                bounce: true,
                mode: SendIgnoreErrors
            });

            self.orders.del(msg.orderId);
            return;
        }

        self.orders.set(msg.orderId, order);
    }

    // Place a bid
    receive(msg: PlaceBid){
        let orderOpt = self.orders.get(msg.orderId);
        require(orderOpt != null, "Order not found");

        let order: AuctionOrder = self.orders.get(msg.orderId)!!;

        require(order.active, "Order is not active");
        require(now() < order.endTime, "Auction has ended");
        
        let bidAmount = context().value;
        require(bidAmount >= order.minBid + self.minStep, "Bid is too low");
        
        if (order.highestBid != null) {
            let highestBid = order.highestBid!!;
            require(bidAmount >= highestBid.amount + self.minStep, "Bid is not higher than the current highest");
            // Return funds to the previous bidder

            let fee = (highestBid.amount * (self.FeePercentageBidder / 100)) / 100;

            let commentBidder: StringBuilder = beginString();
            commentBidder.append("#");
            commentBidder.append(msg.orderId.toString());

            send(SendParameters{
                    to: self.founder,
                    value: fee / 2,
                    bounce: true,
                    mode: SendIgnoreErrors,
                    body: commentBidder.toString().asComment()
                }
            );

            send(SendParameters{
                    to: highestBid.bidder,
                    value: (highestBid.amount * (100 - (self.FeePercentageBidder / 100))) / 100,
                    bounce: true,
                    mode: SendIgnoreErrors
                }
            );
        }

        order.highestBid = Bid{bidder: sender(), amount: bidAmount};
        self.orders.set(msg.orderId, order);
    }

    // Finalize an auction
    receive(msg: FinalizeAuction){
        let isAdmin = self.admins.get(sender());
        require(isAdmin != null && isAdmin == true, "Only admins can finalize auctions");
        
        let orderOpt = self.orders.get(msg.orderId);
        require(orderOpt != null, "Order not found");

        let order: AuctionOrder = self.orders.get(msg.orderId)!!;
        require(now() >= order.endTime, "Auction is still ongoing");
        require(!order.finalized, "Auction already finalized");
        if (order.highestBid == null) {
            let fee = (order.depositPaid * (self.FeePercentageNoBid / 100)) / 100;

            let commentNoBidder: StringBuilder = beginString();
            commentNoBidder.append("#");
            commentNoBidder.append(msg.orderId.toString());

            send(SendParameters{
                    to: self.founder,
                    value: fee / 2,
                    bounce: true,
                    mode: SendIgnoreErrors,
                    body: commentNoBidder.toString().asComment()
                }
            );

            send(SendParameters{
                    to: order.owner,
                    value: (order.depositPaid * (100 - (self.FeePercentageNoBid / 100))) / 100,
                    bounce: true,
                    mode: SendIgnoreErrors
                }
            );
        }

        order.finalized = true;
        self.orders.set(msg.orderId, order);
    }

    // Order auction is successed
    receive(msg: OrderSuccessed){
        let isAdmin = self.admins.get(sender());
        require(isAdmin != null && isAdmin == true, "Only admins can success closing auction");
        
        let orderOpt = self.orders.get(msg.orderId);
        require(orderOpt != null, "Order not found");

        let order: AuctionOrder = self.orders.get(msg.orderId)!!;
        require(order.successed == false, "Order already successed");
        require(order.finalized, "Auction is not finalized");
        require(order.highestBid != null, "No bids were placed");
        let highestBid = order.highestBid!!;

        let winnerFee = (highestBid.amount * (self.FeePercentageWinner / 100)) / 100;
        let winnerAmount = order.depositPaid + highestBid.amount - winnerFee;

        let commentFounder: StringBuilder = beginString();
        commentFounder.append("#");
        commentFounder.append(msg.orderId.toString());

        send(SendParameters{
                to: self.founder,
                value: winnerFee / 2,
                bounce: true,
                mode: SendIgnoreErrors,
                body: commentFounder.toString().asComment()
            }
        );

        send(SendParameters{
                to: order.owner,
                value: winnerAmount,
                bounce: true,
                mode: SendIgnoreErrors,
                body: msg.comment.asComment()
            }
        );

        order.successed = true;
        order.active = false;
        self.orders.set(msg.orderId, order);
    }

    // Order auction is unsuccessed
    receive(msg: OrderUnsuccessed){
        let isAdmin = self.admins.get(sender());
        require(isAdmin != null && isAdmin == true, "Only admins can unsuccess closing auction");

        let order: AuctionOrder = self.orders.get(msg.orderId)!!;
        require(order.successed == false, "Order already successed");
        require(order.finalized, "Auction is not finalized");
        require(order.highestBid != null, "No bids were placed");

        let highestBid = order.highestBid!!;

        let unsuccessFee = (order.depositPaid * (self.FeePercentageUnsuccess / 100)) / 100;
        let bidderAmount = order.depositPaid - unsuccessFee;

        let comment: StringBuilder = beginString();
        comment.append("#");
        comment.append(msg.orderId.toString());

        send(SendParameters{
                to: self.founder,
                value: unsuccessFee / 2,
                bounce: true,
                mode: SendIgnoreErrors,
                body: comment.toString().asComment()
            }
        );

        send(SendParameters{
                to: highestBid.bidder,
                value: bidderAmount,
                bounce: true,
                mode: SendIgnoreErrors,
                body: msg.comment.asComment()
            }
        );

        send(SendParameters{
                to: highestBid.bidder,
                value: highestBid.amount,
                bounce: true,
                mode: SendIgnoreErrors,
            }
        );

        order.active = false;
        self.orders.set(msg.orderId, order);
    }

    // Change the minimum bid
    receive(msg: NewMinBid){
        require(sender() == self.deployer, "Only deployer can change min bid");
        self.minBidRequire = msg.minBid;
    }

    // Change the minimum order duration
    receive(msg: NewMinOrderDuration){
        require(sender() == self.deployer, "Only deployer can change min order duration");
        self.minOrderDuration = msg.duration;
    }

    // Change the minimum step
    receive(msg: NewMinStep){
        require(sender() == self.deployer, "Only deployer can change min step");
        self.minStep = msg.step;
    }

    // Set the founder
    receive(msg: SetFounder){
        require(sender() == self.deployer, "Only deployer can set the founder");
        self.founder = msg.founder;
    }

    // Set the fee percentage for the winner
    receive(msg: SetFeePercentageWinner){
        require(sender() == self.deployer, "Only deployer can set the fee percentage for the winner");
        self.FeePercentageWinner = msg.fee;
    }

    // Set the fee percentage for the bidder
    receive(msg: SetFeePercentageBidder){
        require(sender() == self.deployer, "Only deployer can set the fee percentage for the bidder");
        self.FeePercentageBidder = msg.fee;
    }

    // Set the fee percentage for no bid
    receive(msg: SetFeePercentageNoBid){
        require(sender() == self.deployer, "Only deployer can set the fee percentage for no bid");
        self.FeePercentageNoBid = msg.fee;
    }

    // Set the fee percentage for unsuccess
    receive(msg: SetFeePercentageUnsuccess){
        require(sender() == self.deployer, "Only deployer can set the fee percentage for unsuccess");
        self.FeePercentageUnsuccess = msg.fee;
    }

    // Set the pledge percentage
    receive(msg: SetPledgePerchentage){
        require(sender() == self.deployer, "Only deployer can set the pledge percentage");
        self.pledgePerchentage = msg.percentage;
    }

    // Withdraw funds
    receive(msg: Withdraw) {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");

        let locked: Int = self.lockedBalance();

        require(myBalance() - locked >= msg.amount, "Insufficient balance");

        send(SendParameters{
            to: sender(),
            bounce: true,
            value: msg.amount,
            mode: SendIgnoreErrors
        });
    }

    receive("withdraw") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");

        let locked: Int = self.lockedBalance();

        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - locked,
            mode: SendIgnoreErrors
        });
    }

    // Get an order by ID
    get fun getOrder(orderId: Int): AuctionOrder {
        require(orderId < self.orderCounter, "Invalid order ID");
        return self.orders.get(orderId)!!;
    }

    // Get all orders
    get fun allOrders(): map<Int, AuctionOrder> {
        return self.orders;
    }

    // Get the number of orders
    get fun orderCount(): Int {
        return self.orderCounter;
    }

    // Get all admins
    get fun getAdmins(): map<Address, Bool> {
        return self.admins;
    }

    // Get the minimum bid
    get fun getMinBid(): Int {
        return self.minBidRequire;
    }

    // Get the minimum order duration
    get fun getMinOrderDuration(): Int {
        return self.minOrderDuration;
    }

    // Get the minimum step
    get fun getMinStep(): Int {
        return self.minStep;
    }

    // Get the pledge percentage
    get fun getPledgePerchentage(): Int {
        return self.pledgePerchentage;
    }

    // Get the founder
    get fun getFounder(): Address {
        return self.founder;
    }

    // Get balance
    get fun balance(): Int {
        return myBalance();
    }

    // Get locked balance
    get fun lockedBalance(): Int {
        let result: Int = 0;
        foreach (orderId, order in self.orders) {
            if (order.active || order.endTime == 0) {
                result += order.depositPaid;

                if (order.highestBid != null) {
                    result += order.highestBid!!.amount;
                }
            }
        }

        return result;
    }
}