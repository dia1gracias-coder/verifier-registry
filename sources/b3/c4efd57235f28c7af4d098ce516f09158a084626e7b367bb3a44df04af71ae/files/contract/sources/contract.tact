import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "./helpers.tact";

// The CollectorContract handles the collection of NFTs, assigning ownership to a specific owner and rewarding previous owners.
contract CollectorContract with Deployable, Ownable {
    nftCollectionAddress: Address; // Address of the NFT collection this contract interacts with.
    rewardAmount: Int as uint32;   // Reward amount (in TONs) given to the previous owner of an NFT.
    owner: Address;               // The address of the contract owner.
    nftItemCode: Cell;            // Serialized cell containing the code for NFT items.

    init(nftCollectionAddress: Address, nftItemCode: Cell) {
        self.nftCollectionAddress = nftCollectionAddress;
        self.rewardAmount = ton("0.12345");
        self.nftItemCode = nftItemCode;
        self.owner = sender();
    }

    // Handles the receipt of ownership transfer messages.
    receive(msg: OwnershipAssigned) {
        // Transfer the received NFT item to the contract owner.
        send(SendParameters{
            to: sender(),
            value: ton("0.1"),
            body: NFTTransfer{
                queryId: 42, // Arbitrary identifier
                newOwner: self.owner,
                responseDestination: myAddress(),
                customPayload: null,
                forwardAmount: 1,
                forwardPayload: beginCell().storeUint(0xA, 4).endCell().beginParse() // Placeholder payload
            }.toCell(),
            mode: SendPayGasSeparately | SendIgnoreErrors
        });

        // Ensure that a forward payload exists, containing the NFT item index.
        require(msg.forwardPayload != null, "No forwardPayload provided");
        let payloadSlice : Slice = (msg.forwardPayload!!).beginParse();
        let itemIndex : Int = payloadSlice.loadUint(32);

        // Verify the sender is the expected NFT item contract by calculating the address based on the collection.
        // See https://docs.tact-lang.org/cookbook/nfts/#accepting-nft-ownership-assignment
        let expectedAddress : Address = calculateNFTAddress(itemIndex, self.nftCollectionAddress, self.nftItemCode);
        require(expectedAddress == sender(), "Sender is not expected NFT item contract"); 

        // Send a reward to the previous owner of the NFT item.
        send(SendParameters{
            to: msg.previousOwner,
            body: "Graphon NFT reward".asComment(),
            value: self.rewardAmount,
            bounce: false,
            mode: SendPayGasSeparately | SendIgnoreErrors
        });
    }

    // Handles setup messages to adjust the reward amount.
    receive(msg: SetupMessage) {
        self.requireOwner();
        self.rewardAmount = msg.rewardAmount;
    }

    // Allows the owner to withdraw the remaining balance of the contract.
    receive ("withdrawBalance") {
        self.requireOwner();
        send(SendParameters{
            to: self.owner,
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    receive (text: String) {
    }

    receive(msg: Slice) {
    }

    receive() {
    }

    get fun collection(): Address{
        return self.nftCollectionAddress;
    }
    
    get fun balance(): Int {
        return myBalance();
    }

    get fun rewardAmount(): Int {
        return self.rewardAmount;
    }
}
