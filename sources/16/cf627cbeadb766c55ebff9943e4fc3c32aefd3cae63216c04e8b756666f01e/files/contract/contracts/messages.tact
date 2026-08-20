message Withdraw {
    amount: Int as coins;
    target_address: Address;
}

message Burn {}

message CompanyWithdraw {
    amount: Int as coins;
    target_address: Address;
    company_address: Address
}

message SendMessageWithComment {
    address: Address;
    comment: String;
    value: Int;
}

message SetPublicKey {
    publicKey: Int as uint256;
}

message CreateUserProfileContract {
    admin_address: Address?;
    comment_msg_val: Int? as coins;
    creator_address: Address?;
    gas_consumption: Int? as coins;
    hash: Int;
    signature: Slice;
    telegram_id: Int?;
}

message SetUserProfileCode {
    user_profile_code: Cell;
}

struct UserProfileInitData {
    lazy_bit: Bool;
    master_contract: Address;
    creator_address: Address;
    hash: Int;
}

message CreateCompanyContract {
    comment_msg_val: Int? as coins;
    gas_consumption: Int? as coins;
    creator_address: Address?; // profile_address
    admin_address: Address?;
    description: String;
    logo: String?;
    title: String;
    company_hash: Int;
    user_profile_creator: Address?; // wallet
    user_profile_hash: Int?;
    signature: Slice;
    version_contract_user_profile: Int?;
}

message SetCompanyCode {
    company_code: Cell;
}

struct CompanyInitData {
    lazy_bit: Bool;
    master_contract: Address;
    creator_address: Address;
    hash: Int;
}

message AddWallet {
    new_wallet: Address;
}

message UpdateCeoConfirmationCost {
    ceo_confirmation_cost: Int as coins;
}

message UpdateCommentMsgVal {
    comment_msg_val:Int as coins;
}

message UpdateMsgVals {
    comment_msg_val:Int as coins;
    termination_manager_cost:Int as coins;
}

message UpdateContractServiceCosts {
    user_profile_creation_cost: Int as coins;
    company_creation_cost: Int as coins;
    employee_creation_cost: Int as coins;
    ceo_creation_cost: Int as coins;
    hr_creation_cost: Int as coins;
    manager_creation_cost: Int as coins;
    employee_termination_cost: Int as coins;
    manager_termination_cost: Int as coins;
    hr_termination_cost: Int as coins;
    ceo_termination_cost: Int as coins;
    company_grade_cost: Int as coins;
    employee_grade_cost: Int as coins;
    manager_grade_cost: Int as coins;
    employee_prolongation_cost: Int as coins;
    comment_msg_val: Int as coins;
    deploy_gas_consumption: Int as coins;
    subcontract_gas_consumption: Int as coins;
    min_tons_for_storage_hr: Int as coins;
    created_comment_msg_val_hr: Int as coins;
    terminated_comment_msg_val_hr: Int as coins;
    employee_termination_manager_cost: Int as coins;
    company_voting_cost: Int as coins;
    min_tons_for_storage_company_voting: Int as coins;
    comment_msg_val_company_voting: Int as coins;
    terminate_val: Int as coins;
    confirm_terminate_val: Int as coins;
    confirmation_message_from_ceo_to_company_val: Int as coins;
    manager_confirmation_cost: Int as coins;
    employee_confirmation_cost: Int as coins;
}

message UpdateReviewPeriodLeaving {
    review_period_leaving: Int;
}

// CEO
struct UserCheckData {
    creator_address: Address;
    hash: Int;
    version_contract_user_profile: Int;
}

message CreateCEOContract {
    admin_address: Address?;
    ceo_user_address: Address;
    ceo_user_check_data: UserCheckData;
    company_address: Address;
    company_creator_address: Address?;
    creator_address: Address?;
    company_hash: Int?;
    description: String?;
    terminate_msg_val: Int? as coins;
    confirm_terminate_msg_val: Int? as coins;
    confirmation_message_to_company_val: Int? as coins;
    comment_msg_val: Int? as coins;
    gas_consumption: Int? as coins;
    review_period_leaving: Int?;
    signature: Slice;
    uid: String;
    version_contract_company: Int?;
}

