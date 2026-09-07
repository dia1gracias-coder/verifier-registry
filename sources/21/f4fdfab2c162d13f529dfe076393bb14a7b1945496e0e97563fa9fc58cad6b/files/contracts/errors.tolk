enum Errors {
    UnknownOp = 0xffff

    // Standard Jetton-compatible errors.
    Balance = 47
    NotEnoughGas = 48
    InvalidMessage = 49
    InvalidOp = 72
    NotOwner = 73
    NotValidWallet = 74
    WrongWorkchain = 333

    // Fixed-supply bootstrap errors.
    AlreadyMinted = 401
    InvalidSupply = 402
    MintNotComplete = 403
    WrongReserve = 404
    AlreadySealed = 405
    NotSealed = 406

    // Release protocol errors.
    NotExecutor = 420
    NotCollector = 421
    NotBootstrapAdmin = 422
    InvalidOperationId = 423
    OperationExists = 424
    OperationNotFound = 425
    InvalidOperationState = 426
    Expired = 427
    DeadlineTooFar = 428
    InvalidAmount = 429
    HardCap = 430
    BadRatio = 431
    DuplicateInput = 432
    WrongInputSource = 433
    InsufficientOperationValue = 434
    NotRefundable = 435
    NotPrunable = 436
    SweepBalance = 437
    SweepPending = 438
    UnexpectedConfirmation = 439

    // Locker errors.
    LockerNotBound = 450
    InvalidLpSource = 451
    InvalidPoolSource = 452
    InvalidLockPayload = 453
    SlotExists = 454
    SlotNotFound = 455
    SlotLocked = 456
    NotBeneficiary = 457
    WithdrawPending = 458
    WithdrawNotPending = 459
    WrongConfirmationWallet = 460
    LockIntentNotRegistered = 461
    LockIntentMismatch = 462
    LockIntentNotExpired = 463
    SlotTransferNotPending = 464
    SlotTransferExpired = 465
    SlotTransferSameBeneficiary = 466
    NotProposedBeneficiary = 467

    // Permissionless release V2 errors.
    PriceObservationPending = 470
    ObservationTooEarly = 471
    InvalidPoolResponse = 472
    PoolLocked = 473
    PriceDeviation = 474
    InputImbalance = 475
    ReserveExhausted = 476
    WalletDiscoveryPending = 477
    BootstrapPending = 478
    BootstrapComplete = 479
    PoolTooShallow = 480
    NoProtocolFees = 481
}

// Compatibility aliases keep ABI/test expectations readable while production
// throw sites use the symbolic enum required by Acton's static analysis.
const ERROR_UNKNOWN_OP = Errors.UnknownOp
const ERROR_BALANCE = Errors.Balance
const ERROR_NOT_ENOUGH_GAS = Errors.NotEnoughGas
const ERROR_INVALID_MESSAGE = Errors.InvalidMessage
const ERROR_INVALID_OP = Errors.InvalidOp
const ERROR_NOT_OWNER = Errors.NotOwner
const ERROR_NOT_VALID_WALLET = Errors.NotValidWallet
const ERROR_WRONG_WORKCHAIN = Errors.WrongWorkchain
const ERROR_ALREADY_MINTED = Errors.AlreadyMinted
const ERROR_INVALID_SUPPLY = Errors.InvalidSupply
const ERROR_MINT_NOT_COMPLETE = Errors.MintNotComplete
const ERROR_WRONG_RESERVE = Errors.WrongReserve
const ERROR_ALREADY_SEALED = Errors.AlreadySealed
const ERROR_NOT_SEALED = Errors.NotSealed
const ERROR_NOT_EXECUTOR = Errors.NotExecutor
const ERROR_NOT_COLLECTOR = Errors.NotCollector
const ERROR_NOT_BOOTSTRAP_ADMIN = Errors.NotBootstrapAdmin
const ERROR_INVALID_OPERATION_ID = Errors.InvalidOperationId
const ERROR_OPERATION_EXISTS = Errors.OperationExists
const ERROR_OPERATION_NOT_FOUND = Errors.OperationNotFound
const ERROR_INVALID_OPERATION_STATE = Errors.InvalidOperationState
const ERROR_EXPIRED = Errors.Expired
const ERROR_DEADLINE_TOO_FAR = Errors.DeadlineTooFar
const ERROR_INVALID_AMOUNT = Errors.InvalidAmount
const ERROR_HARD_CAP = Errors.HardCap
const ERROR_BAD_RATIO = Errors.BadRatio
const ERROR_DUPLICATE_INPUT = Errors.DuplicateInput
const ERROR_WRONG_INPUT_SOURCE = Errors.WrongInputSource
const ERROR_INSUFFICIENT_OPERATION_VALUE = Errors.InsufficientOperationValue
const ERROR_NOT_REFUNDABLE = Errors.NotRefundable
const ERROR_NOT_PRUNABLE = Errors.NotPrunable
const ERROR_SWEEP_BALANCE = Errors.SweepBalance
const ERROR_SWEEP_PENDING = Errors.SweepPending
const ERROR_UNEXPECTED_CONFIRMATION = Errors.UnexpectedConfirmation
const ERROR_LOCKER_NOT_BOUND = Errors.LockerNotBound
const ERROR_INVALID_LP_SOURCE = Errors.InvalidLpSource
const ERROR_INVALID_POOL_SOURCE = Errors.InvalidPoolSource
const ERROR_INVALID_LOCK_PAYLOAD = Errors.InvalidLockPayload
const ERROR_SLOT_EXISTS = Errors.SlotExists
const ERROR_SLOT_NOT_FOUND = Errors.SlotNotFound
const ERROR_SLOT_LOCKED = Errors.SlotLocked
const ERROR_NOT_BENEFICIARY = Errors.NotBeneficiary
const ERROR_WITHDRAW_PENDING = Errors.WithdrawPending
const ERROR_WITHDRAW_NOT_PENDING = Errors.WithdrawNotPending
const ERROR_WRONG_CONFIRMATION_WALLET = Errors.WrongConfirmationWallet
const ERROR_LOCK_INTENT_NOT_REGISTERED = Errors.LockIntentNotRegistered
const ERROR_LOCK_INTENT_MISMATCH = Errors.LockIntentMismatch
const ERROR_LOCK_INTENT_NOT_EXPIRED = Errors.LockIntentNotExpired
const ERROR_SLOT_TRANSFER_NOT_PENDING = Errors.SlotTransferNotPending
const ERROR_SLOT_TRANSFER_EXPIRED = Errors.SlotTransferExpired
const ERROR_SLOT_TRANSFER_SAME_BENEFICIARY = Errors.SlotTransferSameBeneficiary
const ERROR_NOT_PROPOSED_BENEFICIARY = Errors.NotProposedBeneficiary
const ERROR_POOL_TOO_SHALLOW = Errors.PoolTooShallow
const ERROR_NO_PROTOCOL_FEES = Errors.NoProtocolFees
