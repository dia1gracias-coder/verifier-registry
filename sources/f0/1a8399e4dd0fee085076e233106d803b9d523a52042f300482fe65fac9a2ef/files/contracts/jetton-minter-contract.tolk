import "@stdlib/gas-payments"
import "errors"
import "jetton-utils"
import "messages"
import "storage"
import "fees-management"

// InternalTransferStep opcode from messages.tolk
const OP_INTERNAL_TRANSFER_STEP = 0x178d4519

type AllowedMessageToMinter =
    | MintNewJettons
    | BurnNotificationForMinter
    | RequestWalletAddress
    | ChangeMinterAdmin
    | ChangeMinterContent

// Handle bounced mint transfers to keep totalSupply consistent.
// We only care about bounced InternalTransferStep coming from mint
// (mint uses transferInitiator = null / addr_none).
fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();

    var s = in.bouncedBody;

    // Need at least opcode
    if (s.remainingBitsCount() < 32) {
        return;
    }

    // Check opcode without consuming it first
    if (s.preloadUint(32) != OP_INTERNAL_TRANSFER_STEP) {
        return;
    }

    // Consume opcode + queryId
    s.loadUint(32);
    if (s.remainingBitsCount() < 64) {
        return;
    }
    s.loadUint(64); // queryId (unused)

    // Defensive parse for coins (VarUInteger 16):
    // first 4 bits = length in bytes (0..16), then length*8 bits value.
    if (s.remainingBitsCount() < 4) {
        return;
    }
    val lenBytes = s.preloadUint(4);
    if (lenBytes > 16) { // sane bound for coins
        return;
    }
    if (s.remainingBitsCount() < (4 + lenBytes * 8)) {
        return;
    }
    val jettonAmount = s.loadCoins();

    // Next field is transferInitiator: address?
    // For mint it's addr_none, which starts with 2 bits == 0b00.
    if (s.remainingBitsCount() < 2) {
        return;
    }
    val addrTag = s.preloadUint(2);
    if (addrTag != 0) {
        // Not addr_none -> not a mint bounce -> ignore
        return;
    }

    // Rollback totalSupply increase done in MintNewJettons handler
    var storage = lazy MinterStorage.load();
    if (storage.totalSupply >= jettonAmount) {
        storage.totalSupply -= jettonAmount;
    } else {
        // Shouldn't happen, but never underflow
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

            // Prevent underflow if a malicious/invalid burn is attempted
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
            // Use bitwise OR for send-mode flags
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

        MintNewJettons => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;

            var internalTransferMsg = lazy msg.internalTransferMsg.load();

            // Mint must use transferInitiator = null (addr_none)
            assert (internalTransferMsg.transferInitiator == null) throw ERR_INVALID_PAYLOAD;

            // Optional sanity check (reject zero-mints)
            assert (internalTransferMsg.jettonAmount > 0) throw ERR_INVALID_PAYLOAD;

            storage.totalSupply += internalTransferMsg.jettonAmount;
            storage.save();

            val deployMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(msg.mintRecipient, contract.getAddress(), storage.jettonWalletCode),
                value: msg.tonAmount,
                body: msg.internalTransferMsg,  // a newly-deployed wallet contract will immediately handle it
            });
            deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        ChangeMinterAdmin => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            storage.adminAddress = msg.newAdminAddress;
            storage.save();
        }

        ChangeMinterContent => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            storage.content = msg.newContent;
            storage.save();
        }

        else => {
            // ignore empty messages, "wrong opcode" for others
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
        mintable: true,
        adminAddress: storage.adminAddress,
        jettonContent: storage.content,
        jettonWalletCode: storage.jettonWalletCode,
    }
}

get fun get_wallet_address(ownerAddress: address): address {
    val storage = lazy MinterStorage.load();
    return calcAddressOfJettonWallet(ownerAddress, contract.getAddress(), storage.jettonWalletCode);
}
