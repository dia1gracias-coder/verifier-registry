import "@stdlib/deploy";
import "@stdlib/stoppable";
import "@stdlib/ownable";

import "./deal_contract.tact";
import "./common.tact";

// Roles
// 1. Owner
// 2. Oracle (can update balances)
// 3. Support (can update details)

// https://docs.ton.org/develop/dapps/asset-processing/jettons#retrieving-jetton-wallet-addresses-for-a-given-user
//
// Open A Deal
//
// 1. Client sends tokenTransfer to his jettonWallet
// 2. Internal Transfer happens: from client's jetton wallet to MasterContract's jetton wallet
// 3. TransferNotification sent to MasterContract
// 4. MasterContract handles the TransferNotification and deploys DealContract
// 5. MasterContract sends TokenTransfer to his jettonWallet
// 6. Internal Transfer happens: from MasterContract's jetton wallet to DealContract's jetton wallet
//
// Reject
//
// 1. MasterContract or Client sends Reject message to DealContract (maybe USDT?)
// 2. DealContract changes the state and sends Token Transfer to his jetton wallet
// 3. Internal Transfer happens: from DealContract's jetton wallet to Client's jetton wallet
//
// Finish
//
// 1. MasterContract or Client sends Finish message to DealContract (trigger?)
// 2. DealContract changes the state and sends Token Transfer to his jetton wallet
// 3. Internal Transfer happens:
// - from DealContract's jetton wallet to Freelancer's jetton wallet
// - from DealContract's jetton wallet to MasterContract's jetton wallet
// - from DealContract's jetton wallet to Referral's jetton wallet

// Add Oracle to track that the Release/Finish/Reject transactions are correct indeed + punish rating
// Add Oracle to set the desired commissions via Master contract

message (0x55548561) SetUsdtAddress {
  usdtAddress: Address;
}

message (0x45548561) OpenDeal {
  guid: String;
  deadlineUNIX: Int as uint64;
  clientDetails: PersonDetails;
  workerAddress: Address;
  workerDetails: PersonDetails;

  referralCustomerAddress: Address?;
  referralFreelancerAddress: Address?;

  description: String;
}


message (0x95548561) OpenDealInternal {
  dealAmount: Int as uint64;
  deadlineUNIX: Int as uint64;
  workerAddress: Address;

  commissions: Commissions?;

  oracleAddress: Address?;
  referralCustomerAddress: Address?;
  referralFreelancerAddress: Address?;
}

message (0x67548561) Upgrade {
    /// New code of the contract.
    /// Defaults to `null`, which keeps the previous code.
    code: Cell? = null;

    /// New data of the contract.
    /// Defaults to `null`, which keeps the previous data.
    data: Cell? = null;
}

