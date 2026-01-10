import "imports/constants.tolk"

struct Storage {
    admins: map<address, uint8> // 1 = authorized
    beneficiary: address // Sale proceeds go here
    price: coins // Price in nanoTON
    nftAddress: address? // NFT contract address (set when locked)
    isComplete: uint8 // 0 = active, 1 = complete
    // Metadata for frontend (stored as slices or refs depending on size, using slices for simplicity)
    listingType: cell // e.g. "username" (ref)
    listingValue: cell // e.g. "@alice" (ref)
}

// Helper methods for Storage
fun Storage.load() {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

// Incoming Messages
struct (0x5fcc3d14) Transfer {
    queryId: uint64
    newOwner: address
    responseDestination: address
    customPayload: cell?
    forwardAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x05138d91) OwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x4c4e434c) CancelSale {
    queryId: uint64
}

struct (0x50524943) UpdatePrice {
    queryId: uint64
    newPrice: coins
}

struct (0x42454e45) UpdateBeneficiary {
    queryId: uint64
    newBeneficiary: address
}

struct (0x41444441) AddAdmin {
    queryId: uint64
    admin: address
}

struct (0x524d4144) RemoveAdmin {
    queryId: uint64
    admin: address
}

// Union of all allowed messages
type AllowedMessage =
    | OwnershipAssigned
    | CancelSale
    | UpdatePrice
    | UpdateBeneficiary
    | AddAdmin
    | RemoveAdmin

// Main Message Handler
fun onInternalMessage(in: InMessage) {
    // 1. Handle Empty Message (Buying Logic)
    if (in.body.isEmpty()) {
        buy(in.senderAddress, in.valueCoins);
        return;
    }

    // 2. Handle Typed Messages
    val msg = lazy AllowedMessage.fromSlice(in.body);
    match (msg) {
        OwnershipAssigned => {
            lockNft(in.senderAddress, msg);
        }
        CancelSale => {
            cancelSale(in.senderAddress, msg);
        }
        UpdatePrice => {
            updatePrice(in.senderAddress, msg);
        }
        UpdateBeneficiary => {
            updateBeneficiary(in.senderAddress, msg);
        }
        AddAdmin => {
            addAdmin(in.senderAddress, msg);
        }
        RemoveAdmin => {
            removeAdmin(in.senderAddress, msg);
        }
        else => {
            // Unknown message, bounce if possible or just ignore
            throw 0xffff;
        }
    }
}

