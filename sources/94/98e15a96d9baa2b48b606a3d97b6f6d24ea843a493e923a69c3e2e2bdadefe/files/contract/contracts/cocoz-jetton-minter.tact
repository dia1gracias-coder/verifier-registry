import "./cocoz-jetton-wallet";
import "./messages";
import "./constants";
import "./utils.tact";

struct ClaimableJetton {
    amount: Int;
}

struct JettonMinterState {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

struct CocozSupplyState {
    totalSupply: Int as coins;
    totalReserveSupply: Int as coins;
    rewardTotalSupply: Int as coins;
    rewardReserveSupply: Int as coins;
    operationTotalSupply: Int as coins;
    operationReserveSupply: Int as coins;
    marinaProtocolTotalSupply: Int as coins;
    marinaProtocolReserveSupply: Int as coins;
    cocozNftTotalSupply: Int as coins;
    cocozNftReserveSupply: Int as coins;
    openNetworkTotalSupply: Int as coins;
    openNetworkReserveSupply: Int as coins;
}

struct ClaimableSupplyState {
    maxSupply: Int as coins;
    totalSupply: Int as coins;
    reserveSupply: Int as coins;
    claimables: map<Address, Int as coins>;
}

contract CocozJettonMinter {
    owner: Address;
    jettonContent: Cell;
    mintable: Bool;

    totalSupply: Int as coins = 0;
    totalReserveSupply: Int as coins = 0;
    const maxSupply: Int = 10_000_000_000 * 1_000_000_000;

    reward: ClaimableSupplyState = ClaimableSupplyState {
        maxSupply: 3_000_000_000 * 1_000_000_000,
        totalSupply: 0,
        reserveSupply: 0,
        claimables: emptyMap(),
    };

    operation: ClaimableSupplyState = ClaimableSupplyState {
        maxSupply: 1_500_000_000 * 1_000_000_000,
        totalSupply: 0,
        reserveSupply: 0,
        claimables: emptyMap(),
    };

    marinaProtocol: ClaimableSupplyState = ClaimableSupplyState {
        maxSupply: 400_000_000 * 1_000_000_000,
        totalSupply: 0,
        reserveSupply: 0,
        claimables: emptyMap(),
    };

    cocozNft: ClaimableSupplyState = ClaimableSupplyState {
        maxSupply: 100_000_000 * 1_000_000_000,
        totalSupply: 0,
        reserveSupply: 0,
        claimables: emptyMap(),
    };

    openNetwork: ClaimableSupplyState = ClaimableSupplyState {
        maxSupply: 5_000_000_000 * 1_000_000_000,
        totalSupply: 0,
        reserveSupply: 0,
        claimables: emptyMap(),
    };

    init(owner: Address, jettonContent: Cell, mintable: Bool) {
        self.owner = owner;
        self.jettonContent = jettonContent;
        self.mintable = mintable;
    }

    // ===============================
    // Default Receive
    // ===============================
    receive() {
        if (sender() != self.owner) {
            message(MessageParameters {
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: beginCell().endCell(),
            });
        }
    }

    // ===============================
    // Reward
    // ===============================
    receive(msg: AllocateRewardClaim) {
        let totalAmount = 0;
        foreach (address, amount in msg.destinations) {
            let prev = self.reward.claimables.get(address);
            if (prev != amount) {
                self.reward.claimables.set(address, amount);
                totalAmount += (amount - (prev != null ? prev!! : 0));
            }
        }

        self.requireAllocateClaim(self.reward, totalAmount);

        self.totalReserveSupply += totalAmount;
        self.reward.reserveSupply += totalAmount;

        message(MessageParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: beginCell().endCell(),
        });
    }

    receive(msg: RewardClaimJetton) {
        let amount = self.requireClaimJetton(self.reward);

        let _ = self.reward.claimables.del(sender());
        self.reward.reserveSupply -= amount;
        self.reward.totalSupply += amount;

        self.claimJetton(msg.queryId, amount, sender());
    }

    receive(msg: MintForReward) {
        self.requireMint(self.reward, msg.mintMessage.amount);
        self.mint(msg.destination, msg.mintMessage);
        self.reward.totalSupply += msg.mintMessage.amount;
    }

