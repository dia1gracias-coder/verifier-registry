// Generated from the verified Tact contract ABI.
contract MasterContract {
    storage: MasterContractData
    incomingMessages: MasterContractIncomingMessage
    thrownErrors: MasterContractErrors
}

struct (0x946a98b6) MasterContractDeploy {
    queryId: uint64
}

struct (0xdcbd3cd5) MasterContractUpgrade {
    code: cell?
    data: cell?
}

struct (0x7c21eaeb) MasterContractSetAdmin {
    new_admin_address: address
}

struct (0x86d27b69) MasterContractUpdateMinTonsForStorage {
    min_tons_for_storage: coins
}

struct (0x78193f7e) MasterContractUpdateGasConsumption {
    gas_consumption: coins
}

struct (0x3878750f) MasterContractWithdraw {
    amount: coins
    target_address: address
}

struct (0xfe967d41) MasterContractSetPublicKey {
    publicKey: uint256
}

struct (0x053c1e56) MasterContractSetUserProfileCode {
    user_profile_code: cell
}

struct (0x60995238) MasterContractSetCompanyCode {
    company_code: cell
}

struct (0xe7bbef99) MasterContractUpdateContractServiceCosts {
    user_profile_creation_cost: coins
    company_creation_cost: coins
    employee_creation_cost: coins
    ceo_creation_cost: coins
    hr_creation_cost: coins
    manager_creation_cost: coins
    employee_termination_cost: coins
    tactContinuation: Cell<MasterContractUpdateContractServiceCostsContinuation>
}

struct MasterContractUpdateContractServiceCostsContinuation {
    manager_termination_cost: coins
    hr_termination_cost: coins
    ceo_termination_cost: coins
    company_grade_cost: coins
    employee_grade_cost: coins
    manager_grade_cost: coins
    employee_prolongation_cost: coins
    comment_msg_val: coins
    tactContinuation: Cell<MasterContractUpdateContractServiceCostsContinuation2>
}

struct MasterContractUpdateContractServiceCostsContinuation2 {
    deploy_gas_consumption: coins
    subcontract_gas_consumption: coins
    min_tons_for_storage_hr: coins
    created_comment_msg_val_hr: coins
    terminated_comment_msg_val_hr: coins
    employee_termination_manager_cost: coins
    company_voting_cost: coins
    min_tons_for_storage_company_voting: coins
    tactContinuation: Cell<MasterContractUpdateContractServiceCostsContinuation3>
}

struct MasterContractUpdateContractServiceCostsContinuation3 {
    comment_msg_val_company_voting: coins
    terminate_val: coins
    confirm_terminate_val: coins
    confirmation_message_from_ceo_to_company_val: coins
    manager_confirmation_cost: coins
    employee_confirmation_cost: coins
}

struct (0x65984f5a) MasterContractUpdateReviewPeriodLeaving {
    review_period_leaving: int257
}

struct (0x4ad68b28) MasterContractSetCEOAddress {
    ceo_contract_address: address
    company_address: address
    ceo_user_address: address
    uid: string
    tactContinuation: Cell<MasterContractSetCEOAddressContinuation>
}

struct MasterContractSetCEOAddressContinuation {
    version_contract_CEO: int257?
}

struct (0xfd283ca3) MasterContractSetCEOCode {
    ceo_code: cell
}

struct (0x9491007d) MasterContractUpdateContractDurationData {
    max_employee_contract_duration: int257
    min_employee_contract_duration: int257
    max_employee_contract_prolongation_duration: int257
    tactContinuation: Cell<MasterContractUpdateContractDurationDataContinuation>
}

struct MasterContractUpdateContractDurationDataContinuation {
    min_employee_contract_prolongation_duration: int257
    max_employee_start_period: int257
    max_manager_start_period: int257
    tactContinuation: Cell<MasterContractUpdateContractDurationDataContinuation2>
}

struct MasterContractUpdateContractDurationDataContinuation2 {
    min_manager_contract_duration: int257
    max_manager_contract_duration: int257
    max_voting_duration: int257
    tactContinuation: Cell<MasterContractUpdateContractDurationDataContinuation3>
}

struct MasterContractUpdateContractDurationDataContinuation3 {
    max_voting_duration_expel: int257
}

struct (0xc3c3096a) MasterContractSetHRCode {
    hr_code: cell
}

struct MasterContractContractVersionsStruct {
    code_hash: int257
    code_depth: int257
}

