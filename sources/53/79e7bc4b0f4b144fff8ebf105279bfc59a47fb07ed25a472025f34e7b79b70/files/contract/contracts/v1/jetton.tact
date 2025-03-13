import "@stdlib/ownable";
import "./jetton_wallet.tact";

trait Jetton with Ownable {

    total_supply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;

    // @msg The TokenUpdateContent message used to update the content of the jetton
    // @content The new content to be set for the jetton
    receive(msg: TokenUpdateContent) {
        self.requireOwner();                // Allow changing content only by owner
        self.content = msg.content;         // Update content
    }

    // @msg The TokenBurnNotification message that provides the details of the burning action
    // @amount The amount of jetton tokens being burned
    // @response_destination The address where excess funds (if any) should be sent
    receive(msg: TokenBurnNotification) {
        self.requireSenderAsWalletOwner(msg.response_destination!!);       // Check wallet
        self.total_supply = self.total_supply - msg.amount; // Update supply
        if (msg.response_destination != null) { // Cashback
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: TokenExcesses{ query_id: msg.query_id }.toCell()
            });
        }
    }

    // @msg The ProvideWalletAddress message with the details for wallet creation
    // @owner_address The address of the wallet owner
    // @include_address Whether or not the wallet address should be included in the response
    receive(msg: ProvideWalletAddress) {
        require(context().value >= ton("0.0061"), "Insufficient gas");
        let init: StateInit = initOf JettonWallet(msg.owner_address, myAddress());
        if (msg.include_address) {
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: TakeWalletAddress{
                    query_id: msg.query_id,
                    wallet_address: contractAddress(init),
                    owner_address: beginCell().storeBool(true).storeAddress(msg.owner_address).endCell().asSlice()
                }.toCell()
            });
        } else {
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: TakeWalletAddress { // 0xd1735400
                    query_id: msg.query_id,
                    wallet_address: contractAddress(init),
                    owner_address: beginCell().storeBool(false).endCell().asSlice()
                }.toCell()
            });
        }
    }

    // Private Methods

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
    fun mint(to: Address, amount: Int, response_destination: Address) {
        require(self.mintable, "Can't Mint Anymore");
        self.total_supply = self.total_supply + amount; // Update total supply

        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
            to: contractAddress(winit),
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransferInternal{
                query_id: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: 0,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    // @owner The address of the wallet owner to check against the sender
    fun requireSenderAsWalletOwner(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    // @address The address of the wallet for which initialization data is to be retrieved
    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonWallet(address, myAddress());
    }

    // ====== Get Methods ====== //

    // @returns JettonData containing the jetton's total supply, mintability status, owner, content, and wallet code
    get fun get_jetton_data(): JettonData {
        return JettonData{
            total_supply: self.total_supply,
            mintable: self.mintable,
            owner: self.owner,
            content: self.content,
            wallet_code: initOf JettonWallet(self.owner, myAddress()).code
        };
    }

    // @owner The address of the wallet owner
    // @returns The address of the wallet for the given owner
    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(initOf JettonWallet(owner, myAddress()));
    }
}