message ConfirmCEOContract {
    ceo_contract_address: Address;
    user_profile_address: Address?;
}

message TerminateCEOContract {
    ceo_contract_address: Address;
    initiator_address: Address;
    sender_value: Int? as coins;
    related_manager_contracts: RelatedManagerContracts?;
}

message TerminateCEOContractUser {
    ceo_contract_address: Address;
    initiator_address: Address?;
    related_manager_contracts: RelatedManagerContracts?;
}

message TerminateCEOContractOwner {
    ceo_contract_address: Address;
    company_address: Address;
    initiator_address: Address?;
    related_manager_contracts: RelatedManagerContracts?;
}

message ConfirmTerminationCEOContract {
    ceo_contract_address: Address;
}

message SetCEOAddress {
    ceo_contract_address: Address;
    company_address: Address;
    ceo_user_address: Address;
    uid: String;
    version_contract_CEO: Int?;
}

message SetCEOCode {
    ceo_code: Cell;
}

struct CEOInitData {
    lazy_bit: Bool;
    master_contract: Address;
    ceo_user_address: Address;
    company_address: Address;
    uid: String;
}
// CEO END

// HR
message CreateHRContract {
    admin_address: Address?;
    creator_address: Address?;
    employee_contract: Address;
    gas_consumption: Int?;
    min_tons_for_storage: Int?;
    created_msg_val: Int?;
    signature: Slice;
    terminated_msg_val: Int?;
}

message CreateHRContractOwner {
    admin_address: Address?;
    company_address: Address;
    company_hash: Int?;
    creator_address: Address?;
    hr_user_address: Address;
    employee_contract: Address;
    employee_date_start: Int? as uint32;
    signature: Slice;
    tag: String?;
    version_contract_employee: Int?;
}

message CreateHRContractCEO {
    admin_address: Address?;
    ceo_contract_address: Address;
    uid: String?;
    company_address: Address?;
    creator_address: Address?;
    hr_user_address: Address;
    employee_contract: Address;
    employee_date_start: Int? as uint32;
    signature: Slice;
    tag: String?;
    check_CEO_employee: Bool?;
    from_CEO: Bool?;
    from_employee: Bool?;
    version_contract_CEO: Int?;
    version_contract_employee: Int?;
}

message TerminateHRContract {
    company_address: Address?;
//     hr_contract_address: Address;
    initiator_address: Address; // ToDo remove???
}

message TerminateHRContractOwner {
    company_address: Address;
    hr_contract_address: Address;
    initiator_address: Address?;
    user_profile_creator: Address?;
    user_hash: Int?;
}

message TerminateHRContractCEO {
    ceo_contract_address: Address;
    uid: String?;
    company_address: Address?;
    hr_contract_address: Address;
    initiator_address: Address?;
}

message TerminateHRContractHR {
    company_address: Address;
    hr_contract_address: Address;
    initiator_address: Address?;
    user_profile_creator: Address?;
    user_hash: Int?;
}

message UpdateHrConfirmationCost {
    hr_confirmation_cost: Int as coins;
}

message UpdateContractDurationData {
    max_employee_contract_duration: Int;
    min_employee_contract_duration: Int;
    max_employee_contract_prolongation_duration: Int;
    min_employee_contract_prolongation_duration: Int;
    max_employee_start_period: Int;
    max_manager_start_period: Int;
    min_manager_contract_duration: Int;
    max_manager_contract_duration: Int;
    max_voting_duration: Int;
    max_voting_duration_expel: Int;
}

message SetHRCode {
    hr_code: Cell;
}