struct (0x4a2f2bdc) MasterContractSetVersionContract {
    type_: string
    key: int257
    value: MasterContractContractVersionsStruct
}

struct (0x426201f1) MasterContractSetCommission {
    commission_creation_employee: int257?
    commission_creation_manager: int257?
    commission_prolongation_employee: int257?
}

struct MasterContractRelatedManagerContracts {
    manager_contracts: map<int257, address>
}

struct (0xa1a06300) MasterContractTerminateEmployeeContractHR {
    company_address: address?
    employee_contract_address: address
    hr_contract_address: address
    tactContinuation: Cell<MasterContractTerminateEmployeeContractHRContinuation>
}

struct MasterContractTerminateEmployeeContractHRContinuation {
    hr_employee_address: address
    initiator_address: address?
    version_contract_hr: int257?
    related_manager_contracts: MasterContractRelatedManagerContracts?
}

struct MasterContractGradeCostValuesStruct {
    company_grade_cost: coins
    employee_grade_cost: coins
    manager_grade_cost: coins
}

struct (0x8b4ae47f) MasterContractSetEmployeeContractCode {
    employee_contract_code: cell
}

struct (0x46d54c0e) MasterContractProlongateEmployeeContractManagerContract {
    company_address: address
    manager_address: address
    manager_employee_contract: address
    tactContinuation: Cell<MasterContractProlongateEmployeeContractManagerContractContinuation>
}

struct MasterContractProlongateEmployeeContractManagerContractContinuation {
    subordinate_address: address
    subordinate_employee_contract: address
    date_start: int257
    tactContinuation: Cell<MasterContractProlongateEmployeeContractManagerContractContinuation2>
}

struct MasterContractProlongateEmployeeContractManagerContractContinuation2 {
    new_date_closed: int257
    employee_address: address?
    employee_contract_address: address?
    tactContinuation: Cell<MasterContractProlongateEmployeeContractManagerContractContinuation3>
}

struct MasterContractProlongateEmployeeContractManagerContractContinuation3 {
    review_period_leaving: int257?
    version_contract_manager: int257?
}

struct MasterContractProlongateEmployeeContractStruct {
    employee_contract_address: address
    duration: int257
}

struct (0xf14844ea) MasterContractProlongateEmployeeContractOwner {
    company_address: address
    company_creator: address?
    company_hash: int257?
    tactContinuation: Cell<MasterContractProlongateEmployeeContractOwnerContinuation>
}

struct MasterContractProlongateEmployeeContractOwnerContinuation {
    version_contract_company: int257?
    data: MasterContractProlongateEmployeeContractStruct
}

struct (0xf9cdc7a9) MasterContractProlongateEmployeeContractCEO {
    ceo_contract_address: address
    uid: string?
    company_address: address?
    initiator_address: address?
    tactContinuation: Cell<MasterContractProlongateEmployeeContractCEOContinuation>
}

struct MasterContractProlongateEmployeeContractCEOContinuation {
    version_contract_CEO: int257?
    data: MasterContractProlongateEmployeeContractStruct
}

struct (0x8d59634c) MasterContractProlongateEmployeeContractHR {
    hr_contract_address: address
    hr_employee_address: address
    company_address: address?
    tactContinuation: Cell<MasterContractProlongateEmployeeContractHRContinuation>
}

struct MasterContractProlongateEmployeeContractHRContinuation {
    company_creator: address?
    company_hash: int257?
    initiator_address: address?
    from_company: bool
    tactContinuation: Cell<MasterContractProlongateEmployeeContractHRContinuation2>
}

struct MasterContractProlongateEmployeeContractHRContinuation2 {
    version_contract_company: int257?
    version_contract_hr: int257?
    tactContinuation: Cell<MasterContractProlongateEmployeeContractHRContinuation3>
}

struct MasterContractProlongateEmployeeContractHRContinuation3 {
    data: MasterContractProlongateEmployeeContractStruct
}

struct (0x5e2ffa3e) MasterContractConfirmProlongationEmployeeContract {
    employee_contract_address: address
    initiator_address: address?
    review_period_leaving: int257?
    tactContinuation: Cell<MasterContractConfirmProlongationEmployeeContractContinuation>
}

struct MasterContractConfirmProlongationEmployeeContractContinuation {
    user_profile_creator: address?
    user_hash: int257?
    sender_wallet: address?
    sender_value: coins?
    tactContinuation: Cell<MasterContractConfirmProlongationEmployeeContractContinuation2>
}

