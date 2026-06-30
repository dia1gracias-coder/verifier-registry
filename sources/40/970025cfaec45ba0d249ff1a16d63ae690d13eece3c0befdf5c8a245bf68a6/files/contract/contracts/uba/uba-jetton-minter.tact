// SPDX-License-Identifier: MIT

import "./uba-jetton-wallet";
import "../base/messages";
import "../base/constants";
import "../utils";

struct SsdtJettonMinterV2State {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

contract SsdtJettonMinterV2(
    totalSupply: Int as coins,
    owner: Address,
    jettonContent: Cell,
) {
    receive(msg: ProvideWalletAddress) {
        let ownerWorkchain: Int = parseStdAddress(msg.ownerAddress.asSlice()).workchain;
        let targetJettonWallet: BasechainAddress = (ownerWorkchain == Basechain)
            ? contractBasechainAddress(getSsdtJettonWalletInit(msg.ownerAddress))
            : emptyBasechainAddress();

        message(MessageParameters {
            body: makeTakeWalletAddressMsg(targetJettonWallet, msg),
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
        });
    }

    receive(msg: Mint) {
        require(sender() == self.owner, "Incorrect sender");

        checkEitherForwardPayload(msg.mintMessage.forwardPayload);

        let ctx = context();
        require(
            ctx.value >
            minTonsForStorage +
            msg.mintMessage.forwardTonAmount +
            ctx.readForwardFee() +
            getForwardFee(walletStateInitCells, walletStateInitBits, false) +
            2 * getComputeFee(gasForTransfer, false),
            "Insufficient gas for mint",
        );

        self.totalSupply += msg.mintMessage.amount;

        deploy(DeployParameters {
            value: 0,
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: msg.mintMessage.toCell(),
            init: getSsdtJettonWalletInit(msg.receiver),
        });
    }

    receive(msg: JettonBurnNotification) {
        let sender = parseStdAddress(sender().asSlice());
        let wallet = getSsdtJettonBasechainWalletByOwner(msg.sender);

        require(sender.workchain == Basechain && sender.address == wallet.hash!!, "Unauthorized burn");

        self.totalSupply -= msg.amount;

        if (msg.responseDestination != null) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors,
            });
        }
    }

    receive(msg: JettonUpdateContent) {
        require(sender() == self.owner, "Incorrect sender");
        self.jettonContent = msg.content;
    }

    receive(msg: ChangeOwner) {
        require(sender() == self.owner, "Incorrect sender");
        self.owner = msg.newOwner;
    }

    receive(msg: ClaimTON) {
        require(sender() == self.owner, "Incorrect sender");
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);

        message(MessageParameters {
            bounce: true,
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    bounced(rawMsg: Slice) {
    }

    get fun get_jetton_data(): SsdtJettonMinterV2State {
        return SsdtJettonMinterV2State {
            totalSupply: self.totalSupply,
            mintable: true,
            adminAddress: self.owner,
            jettonContent: self.jettonContent,
            jettonWalletCode: codeOf SsdtJettonWalletV2,
        };
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return getSsdtJettonWalletByOwner(ownerAddress);
    }

    get fun get_contract_version(): Int {
        return jettonImplementationVersion;
    }
}

inline fun getSsdtJettonWalletInit(address: Address): StateInit {
    return initOf SsdtJettonWalletV2(address, myAddress(), 0);
}

inline fun getSsdtJettonWalletByOwner(jettonWalletOwner: Address): Address {
    return contractAddress(getSsdtJettonWalletInit(jettonWalletOwner));
}

inline fun getSsdtJettonBasechainWalletByOwner(jettonWalletOwner: Address): BasechainAddress {
    return contractBasechainAddress(getSsdtJettonWalletInit(jettonWalletOwner));
}