struct ContractVersionsStruct{
    code_hash: Int;
    code_depth: Int;
}

message SetVersionContract {
    type: String;
    key: Int;
    value: ContractVersionsStruct
}

message SetCommission {
    commission_creation_employee: Int?;
    commission_creation_manager: Int?;
    commission_prolongation_employee: Int?;
}

struct HRInitData {
    lazy_bit: Bool;
    master_contract: Address;
    hr_user_address: Address;
    company_address: Address;
}
// HR END

// EMPLOYEE
message CreateEmployeeContract {
    admin_address: Address?;
    company_address: Address;
    creator_address: Address?;
    company_hash: Int?;
    comment_msg_val: Int? as coins;
    description: String?;
    duration: Int as uint32;
    gas_consumption: Int? as coins;
    review_period_leaving: Int? as uint32;
    hours: String;
    signature: Slice;
    termination_manager_cost: Int? as coins;
    schedule: String;
}

message CreateEmployeeContractOwner {
    admin_address: Address?;
    company_address: Address;
    company_creator_address: Address?;
    company_hash: Int?;
    creator_address: Address?;
    date_start: Int as uint32;
    description: String?;
    duration: Int as uint32;
    employee_address: Address;
    employee_check_data: UserCheckData;
    hours: String;
    signature: Slice;
    schedule: String;
    tag: String;
    version_contract_company: Int?;
}

message CreateEmployeeContractCEO {
    admin_address: Address?;
    ceo_contract_address: Address;
    uid: String?;
    company_address: Address?;
    creator_address: Address?;
    date_start: Int as uint32;
    description: String?;
    duration: Int as uint32;
    employee_address: Address;
    employee_check_data: UserCheckData;
    hours: String;
    signature: Slice;
    schedule: String;
    tag: String;
    version_contract_CEO: Int?;
}

message CreateEmployeeContractHR {
    admin_address: Address?;
    hr_contract_address: Address;
    hr_employee_address: Address;
    company_address: Address?;
    company_creator_address: Address?;
    company_hash: Int?;
    creator_address: Address?;
    date_start: Int as uint32;
    description: String?;
    duration: Int as uint32;
    employee_address: Address;
    employee_check_data: UserCheckData;
    tag: String;
    hours: String;
    signature: Slice;
    schedule: String;
    from_company: Bool = false;
    version_contract_company: Int?;
    version_contract_hr: Int?;
}

struct RelatedManagerContracts {
    manager_contracts: map<Int, Address>
}

message TerminateEmployeeContract {
    initiator_address: Address;
    is_CEO: Bool = false;
    is_HR: Bool = false;
    company_address: Address?;
    related_manager_contracts: RelatedManagerContracts?;
}

message TerminateEmployeeContractOwner {
    company_address: Address;
    employee_contract_address: Address;
    initiator_address: Address?;
    user_profile_creator: Address?;
    user_hash: Int?;
    related_manager_contracts: RelatedManagerContracts?;
}

message TerminateEmployeeContractEmployee {
    employee_contract_address: Address;
    initiator_address: Address?;
    user_profile_creator: Address?;
    user_hash: Int?;
    related_manager_contracts: RelatedManagerContracts?;
}

message ConfirmEmployeeContract {
    employee_contract_address: Address;
    initiator_address: Address?;
    user_profile_creator: Address?;
    user_hash: Int?;
    sender_wallet: Address?;
    sender_value: Int? as coins;
}

message TerminateEmployeeContractCEO {
    ceo_contract_address: Address;
    uid: String?;
    company_address: Address?;
    employee_contract_address: Address;
    initiator_address: Address?;
    related_manager_contracts: RelatedManagerContracts?;
}

message TerminateEmployeeContractHR {
    company_address: Address?;
    employee_contract_address: Address;
    hr_contract_address: Address;
    hr_employee_address: Address;
    initiator_address: Address?;
    version_contract_hr: Int?;
    related_manager_contracts: RelatedManagerContracts?;
}

