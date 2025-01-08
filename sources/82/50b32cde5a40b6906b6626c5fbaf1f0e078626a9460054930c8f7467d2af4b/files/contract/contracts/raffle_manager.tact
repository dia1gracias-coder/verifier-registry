import "@stdlib/deploy";
import "@stdlib/ownable";
message CreatePot {
    potId: Int;
    entryFee: Int as uint128;
}
message JoinPot {
    potId: Int;
}
message ClosePot {
    potId: Int;
}
struct PotInfo {
    potId: Int;
    totalAmount: Int as uint128;
    entryFee: Int as uint128;
    participants: map<Int, Address>; // Cyclic array implementation
    participantsLength: Int as uint8;
    participantsStart: Int as uint8;
    winner: Address;
    closed: Bool;
}

contract RaffleManager with Deployable, Ownable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years
    owner: Address;
    pots: map<Int, PotInfo>;
    init(initialOwner: Address){
        self.owner = initialOwner;
    }

    receive(msg: CreatePot) {
        self.requireOwner();
        require(!self.pots.exists(msg.potId), "Pot ID already exists");
        self.pots.set(msg.potId, PotInfo{
            potId: msg.potId,
            totalAmount: 0,
            entryFee: msg.entryFee,
            participants: emptyMap(),
            participantsLength: 0,
            participantsStart: 0,
            winner: newAddress(0, 0),
            closed: false
        });
        self.notify("Pot created successfully".asComment());
    }

   receive(msg: JoinPot) {
        let ctx: Context = context();
        let potId = msg.potId;
        require(self.pots.exists(potId), "Pot does not exist");
        let pot = self.pots.get(potId)!!;
        require(ctx.value >= pot.entryFee, "Insufficient entry fee");

        let participantIndex = pot.participantsLength;
        pot.participants.set(participantIndex, ctx.sender);
        pot.participantsLength = pot.participantsLength + 1;
        pot.totalAmount += ctx.value;
        self.pots.set(potId, pot);
    }

    receive(msg: ClosePot) {
        self.requireOwner();
        let potId = msg.potId;
        require(self.pots.exists(potId), "Pot does not exist");
        let pot = self.pots.get(potId)!!;
        require(!pot.closed, "Pot is already closed");

        pot.closed = true;
        self.pots.set(potId, pot);

        self.notify("Pot closed successfully".asComment());
    }

    get fun potInfo(potId: Int): PotInfo {
        if (self.pots.exists(potId)) {
            return self.pots.get(potId)!!;
        } else {
            return PotInfo{
                potId: potId,
                totalAmount: 0,
                entryFee: 0,
                participants: emptyMap(),
                participantsLength: 0,
                participantsStart: 0,
                winner: newAddress(0, 0),
                closed: false
            };
        }
    }

    get fun participant(potId: Int, index: Int): Address {
        require(self.pots.exists(potId), "Pot does not exist");
        let pot = self.pots.get(potId)!!;
        require(index >= 0 && index < pot.participantsLength, "Index out of bounds");
        return pot.participants.get(index)!!;
    }
}