struct MasterContractConfirmProlongationEmployeeContractContinuation2 {
    version_contract_user_profile: int257?
}

struct MasterContractTerminateManagerContractCompanyStruct {
    company_address: address
    company_creator: address?
    company_hash: int257?
    tactContinuation: Cell<MasterContractTerminateManagerContractCompanyStructContinuation>
}

struct MasterContractTerminateManagerContractCompanyStructContinuation {
    initiator_address: address?
    manager_contract_address: address
}

struct (0xf4c45823) MasterContractTerminateManagerContractHR {
    hr_contract_address: address
    hr_employee_address: address
    version_contract_hr: int257?
    tactContinuation: Cell<MasterContractTerminateManagerContractHRContinuation>
}

struct MasterContractTerminateManagerContractHRContinuation {
    data: MasterContractTerminateManagerContractCompanyStruct
}

struct (0x3ee0955d) MasterContractSetManagerContractCode {
    manager_contract_code: cell
}

struct (0x8044eafc) MasterContractSetCompanyVotingCode {
    company_voting_code: cell
}

struct (0xc126ecca) MasterContractHandleSuccessVoting {
    coowner_candidate_address: address?
    expel_candidate_address: address?
    new_company_title: string?
    new_company_description: string?
    tactContinuation: Cell<MasterContractHandleSuccessVotingContinuation>
}

struct MasterContractHandleSuccessVotingContinuation {
    new_company_logo: string?
    company_voting_address: address
    company_voting_type: string
    company_address: address
    version_contract_company_voting: int257?
}

struct MasterContractDurationStruct {
    max_employee_contract_duration: int257
    min_employee_contract_duration: int257
    max_employee_start_period: int257
    tactContinuation: Cell<MasterContractDurationStructContinuation>
}

struct MasterContractDurationStructContinuation {
    max_manager_start_period: int257
    max_employee_contract_prolongation_duration: int257
    min_employee_contract_prolongation_duration: int257
    tactContinuation: Cell<MasterContractDurationStructContinuation2>
}

struct MasterContractDurationStructContinuation2 {
    max_manager_contract_duration: int257
    min_manager_contract_duration: int257
    max_voting_duration: int257
    tactContinuation: Cell<MasterContractDurationStructContinuation3>
}

struct MasterContractDurationStructContinuation3 {
    max_voting_duration_expel: int257
}

struct MasterContractData {
    tactDeploymentCompleted: bool
    admin: address?
    index: int257
    publicKey: uint256?
    _version: uint32
    tactContinuation: Cell<MasterContractDataContinuation>
}

struct MasterContractDataContinuation {
    review_period_leaving: int257
    type_: string
    gas_consumption: coins
    min_tons_for_storage: coins
    subcontract_gas_consumption: coins
    deploy_gas_consumption: coins
    comment_msg_val: coins
    company_creation_cost: coins
    tactContinuation: Cell<MasterContractDataContinuation2>
}

struct MasterContractDataContinuation2 {
    ceo_creation_cost: coins
    employee_confirmation_cost: coins
    employee_creation_cost: coins
    employee_termination_cost: coins
    employee_termination_manager_cost: coins
    employee_prolongation_cost: coins
    employee_grade_cost: coins
    company_grade_cost: coins
    tactContinuation: Cell<MasterContractDataContinuation3>
}

struct MasterContractDataContinuation3 {
    hr_creation_cost: coins
    hr_termination_cost: coins
    min_tons_for_storage_hr: coins
    created_comment_msg_val_hr: coins
    terminated_comment_msg_val_hr: coins
    manager_confirmation_cost: coins
    manager_creation_cost: coins
    manager_termination_cost: coins
    tactContinuation: Cell<MasterContractDataContinuation4>
}

struct MasterContractDataContinuation4 {
    manager_grade_cost: coins
    company_voting_cost: coins
    min_tons_for_storage_company_voting: coins
    comment_msg_val_company_voting: int257
    user_profile_creation_cost: coins
    user_profile_code: cell?
    company_code: cell?
    ceo_code: cell?
    tactContinuation: Cell<MasterContractDataContinuation5>
}

struct MasterContractDataContinuation5 {
    hr_code: cell?
    employee_contract_code: cell?
    manager_contract_code: cell?
    tactContinuation: Cell<MasterContractDataContinuation6>
}

