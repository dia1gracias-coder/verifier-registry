import "@stdlib/ownable";
import "./messages";

contract ToncastDAOepoch with Ownable {
    owner: Address;
    epochNumber: Int as uint32;
    totalTonReceived: Int as coins;      // Total TON received in this epoch
    totalToncastStaked: Int as coins;    // Total TONCAST staked in this epoch
    isInitialized: Bool;                 // Flag to track if initial deposit was made
    
    init(owner: Address, epochNumber: Int) {
        self.owner = owner;
        self.epochNumber = epochNumber;
        self.totalTonReceived = 0;
        self.totalToncastStaked = 0;
        self.isInitialized = false;
    }
    
    receive(msg: DeployEpoch) {
        self.requireOwner();
        throwUnless(508, !self.isInitialized);
        throwUnless(501, msg.totalToncastStaked > 0);
        throwUnless(506, context().value >= ton("0.05"));
        self.totalTonReceived = context().value - ton("0.05"); // 0.05 TON storage fee
        self.totalToncastStaked = msg.totalToncastStaked;
        self.isInitialized = true;
    }
    
    // Process payout to staker
    receive(msg: PayoutStaker) {
        // Only owner can initiate payouts
        self.requireOwner();
        
        // Check if epoch is initialized
        throwUnless(500, self.isInitialized);
        
        // Validate staker amount
        throwUnless(502, msg.stakerToncastAmount > 0);
        throwUnless(503, msg.stakerToncastAmount <= self.totalToncastStaked);
        
        // Prevent division by zero
        throwUnless(505, self.totalToncastStaked > 0);
        
        // Calculate staker's share in TON
        // stakerShare = (stakerToncastAmount / totalToncastStaked) * totalTonReceived
        let stakerShare: Int = (msg.stakerToncastAmount * self.totalTonReceived) / self.totalToncastStaked;
        
        // Ensure payout is meaningful (min 0.005 TON to cover gas costs)
        throwUnless(504, stakerShare >= ton("0.005"));
        
        // Build comment
        let comment: StringBuilder = beginString();
            comment.append("Epoch #");
            comment.append(self.epochNumber.toString());
            comment.append(" reward");

        // Check if we have enough balance
        if (myBalance() > (stakerShare + ton("0.005"))) {
            // Normal payout with calculated share
            message(MessageParameters{
                to: msg.stakerAddress,
                value: stakerShare,
                mode: SendRemainingValue | SendIgnoreErrors,
                body: comment.toString().asComment()
            });
        } else {
            // Not enough for full share, but have minimum - send all remaining
            message(MessageParameters{
                to: msg.stakerAddress,
                value: 0,
                mode: SendRemainingBalance | SendDestroyIfZero,
                body: comment.toString().asComment()
            });
        }
    }
    
    // Accept incoming TON
    receive(msg: Slice) { 
    }
    
    // Get all epoch data in one call
    get fun getEpochData(): EpochData {
        return EpochData{
            epochNumber: self.epochNumber,
            totalTonReceived: self.totalTonReceived,
            totalToncastStaked: self.totalToncastStaked,
            isInitialized: self.isInitialized,
            owner: self.owner
        };
    }
    
    // Calculate staker's reward share
    get fun calculateStakerReward(stakerToncastAmount: Int): Int {
        if (!self.isInitialized || self.totalToncastStaked == 0 || stakerToncastAmount <= 0) {
            return 0;
        }
        let reward: Int = (stakerToncastAmount * self.totalTonReceived) / self.totalToncastStaked;
        // Return 0 if reward is below minimum payout threshold
        if (reward < ton("0.005")) {
            return 0;
        }
        return reward;
    }
}
