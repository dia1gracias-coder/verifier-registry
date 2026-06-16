const OP_JETTON_TRANSFER: Int = 0x0f8a7ea5;
const OP_JETTON_EXCESS: Int = 0xd53276db;
const FALLBACK_DELAY_SECONDS: Int = 15 * 24 * 60 * 60;
const MAX_NODES: Int = 60;
const MIN_CLAIM_VALUE: Int = ton("0.1");

message(0x51a6f0c1) SetJettonWallet {
    wallet: Address;
}

message(0x0f8a7ea5) JettonTransferBounce {
    queryId: Int as uint64;
    amount: Int as coins;
}

message(0xd53276db) JettonExcess {
    queryId: Int as uint64;
}

struct ReleaseNode {
    releaseTime: Int as uint32;
    amount: Int as coins;
    claimedAmount: Int as coins;
    claimedBy: Int as uint2; // 0 = unclaimed, 1 = claimWallet, 2 = fallbackWallet
    pendingQueryId: Int as uint64;
    pendingAmount: Int as coins;
}

struct PendingClaim {
    amount: Int as coins;
    recipient: Address;
    claimedBy: Int as uint2;
    firstNode: Int as uint16;
    endNode: Int as uint16;
    active: Bool;
}

struct VestingConfig {
    setupWallet: Address;
    claimWallet: Address;
    fallbackWallet: Address;
    jettonWallet: Address;
    jettonWalletReady: Bool;
    claimJettonWallet: Address;
    fallbackJettonWallet: Address;
    totalAmount: Int as coins;
    nodesCount: Int as uint16;
    totalClaimed: Int as coins;
    nextQueryId: Int as uint64;
}

struct ReleaseNodeStatus {
    releaseTime: Int as uint32;
    amount: Int as coins;
    primaryUnlocked: Bool;
    fallbackUnlocked: Bool;
    claimed: Bool;
    claimedBy: Int as uint2; // 0 = unclaimed, 1 = claimWallet, 2 = fallbackWallet
    claimedAmount: Int as coins;
    pendingQueryId: Int as uint64;
    pendingAmount: Int as coins;
}

