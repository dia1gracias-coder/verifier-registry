import "@stdlib/ownable";
import "@stdlib/stoppable";
import "./wallet";
/* ===== JETTON CONTRACT ===== */
@interface("org.ton.jetton.master")
trait Jetton with OwnableTransferable, Resumable {
    /* ===== VARIABLES ===== */

    /* Jetton Trait */
    total_supply: Int;
    mintable: Bool;
    content: Cell;
    /* OwnableTransferable Trait */
    owner: Address;
    /* Resumable Trait */
    stopped: Bool;

    /* ===== RECEIVES ===== */
    receive(msg: TokenUpdateContent){
        self.requireOwner();
        self.content = msg.content;
    }

    receive(msg: TokenBurnNotification){
        self.requireJettonWallet(msg.owner);
        self.total_supply = (self.total_supply - msg.amount);
        if (msg.response_destination != null) {
            send(SendParameters{
                    to: msg.response_destination!!,
                    value: 0,
                    bounce: false,
                    mode: (SendRemainingValue + SendIgnoreErrors),
                    body: TokenExcesses{query_id: msg.query_id}.toCell()
                }
            );
        }
    }

    /* ===== FUNCTIONS ===== */

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
     fun mint(to: Address, amount: Int, response_destination: Address) {
        self.total_supply = (self.total_supply + amount);
        let winit: StateInit = self.getJettonWalletInit(to);
        send(SendParameters{
                to: contractAddress(winit),
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: TokenTransferInternal{
                    query_id: 0,
                    amount: amount,
                    from: myAddress(),
                    response_destination: response_destination,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    /* ===== HELPER FUNCTIONS ===== */

     fun requireJettonWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonWallet(myAddress(), address);
    }

    // ===== GET FUNCTIONS ===== //

    get fun get_jetton_data(): JettonData {
        let winit: StateInit = self.getJettonWalletInit(self.owner);
        return
            JettonData{
                total_supply: self.total_supply,
                mintable: self.mintable,
                admin_address: self.owner,
                jetton_content: self.content,
                jetton_wallet_code: winit.code
            };
    }

    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }
}
/* ===== STRUCTS ===== */
struct JettonData {
    total_supply: Int;
    mintable: Bool;
    admin_address: Address;
    jetton_content: Cell;
    jetton_wallet_code: Cell;
}
/* ===== MESSAGES ===== */
message Mint {
    amount: Int;
    receiver: Address;
}
message TokenUpdateContent {
    content: Cell;
}