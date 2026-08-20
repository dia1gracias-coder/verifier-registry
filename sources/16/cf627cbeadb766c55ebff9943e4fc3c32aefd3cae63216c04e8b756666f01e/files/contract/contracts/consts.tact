const COMMENT_MSG_VAL: Int = ton("0.02");

// MANAGER CONTRACT
const TERMINATE_MANAGER_CONTRACT_REFUND: Int = ton("0.1");
const MIN_TONS_FOR_STORAGE_MC: Int = ton("0.3");
const COMMENT_TONS_MC: Int = ton("0.02");

const MAX_DURATION_MC: Int = 60*60*24*184;
const MIN_DURATION_MC: Int = 60*60*24;


// EMPLOYEE CONTRACT
const MIN_TONS_FOR_STORAGE_EC: Int = ton("0.1");
const TERMINATE_MANAGER_CONTRACT_VAL: Int = ton("0.04");
const COMMENT_TONS_EC: Int = ton("0.02");

const MAX_DURATION_EC: Int = 60*60*24*184;
const MIN_DURATION_EC: Int = 60*60*24;


// HR
const MIN_TONS_FOR_STORAGE_HR: Int = ton("0.1");
const CREATED_MESSAGE_VAL_HR: Int = ton("0.02");
const TERMINATED_MESSAGE_VAL_HR: Int = ton("0.02");


// CEO
const MIN_TONS_FOR_STORAGE_CEO: Int = ton("0.1");
const CREATED_MESSAGE_VAL_CEO: Int = ton("0.01");
const TERMINATED_MESSAGE_VAL_CEO: Int = ton("0.02");
const CONFIRMATION_MESSAGE_VAL_TO_COMPANY_CEO: Int = ton("0.15");
const CONFIRM_TERMINATION_MESSAGE_VAL_TO_COMPANY_CEO: Int = ton("0.05");


// COMPANY VOTING
const MIN_TONS_FOR_STORAGE_CV: Int = ton("0.1");
const COMMENT_TONS_CV: Int = ton("0.2");

const MAX_VOTING_DURATION_EXPEL: Int = 60*60*24*365; // 1 year
const MAX_VOTING_DURATION: Int = 60*60*24*30; // 1 month

const COMPANY_VOTING_COST: Int = ton("0.2");

const ADD_COOWNER: String = "add_coowner";
const EXPEL_COOWNER: String = "expel_coowner";
const CHANGE_COMPANY_TITLE: String = "change_company_title";
const CHANGE_COMPANY_DESCRIPTION: String = "change_company_description";
const CHANGE_COMPANY_LOGO: String = "change_company_logo";
