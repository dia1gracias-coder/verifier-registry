import "@stdlib/deploy";
import "@stdlib/ownable";

message NewService {
    description: String;
}

message NewServiceResponse {
    serviceId: Int as uint256;
}

message FinalizeService {
    serviceId: Int as uint256;
}

contract BiddingPlatform with Deployable, Ownable {
    owner: Address;
    numServices: Int as uint256 = 0;

    init() {
        self.owner = sender();
    }

    receive(msg: NewService) {
        self.numServices = self.numServices + 1;
        let init: StateInit = initOf ServiceChild(myAddress(), self.numServices);
        send(SendParameters{
            to: contractAddress(init),
            body: InternalSetDescription{description: msg.description}.toCell(),
            value: ton("0.02"),
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data
        });
        self.reply(NewServiceResponse{serviceId: self.numServices}.toCell());
    }

    receive(msg: FinalizeService) {
        self.requireOwner();
        require(msg.serviceId <= self.numServices, "Service does not exist");
        send(SendParameters{
            to: contractAddress(initOf ServiceChild(myAddress(), msg.serviceId)),
            body: FinalizeBidding{excess: sender()}.toCell(),
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    get fun numServices(): Int {
        return self.numServices;
    }

    get fun serviceAddress(serviceId: Int): Address {
        return contractAddress(initOf ServiceChild(myAddress(), serviceId));
    }
}

// Messages for child contract
message InternalSetDescription {
    description: String;
}

message PlaceBid {
    bidAmount: Int as uint256;
}

message FinalizeBidding {
    excess: Address;
}

struct BidDetails {
    bidder: Address?;
    bidAmount: Int as uint256;
}

contract ServiceChild {
    parent: Address;
    serviceId: Int as uint256;
    description: String = "";
    highestBid: Int as uint256 = 0;
    highestBidder: Address?;
    isFinalized: Bool = false;

    init(parent: Address, serviceId: Int) {
        self.parent = parent;
        self.serviceId = serviceId;
    }

    receive(msg: InternalSetDescription) {
        require(sender() == self.parent, "Parent only");
        self.description = msg.description;
    }

    receive(msg: PlaceBid) {
        require(!self.isFinalized, "Bidding is finalized");
        require(msg.bidAmount > self.highestBid, "Bid must be higher than current highest");
        require(context().value >= msg.bidAmount, "Insufficient funds sent");

        // Return the previous highest bid if exists
        if (self.highestBidder != null) {
            send(SendParameters{
                to: self.highestBidder!!,
                value: self.highestBid,
                mode: SendIgnoreErrors
            });
        }

        self.highestBid = msg.bidAmount;
        self.highestBidder = sender();

        // Return excess funds to the bidder
        if (context().value > msg.bidAmount) {
            send(SendParameters{
                to: sender(),
                value: context().value - msg.bidAmount,
                mode: SendIgnoreErrors
            });
        }
    }

    receive(msg: FinalizeBidding) {
        require(sender() == self.parent, "Parent only");
        require(!self.isFinalized, "Already finalized");
        
        self.isFinalized = true;

        // If there was a winning bid, send funds to the excess address (owner)
        if (self.highestBid > 0) {
            send(SendParameters{
                to: msg.excess,
                value: self.highestBid,
                mode: SendRemainingValue + SendIgnoreErrors
            });
        }
    }

    get fun highestBidDetails(): BidDetails {
        return BidDetails{
            bidder: self.highestBidder,
            bidAmount: self.highestBid
        };
    }

    get fun serviceInfo(): String {
        return self.description;
    }
}
