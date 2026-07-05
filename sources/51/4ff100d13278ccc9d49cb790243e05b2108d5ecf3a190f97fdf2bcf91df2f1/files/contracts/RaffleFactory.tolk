// OpenRaff v1 — Factory contract.
//
// Deploys immutable Raffle instances at deterministic addresses and stamps the
// protocol parameters (fee, draw_timeout, treasury) into each instance. See
// docs/versions/v1/messages.md §4.

import "../gen/Raffle.code"
import "common"
import "messages"

contract RaffleFactory {
    author: "OpenRaff"
    version: "0.1.0"
    description: "OpenRaff factory: deploys immutable raffle instances"
    storage: FactoryStorage
    incomingMessages: FactoryMessage
}

type FactoryMessage =
    | CreateRaffle
    | SetParams

fun onInternalMessage(in: InMessage) {
    val msg = lazy FactoryMessage.fromSlice(in.body);

    match (msg) {
        CreateRaffle => handleCreateRaffle(in.valueCoins, msg),
        SetParams => handleSetParams(in.senderAddress, msg),
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

fun handleCreateRaffle(msgValue: coins, msg: CreateRaffle) {
    var fs = FactoryStorage.load();
    val config = msg.config.load();

    // Validate the organizer-provided configuration.
    assert (config.softCap > 0 && config.softCap <= config.hardCap) throw Errors.InvalidConfig;
    assert (config.ticketPrice > 0) throw Errors.InvalidConfig;
    assert (
        blockchain.now() <= config.saleStart && config.saleStart < config.saleDeadline
    ) throw Errors.InvalidConfig;
    val prizeCount = countPrizes(config.prizes);
    assert (prizeCount > 0) throw Errors.InvalidConfig;

    val raffleId = fs.raffleCount;

    // Force-add the organizer's ed25519 key as the fallback publisher.
    var publishers = msg.publishers;
    publishers.set(msg.organizerPubkey, 1);

    val meta: RaffleMeta = {
        raffleId,
        factory: contract.getAddress(),
        protocolFeeBps: fs.protocolFeeBps,
        drawTimeout: fs.drawTimeout,
        treasury: fs.treasury,
        config: msg.config,
        publishers,
        prizeCount: prizeCount as uint32,
    };

    val runtime: RaffleRuntime = {
        totalCollected: 0,
        ticketsSold: 0,
        salesClosedAt: 0,
        targetRound: 0,
        randomness: 0,
        drandSignature: null,
        drawCounter: 0,
        winnersDrawn: 0,
        jettonWallet: null,
    };

    val maps: RaffleMaps = {
        ledgerByIndex: [],
        participants: [],
        winners: [],
        drawSwap: [],
    };

    val initStorage: RaffleStorage = {
        status: STATUS_SCHEDULED,
        meta: meta.toCell(),
        runtime: runtime.toCell(),
        maps: maps.toCell(),
    };

    // Forward the incoming value (minus a small factory-side buffer) to fund
    // the new instance's storage.
    assert (msgValue > GAS_RESERVE) throw Errors.InsufficientValue;
    val stateInit: ContractState = { code: raffleCompiledCode(), data: initStorage.toCell() };
    val instanceAddr = (AutoDeployAddress { stateInit }).calculateAddress();
    val deployMsg = createMessage({
        bounce: BounceMode.NoBounce,
        value: msgValue - GAS_RESERVE,
        dest: { stateInit },
    });
    deployMsg.send(SEND_MODE_REGULAR);

    fs.raffleCount = raffleId + 1;
    fs.save();

    emitEvent(EvRaffleCreated {
        raffleId,
        instance: instanceAddr,
        organizer: config.organizer,
        paymentJetton: config.paymentJetton,
    });
}

fun handleSetParams(senderAddress: address, msg: SetParams) {
    var fs = FactoryStorage.load();
    assert (senderAddress == fs.owner) throw Errors.NotOwner;

    fs.protocolFeeBps = msg.protocolFeeBps;
    fs.drawTimeout = msg.drawTimeout;
    fs.treasury = msg.treasury;
    fs.save();
}

// --------------------------------------------------------------------------
// Get methods
// --------------------------------------------------------------------------

// (protocol_fee_bps, draw_timeout, treasury, raffle_count, owner)
get fun factoryData(): (int, int, address, int, address) {
    val fs = FactoryStorage.load();
    return (fs.protocolFeeBps, fs.drawTimeout, fs.treasury, fs.raffleCount, fs.owner);
}
