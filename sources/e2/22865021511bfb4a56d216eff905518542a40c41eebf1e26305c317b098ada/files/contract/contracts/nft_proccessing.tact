import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";

const min_gas: Int = ton("0.02");
const nft_gas: Int = ton("0.06");

inline fun calculateNFTAddress(index: Int, collectionAddress: Address, nftCode: Cell): Address {
    let initData = NFTItemInitData {
        index,
        collectionAddress,
    };

    return contractAddress(StateInit { code: nftCode, data: initData.toCell() });
}

contract NftProccessing with Deployable, Ownable {

    nftCollectionAddress: Address;
    nftItemIndex: Int as uint64;
    nftCode: Cell;

    owner: Address;
    original_owner: Address;
    lender: Address;
    nft: Address;
    loan_amount: Int as coins = 0;
    receivedAll: Int as coins = 0;
    nft_received: Bool = false;
    status: Int as uint8 = 0;

    init(
        owner: Address, 
        original_owner: Address, 
        lender: Address, 
        nft: Address, 
        collectionAddr: Address,
        nftCode: Cell,
        nftCollectionAddress: Address,
        nftItemIndex: Int) {

        self.nftCode = nftCode;
        self.nftCollectionAddress = nftCollectionAddress;
        self.nftItemIndex = nftItemIndex;
        self.owner = owner;
        self.nft = nft;
        self.original_owner = original_owner;
        self.lender = lender;
    }

    receive(msg: NftOwnershipAssigned) {
        let ctx: Context = context();
        if(ctx.sender != self.nft) {
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                body: NFTTransfer{
                    queryId: msg.queryId,
                    newOwner: msg.prev_owner,
                    responseDestination: msg.prev_owner,
                    customPayload: "Invalid Nft".asComment(),
                    forwardAmount: 0,
                    forwardPayload: emptySlice(),
                }.toCell()
            });
        }
        else {
            self.nft_received = true;
            send(SendParameters{
                to: msg.prev_owner,
                value: 0,
                mode: SendRemainingValue,
                body: "Nft Received".asComment()
            });
        }
    }

    receive(msg: StartCredit) {
        self.requireOwner();
        require(self.status == 0, "уже запуще");
        require(msg.creditAmount > 0, "кредит: 0");

        self.loan_amount = msg.creditAmount;
        self.lender = msg.lender;
        self.original_owner = msg.originalOwner;
        self.nft = msg.nft;
        self.status = 1;
    }

    receive("get static data") {
        let nftAddress = sender();
        send(SendParameters {
            to: nftAddress,
            value: ton("0.1"),
            body: NFTGetStaticData {
            queryId: 42,
            }.toCell(),
        });
    }

    receive(msg: NFTReportStaticData) {
        let expectedNftAddress = calculateNFTAddress(msg.index, msg.collection, self.nftCode);
        require(expectedNftAddress == sender(), "NFT contract is not the sender");
        self.nftCollectionAddress = msg.collection;
        self.nftItemIndex = msg.index;
    }

    receive("increment") {
        if (self.nft_received == true){
            let tonreceived: Int = context().value;
            self.receivedAll += tonreceived;
            if (self.receivedAll >= self.loan_amount) {
                self.status = 3;

                let emptyPayload = emptyCell().asSlice();

                send(SendParameters{
                    to: self.nft,
                    value: nft_gas,
                    bounce: true,
                    body: NFTTransfer{
                        queryId: 0,
                        newOwner: self.original_owner,
                        responseDestination: myAddress(),
                        customPayload: null,
                        forwardAmount: 0,
                        forwardPayload: emptyPayload,
                    }.toCell(),
                });

                let sendnow: Int = max(myBalance() - min_gas, 0);
                let pay: Int = min(self.receivedAll, sendnow);
                if (pay > 0) {
                    send(SendParameters{
                        to: self.lender,
                        value: pay,
                        bounce: true,
                    });
                    self.receivedAll -= pay;
                }
            }
        }else{
            send(SendParameters{
                to: sender(),
                value: min_gas,
                bounce: true,
                body: "nft not received".asComment()
            })
        }
    }

    get fun get_status(): Cell{
        let b = beginCell();
        b.storeUint(self.status, 8);
        b.storeAddress(self.nft);
        b.storeAddress(self.original_owner);
        b.storeAddress(self.lender);
        b.storeCoins(self.loan_amount);
        b.storeCoins(self.receivedAll);
        return b.endCell();
    }
}
