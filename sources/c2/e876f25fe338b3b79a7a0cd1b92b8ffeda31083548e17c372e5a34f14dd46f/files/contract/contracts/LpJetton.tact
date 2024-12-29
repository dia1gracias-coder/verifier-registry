import "@stdlib/ownable";
import "./wallet_lp.tact";
import "./tep74/messages.tact";
// ============================================================================================================ //
@interface("org.ton.jetton.master")
trait LPJetton with Ownable {
    total_supply:   Int;        // The total amount of minted tokens
    mintable:       Bool;       // Mintability flag
    owner:          Address;    // The contract's owner
    content:        Cell;       // Token metadata
    query_id:       Int;        // Sent messages counter

    //********************************************//
    //             Message Processing             //
    //********************************************//

    receive(){}

    receive(msg: TokenUpdateContent){
        self.requireOwner(); // Allow changing content only by owner
        self.content = msg.content; // Update content
    }

    // https://github.com/ton-blockchain/TEPs/blob/master/text/0089-jetton-wallet-discovery.md
    receive(msg: ProvideWalletAddress){
        // 0x2c76b973
        require(context().value >= ton("0.0061"), "Insufficient gas");
        let init: StateInit = initOf LPWallet(msg.owner_address, myAddress());
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
                }
            );
        } else {
            send(SendParameters{
                    to: sender(),
                    value: 0,
                    mode: SendRemainingValue,
                    body: TakeWalletAddress{ // 0xd1735400
                        query_id: msg.query_id,
                        wallet_address: contractAddress(init),
                        owner_address: beginCell().storeBool(false).endCell().asSlice()
                    }.toCell()
                }
            );
        }
    }

    //********************************************//
    //             Internal functions             //
    //********************************************//

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
    fun mint(to: Address, amount: Int, response_destination: Address) {
        require(self.mintable, "Can't Mint Anymore");
        self.total_supply = (self.total_supply + amount); // Update the total supply
        self.query_id += 1;
        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
                to: contractAddress(winit),
                value: 0,
                bounce: true,
                mode: SendRemainingValue,
                body: TokenTransferInternal{
                    query_id: self.query_id,
                    amount: amount,
                    from: myAddress(),
                    response_destination: response_destination,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    fun burn(from: Address, amount: Int) {
        self.query_id += 1;
        send(SendParameters{
            to: self._get_wallet_address(from),
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenBurn {
                query_id: self.query_id,
                amount: amount,
                response_destination: myAddress(),
                custom_payload: null
            }.toCell()
        });
    }

    fun requireSenderAsWalletOwner(owner: Address) {
        let ctx: Context = context();
        require(self._get_wallet_address(owner) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf LPWallet(address, myAddress());
    }

    fun _get_wallet_address(owner: Address): Address {
        return contractAddress(self.getJettonWalletInit(owner));
    }

    //********************************************//
    //                 Get Methods                //
    //********************************************//

    get fun get_jetton_data(): JettonData {
        return
            JettonData{
                total_supply:   self.total_supply,
                mintable:       self.mintable,
                admin:          self.owner,
                content:        self.content,
                wallet_code: initOf LPWallet(self.owner, myAddress()).code
            };
    }

    get fun get_wallet_address(owner: Address): Address {
        return self._get_wallet_address(owner);
    }
}