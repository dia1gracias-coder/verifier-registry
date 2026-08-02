import "errors"

const BANK_POSITION_QUEUED = 1
const BANK_POSITION_PARTIALLY_FUNDED = 2
const BANK_POSITION_PAYOUT_SENT = 3

type PositionMap = map<uint64, Cell<BankPositionData>>

type QueueMap = map<uint64, uint64>

type ActivePositionMap = map<address, uint64>

type UsedPositionMap = map<uint64, bool>

struct BankPositionData {
    owner: address
    principal: coins
    multiplierBps: uint16
    targetPayout: coins
    fundedAmount: coins
    queueIndex: uint64
    createdAt: uint32
    completedAt: uint32
    status: uint8
}

struct BankStorage {
    owner: address
    treasury: address
    feeBps: uint16
    paused: bool
    headQueueIndex: uint64
    nextQueueIndex: uint64
    completedPositions: uint64 = 0
    lockedFunding: coins
    positions: PositionMap
    queue: QueueMap
    activePositions: ActivePositionMap
    usedPositionIds: UsedPositionMap
}

struct BankContractConfigView {
    owner: address
    treasury: address
    feeBps: uint16
    paused: bool
    headQueueIndex: uint64
    nextQueueIndex: uint64
    completedPositions: uint64
    principalLimit: coins
    lockedFunding: coins
}

struct BankQueueView {
    headQueueIndex: uint64
    nextQueueIndex: uint64
    openPositions: uint64
    completedPositions: uint64
    principalLimit: coins
}

struct BankAdminStateView {
    owner: address
    treasury: address
    feeBps: uint16
    paused: bool
    completedPositions: uint64
    principalLimit: coins
    lockedFunding: coins
}

fun BankStorage.load(): BankStorage {
    return BankStorage.fromCell(contract.getData());
}

fun BankStorage.save(self) {
    contract.setData(self.toCell());
}

fun BankStorage.loadPosition(self, positionId: uint64): BankPositionData {
    return self.positions.mustGet(positionId, BankErrors.PositionMissing).load();
}