struct MasterContractDataContinuation6 {
    company_voting_code: cell?
    version_contract_CEO: map<int257, Cell<MasterContractContractVersionsStruct>>
    version_contract_user_profile: map<int257, Cell<MasterContractContractVersionsStruct>>
    tactContinuation: Cell<MasterContractDataContinuation7>
}

struct MasterContractDataContinuation7 {
    version_contract_company: map<int257, Cell<MasterContractContractVersionsStruct>>
    version_contract_HR: map<int257, Cell<MasterContractContractVersionsStruct>>
    version_contract_employee: map<int257, Cell<MasterContractContractVersionsStruct>>
    tactContinuation: Cell<MasterContractDataContinuation8>
}

struct MasterContractDataContinuation8 {
    version_contract_manager: map<int257, Cell<MasterContractContractVersionsStruct>>
    version_contract_company_voting: map<int257, Cell<MasterContractContractVersionsStruct>>
    duration_data: MasterContractDurationStruct
    ceo_termination_cost: coins
    terminate_val: coins
    tactContinuation: Cell<MasterContractDataContinuation9>
}

struct MasterContractDataContinuation9 {
    confirm_terminate_val: coins
    confirmation_message_from_ceo_to_company_val: coins
    commission_creation_employee: coins
    commission_creation_manager: coins
    commission_prolongation_employee: coins
}

type MasterContractIncomingMessage =
    | MasterContractSetUserProfileCode
    | MasterContractSetCompanyCode
    | MasterContractSetCEOAddress
    | MasterContractSetCEOCode
    | MasterContractSetHRCode
    | MasterContractTerminateEmployeeContractHR
    | MasterContractProlongateEmployeeContractOwner
    | MasterContractProlongateEmployeeContractCEO
    | MasterContractProlongateEmployeeContractHR
    | MasterContractConfirmProlongationEmployeeContract
    | MasterContractSetEmployeeContractCode
    | MasterContractTerminateManagerContractHR
    | MasterContractProlongateEmployeeContractManagerContract
    | MasterContractSetManagerContractCode
    | MasterContractHandleSuccessVoting
    | MasterContractSetCompanyVotingCode
    | MasterContractUpdateReviewPeriodLeaving
    | MasterContractUpdateContractServiceCosts
    | MasterContractUpdateContractDurationData
    | MasterContractSetVersionContract
    | MasterContractSetCommission
    | MasterContractSetPublicKey
    | MasterContractDeploy
    | MasterContractUpgrade
    | MasterContractSetAdmin
    | MasterContractUpdateMinTonsForStorage
    | MasterContractUpdateGasConsumption
    | MasterContractWithdraw

