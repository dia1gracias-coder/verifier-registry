import "@stdlib/ownable";
import "./jetton-default-wallet";

trait JettonMasterStandard with Ownable {

    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;

    /**
    * Sets the content field of this contract. Will only be invoked if message is sent by contract owner.
    * Metadata and URI must adhere to the 0064-token-data-standard: https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md
    *
    * @param msg The TokenUpdateContent message containing the following parameter:
    *      content: The new content URI of the Jetton
    */
    receive(msg: TokenUpdateContent) {
        self.requireOwner();
        self.content = msg.content;
    }

    /**
    * Updates the total supply field of this contract upon TokenBurn at JettonDefaultWallet. Will only be invoked if the message is sent by 
    * JettonDefaultWallet of owner.
    *
    * @param msg The TokenBurnNotification message containing the following parameter:
    *       queryId: Arbitrary request number
    *       amount: Aount of burned jettons
    *       owner: Address of the owner
    *       responseAddress: Address to send a response with confirmation of a successful burn and the rest of the incoming message coins
    */
    receive(msg: TokenBurnNotification) {
        self.requireWallet(msg.owner);
        self.totalSupply = self.totalSupply - msg.amount;

        if (msg.responseAddress != null) {
            send(SendParameters{
                to: msg.responseAddress!!, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    /**
    * Returns the Jetton wallet address of the owner of this contract.
    *
    * @param owner Address of owner
    */
    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }

    /**
    * Returns the Jetton data of this contract.
    */
    get fun get_jetton_data(): JettonData {
        let code: Cell = self.getJettonWalletInit(myAddress()).code;

        // Wokaround for TonClient, unable to read optionals
        let outputContent: Cell = emptyCell();
        if (self.content != null) {
            outputContent = self.content!!;
        }

        return JettonData{ 
            totalSupply: self.totalSupply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: outputContent, 
            walletCode: code
        };
    }

    /**
    * Private function to mint jettons to a recipient.
    *
    * @param to Address of recipient
    * @param amount Amount of nano-tons to mint
    * @param responseAddress Address to send any excess TON to
    */
    fun mint(to: Address, amount: Int, responseAddress: Address?) {
        // Update total supply
        self.totalSupply = self.totalSupply + amount;

        let winit: StateInit = self.getJettonWalletInit(to);
        let walletAddress: Address = contractAddress(winit);
        send(SendParameters{
            to: walletAddress, 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                amount: amount,
                queryId: 0,
                from: myAddress(),
                responseAddress: responseAddress,
                forwardTonAmount: 0,
                forwardPayload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    /**
    * Ensures that the sender's address is the Jetton wallet derived from the provided owner's address.
    *
    * @param owner Address of owner
    */
    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    /**
    * Returns the init code of the Jetton wallet of the specified owner.
    *
    * @param owner Address of owner
    */
    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(myAddress(), address);
    }
}

/***************************************** JettonMasterStandard structs *****************************************/

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;
    walletCode: Cell;
}

/***************************************** JettonMasterStandard messages *****************************************/

message TokenUpdateContent {
    content: Cell?;
}

message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    responseAddress: Address?;
}