import "@stdlib/deploy";
import "@stdlib/ownable";
import "./traits/operator_control.tact";

import "./structs/balance.tact";
import "./messages.tact";
import "./qst_me_sponsor.tact";

contract QstMeSponsorsMain with Deployable, OwnableTransferable, OperatorControl {
  owner: Address;
  operators: map<Address, Bool>;
  protocol_balance: Balance;
  community_balance: Balance;
  usdt_wallet: Address;

  init(
    init_owner: Address
  ) {
    self.owner = init_owner;
    self.protocol_balance = Balance { ton: 0, usdt: 0 };
    self.community_balance = Balance { ton: 0, usdt: 0 };
    self.usdt_wallet = myAddress();
  }

  receive(msg: RegisterSponsor) {
    require(sender() == self.owner, "Only owner can register sponsors");

    let init: StateInit = initOf QstMeSponsor(myAddress(), msg.id);

    send(SendParameters{
      to: contractAddress(init),
      value: ton("0.05"),
      mode: SendIgnoreErrors,
      body: Deploy { queryId: msg.id }.toCell(),
      data: init.data,
      code: init.code,
    });

    self.reply(SponsorRegistered{ id: msg.id }.toCell());
  }

  receive(msg: WithdrawProtocolTon) {
    self.requireOwner();

    let protocolTonBalance = self.protocol_balance.ton;
    self.protocol_balance.ton = 0;

    send(SendParameters{
      to: msg.address,
      value: protocolTonBalance,
      mode: SendIgnoreErrors,
      body: QstMeWithdraw { asset: "ton", amount: protocolTonBalance }.toCell(),
    });

    self.reply(ProtocolWithdrawn { address: msg.address, asset: "ton", amount: protocolTonBalance }.toCell());
  }

  receive(msg: WithdrawProtocolUSDT){
    self.requireOwner();

    let protocolUsdtBalance = self.protocol_balance.usdt;
    self.protocol_balance.usdt = 0;

    send(SendParameters{
      to: msg.address,
      value: ton("0.05"),
      body: JettonTransfer {
        queryId: 0,
        amount: protocolUsdtBalance,
        destination: msg.address,
        responseDestination: sender(),
        customPayload: null,
        forwardTonAmount: 0,
        forwardPayload: rawSlice("F"),
      }.toCell(),
    });

    self.reply(ProtocolWithdrawn { address: msg.address, asset: "usdt", amount: protocolUsdtBalance }.toCell());
  }

  receive(msg: RewardUserTon) {
    self._requireOperator();

    self.community_balance.ton -= msg.amount;

    send(SendParameters{
      to: msg.address,
      value: msg.amount,
      mode: SendIgnoreErrors,
      body: QstMeReward { asset: "ton", amount: msg.amount }.toCell(),
    });

    self.reply(UserRewarded { address: msg.address, amount: Balance { ton: msg.amount, usdt: 0} }.toCell());
  }

  receive(msg: RewardUserUSDT) {
    self._requireOperator();

    self.community_balance.usdt -= msg.amount;

    send(SendParameters{
      to: msg.address,
      value: ton("0.05"),
      body: JettonTransfer {
        queryId: 0,
        amount: msg.amount,
        destination: msg.address,
        responseDestination: sender(),
        customPayload: null,
        forwardTonAmount: 0,
        forwardPayload: rawSlice("F"),
      }.toCell(),
    });

    self.reply(UserRewarded { address: msg.address, amount: Balance { ton: msg.amount, usdt: 0} }.toCell());
  }

  receive(msg: SetUSDTWallet) {
    require(sender() == self.owner, "Only owner can set USDT wallet");
    self.usdt_wallet = msg.address;

    self.reply(USDTWalletSet{ address: msg.address }.toCell());
  }

  receive(msg: ApproveSponsorship) {
    require(sender() == self.sponsorContractAddress(msg.sponsor), "Only appropriate sponsor contract can approve sponsorship");

    let community_part = Balance {
    ton: msg.amount.ton / 5,
    usdt: msg.amount.usdt / 5,
    };

    let protocol_part = Balance {
      ton: msg.amount.ton - community_part.ton,
      usdt: msg.amount.usdt - community_part.usdt,
    };

    self.community_balance = self.community_balance.add(community_part);
    self.protocol_balance = self.protocol_balance.add(protocol_part);
  }

  receive(msg: JettonTransferNotification) {
    require(sender() == self.usdt_wallet, "Only USDT Jetton notifications are acceptable");

    if (msg.amount == 0) { return }

    let sponsorId = msg.forwardPayload.loadUint(64);

    send(SendParameters{
      to: self.sponsorContractAddress(sponsorId),
      value: ton("0.05"),
      body: RegisterSponsorship {
        sponsor: sponsorId,
        amount: Balance {
          ton: 0,
          usdt: msg.amount,
        },
      }.toCell(),
    });
  }

  get fun sponsorContractAddress(id: Int): Address {
    let init: StateInit = initOf QstMeSponsor(myAddress(), id);
    return contractAddress(init);
  }

  get fun getCommunityBalance(): Balance {
    return self.community_balance;
  }

  get fun getProtocolBalance(): Balance {
    return self.protocol_balance;
  }
}
