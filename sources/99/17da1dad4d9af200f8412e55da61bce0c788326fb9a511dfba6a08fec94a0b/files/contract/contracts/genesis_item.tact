import "./TEPs/0062-nft-standard";

const min_tons_for_storage: Int = ton("0.03");

contract NftGenesisItem {
    deployed: Bool = false;
    owner: Address;
    collection: Address;
    index: Int as uint64;
    individual_content: Cell;

    init(collection: Address, index: Int) {
        self.collection = collection;
        self.index = index;
        self.owner = collection;
        self.individual_content = emptyCell();
        self.deployed = false;
    }

    receive() {
        // ignore empty internal messages
    }

    receive(msg: Slice) {
        if (!self.deployed) {
            require(sender() == self.collection, "Invalid Sender");
            self.owner = msg.loadAddress();
            self.individual_content = msg.loadRef();
            self.deployed = true;
            return;
        }

        require(false, "Unknown op");
    }

    receive(msg: NftGetStaticData) {
        require(self.deployed, "Not Deployed");

        send(SendParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: NftReportStaticData {
                query_id: msg.query_id,
                index: self.index,
                collection: self.collection
            }.toCell(),
        });
    }

    receive(msg: NftTransfer) {
        require(self.deployed, "Not Deployed");
        require(sender() == self.owner, "Invalid Owner");

        forceWorkchain(msg.new_owner, 0, 333);
        let fwd_fee: Int = context().readForwardFee();
        let need_response: Bool = msg.response_destination.asSlice().preloadUint(2) != 0;
        let rest_amount: Int = myBalance() - min_tons_for_storage;
        if (msg.forward_amount > 0) {
            rest_amount = rest_amount - (msg.forward_amount + fwd_fee);
        }
        if (need_response) {
            rest_amount = rest_amount - fwd_fee;
        }
        require(rest_amount >= 0, "Invalid Amount");

        let previous_owner: Address = self.owner;

        if (msg.forward_amount > 0) {
            send(SendParameters {
                to: msg.new_owner,
                value: msg.forward_amount,
                mode: SendPayFwdFeesSeparately,
                bounce: false,
                body: NftOwnershipAssigned {
                    query_id: msg.query_id,
                    previous_owner: previous_owner,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        if (need_response) {
            forceWorkchain(msg.response_destination, 0, 333);
            send(SendParameters {
                to: msg.response_destination,
                value: rest_amount,
                mode: SendPayFwdFeesSeparately,
                bounce: false,
                body: NftExcesses {
                    query_id: msg.query_id,
                }.toCell()
            });
        }

        self.owner = msg.new_owner;
    }

    get fun get_nft_data(): NftData {
        return NftData {
            init: self.deployed,
            index: self.index,
            collection_address: self.collection,
            owner_address: self.owner,
            individual_content: self.individual_content
        };
    }
}
