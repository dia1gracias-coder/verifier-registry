import "@stdlib/ownable";
import "@stdlib/deploy";

import "./treasury_messages.tact";
import "./treasury_constants.tact";
import "../messages/jetton";
import "../messages/pause";
import "../messages/upgrade";
import "../constants.tact";

asm fun setCode(code: Cell) { SETCODE }

contract Treasury with Ownable, Deployable {
    // ---- State ----
    owner: Address;
    paused: Bool;

    jettonMaster: Address;
    treasuryJettonWallet: Address;

    backendPubKey: Int as uint256;

    // Guards
    nonce: Int as uint64;
    minPayout: Int as coins;
    maxPayout: Int as coins;

    init(
        owner: Address,
        backendPubKey: Int as uint256,
        jettonMaster: Address,
        treasuryJettonWallet: Address,
        minPayout: Int as coins,
        maxPayout: Int as coins,
    ) {
        self.owner = owner;
        self.backendPubKey = backendPubKey;
        self.paused = false;
        self.nonce = 0;
        self.jettonMaster = jettonMaster;
        self.treasuryJettonWallet = treasuryJettonWallet;
        self.minPayout = minPayout;
        self.maxPayout = maxPayout;
    }

    inline fun verifySignature(msg: RewardRequest): Bool {
        let signedCell: Cell = beginCell()
            .storeAddress(msg.contract)
            .storeAddress(msg.recipient)
            .storeCoins(msg.amount)
            .storeUint(msg.nonce, 64)
            .storeUint(msg.validUntil, 32)
            .endCell();

        let signatureSlice: Slice = msg.signature.beginParse();

        let bundle: SignedBundle = SignedBundle {
            signature: signatureSlice.loadBits(512),
            signedData: signedCell.beginParse(),
        };

        return bundle.verifySignature(self.backendPubKey);
    }

    get fun backendKey(): Int {
        return self.backendPubKey;
    }

    get fun paused(): Bool {
        return self.paused;
    }

    get fun nonce(): Int {
        return self.nonce;
    }

    get fun treasuryJettonWallet(): Address {
        return self.treasuryJettonWallet;
    }

    get fun maxPayout(): Int {
        return self.maxPayout;
    }

    get fun minPayout(): Int {
        return self.minPayout;
    }

    get fun jettonMaster(): Address {
        return self.jettonMaster;
    }

    external(msg: RewardRequest) {
        throwUnless(ERR_PAUSED, !self.paused);
        throwUnless(ERR_BAD_CONTRACT, msg.contract == myAddress());
        throwUnless(ERR_EXPIRED, now() <= msg.validUntil);
        throwUnless(ERR_BAD_NONCE, msg.nonce == (self.nonce + 1));
        throwUnless(ERR_SIG_INVALID, self.verifySignature(msg));

        if (self.minPayout > 0) {
            throwUnless(ERR_MIN_AMOUNT, msg.amount >= self.minPayout);
        }
        if (self.maxPayout > 0) {
            throwUnless(ERR_MAX_AMOUNT, msg.amount <= self.maxPayout);
        }

        acceptMessage();

        self.nonce = msg.nonce;

        // Forward a small TON amount so the recipient wallet can emit notification
        let fwdTon: Int = GasNotification;

        let body: Cell = JettonTransfer {
            queryId: self.nonce,
            amount: msg.amount,
            destination: msg.recipient,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: fwdTon,
            forwardPayload: beginCell().endCell().beginParse(),
        }.toCell();

        send(SendParameters {
            to: self.treasuryJettonWallet,
            value: TREASURY_SEND_VALUE,
            mode: TREASURY_SEND_MODE,
            bounce: true,
            body,
        });

        emit(PayoutExecutedEvent {
            recipient: msg.recipient,
            amount: msg.amount,
            nonce: self.nonce,
        }.toCell());
    }

    receive(msg: SetPaused) {
        self.requireOwner();
        acceptMessage();
        let old = self.paused;
        self.paused = msg.paused;
        emit(PausedChangedEvent { oldState: old, newState: self.paused }.toCell());
    }

    receive(msg: SetBackendKey) {
        self.requireOwner();
        acceptMessage();
        self.backendPubKey = msg.pubkey;
        let keyHash: Int = hashUint256(msg.pubkey);
        emit(BackendKeyRotatedEvent { keyHash }.toCell());
    }

    receive(msg: SetMaxPayout) {
        self.requireOwner();
        acceptMessage();
        self.maxPayout = msg.amount;
    }

    receive(msg: SetMinPayout) {
        self.requireOwner();
        acceptMessage();
        self.minPayout = msg.amount;
    }

    receive(msg: SetTreasuryWallet) {
        self.requireOwner();
        acceptMessage();
        self.treasuryJettonWallet = msg.addr;
    }

    receive(msg: Upgrade) {
        self.requireOwner();
        acceptMessage();

        let codeHash: Int = hashCell(msg.code);
        emit(UpgradedEvent { codeHash }.toCell());

        setCode(msg.code);
    }
}
