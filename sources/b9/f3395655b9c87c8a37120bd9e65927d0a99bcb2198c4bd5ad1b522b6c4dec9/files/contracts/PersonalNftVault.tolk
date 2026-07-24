import "errors"
import "fees-management"
import "messages"
import "types"

contract PersonalNftVault {
    author: "Reza Apes"
    version: "1.0.0"
    description: "Deterministic owner-only NFT vault with same-wallet withdrawal"
    storage: PersonalVaultStorage
    incomingMessages: AllowedMessageToPersonalVault
}

type AllowedMessageToPersonalVault = DeployPersonalVault | WithdrawNftToOwner

fun onInternalMessage(in: InMessage) {
    val storage = PersonalVaultStorage.load();
    val msg = lazy AllowedMessageToPersonalVault.fromSlice(in.body);

    assert (in.senderAddress == storage.ownerAddress) throw Errors.NotFromOwner;

    match (msg) {
        DeployPersonalVault => {
            // StateInit already contains the immutable owner. No mutable initialization exists.
        }

        WithdrawNftToOwner => {
            assert (in.valueCoins >= MIN_VAULT_WITHDRAW_VALUE) throw Errors.TooLittleValue;
            assert (msg.nftItemAddress.getWorkchain() == BASECHAIN) throw Errors.InvalidWorkchain;

            reserveToncoinsOnBalance(
                VAULT_STORAGE_RESERVE,
                RESERVE_MODE_EXACT_AMOUNT | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL,
            );

            val transferBody = beginCell()
                .storeUint(0x5fcc3d14, 32)
                .storeAny(msg.queryId)
                .storeAny(storage.ownerAddress)
                .storeAny(storage.ownerAddress)
                .storeAny(null as cell?)
                .storeAny(0 as coins)
                .storeAny(PayloadInline { value: createEmptySlice() });
            val transferMessage = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: msg.nftItemAddress,
                value: in.valueCoins - VAULT_PROCESSING_BUFFER,
                body: AskToChangeOwnership.fromSlice(transferBody.toSlice()),
            });
            transferMessage.send(SEND_MODE_REGULAR | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {
    // A failed NFT transfer returns value to the vault. Ownership remains unchanged.
}

get fun get_vault_data(): PersonalVaultStorage {
    return PersonalVaultStorage.load();
}
