tolk 1.2

import "@stdlib/gas-payments"
import "@stdlib/tvm-dicts"

// Error codes
const ERR_NOT_ADMIN: int = 401;
const ERR_EMPTY_NAME: int = 402;
const ERR_AGENT_NOT_FOUND: int = 404;

// Storage layout:
// admin(address) + agentCount(uint32) + ref(agentCode cell) + agents(dict: uint32 index → address)

struct Storage {
    admin: address
    agentCount: uint32
    agentCode: cell
    agents: dict
}

fun Storage.load() {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

// Message structs (32-bit opcodes)
struct (0x00000010) RegisterAgent {
    queryId: uint64
    name: uint256
    capabilitiesHash: uint256
    hashesRef: cell
}

struct (0x00000015) AddReputationRequest {
    queryId: uint64
    agentIndex: uint32
    amount: uint32
}

type AllowedMessage =
    | RegisterAgent
    | AddReputationRequest;

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        RegisterAgent => {
            var storage = lazy Storage.load();

            // Verify name is not empty
            assert(msg.name != 0) throw ERR_EMPTY_NAME;

            // Parse hashesRef to get endpointHash and metadataHash
            var hashesSlice = msg.hashesRef.beginParse();
            val endpointHash = hashesSlice.loadUint(256);
            val metadataHash = hashesSlice.loadUint(256);

            // Build hashes cell
            val hashesCell = beginCell()
                .storeUint(endpointHash, 256)
                .storeUint(metadataHash, 256)
                .endCell();

            // Build data cell (name + capHash + ref(hashesCell))
            val dataCell = beginCell()
                .storeUint(msg.name, 256)
                .storeUint(msg.capabilitiesHash, 256)
                .storeRef(hashesCell)
                .endCell();

            // Build identity initial data cell (same layout as agentIdentityConfigToCell)
            val identityData = beginCell()
                .storeAddress(in.senderAddress)          // owner = sender
                .storeAddress(contract.getAddress())    // registry = this contract
                .storeBool(true)                          // active = true
                .storeUint(0, 32)                         // reputation = 0
                .storeUint(blockchain.now(), 32)          // registeredAt
                .storeUint(blockchain.now(), 32)          // updatedAt
                .storeRef(dataCell)                       // data ref
                .endCell();

            // Deploy child contract using AutoDeployAddress
            val deployDest: AutoDeployAddress = {
                workchain: 0,
                stateInit: {
                    code: storage.agentCode,
                    data: identityData
                }
            };
            val agentAddr = deployDest.calculateAddress();

            // Send init message to child
            createMessage({
                bounce: BounceMode.NoBounce,
                dest: deployDest,
                value: ton("0.02"),
                body: beginCell()
                    .storeUint(0x01, 32)
                    .storeUint(msg.queryId, 64)
                    .endCell()
                    .beginParse()
            }).send(SEND_MODE_REGULAR);

            // Store agent address in dict
            val agentIndex = storage.agentCount;
            storage.agents.uDictSet(32, agentIndex, beginCell().storeAddress(agentAddr).endCell().beginParse());

            // Increment count and save
            storage.agentCount = agentIndex + 1;
            storage.save();

            // Return excess TON to sender
            createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: beginCell()
                    .storeUint(0xd53276db, 32)  // op: excesses
                    .storeUint(msg.queryId, 64)
                    .endCell()
                    .beginParse()
            }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }

        AddReputationRequest => {
            var storage = lazy Storage.load();

            // Verify sender is admin
            assert(in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;

            // Look up agent address by index
            var (agentSlice, found) = storage.agents.uDictGet(32, msg.agentIndex);
            assert(found) throw ERR_AGENT_NOT_FOUND;

            val agentAddr = agentSlice!.loadAddress();

            // Forward AddReputation (op 0x05) message to the agent
            createMessage({
                bounce: BounceMode.NoBounce,
                dest: agentAddr,
                value: ton("0.01"),
                body: beginCell()
                    .storeUint(0x05, 32)
                    .storeUint(msg.queryId, 64)
                    .storeUint(msg.amount, 32)
                    .endCell()
                    .beginParse()
            }).send(SEND_MODE_REGULAR);

            // Return excess TON to sender
            createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: beginCell()
                    .storeUint(0xd53276db, 32)  // op: excesses
                    .storeUint(msg.queryId, 64)
                    .endCell()
                    .beginParse()
            }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }

        else => {
            // Ignore empty messages (simple transfers)
        }
    }
}

get fun getAgentCount(): int {
    val storage = Storage.load();
    return storage.agentCount;
}

get fun getAgentAddress(index: int): address {
    val storage = Storage.load();
    var (agentSlice, found) = storage.agents.uDictGet(32, index);
    assert(found) throw ERR_AGENT_NOT_FOUND;
    return agentSlice!.loadAddress();
}

get fun getAdmin(): address {
    val storage = Storage.load();
    return storage.admin;
}
