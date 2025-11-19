import "@stdlib/ownable";
import "./PartnerNftItem.tact";
import "./Messages.tact";
import "./Errors.tact";

// ===== Messages =====
message(0x157c62bb) Mint {
    to: Address;
    shareBps: Int;
    uri: String;        
}

message(0xca9e378a) Burn {
    tokenId: Int;   // == item index
}

message(0x791c083b) SetTxProcessor {
    processor: Address;
    allowed: Bool;
}

message(0x1599f05f) SetWalletWhitelist {
    wallet: Address;
    allowed: Bool;
}

// ===== Structs =====
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Slice;
}

contract PartnerNftCollection with Ownable {

    // ===== Storage =====
    owner: Address;
    nextItemIndex: Int;  // TEP-62: next_item_index
    collectionContent: Cell;       // TEP-64: collection_content
    itemCode: Cell;                // item_code

    //  ===== Business-specific storage =====
    walletWhitelist: map<Address, Bool>;                      // wallet -> bool
    walletIndex: map<Address, Int>;                 // wallet -> item index
    tokenShareBps: map<Int, Int>;         // index -> shareBps
    successfulTxCount: map<Int, Int>;     // index -> count
    txProcessors: map<Address, Bool>;                         // processor -> bool
    indexToAddress: map<Int, Address>;              // index -> NFT item address

    // ===== Init =====
    init(owner: Address, collectionContent: Cell, itemCode: Cell) {
        self.owner = owner;
        self.nextItemIndex = 0;
        self.collectionContent = collectionContent;
        self.itemCode = itemCode;
        self.walletWhitelist = emptyMap();
        self.walletIndex = emptyMap();
        self.tokenShareBps = emptyMap();
        self.successfulTxCount = emptyMap();
        self.txProcessors = emptyMap();
        self.indexToAddress = emptyMap();
    }

    // ===== Business logic =====
    // Mint 1 NFT per address (TEP-62 style)
    receive(msg: Mint) {
        self.requireOwner();
        // Checks
        let existingOpt = self.walletIndex.get(msg.to);
        throwIf(OwnerAlreadyHasToken, existingOpt != null);
        throwIf(RewardBpsTooHigh, !(msg.shareBps >= 0 && msg.shareBps <= 10000));
        throwIf(InvalidTokenURI, msg.uri == "");

        let index = self.nextItemIndex;
        // 1) prepare init for PartnerNftItem
        let itemInit = initOf PartnerNftItem(
            myAddress(),
            msg.to,
            index,
            msg.uri,
            msg.shareBps
        );
        // 2) calculate item address
        let itemAddress: Address = contractAddress(itemInit);

        // 3) send message with init (deploy + msg)
        send(SendParameters{
            to: itemAddress,
            value: ton("0.05"),   // enough for deploy + gas
            mode: SendIgnoreErrors, 
            code: itemInit.code,
            data: itemInit.data,
            body: null
        });

        // 4) save index -> address, whitelist, shareBps, etc.
        self.indexToAddress.set(index, itemAddress);
        self.walletIndex.set(msg.to, index);
        self.walletWhitelist.set(msg.to, true);
        self.tokenShareBps.set(index, msg.shareBps);
        foreach (processor, allowed in self.txProcessors) {
            if (allowed) {
                send(SendParameters{
                    to: processor,
                    value: ton("0.02"),
                    mode: 0,
                    body: RegisterPartnerShare{
                        wallet: msg.to,
                        shareBps: self.platformShareBpsForWallet(msg.to)
                    }.toCell()
                });
            }
        }
        self.nextItemIndex = index + 1;
    }

    // Burn: remove NFT from collection and destroy item
    receive(msg: Burn) {
        // check ownership
        let claimedOwner = sender();
        let idxOpt = self.walletIndex.get(claimedOwner);
        let idx = idxOpt != null ? idxOpt!! : -1;
        throwIf(NotOwner, idx != msg.tokenId);

        // item address
        let itemAddrOpt = self.indexToAddress.get(msg.tokenId);
        throwIf(InvalidToken, itemAddrOpt == null);
        let itemAddr = itemAddrOpt!!;

        // send BurnFromCollection message to item
        let body = beginCell()
            .storeUint(0xca9e378a, 32) // op BurnFromCollection in item
            .endCell();

        send(SendParameters{
            to: itemAddr,
            value: ton("0.02"), // чуть на gas
            body: body
        });

        // cleanup storage
        self.walletIndex.set(claimedOwner, null);
        self.walletWhitelist.set(claimedOwner, null);
        self.tokenShareBps.set(msg.tokenId, null);
        self.successfulTxCount.set(msg.tokenId, null);
        self.indexToAddress.set(msg.tokenId, null);

        foreach (processor, allowed in self.txProcessors) {
            if (allowed) {
                send(SendParameters{
                    to: processor,
                    value: ton("0.02"),
                    mode: 0,
                    body: UnregisterPartnerShare{ wallet: claimedOwner }.toCell()
                });
            }
        }
    }
    // ==== Management ====
    receive(msg: SetWalletWhitelist) {
        self.requireOwner();
        self.walletWhitelist.set(msg.wallet, msg.allowed);
         // считаем shareBps для этого кошелька
        foreach (processor, allowedProc in self.txProcessors) {
            if (allowedProc) {
                send(SendParameters{
                    to: processor,
                    value: ton("0.02"),
                    mode: 0,
                    body: RegisterPartnerShare{
                        wallet: msg.wallet,
                        shareBps: self.platformShareBpsForWallet(msg.wallet)
                    }.toCell()
                });
            }
        }
    }

    receive(msg: SetTxProcessor) {
        self.requireOwner();
        self.txProcessors.set(msg.processor, msg.allowed);
    }

    // ===== Business-specific receives =====
    // Increment successfulTxCount for wallet's token
    receive(msg: IncrementSuccessfulTx) {
        // 1) check sender is allowed tx processor
        let allowedOpt = self.txProcessors.get(sender());
        if (allowedOpt == null || !allowedOpt!!) {
            return;
        }
        // 2) find token index for wallet
        let idxOpt = self.walletIndex.get(msg.wallet);
        if (idxOpt == null) {
            return;
        }
        let idx = idxOpt!!;
        // 3) increment successfulTxCount
        let currentOpt = self.successfulTxCount.get(idx);
        let current = currentOpt != null ? currentOpt!! : 0;
        self.successfulTxCount.set(idx, current + 1);
    }

    // ===== TEP-62 get-methods of the collection =====
    get fun get_collection_data(): CollectionData {
        return CollectionData{
            next_item_index: self.nextItemIndex,
            collection_content: self.collectionContent,
            owner_address: self.owner.asSlice()
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        let addrOpt = self.indexToAddress.get(index);
        throwIf(InvalidToken, addrOpt == null);
        return addrOpt!!; // Address как slice нормально читается снаружи
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        return individual_content;
    }

    // ===== Additional get-methods =====
    get fun successfulTxCountOf(wallet: Address): Int {
        let idxOpt = self.walletIndex.get(wallet);
        let idx = idxOpt != null ? idxOpt!! : 0;
        if (idxOpt == null) {
            return 0;
        }
        let countOpt = self.successfulTxCount.get(idx);
        return countOpt != null ? countOpt!! : 0;
    }

    get fun tokenOf(owner: Address): Int {
        let idxOpt = self.walletIndex.get(owner);
        return idxOpt != null ? idxOpt!! : -1;
    }   

    get fun isWalletWhitelisted(wallet: Address): Bool {
        let inListOpt = self.walletWhitelist.get(wallet);
        let inList = inListOpt != null ? inListOpt!! : false;
        let hasToken = self.walletIndex.get(wallet) != null;
        return inList && hasToken;
    }

    get fun platformShareBpsForWallet(wallet: Address): Int? {
        let inListOpt = self.walletWhitelist.get(wallet);
        let inList = inListOpt != null ? inListOpt!! : false;
        let idxOpt = self.walletIndex.get(wallet);
        if (!inList || idxOpt == null) {
            return null;
        }
        let idx = idxOpt!!;
        return self.tokenShareBps.get(idx);
    }

    get fun isPaymentProccesorAllowed(processor: Address): Bool {
        let allowedOpt = self.txProcessors.get(processor);
        return allowedOpt != null ? allowedOpt!! : false;
    }

    get fun get_version(): Int {
        return 2;
    }
}
