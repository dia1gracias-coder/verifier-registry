import "@stdlib/deploy";
import "./kgGRM_Item.tact";
import "./messages.tact";
import "./content.tact";

const COLLECTION_IMAGE_URL: String = "https://i.imgur.com/cvJsSoz.jpeg";

struct CollectionData {
    nextItemIndex: Int;
    content: Cell;
    ownerAddress: Address;
}

// ════════════════════════════════════════════════════════════
//  kgGRM_Collection — TEP-62 NFT Collection
//
//  Acts as factory + access control layer.
//  Only Vault can mint or burn — no one else.
// ════════════════════════════════════════════════════════════
contract kgGRM_Collection with Deployable {
    vault: Address;
    ownerAddress: Address;
    nextItemIndex: Int as uint64;

    init(vault: Address, ownerAddress: Address) {
        self.vault = vault;
        self.ownerAddress = ownerAddress;
        self.nextItemIndex = 0;
    }

    // ─── Mint: deploy NFT Item and transfer to user ──────────
    receive(msg: Mint) {
        require(sender() == self.vault, "Only Vault can mint");

        let itemIndex: Int = self.nextItemIndex;
        let itemInit: StateInit = initOf kgGRM_Item(itemIndex, myAddress());
        let itemAddress: Address = contractAddress(itemInit);

        // Deploy Item + immediately send NFTTransfer to change owner to user.
        // Item starts with owner = collection, NFTTransfer switches it to msg.to.
        //
        // bounce: true — if the Item's own processing of this message runs
        // out of gas (a separate transaction, after nextItemIndex below is
        // already committed here), the unspent TON bounces back to the
        // Collection instead of being stranded in a half-initialized Item.
        // Note this can't undo the index bump (Tact has no cross-transaction
        // rollback) — a skipped index is harmless bookkeeping, not a fund-
        // safety issue, since no GRM moves at this stage.
        send(SendParameters{
            to: itemAddress,
            value: ton("0.07"),
            bounce: true,
            mode: SendPayGasSeparately,
            code: itemInit.code,
            data: itemInit.data,
            body: NFTTransfer{
                queryId: msg.queryId,
                newOwner: msg.to,
                responseDestination: msg.to,
                customPayload: null,
                forwardAmount: ton("0.01"),
                forwardPayload: emptyCell().asSlice()
            }.toCell()
        });

        self.nextItemIndex = itemIndex + 1;
    }

    // ─── Burn: forward NFTBurn to specific Item ──────────────
    receive(msg: CollectionBurn) {
        require(sender() == self.vault, "Only Vault can burn");

        let itemAddress: Address = contractAddress(
            initOf kgGRM_Item(msg.itemIndex, myAddress())
        );

        send(SendParameters{
            to: itemAddress,
            value: ton("0.03"),
            bounce: false,
            mode: SendPayGasSeparately,
            body: NFTBurn{
                queryId: msg.queryId,
                responseDestination: msg.responseDestination
            }.toCell()
        });
    }

    receive() {}

    // ─── TEP-62 Collection Get Methods ──────────────────────
    get fun get_collection_data(): CollectionData {
        return CollectionData{
            nextItemIndex: self.nextItemIndex,
            content: buildOnchainContent(
                "kgGRM Vault",
                "Wrapped GRM Jetton Vault NFTs. Each kgGRM NFT represents exactly 1000 GRM locked in the vault and can be unwrapped at any time to redeem the underlying tokens.",
                COLLECTION_IMAGE_URL
            ),
            ownerAddress: self.ownerAddress
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        return contractAddress(initOf kgGRM_Item(index, myAddress()));
    }

}
