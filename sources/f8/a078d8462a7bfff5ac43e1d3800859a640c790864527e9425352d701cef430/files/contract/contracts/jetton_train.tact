//                                                                                       ......
//             ....                                                                      .......
//             .....                                                                     .......
//             .....                                                                      ....
//             .....
//             .....
//             .....               ...        .......            .......                   ...        ...         .....
//       ...................      .....  .............      ..................            .....      .....  .................
//       ...................      ....................   .......................          .....      ..........................
//       ...................      ............          ............ .............        .....      ..............  ............
//             .....              ........            ........             ........       .....      ........              .......
//             .....              ......              ......                 .......      .....      .......                .......
//             .....              ......             ......                    .....      .....      ......                  ......
//             .....              .....             ......                     ......     .....      .....                    .....
//             .....              .....             .....                       .....     .....      .....                    .....
//             .....              .....             .....                       .....     .....      .....                    .....
//             .....              .....             .....                       .....     .....      .....                    .....
//             .....              .....             ......                      .....     .....      .....                    .....
//             .....              .....              ......                    ......     .....      .....                    .....
//             .....              .....              .......                 ........     .....      .....                    .....
//             .......            .....               ........              .........     .....      .....                    .....
//              .............     .....                .........         ............     .....      .....                    .....
//               .............    .....                  ...................... .....     .....      .....                    .....
//                 ...........    .....                     .................   .....     .....      .....                    .....
//                     ......      ...                           ........        ...       ...        ...                      ...

import "@stdlib/deploy";
//Jetton's messages
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}
message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}
message(0xd53276db) Excesses {
}
// Lock object
struct HTLC {
    sender: Address;
    senderPubKey: Int;
    srcReceiver: Address;
    secret: Int;
    hashlock: Int;
    amount: Int;
    timelock: Int;
    claimed: Int;
    jettonMasterAddress: Address;
    htlcJettonWalletAddress: Address;
}
// Reward object
struct Reward {
    amount: Int;
    timelock: Int;
}
struct CommitData {
    dstChain: String;
    dstAsset: String;
    dstAddress: String;
    srcAsset: String;
    Id: Int;
    srcReceiver: Address;
    timelock: Int;
    jettonMasterAddress: Address;
    htlcJettonWalletAddress: Address;
    senderPubKey: Int;
    hopChains: map<Int, StringImpl>;
    hopAssets: map<Int, StringImpl>;
    hopAddresses: map<Int, StringImpl>;
}
struct LockData {
    Id: Int;
    timelock: Int;
    reward: Int;
    rewardTimelock: Int;
    srcReceiver: Address;
    srcAsset: String;
    dstChain: String;
    dstAddress: String;
    dstAsset: String;
    hashlock: Int;
    jettonMasterAddress: Address;
    htlcJettonWalletAddress: Address;
}
// Messages received by contract
message(0x5cdd41d9) AddLock {
    Id: Int;
    hashlock: Int;
    timelock: Int;
}
message(0x758db085) Redeem {
    Id: Int;
    secret: Int;
}
message(0xad821ef9) Refund {
    Id: Int;
}
message(0xc1d818ff) AddLockSig {
    data: Slice;
    signature: Slice;
}
// Emitted message
message(0xbf3d24d1) TokenCommitted {
    Id: Int;
    dstChain: String;
    dstAddress: String;
    dstAsset: String;
    sender: Address;
    srcReceiver: Address;
    srcAsset: String;
    amount: Int;
    timelock: Int;
    jettonMasterAddress: Address;
    htlcJettonWalletAddress: Address;
    senderPubKey: Int;
    hopChains: map<Int, StringImpl>;
    hopAssets: map<Int, StringImpl>;
    hopAddresses: map<Int, StringImpl>;
}
message(0x0f47e1b8) TokenLocked {
    Id: Int;
    dstChain: String;
    dstAddress: String;
    dstAsset: String;
    sender: Address;
    srcReceiver: Address;
    srcAsset: String;
    amount: Int;
    timelock: Int;
    hashlock: Int;
    reward: Int;
    rewardTimelock: Int;
    jettonMasterAddress: Address;
    htlcJettonWalletAddress: Address;
}
message(0x6564cfc9) TokenRedeemed {
    Id: Int;
    redeemAddress: Address;
    secret: Int;
    hashlock: Int;
}
// String implementation as struct
struct StringImpl {
    data: String;
}

