// messages.tact
// Общие сообщения и константы для GreenCandle токена

const DECIMALS: Int = 9;
const TAX_BPS: Int = 1000;
const BPS_DENOM: Int = 10000;

message InternalMint { 
    to: Address;
    amount: Int as coins;
}

message InternalReceive { 
    from: Address;
    amount: Int as coins;
}

message InitTax { 
    addr: Address;
}

message Transfer {
    to: Address;
    amount: Int as coins;
    notify: Bool;
    forwardTon: Int as coins;
    responseTo: Address;
}
