import "@stdlib/ownable";
import "@stdlib/stoppable";
import "./surf_internal_msgs";
import "./messages";

import "./surf_on_ton";

message SetFactoryOptions {
    vx1: Int? as coins;
    vy1: Int? as coins;
    desiredSupply: Int? as coins;
    tonThreshold: Int? as coins;
    dexLaunchFee: Int? as coins;
    createFee: Int? as coins;
    orderFeeBps: Int? as uint32;
    proxyTonMain: Address?;
    dexRouter: Address?;
    teamWalletShareBps: Int? as uint32;
    teamWallet: Address?;
    rewardWallet: Address?;
}

message LaunchToken {
    content: Cell;
    id: Int;
    firstBuyLock: Bool;
}

message FeeDistribution {

}

message SurfTokenCreated {
    tokenAddress: Address;
    author: Address;
    tokenMeta: Cell;
    id: Int;
    vx1Component1: Int; //vx1+tonThreshold
    vx1Component2: Int; //vx1-tonThreshold
    vy1Encoded: Int;
    desiredSupplyEncoded: Int;
}

contract SurfFactory with Resumable, OwnableTransferable {
    const BP: Int = 100_00;
    const SELF_STORAGE: Int = ton("0.05");

    owner: Address;
    vx1: Int as coins; //120bit
    vy1: Int as coins; //120bit
    desiredSupply: Int as coins; //120bit
    tonThreshold: Int as coins; //120bit
    dexLaunchFee: Int as coins; //120bit
    createFee: Int as coins; //120bit
    orderFeeBps: Int as uint32;
    proxyTonMain: Address;
    dexRouter: Address;
    teamWalletShareBps: Int as uint32;
    teamWallet: Address;
    rewardWallet: Address;
    stopped: Bool;


    init(
        vx1: Int,
        vy1: Int,
        desiredSupply: Int,
        tonThreshold: Int,
        dexLaunchFee: Int,
        createFee: Int,
        orderFeeBps: Int,
        proxyTonMain: Address,
        dexRouter: Address,
        teamWalletShareBps: Int,
        teamWallet: Address,
        rewardWallet: Address,

    )
    {
        self.owner = context().sender;

        self.vx1 = vx1;
        self.vy1 = vy1;
        self.desiredSupply = desiredSupply;
        self.tonThreshold = tonThreshold;
        self.dexLaunchFee = dexLaunchFee;
        self.createFee = createFee;
        self.orderFeeBps = orderFeeBps;
        self.proxyTonMain = proxyTonMain;
        self.dexRouter = dexRouter;
        self.teamWalletShareBps = teamWalletShareBps;
        self.teamWallet = teamWallet;
        self.rewardWallet = rewardWallet;
        self.stopped = false;
    }


    receive(msg: Deploy) {

    }

    receive(opts: SetFactoryOptions) {
        self.requireOwner();


        if (opts.vx1 != null) {
            self.vx1 = opts.vx1!!;
        }

        if (opts.vy1 != null) {
            self.vy1 = opts.vy1!!;
        }

        if (opts.desiredSupply != null) {
            self.desiredSupply = opts.desiredSupply!!;
        }

        if (opts.tonThreshold != null) {
            self.tonThreshold = opts.tonThreshold!!;
        }

        if (opts.dexLaunchFee != null) {
            self.dexLaunchFee = opts.dexLaunchFee!!;
        }

        if (opts.createFee != null) {
            self.createFee = opts.createFee!!;
        }

        if (opts.orderFeeBps != null) {
            self.orderFeeBps = opts.orderFeeBps!!;
        }

        if (opts.proxyTonMain != null) {
            self.proxyTonMain = opts.proxyTonMain!!;
        }

        if (opts.dexRouter != null) {
            self.dexRouter = opts.dexRouter!!;
        }

        if (opts.teamWalletShareBps != null) {
            self.teamWalletShareBps = opts.teamWalletShareBps!!;
        }

        if (opts.teamWallet != null) {
            self.teamWallet = opts.teamWallet!!;
        }

        if (opts.rewardWallet != null) {
            self.rewardWallet = opts.rewardWallet!!;
        }
    }

    receive(tokenLaunchMsg: LaunchToken) {
        self.requireNotStopped();
        let value = context().value;
        let initialBalance: Int = myBalance() - value;
        let storageFee: Int = self.SELF_STORAGE - min(initialBalance, self.SELF_STORAGE);
        require(value >= (ton("1.5") + self.createFee + storageFee), "Not enough gas");
        
        let tokenInit: StateInit = initOf SurfOnTon(
            self.owner,
            self.vx1,
            self.vy1,
            self.desiredSupply,
            self.tonThreshold,
            self.dexLaunchFee,
            self.orderFeeBps,
            tokenLaunchMsg.content,
            self.proxyTonMain,
            self.dexRouter
        );

        let tokenAddress: Address = contractAddress(tokenInit);

        let deployMsg: Deploy= Deploy {
            tokenDeployer: null
        };

        if (tokenLaunchMsg.firstBuyLock) {
            deployMsg.tokenDeployer = context().sender;
        }

        send(SendParameters{
            to: tokenAddress,
            value: value - self.createFee - self.SELF_STORAGE,
            bounce: true,
            mode: 0,
            body: deployMsg.toCell(),
            code: tokenInit.code,
            data: tokenInit.data
        });

        let encryptionBase = self.tonThreshold ^ self.vx1;
        
        let fullmask = 1 << 255;
        fullmask -= 1;
        fullmask |= (1 << 255);

        encryptionBase = encryptionBase ^ (((fullmask >> 32) & encryptionBase) << 32);
        encryptionBase = encryptionBase ^ (((fullmask >> 64) & encryptionBase) << 64);
        encryptionBase = encryptionBase ^ (((fullmask >> 128) & encryptionBase) << 128);

        emit(SurfTokenCreated{
            tokenAddress: tokenAddress,
            author: context().sender,
            tokenMeta: tokenLaunchMsg.content,
            id: tokenLaunchMsg.id,
            vx1Component1: self.vx1 + self.tonThreshold,
            vx1Component2: self.vx1 - self.tonThreshold,
            vy1Encoded: encryptionBase ^ self.vy1,
            desiredSupplyEncoded: encryptionBase ^ self.desiredSupply,
        }.toCell());
    }

    receive(msg: FeeDistribution) {
        self.requireOwner();

        let feeDistribution: Int = myBalance() 
            - self.SELF_STORAGE 
            - ton("0.01")
            - 2 * context().readForwardFee();
        let teamShare: Int = feeDistribution * self.teamWalletShareBps / self.BP;

        send(SendParameters {
            to: self.teamWallet,
            value: teamShare,
            bounce: false,
            mode: 0,
            body: FeeDistribution{}.toCell(),
        });

        send(SendParameters {
            to: self.rewardWallet,
            value: feeDistribution - teamShare,
            bounce: false,
            mode: 0,
            body: FeeDistribution{}.toCell(),
        });
    }

    receive(msg: TokenNotification) {

    }
}