enum MasterContractErrors {
    /// Stack underflow
    StackUnderflow = 2
    /// Stack overflow
    StackOverflow = 3
    /// Integer overflow
    IntegerOverflow = 4
    /// Integer out of expected range
    IntegerOutOfExpectedRange = 5
    /// Invalid opcode
    InvalidOpcode = 6
    /// Type check error
    TypeCheckError = 7
    /// Cell overflow
    CellOverflow = 8
    /// Cell underflow
    CellUnderflow = 9
    /// Dictionary error
    DictionaryError = 10
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
    /// Null reference exception
    NullReferenceException = 128
    /// Invalid serialization prefix
    InvalidSerializationPrefix = 129
    /// Invalid incoming message
    InvalidIncomingMessage = 130
    /// Constraints error
    ConstraintsError = 131
    /// Access denied
    AccessDenied = 132
    /// Contract stopped
    ContractStopped = 133
    /// Invalid argument
    InvalidArgument = 134
    /// Code of a contract was not found
    CodeOfAContractWasNotFound = 135
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
    /// CreateEmployeeContractCEO: sender is not CEO address
    CreateEmployeeContractCEOSenderIsNotCEOAddress = 4249
    /// SetEmployeeContractCode: sender is not a contract admin
    SetEmployeeContractCodeSenderIsNotAContractAdmin = 4327
    /// prolongateEmployeeContract: not enough value for commission
    ProlongateEmployeeContractNotEnoughValueForCommission = 4348
    /// SetHRCode: sender is not a contract admin
    SetHRCodeSenderIsNotAContractAdmin = 5001
    /// TerminateManagerContractHR: not enough funds for manager termination
    TerminateManagerContractHRNotEnoughFundsForManagerTermination = 6813
    /// createHRContract: invalid signature
    CreateHRContractInvalidSignature = 6984
    /// SetCompanyVotingCode: sender is not a contract admin
    SetCompanyVotingCodeSenderIsNotAContractAdmin = 7163
    /// TerminateEmployeeContractHR: not enough funds for employee termination
    TerminateEmployeeContractHRNotEnoughFundsForEmployeeTermination = 7487
    /// deployManager: incorrect date_start period
    DeployManagerIncorrectDateStartPeriod = 8073
    /// prolongateEmployeeContract: incorrect duration
    ProlongateEmployeeContractIncorrectDuration = 8186
    /// validatePermissions: sender is not a contract admin
    ValidatePermissionsSenderIsNotAContractAdmin = 8384
    /// CreateCEOContract: invalid signature
    CreateCEOContractInvalidSignature = 8748
    /// ProlongateEmployeeContractOwner: sender is not equal company address
    ProlongateEmployeeContractOwnerSenderIsNotEqualCompanyAddress = 9153
    /// CreateEmployeeContractCEO: not enough funds for employee creation
    CreateEmployeeContractCEONotEnoughFundsForEmployeeCreation = 9828
    /// deployEmployee: not enough value for commission
    DeployEmployeeNotEnoughValueForCommission = 10458
    /// CreateManagerContractManager: not enough funds for manager creation
    CreateManagerContractManagerNotEnoughFundsForManagerCreation = 12094
    /// UpdateContractServiceCosts: only admin can update contract service costs
    UpdateContractServiceCostsOnlyAdminCanUpdateContractServiceCosts = 12225
    /// HandleSuccessVoting: sender is not company voting address
    HandleSuccessVotingSenderIsNotCompanyVotingAddress = 12875
    /// deployManager: incorrect duration
    DeployManagerIncorrectDuration = 14448
    /// DeployManager: forbidden create contract between same user
    DeployManagerForbiddenCreateContractBetweenSameUser = 15817
    /// CreateCEOContract: sender is not company contract
    CreateCEOContractSenderIsNotCompanyContract = 17096
    /// CreateEmployeeContractOwner: sender is not msg company
    CreateEmployeeContractOwnerSenderIsNotMsgCompany = 17941
    /// CreateManagerContractOwner: not enough funds for manager creation
    CreateManagerContractOwnerNotEnoughFundsForManagerCreation = 19107
    /// CreateUserProfileContract: invalid signature
    CreateUserProfileContractInvalidSignature = 20321
    /// ConfirmProlongationEmployeeContract: not enough funds for employee contract prolongation
    ConfirmProlongationEmployeeContractNotEnoughFundsForEmployeeContractProlongation = 20388
    /// TerminateEmployeeContractHR: sender is not HR contract
    TerminateEmployeeContractHRSenderIsNotHRContract = 21651
    /// deployEmployee: invalid signature
    DeployEmployeeInvalidSignature = 22147
    /// CreateCompanyVotingContract: invalid signature
    CreateCompanyVotingContractInvalidSignature = 22549
    /// CreateManagerContractManager: employee_manager is incorrect
    CreateManagerContractManagerEmployeeManagerIsIncorrect = 22610
    /// ProlongateEmployeeContractOwner: not enough funds for employee contract prolongation
    ProlongateEmployeeContractOwnerNotEnoughFundsForEmployeeContractProlongation = 22785
    /// CreateEmployeeContractHR: sender is not HR contract address
    CreateEmployeeContractHRSenderIsNotHRContractAddress = 23271
    /// ConfirmProlongationEmployeeContract: invalid initiator_address
    ConfirmProlongationEmployeeContractInvalidInitiatorAddress = 23514
    /// CreateCEOContract: ceo_user_address is incorrect
    CreateCEOContractCeoUserAddressIsIncorrect = 23748
    /// ProlongateEmployeeContractCEO: not enough funds for employee contract prolongation
    ProlongateEmployeeContractCEONotEnoughFundsForEmployeeContractProlongation = 24745
    /// ProlongateEmployeeContractCEO: sender is not msg CEO
    ProlongateEmployeeContractCEOSenderIsNotMsgCEO = 24886
    /// ProlongateEmployeeContractManagerContract: sender is not manager contracts
    ProlongateEmployeeContractManagerContractSenderIsNotManagerContracts = 25258
    /// CreateCompanyVotingContract: sender is not equal company address
    CreateCompanyVotingContractSenderIsNotEqualCompanyAddress = 25825
    /// CreateManagerContractSubordinate: employee_subordinate is incorrect
    CreateManagerContractSubordinateEmployeeSubordinateIsIncorrect = 26650
    /// ProlongateEmployeeContractHR: company_address is incorrect
    ProlongateEmployeeContractHRCompanyAddressIsIncorrect = 27101
    /// ProlongateEmployeeContractOwner: sender is not msg company
    ProlongateEmployeeContractOwnerSenderIsNotMsgCompany = 27936
    /// ProlongateEmployeeContractCEO: sender is not equal ceo address
    ProlongateEmployeeContractCEOSenderIsNotEqualCeoAddress = 28137
    /// CreateCompanyContract: not enough funds for company creation
    CreateCompanyContractNotEnoughFundsForCompanyCreation = 30487
    /// CheckManager: sender is not msg employee_manager_contract
    CheckManagerSenderIsNotMsgEmployeeManagerContract = 31112
    /// CheckManager: invalid employee_manager_contract for CEO
    CheckManagerInvalidEmployeeManagerContractForCEO = 32845
    /// CreateHRContractOwner: not enough funds for HR creation
    CreateHRContractOwnerNotEnoughFundsForHRCreation = 33229
    /// CheckSubordinate: sender is not msg employee_subordinate_contract
    CheckSubordinateSenderIsNotMsgEmployeeSubordinateContract = 33359
    /// CreateHRContractCEO: sender is not employee contract
    CreateHRContractCEOSenderIsNotEmployeeContract = 33497
    /// SetCommission: only admin can update commission values
    SetCommissionOnlyAdminCanUpdateCommissionValues = 33851
    /// CreateHRContractCEO: employee_contract is invalid
    CreateHRContractCEOEmployeeContractIsInvalid = 34933
    /// CreateManagerContractSubordinate: sender is not one user contracts
    CreateManagerContractSubordinateSenderIsNotOneUserContracts = 35003
    /// CreateCompanyContract: invalid signature
    CreateCompanyContractInvalidSignature = 35049
    /// CheckSubordinate: invalid employee_subordinate_contract
    CheckSubordinateInvalidEmployeeSubordinateContract = 35118
    /// CheckManager: invalid employee_manager_contract
    CheckManagerInvalidEmployeeManagerContract = 35320
    /// CreateManagerContractCEO: not enough funds for manager creation
    CreateManagerContractCEONotEnoughFundsForManagerCreation = 35374
    /// CreateCompanyVotingContract: not enough funds for company voting creation
    CreateCompanyVotingContractNotEnoughFundsForCompanyVotingCreation = 36522
    /// CreateEmployeeContractHR: sender is not company contract address
    CreateEmployeeContractHRSenderIsNotCompanyContractAddress = 37353
    /// only admin can update gas_consumption
    OnlyAdminCanUpdateGasConsumption = 37504
    /// CreateCompanyVotingContract: new_coowner is incorrect
    CreateCompanyVotingContractNewCoownerIsIncorrect = 38014
    /// TerminateManagerContractHR: sender is not equal HR address
    TerminateManagerContractHRSenderIsNotEqualHRAddress = 38482
    /// CreateHRContractOwner: sender is not equal employee contract
    CreateHRContractOwnerSenderIsNotEqualEmployeeContract = 38732
    /// CreateHRContractOwner: employee_contract is invalid
    CreateHRContractOwnerEmployeeContractIsInvalid = 39582
    /// CreateManagerContractManager: sender is not one user contracts
    CreateManagerContractManagerSenderIsNotOneUserContracts = 40595
    /// validateUpgrade: Sender is not a contract admin
    ValidateUpgradeSenderIsNotAContractAdmin = 41881
    /// ConfirmProlongationEmployeeContract: sender is not user contract
    ConfirmProlongationEmployeeContractSenderIsNotUserContract = 41943
    /// CreateEmployeeContractHR: not enough funds for employee creation
    CreateEmployeeContractHRNotEnoughFundsForEmployeeCreation = 42081
    /// CreateCompanyVotingContract: sender is not msg company
    CreateCompanyVotingContractSenderIsNotMsgCompany = 43648
    /// CreateManagerContractHR: not enough funds for manager creation
    CreateManagerContractHRNotEnoughFundsForManagerCreation = 43677
    /// ProlongateEmployeeContractHR: not enough funds for employee contract prolongation
    ProlongateEmployeeContractHRNotEnoughFundsForEmployeeContractProlongation = 43732
    /// SetVersionContract: only admin can update version_contract values
    SetVersionContractOnlyAdminCanUpdateVersionContractValues = 43929
    /// SetManagerContractCode: sender is not a contract admin
    SetManagerContractCodeSenderIsNotAContractAdmin = 44851
    /// validateUpgrade: reviews are published
    ValidateUpgradeReviewsArePublished = 45307
    /// SetUserProfileCode: sender is not a contract admin
    SetUserProfileCodeSenderIsNotAContractAdmin = 45885
    /// SetCEOCode: sender is not a contract admin
    SetCEOCodeSenderIsNotAContractAdmin = 46258
    /// SetPublicKey: only admin can update commission values
    SetPublicKeyOnlyAdminCanUpdateCommissionValues = 47714
    /// CreateCEOContract: not enough funds for CEO creation
    CreateCEOContractNotEnoughFundsForCEOCreation = 47914
    /// TerminateManagerContractHR: invalid hr_contract_address
    TerminateManagerContractHRInvalidHrContractAddress = 48715
    /// CreateHRContractCEO: sender is not CEO address
    CreateHRContractCEOSenderIsNotCEOAddress = 49727
    /// CreateManagerContractHR: sender is not equal HR address
    CreateManagerContractHRSenderIsNotEqualHRAddress = 49747
    /// upgrade_admin: sender is not a admin
    UpgradeAdminSenderIsNotAAdmin = 51220
    /// deployManager: not enough value for commission
    DeployManagerNotEnoughValueForCommission = 51504
    /// UpdateUserProfileCreationCost: only admin can update review_period_leaving
    UpdateUserProfileCreationCostOnlyAdminCanUpdateReviewPeriodLeaving = 53263
    /// CreateUserProfileContract: not enough funds for user profile creation
    CreateUserProfileContractNotEnoughFundsForUserProfileCreation = 53568
    /// CreateManagerContractCEO: sender is not equal CEO address
    CreateManagerContractCEOSenderIsNotEqualCEOAddress = 54228
    /// CreateManagerContractOwner: sender is not msg company
    CreateManagerContractOwnerSenderIsNotMsgCompany = 55024
    /// CreateEmployeeContractOwner: not enough funds for employee creation
    CreateEmployeeContractOwnerNotEnoughFundsForEmployeeCreation = 55334
    /// ProlongateEmployeeContractHR: sender is not msg HR
    ProlongateEmployeeContractHRSenderIsNotMsgHR = 55943
    /// CreateManagerContractSubordinate: not enough funds for manager creation
    CreateManagerContractSubordinateNotEnoughFundsForManagerCreation = 56620
    /// SetCEOAddress: incorrect ceo_contract_address
    SetCEOAddressIncorrectCeoContractAddress = 57188
    /// CreateHRContractCEO: not enough funds for HR creation
    CreateHRContractCEONotEnoughFundsForHRCreation = 57940
    /// deployEmployee: incorrect date_start period
    DeployEmployeeIncorrectDateStartPeriod = 59222
    /// UpdateContractDurationData: only admin can update duration_data
    UpdateContractDurationDataOnlyAdminCanUpdateDurationData = 59472
    /// CreateCompanyContract: sender is not user profile contract
    CreateCompanyContractSenderIsNotUserProfileContract = 59777
    /// validateUpgrade: date_review_end is passed
    ValidateUpgradeDateReviewEndIsPassed = 60621
    /// only admin can update min_tons_for_storage
    OnlyAdminCanUpdateMinTonsForStorage = 61107
    /// deployEmployee: employee_address is incorrect
    DeployEmployeeEmployeeAddressIsIncorrect = 61147
    /// deployManager: invalid signature
    DeployManagerInvalidSignature = 61422
    /// CreateManagerContractOwner: sender is not equal company address
    CreateManagerContractOwnerSenderIsNotEqualCompanyAddress = 61566
    /// SetCompanyCode: sender is not a contract admin
    SetCompanyCodeSenderIsNotAContractAdmin = 61729
    /// ProlongateEmployeeContractHR: sender is not equal hr address
    ProlongateEmployeeContractHRSenderIsNotEqualHrAddress = 61960
    /// deployEmployee: incorrect duration
    DeployEmployeeIncorrectDuration = 62135
    /// SetCEOAddress: sender is not CEO address
    SetCEOAddressSenderIsNotCEOAddress = 62240
    /// CreateEmployeeContractOwner: sender is not equal company address
    CreateEmployeeContractOwnerSenderIsNotEqualCompanyAddress = 63366
    /// validateUpgrade: sender is not a admin
    ValidateUpgradeSenderIsNotAAdmin = 63575
    /// HandleSuccessVoting: invalid msg company voting address
    HandleSuccessVotingInvalidMsgCompanyVotingAddress = 63697
}

