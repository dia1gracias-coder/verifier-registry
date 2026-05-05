type ForwardPayloadRemainder = RemainingBitsAndRefs

type AllowedMessage = InitContract | TakeWalletAddress | TransferNotification | OpenDisput | ReleaseMonthRent | ResolveDispute | CloseRentContract | ConfirmCheckIn | OpenCheckInDispute | OpenMonthDispute | ConfirmCheckOutTenant | ConfirmCheckOutLandloard | OpenCheckOutDispute
type TheoreticallyBounceable = AskToTransfer | ProvideWalletAddress
//ADMIN ACTIONS
//Відкриття диспуту у будь-який момент
struct (0x1001) OpenDisput{}

//Виплата орендної плати за місяць
//month - місяць оренди
struct (0x1002) ReleaseMonthRent {
    month: uint8,
    queryId: uint56
}

//Вирішення диспуту
// rentToTenant: Скільки оренди до Орендаря,
// rentToLandlord: Скільки оренди до Орендодавця,
// depositToTenant: Скільки депозиту до Орендаря,
// depositToLandlord: Скільки депозиту до Орендодавця
struct (0x1003) ResolveDispute {
    queryId: uint56,
    rentToTenant: coins,
    rentToLandlord: coins,
    depositToTenant: coins,
    depositToLandlord: coins
}

struct (0x1004) CloseRentContract {

}
//TENANT ACTIONS
//Підтвердження заселення
struct (0x2001) ConfirmCheckIn {

}

//Відкриття диспуту протягом 24 год після заселення
struct (0x2002) OpenCheckInDispute {

}

//Відкриття диспуту протягом 24 год після попереднього місяця
struct (0x2003) OpenMonthDispute {

}

//Підтвердження виселення
struct (0x2004) ConfirmCheckOutTenant {

}


//LANDLORD ACTIONS
//Підтвердження виселення
struct (0x3001) ConfirmCheckOutLandloard {

}

//Відкриття диспуту протягом 24 год після виселення
struct (0x3002) OpenCheckOutDispute {

}

// TEP-89 message structs
struct (0x2c76b973) ProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool       // ask minter to echo owner back in the response
}

struct (0xd1735400) TakeWalletAddress {
    queryId: uint64
    walletAddress: address
    ownerAddress: Cell<address>?   // optional, returned only if includeAddress = true
}


struct (0x12345678) InitContract {}

// TEP-74: incoming jetton transfer notification
struct (0x7362d09c) TransferNotification {
    queryId: uint64
    jettonAmount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}


struct (0x0f8a7ea5) AskToTransfer {
    queryId: uint64
    jettonAmount: coins
    transferRecipient: address
    sendExcessesTo: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}