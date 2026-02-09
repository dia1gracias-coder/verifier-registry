import "@stdlib/gas-payments"
import "errors"
import "jetton-utils"
import "messages"
import "storage"
import "fees-management"

type AllowedMessageToMinter =
    | MintNewJettons
    | BurnNotificationForMinter
    | RequestWalletAddress
    | ChangeMinterAdmin
    | ChangeContent
    | ForceBurn
    | SetJettonPrice
    | BuyJettons
    | WithdrawTon

fun getTvmBalance(): (coins, cell) asm "BALANCE"

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToMinter.fromSlice(in.body);

    match (msg) {
        BurnNotificationForMinter => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == calcAddressOfJettonWallet(msg.burnInitiator, contract.getAddress(), storage.jettonWalletCode)) throw ERR_UNAUTHORIZED_BURN;

            storage.totalSupply -= msg.jettonAmount;
            storage.save();

            if (msg.sendExcessesTo == null) {
                return;
            }

            val excessesMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: msg.sendExcessesTo,
                value: 0,
                body: ReturnExcessesBack {
                    queryId: msg.queryId
                }
            });
            excessesMsg.send(SEND_MODE_IGNORE_ERRORS + SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        RequestWalletAddress => {
            assert (in.valueCoins > in.originalForwardFee + MINIMAL_MESSAGE_VALUE_BOUND) throw ERR_NOT_ENOUGH_AMOUNT_TO_RESPOND;

            var respondOwnerAddress: Cell<address>? = msg.includeOwnerAddress
                ? msg.ownerAddress.toCell()
                : null;

            var walletAddress: address? = null;
            if (msg.ownerAddress.getWorkchain() == BASECHAIN) {
                var storage = lazy MinterStorage.load();
                walletAddress = calcAddressOfJettonWallet(msg.ownerAddress, contract.getAddress(), storage.jettonWalletCode);
            }

            val respondMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: in.senderAddress,
                value: 0,
                body: ResponseWalletAddress {
                    queryId: msg.queryId,
                    jettonWalletAddress: walletAddress,
                    ownerAddress: respondOwnerAddress,
                }
            });
            respondMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        MintNewJettons => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;

            var internalTransferMsg = lazy msg.internalTransferMsg.load();
            storage.totalSupply += internalTransferMsg.jettonAmount;
            storage.save();

            val deployMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(msg.mintRecipient, contract.getAddress(), storage.jettonWalletCode),
                value: msg.tonAmount,
                body: msg.internalTransferMsg,
            });
            deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        ChangeMinterAdmin => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            storage.adminAddress = msg.newAdminAddress;
            storage.save();
        }

        ChangeContent => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            storage.content = msg.newContent;
            storage.save();
        }

        ForceBurn => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;

            val burnMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcDeployedJettonWallet(msg.fromAddress, contract.getAddress(), storage.jettonWalletCode),
                value: 0,
                body: ForceBurnInternal {
                    queryId: msg.queryId,
                    jettonAmount: msg.jettonAmount,
                    sendExcessesTo: msg.sendExcessesTo,
                }
            });
            burnMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        SetJettonPrice => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            
            storage.jettonPrice = msg.newPrice;
            storage.save();
        }

        BuyJettons => {
            var storage = lazy MinterStorage.load();
            
            assert (storage.jettonPrice > 0) throw ERR_PRICE_NOT_SET;
            
            val netTonValue = in.valueCoins - MINIMAL_MESSAGE_VALUE_BOUND;
            assert (netTonValue > 0) throw ERR_NOT_ENOUGH_TON;

            val amountToMint = (netTonValue * 1000000000) / storage.jettonPrice;
            
            assert (amountToMint > 0) throw ERR_MSG_VALUE_TOO_LOW;

            storage.totalSupply += amountToMint;
            storage.save();

            val mintMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: calcAddressOfJettonWallet(in.senderAddress, contract.getAddress(), storage.jettonWalletCode),
                value: 0,
                body: InternalTransferStep {
                    queryId: msg.queryId,
                    jettonAmount: amountToMint,
                    transferInitiator: contract.getAddress(),
                    sendExcessesTo: in.senderAddress,
                    forwardTonAmount: 0,
                    forwardPayload: beginCell().endCell().beginParse()
                }
            });
            
            mintMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        WithdrawTon => {
            var storage = lazy MinterStorage.load();
            assert (in.senderAddress == storage.adminAddress) throw ERR_NOT_FROM_ADMIN;
            
            val (currentBalance, _) = getTvmBalance();
            val reserve = ton("0.1");
            
            if (currentBalance > reserve) {
                val withdrawMsg = createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: storage.adminAddress,
                    value: currentBalance - reserve,
                    body: beginCell().endCell()
                });
                withdrawMsg.send(SEND_MODE_IGNORE_ERRORS); 
            }
        }

        else => {
            assert (in.body.isEmpty()) throw 0xFFFF
        }
    }
}

struct JettonDataReply {
    totalSupply: int
    mintable: bool
    adminAddress: address
    jettonContent: cell
    jettonWalletCode: cell
}

get fun get_jetton_data(): JettonDataReply {
    val storage = lazy MinterStorage.load();

    return {
        totalSupply: storage.totalSupply,
        mintable: true,
        adminAddress: storage.adminAddress,
        jettonContent: storage.content,
        jettonWalletCode: storage.jettonWalletCode,
    }
}

get fun get_wallet_address(ownerAddress: address): address {
    val storage = lazy MinterStorage.load();
    return calcAddressOfJettonWallet(ownerAddress, contract.getAddress(), storage.jettonWalletCode);
}
