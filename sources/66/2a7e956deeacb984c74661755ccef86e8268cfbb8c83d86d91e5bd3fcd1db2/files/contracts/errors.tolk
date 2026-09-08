// Exit codes are kept identical to the audited FunC implementation, so that any
// client, indexer or runbook written against it keeps working.

enum Errors {
    InvalidWorkchain = 333

    NotFromOwner = 401
    TooSmallRestAmount = 402
    NotFromCollection = 403
    NotFromItem = 404
    NotInitialized = 405
    AuctionInProgress = 406
    AuctionNotStarted = 407
    AuctionNotFinished = 408
    DomainExpired = 409
    ReservedRecord = 416
    NotFound = 417

    // DNS resolver codes, identical to TON DNS
    DnsBadSubdomain = 70
    DnsBadContent = 412
    DnsNoZeroByte = 413

    WrongJettonWallet = 501
    GrmWalletNotSet = 502
    GrmWalletLocked = 503
    Accounting = 505
}
