import "@stdlib/gas-payments"
import "@stdlib/tvm-dicts"

// values
const MAX_ROYALTY_USERS_AMOUNT = 10

// This value defines the balance threshold after which shares will be distributed.
// You can increase it if needed.
const DISTRIBUTION_BUFFER_LIMIT = ton("1")

const TOTAL_ROYALTY_PERCENT = 100

// The value each share is multiplied by.
// Ensure that TOTAL_ROYALTY_PERCENT * ROYALTY_PRECISION fits into a uint32.
// Increase the bounds if it doesn't.
const ROYALTY_PRECISION = 1000

// gas
// Upper gas usage bound for MAX_ROYALTY_USERS_AMOUNT = 10.
// Must be recalculated if the number of users increases.
const GAS_CONSUMPTION_DISTRIBUTION = 22000

// miscellaneous
const MY_WORKCHAIN = BASECHAIN

// This parameter depends on the workchain.
// For BASECHAIN it should be set to 256.
// see: https://docs.ton.org/v3/documentation/smart-contracts/addresses/#address-of-smart-contract
const ADDRESS_HASH_LENGTH = 256

// map<account_id(uint256 in basechain), Royalty share scaled by ROYALTY_PRECISION (uint32)>; 
// Valid if it contains between 1 and MAX_ROYALTY_USERS_AMOUNT recipients and the sum of their shares equals TOTAL_ROYALTY_PERCENT
type RoyaltyDict = dict

// could use MaybeNotInitialized pattern here
// with two separate structs if needed
struct Storage {
    // should be false on deploy; 
    // flag indicating that contract has already been initialized, and totalRoyaltyReceivers is indicator of royaltyDict correctness
    isInitialized: bool 
    // mapping from royalty receivers to their respective shares
    royaltyDict: RoyaltyDict 
    // destination for all incoming funds if royaltyDict is invalid
    trustedBackupAddress: address 
    // default value is null, but can be used as ID of the contract instance on deploy 
    // stores the number of recipients to correctly calculate the forward fee during distribution; 
    // if it remains null after validation, royaltyDict is considered invalid, and all funds are sent to trustedBackupAddress
    totalRoyaltyReceivers: uint8? 
}

fun Storage.isCorrect(self) {
    return self.totalRoyaltyReceivers != null;
}

fun Storage.load() {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

// The initialization function validates the provided royaltyDict; 
// if it is invalid, it returns null, otherwise it returns the number of recipients.
@pure
fun Storage.initialize(self): uint8? {
    if (self.royaltyDict.dictIsEmpty()) {
        return null;
    }

    var counter = 0;
    var totalRoyaltyPercent = 0;

    var (addressHash, value, isFound) = self.royaltyDict.uDictGetFirst(ADDRESS_HASH_LENGTH);
    
    // iterate over the dictionary
    while (isFound) {
        counter += 1;

        totalRoyaltyPercent += value!.loadUint(32);

        // check each cycle because we can be run out of gas and not save state
        if (counter > MAX_ROYALTY_USERS_AMOUNT) {
            return null;
        }

        (addressHash, value, isFound) = self.royaltyDict.uDictGetNext(
            ADDRESS_HASH_LENGTH,
            addressHash!
        );
    }

    if (counter == 0) {
        return null;
    }

    if (totalRoyaltyPercent != TOTAL_ROYALTY_PERCENT * ROYALTY_PRECISION) {
        return null;
    }

    return counter;
}

struct (0x7a2f11d8) Deploy {}

fun handleBackup(backupAddress: address) {
    val backupMsg = createMessage({
        value: 0,
        bounce: false,
        dest: backupAddress,
    });

    // just send all balance to backup address
    backupMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun handleDistribution(
    myBalance: int,
    msgValue: int,
    totalRoyaltyReceivers: uint8,
    royaltyDict: RoyaltyDict,
) {
    // compute + fwd for every distribution message (only lump);
    // The lump forward fee is deducted not from the gas (which was purchased with msgValue) 
    // but from the contract’s balance during the action phase;
    // however, for simplicity of calculations, we subtract it from msgValue
    val gasCheck = calculateGasFee(MY_WORKCHAIN, GAS_CONSUMPTION_DISTRIBUTION) +
    getLumpFwdFeeForMessageAmount(totalRoyaltyReceivers);

    // we don't have enough value to pay for gas
    if (msgValue < gasCheck) {
        return;
    }

    // checks are done, distribute value
    val valueToDistribute = myBalance - gasCheck;

    var (addressHash, value, isFound) = royaltyDict.uDictGetFirst(ADDRESS_HASH_LENGTH);

    // iterate over the dictionary and calculate the value for each recipient
    while (isFound) {
        val royaltyPercent = value!.loadUint(32);

        val royaltyValue = mulDivFloor(
            valueToDistribute,
            royaltyPercent,
            TOTAL_ROYALTY_PERCENT * ROYALTY_PRECISION // Also divide by ROYALTY_PRECISION because each share value is scaled by this precision factor.
        );

        val royaltyPieceDistributionMsg = createMessage({
            value: royaltyValue,
            bounce: false,
            dest: (MY_WORKCHAIN, addressHash!),
        });

        royaltyPieceDistributionMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);

        (addressHash, value, isFound) = royaltyDict.uDictGetNext(ADDRESS_HASH_LENGTH, addressHash!);
    }
}

// we don't want any throws in compute/action phase since bounce;
// only returns
fun onInternalMessage(in: InMessage) {
    var storage = lazy Storage.load();

    // Initialize the contract once, validating the provided data.
    if (!storage.isInitialized) {
        storage.totalRoyaltyReceivers = storage.initialize();

        storage.isInitialized = true;
        storage.save();
        commitContractDataAndActions();
    }

    // If the message is not a Deploy message, it is considered a royalty payment.
    val msg = lazy Deploy.fromSlice(in.body);

    match (msg) {
        Deploy => {
            // do nothing, don't distribute deploy value
        }
        else => {
            val myBalance = contract.getOriginalBalance();
            // if balance is less than buffer min, always return
            if (myBalance < DISTRIBUTION_BUFFER_LIMIT) {
                return;
            }

            // if contract's invariant is broken refund to
            // backup address
            if (!storage.isCorrect()) {
                handleBackup(storage.trustedBackupAddress);
            } else {
                handleDistribution(
                    myBalance,
                    in.valueCoins,
                    storage.totalRoyaltyReceivers!,
                    storage.royaltyDict
                );
            }
        }
    }
}

// returns on stack: isInitialized -> royaltyDict -> trustedBackupAddress -> totalRoyaltyReceivers
get fun getStorage() {
    return Storage.load();
}

fun getLumpFwdFeeForMessageAmount(numberOfMsgs: uint8) {
    // in tvm11 would be:
    // asm "25 GETPARAMLONG"
    return calculateForwardFee(MY_WORKCHAIN, 0, 0) * numberOfMsgs;
}
