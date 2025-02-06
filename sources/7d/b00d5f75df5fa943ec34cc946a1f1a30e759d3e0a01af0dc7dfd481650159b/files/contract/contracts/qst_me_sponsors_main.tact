import "@stdlib/deploy";
import "@stdlib/ownable";
import "./traits/operator_control.tact";

import "./structs/assets.tact";
import "./messages.tact";
import "./qst_me_sponsor.tact";

contract QstMeSponsorsMain with Deployable, OwnableTransferable, OperatorControl {
  owner: Address;
  operators: map<Address, Bool>;
  protocolBalance: Assets;
  communityBalance: Assets;
  usdtWallet: Address?;


  init(
    initOwner: Address
  ) {
    self.owner = initOwner;
    self.protocolBalance = Assets { ton: 0, usdt: 0 };
    self.communityBalance = Assets { ton: 0, usdt: 0 };
    self.usdtWallet = null;
  }


  receive(msg: RegisterSponsor) {
    self.requireOperator();
    require(msg.communityPercent > 0 && msg.communityPercent <= 10000, "Community percent must be in range 1(0.01%)..10000(100%)");
    require(msg.threshold > 0, "Threshold must be greater than 0");

    let init: StateInit = initOf QstMeSponsor(myAddress(), msg.sponsorId);

    send(SendParameters{
      to: contractAddress(init),
      value: 0,
      mode: SendRemainingValue,
      body: InternalResetSponsor {
        sponsorId: msg.sponsorId,
        communityPercent: msg.communityPercent,
        threshold: msg.threshold,
        initiator: sender(),
      }.toCell(),
      data: init.data,
      code: init.code,
    });
  }

  receive(msg: SetUSDTWallet) {
    require(sender() == self.owner, "Only owner can set USDT wallet");
    self.usdtWallet = msg.address;

    self.reply(USDTWalletSet{ address: msg.address }.toCell());
  }

  receive(msg: SetCommunityPercent) {
    self.requireOperator();

    send(SendParameters{
    to: self.sponsorContractAddress(msg.sponsorId),
    value: 0,
    mode: SendRemainingValue,
    body: InternalSetCommunityPercent {
      percent: msg.percent,
      initiator: sender(),
    }.toCell(),
    });
  }

  receive(msg: WithdrawProtocolTon) {
    self.requireOwner();

    let protocolTonBalance = self.protocolBalance.ton;
    self.protocolBalance.ton = 0;

    send(SendParameters{
    to: msg.address,
    value: protocolTonBalance,
    mode: SendIgnoreErrors,
    body: QstMeWithdrawalTon { amount: protocolTonBalance }.toCell(),
    });

    self.reply(ProtocolWithdrawnTon { address: msg.address, amount: protocolTonBalance }.toCell());
  }

  receive(msg: WithdrawProtocolUSDT) {
    self.requireOwner();
    require(self.usdtWallet != null, "USDT wallet is not set");

    let protocolUsdtBalance = self.protocolBalance.usdt;
    self.protocolBalance.usdt = 0;

    let body = JettonTransfer {
      queryId: 2,
      amount: protocolUsdtBalance,
      destination: msg.address,
      responseDestination: sender(),
      customPayload: null,
      forwardTonAmount: 0,
      forwardPayload: rawSlice("FF"),
    }.toCell();

    send(SendParameters{
      to: self.usdtWallet!!,
      value: 0,
      mode: SendRemainingValue,
      body,
    });
  }

  receive(msg: RewardUser) {
    self.requireOperator();

    self.rewardUser(msg.reward);

    send(SendParameters{
      to: sender(),
      value: ton("0.05"),
      mode: SendIgnoreErrors,
      body: UsersRewarded { usersAmount: 1, totalReward: msg.reward.reward }.toCell(),
    });
  }

  receive(msg: RewardUsers) {
    self.requireOperator();

    let totalReward: Assets = Assets { ton: 0, usdt: 0 };

    let i: Int = 0;
    while (i < msg.rewards.length) {
      let reward = msg.rewards.getIdx(i);

      totalReward = totalReward.add(reward.reward);

      self.rewardUser(reward);
    }

    send(SendParameters{
      to: sender(),
      value: ton("0.05"),
      mode: SendIgnoreErrors,
      body: UsersRewarded { usersAmount: msg.rewards.length, totalReward }.toCell(),
    });
  }

//  receive(msg: SponsorWithTon) {
//    send(SendParameters{
//      to: self.sponsorContractAddress(msg.sponsorId),
//      value: 0,
//      mode: SendRemainingValue,
//      body: InternalRegisterSponsorship {
//        amount: Assets {
//          ton: msg.amount,
//          usdt: 0,
//        },
//        initiator: sender(),
//      }.toCell(),
//    });
//  }

  receive(msg: JettonTransferNotification) {
    require(sender() == self.usdtWallet!!, "Only USDT Jetton notifications are acceptable");

    if (msg.amount == 0) { return }

    let sponsorId = msg.forwardPayload
        .loadRef()
        .beginParse()
        .loadUint(64);

    send(SendParameters{
      to: self.sponsorContractAddress(sponsorId),
      value: 0,
      mode: SendRemainingValue,
      body: InternalRegisterSponsorship {
        amount: Assets {
          ton: 0,
          usdt: msg.amount,
        },
        initiator: msg.sender,
      }.toCell(),
    });
  }

  receive(msg: InternalApproveSponsorship) {
    require(sender() == self.sponsorContractAddress(msg.sponsorId), "Only appropriate sponsor contract can approve sponsorship");

    let communityPart = Assets {
    ton: msg.amount.ton * msg.communityPercent / 10000,
    usdt: msg.amount.usdt * msg.communityPercent / 10000,
    };

    let protocolPart = Assets {
    ton: msg.amount.ton - communityPart.ton,
    usdt: msg.amount.usdt - communityPart.usdt,
    };

    self.communityBalance = self.communityBalance.add(communityPart);
    self.protocolBalance = self.protocolBalance.add(protocolPart);

    self.forward(
      msg.initiator,
      SponsorshipAccepted {
        sponsorId: msg.sponsorId,
        amount: msg.amount,
      }.toCell(),
      false,
      null
    );
  }


  bounced(msg: QstMeWithdrawalTon) {
    self.protocolBalance.ton += msg.amount;
  }

  bounced(msg: QstMeRewardTon) {
    self.communityBalance.ton += msg.amount;
  }

  bounced(msg: bounced<JettonTransfer>) {
    if (msg.queryId == 2) {
      self.protocolBalance.usdt += msg.amount;
    }
    if (msg.queryId == 4) {
      self.communityBalance.usdt += msg.amount;
    }
  }

  fun rewardUser(userReward: UserReward) {
    if (userReward.reward.usdt > 0) {
      self.rewardUserWithUsdt(userReward.user, userReward.reward.usdt);
    }
    if (userReward.reward.ton > 0) {
      self.rewardUserWithTon(userReward.user, userReward.reward.ton);
    }
  }

  fun rewardUserWithUsdt(user: Address, amount: Int) {
    require(self.communityBalance.usdt >= amount, "USDT community balance is not enough to reward user");

    self.communityBalance.usdt -= amount;

    let body = JettonTransfer {
      queryId: 4,
      amount,
      destination: user,
      responseDestination: sender(),
      customPayload: null,
      forwardTonAmount: 0,
      forwardPayload: rawSlice("FF"),
    }.toCell();

    send(SendParameters{
      to: self.usdtWallet!!,
      value: ton("0.05"),
      body,
    });
  }

  fun rewardUserWithTon(user: Address, amount: Int) {
    require(self.communityBalance.ton >= amount, "TON community balance is not enough to reward user");

    self.communityBalance.ton -= amount;

    send(SendParameters{
      to: user,
      value: amount,
      mode: SendIgnoreErrors,
      body: QstMeRewardTon { amount }.toCell(),
    });
  }

  get fun sponsorContractAddress(sponsorId: Int): Address {
    let init: StateInit = initOf QstMeSponsor(myAddress(), sponsorId);
    return contractAddress(init);
  }

  get fun communityBalance(): Assets {
    return self.communityBalance;
  }

  get fun protocolBalance(): Assets {
    return self.protocolBalance;
  }

  get fun usdtWallet(): Address? {
    return self.usdtWallet;
  }
}