// --- Logic Implementations ---
fun buy(sender: address, value: coins) {
    var storage = Storage.load();

    // Checks
    assert (storage.isComplete == 0) throw 101; // Sale is not active/complete
    assert (storage.nftAddress != null) throw 102; // NFT not locked yet
    assert (
        value >= storage.price + GAS_TRANSFER_NFT + GAS_COMPUTE_FEES
    ) throw 103; // Insufficient funds

    // 1. Transfer NFT to Buyer (Atomic Step 1)
    val nftTransfer = createMessage({
        dest: storage.nftAddress!!,
        value: GAS_TRANSFER_NFT, // Forward fee for NFT transfer
        bounce: true,
        body: Transfer {
            queryId: 0,
            newOwner: sender, // Buyer
            responseDestination: sender, // Notify buyer
            customPayload: null,
            forwardAmount: 0,
            forwardPayload: beginCell().endCell().beginParse(),
        },
    });
    nftTransfer.send(SEND_MODE_PAY_FEES_SEPARATELY);

    // 2. Send Proceeds to Beneficiary (Atomic Step 2)
    val payment = createMessage({
        dest: storage.beneficiary,
        value: storage.price,
        bounce: false, // Don't revert if beneficiary wallet is weird, just take the money
        body: beginCell().endCell(),
    });
    payment.send(SEND_MODE_PAY_FEES_SEPARATELY);

    // 3. Mark Complete and Save
    storage.isComplete = 1;
    storage.save();

    // 4. Return Excess Gas to Buyer (done automatically by generic "return change" logic if we used specific mode, 
    //    but here we want to keep the reserve and return the rest manually or rely on standard flow.
    //    Since we aren't using SEND_MODE_CARRY_ALL_REMAINING for the previous sends, we have remainder here.
    //    We can send the rest back to sender.)
    // Reserve minimum balance for storage rent
    reserveToncoinsOnBalance(GAS_MIN_RESERVE, 0);

    // Return rest to sender
    val refund = createMessage({
        dest: sender,
        value: 0,
        bounce: false,
        body: emptyCell(),
    });
    refund.send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun lockNft(sender: address, msg: OwnershipAssigned) {
    var storage = Storage.load();

    // Verify state
    assert (storage.isComplete == 0) throw 104; // Sale already complete
    assert (storage.nftAddress == null) throw 105; // Already locked an NFT

    // Lock it
    storage.nftAddress = sender;
    storage.save();

    // Refund excess gas to the *previous owner* (who sent the NFT)
    reserveToncoinsOnBalance(GAS_MIN_RESERVE, 0);
    val refund = createMessage({
        dest: msg.prevOwner,
        value: 0,
        bounce: false,
        body: emptyCell(),
    });
    refund.send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun cancelSale(sender: address, msg: CancelSale) {
    var storage = Storage.load();
    checkAdmin(storage, sender);

    assert (storage.isComplete == 0) throw 101;

    // Return NFT if locked
    if (storage.nftAddress != null) {
        val returnNft = createMessage({
            dest: storage.nftAddress!!,
            value: 0,
            bounce: true,
            // Carry remaining value to pay for transfer, minus our reserve
            body: Transfer {
                queryId: msg.queryId,
                newOwner: storage.beneficiary, // Return to beneficiary/seller
                responseDestination: sender,
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice(),
            },
        });

        // We need to keep our reserve, send the rest to pay for transfer
        reserveToncoinsOnBalance(GAS_MIN_RESERVE, 0);
        returnNft.send(SEND_MODE_CARRY_ALL_BALANCE);
    } else {
        // Just empty, nothing to return. Refund gas.
        reserveToncoinsOnBalance(GAS_MIN_RESERVE, 0);
        val refund = createMessage({
            dest: sender,
            value: 0,
            bounce: false,
            body: emptyCell(),
        });
        refund.send(SEND_MODE_CARRY_ALL_BALANCE);
    }

    // Mark complete
    storage.isComplete = 1;
    storage.save();
}

fun updatePrice(sender: address, msg: UpdatePrice) {
    var storage = Storage.load();
    checkAdmin(storage, sender);

    storage.price = msg.newPrice;
    storage.save();
}

fun updateBeneficiary(sender: address, msg: UpdateBeneficiary) {
    var storage = Storage.load();
    checkAdmin(storage, sender);

    storage.beneficiary = msg.newBeneficiary;
    storage.save();
}

fun addAdmin(sender: address, msg: AddAdmin) {
    var storage = Storage.load();
    checkAdmin(storage, sender);

    storage.admins.set(msg.admin, 1);
    storage.save();
}

fun removeAdmin(sender: address, msg: RemoveAdmin) {
    var storage = Storage.load();
    checkAdmin(storage, sender);

    storage.admins.delete(msg.admin);
    storage.save();
}

// Helpers
fun checkAdmin(storage: Storage, sender: address) {
    val isAdmin = storage.admins.get(sender);
    assert (isAdmin.isFound) throw 401; // Unauthorized
}

// Getters
get fun sale_details(): (coins, address?, int, address, slice, slice) {
    val s = Storage.load();
    return (
        s.price,
        s.nftAddress,
        s.isComplete,
        s.beneficiary,
        s.listingType.beginParse(),
        s.listingValue.beginParse()
    );
}

get fun is_admin(addr: address): int {
    val s = Storage.load();
    return s.admins.get(addr).isFound ? 1 : 0;
}
