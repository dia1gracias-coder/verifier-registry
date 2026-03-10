import "@stdlib/gas-payments"
import "errors"
import "jetton-utils"
import "messages"
import "storage"
import "fees-management"
import "constants"

const OP_INTERNAL_TRANSFER_STEP = 0x178d4519

type AllowedMessageToMinter =
    | MintNewJettons
    | MintRewards
    | BurnNotificationForMinter
    | RequestWalletAddress
    | ChangeMinterAdmin
    | ChangeMinterContent
    | ChangeMinterRole
    | AcceptMinterAdmin

// Handle bounced mint transfers to keep totalSupply consistent.
fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();

    var s = in.bouncedBody;

    if (s.remainingBitsCount() < 32) {
        return;
    }

    if (s.preloadUint(32) != OP_INTERNAL_TRANSFER_STEP) {
        return;
    }

    s.loadUint(32);
    if (s.remainingBitsCount() < 64) {
        return;
    }
    s.loadUint(64);

    if (s.remainingBitsCount() < 4) {
        return;
    }
    val lenBytes = s.preloadUint(4);
    if (lenBytes > 16) {
        return;
    }
    if (s.remainingBitsCount() < (4 + lenBytes * 8)) {
        return;
    }
    val jettonAmount = s.loadCoins();

    if (s.remainingBitsCount() < 2) {
        return;
    }
    val addrTag = s.preloadUint(2);
    if (addrTag != 0) {
        return;
    }

    // Rollback totalSupply on bounced mint.
    // Note: totalMintedRewards is intentionally NOT rolled back because the bounce
    // handler cannot distinguish admin mints from reward mints (both use
    // InternalTransferStep). Rolling back rewards could allow manipulation of the
    // rewards pool cap. The practical impact is minimal since bounces are rare
    // (only if recipient wallet deployment fails for an invalid address).
    var storage = lazy MinterStorage.load();
    if (storage.totalSupply >= jettonAmount) {
        storage.totalSupply -= jettonAmount;
    } else {
        storage.totalSupply = 0;
    }
    storage.save();
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToMinter.fromSlice(in.body);

    match (msg) {
        BurnNotificationForMinter => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == calcAddressOfJettonWallet(msg.burnInitiator, contract.getAddress(), storage.jettonWalletCode)) throw ERR_UNAUTHORIZED_BURN;

            assert (storage.totalSupply >= msg.jettonAmount) throw ERR_INVALID_PAYLOAD;
            storage.totalSupply -= msg.jettonAmount;
            storage.save();

            if (msg.sendExcessesTo == null) {
                return;
            }

            val excessesMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: msg.sendExcessesTo,
                value: 0,
                body: ReturnExcessesBack {
                    queryId: msg.queryId
                }
            });
            excessesMsg.send(SEND_MODE_IGNORE_ERRORS | SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RequestWalletAddress => {
            assert (in.valueCoins > in.originalForwardFee + MINIMAL_MESSAGE_VALUE_BOUND) throw ERR_NOT_ENOUGH_AMOUNT_TO_RESPOND;

            var respondOwnerAddress: Cell<address>? = msg.includeOwnerAddress
                ? msg.ownerAddress.toCell()
                : null;

            var walletAddress: address? = null;
            if (msg.ownerAddress.getWorkchain() == BASECHAIN) {
                var storage = lazy MinterStorage.load();
                walletAddress = calcAddressOfJettonWallet(msg.ownerAddress, contract.getAddress(), storage.jettonWalletCode);
            }

            val respondMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: in.senderAddress,
                value: 0,
                body: ResponseWalletAddress {
                    queryId: msg.queryId,
                    jettonWalletAddress: walletAddress,
                    ownerAddress: respondOwnerAddress,
                }
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        // Admin-only: mint for initial allocations (treasury, team, ecosystem, liquidity)
        MintNewJettons => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            assert (msg.mintRecipient.getWorkchain() == BASECHAIN) throw ERR_WRONG_WORKCHAIN;

            var internalTransferMsg = lazy msg.internalTransferMsg.load();

            assert (internalTransferMsg.transferInitiator == null) throw ERR_INVALID_PAYLOAD;
            assert (internalTransferMsg.jettonAmount > 0) throw ERR_ZERO_AMOUNT;

            // Hard cap enforcement
            assert (storage.totalSupply + internalTransferMsg.jettonAmount <= MAX_SUPPLY) throw ERR_SUPPLY_CAP_EXCEEDED;

            storage.totalSupply += internalTransferMsg.jettonAmount;
            storage.save();

            val deployMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(msg.mintRecipient, contract.getAddress(), storage.jettonWalletCode),
                value: msg.tonAmount,
                body: msg.internalTransferMsg,
            });
            deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        // Game minter: distribute from the play-to-earn rewards pool
        MintRewards => {
            var storage = lazy MinterStorage.load();
            var extra = lazy storage.extraData.load();
            assert (in.senderAddress == extra.minterAddress) throw ERR_NOT_FROM_MINTER;
            assert (msg.mintRecipient.getWorkchain() == BASECHAIN) throw ERR_WRONG_WORKCHAIN;

            var internalTransferMsg = lazy msg.internalTransferMsg.load();

            assert (internalTransferMsg.transferInitiator == null) throw ERR_INVALID_PAYLOAD;
            assert (internalTransferMsg.jettonAmount > 0) throw ERR_ZERO_AMOUNT;

            // Rewards pool cap
            assert (extra.totalMintedRewards + internalTransferMsg.jettonAmount <= REWARDS_POOL_CAP) throw ERR_REWARDS_POOL_EXHAUSTED;

            // Global hard cap
            assert (storage.totalSupply + internalTransferMsg.jettonAmount <= MAX_SUPPLY) throw ERR_SUPPLY_CAP_EXCEEDED;

            extra.totalMintedRewards += internalTransferMsg.jettonAmount;
            storage.totalSupply += internalTransferMsg.jettonAmount;
            storage.extraData = extra.toCell();
            storage.save();

            val deployMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(msg.mintRecipient, contract.getAddress(), storage.jettonWalletCode),
                value: msg.tonAmount,
                body: msg.internalTransferMsg,
            });
            deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        // Two-step admin transfer: admin proposes a new admin
        ChangeMinterAdmin => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            assert (msg.newAdminAddress.getWorkchain() == BASECHAIN) throw ERR_WRONG_WORKCHAIN;
            var extra = lazy storage.extraData.load();
            extra.pendingAdminAddress = msg.newAdminAddress;
            storage.extraData = extra.toCell();
            storage.save();
        }

        // Two-step admin transfer: pending admin accepts the role
        AcceptMinterAdmin => {
            var storage = lazy MinterStorage.load();
            var extra = lazy storage.extraData.load();
            assert (extra.pendingAdminAddress != null) throw ERR_NO_PENDING_ADMIN;
            val pendingAdmin = extra.pendingAdminAddress!;
            assert (in.senderAddress == pendingAdmin) throw ERR_NOT_PENDING_ADMIN;
            storage.adminAddress = pendingAdmin;
            extra.pendingAdminAddress = null;
            storage.extraData = extra.toCell();
            storage.save();
        }

        ChangeMinterContent => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            storage.content = msg.newContent;
            storage.save();
        }

        // Admin changes the authorized game minter
        ChangeMinterRole => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            assert (msg.newMinterAddress.getWorkchain() == BASECHAIN) throw ERR_WRONG_WORKCHAIN;
            var extra = lazy storage.extraData.load();
            extra.minterAddress = msg.newMinterAddress;
            storage.extraData = extra.toCell();
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF
        }
    }
}

