import "@stdlib/deploy";
import "@stdlib/deploy";
import "@stdlib/ownable";
import "./stable_messages";
import "./stable_wallet";
import "./access_control";
struct MasterData {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    jetton_content: Cell;
    jetton_wallet_code: Cell;
}
struct ContractRoles {
    default_role: Int;
    minter_role: Int;
    admin_role: Int;
}

// @interface("org.ton.jetton.master")
contract StableMaster with Deployable, AccessControl {
    const ADMIN_ROLE: Int = sha256("ADMIN_ROLE");
    const MINTER_ROLE: Int = sha256("MINTER_ROLE");
    totalSupply: Int as coins;
    mintable: Bool;
    burnable: Bool;
    owner: Address;
    jetton_content: Cell;
    roles: map<Int, RoleData>;
    seqno: Int;
    init(content: Cell, owner: Address){
        self.mintable = true;
        self.burnable = true;
        self.owner = owner;
        self.jetton_content = content;
        self.totalSupply = 0;
        self.seqno = 10;
        self.__AccessControlInit__(owner);
    }

    receive(msg: UpdateStatus){
        self._checkRole(self.ADMIN_ROLE, sender());
        send(SendParameters{
                to: self.get_wallet_address(msg.owner),
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: msg.toCell()
            }
        );
    }

    receive(msg: Mint){
        self._checkRole(self.MINTER_ROLE, sender());
        require(self.mintable, "Minting is not allowed");
        self.mint(msg.amount, msg.receiver);
    }

    receive(msg: TokenBurn){
        self._checkRole(self.MINTER_ROLE, sender());
        require(self.burnable, "Burning is not allowed");
        send(SendParameters{
                to: self.get_wallet_address(msg.owner),
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: msg.toCell()
            }
        );
    }

    receive(msg: TokenBurnNotification){
        require(self.get_wallet_address(msg.owner) == sender(), "Invalid sender");
        self.totalSupply = self.totalSupply - msg.amount; // Update supply

        if (msg.response_destination != null) {
            // Cashback
            send(SendParameters{
                    to: msg.response_destination!!,
                    value: 0,
                    bounce: false,
                    mode: SendRemainingValue + SendIgnoreErrors,
                    body: TokenExcesses{queryId: msg.queryId}.toCell()
                }
            );
        }
    }

    fun mint(amount: Int, receiver: Address) {
        self.totalSupply = self.totalSupply + amount;
        let winit: StateInit = self.getJettonWalletInit(receiver);
        send(SendParameters{
                to: contractAddress(winit),
                value: 0,
                bounce: true,
                mode: SendRemainingValue,
                body: TokenTransferInternal{
                    queryId: 0,
                    amount: amount,
                    from: myAddress(),
                    response_destination: receiver,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    bounced(src: bounced<TokenTransferInternal>){
        self.totalSupply = self.totalSupply - src.amount;
    }

    get fun getContractRoles(): ContractRoles {
        return
            ContractRoles{
                default_role: self.DEFAULT_ADMIN_ROLE,
                minter_role: self.MINTER_ROLE,
                admin_role: self.ADMIN_ROLE
            };
    }

    fun getJettonWalletInit(wallet_owner: Address): StateInit {
        return initOf StableWallet(myAddress(), wallet_owner);
    }

    get fun get_jetton_data(): MasterData {
        return
            MasterData{
                total_supply: self.totalSupply,
                mintable: self.mintable,
                owner: self.owner,
                jetton_content: self.jetton_content,
                jetton_wallet_code: self.getJettonWalletInit(myAddress()).code
            };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(self.getJettonWalletInit(owner));
    }
}