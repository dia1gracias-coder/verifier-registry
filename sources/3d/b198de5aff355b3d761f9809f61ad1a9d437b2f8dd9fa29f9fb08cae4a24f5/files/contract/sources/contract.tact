import "@stdlib/deploy";

message(0x05138d91) OwnershipAssigned {
  queryId: Int as uint64;
  prevOwner: Address;
  forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
  queryId: Int as uint64;            
  newOwner: Address; 
  responseDestination: Address; 
  customPayload: Cell?; 
  forwardAmount: Int as coins; 
  forwardPayload: Slice as remaining; 
}

message NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

contract SampleTactContract with Deployable {
  seed: Int as uint128;
  time: Int as uint32;
  owner: Address?;
  nftAddress: Address?;
  
  init(seed: Int) {
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
    self.time = 0;
  }

  receive(msg: OwnershipAssigned) {
    if(self.owner == null){
      self.owner = msg.prevOwner;
      self.nftAddress = sender();
      self.time = now() + msg.forwardPayload.loadUint(32);
    }

    else{
      send(SendParameters{
        to: sender(),
        value: ton("0.1"),
        mode: 0,
        bounce: false,
        body: Transfer{
          queryId: 0,
          newOwner: msg.prevOwner,
          responseDestination: myAddress(),
          customPayload: emptyCell(),
          forwardAmount: ton("0.05"),
          forwardPayload: emptySlice()
        }.toCell()
      }); 
    }
  }

  receive(msg: NftWithdrawal) {
    require(sender() == self.owner, "Invalid sender");
    require(msg.nftAddress == self.nftAddress, "Invalid nft address");

    if(self.time > now()){
      self.reply("NFT is still locked".asComment());
    }

    else{
      send(SendParameters{
        to: msg.nftAddress,
        value: 0,
        mode: 128,
        bounce: false,
        body: Transfer{
          queryId: 0,
          newOwner: sender(),
          responseDestination: sender(),
          customPayload: emptyCell(),
          forwardAmount: myBalance() - context().value,
          forwardPayload: emptySlice()
        }.toCell()
      });

      self.time = 0;
      self.nftAddress = null;
      self.owner = null;
    }
  }

  get fun time(): Int {
    return max(0, self.time - now());
  }

  get fun nft(): Address? {
    return self.nftAddress;
  }

  get fun owner(): Address? {
    return self.owner;
  }
}