get fun userProfileAddress(creator_address: address, hash: int257, version: int257): address {
    throw 0;
}

get fun companyAddress(creator_address: address, hash: int257, version: int257): address {
    throw 0;
}

get fun ceoAddress(ceo_user_address: address, company_address: address, uid: string, version: int257): address {
    throw 0;
}

get fun hrAddress(hr_user_address: address, company_address: address, version: int257): address {
    throw 0;
}

get fun employeeAddress(employee_address: address, company_address: address, tag: string, date_start: int257, version: int257): address {
    throw 0;
}

get fun managerAddress(company_address: address, manager_address: address, manager_employee_contract: address, subordinate_address: address, subordinate_employee_contract: address, date_start: int257, version: int257): address {
    throw 0;
}

get fun companyVotingAddress(company_address: address, version: int257): address {
    throw 0;
}

get fun index(): int257 {
    throw 0;
}

get fun publicKey(): int257? {
    throw 0;
}

get fun reviewPeriodLeaving(): int257 {
    throw 0;
}

get fun userProfileCreationCost(): int257 {
    throw 0;
}

get fun commentMsgVal(): int257 {
    throw 0;
}

get fun companyCreationCost(): int257 {
    throw 0;
}

get fun ceoCreationCost(): int257 {
    throw 0;
}

