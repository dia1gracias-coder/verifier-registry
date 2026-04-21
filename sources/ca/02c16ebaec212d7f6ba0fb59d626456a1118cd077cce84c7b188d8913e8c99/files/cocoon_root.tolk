
import "@stdlib/gas-payments"
import "opcodes"
import "errors"
import "messages"
import "storage"

// === Root-specific Union Types ===

type RootMessage =
    | AddWorkerType
    | DelWorkerType
    | AddModelType
    | DelModelType
    | AddProxyType
    | DelProxyType
    | RegisterProxy
    | UnregisterProxy
    | UpdateProxy
    | ChangeFees
    | ChangeParams
    | UpgradeContracts
    | UpgradeCode
    | ResetRoot
    | UpgradeFull
    | ChangeOwner

// === Helper Functions ===

fun validateProxyAddr(addr: slice) {
    // Validate: type(1) + len(7) + addr(len*8)
    // Clone the slice to avoid consuming it
    var tempAddr = addr;
    assert (tempAddr.loadUint(1) == 0) throw ERROR_MSG_FORMAT_MISMATCH;
    val addrLen = tempAddr.loadUint(7);
    tempAddr.skipBits(addrLen * 8);
    tempAddr.assertEnd();
}

// === Message Handler ===

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }

    val toLeaveOnBalance = max(
        contract.getOriginalBalance() - in.valueCoins + contract.getStorageDuePayment(),
        STORAGE_ESTIMATE
    );
    reserveToncoinsOnBalance(toLeaveOnBalance, RESERVE_MODE_EXACT_AMOUNT);

    val op = in.body.preloadUint(32);
    if (op == OP_DO_NOT_PROCESS) {
        return;
    }
    val queryHeader = lazy QueryHeader.fromSlice(in.body, {assertEndAfterReading: false});
    val queryId = queryHeader.queryId;

    var storage = lazy RootStorage.load();
    // Save before ChangeOwner may modify it — excesses go to the original owner
    val ownerAddress = storage.ownerAddress;

    // Only owner can perform operations
    assert (in.senderAddress == storage.ownerAddress) throw ERROR_EXPECTED_MESSAGE_FROM_OWNER;

    var data = lazy storage.data.load();
    var params = lazy storage.params.load();

    // Match on message type
    val msg = lazy RootMessage.fromSlice(in.body);


    match (msg) {
        AddWorkerType => {
            data.workerHashes.set(msg.workerHash, ());
        },

        DelWorkerType => {
            data.workerHashes.delete(msg.workerHash);
        },

        AddModelType => {
            data.modelHashes.set(msg.modelHash, ());
        },

        DelModelType => {
            data.modelHashes.delete(msg.modelHash);
        },

        AddProxyType => {
            data.proxyHashes.set(msg.proxyHash, ());
        },

        DelProxyType => {
            data.proxyHashes.delete(msg.proxyHash);
        },

        RegisterProxy => {
            // Validate and extract hash from proxyInfo
            validateProxyAddr(msg.proxyInfo);

            data.lastProxySeqno += 1;
            data.registeredProxies.set(data.lastProxySeqno, msg.proxyInfo);
        },

        UnregisterProxy => {
            data.registeredProxies.delete(msg.seqno);
        },

        UpdateProxy => {
            // Validate new address format
            validateProxyAddr(msg.proxyAddr);

            // Get existing entry and extract hash
            val r = data.registeredProxies.get(msg.seqno);
            assert (r.isFound) throw ERROR_UNKNOWN_PROXY_TYPE;

            // Create new entry
            data.registeredProxies.set(msg.seqno, msg.proxyAddr);
        },

        ChangeFees => {
            params.paramsVersion += 1;
            params.pricePerToken = msg.pricePerToken;
            params.workerFeePerToken = msg.workerFeePerToken;
        },

        ChangeParams => {
            params.paramsVersion += 1;
            params.pricePerToken = msg.pricePerToken;
            params.workerFeePerToken = msg.workerFeePerToken;
            params.proxyDelayBeforeClose = msg.proxyDelayBeforeClose;
            params.clientDelayBeforeClose = msg.clientDelayBeforeClose;
            params.minProxyStake = msg.minProxyStake;
            params.minClientStake = msg.minClientStake;
        },

        UpgradeContracts => {
            params.paramsVersion += 1;
            params.proxyScCode = msg.proxyCode;
            params.workerScCode = msg.workerCode;
            params.clientScCode = msg.clientCode;
        },

        UpgradeCode => {
            contract.setCodePostponed(msg.newCode);
            sendExcesses(ownerAddress, queryId);
            return;  // Don't save storage when upgrading code
        },

        ResetRoot => {
            // Reset all maps
            data.proxyHashes = [];
            data.workerHashes = [];
            data.modelHashes = [];
            data.registeredProxies = [];
        },

        UpgradeFull => {
            // Full upgrade: replace both data and code
            contract.setData(msg.newData);
            contract.setCodePostponed(msg.newCode);
            sendExcesses(storage.ownerAddress, msg.queryId);
            return;  // Don't save storage, we just replaced it
        },
        
        ChangeOwner => {
            storage.ownerAddress = msg.newOwnerAddress;
        }
    }

    sendExcesses(ownerAddress, queryId);

    // Save updated data
    storage.data = data.toCell();
    storage.params = params.toCell();
    storage.version += 1;
    storage.save();
}

