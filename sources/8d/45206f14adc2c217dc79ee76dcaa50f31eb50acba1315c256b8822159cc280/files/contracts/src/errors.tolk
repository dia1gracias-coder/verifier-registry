enum Errors {
    NotEnoughExtensionBalance = 1012
    OnlyAdmin = 1013
    SpendLimitExceeded = 1015
    InvalidSignature = 1016
    InvalidSeqno = 1017
    Expired = 1018
    WrongDomainTag = 1019
    ValidityWindowTooLong = 1020
    ZeroAmount = 1021
    InvalidLimitParams = 1023
    DestinationWrongWorkchain = 1024
    NotEnoughValueForCancel = 1026
    WindowSecondsOutOfRange = 1027
    SinglePaymentTooLarge = 1028
    NotEnoughGasValue = 1030
    NoPendingKeyRotation = 1031
    // A1 (КРИТИЧНО): платёж самому себе позволял держателю ключа подписи
    // подделаться под админа — кошелёк отправлял сообщение расширению, и
    // отправителем оказывался кошелёк, то есть admin в продакшн-топологии.
    SelfPaymentForbidden = 1033
    PayloadNotAComment = 1034
    PayloadTooComplex = 1035
    ExtensionCancelled = 1036
    ExtensionPaused = 1038
    SmallOrderPublicKey = 1039
    RotationExpired = 1040
    AmountTooSmall = 1037
    UnsupportedExternalMessage = 0xFFFF
}
