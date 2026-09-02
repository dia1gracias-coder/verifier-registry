tolk 1.4.1

import "common/constants.tolk"
import "common/errors.tolk"
import "common/messages.tolk"
import "common/wallet-storage.tolk"

struct MinterStorage {
    totalSupply: coins;
    adminAddress: address;
    treasuryOwner: address;
    content: cell;
    jettonWalletCode: cell;
    mintingEnabled: bool;
    paused: bool;
}

fun MinterStorage.load(): MinterStorage {
    return MinterStorage.fromCell(contract.getData());
}

fun MinterStorage.save(self): void {
    contract.setData(self.toCell());
}

struct JettonDataReply {
    totalSupply: coins;
    mintable: int;
    adminAddress: address;
    content: cell;
    jettonWalletCode: cell;
}

// Dispatch union — full set of nine handled ops.
type AllowedMessageToMinter =
    | ActivateWallet
    | BlockWallet
    | MintRequest
    | BurnNotificationForMinter
    | ChangeAdmin
    | ChangeContent
    | SetMintingEnabled
    | SetGlobalPause
    | ChangeTreasuryOwner;

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToMinter.fromSlice(in.body);

    match (msg) {
        ActivateWallet => {
            val storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_ADMIN;

            // One message: deploy canonical (BLOCKED) wallet if absent, then set ALLOWED.
            // If the wallet already exists, stateInit is ignored and only the body runs.
            val activateMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: calcDeployedJettonWallet(msg.ownerAddress, contract.getAddress(), storage.jettonWalletCode),
                value: 0,
                body: SetWalletStatus { queryId: msg.queryId, newStatus: STATUS_ALLOWED },
            });
            activateMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }
        BlockWallet => {
            val storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_ADMIN;

            // No stateInit: only an already-deployed wallet is affected; if none exists,
            // the message harmlessly does nothing (NoBounce).
            val blockMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: calcDeployedJettonWallet(msg.ownerAddress, contract.getAddress(), storage.jettonWalletCode).calculateAddress(),
                value: 0,
                body: SetWalletStatus { queryId: msg.queryId, newStatus: STATUS_BLOCKED },
            });
            blockMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }
        MintRequest => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_ADMIN;
            assert (storage.mintingEnabled) throw ERR_MINTING_DISABLED;
            assert (!storage.paused) throw ERR_PAUSED;

            storage.totalSupply += msg.jettonAmount;
            storage.save();

            // No stateInit: recipient must already be activated/ALLOWED, else this bounces.
            // forwardPayload is a valid empty TEP-74 (Either Cell ^Cell): a single '0' bit.
            val mintMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(msg.toOwner, contract.getAddress(), storage.jettonWalletCode).calculateAddress(),
                value: 0,
                body: InternalTransferStep {
                    queryId: msg.queryId,
                    jettonAmount: msg.jettonAmount,
                    transferInitiator: contract.getAddress(),
                    sendExcessesTo: storage.adminAddress,
                    forwardTonAmount: msg.forwardTonAmount,
                    forwardPayload: beginCell().storeBool(false).endCell().beginParse(),
                },
            });
            mintMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }
        BurnNotificationForMinter => {
            var storage = lazy MinterStorage.load();
            assert (msg.burnInitiator == storage.treasuryOwner) throw ERR_NOT_TREASURY;
            val expectedWallet =
                calcDeployedJettonWallet(msg.burnInitiator, contract.getAddress(), storage.jettonWalletCode).calculateAddress();
            assert (in.senderAddress == expectedWallet) throw ERR_INVALID_SENDER_WALLET;

            storage.totalSupply -= msg.jettonAmount;
            storage.save();

            val excessMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: msg.sendExcessesTo,
                value: 0,
                body: ReturnExcessesBack { queryId: msg.queryId },
            });
            excessMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }
        ChangeAdmin => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_ADMIN;
            storage.adminAddress = msg.newAdmin;
            storage.save();
        }
        ChangeContent => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_ADMIN;
            storage.content = msg.newContent;
            storage.save();
        }
        SetMintingEnabled => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_ADMIN;
            storage.mintingEnabled = msg.enabled;
            storage.save();
        }
        SetGlobalPause => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_ADMIN;
            storage.paused = msg.isPaused;
            storage.save();
        }
        ChangeTreasuryOwner => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_ADMIN;
            storage.treasuryOwner = msg.newTreasuryOwner;
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw ERR_UNKNOWN_OP;
        }
    }
}

// The minter only ever sends one bounceable message: the mint internal_transfer.
type MinterBounceToHandle =
    | InternalTransferStep;

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy MinterBounceToHandle.fromSlice(in.bouncedBody);
    match (msg) {
        InternalTransferStep => {
            var storage = lazy MinterStorage.load();
            storage.totalSupply -= msg.jettonAmount;
            storage.save();
        }
    }
}

get fun get_jetton_data(): JettonDataReply {
    val storage = lazy MinterStorage.load();
    return {
        totalSupply: storage.totalSupply,
        mintable: storage.mintingEnabled && !storage.paused ? -1 : 0,
        adminAddress: storage.adminAddress,
        content: storage.content,
        jettonWalletCode: storage.jettonWalletCode,
    };
}

get fun get_treasury_owner(): address {
    val storage = lazy MinterStorage.load();
    return storage.treasuryOwner;
}

get fun get_wallet_address(ownerAddress: address): address {
    val storage = lazy MinterStorage.load();
    return calcDeployedJettonWallet(ownerAddress, contract.getAddress(), storage.jettonWalletCode).calculateAddress();
}
