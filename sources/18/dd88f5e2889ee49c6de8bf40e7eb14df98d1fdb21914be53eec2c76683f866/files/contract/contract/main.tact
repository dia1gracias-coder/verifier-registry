import "@stdlib/deploy";

message CreateRoom {
    roomId: Int as uint256;            // Unique room identifier
    gameType: Int as int8;         // 0 = Chess, 1 = Billiards, 2 = Trivial
    betVolume: Int as coins;        // Bet value for this room (e.g. $0.10, $0.50, etc.)
    capacity: Int as uint256;          // Maximum number of players allowed in the room
}

message Bet {
    roomId: Int as uint256;
    betAmount: Int as coins;        // Must equal the room’s betVolume
    gameType: Int as uint8;         // Provided for verification against room data
}

message EndGame {
    roomId: Int as uint256;
    winnerCount: Int as uint8;       // 1, 2, or 3 winners for the room
    winner1: Address;
    
}

message WithdrawWinnings {
    user: Address;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
const JettonTransferGas: Int = ton("0.1");

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

fun calculateJettonWalletAddress(
    ownerAddress: Address,
    jettonMasterAddress: Address,
    jettonWalletCode: Cell
): Address {

    let initData = JettonWalletData{
        balance: 0,
        ownerAddress,
        jettonMasterAddress,
        jettonWalletCode,
    };

    return contractAddress(StateInit{
        code: jettonWalletCode,
        data: initData.toCell(),
    });
}

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

struct Room {
    gameType: Int as uint8;         // Game type (Chess, Billiards, Trivial)
    betVolume: Int as coins;        // Bet amount required to join this room
    capacity: Int as uint8;          // Maximum players allowed
    playersCount: Int as uint8;      // Number of players who have joined
    totalLocked: Int as coins;      // Total amount locked in this room
}
struct PendingBet {
    roomId: Int as uint256;
    betAmount: Int as coins;
}

contract BettingContract with Deployable {

    m_rooms: map<Int as uint8, Room>;
    userWinnings: map<Address, Int as coins>;
    owner: Address;
    feePercent: Int as uint8 = 30;
    withdrawalCap: Int as coins = ton("10"); // e.g. 10 USDT in smallest unit
    userBets: map<Int as uint256, Bool>;
    jettonWalletAddress: Address;
    totalReceivedJettons: Int as coins = 0;
    pendingBets: map<Address, PendingBet>;









    init(_owner:Address, jettonWalletCode: Cell, jettonMasterAddress: Address) {
        self.owner = _owner;
        self.m_rooms = emptyMap();
        self.userWinnings = emptyMap(); 
        self.userBets = emptyMap();
                self.pendingBets = emptyMap();

        self.jettonWalletAddress = calculateJettonWalletAddress(myAddress(), jettonMasterAddress, jettonWalletCode);


    }

    // --- Room Creation ---
    // Only the owner can create new rooms.
    receive(msg: CreateRoom) {
        require(sender() == self.owner, "Only owner can create rooms");
        require(!self.m_rooms.exists(msg.roomId), "Room already exists"); 

        let room = Room{
            gameType: msg.gameType,
            betVolume: msg.betVolume,
            capacity: msg.capacity,
            playersCount: 0,
            totalLocked: 0
        };
       
        self.m_rooms.set(msg.roomId,room);
        // Refund any remaining gas.
        cashback(sender());
    }

    receive(msg: Bet) {

        let roomOpt: Room? = self.m_rooms.get(msg.roomId); 

       require(roomOpt != null, "Room not found");

       let room: Room = roomOpt!!;
        let keyCell = beginCell().storeUint(msg.roomId, 256).storeAddress(sender()).endCell();
        let betKey: Int  = keyCell.hash();

        require(self.userBets.get(betKey) == null, "User already bet in this room");

 

        require(room.capacity > room.playersCount, "Room is full");
        // Ensure the bet amount matches the room's set betVolume.
        require(msg.betAmount == room.betVolume, "Invalid bet amount");

        room.playersCount += 1;
        // room.totalLocked += msg.betAmount;
        self.m_rooms.set(msg.roomId,room); 
        self.userBets.set(betKey, true);
        let p: PendingBet = PendingBet{
            roomId: msg.roomId,
            betAmount: msg.betAmount
        };
        self.pendingBets.set(sender(), p);



        cashback(sender());
    }

    receive(msg: JettonTransferNotification)
    {
        require(sender() == self.jettonWalletAddress, "Notification not from jetton wallet");
        let pendingOpt: PendingBet? = self.pendingBets.get(msg.sender);
        require(pendingOpt != null, "No pending bet for sender");
        let pending = pendingOpt!!;
        require(msg.amount == pending.betAmount, "Transferred amount does not match pending bet amount");

         // Update the room's totalLocked using the pending bet's roomId.
        let roomOpt: Room? = self.m_rooms.get(pending.roomId);
        require(roomOpt != null, "Room not found for pending bet");
        let room = roomOpt!!;
        room.totalLocked += msg.amount;
        self.m_rooms.set(pending.roomId, room);

         // Clear the pending bet.
        self.pendingBets.del(msg.sender);

        // Update total received jettons.
        self.totalReceivedJettons += msg.amount;

        // Forward any excess funds if needed.
        self.forward(msg.sender, null, false, null);
        cashback(msg.sender);



    }
    
    get fun getRoomInfo(roomId: Int): Room {
        let roomOpt: Room? = self.m_rooms.get(roomId);

        // Require that the room was found, otherwise throw an error
         require(roomOpt != null, "Room not found in getRoomInfo"); 

         // If the require passes, roomOpt cannot be null, so we can safely unwrap with !!
          return roomOpt!!;  
    }

    get fun getUserWinnings(user: Address): Int {
         let winningsOpt = self.userWinnings.get(user);
         if (winningsOpt != null) {
              return winningsOpt!!;
        } else {
        return 0;
         }
    }

    receive(msg: EndGame) {
        
        let roomOpt = self.m_rooms.get(msg.roomId);
        require(roomOpt != null, "Room not found");
         let room = roomOpt!!;

         let feePercentage:Int=30;

        if (room.betVolume < ton("1")) {
            feePercentage = 30;
        } else if (room.betVolume < ton("5")) {
            feePercentage = 20;
        } else if (room.betVolume < ton("20")) {
            feePercentage = 10;
        } else if (room.betVolume < ton("500")) {
            feePercentage = 5;
        } else {
            feePercentage = 3;
        }


        let fee = (room.totalLocked * feePercentage) / 100;
        // The remaining prize pool (distributed among winners).
        let prizePool = room.totalLocked - fee;

        // Send the fee directly to the owner.
        send(SendParameters{
            to: self.owner,
            value: ton("0.1"),  // Minimal TON coins for gas; adjust as needed.
            // body:  Cell()    // Empty cell payload.
        });

        // Distribute winnings according to provided amounts.
        if (msg.winnerCount == 1) {
            let current = self.userWinnings.get(msg.winner1);
            let newTotal = (current != null ? current!! : 0) + prizePool;
            self.userWinnings.set(msg.winner1, newTotal);
            
        }
        


        self.m_rooms.del(msg.roomId);

        cashback(sender());
    }

    receive(msg: WithdrawWinnings) {
        let amountOpt = self.userWinnings.get(msg.user);

        require(amountOpt != null, "Amount not found");
        let amount = amountOpt!!;

        require(amount >= self.withdrawalCap, "Winnings below withdrawal cap");

        // Reset user's winnings.
        self.userWinnings.set(msg.user, 0);
        // Transfer the winnings to the user.
         send(SendParameters{
            to: self.jettonWalletAddress,
            value: JettonTransferGas,
            body: JettonTransfer{
                queryId: 42,
                amount: amount,
                destination: msg.user,
                responseDestination: msg.user,
                customPayload: null,
                forwardTonAmount: 1,
                forwardPayload: rawSlice("F")
            }.toCell()
        });
        cashback(msg.user);
    }

    get fun get_jetton_balance(): Int {

        return self.totalReceivedJettons;
    }

}
