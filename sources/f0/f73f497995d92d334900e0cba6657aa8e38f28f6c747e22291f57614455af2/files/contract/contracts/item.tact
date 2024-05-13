import "@stdlib/deploy";
import "./messages";

//const min_balance: Int = ton("0.05");
//const gas_consumption: Int = ton("0.02");
const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");


struct NftData {
    deployed: Bool;
    index: Int;
    collection: Address;
    owner: Address;
    content: Cell;
}

struct NftRoyaltyParams {
    numerator: Int;
    denominator: Int;
    royalty_destination: Address;
}

trait NftRoyalty {
    royalty_destination: Address;
    numerator: Int;
    denominator: Int;

    receive(msg: NftGetRoyaltyParams) {
        send(SendParameters{
        to: sender(),
        value: 0,
        mode: SendRemainingValue,
        body: NftReportRoyaltyParams{
        query_id: msg.query_id,
        numerator: self.numerator,
        denominator: self.denominator,
        destination: self.royalty_destination
        }.toCell()
        });
    }

    get fun royalty_params(): NftRoyaltyParams {
        return NftRoyaltyParams{numerator: self.numerator, denominator: self.denominator, royalty_destination: self.royalty_destination};
    }
}

trait NftStandart {
    deployed: Bool;
    collection: Address;
    owner: Address;
    index: Int;
    content: Cell;

    receive(msg: NftTransfer) {
        let ctx: Context = context(); // Reference: https://docs.tact-lang.org/language/ref/common#context
        let msgValue: Int = self.msgValue(ctx.value);
        require(self.deployed, "Not Deployed");
        require(ctx.sender == self.owner, "not owner");

        self.owner = msg.new_owner;
        if (msg.forward_amount > 0) {
            send(SendParameters{
            to: msg.new_owner,
            value: msg.forward_amount,
            mode:  SendPayGasSeparately,
            bounce: true,
            body: NftOwnershipAssigned{
            query_id: msg.query_id,
            prev_owner: ctx.sender,
            forward_payload: msg.forward_payload
            }.toCell()
            });
        }

        msgValue = msgValue - ctx.readForwardFee();
        if (msg.response_destination != null) {
                send(SendParameters{
                to: msg.response_destination,
                value: msgValue - msg.forward_amount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: Excesses { query_id: msg.query_id }.toCell()
                });
        }
    }
    receive(msg: NftGetStaticData) {
        send(SendParameters{
        to: sender(),
        value: 0,
        mode: SendRemainingValue,
        body: NftReportStaticData{
        query_id: msg.query_id,
        index: self.index,
        collection: self.collection
        }.toCell()
        });
    }

    get fun get_nft_data(): NftData {
        return NftData{deployed: self.deployed, index: self.index, collection: self.collection, owner: self.owner, content: self.content};
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }
}

contract NftItem with NftStandart, NftRoyalty {
    deployed: Bool = false;
    collection: Address;
    owner: Address;
    index: Int as uint256;
    content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16 = 0;
    denominator: Int as uint16 = 1;

    init(collection: Address, index: Int) {
        self.collection = collection;
        self.index = index;
        self.owner = self.collection;
        self.content = emptyCell();
        self.royalty_destination = self.collection;
    }

    receive(msg: NftDeploy) {
        require(sender() == self.collection, "Invalid Sender");
        require(self.index == msg.index, "Invalid Index");
        require(!self.deployed, "Already Deployed");
        self.owner = msg.owner;
        self.content = msg.content;
        self.deployed = true;
        self.royalty_destination = msg.royalty_destination;
        self.numerator = msg.numerator;
        self.denominator = msg.denominator;

        send(SendParameters{
            to: msg.owner,
            value: ton("0.001"),
            mode:  SendPayGasSeparately,
            bounce: true,
            body: NftOwnershipAssigned{
                        query_id: 0,
                        prev_owner: self.collection,
                        forward_payload: "".asComment().asSlice()
                    }.toCell()
                });

    }
}