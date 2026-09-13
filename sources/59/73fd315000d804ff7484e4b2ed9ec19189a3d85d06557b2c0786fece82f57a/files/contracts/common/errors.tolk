// Exit codes shared by all GRAMDESKS contracts. Each range belongs to one contract family
// so a failing transaction can be attributed without ambiguity.
enum Errors {
    // shared 3xx / 4xx
    InvalidWorkchain = 333
    NotFromAdmin = 401
    NotFromOwner = 402
    InsufficientValue = 410
    IncorrectForwardPayload = 708

    // DeskCollection 42x
    NotFromMinter = 420
    CapReached = 421
    InvalidSerial = 422

    // DeskItem 43x
    NotFromCollection = 430
    NotFromPot = 431
    StampsNotReady = 432
    SlotBusy = 433
    NoSlotsSelected = 434
    AlreadyInitialized = 435

    // Pot 44x-45x
    NotFromKeeper = 440
    NotFromDesk = 442
    SlotUnknown = 443
    SlotDisabled = 444
    OperationInFlight = 445
    NothingPending = 446
    NotRotationNext = 447
    BelowThreshold = 448
    DestNotWhitelisted = 449
    PayloadOwnerMismatch = 450
    BudgetExceeded = 451
    RoundOwed = 452
    UnknownJettonWallet = 453
    PendingNotExpired = 454
    UsdtWalletUnset = 455
    NoLiveDesks = 456
    SlotExists = 457
    InvalidParams = 458
    /// Keeper minimum output below the admin price floor (Convert / Round).
    BelowFloor = 459
    /// Escrow payload min-out lower than the keeper's declared minimum.
    PayloadMinOutMismatch = 441

    // DeskMinter 46x
    WrongDeposit = 460
    MinterPaused = 461
    NotFromDeskWallet = 462
    NoPendingDeploy = 463
    MinterCapReached = 464

    // Launcher 47x-49x (FeeSplitter, RewardMaster/Wallet, RewardVault, Curve, Pool, Factory, Buyback)
    NotFromFactory = 470
    AlreadyWired = 471
    NotFromCurve = 472
    NotFromMaster = 473
    NotFromVault = 474
    NotFromPool = 475
    SettleInFlight = 476
    CurveClosed = 477
    CurveNotOpen = 478
    SlippageExceeded = 479
    BelowMinTrade = 480
    InvalidSplits = 481
    NotFromSplitter = 482
    RewardUnknown = 483
    TooManyRewards = 484
    RewardInactive = 485
    NotWired = 486
    NotFromRewardWallet = 487
    FactoryPaused = 488
    LaunchFeeUnpaid = 489
    NotFromCoinWallet = 490
    PoolEmpty = 491
    MarketUnset = 492
    IndexOverflow = 493
}