// === Get Methods ===

get fun last_proxy_seqno(): int {
    val storage = RootStorage.load();
    val data = storage.data.load();
    return data.lastProxySeqno;
}

struct CocoonDataReply {
    version: uint32
    lastProxySeqno: uint32
    paramsVersion: uint32
    uniqueId: uint32
    isTest: int
    pricePerToken: coins
    workerFeePerToken: coins
    minProxyStake: coins
    minClientStake: coins
    ownerAddress: slice
}

get fun get_cocoon_data(): CocoonDataReply {
    val storage = RootStorage.load();
    val data = storage.data.load();
    val params = storage.params.load();

    return {
        version: storage.version,
        lastProxySeqno: data.lastProxySeqno,
        paramsVersion: params.paramsVersion,
        uniqueId: params.uniqueId,
        isTest: params.isTest ? 1 : 0,
        pricePerToken: params.pricePerToken,
        workerFeePerToken: params.workerFeePerToken,
        minProxyStake: params.minProxyStake,
        minClientStake: params.minClientStake,
        ownerAddress: storage.ownerAddress as slice,
    };
}

struct CocoonParamsReply {
    paramsVersion: uint32
    uniqueId: uint32
    isTest: int
    pricePerToken: coins
    workerFeePerToken: coins
    cachedTokensPriceMultiplier: uint32
    reasoningTokensPriceMultiplier: uint32
    proxyDelayBeforeClose: uint32
    clientDelayBeforeClose: uint32
    minProxyStake: coins
    minClientStake: coins
    proxyScCodeHash: uint256
    workerScCodeHash: uint256
    clientScCodeHash: uint256
}

get fun get_cur_params(): CocoonParamsReply {
    val storage = RootStorage.load();
    val params = storage.params.load();

    return {
        paramsVersion: params.paramsVersion,
        uniqueId: params.uniqueId,
        isTest: params.isTest ? 1 : 0,
        pricePerToken: params.pricePerToken,
        workerFeePerToken: params.workerFeePerToken,
        cachedTokensPriceMultiplier: params.cachedTokensPriceMultiplier,
        reasoningTokensPriceMultiplier: params.reasoningTokensPriceMultiplier,
        proxyDelayBeforeClose: params.proxyDelayBeforeClose,
        clientDelayBeforeClose: params.clientDelayBeforeClose,
        minProxyStake: params.minProxyStake,
        minClientStake: params.minClientStake,
        proxyScCodeHash: params.proxyScCode != null ? params.proxyScCode!.hash() : 0,
        workerScCodeHash: params.workerScCode != null ? params.workerScCode!.hash() : 0,
        clientScCodeHash: params.clientScCode != null ? params.clientScCode!.hash() : 0,
    };
}

get fun proxy_hash_is_valid(hash: uint256): bool {
    val storage = RootStorage.load();
    val data = storage.data.load();
    return data.proxyHashes.exists(hash);
}

get fun worker_hash_is_valid(hash: uint256): bool {
    val storage = RootStorage.load();
    val data = storage.data.load();
    return data.workerHashes.exists(hash);
}

get fun model_hash_is_valid(hash: uint256): bool {
    val storage = RootStorage.load();
    val data = storage.data.load();
    return data.modelHashes.exists(hash);
}