    // ===============================
    // Operation
    // ===============================
    receive(msg: AllocateOperationClaim) {
        let totalAmount = 0;
        foreach (address, amount in msg.destinations) {
            let prev = self.operation.claimables.get(address);
            if (prev != amount) {
                self.operation.claimables.set(address, amount);
                totalAmount += (amount - (prev != null ? prev!! : 0));
            }
        }

        self.requireAllocateClaim(self.operation, totalAmount);

        self.totalReserveSupply += totalAmount;
        self.operation.reserveSupply += totalAmount;

        message(MessageParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: beginCell().endCell(),
        });
    }

    receive(msg: OperationClaimJetton) {
        let amount = self.requireClaimJetton(self.operation);
        let _ = self.operation.claimables.del(sender());
        self.operation.reserveSupply -= amount;
        self.operation.totalSupply += amount;
        self.claimJetton(msg.queryId, amount, sender());
    }

    receive(msg: MintForOperation) {
        self.requireMint(self.operation, msg.mintMessage.amount);
        self.mint(msg.destination, msg.mintMessage);
        self.operation.totalSupply += msg.mintMessage.amount;
    }

    // ===============================
    // Marina Protocol
    // ===============================
    receive(msg: AllocateMarinaProtocolClaim) {
        let totalAmount = 0;

        foreach (address, amount in msg.destinations) {
            let prev = self.marinaProtocol.claimables.get(address);
            if (prev != amount) {
                self.marinaProtocol.claimables.set(address, amount);
                totalAmount += (amount - (prev != null ? prev!! : 0));
            }
        }

        self.requireAllocateClaim(self.marinaProtocol, totalAmount);

        self.totalReserveSupply += totalAmount;
        self.marinaProtocol.reserveSupply += totalAmount;

        message(MessageParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: beginCell().endCell(),
        });
    }

    receive(msg: MarinaProtocolClaimJetton) {
        let amount = self.requireClaimJetton(self.marinaProtocol);

        let _ = self.marinaProtocol.claimables.del(sender());
        self.marinaProtocol.reserveSupply -= amount;
        self.marinaProtocol.totalSupply += amount;

        self.claimJetton(msg.queryId, amount, sender());
    }

    receive(msg: MintForMarinaProtocol) {
        self.requireMint(self.marinaProtocol, msg.mintMessage.amount);
        self.mint(msg.destination, msg.mintMessage);
        self.marinaProtocol.totalSupply += msg.mintMessage.amount;
    }

    // ===============================
    // Cocoz NFT
    // ===============================
    receive(msg: AllocateCocozNftClaim) {
        let totalAmount = 0;

        foreach (address, amount in msg.destinations) {
            let prev = self.cocozNft.claimables.get(address);
            if (prev != amount) {
                self.cocozNft.claimables.set(address, amount);
                totalAmount += (amount - (prev != null ? prev!! : 0));
            }
        }

        self.requireAllocateClaim(self.cocozNft, totalAmount);
        
        self.totalReserveSupply += totalAmount;
        self.cocozNft.reserveSupply += totalAmount;
        
        message(MessageParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: beginCell().endCell(),
        });
    }

    receive(msg: CocozNftClaimJetton) {
        let amount = self.requireClaimJetton(self.cocozNft);

        let _ = self.cocozNft.claimables.del(sender());
        self.cocozNft.reserveSupply -= amount;
        self.cocozNft.totalSupply += amount;

        self.claimJetton(msg.queryId, amount, sender());
    }

    receive(msg: MintForCocozNft) {
        self.requireMint(self.cocozNft, msg.mintMessage.amount);
        self.mint(msg.destination, msg.mintMessage);
        self.cocozNft.totalSupply += msg.mintMessage.amount;
    }

    // ===============================
    // The Open Network
    // ===============================
    receive(msg: AllocateOpenNetworkClaim) {
        let totalAmount = 0;

        foreach (address, amount in msg.destinations) {
            let prev = self.openNetwork.claimables.get(address);
            if (prev != amount) {
                self.openNetwork.claimables.set(address, amount);
                totalAmount += (amount - (prev != null ? prev!! : 0));
            }
        }

        self.requireAllocateClaim(self.openNetwork, totalAmount);
        
        self.totalReserveSupply += totalAmount;
        self.openNetwork.reserveSupply += totalAmount;
        
        message(MessageParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: beginCell().endCell(),
        });
    }

    receive(msg: OpenNetworkClaimJetton) {
        let amount = self.requireClaimJetton(self.openNetwork);

        let _ = self.openNetwork.claimables.del(sender());
        self.openNetwork.reserveSupply -= amount;
        self.openNetwork.totalSupply += amount;

        self.claimJetton(msg.queryId, amount, sender());
    }

    receive(msg: MintForOpenNetwork) {
        self.requireMint(self.openNetwork, msg.mintMessage.amount);
        self.mint(msg.destination, msg.mintMessage);
        self.openNetwork.totalSupply += msg.mintMessage.amount;
    }

    // ===============================
    // Default Jetton Receive
    // ===============================
    receive(msg: Mint) {
        self.requireMint(self.reward, msg.mintMessage.amount);
        self.mint(msg.destination, msg.mintMessage);
        self.reward.totalSupply += msg.mintMessage.amount;
    }

    receive(msg: ProvideWalletAddress) {
        let ownerWorkchain: Int = parseStdAddress(msg.ownerAddress.asSlice()).workchain;

        // If owner is basechain address, we can calculate jettonWallet
        let targetJettonWallet: BasechainAddress = (ownerWorkchain == Basechain)
            ? contractBasechainAddress(initOf CocozJettonWallet(0, msg.ownerAddress, myAddress()))
            : emptyBasechainAddress();

        message(MessageParameters {
            body: makeTakeWalletAddressMsg(targetJettonWallet, msg),
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
        });
    }

    receive(msg: JettonBurnNotification) {
        let sender = parseStdAddress(sender().asSlice());
        let wallet = getJettonBasechainWalletByOwner(msg.sender);

        // Workchain 0 is basechain
        require(sender.workchain == Basechain && sender.address == wallet.hash!!, "Unauthorized burn");

        self.totalSupply -= msg.amount;

        if (msg.responseDestination != null) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors, // ignore errors, because supply has already been updated
            });
        }
    }

    receive(msg: JettonUpdateContent) {
        require(sender() == self.owner, "Incorrect sender");
        self.jettonContent = msg.content;
    }

    receive(msg: ChangeOwner) {
        require(sender() == self.owner, "Incorrect sender");
        self.owner = msg.newOwner;
    }

    receive(msg: CloseMinting) {
        require(sender() == self.owner, "Incorrect sender");
        self.mintable = false;
        cashback(sender());
    }

    receive(msg: ClaimTON) {
        require(sender() == self.owner, "Incorrect sender");
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);

        // we allow bounce here and don't handle it, if claim fails we just accept the TONs back
        message(MessageParameters {
            bounce: true,
            to: msg.destination,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive(msg: WithdrawAll) {
        require(sender() == self.owner, "Incorrect sender");

        message(MessageParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode:SendRemainingBalance | SendIgnoreErrors,
        });
    }

    // ===============================
    // Bounced
    // ===============================
    bounced(msg: bounced<JettonTransferInternal>) {
        self.totalSupply -= msg.amount;
    }

    // ===============================
    // Requires
    // ===============================
    fun requireAllocateClaim(state: ClaimableSupplyState, amount: Int) {
        require(sender() == self.owner, "Not admin");
        require(self.mintable, "Mint is closed");
        require(self.totalSupply + self.totalReserveSupply + amount <= self.maxSupply, "Max pool is full");
        require(state.totalSupply + state.reserveSupply + amount <= state.maxSupply, "State pool is full");
    }

    fun requireClaimJetton(state: ClaimableSupplyState): Int {
        require(self.mintable, "Mint is closed");
        let claim = state.claimables.get(sender());
        let amount = claim != null ? claim!! : 0;
        require(amount > 0, "Nothing to claim");

        return amount;
    }

    fun requireMint(state: ClaimableSupplyState, amount: Int) {
        require(sender() == self.owner, "Incorrect sender");
        require(self.mintable, "Mint is closed");
        require(self.totalSupply + self.totalReserveSupply + amount <= self.maxSupply, "Max pool is full");
        require(state.totalSupply + state.reserveSupply + amount <= state.maxSupply, "State pool is full");
    }

    // ===============================
    // Functions
    // ===============================
    fun claimJetton(queryId: Int, amount: Int, destination: Address) {
        self.totalReserveSupply -= amount;
        self.totalSupply += amount;

        let transferMsg = JettonTransferInternal {
            queryId: queryId,
            amount: amount,
            sender: self.owner,
            responseDestination: destination,
            forwardTonAmount: 0,
            forwardPayload: beginCell().endCell().asSlice(),
        };

        deploy(DeployParameters {
            value: 0,
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: transferMsg.toCell(),
            init: getJettonWalletInit(destination),
        });
    }

    fun mint(destination: Address, mintMessage: JettonTransferInternal) {
        checkEitherForwardPayload(mintMessage.forwardPayload);

        let ctx = context();

        // we don't add compute fees for mint itself and reserve here
        // it's okay since it's sent only by the admin and excesses will return back
        require(
            ctx.value >
            minTonsForStorage +
            mintMessage.forwardTonAmount +
            ctx.readForwardFee() +
            2 * getComputeFee(gasForTransfer, false),
            "Insufficient gas for mint",
        );

        self.totalSupply += mintMessage.amount;

        // basechain destination is calculated inside deploy function
        deploy(DeployParameters {
            value: 0, // ignore msg.destinationnAmount and use SendMode 64 instead
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: mintMessage.toCell(),
            init: getJettonWalletInit(destination),
        });
    }

    get fun get_jetton_data(): JettonMinterState {
        return JettonMinterState {
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            adminAddress: self.owner,
            jettonContent: self.jettonContent,
            jettonWalletCode: codeOf CocozJettonWallet,
        };
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return getJettonWalletByOwner(ownerAddress);
    }

    get fun get_supply_status(): CocozSupplyState {
        return CocozSupplyState {
            totalSupply: self.totalSupply,
            totalReserveSupply: self.totalReserveSupply,
            rewardTotalSupply: self.reward.totalSupply,
            rewardReserveSupply: self.reward.reserveSupply,
            operationTotalSupply: self.operation.totalSupply,
            operationReserveSupply: self.operation.reserveSupply,
            marinaProtocolTotalSupply: self.marinaProtocol.totalSupply,
            marinaProtocolReserveSupply: self.marinaProtocol.reserveSupply,
            cocozNftTotalSupply: self.cocozNft.totalSupply,
            cocozNftReserveSupply: self.cocozNft.reserveSupply,
            openNetworkTotalSupply: self.openNetwork.totalSupply,
            openNetworkReserveSupply: self.openNetwork.reserveSupply,
        };
    }

    get fun get_reward_supply_state(): ClaimableSupplyState {
        return self.reward;
    }

    get fun get_operation_supply_state(): ClaimableSupplyState {
        return self.operation;
    }

    get fun get_marina_protocol_supply_state(): ClaimableSupplyState {
        return self.marinaProtocol;
    }

    get fun get_cocoz_nft_supply_state(): ClaimableSupplyState {
        return self.cocozNft;
    }

    get fun get_open_network_supply_state(): ClaimableSupplyState {
        return self.openNetwork;
    }

    get fun get_reward_claimable_amount(address: Address): Int {
        let amount = self.reward.claimables.get(address);
        return amount != null ? amount!! : 0;
    }

    get fun get_operation_claimable_amount(address: Address): Int {
        let amount = self.operation.claimables.get(address);
        return amount != null ? amount!! : 0;
    }

    get fun get_marina_protocol_claimable_amount(address: Address): Int {
        let amount = self.marinaProtocol.claimables.get(address);
        return amount != null ? amount!! : 0;
    }

    get fun get_cocoz_nft_claimable_amount(address: Address): Int {
        let amount = self.cocozNft.claimables.get(address);
        return amount != null ? amount!! : 0;
    }

    get fun get_open_network_claimable_amount(address: Address): Int {
        let amount = self.openNetwork.claimables.get(address);
        return amount != null ? amount!! : 0;
    }
}

inline fun getJettonWalletInit(address: Address): StateInit {
    return initOf CocozJettonWallet(0, address, myAddress());
}

inline fun getJettonWalletByOwner(jettonWalletOwner: Address): Address {
    return contractAddress(getJettonWalletInit(jettonWalletOwner));
}

inline fun getJettonBasechainWalletByOwner(jettonWalletOwner: Address): BasechainAddress {
    return contractBasechainAddress(getJettonWalletInit(jettonWalletOwner));
}
