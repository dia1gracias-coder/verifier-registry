import "@stdlib/ownable";
import "./wallet_lp.tact";
import "./tep74/messages.tact";
// ============================================================================================= //
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

    receive(msg: TokenUpdateContent){
        self.requireOwner();
        self.content = msg.content;
    }

    // @dev https://github.com/ton-blockchain/TEPs/blob/master/text/0089-jetton-wallet-discovery.md
    receive(msg: ProvideWalletAddress){
        // 0x2c76b973
        require(
            context().value >= ton("0.0061"), 
            "LPWallet: Insufficient gas"
        );

        let init: StateInit = initOf LPWallet(msg.owner_address, myAddress());

        if (msg.include_address) {
            send(SendParameters{
                    to:     sender(),
                    value:  0,
                    mode:   SendRemainingValue,
                    body:   TakeWalletAddress{
                        query_id:           msg.query_id,
                        wallet_address:     contractAddress(init),
                        owner_address:      beginCell()
                                                .storeBool(true)
                                                .storeAddress(msg.owner_address)
                                            .endCell()
                                            .asSlice()
                    }.toCell()
                }
            );
        } else {
            send(SendParameters{
                    to:     sender(),
                    value:  0,
                    mode:   SendRemainingValue,
                    body:   TakeWalletAddress{ // 0xd1735400
                        query_id:           msg.query_id,
                        wallet_address:     contractAddress(init),
                        owner_address:      beginCell()
                                                .storeBool(false)
                                            .endCell()
                                            .asSlice()
                    }.toCell()
                }
            );
        }
    }

    //********************************************//
    //             Internal functions             //
    //********************************************//

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf LPWallet(address, myAddress());
    }

    fun _get_wallet_address(owner: Address): Address {
        return contractAddress(self.getJettonWalletInit(owner));
    }

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
    fun mint(to: Address, amount: Int, response_destination: Address) {

        require(self.mintable, "LPWallet: Can't Mint Anymore");

        self.total_supply += amount;

        self.query_id += 1;

        let winit: StateInit = self.getJettonWalletInit(to);

        send(SendParameters{
                to:         contractAddress(winit),
                value:      0,
                bounce:     true,
                mode:       SendRemainingValue,
                body:       TokenTransferInternal{
                    query_id:               self.query_id,
                    amount:                 amount,
                    from:                   myAddress(),
                    response_destination:   response_destination,
                    forward_ton_amount:     0,
                    forward_payload:        beginCell().endCell().asSlice()
                }.toCell(),
                code:       winit.code,
                data:       winit.data
            }
        );
    }

    // @from the account to burn from
    // @amount the number of jettons to burn
    fun burn(from: Address, amount: Int) {

        self.query_id += 1;
        
        send(SendParameters{
            to:         self._get_wallet_address(from),
            value:      0,
            bounce:     true,
            mode:       SendRemainingValue,
            body:       TokenBurn {
                query_id:               self.query_id,
                amount:                 amount,
                response_destination:   myAddress(),
                custom_payload:         null
            }.toCell()
        });
    }

    // @owner the current wallet's owner
    fun requireSenderAsWalletOwner(owner: Address) {
        require(
            self._get_wallet_address(owner) == context().sender, 
            "LPWallet: Invalid sender"
        );
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
                wallet_code:    initOf LPWallet(self.owner, myAddress()).code
            };
    }

    get fun get_wallet_address(owner: Address): Address {
        return self._get_wallet_address(owner);
    }
}