contract JettonVesting {
    setupWallet: Address;
    claimWallet: Address;
    fallbackWallet: Address;
    jettonWallet: Address;
    jettonWalletReady: Bool = false;
    claimJettonWallet: Address;
    fallbackJettonWallet: Address;
    totalAmount: Int as coins;
    nodes: map<Int as uint16, ReleaseNode>;
    pendingClaims: map<Int as uint64, PendingClaim>;
    nodesCount: Int as uint16;
    totalClaimed: Int as coins = 0;
    nextQueryId: Int as uint64 = 1;

    init(
        setupWallet: Address,
        claimWallet: Address,
        fallbackWallet: Address,
        claimJettonWallet: Address,
        fallbackJettonWallet: Address,
        totalAmount: Int as coins,
        nodes: map<Int as uint16, ReleaseNode>,
        nodesCount: Int as uint16
    ) {
        self.setupWallet = setupWallet;
        self.claimWallet = claimWallet;
        self.fallbackWallet = fallbackWallet;
        self.jettonWallet = setupWallet;
        self.claimJettonWallet = claimJettonWallet;
        self.fallbackJettonWallet = fallbackJettonWallet;
        self.totalAmount = totalAmount;
        self.nodes = nodes;
        self.nodesCount = nodesCount;

        require(claimWallet != fallbackWallet, "wallets match");
        require(claimJettonWallet != fallbackJettonWallet, "wallets match");
        require(claimWallet != claimJettonWallet, "invalid jetton wallet");
        require(claimWallet != fallbackJettonWallet, "invalid jetton wallet");
        require(fallbackWallet != claimJettonWallet, "invalid jetton wallet");
        require(fallbackWallet != fallbackJettonWallet, "invalid jetton wallet");
        require(totalAmount > 0, "invalid total");
        require(nodesCount > 0, "invalid nodes");
        require(nodesCount <= MAX_NODES, "too many nodes");

        let sum: Int = 0;
        let i: Int = 0;
        let previousReleaseTime: Int = 0;
        while (i < nodesCount) {
            let nodeOpt = nodes.get(i);
            require(nodeOpt != null, "missing node");
            let node = nodeOpt!!;
            require(node.amount > 0, "invalid amount");
            require(node.claimedAmount == 0, "invalid claimed");
            require(node.claimedBy == 0, "invalid claimed");
            require(node.pendingQueryId == 0, "invalid pending");
            require(node.pendingAmount == 0, "invalid pending");
            require(node.releaseTime >= previousReleaseTime, "invalid schedule");
            previousReleaseTime = node.releaseTime;
            sum += node.amount;
            i += 1;
        }
        require(sum == totalAmount, "amount mismatch");
    }

    receive() {}

    receive(msg: SetJettonWallet) {
        require(sender() == self.setupWallet, "unauthorized");
        require(!self.jettonWalletReady, "jetton wallet already set");
        require(msg.wallet != self.claimWallet, "invalid jetton wallet");
        require(msg.wallet != self.fallbackWallet, "invalid jetton wallet");
        require(msg.wallet != self.claimJettonWallet, "invalid jetton wallet");
        require(msg.wallet != self.fallbackJettonWallet, "invalid jetton wallet");
        self.jettonWallet = msg.wallet;
        self.jettonWalletReady = true;
        cashback(sender());
    }

    receive("claim") {
        require(self.jettonWalletReady, "jetton wallet not set");
        require(context().value >= MIN_CLAIM_VALUE, "not enough TON");

        let isPrimary: Bool = sender() == self.claimWallet;
        let isFallback: Bool = sender() == self.fallbackWallet;
        require(isPrimary || isFallback, "unauthorized");

        let amount: Int = 0;
        let target: Address = self.claimWallet;
        let claimedBy: Int = 1;
        if (isFallback) {
            target = self.fallbackWallet;
            claimedBy = 2;
        }

        let queryId = self.nextQueryId;
        self.nextQueryId += 1;

        let i: Int = 0;
        let firstNode: Int = self.nodesCount;
        let endNode: Int = 0;
        while (i < self.nodesCount) {
            let nodeOpt = self.nodes.get(i);
            require(nodeOpt != null, "missing node");
            let node = nodeOpt!!;
            let remaining = node.amount - node.claimedAmount;
            if (remaining > 0) {
                if (isPrimary && now() >= node.releaseTime) {
                    require(node.pendingQueryId == 0, "node already pending");
                    node.claimedAmount += remaining;
                    node.claimedBy = claimedBy;
                    node.pendingQueryId = queryId;
                    node.pendingAmount = remaining;
                    if (amount == 0) {
                        firstNode = i;
                    }
                    endNode = i + 1;
                    amount += remaining;
                    self.totalClaimed += remaining;
                } else if (isFallback && now() >= node.releaseTime + FALLBACK_DELAY_SECONDS) {
                    require(node.pendingQueryId == 0, "node already pending");
                    node.claimedAmount += remaining;
                    node.claimedBy = claimedBy;
                    node.pendingQueryId = queryId;
                    node.pendingAmount = remaining;
                    if (amount == 0) {
                        firstNode = i;
                    }
                    endNode = i + 1;
                    amount += remaining;
                    self.totalClaimed += remaining;
                }
                self.nodes.set(i, node);
            }
            i += 1;
        }

        require(amount > 0, "nothing to claim");

        self.pendingClaims.set(queryId, PendingClaim{
            amount: amount,
            recipient: target,
            claimedBy: claimedBy,
            firstNode: firstNode,
            endNode: endNode,
            active: true
        });

        self.sendJettonTransfer(queryId, target, amount);
    }

    receive(msg: JettonExcess) {
        require(self.jettonWalletReady, "jetton wallet not set");
        let pendingOpt = self.pendingClaims.get(msg.queryId);
        if (pendingOpt != null) {
            let pending = pendingOpt!!;
            require(sender() == self.expectedExcessSender(pending.claimedBy), "unauthorized");
            self.pendingClaims.del(msg.queryId);
            self.completeClaim(msg.queryId, pending.firstNode, pending.endNode);
            cashback(pending.recipient);
        } else {
            require(sender() == self.claimJettonWallet || sender() == self.fallbackJettonWallet, "unauthorized");
        }
    }

    bounced(src: bounced<JettonTransferBounce>) {
        require(self.jettonWalletReady, "jetton wallet not set");
        require(sender() == self.jettonWallet, "unauthorized");

        let queryId = src.queryId;
        let amount = src.amount;
        require(amount > 0, "invalid bounce");

        let pendingOpt = self.pendingClaims.get(queryId);
        require(pendingOpt != null, "invalid bounce");
        let pending = pendingOpt!!;
        require(pending.active, "invalid bounce");
        require(pending.amount == amount, "invalid bounce");

        self.rollbackClaim(queryId, amount);
        self.pendingClaims.del(queryId);
    }

    fun sendJettonTransfer(queryId: Int, to: Address, amount: Int) {
        // Misconfigured Jetton Wallets that do not bounce failures or send standard excesses can leave
        // node pending markers uncleared; deployment must validate the target Jetton behavior first.
        let body = beginCell()
            .storeUint(OP_JETTON_TRANSFER, 32)
            .storeUint(queryId, 64)
            .storeCoins(amount)
            .storeAddress(to)
            .storeAddress(myAddress())
            .storeBit(false)
            .storeCoins(1)
            .storeBit(false)
            .endCell();

        send(SendParameters{
            to: self.jettonWallet,
            value: 0,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: body,
            bounce: true
        });
    }

    fun rollbackClaim(queryId: Int, amount: Int) {
        let remaining = amount;
        let i: Int = self.nodesCount;
        while (i > 0 && remaining > 0) {
            i -= 1;
            let nodeOpt = self.nodes.get(i);
            require(nodeOpt != null, "missing node");
            let node = nodeOpt!!;

            if (node.pendingQueryId == queryId && node.pendingAmount > 0) {
                let fromNode = node.pendingAmount;
                require(fromNode <= remaining, "invalid bounce");
                require(fromNode <= node.claimedAmount, "invalid bounce");

                node.claimedAmount -= fromNode;
                if (node.claimedAmount == 0) {
                    node.claimedBy = 0;
                }
                node.pendingQueryId = 0;
                node.pendingAmount = 0;
                self.totalClaimed -= fromNode;
                remaining -= fromNode;
            }

            self.nodes.set(i, node);
        }
        require(remaining == 0, "invalid bounce");
    }

    fun completeClaim(queryId: Int, firstNode: Int, endNode: Int) {
        require(firstNode < endNode, "invalid pending range");
        require(endNode <= self.nodesCount, "invalid pending range");

        let i: Int = firstNode;
        while (i < endNode) {
            let nodeOpt = self.nodes.get(i);
            require(nodeOpt != null, "missing node");
            let node = nodeOpt!!;
            if (node.pendingQueryId == queryId) {
                node.pendingQueryId = 0;
                node.pendingAmount = 0;
                self.nodes.set(i, node);
            }
            i += 1;
        }
    }

    fun expectedExcessSender(claimedBy: Int): Address {
        if (claimedBy == 1) {
            return self.claimJettonWallet;
        }
        require(claimedBy == 2, "invalid claim");
        return self.fallbackJettonWallet;
    }

    get fun getConfig(): VestingConfig {
        return VestingConfig{
            setupWallet: self.setupWallet,
            claimWallet: self.claimWallet,
            fallbackWallet: self.fallbackWallet,
            jettonWallet: self.jettonWallet,
            jettonWalletReady: self.jettonWalletReady,
            claimJettonWallet: self.claimJettonWallet,
            fallbackJettonWallet: self.fallbackJettonWallet,
            totalAmount: self.totalAmount,
            nodesCount: self.nodesCount,
            totalClaimed: self.totalClaimed,
            nextQueryId: self.nextQueryId
        };
    }

    get fun getNode(index: Int): ReleaseNode {
        let nodeOpt = self.nodes.get(index);
        require(nodeOpt != null, "missing node");
        return nodeOpt!!;
    }

    get fun getNodeStatus(index: Int): ReleaseNodeStatus {
        let nodeOpt = self.nodes.get(index);
        require(nodeOpt != null, "missing node");
        let node = nodeOpt!!;
        return ReleaseNodeStatus{
            releaseTime: node.releaseTime,
            amount: node.amount,
            primaryUnlocked: now() >= node.releaseTime,
            fallbackUnlocked: now() >= node.releaseTime + FALLBACK_DELAY_SECONDS,
            claimed: node.claimedAmount >= node.amount,
            claimedBy: node.claimedBy,
            claimedAmount: node.claimedAmount,
            pendingQueryId: node.pendingQueryId,
            pendingAmount: node.pendingAmount
        };
    }

    get fun getClaimable(address: Address): Int {
        let isPrimary: Bool = address == self.claimWallet;
        let isFallback: Bool = address == self.fallbackWallet;
        if (!isPrimary && !isFallback) {
            return 0;
        }

        let amount: Int = 0;
        let i: Int = 0;
        while (i < self.nodesCount) {
            let nodeOpt = self.nodes.get(i);
            if (nodeOpt != null) {
                let node = nodeOpt!!;
                let remaining = node.amount - node.claimedAmount;
                if (remaining > 0) {
                    if (isPrimary && now() >= node.releaseTime) {
                        amount += remaining;
                    } else if (isFallback && now() >= node.releaseTime + FALLBACK_DELAY_SECONDS) {
                        amount += remaining;
                    }
                }
            }
            i += 1;
        }
        return amount;
    }

}