message LeaveCompanyGrade{  // employee about company
    company_grade: Int as uint4;
    company_review: String;
    employee_contract_address: Address;
    initiator_address: Address?;
    user_profile_creator: Address?;
    user_hash: Int?;
}

message EditCompanyGrade{  // employee about company
    company_grade: Int as uint4;
    company_review: String;
    employee_contract_address: Address; // or CEO
    initiator_address: Address?;
    user_profile_creator: Address?;
    user_hash: Int?; // ToDo correct fields
}

message LeaveEmployeeGrade { // company about employee
    company_address: Address?;
    employee_grade: Int as uint4;
    employee_review: String;
    initiator_address: Address
}

message LeaveEmployeeGradeOwner { // company owner about employee
    company_address: Address;
    company_creator: Address?;
    company_hash: Int?;
    employee_grade: Int as uint4;
    employee_review: String;
    employee_contract_address: Address; // or CEO address
    initiator_address: Address?;
}

message LeaveEmployeeGradeCEO { // company CEO about employee
    ceo_contract_address: Address;
    uid: String?;
    company_address: Address?;
    employee_grade: Int as uint4;
    employee_review: String;
    employee_contract_address: Address;
    initiator_address: Address?;
}

message EditEmployeeGrade { // company about employee
    company_address: Address?;
    employee_grade: Int as uint4;
    employee_review: String;
    initiator_address: Address;
}

message EditEmployeeGradeOwner { // company owner about employee
    company_address: Address;
    company_creator: Address?;
    company_hash: Int?;
    employee_grade: Int as uint4;
    employee_review: String;
    employee_contract_address: Address; // or CEO address
    initiator_address: Address?;
}

message EditEmployeeGradeCEO { // company CEO about employee
    ceo_contract_address: Address;
    uid: String?;
    company_address: Address?;
    employee_grade: Int as uint4;
    employee_review: String;
    employee_contract_address: Address;
    initiator_address: Address?;
}

message UpdateGradeCostValues {
    company_grade_cost: Int as coins;
    employee_grade_cost: Int as coins;
    manager_grade_cost: Int as coins;
}

struct GradeCostValuesStruct{
    company_grade_cost: Int as coins;
    employee_grade_cost: Int as coins;
    manager_grade_cost: Int as coins;
}

struct EmployeeInitData {
    lazy_bit: Bool;
    master_contract: Address;
    employee_address: Address;
    company_address: Address;
    tag: String;
    date_start: Int
}

message SetEmployeeContractCode {
    employee_contract_code: Cell;
}

message ProlongateEmployeeContractManagerContract {
    company_address: Address;
    manager_address:  Address; // user profile contract
    manager_employee_contract:  Address;
    subordinate_address:  Address; // user profile contract
    subordinate_employee_contract:  Address;
    date_start: Int;
    new_date_closed: Int;
    employee_address: Address?;
    employee_contract_address: Address?;
    review_period_leaving: Int?;
    version_contract_manager: Int?;
}

message ProlongateEmployeeContract {
    company_address: Address;
    duration: Int;
    review_period_leaving: Int?
}

struct ProlongateEmployeeContractStruct {
    employee_contract_address: Address;
    duration: Int;
}

message ProlongateEmployeeContractOwner {
    company_address: Address;
    company_creator: Address?;
    company_hash: Int?;
    version_contract_company: Int?;
    data: ProlongateEmployeeContractStruct
}

message ProlongateEmployeeContractCEO {
    ceo_contract_address: Address;
    uid: String?;
    company_address: Address?;
    initiator_address: Address?;
    version_contract_CEO: Int?;
    data: ProlongateEmployeeContractStruct
}

message ProlongateEmployeeContractHR {
    hr_contract_address: Address;
    hr_employee_address: Address;
    company_address: Address?;
    company_creator: Address?;
    company_hash: Int?;
    initiator_address: Address?;
    from_company: Bool = false;
    version_contract_company: Int?;
    version_contract_hr: Int?;
    data: ProlongateEmployeeContractStruct
}