struct JettonDataReply {
    totalSupply: coins
    mintable: bool
    adminAddress: address
    jettonContent: cell
    jettonWalletCode: cell
}

get fun get_jetton_data(): JettonDataReply {
    val storage = lazy MinterStorage.load();

    return {
        totalSupply: storage.totalSupply,
        mintable: storage.totalSupply < MAX_SUPPLY,
        adminAddress: storage.adminAddress,
        jettonContent: storage.content,
        jettonWalletCode: storage.jettonWalletCode,
    }
}

get fun get_wallet_address(ownerAddress: address): address {
    val storage = lazy MinterStorage.load();
    return calcAddressOfJettonWallet(ownerAddress, contract.getAddress(), storage.jettonWalletCode);
}

struct RewardsInfoReply {
    totalMintedRewards: coins
    rewardsPoolCap: coins
}

// Transparency: anyone can query the rewards pool status
get fun get_rewards_info(): RewardsInfoReply {
    val storage = lazy MinterStorage.load();
    val extra = lazy storage.extraData.load();
    return {
        totalMintedRewards: extra.totalMintedRewards,
        rewardsPoolCap: REWARDS_POOL_CAP,
    }
}

// Query the authorized game minter address
get fun get_minter_address(): address {
    val storage = lazy MinterStorage.load();
    val extra = lazy storage.extraData.load();
    return extra.minterAddress;
}

// Query the pending admin address (null if no transfer proposed)
get fun get_pending_admin(): address? {
    val storage = lazy MinterStorage.load();
    val extra = lazy storage.extraData.load();
    return extra.pendingAdminAddress;
}
