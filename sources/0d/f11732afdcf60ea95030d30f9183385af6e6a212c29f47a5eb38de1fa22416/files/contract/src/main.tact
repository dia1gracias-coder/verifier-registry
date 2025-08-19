import "@stdlib/ownable";
import "@stdlib/deploy";

message(0x1) Enter {}

message(0x2) Draw {}

contract LotteryFortuneSun with Ownable, Deployable {
	owner: Address;

// networkFee in TON
	networkFee: Int;

// minAmount in TON
	minAmount: Int;

// prizePool in TON
	prizePool: Int;

// participantsMap
	participants: map<Address, Int as int128>;

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
		self.networkFee = ton("0.006");
		self.owner = _owner;
		self.minAmount = ton("0.5");
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
		require(self.participantsCount > 0, "Participants empty");

		let jackpotPart: Int = self.jackpot != null ? (self.prizePool * self.jackpotPercent / 100) : 0;
		let ownerFeePart: Int = self.prizePool * self.ownerPercent / 100;
		let winnerPart: Int = self.prizePool - jackpotPart - ownerFeePart;

		// 0 - prizePool - 1
		let r: Int = random(0, self.prizePool);
		let acc: Int = 0;
		let winnerAddress: Address? = null;

		foreach (addr, stake in self.participants) {
			acc += stake;
			if (r <= acc && winnerAddress == null) {
				winnerAddress = addr;
			}
		}

		require(winnerAddress != null, "Winner not found. Retry!");


		send(SendParameters { to: winnerAddress!!, value: winnerPart });
		self.lastWinner = winnerAddress;

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
		require(context().value >= self.minAmount, "Amount must more or equal than minAmount");
		require(self.participantsCount < self.maxParticipants, "Pool is full");

		self.participantsCount += 1;
		self.participants.set(sender(), context().value - self.networkFee);
		self.prizePool += context().value - self.networkFee;
	}

// Draw
	receive(msg: Draw) {
		self.requireOwner();
		self.draw();
	}

	get fun isExistsParticipants(address: Address): Bool {
		return self.participants.exists(address)
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

	get fun minAmount(): Int {
		return self.minAmount;
	}

	get fun prizePool(): Int {
		return self.prizePool;
	}

	get fun participants(): map<Address, Int as int128> {
		return self.participants;
	}

	get fun networkFee(): Int {
		return self.networkFee;
	}
}