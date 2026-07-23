/// Stable contract exit codes. Do not renumber: backend settlement and diagnostics use them.
enum Errors {
    NotFromOwner = 401
    NotFromPendingOwner = 403
    NotFromCollection = 405
    InvalidWorkchain = 406

    InvalidForwardPayload = 708
    TooLittleValue = 709
    PriceBelowMinimum = 710
    CollectionPaused = 711
    SupplyExhausted = 712
    WrongRecipient = 713
    WrongCollection = 714
    WrongVoucherDomain = 715
    VoucherExpired = 716
    InvalidSignature = 717
    SerialAlreadyClaimed = 718
    NonceAlreadyUsed = 719
    InvalidSerial = 720
    PendingOwnerNotSet = 721
    InvalidAddress = 722
    SerialOutOfRange = 723
    MaxSupplyOutOfRange = 724
    TransferPending = 725
    NoPendingTransfer = 726
    WrongTransferAuthorization = 727
    TransferNonceExhausted = 728
    InvalidContentId = 729
}
