import "@stdlib/strings"
import "messages"

struct WalletStorage {
    jettonBalance: coins
    ownerAddress: address
    minterAddress: address
    lastClaimSequence: uint64
    pendingTransfer: Cell<AskToTransfer>?
}

/// Mutable policy is stored behind one reference so the TEP-74 root remains compact.
/// Closing minting is irreversible, while claim pause and transfer freeze stay reversible.
struct ApeJettonPolicy {
    treasuryAddress: address
    voucherSignerPublicKey: uint256
    voucherDomain: uint256
    serviceFee: coins
    claimsPaused: bool
    transfersFrozen: bool
    mintingClosed: bool
}

struct MinterStorage {
    totalSupply: coins
    adminAddress: address?
    nextAdminAddress: address?
    metadata: cell
    policy: Cell<ApeJettonPolicy>
}

fun MinterStorage.load(): MinterStorage {
    return MinterStorage.fromCell(contract.getData());
}

fun MinterStorage.save(self) {
    contract.setData(self.toCell());
}

fun WalletStorage.load(): WalletStorage {
    return WalletStorage.fromCell(contract.getData());
}

fun WalletStorage.save(self) {
    contract.setData(self.toCell());
}

struct JettonWalletDataReply {
    jettonBalance: coins
    ownerAddress: address
    minterAddress: address
    jettonWalletCode: cell
}

struct JettonDataReply {
    totalSupply: int
    mintable: bool
    adminAddress: address?
    jettonContent: Cell<OnchainMetadataReply>
    jettonWalletCode: cell
}

struct ApeJettonPolicyReply {
    adminAddress: address?
    nextAdminAddress: address?
    treasuryAddress: address
    voucherSignerPublicKey: uint256
    voucherDomain: uint256
    serviceFee: coins
    claimsPaused: bool
    transfersFrozen: bool
    mintingClosed: bool
}

struct (0x00) OnchainMetadataReply {
    contentDict: map<uint256, string_prefixed0x>
}
