import "@stdlib/deploy";
import "@stdlib/ownable";
import "./native";
import "./messages";
import "./structs";

extends fun getHash(self: Address): Int {
	let parsed: ParsedAddress = parseAddress(self);
	require(parsed.wc == 0, "Only basechain is supported");
	return parsed.hash;
}

fun getTEP74TranserMessage(amount: Int, to: Address): Cell {
	return beginCell()                          //TEP74:
		.storeUint(0xf8a7ea5, 32)               //op::code
		.storeUint(now_lt(), 64)                //query_id
		.storeCoins(amount)                     //jetton_amount
		.storeAddress(to)                       //owner_address
		.storeAddress(to)                       //response_address
		.storeInt(0, 1)                         //custom_payload
		.storeCoins(1)                          //forward_amount
		.storeInt(0, 1)                         //forward_payload
		.endCell();
}

const ROUND_PRESEED:	Int = 4;
const ROUND_ECOSYSTEM:	Int = 5;
const ROUND_LIQUIDITY:	Int = 7;
const ROUND_DAO:		Int = 8;

contract PunkVesting with Deployable, Ownable {
	owner: Address;
	jettonWallet: Address?;

	holdersCount: Int as uint8;
	holdersMap: map<Int, Balance>;

	periodsCount: Int as uint8;
	periodsMap: map<Int, Period>;
	percentFactor: Int;

	vestingRound: Int as uint8;
	const minCoinsForTranser: Int = 70000000;

	init() {
		self.owner = sender();

		self.holdersCount = 0;
		self.holdersMap = emptyMap();

		self.periodsCount = 0;
		self.periodsMap = emptyMap();
		self.percentFactor = 100;
		self.vestingRound = 0;
	}

    receive(msg: SetVestingRound) {
        self.requireOwner();
        require(self.vestingRound == 0, "Round already set");

        self.vestingRound = msg.vestingRound;
        self.periodsCount = 19;
		self.percentFactor = 100;
		self.periodsMap.set(0, Period{startTime: 1688495400, percent: 10}); //10% 04.07.2023 18:30:00 UTC+0
		self.periodsMap.set(1, Period{startTime: 1691173800, percent: 15}); //5% 04.08.2023 18:30:00 UTC+0
		self.periodsMap.set(2, Period{startTime: 1693852200, percent: 20}); //5% 04.09.2023 18:30:00 UTC+0
		self.periodsMap.set(3, Period{startTime: 1696444200, percent: 25}); //5% 04.10.2023 18:30:00 UTC+0
		self.periodsMap.set(4, Period{startTime: 1699122600, percent: 30}); //5% 04.11.2023 18:30:00 UTC+0
		self.periodsMap.set(5, Period{startTime: 1701714600, percent: 35}); //5% 04.12.2023 18:30:00 UTC+0
		self.periodsMap.set(6, Period{startTime: 1704393000, percent: 40}); //5% 04.01.2024 18:30:00 UTC+0
		self.periodsMap.set(7, Period{startTime: 1707071400, percent: 45}); //5% 04.02.2024 18:30:00 UTC+0
		self.periodsMap.set(8, Period{startTime: 1709577000, percent: 50}); //5% 04.03.2024 18:30:00 UTC+0
		self.periodsMap.set(9, Period{startTime: 1712255400, percent: 55}); //5% 04.04.2024 18:30:00 UTC+0
		self.periodsMap.set(10, Period{startTime: 1714847400, percent: 60}); //5% 04.05.2024 18:30:00 UTC+0
		self.periodsMap.set(11, Period{startTime: 1717525800, percent: 65}); //5% 04.06.2024 18:30:00 UTC+0
		self.periodsMap.set(12, Period{startTime: 1720117800, percent: 70}); //5% 04.07.2024 18:30:00 UTC+0
		self.periodsMap.set(13, Period{startTime: 1722796200, percent: 75}); //5% 04.08.2024 18:30:00 UTC+0
		self.periodsMap.set(14, Period{startTime: 1725474600, percent: 80}); //5% 04.09.2024 18:30:00 UTC+0
		self.periodsMap.set(15, Period{startTime: 1728066600, percent: 85}); //5% 04.10.2024 18:30:00 UTC+0
		self.periodsMap.set(16, Period{startTime: 1730745000, percent: 90}); //5% 04.11.2024 18:30:00 UTC+0
		self.periodsMap.set(17, Period{startTime: 1733337000, percent: 95}); //5% 04.12.2024 18:30:00 UTC+0
		self.periodsMap.set(18, Period{startTime: 1736015400, percent: 100}); //5% 04.01.2025 18:30:00 UTC+0

    }

	receive (msg: PutHoldersMsg) {
		self.requireOwner();
		require(self.holdersCount == 0, "Holders map already set");

		let i: Int = 0;
		repeat (msg.count) {
			let curHolder: HolderDto = msg.holders.get(i)!!;
			let key: Int = curHolder.address.getHash();
			let currentBalance: Int = curHolder.starting;
			if (self.vestingRound == ROUND_PRESEED) {
				currentBalance = currentBalance - 33350000000000;
			}
			if (self.vestingRound == ROUND_ECOSYSTEM) {
				currentBalance = currentBalance - 3071250000000000;
			}
			if (self.vestingRound == ROUND_LIQUIDITY) {
				currentBalance = currentBalance - 1500000000000000;
			}
			if (self.vestingRound == ROUND_DAO) {
				currentBalance = currentBalance - 225000000000000;
			}

			let balance: Balance = Balance{starting: curHolder.starting, current: currentBalance};
			self.holdersMap.set(key, balance);
			self.holdersCount = self.holdersCount + 1;
			i = i + 1;
		}
	}

	receive(msg: SetOwnerWallet) {
		self.requireOwner();
		require(self.jettonWallet == null, "Jetton wallet already set");
		self.jettonWallet = msg.address;
	}

	receive() {
		require(self.jettonWallet != null,
			"Rejected by reason: jetton wallet is not set");
		require(self.vestingRound != 0, "Periods is not set");

		let context: Context = context();
		let inCoins: Int = context().value;
		require(self.minCoinsForTranser<=inCoins,
			"Rejected by reason: the minimum volume is not enough");

		let sender: Address = context.sender;
		let key: Int = sender.getHash();
		let balance: Balance? = self.getHolderBalance(key);
		require(balance != null,
			"Rejected by reason: unknown wallet");

		let onPeriod: Int = self.getAvailableOnPeriod((balance!!).starting);
		let availableCount: Int = onPeriod - ((balance!!).starting - (balance!!).current);

		require(availableCount > 0,
			"There are no tokens available for withdrawal at the moment.");

		let body: Cell = getTEP74TranserMessage(availableCount, sender);

		send(SendParameters{
			to: self.jettonWallet!!,
			body: body,
			value: 40000000,
			mode: SendPayGasSeparately
		});

		self.holdersMap.set(key, Balance{
			starting: (balance!!).starting,
			current: (balance!!).current - availableCount
		});
	}

	receive(msg: TopupBalance) {
		self.requireOwner();
	}

	fun getCurrentPeriod_internal(): Period? {
		require(self.vestingRound != 0, "Periods is not set");
		let now: Int = now();

		let i: Int = self.periodsCount - 1;
		if (now < (self.periodsMap.get(0)!!).startTime) {
			return null;
		}

		let currentPeriod: Period = self.periodsMap.get(i)!!;
		while (i >= 1) {
			currentPeriod = self.periodsMap.get(i)!!;
			if (now > currentPeriod.startTime) {
				return currentPeriod;
			}
			else {
				i = i - 1;
			}
		}

		currentPeriod = self.periodsMap.get(0)!!;
		return currentPeriod;
	}

	fun getHolderBalance(key: Int): Balance? {
		return self.holdersMap.get(key);
	}

	fun getAvailableOnPeriod(starting: Int): Int {
		let currentPeriod: Period? = self.getCurrentPeriod_internal();
		if (currentPeriod == null) {
			return 0;
		}

		return muldiv(starting, (currentPeriod!!).percent, self.percentFactor);
	}

	fun convertToBalance(dto: HolderDto): Balance {
		return Balance{starting: dto.starting, current:dto.starting};
	}

	fun isKnownHolder(key: Int): Bool {
		return self.holdersMap.get(key) != null;
	}

	fun getHolderInfo_internal(adr: Address): HolderInfo {
		let key: Int = adr.getHash();
		let balance: Balance = self.holdersMap.get(key)!!;

		let onPeriod: Int = self.getAvailableOnPeriod(balance.starting);
		let available: Int = onPeriod - (balance.starting - balance.current);

		return HolderInfo{
			common: balance.starting,
			current: balance.current,
			available: available,
			currentPeriod: self.getCurrentPeriod_internal()
		};
	}

	get fun getHolderInfo(adr: Address): HolderInfo {
        return self.getHolderInfo_internal(adr);
    }

    get fun Periods(): PeriodsSet {
        return PeriodsSet{count: self.periodsCount, periods: self.periodsMap};
    }

    get fun AllHolders(): map<Int, Balance> {
        return self.holdersMap;
    }

    get fun JettonWallet(): Address? {
        return self.jettonWallet;
    }
}