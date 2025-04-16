
import "./shared.tact";
import "./DepositUser.tact";


struct JettonWalletData {
  // balance: Int as coins;
  jettonMasterAddress: Address;
  ownerAddress: Address;
  // jettonWalletCode: Cell;
}
message(0x2c76b973) ProvideWalletAddress {
    queryId: Int as uint64;
    ownerAddress: Address;
    includeAddress: Bool;
}

message(0xd1735400) TakeWalletAddress {
    queryId: Int as uint64;
    // if it is not possible to generate wallet address
    // for address in question (for instance wrong workchain)
    // wallet_address in take_wallet_address
    // should be equal to addr_none
    walletAddress: Address;
    // If include_address is set to True,
    // take_wallet_address should include
    // owner_address equal to owner_address in request
    ownerAddress: Cell;
}



message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Cell?;
}


/**
  transfer#0f8a7ea5 
  query_id:uint64
  amount:(VarUInteger 16)
  destination:MsgAddress
  response_destination:MsgAddress
  custom_payload:(Maybe ^Cell)
  forward_ton_amount:(VarUInteger 16)
  forward_payload:(Either Cell ^Cell) 
    = InternalMsgBody;
*/
message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Cell?;
}

const JettonTransferGas: Int = ton("0.05");

fun calculateJettonWalletStateInit(
    ownerAddress: Address,
    jettonMasterAddress: Address,
    jettonWalletCode: Cell
): StateInit {

    let initData = JettonWalletData{
        // balance: 0,
        ownerAddress,
        jettonMasterAddress,
        // jettonWalletCode,
    };

    return StateInit{
        code: jettonWalletCode,
        data: initData.toCell(),
    };
}

contract DepositJetton(
  admin: Address,
  jettonMaster: Address,
  jettonWallet: Address?
) {

  receive() {  
    if(self.jettonWallet == null){
      message(MessageParameters{
        to: self.jettonMaster,
        value: 0,
        mode: SendRemainingValue,
        body: ProvideWalletAddress{
          queryId: 0,
          ownerAddress: myAddress(),
          includeAddress: true,
        }.toCell(),
      });
    }
  }

  receive(msg: TakeWalletAddress) {
    require(sender() == self.jettonMaster,"Not Jetton Master");
    require(self.jettonWallet == null,"Jetton Inited");
    require(msg.ownerAddress.beginParse().loadAddress() == myAddress(),"Not my address");
    self.jettonWallet = msg.walletAddress;
    message(MessageParameters{
      to: self.admin,
      value: 0,
      mode: SendRemainingValue,
      body: Excesses{}.toCell(),
    });
  }


  receive(msg: JettonTransferNotification) {

    require(sender() == self.jettonWallet!!, "Unauthorized");

    let init = initOf DepositUser(
      myAddress(),
      msg.sender,
      0, 
      0,
      0
    );

    let userdeposit = contractAddress(init);


    send(SendParameters{
        to: userdeposit,
        value: 0,              // pay for message, the deployment and give some TON for storage
        mode: SendRemainingValue ,
        bounce: false,
        code: init.code,                // attaching the state init will cause the message to deploy
        data: init.data,
        body: NotifyDeposit{
          user: msg.sender,
          amount: msg.amount,
        }.toCell(),
    });
  }

  receive(msg: TakeFund) {
    require(sender() == self.admin,"Unauthorized");
    require(msg.amount != null && msg.amount!! > 0,"Invalid Amount");
   
    message(MessageParameters{
      to: self.jettonWallet!!,
      value: JettonTransferGas,
      body: JettonTransfer{
        queryId: 0,
        amount: msg.amount!!,
        destination: self.admin,
        responseDestination: self.admin,
        customPayload: null,
        forwardTonAmount: 0, // if it's 0, the notification won't be sent!
        forwardPayload: null,
      }.toCell(),
    });

  }

  receive(msg: NotifyDepositEvent) {
    require(sender() == contractAddress(initOf DepositUser(
      myAddress(),
      msg.user,
      0, 
      0,
      0
    )),"Unautorized");
    
    emit(msg.toCell());
    
  }

}