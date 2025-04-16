message(0x4e502f4b) UserDate{
    storeId: Int as uint32;
    userAddress: Address;
    telegramId: Int as uint64;
    refererAddress: Address;
    winType: Int? as uint8;
}

message(0x3a8b046a) UserDateRequest {
    seqno: Int as uint32;
    winType: Int as uint8;
}

contract PotStorage {
    id: Int as uint32;
    potAddress: Address;
    userAddress: Address;
    refererAddress: Address;
    telegramId: Int as uint64;

    init(id: Int, potAddress: Address) {
        self.id = id;
        self.potAddress = potAddress;

        self.userAddress = myAddress();
        self.refererAddress = myAddress();
        self.telegramId = 0;
    }

    receive(msg: UserDate) {
        self.userAddress = msg.userAddress;
        self.refererAddress = msg.refererAddress;
        self.telegramId = msg.telegramId;
    }

    receive(msg: UserDateRequest){
        let body = UserDate{
            storeId: self.id,
            userAddress: self.userAddress,
            telegramId: self.telegramId,
            refererAddress: self.refererAddress,
            winType: msg.winType,
        }.toCell();

        send(SendParameters{
            to: context().sender,
            value:  ton("0.02"),
            mode: 0,
            body: body,
            bounce: false,
        });
    }

    get fun id(): Int {
        return self.id;
    }

    get fun potAddress(): Address {
        return self.potAddress;
    }

    get fun userAddress(): Address {
        return self.userAddress;
    }

    get fun refererAddress(): Address {
        return self.refererAddress;
    }

    get fun telegramId(): Int {
        return self.telegramId;
    }
}