message ConfirmProlongationEmployeeContract {
    employee_contract_address: Address;
    initiator_address: Address?;
    review_period_leaving: Int?;
    user_profile_creator: Address?;
    user_hash: Int?;
    sender_wallet: Address?;
    sender_value: Int? as coins;
    version_contract_user_profile: Int?;
}

message RefuseEmployeeContract {
    employee_contract_address: Address;
    sender_value: Int? as coins;
}

// EMPLOYEE END

// MANAGER

struct VersionStruct {
    version_contract_CEO: Int?;
}

struct CreateManagerContractStruct {
    company_creator: Address?;
    company_hash: Int?;
    creator_address: Address?; // userProfile company owner
    date_start: Int as uint32;
    description: String?;
    duration: Int as uint32;
    employee_manager: Address;
    employee_manager_contract: Address;
    employee_manager_is_CEO: Bool;
    employee_subordinate: Address;
    employee_subordinate_contract: Address;
    review_period_leaving: Int as uint32;
    signature: Slice;
    tag_manager: String?;
    tag_subordinate: String?;
}

message CreateManagerContractOwner {
    company_address: Address;
    version_contract_company: Int?;
    data: CreateManagerContractStruct;
}

message CreateManagerContractCEO {
    ceo_contract_address: Address;
    uid: String?;
    company_address: Address?;
    data: CreateManagerContractStruct;
    version_contract_CEO: Int?;
}

message CreateManagerContractHR {
    hr_contract_address: Address;
    hr_employee_address: Address;
    company_address: Address?;
    from_company: Bool = false;
    version_contract_company: Int?;
    version_contract_hr: Int?;
    data: CreateManagerContractStruct;
}

message CreateManagerContractManager {
    company_address: Address;
    user_creator_address: Address?;
    user_hash: Int?;
    version_contract_user_profile: Int?;
    data: CreateManagerContractStruct;
}

message CreateManagerContractSubordinate {
    company_address: Address;
    user_creator_address: Address?;
    user_hash: Int?;
    version_contract_user_profile: Int?;
    data: CreateManagerContractStruct;
}

message CreateManagerContract { // ToDo use CreateManagerContractStruct
    admin_address: Address?;
    company_address: Address;
    comment_msg_val: Int;
    creator_address: Address?; // user profile
    date_start: Int as uint32;
    description: String?;
    duration: Int as uint32;
    gas_consumption: Int as coins;
    review_period_leaving: Int as uint32;
    signature: Slice;
    tag_manager: String?;
    tag_subordinate: String?;
}

message CheckManager { // ToDo use CreateManagerContractStruct
    company_address: Address;
    data: CreateManagerContractStruct;
    employee_date_start: Int? as uint32;
    uid: String?;
    version_contract_CEO: Int?;
    version_contract_employee: Int?;
}

message CheckSubordinate { // ToDo use CreateManagerContractStruct
    company_address: Address;
    version_contract_employee: Int?;
    data: CreateManagerContractStruct;
    employee_date_start: Int? as uint32;
}

struct ConfirmManagerContract {
    employee_contract_address: Address;
    company_address: Address?;
    employee_date_start: Int? as uint32;
    initiator_address: Address?;
    tag: String?;
    manager_contract_address: Address;
    employee_manager_contract_date_closed: Int?;
    employee_subordinate_contract_date_closed: Int?;
}

message ConfirmManagerContractManager {
    data: ConfirmManagerContract;
}

message ConfirmManagerContractSubordinate {
    data: ConfirmManagerContract;
}

message TerminateManagerContractEmployees {
    creator_address: Address?;
    initiator_address: Address?;
    user_hash: Int?;
    input_value: Int?;
    manager_contract_address: Address;
}

