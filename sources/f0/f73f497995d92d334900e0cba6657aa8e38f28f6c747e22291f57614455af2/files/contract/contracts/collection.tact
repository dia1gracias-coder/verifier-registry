import "@stdlib/deploy";
import "@stdlib/ownable";
import "./item";

struct CollectionData {
    next_index: Int;
    content: Cell;
    owner: Address;
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forward_payload: Slice as remaining;
}

contract NftCollection with Ownable, Deployable, NftRoyalty {
    owner: Address;
    next_index: Int as uint256 = 0;
    content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;
    jettonWallet: Address?;
    mint_jetton_amount: Int as coins;
    usedWallets:  map<Address, Bool>;
    max_nft_items: Int as uint256;

    init(owner: Address, content: Cell, royalty_destination: Address, numerator: Int, denominator: Int, mint_jetton_amount: Int, max_nft_items: Int) {
        self.owner = owner;
        self.content = content;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
        self.mint_jetton_amount = mint_jetton_amount;
        self.max_nft_items = max_nft_items;
    }

    receive(msg: TokenNotification)
    {
        require(self.jettonWallet == sender(), "Jetton not supported.");
        require(msg.amount >= self.mint_jetton_amount, "Jetton amount is not enough.");
        // require(self.next_index < self.max_nft_items, "Max NFT items reached.");
        if(self.next_index >= self.max_nft_items){
            send(SendParameters{
                to: self.jettonWallet!!,
                value: 0,
                mode: SendRemainingValue | SendIgnoreErrors,
                body: TokenTransfer{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    destination: msg.sender, // not jetton wallet
                    response_destination: msg.sender,
                    custom_payload: null,
                    forward_ton_amount: ton("0.0001"),
                    forward_payload: self.GetComment("Mint is over.")
                }.toCell()
            });
        }

        // require(self.usedWallets.get(sender()) == null, "This walled is used");
        else if (self.usedWallets.get(msg.sender) != null) {
            send(SendParameters{
                to: self.jettonWallet!!,
                value: 0,
                mode: SendRemainingValue | SendIgnoreErrors,
                body: TokenTransfer{
                queryId: msg.queryId,
                amount: msg.amount,
                destination: msg.sender, // not jetton wallet
                response_destination: msg.sender,
                custom_payload: null,
                forward_ton_amount: ton("0.0001"),
                forward_payload: self.GetComment("Only 1 NFT per wallet.")
                }.toCell()
            });
        }
        else {
            self.usedWallets.set(msg.sender, true);

            let nft_init: StateInit = initOf NftItem(myAddress(), self.next_index);
            let nft_address: Address = contractAddress(nft_init);
            send(SendParameters{
                to: nft_address,
                value: ton("0.05"),
                mode: SendPayGasSeparately,
                bounce: false,
                data: nft_init.data,
                code: nft_init.code,
                body: NftDeploy{
                    index: self.next_index,
                    owner: msg.sender,
                    content: self.GetOffchainLink("https://storage.anon.tg/nft/anon_8club/nft.json"),
                    royalty_destination: self.royalty_destination,
                    numerator: self.numerator,
                    denominator: self.denominator
                }.toCell()});
            self.next_index = self.next_index + 1;
        }
    }


    receive(msg: ChangeJettonWallet) {
        self.requireOwner();
        self.jettonWallet = msg.address;
    }

    receive("Totup"){
        self.requireOwner();
    }

    receive("Finish"){
        self.requireOwner();
        self.usedWallets = emptyMap();
    }



    get fun get_collection_data(): CollectionData {
        return CollectionData{next_index: self.next_index, content: self.content, owner: self.owner};
    }

    // ------------------ Get Function  ------------------ //

    get fun get_nft_address_by_index(index: Int): Address {
        return contractAddress(initOf NftItem(myAddress(), index));
    }
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    fun GetOffchainLink(Link: String): Cell {
        let sb: StringBuilder = beginString();
        sb.append(Link);
        return beginCell()
        .storeUint(1, 8)
        .storeSlice(sb.toSlice())
        .endCell();
    }

    fun GetComment(Comment: String): Slice {
        let sb: StringBuilder = beginTailString();
        sb.append(Comment);
        return beginCell().storeUint(0, 1 + 32).storeSlice(sb.toSlice()).endCell().asSlice();
    }
}