contract MasterContract with Deployable, Resumable {
  owner: Address;
  oracleAddress: Address?;
  stopped: Bool;
  usdtAddress: Address?;
  commissions: Commissions;
  version: Int as uint32;

  init() {
      self.owner = sender();
      self.stopped = false;
      self.commissions = Commissions {
          transfershipCommissionPercentage: 90, // 9.0% by default
          referralFreelancerCommissionPercentage: 5, // 0.5% by default
          referralCustomerCommissionPercentage: 5 // 0.5% by default
      };
      self.version = 1;
  }

  get fun version(): Int {
        return self.version;
  }

  receive(msg: Upgrade) {
    require(self.owner == sender(), "Only owner can upgrade");

    let ctx = context();

    if (msg.code != null) {
      // Change of code will be applied at the end of this transaction
      setCode(msg.code!!);
    }
    if (msg.data != null) {
        // Change of data will be immediate
        setData(msg.data!!);

        // By the end of every transaction,
        // the Tact compiler automatically adds a call to setData() for your convenience.
        // However, we've already set the data ourselves,
        // so let's stop the execution now to prevent a secondary call to setData().
        throw(0);
    }

    self.version += 1;
  }

  receive(msg: SetUsdtAddress) {
    self.requireNotStopped();

    require(self.owner == sender(), "Only owner can set the usdt address");

    self.usdtAddress = msg.usdtAddress;

    self.reply("usdtAddress is updated".asComment());
  }

  receive(msg: SetOracleAddress) {
    self.requireNotStopped();

    require(self.owner == sender(), "Only owner can set the oracle address");

    if (msg.dealAddress != null) {
      send(SendParameters{
          to: msg.dealAddress!!,
          value: context().value,
          body: msg.toCell()
      });
      self.reply("Redirected SetOracleAddress message".asComment());
    } else {
      self.oracleAddress = msg.oracleAddress;
      self.reply("oracleAddress is updated".asComment());
    }
  }

  receive(msg: TokenNotification) {
    self.requireNotStopped();

    if (self.usdtAddress != null && self.usdtAddress!! == sender()) {
      let ctx: Context = context();

      let maybeMsgCell = msg.forward_payload.preloadMaybeRef();
   
      let msgSlice = 
        (maybeMsgCell != null) 
        ? maybeMsgCell!!.asSlice()
        : msg.forward_payload;

      let deal: OpenDeal = OpenDeal.fromSlice(msgSlice);
      let init: StateInit = initOf DealContract(myAddress(), msg.from, deal.guid);

      send(SendParameters{
        to: contractAddress(init),
        value: self.getPercentVal(ctx.value, 150),
        code: init.code,
        data: init.data,
        body: TokenExcesses{queryId: msg.queryId}.toCell()
      });

      let openDealInternal = OpenDealInternal{
        oracleAddress: self.oracleAddress,
        dealAmount: 0, // msg.amount,
        deadlineUNIX: 0, //deal.deadlineUNIX,
        workerAddress: deal.workerAddress,
        referralCustomerAddress: deal.referralCustomerAddress,
        referralFreelancerAddress: deal.referralFreelancerAddress,
        commissions: self.commissions,
      };

      send(SendParameters{
         to: sender(),
         value: self.getPercentVal(ctx.value, 750),
         body: TokenTransfer{
            queryId: msg.queryId,
            amount: msg.amount,
            destination: contractAddress(init),
            response_destination: msg.from,
            custom_payload: null,
            forward_ton_amount: self.getPercentVal(ctx.value, 500),
            forward_payload: beginCell().storeBit(true).storeRef(openDealInternal.toCell()).asSlice()
         }.toCell()
      });
    }
  }

  receive(msg: TokenExcesses) {
  }

  receive(msg: SetCommissions) {
      require(self.owner == sender(), "Only owner can set the commissions");

      validateCommissions(msg.commissions);

      if (msg.dealAddress == null) {
          self.commissions = msg.commissions;

          send(SendParameters{
              to: sender(),
              value: context().value,
              body: "The Autoproof commissions were updated".asComment(),
          });

          self.reply("Updated master contract commissions".asComment());
      } else {
          send(SendParameters{
              to: msg.dealAddress!!,
              value: context().value,
              body: msg.toCell()
          });
          self.reply("Redirected SetCommissions message".asComment());
      }
  }

  receive(msg: UpdateDetails) {
      require(self.owner == sender(), "Only owner can update the details");

      send(SendParameters{
          to: msg.dealAddress,
          value: context().value,
          body: msg.toCell()
      });
      self.reply("Redirected UpdateDetails message".asComment());
  }

  receive(msg: GetFunds) {
    require(self.owner == sender(), "Only owner can get funds");

    if (msg.dealAddress != null) {
        send(SendParameters{
            to: msg.dealAddress!!,
            value: context().value,
            body: msg.toCell()
        });
        self.reply("Redirected GetFunds message".asComment());
    } else {
      if (self.usdtAddress != null && msg.usdt != null && msg.usdt == true) {
        send(SendParameters{
           to: self.usdtAddress!!,
           value: self.getPercentVal(context().value, 800), // 80% 
           body: TokenTransfer{
              queryId: random(0, 18446744073709551615), // uint64
              amount: msg.amount,
              destination: self.owner, 
              response_destination: self.owner,
              custom_payload: null,
              forward_ton_amount: 0, 
              forward_payload: beginCell().storeBit(false).asSlice()
           }.toCell()
        });
        
      } else {
        require(myBalance() > msg.amount, "Not enough funds");

        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            body: "Send funds to the owner".asComment(),
        });
      }
    }
  }

  get fun getOwner(): Address {
    return self.owner;
  }

  get fun getUsdtAddress(): Address? {
    return self.usdtAddress;
  }

  get fun getOracleAddress(): Address? {
    return self.oracleAddress;
  }

  get fun currentCommissions(): Commissions? {
      return self.commissions;
  }

  get fun currentTransfershipCommissionPercentage(): Int {
      return self.commissions.transfershipCommissionPercentage;
  }

  get fun currentReferralCustomerCommissionPercentage(): Int {
      return self.commissions.referralCustomerCommissionPercentage;
  }

  get fun currentReferralFreelancerCommissionPercentage(): Int {
      return self.commissions.referralFreelancerCommissionPercentage;
  }

  fun getPercentVal(v: Int, p: Int): Int {
    let value: Int = v / 1000 * p;
    return value;
  }
}


asm fun setCode(code: Cell) { SETCODE }
asm fun setData(data: Cell) { c4 POP }
