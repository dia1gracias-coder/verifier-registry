import "@stdlib/ownable";
import "@stdlib/deploy";

message(0x1) Enter {}

message(0x2) Draw {}

contract LotteryFortuneSun with Ownable, Deployable {
	owner: Address;
	networkFee: Int; // networkFee in TON
	minAmount: Int; // minAmount in TON
	prizePool: Int; // prizePool in TON

	participants: map<Address, Int as int128>; // participantsMap
	participantsCount: Int as int8; // participantsCount
	maxParticipants: Int as int8; // maxParticipants
	minParticipants: Int as int8; // minParticipants for draw

	lastWinner: Address?; // lastWinner address
	jackpot: Address?; // jackpot address pool

	jackpotPercent: Int as int32; // jackpot pool percent
	ownerPercent: Int as int32; // owner percent

	deadline: Int? as int32; // Deadline start

	init(_owner: Address, _jackpot: Address?) {
		self.owner = _owner;
		self.jackpot = _jackpot;

		self.networkFee = ton("0.006");
		self.minAmount = ton("0.5");
		self.prizePool = ton("0");

		self.participants = emptyMap();
		self.participantsCount = 0;
		self.maxParticipants = 32;
		self.minParticipants = 2;

		self.jackpotPercent = 10;
		self.ownerPercent = 10;
	}

	fun draw() {
		self.requireOwner();
		require(self.participantsCount >= self.minParticipants, "Not enough participants");
		require(self.deadline != null, "Deadline is not set");
		require(now() >= self.deadline!!, "Early draw");

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
		self.deadline = null;
	}

// Enter into the pool
	receive(msg: Enter) {
		require(self.participants.get(context().sender) == null, "Exist participants");
		require(context().value >= self.minAmount, "Amount must more or equal than minAmount");
		require(self.participantsCount < self.maxParticipants, "Pool is full");
		require(self.deadline == null || now() < self.deadline!!, "Pool is closed");

		self.participantsCount += 1;
		self.participants.set(sender(), context().value - self.networkFee);
		self.prizePool += context().value - self.networkFee;

		if(self.participantsCount == self.minParticipants) {
			self.deadline = now() + 10;
		}
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

	get fun deadline(): Int? {
		return self.deadline;
	}
}