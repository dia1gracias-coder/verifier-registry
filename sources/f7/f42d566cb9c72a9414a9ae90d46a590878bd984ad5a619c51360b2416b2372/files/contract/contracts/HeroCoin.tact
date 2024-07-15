import "@stdlib/deploy";
import "@stdlib/ownable";
import "./constants/Error.tact";
import "./messages/Jetton.tact";
import "./messages/Vesting.tact";
import "./HeroCoinWallet.tact";
import "./HeroVestingWallet.tact";

struct JettonData {
    totalSupply: Int; // Total amount of circulating jettons
    mintable: Bool;   // Flag if new jettons can be minted or not
    owner: Address;   // Owner address of the current contract
    content: Cell;    // Jetton's content (metadata)
    walletCode: Cell; // Jetton wallet's code
}

/**
 * @dev This contract implements the master contract for Hero Coin, which creates
 * TON fungible tokens in accordance with the Jettons standard specification
 * https://github.com/ton-blockchain/TEPs/blob/master/text/0074-jettons-standard.md.
 *
 * It is used to mint new jettons, to vest them, to account for circulating supply
 * after burning and to provide Jetton's information as well as addresses of jetton
 * and vesting wallets.
 *
 * Jetton's content (metadata) is stored in the form defined by the Token data
 * standard specification
 * https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md
 *
 * Jetton circulating supply is subject to the hard cap, which respects both minted
 * and vesting (not already minted) jettons.
 */
@interface("org.ton.jetton.master")
contract HeroCoin with Deployable, OwnableTransferable {
    owner: Address;
    content: Cell;
    mintable: Bool;
    totalSupply: Int as coins;
    cap: Int as coins; 

    /**
     * @dev Initializes the contract with the following parameters:
     * - `owner` is the contract admin's address.
     * - `content` is a cell containing Jetton's metadata.
     * - `cap` is the hard cap of the circulating supply.
     */
    init(owner: Address, content: Cell, cap: Int) {
        self.owner = owner;
        self.content = content;
        self.mintable = true;
        self.totalSupply = 0;
        self.cap = cap;
    }

    /**
     * @dev Handles a message to update Jetton's content (metadata) stored in
     * the form defined by the Token Data standard specification
     * https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md 
     * 
     * Requirements:
     * - The sender is restricted to the owner of the master contract.
     * 
     * Actions:
     * - Sends the UpdateContentOk message back to the sender.
     */
    receive(msg: UpdateContent) {
        self.requireOwner();

        self.content = msg.content;
        self.reply(UpdateContentOk{query_id: msg.query_id}.toCell());
    }

    /**
     * @dev Handles a message to mint an amount of jettons for a given recipient
     * address. The circulating supply will be increased only after a successful call
     * from the contract's owner, who is responsible for minting. If this call comes
     * from the owner of vesting wallet, the circulating supply won't be affected as
     * it has been accounted for on the previous vesting step.
     * 
     * Requirements:
     * - The sender is restricted either to the contract's owner or to the owner of
     *   a vesting wallet.
     * - Minting must be allowed on the current contract.
     * - The circulating supply of jettons including the minted ones must be below
     *   the hard cap.
     *
     * Actions:
     * - Sends the InternalTransfer message to the recipient's jetton wallet. If the
     *   wallet doesn't exist, it will be deployed.
     */
    receive(msg: Mint) {
        let isOwner: Bool = sender() == self.owner();
        if (!isOwner) {
            nativeThrowUnless(ERROR_CODE_ACCESS_DENIED, sender() == self.get_vesting_address(msg.to));
        }

        require(self.mintable, "Mint: Forbidden");
        require(self.totalSupply + msg.amount <= self.cap, "Mint: Cap reached");

        if (isOwner) {
            self.updateTotalSupply(msg.amount);
        }

        let stateInit: StateInit = self.getJettonWalletInit(msg.to);
        send(SendParameters{
            to: contractAddress(stateInit), 
            value: 0, 
            mode: SendRemainingValue,
            bounce: false,
            body: InternalTransfer{ 
                query_id: msg.query_id,
                amount: msg.amount,
                from: myAddress(),
                response_destination: msg.response_destination,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: stateInit.code,
            data: stateInit.data
        });
    }

    /**
     * @dev Handles a message to vest an amount of jettons for a given recipient
     * address. The circulating supply will be increased after a successfull call.
     * 
     * Requirements:
     * - The sender is restricted to the contract's owner.
     * - Minting must be allowed on the current contract.
     * - The circulating supply of jettons including the vesting ones must be below
     *   the hard cap.
     *
     * Actions:
     * - Sends the InternalVest message to the recipient's vesting wallet. If the
     *   wallet doesn't exist, it will be deployed.
     */
    receive(msg: Vest) {
        self.requireOwner();
        require(self.mintable, "Vest: Forbidden");
        require(self.totalSupply + msg.amount <= self.cap, "Vest: Cap reached");

        self.updateTotalSupply(msg.amount);

        let stateInit: StateInit = self.getVestingWalletInit(msg.to);
        send(SendParameters{
            to: contractAddress(stateInit), 
            value: 0, 
            mode: SendRemainingValue,
            bounce: false,
            body: InternalVest{
                query_id: msg.query_id,
                amount: msg.amount,
                start: msg.start,
                duration: msg.duration,
                response_destination: sender(),
                force: msg.force,
            }.toCell(),
            code: stateInit.code,
            data: stateInit.data
        });
    }

    /**
     * @dev Handles a message to handle a burn notificaiton from the jetton wallet's
     * owner. The circulating supply will be decreased after a successful call.
     * 
     * Requirements:
     * - The sender is restricted to the jetton wallet's owner only.
     *
     * Actions:
     * - Sends the Excesses message with remaining Toncoins to the burn initiator.
     */
    receive(msg: BurnNotification) {
        let stateInit: StateInit = self.getJettonWalletInit(msg.owner);
        nativeThrowUnless(ERROR_CODE_ACCESS_DENIED, sender() == contractAddress(stateInit));

        self.totalSupply = self.totalSupply - msg.amount;

        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!, 
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body: Excesses{ query_id: msg.query_id }.toCell()
            });
        }
    }

    /**
     * @dev Updates the circulating supply of jettons. If the supply reaches the hard
     * cap, minting will be forbidden.
     */
    fun updateTotalSupply(amount: Int) {
        self.totalSupply += amount;
        if (self.totalSupply >= self.cap) {
            self.mintable = false;
        }
    }

    /**
     * @dev Gets state init of the jetton wallet for a given owner.
     */
    fun getJettonWalletInit(owner: Address): StateInit {
        return initOf HeroCoinWallet(myAddress(), owner);
    }

    /**
     * @dev Gets state init of the vesting wallet for a given owner.
     */
    fun getVestingWalletInit(owner: Address): StateInit {
        return initOf HeroVestingWallet(myAddress(), owner);
    }

    /**
     * @dev Gets Jetton's information.
     */
    get fun get_jetton_data(): JettonData {
        let stateInit: StateInit = self.getJettonWalletInit(myAddress());
        return JettonData{ 
            totalSupply: self.totalSupply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            walletCode: stateInit.code
        };
    }

    /**
     * @dev Gets the jetton wallet address for a given owner.
     */
    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(self.getJettonWalletInit(owner));
    }

    /**
     * @dev Gets the vesting wallet address for a given owner.
     */
    get fun get_vesting_address(owner: Address): Address {
        return contractAddress(self.getVestingWalletInit(owner));
    }
} 
