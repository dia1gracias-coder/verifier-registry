// these error codes are quite strange, but they are exactly the same as in FunC implementation
// Source: https://github.com/ton-blockchain/acton-contracts/blob/master/nft-v1.1/contracts/errors.tolk
// Extra codes 410+ are minter / contentHash checks, not TEP-62.

enum Errors {
    BatchLimitExceeded = 399
    InvalidWorkchain = 333
    NotFromAdmin = 401
    NotFromOwner = 401
    NotFromCollection = 405
    InvalidItemIndex = 402
    TooSmallRestAmount = 402
    IncorrectForwardPayload = 708

    Paused = 410
    BadSignature = 411
    SeqnoMismatch = 412
    PermitExpired = 413
    SenderMismatch = 414
    PermitBind = 415
    InvalidPatentFields = 420
    InsufficientValue = 421
}
