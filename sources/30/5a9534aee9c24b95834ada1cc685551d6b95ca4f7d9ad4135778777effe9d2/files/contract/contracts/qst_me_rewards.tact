import "@stdlib/deploy";
import "@stdlib/ownable";
import "./traits/upgradeable.tact";
import "./traits/operator_control.tact";
import "./traits/signature_validation.tact";
import "./traits/nonce_control.tact";

import "./messages.tact";

contract QstMeRewards with
  Deployable,
  OwnableTransferable,
  Upgradeable,
  OperatorControl,
  SignatureValidation,
  NonceControl {
  override const domain: String = "QstMeRewards";

  owner: Address;
  operators: map<Address, Bool>;
  pubKeys: map<Int, Bool>;
  nonce: Int;

  init(owner: Address) {
    self.owner = owner;
    self.nonce = 0;
  }

  receive(msg: RewardUser) {
    self.requireOwnerOrOperator();

    self.rewardUser(msg.reward);

    self.reply(UsersRewarded { usersAmount: 1 }.toCell());
  }

  receive(msg: RewardUsers) {
    self.requireOwnerOrOperator();

    let i: Int = 0;
    while (i < msg.rewards.length) {
      let reward = msg.rewards.getIdx(i);

      self.rewardUser(reward);
      i += 1;
    }

    self.reply(UsersRewarded { usersAmount: msg.rewards.length }.toCell());
  }

  receive(msg: RewardUserSigned) {
    self.requireAcceptedPubKey(msg.pubKey);
    self.requireValidNonce(msg.nonce);
    require(msg.timestamp + 60 * 5 > now(), "RewardUserSigned: timestamp is too old");

    let data = beginCell()
      .storeUint(msg.nonce, 256)
      .storeUint(msg.timestamp, 256)
      .storeRef(msg.reward.toCell())
      .endCell();

    require(self.validateSignature(data, msg.pubKey, msg.signature), "RewardUserSigned: invalid signature");

    self.setNonce(msg.nonce);

    self.rewardUser(msg.reward);

    self.reply("QstMe reward sent".asComment());
  }

  fun rewardUser(userReward: UserReward) {
    if (userReward.jettonWallet == null) {
      self.rewardUserWithTon(userReward.user, userReward.amount);
    } else {
      self.rewardUserWithJetton(userReward.user, userReward.jettonWallet!!, userReward.amount);
    }
  }

  fun rewardUserWithTon(user: Address,  amount: Int) {
    send(SendParameters{
      to: user,
      value: amount,
      mode: SendIgnoreErrors,
      body: QstMeRewardTon { amount }.toCell(),
    });
  }

  fun rewardUserWithJetton(user: Address, jettonWallet: Address, amount: Int) {
    let body = JettonTransfer {
      queryId: 0,
      amount,
      destination: user,
      responseDestination: sender(),
      customPayload: null,
      forwardTonAmount: 0,
      forwardPayload: rawSlice("FF"),
    }.toCell();

    send(SendParameters{
      to: jettonWallet,
      value: ton("0.05"),
      body,
    });
  }
}