struct TerminateManagerContractCompanyStruct {
    company_address: Address;
    company_creator: Address?;
    company_hash: Int?;
    initiator_address: Address?;
    manager_contract_address: Address;
}

message TerminateManagerContractOwner {
    data: TerminateManagerContractCompanyStruct;
}

message TerminateManagerContractCEO {
    ceo_contract_address: Address;
    uid: String?;
    data: TerminateManagerContractCompanyStruct;
}

message TerminateManagerContractHR {
    hr_contract_address: Address;
    hr_employee_address: Address;
    version_contract_hr: Int?;
    data: TerminateManagerContractCompanyStruct;
}

message TerminateManagerContractCompany {
    initiator_address: Address;
    company_address: Address;
}

message TerminateManagerContractEmployeeContract {
    manager_contract_address: Address?;
    employee_address: Address;
    company_address: Address;
    tag: String;
    date_start: Int;
}
message TerminateManagerContractCEOContractService {}

struct ManagerGradeStruct {
    grade: Int as uint4;
    review: String;
    manager_contract_address: Address;
    initiator_address: Address?;
    user_profile_creator: Address?;
    user_hash: Int?;
}

message LeaveSubordinateGrade{ // manager about subordinate
    data: ManagerGradeStruct;
}

message LeaveManagerGrade{ // subordinate about manager
    data: ManagerGradeStruct;
}

message EditSubordinateGrade{ // manager about subordinate
    data: ManagerGradeStruct;
}

message EditManagerGrade{ // subordinate about manager
    data: ManagerGradeStruct;
}

struct ManagerInitData {
    lazy_bit: Bool;
    master_contract: Address;
    company_address: Address;
    manager_address:  Address; // user profile contract
    manager_employee_contract:  Address;
    subordinate_address:  Address; // user profile contract
    subordinate_employee_contract:  Address;
    date_start: Int
}

message SetManagerContractCode {
    manager_contract_code: Cell;
}
// MANAGER END

// COMPANY VOTING
struct CompanyVotingInitData {
    lazy_bit: Bool;
    master_contract: Address;
    company_address: Address;
}

message SetCompanyVotingCode{
    company_voting_code: Cell;
}

message CreateCompanyVotingContract{
    admin_address: Address?;
    company_address: Address;
    company_hash: Int?;
    company_creator_address: Address?; // profile_address owner; company_creator
    company_voting_creator_address: Address?; // profile_address owner; creator voting
    comment_tons: Int?;
    expel_candidate_address: Address?;
    gas_consumption: Int?;
    max_voting_duration: Int?;
    max_voting_duration_expel: Int?;
    min_tons_for_storage: Int?;
    list_voters: map<Address, Bool>;
    new_coowner: Address?;
    new_coowner_check_data: UserCheckData?;
    new_description: String?;
    new_logo: String?;
    new_title: String?;
    signature: Slice;
    voting_type: String;
    version_contract_company: Int?;
}

message ConfirmCompanyVotingCoownerCandidate{
    company_voting_address: Address;
}

message RefuseCompanyVotingCoownerCandidate{
    company_voting_address: Address;
}

message HandleSuccessVoting{
    coowner_candidate_address: Address?;
    expel_candidate_address: Address?;
    new_company_title: String?;
    new_company_description: String?;
    new_company_logo: String?;
    company_voting_address: Address;
    company_voting_type: String;
    company_address: Address;
    version_contract_company_voting: Int?;
}

message BurnCompanyVoting{}

message SendPositiveVote{
    company_voting_address: Address;
}

message SendNegativeVote{
    company_voting_address: Address;
}

message FinishCompanyVoting{
    company_voting_address: Address;
}

message TerminateCompanyVoting{
    company_voting_address: Address;
}

message ChangeCompanyData{
    company_address: Address;
    new_company_title: String?;
    new_company_description: String?;
    new_company_logo: String?;
}

// COMPANY VOTING END