contract TrainJetton with Deployable {
    contracts: map<Int, HTLC>;
    rewards: map<Int, Reward>;

    receive(msg: TokenNotification){
        let ctx: Context = context();
        let slice = msg.forward_payload.asCell().beginParse();
        let flag = slice.loadUint(1);
        let refCell = slice.loadRef();
        let refSlice = refCell.beginParse();
        let op_code = refSlice.loadUint(32);
        if (op_code == 1734998782) {
            let commitData: CommitData = CommitData.fromSlice(refSlice);
            if (msg.amount != 0 && commitData.timelock > (now() + 900) && !self.contracts.exists(commitData.Id)) {
                self.contracts.set(commitData.Id,
                    HTLC{
                        sender: msg.from,
                        senderPubKey: commitData.senderPubKey,
                        srcReceiver: commitData.srcReceiver,
                        secret: 1,
                        hashlock: 1,
                        amount: msg.amount,
                        timelock: commitData.timelock,
                        claimed: 1,
                        jettonMasterAddress: commitData.jettonMasterAddress,
                        htlcJettonWalletAddress: commitData.htlcJettonWalletAddress
                    }
                );
                emit(TokenCommitted{
                        Id: commitData.Id,
                        dstChain: commitData.dstChain,
                        dstAddress: commitData.dstAddress,
                        dstAsset: commitData.dstAsset,
                        sender: msg.from,
                        srcReceiver: commitData.srcReceiver,
                        srcAsset: commitData.srcAsset,
                        amount: msg.amount,
                        timelock: commitData.timelock,
                        jettonMasterAddress: commitData.jettonMasterAddress,
                        htlcJettonWalletAddress: commitData.htlcJettonWalletAddress,
                        senderPubKey: commitData.senderPubKey,
                        hopChains: commitData.hopChains,
                        hopAssets: commitData.hopAssets,
                        hopAddresses: commitData.hopAddresses
                    }.toCell()
                );
            } else {
                send(SendParameters{
                        to: sender(),
                        value: context().value,
                        bounce: true,
                        mode: 0,
                        body: TokenTransfer{
                            queryId: 0x3f7a92b1c4e5d8a0,
                            amount: msg.amount,
                            destination: msg.from,
                            response_destination: sender(),
                            custom_payload: null,
                            forward_ton_amount: SendRemainingValue | SendIgnoreErrors,
                            forward_payload: "Commit Failed".asSlice()
                        }.toCell()
                    }
                );
            }
        }
        if (op_code == 317164721) {
            let lockData: LockData = LockData.fromSlice(refSlice);
            if (
                !self.contracts.exists(lockData.Id) &&
                msg.amount > lockData.reward &&
                (now() + 1800) < lockData.timelock &&
                lockData.rewardTimelock < lockData.timelock &&
                lockData.rewardTimelock > now()
            ) {
                self.contracts.set(lockData.Id,
                    HTLC{
                        sender: msg.from,
                        senderPubKey: 1,
                        srcReceiver: lockData.srcReceiver,
                        secret: 1,
                        hashlock: lockData.hashlock,
                        amount: msg.amount - lockData.reward,
                        timelock: lockData.timelock,
                        claimed: 1,
                        jettonMasterAddress: lockData.jettonMasterAddress,
                        htlcJettonWalletAddress: lockData.htlcJettonWalletAddress
                    }
                );
                if (lockData.reward != 0) {
                    self.rewards.set(lockData.Id, Reward{amount: lockData.reward, timelock: lockData.rewardTimelock});
                }
                emit(TokenLocked{
                        Id: lockData.Id,
                        dstChain: lockData.dstChain,
                        dstAddress: lockData.dstAddress,
                        dstAsset: lockData.dstAddress,
                        sender: msg.from,
                        srcReceiver: lockData.srcReceiver,
                        srcAsset: lockData.srcAsset,
                        amount: msg.amount - lockData.reward,
                        timelock: lockData.timelock,
                        reward: lockData.reward,
                        rewardTimelock: lockData.rewardTimelock,
                        hashlock: lockData.hashlock,
                        jettonMasterAddress: lockData.jettonMasterAddress,
                        htlcJettonWalletAddress: lockData.htlcJettonWalletAddress
                    }.toCell()
                );
            } else {
                send(SendParameters{
                        to: sender(),
                        value: context().value,
                        bounce: true,
                        mode: 0,
                        body: TokenTransfer{
                            queryId: 0x3f7a92b1c4e5d8a0,
                            amount: msg.amount,
                            destination: msg.from,
                            response_destination: sender(),
                            custom_payload: null,
                            forward_ton_amount: SendRemainingValue | SendIgnoreErrors,
                            forward_payload: "Lock Failed".asSlice()
                        }.toCell()
                    }
                );
            }
        }
    }

    receive(msg: AddLock){
        require(self.contracts.exists(msg.Id), "Contract Does Not Exist");
        let htlc: HTLC = self.contracts.get(msg.Id)!!;
        require(sender() == htlc.sender, "No Allowance");
        require(htlc.hashlock == 1, "Hashlock Already Set");
        require(msg.timelock > (now() + 900), "Not Future Timelock");
        // these checks can be skipped as commit object after Refund is deleted and Redeem can be called if anyone knows M s.t. sha256(M) = 1
        require(htlc.claimed == 1, "Already Claimed");
        self.contracts.set(msg.Id,
            HTLC{
                sender: htlc.sender,
                senderPubKey: htlc.senderPubKey,
                srcReceiver: htlc.srcReceiver,
                secret: 1,
                hashlock: msg.hashlock,
                amount: htlc.amount,
                timelock: msg.timelock,
                claimed: 1,
                jettonMasterAddress: htlc.jettonMasterAddress,
                htlcJettonWalletAddress: htlc.htlcJettonWalletAddress
            }
        );
        send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue | SendIgnoreErrors,
                body: Excesses{}.toCell()
            }
        );
    }

    receive(msg: AddLockSig){
        require(self.contracts.exists(msg.data.preloadInt(257)) == true, "Contract Does Not Exist");
        let htlc: HTLC = self.contracts.get(msg.data.preloadInt(257))!!;
        require(checkSignature(msg.data.hash(), msg.signature, htlc.senderPubKey), "Invalid signature");
        let Id: Int = msg.data.loadInt(257);
        let hashlock: Int = msg.data.loadInt(257);
        let timelock: Int = msg.data.loadInt(257);
        require(timelock > (now() + 900), "Not Future Timelock");
        require(htlc.hashlock == 1, "Hashlock Already Set");
        // these checks can be skipped as commit object after Refund is deleted and Redeem can be called if anyone knows M s.t. sha256(M) = 0
        require(htlc.claimed == 1, "Already Claimed");
        self.contracts.set(Id,
            HTLC{
                sender: htlc.sender,
                senderPubKey: htlc.senderPubKey,
                srcReceiver: htlc.srcReceiver,
                secret: 1,
                hashlock: hashlock,
                amount: htlc.amount,
                timelock: timelock,
                claimed: 1,
                jettonMasterAddress: htlc.jettonMasterAddress,
                htlcJettonWalletAddress: htlc.htlcJettonWalletAddress
            }
        );
        send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue | SendIgnoreErrors,
                body: Excesses{}.toCell()
            }
        );
    }

    receive(msg: Redeem){
        let ctx: Context = context();
        require(self.contracts.exists(msg.Id) == true, "Contract Does Not Exist");
        let htlc: HTLC = self.contracts.get(msg.Id)!!;
        //these checks can be skipped as after modification HTLC object is deleted
        require(htlc.claimed == 1, "Already Claimed");
        let hashlockFromSecretSlice: Slice = beginCell().storeUint(msg.secret, 256).asSlice();
        let hashlockFromSecret: Int = sha256(hashlockFromSecretSlice);
        require(htlc.hashlock == hashlockFromSecret, "Hashlock Not Match");
        emit(TokenRedeemed{Id: msg.Id, redeemAddress: sender(), secret: msg.secret, hashlock: htlc.hashlock}.toCell());
        if (!self.rewards.exists(msg.Id)) {
            send(SendParameters{
                    to: htlc.htlcJettonWalletAddress,
                    value: 0,
                    bounce: true,
                    mode: SendRemainingValue | SendIgnoreErrors,
                    body: TokenTransfer{
                        queryId: 0xd1af6d35ae06,
                        amount: htlc.amount,
                        destination: htlc.srcReceiver,
                        response_destination: sender(),
                        custom_payload: null,
                        forward_ton_amount: 1,
                        forward_payload: "Redeemed".asSlice()
                    }.toCell()
                }
            );
        } else {
            let reward: Reward = Reward{amount: 0, timelock: 0};
            reward = self.rewards.get(msg.Id)!!;
            if (reward.timelock > now()) {
                send(SendParameters{
                        to: htlc.htlcJettonWalletAddress,
                        value: ctx.value / 2,
                        bounce: true,
                        mode: 0,
                        body: TokenTransfer{
                            queryId: 0xd1af6d35ae06,
                            amount: htlc.amount,
                            destination: htlc.srcReceiver,
                            response_destination: sender(),
                            custom_payload: null,
                            forward_ton_amount: 1,
                            forward_payload: "Redeemed".asSlice()
                        }.toCell()
                    }
                );
                send(SendParameters{
                        to: htlc.htlcJettonWalletAddress,
                        value: ctx.value - (ctx.value / 2),
                        bounce: true,
                        mode: 0,
                        body: TokenTransfer{
                            queryId: 0xd1af6d35ae06,
                            amount: reward.amount,
                            destination: htlc.sender,
                            response_destination: sender(),
                            custom_payload: null,
                            forward_ton_amount: 1,
                            forward_payload: "Reward Returned".asSlice()
                        }.toCell()
                    }
                );
            } else {
                if (sender() == htlc.srcReceiver) {
                    send(SendParameters{
                            to: htlc.htlcJettonWalletAddress,
                            value: 0,
                            bounce: true,
                            mode: SendRemainingValue | SendIgnoreErrors,
                            body: TokenTransfer{
                                queryId: 0xd1af6d35ae06,
                                amount: htlc.amount + reward.amount,
                                destination: htlc.srcReceiver,
                                response_destination: sender(),
                                custom_payload: null,
                                forward_ton_amount: 1,
                                forward_payload: "Redeemed and Rewarded".asSlice()
                            }.toCell()
                        }
                    );
                } else {
                    send(SendParameters{
                            to: htlc.htlcJettonWalletAddress,
                            value: ctx.value / 2,
                            bounce: true,
                            mode: 0,
                            body: TokenTransfer{
                                queryId: 0xd1af6d35ae06,
                                amount: htlc.amount,
                                destination: htlc.srcReceiver,
                                response_destination: sender(),
                                custom_payload: null,
                                forward_ton_amount: 1,
                                forward_payload: "Redeemed".asSlice()
                            }.toCell()
                        }
                    );
                    send(SendParameters{
                            to: htlc.htlcJettonWalletAddress,
                            value: ctx.value - (ctx.value / 2),
                            bounce: true,
                            mode: 0,
                            body: TokenTransfer{
                                queryId: 0xd1af6d35ae06,
                                amount: reward.amount,
                                destination: sender(),
                                response_destination: sender(),
                                custom_payload: null,
                                forward_ton_amount: 1,
                                forward_payload: "Rewarded".asSlice()
                            }.toCell()
                        }
                    );
                }
            }
            self.rewards.del(msg.Id);
        }
        self.contracts.del(msg.Id);
    }

    receive(msg: Refund){
        let ctx: Context = context();
        require(self.contracts.exists(msg.Id), "Contract Does Not Exist");
        let htlc: HTLC = self.contracts.get(msg.Id)!!;
        require(htlc.timelock < now(), "Not Passed Timelock");
        //these checks can be skipped as after modification HTLC object is deleted
        require(htlc.claimed == 1, "Already Claimed");
        send(SendParameters{
                to: htlc.htlcJettonWalletAddress,
                value: ctx.value,
                bounce: true,
                mode: 0,
                body: TokenTransfer{
                    queryId: 0x11af6235be13,
                    amount: htlc.amount,
                    destination: htlc.sender,
                    response_destination: sender(),
                    custom_payload: null,
                    forward_ton_amount: 1,
                    forward_payload: "Refunded".asSlice()
                }.toCell()
            }
        );
        self.contracts.del(msg.Id);
    }

    get fun getHTLCDetails(Id: Int): HTLC? {
        return self.contracts.get(Id);
    }

    get fun getContractsLength(): Int {
        let length: Int = 0;
        foreach (key, value in self.contracts) {
            length += 1;
        }
        return length;
    }

    get fun getRewardDetails(Id: Int): Reward? {
        return self.rewards.get(Id);
    }

    get fun getRewardsLength(): Int {
        let length: Int = 0;
        foreach (key, value in self.rewards) {
            length += 1;
        }
        return length;
    }
}