get fun ceoTerminationCost(): int257 {
    throw 0;
}

get fun employeeConfirmationCost(): int257 {
    throw 0;
}

get fun employeeCreationCost(): int257 {
    throw 0;
}

get fun employeeTerminationManagerCost(): int257 {
    throw 0;
}

get fun employeeTerminationCost(): int257 {
    throw 0;
}

get fun employeeProlongationCost(): int257 {
    throw 0;
}

get fun hrCreationCost(): int257 {
    throw 0;
}

get fun hrTerminationCost(): int257 {
    throw 0;
}

get fun minTonsForStorageHr(): int257 {
    throw 0;
}

get fun createdCommentMsgValHr(): int257 {
    throw 0;
}

get fun terminatedCommentMsgValHr(): int257 {
    throw 0;
}

get fun managerConfirmationCost(): int257 {
    throw 0;
}

get fun managerCreationCost(): int257 {
    throw 0;
}

get fun managerTerminationCost(): int257 {
    throw 0;
}

get fun companyVotingCreationCost(): int257 {
    throw 0;
}

get fun minTonsForStorageCompanyVoting(): int257 {
    throw 0;
}

get fun subcontractGasConsumption(): int257 {
    throw 0;
}

get fun deployGasConsumption(): int257 {
    throw 0;
}

get fun commentMsgValCompanyVoting(): int257 {
    throw 0;
}

get fun durationData(): MasterContractDurationStruct {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun GradeCost(): MasterContractGradeCostValuesStruct {
    throw 0;
}

// Tact getter name: type
// Tact method ID: 129607
get fun type_(): string {
    throw 0;
}

get fun terminateVal(): int257 {
    throw 0;
}

get fun confirmTerminateVal(): int257 {
    throw 0;
}

get fun confirmationMessageFronCeoToCompanyVal(): int257 {
    throw 0;
}

get fun versionContract(type_: string, key: int257): MasterContractContractVersionsStruct? {
    throw 0;
}

get fun commissionCreationEmployee(): int257 {
    throw 0;
}

get fun commissionCreationManager(): int257 {
    throw 0;
}

get fun commissionProlongationEmployee(): int257 {
    throw 0;
}

get fun adminAddress(): address? {
    throw 0;
}

get fun isUpgradable(): bool {
    throw 0;
}

get fun version(): int257 {
    throw 0;
}

get fun gasConsumption(): int257 {
    throw 0;
}

get fun minTonsForStorage(): int257 {
    throw 0;
}
