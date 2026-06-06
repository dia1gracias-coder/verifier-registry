import "./time_mint_constants";
import "./time_mint_messages";

contract TimeMintItem(
    owner: Address?,
    content: Cell?,
    collectionAddress: Address,
    itemIndex: Int as uint64,
) {
    receive() {}

    receive(msg: GetStaticData) {
        throwUnless(NotInit, self.owner != null);

        sendMsg(
            sender(),
            0,
            ReportStaticData,
            msg.queryId,
            beginCell()
                .storeUint(self.itemIndex, 256)
                .storeAddress(self.collectionAddress),
            SendRemainingValue,
        );
    }

    receive(msg: Slice) {
        throwUnless(InvalidData, self.owner == null);
        throwUnless(IncorrectSender, sender() == self.collectionAddress);

        let body = InitNFTBody.fromSlice(msg);

        self.owner = body.owner;
        self.content = body.content;
    }

    receive(msg: Transfer) {
        throwUnless(NotInit, self.owner != null);
        throwUnless(IncorrectSender, sender() == self.owner);
        throwUnless(IncorrectForwardPayload, msg.forwardPayload.bits() >= 1);
        forceBasechain(msg.newOwner);

        let fwdFees = context().readForwardFee();
        let restAmount = myBalance() - minTonsForStorage;

        if (msg.forwardAmount > 0) {
            restAmount -= msg.forwardAmount + fwdFees;
        }

        let needResponse = msg.responseDestination != null;
        if (needResponse) {
            restAmount -= fwdFees;
        }

        throwUnless(InvalidFees, restAmount >= 0);

        if (msg.forwardAmount > 0) {
            sendMsg(
                msg.newOwner,
                msg.forwardAmount,
                OwnershipAssigned,
                msg.queryId,
                beginCell()
                    .storeAddress(self.owner!!)
                    .storeSlice(msg.forwardPayload),
                SendPayFwdFeesSeparately,
            );
        }

        if (needResponse) {
            forceBasechain(msg.responseDestination!!);
            sendMsg(
                msg.responseDestination!!,
                restAmount,
                Excesses,
                msg.queryId,
                beginCell(),
                SendPayFwdFeesSeparately,
            );
        }

        self.owner = msg.newOwner;
    }

    get fun get_nft_data(): NFTData {
        return NFTData {
            init: self.owner != null ? -1 : 0,
            itemIndex: self.itemIndex,
            collectionAddress: self.collectionAddress,
            owner: self.owner,
            content: self.content,
        };
    }
}

inline fun sendMsg(toAddress: Address, amount: Int, op: Int, queryId: Int, payload: Builder, sendMode: Int) {
    message(MessageParameters {
        bounce: false,
        to: toAddress,
        value: amount,
        body: beginCell()
            .storeUint(op, 32)
            .storeUint(queryId, 64)
            .storeBuilder(payload)
            .endCell(),
        mode: sendMode,
    });
}
