// Message layouts used by the TEP-62 NFT contracts.
//
// TON contracts talk to each other by sending messages, and a message body
// is just a cell that starts with a 32-bit "opcode" saying what kind of
// message it is, followed by whatever data that message needs. Each
// `struct (0x...)` below is one such message shape; the number in
// parentheses is its opcode.

import "storage";

// Sent by the collection to a freshly-deployed NFT item, to fill in its
// real data (owner, content, royalty address) for the first time.
struct NftItemInitAtDeployment {
    ownerAddress: address
    content: Cell<SnakeString>
    royaltyAddress: address
}

// ---- Messages the COLLECTION contract accepts ----

// "Mint one NFT." Only the collection's admin can send this.
struct (0x00000001) DeployNft {
    queryId: uint64
    itemIndex: uint64
    attachGrams: coins                       // TON forwarded to fund the new NFT contract
    initParams: Cell<NftItemInitAtDeployment>
}

// "Mint many NFTs in one message." Same idea as DeployNft, just batched.
struct (0x00000002) BatchDeployNfts {
    queryId: uint64
    deployList: map<uint64, BatchDeployDictItem>
}

struct BatchDeployDictItem {
    attachGrams: coins
    initParams: Cell<NftItemInitAtDeployment>
}

// "Hand admin rights to someone else."
struct (0x00000003) ChangeCollectionAdmin {
    queryId: uint64
    newAdminAddress: address
}

// ---- Messages the ITEM (individual NFT) contract accepts ----

// TEP-62 standard: "Transfer this NFT to a new owner." Only the current
// owner may send this. This is also what triggers the 2% royalty payout.
struct (0x5fcc3d14) Transfer {
    queryId: uint64
    newOwnerAddress: address
    // If null => don't send excess TON back.
    sendExcessesTo: address?
    // Optional application data (not used by this contract).
    customPayload: dict
    // TON forwarded to the new owner as part of the "you now own this" notification.
    forwardGrams: coins
    // Remaining bits/refs forwarded to the new owner payload.
    forwardPayload: RemainingBitsAndRefs
}

// Sent by the item TO the new owner, right after a transfer completes —
// lets the new owner's wallet/dApp know "you now own this NFT".
struct (0x05138d91) NotificationForNewOwner {
    queryId: uint64
    oldOwnerAddress: address
    payload: RemainingBitsAndRefs
}

// Sent back to whoever paid for the transfer, refunding any TON that
// wasn't needed for gas/royalty/forwarding.
struct (0xd53276db) ReturnExcessesBack {
    queryId: uint64
}

// "Tell me your index and collection address." Read-only-style request,
// answered by ResponseStaticData below.
struct (0x2fcb26a2) RequestStaticData {
    queryId: uint64
}

struct (0x8b771735) ResponseStaticData {
    queryId: uint64
    itemIndex: uint256
    collectionAddress: address
}

// Sent to the royalty address whenever a transfer pays out its 2% cut.
// (There's no official TEP for "royalty on transfer" — this is just a
// deterministic message body so the payment is easy to recognize on-chain.)
struct (0x44445555) RoyaltyPaid {
    queryId: uint64
}
