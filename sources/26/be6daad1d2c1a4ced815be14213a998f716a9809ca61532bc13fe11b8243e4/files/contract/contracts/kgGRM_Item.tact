import "@stdlib/deploy";
import "./messages.tact";
import "./content.tact";

const ITEM_IMAGE_URL: String = "https://i.imgur.com/cvJsSoz.jpeg";

struct NftData {
    init: Bool;
    index: Int;
    collection: Address;
    owner: Address;
    content: Cell;
}

// ════════════════════════════════════════════════════════════
//  kgGRM_Item — NFT representing exactly 1000 wrapped GRM
//
//  Address is deterministic: contractAddress(initOf kgGRM_Item(index, collection))
//  This lets Vault verify NFT authenticity without any oracle.
// ════════════════════════════════════════════════════════════
contract kgGRM_Item with Deployable {
    index: Int as uint64;
    collection: Address;
    owner: Address;

    init(index: Int, collection: Address) {
        self.index = index;
        self.collection = collection;
        self.owner = collection; // Collection is owner until minted to user
    }

    // ─── TEP-62: Transfer to new owner ──────────────────────
    receive(msg: NFTTransfer) {
        require(sender() == self.owner, "Only owner can transfer");

        let prevOwner: Address = self.owner;
        self.owner = msg.newOwner;

        // Notify new owner (Vault) — forward payload carries itemIndex for verification
        if (msg.forwardAmount > 0) {
            send(SendParameters{
                to: msg.newOwner,
                value: msg.forwardAmount,
                bounce: false,
                mode: SendPayGasSeparately,
                body: NFTOwnershipAssigned{
                    queryId: msg.queryId,
                    prevOwner: prevOwner,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }

        // Return excess TON.
        // NOTE: must NOT use SendRemainingValue here — it would re-add
        // the full inbound message value, double-counting against the
        // forwardAmount already sent above (mode SendPayGasSeparately)
        // and aborting the transaction with action-phase error 37
        // ("not enough funds"). A small fixed value paid from this
        // contract's own balance is enough for an ack message.
        if (msg.responseDestination != null) {
            send(SendParameters{
                to: msg.responseDestination!!,
                value: ton("0.01"),
                bounce: false,
                mode: SendPayGasSeparately,
                body: beginCell()
                    .storeUint(0xd53276db, 32) // excesses
                    .storeUint(msg.queryId, 64)
                    .endCell()
            });
        }
    }

    // ─── Burn: only Collection can call this ─────────────────
    receive(msg: NFTBurn) {
        // Collection is the only authorized burner (Vault routes through Collection)
        require(sender() == self.collection, "Only collection can burn");

        self.owner = self.collection; // NFT is permanently locked — effectively burned

        if (msg.responseDestination != null) {
            send(SendParameters{
                to: msg.responseDestination!!,
                value: 0,
                bounce: false,
                mode: SendRemainingValue
            });
        }
    }

    receive() {} // accept excess TON

    // ─── TEP-62 Get Methods ─────────────────────────────────
    get fun get_nft_data(): NftData {
        return NftData{
            init: true,
            index: self.index,
            collection: self.collection,
            owner: self.owner,
            content: buildOnchainContent(
                "kgGRM",
                "This NFT represents exactly 1000 GRM locked in the kgGRM Vault. Unwrap it by sending the NFT back to the vault to redeem your tokens.",
                ITEM_IMAGE_URL
            )
        };
    }
}
