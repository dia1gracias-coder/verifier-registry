import "@stdlib/ownable";
import "@stdlib/deploy";

message(0x1) Enter {}

message(0x2) Draw {}

message DrawEvent {
	amount: Int as coins;
	recipient: Address;
}

contract LotteryFortuneSun with Ownable, Deployable {
	owner: Address;

	// entryAmount in TON
	entryAmount: Int;

	// prizePool in TON
	prizePool: Int;

	// participantsMap
	participants: map<Address, Int as int8>;

	// participantsCount
	participantsCount: Int as int8;

	// maxParticipants
	maxParticipants: Int as int8;

	// lastWinner address
	lastWinner: Address?;

	// jackpot address pool
	jackpot: Address?;

	// jackpot pool percent
	jackpotPercent: Int as int32;

	// owner percent
	ownerPercent: Int as int32;

	init(_owner: Address, _jackpot: Address) {
		self.owner = _owner;
		self.entryAmount = ton("0.1");
		self.prizePool = ton("0");
		self.maxParticipants = 10;
		self.jackpot = _jackpot;
		self.jackpotPercent = 5;
		self.ownerPercent = 5;
		self.participants = emptyMap();
		self.participantsCount = 0;
	}

	fun draw() {
		self.requireOwner();
		require(self.participantsCount > 1, "Participants empty");


		let jackpotPart: Int = self.jackpot != null ? (self.prizePool * self.jackpotPercent / 100) : 0;
		let ownerFeePart: Int = self.prizePool * self.ownerPercent / 100;
		let winnerPart: Int = self.prizePool - jackpotPart - ownerFeePart;

		let winnerIndex = random(1, self.participantsCount + 1);
		let winnerAddress: Address? = null;

		foreach(key, value in self.participants) {
			if(value == winnerIndex) {
				winnerAddress = key;
			}
		}

		require(winnerAddress != null, "Winner not found. Retry!");


		send(SendParameters { to: winnerAddress!!, value: winnerPart });
		emit(DrawEvent{ recipient: winnerAddress!!, amount: winnerPart }.toCell());
		self.lastWinner = winnerAddress;


		send(SendParameters { to: self.owner(), value: ownerFeePart });

		if(jackpotPart > 0 && self.jackpot != null) {
			send(SendParameters { to: self.jackpot!!, value: jackpotPart });
		}

		// reset pool
		self.resetPool();
	}

	fun resetPool() {
		self.participantsCount = 0;
		self.participants = emptyMap();
		self.prizePool = ton("0");
	}

	// Enter into the pool
	receive(msg: Enter) {
		require(self.participants.get(context().sender) == null, "Exist participants");
		require(context().value == self.entryAmount, "Invalid entry amount");
		require(self.participantsCount < self.maxParticipants, "Pool is full");

		self.participantsCount += 1;
		self.participants.set(sender(), self.participantsCount);
		self.prizePool += context().value;
	}

	// Draw
	receive(msg: Draw) {
		self.requireOwner();
		self.draw();
	}

	get fun participantsCount(): Int {
		return self.participantsCount;
	}

	get fun maxParticipants(): Int {
		return self.maxParticipants;
	}

	get fun lastWinner(): Address? {
		return self.lastWinner;
	}

	get fun entryAmount(): Int {
		return self.entryAmount;
	}

	get fun prizePool(): Int {
		return self.prizePool;
	}
}
