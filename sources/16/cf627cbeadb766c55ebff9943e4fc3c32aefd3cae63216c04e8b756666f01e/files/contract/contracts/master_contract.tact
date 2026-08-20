import "@stdlib/deploy";

import "./traits/upgradable_new.tact";
import "./traits/gas_consumption.tact";
import "./traits/top_up_balance.tact";
import "./traits/withdraw.tact";

import "./consts.tact";
import "./messages.tact";

struct DeployEmployee{
    msgValue: Int;
    company_address: Address;
    creator_address: Address;
    date_start: Int;
    description: String?;
    duration: Int;
    employee_address: Address;
    employee_check_data: UserCheckData;
    hours: String;
    signature: Slice;
    schedule: String;
    tag: String;
}

struct DurationStruct{
    max_employee_contract_duration: Int;
    min_employee_contract_duration: Int;
    max_employee_start_period: Int;
    max_manager_start_period: Int;
    max_employee_contract_prolongation_duration: Int;
    min_employee_contract_prolongation_duration: Int;
    max_manager_contract_duration: Int;
    min_manager_contract_duration: Int;
    max_voting_duration: Int;
    max_voting_duration_expel: Int;
}

struct DeployManager{
    msgValue: Int;
    company_address: Address;
    creator_address: Address?; // user profile
    date_start: Int as uint32;
    description: String?;
    duration: Int as uint32;
    employee_manager: Address;
    employee_manager_contract: Address;
    employee_subordinate: Address;
    employee_subordinate_contract: Address;
    signature: Slice;
    tag_manager: String?;
    tag_subordinate: String?;
}

struct CheckManagerStruct{
    company_address: Address;
    data: CreateManagerContractStruct;
}

contract MasterContract with Deployable, Upgradable, GasConsumption, TopUpBalance, Withdrawal {
    admin: Address?;
    index: Int; // ToDo TEMP??
    publicKey: Int? as uint256;
    _version: Int as uint32 = 0;
    review_period_leaving: Int = 60 * 60 * 24 * 14; // ToDo const

    type: String = "master";

    gas_consumption: Int as coins = ton("0.02");
    min_tons_for_storage: Int as coins = ton("0.1");
    subcontract_gas_consumption: Int as coins = ton("0.01");
    deploy_gas_consumption: Int as coins = ton("0.03");

    comment_msg_val: Int as coins = COMMENT_MSG_VAL;

    company_creation_cost: Int as coins = ton("0.1");

    ceo_creation_cost: Int as coins = ton("0.1");

    employee_confirmation_cost: Int as coins = ton("0.1");
    employee_creation_cost: Int as coins = ton("0.1");
    employee_termination_cost: Int as coins = ton("0.1");
    employee_termination_manager_cost: Int as coins = ton("0.04");
    employee_prolongation_cost: Int as coins = ton("0.1");

    employee_grade_cost: Int as coins = ton("0.1");
    company_grade_cost: Int as coins = ton("0.1");

    hr_creation_cost: Int as coins = ton("0.1");
    hr_termination_cost: Int as coins = ton("0.1");
    min_tons_for_storage_hr: Int as coins = MIN_TONS_FOR_STORAGE_HR;
    created_comment_msg_val_hr: Int as coins = CREATED_MESSAGE_VAL_HR;
    terminated_comment_msg_val_hr: Int as coins = TERMINATED_MESSAGE_VAL_HR;

    manager_confirmation_cost: Int as coins = ton("0.1");
    manager_creation_cost: Int as coins = ton("0.1");
    manager_termination_cost: Int as coins = ton("0.1");
    manager_grade_cost: Int as coins = ton("0.1");

    company_voting_cost: Int as coins = COMPANY_VOTING_COST;
    min_tons_for_storage_company_voting: Int as coins = MIN_TONS_FOR_STORAGE_CV;
    comment_msg_val_company_voting: Int = COMMENT_TONS_CV;

    user_profile_creation_cost: Int as coins = ton("0.1");

    user_profile_code: Cell?;
    company_code: Cell?;
    ceo_code: Cell?;
    hr_code: Cell?;
    employee_contract_code: Cell?;
    manager_contract_code: Cell?;
    company_voting_code: Cell?;

    version_contract_CEO: map<Int, ContractVersionsStruct>;
    version_contract_user_profile: map<Int, ContractVersionsStruct>;
    version_contract_company: map<Int, ContractVersionsStruct>;
    version_contract_HR: map<Int, ContractVersionsStruct>;
    version_contract_employee: map<Int, ContractVersionsStruct>;
    version_contract_manager: map<Int, ContractVersionsStruct>;
    version_contract_company_voting: map<Int, ContractVersionsStruct>;

    duration_data: DurationStruct = DurationStruct{
        max_employee_contract_duration: MAX_DURATION_EC,
        min_employee_contract_duration: MIN_DURATION_EC,

        max_employee_contract_prolongation_duration: MAX_DURATION_EC,
        min_employee_contract_prolongation_duration: MIN_DURATION_EC,

        max_manager_contract_duration: MAX_DURATION_MC,
        min_manager_contract_duration: MIN_DURATION_MC,

        max_employee_start_period: 60*60*24*90,
        max_manager_start_period: 60*60*24*90,

        max_voting_duration: MAX_VOTING_DURATION,
        max_voting_duration_expel: MAX_VOTING_DURATION_EXPEL
    };

    ceo_termination_cost: Int as coins = ton("0.2");
    terminate_val: Int as coins = TERMINATED_MESSAGE_VAL_CEO; // ToDo getter ++; setter
    confirm_terminate_val: Int as coins = CONFIRM_TERMINATION_MESSAGE_VAL_TO_COMPANY_CEO; // ToDo getter ++; setter
    confirmation_message_from_ceo_to_company_val: Int as coins = CONFIRMATION_MESSAGE_VAL_TO_COMPANY_CEO;

    commission_creation_employee: Int as coins = ton("0");
    commission_creation_manager: Int as coins = ton("0");
    commission_prolongation_employee: Int as coins = ton("0");

    init(admin: Address, index: Int) {
        self.admin = admin;
        self.index = index;
    }

    receive(str: String) {}

    override fun validatePermissions(ctx: Context, amount: Int) {
        require(sender() == self.admin!!, "validatePermissions: sender is not a contract admin");
    }

    //============================ USER PROFILE ============================
    receive (msg: CreateUserProfileContract) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        let userProfileAddress: Address = self.userProfileAddress(ctx.sender, msg.hash, -1);
        let ok: Bool = self.checkSignature(userProfileAddress.asSlice(), msg.signature);

        require(ok, "CreateUserProfileContract: invalid signature");
        require(msgValue >= self.user_profile_creation_cost, "CreateUserProfileContract: not enough funds for user profile creation");

        msgValue -= self.deploy_gas_consumption;

        msg.creator_address = ctx.sender;
        msg.admin_address = self.admin;
        msg.comment_msg_val = self.comment_msg_val;
        msg.gas_consumption = self.subcontract_gas_consumption;

        let user_profile_init: StateInit = self.userProfileInit(msg.creator_address!!, msg.hash);

        deploy(DeployParameters{
            value: msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: msg.toCell(),
            init: user_profile_init
        });
    }

    fun userProfileInit(creator_address: Address, hash: Int): StateInit {
        let initData: UserProfileInitData = UserProfileInitData{
            lazy_bit: false,
            master_contract: myAddress(),
            creator_address: creator_address,
            hash: hash
        };

        return StateInit{
            code: self.user_profile_code!!,
            data: initData.toCell()
        }
    }

    get fun userProfileAddress(creator_address: Address, hash:Int, version: Int): Address {
        let version_contract_user_profile: ContractVersionsStruct? = self.version_contract_user_profile.get(version);
        let initCode: StateInit = self.userProfileInit(creator_address, hash);

        if (version_contract_user_profile == null){
            return contractAddress(initCode);
        } else {
            return contractAddressFromHash(version_contract_user_profile!!.code_hash, version_contract_user_profile!!.code_depth, initCode.data)
        }
    }

    receive (msg: SetUserProfileCode) {
        require(sender() == self.admin!!, "SetUserProfileCode: sender is not a contract admin");
        self.user_profile_code = msg.user_profile_code;
    }
    //============================ USER PROFILE END ============================

    //============================ COMPANY ============================
    receive (msg: CreateCompanyContract) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        let companyAddress: Address = self.companyAddress(ctx.sender, msg.company_hash, -1);
        let ok: Bool = self.checkSignature(companyAddress.asSlice(), msg.signature);

        require(ok, "CreateCompanyContract: invalid signature");
        require(ctx.sender == self.userProfileAddress(msg.user_profile_creator!! ,msg.user_profile_hash!!, msg.version_contract_user_profile!!), "CreateCompanyContract: sender is not user profile contract");
        require(msgValue >= self.company_creation_cost, "CreateCompanyContract: not enough funds for company creation");

        msgValue -= self.deploy_gas_consumption;

        let company_init: StateInit = self.companyInit(msg.creator_address!!, msg.company_hash);

        msg.comment_msg_val = self.comment_msg_val;
        msg.gas_consumption = self.subcontract_gas_consumption;
        msg.creator_address = ctx.sender;
        msg.admin_address = self.admin;

        deploy(DeployParameters{
            value: msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: msg.toCell(),
            init: company_init
        });
    }

    fun companyInit(creator_address: Address, hash: Int): StateInit {
        let initData: CompanyInitData = CompanyInitData{
            lazy_bit: false,
            master_contract: myAddress(),
            creator_address: creator_address,
            hash: hash
        };

        return StateInit{
            code: self.company_code!!,
            data: initData.toCell()
        }
    }

    get fun companyAddress(creator_address: Address, hash: Int, version: Int): Address {
        let version_contract_company: ContractVersionsStruct? = self.version_contract_company.get(version);
        let initCode: StateInit = self.companyInit(creator_address, hash);

        if (version_contract_company == null){
            return contractAddress(initCode);
        } else {
            return contractAddressFromHash(version_contract_company!!.code_hash, version_contract_company!!.code_depth, initCode.data)
        }
    }

    receive (msg: SetCompanyCode) {
        require(sender() == self.admin!!, "SetCompanyCode: sender is not a contract admin");
        self.company_code = msg.company_code;
    }
    //============================ COMPANY END ============================

    //============================== CEO ==============================
    receive(msg: CreateCEOContract) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        let ceoAddress: Address = self.ceoAddress(msg.ceo_user_address, msg.company_address, msg.uid, -1);
        let ok: Bool = self.checkSignature(ceoAddress.asSlice(), msg.signature);

        require(ok, "CreateCEOContract: invalid signature");
        require(msgValue >= self.ceo_creation_cost, "CreateCEOContract: not enough funds for CEO creation");
        require (ctx.sender == self.companyAddress(msg.company_creator_address!!, msg.company_hash!!, msg.version_contract_company!!), "CreateCEOContract: sender is not company contract");
        require(
            msg.ceo_user_address == self.userProfileAddress(msg.ceo_user_check_data.creator_address, msg.ceo_user_check_data.hash, msg.ceo_user_check_data.version_contract_user_profile),
            "CreateCEOContract: ceo_user_address is incorrect"
        );

        msgValue -= self.deploy_gas_consumption;

        let ceo_init: StateInit = self.ceoInit(msg.ceo_user_address, msg.company_address, msg.uid);

        msg.admin_address = self.admin;
        msg.terminate_msg_val = self.terminate_val;
        msg.confirm_terminate_msg_val = self.confirm_terminate_val;
        msg.confirmation_message_to_company_val = self.confirmation_message_from_ceo_to_company_val;
        msg.comment_msg_val = self.comment_msg_val;
        msg.gas_consumption = self.subcontract_gas_consumption;
        msg.review_period_leaving = self.review_period_leaving;

        deploy(DeployParameters{
            value: msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: msg.toCell(),
            init: ceo_init
        });
    }

    receive(msg: SetCEOAddress) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(ctx.sender == msg.ceo_contract_address, "SetCEOAddress: incorrect ceo_contract_address");
        require(ctx.sender == self.ceoAddress(msg.ceo_user_address, msg.company_address, msg.uid, msg.version_contract_CEO!!), "SetCEOAddress: sender is not CEO address");

        msgValue -= self.gas_consumption;

        message(MessageParameters{
            to: msg.company_address,
            value: msgValue,
            bounce: false,
            body: msg.toCell(),
        });
    }

    fun ceoInit(ceo_user_address: Address, company_address: Address, uid: String): StateInit {
        let initData: CEOInitData = CEOInitData{
            lazy_bit: false,
            master_contract: myAddress(),
            ceo_user_address: ceo_user_address,
            company_address: company_address,
            uid: uid
        };

        return StateInit{
            code: self.ceo_code!!,
            data: initData.toCell()
        }
    }

    get fun ceoAddress(ceo_user_address: Address, company_address: Address, uid: String, version: Int): Address {
        let version_contract_CEO_data: ContractVersionsStruct? = self.version_contract_CEO.get(version);
        let initCode: StateInit = self.ceoInit(ceo_user_address, company_address, uid);

        if (version_contract_CEO_data == null){
            return contractAddress(initCode);
        } else {
            return contractAddressFromHash(version_contract_CEO_data!!.code_hash, version_contract_CEO_data!!.code_depth, initCode.data)
        }
    }

    receive (msg: SetCEOCode) {
        require(sender() == self.admin!!, "SetCEOCode: sender is not a contract admin");
        self.ceo_code = msg.ceo_code;
    }
    //============================ CEO END ============================

    //================================ HR ================================
    receive(msg: CreateHRContractOwner) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        let calculated_employee_contract: Address = self.employeeAddress(msg.hr_user_address, msg.company_address, msg.tag!!, msg.employee_date_start!!, msg.version_contract_employee!!);

        require(msgValue >= self.hr_creation_cost, "CreateHRContractOwner: not enough funds for HR creation");
        require(msg.employee_contract == calculated_employee_contract, "CreateHRContractOwner: employee_contract is invalid");
        // ceo_user_address must be employee
        require(msg.employee_contract == ctx.sender, "CreateHRContractOwner: sender is not equal employee contract");

        msgValue -= self.deploy_gas_consumption;

        self.createHRContract(
            msg.hr_user_address,
            msg.company_address,
            msg.creator_address!!,
            msg.employee_contract,
            msg.signature,
            msgValue
        );
    }

    receive(msg: CreateHRContractCEO) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        // ToDo check employee;
        if (msg.from_employee!!) {
            let calculated_employee_contract: Address = self.employeeAddress(msg.hr_user_address, msg.company_address!!, msg.tag!!, msg.employee_date_start!!, msg.version_contract_employee!!);
            require(msg.employee_contract == calculated_employee_contract, "CreateHRContractCEO: employee_contract is invalid");
            // hr_user_address must be employee
            require(msg.employee_contract == ctx.sender, "CreateHRContractCEO: sender is not employee contract");

            msgValue -= self.deploy_gas_consumption;

            self.createHRContract(
                msg.hr_user_address,
                msg.company_address!!,
                msg.creator_address!!,
                msg.employee_contract,
                msg.signature,
                msgValue
            );
        } else if (msg.from_CEO!!) {
            require(msgValue >= self.hr_creation_cost, "CreateHRContractCEO: not enough funds for HR creation");
            require(ctx.sender == self.ceoAddress(msg.creator_address!!, msg.company_address!!, msg.uid!!, msg.version_contract_CEO!!), "CreateHRContractCEO: sender is not CEO address");
            // ToDo send CEO to employee
            msgValue -= self.gas_consumption;

            message(MessageParameters{
                to: msg.employee_contract,
                value: msgValue,
                body: msg.toCell(),
            });
        }
    }

    fun createHRContract(hr_user_address: Address, company_address: Address, creator_address: Address, employee_contract: Address, signature: Slice, msgValue: Int){
        let hrAddress: Address = self.hrAddress(hr_user_address, company_address, -1);
        let ok: Bool = self.checkSignature(hrAddress.asSlice(), signature);

        require(ok, "createHRContract: invalid signature");

        let hr_init: StateInit = self.hrInit(hr_user_address, company_address);

        let createHRmsg = CreateHRContract{
            admin_address: self.admin,
            creator_address: creator_address,
            employee_contract: employee_contract,
            gas_consumption: self.subcontract_gas_consumption,
            min_tons_for_storage: self.min_tons_for_storage_hr,
            created_msg_val: self.created_comment_msg_val_hr,
            signature: signature,
            terminated_msg_val: self.terminated_comment_msg_val_hr,
        };

        deploy(DeployParameters{
            value: msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: createHRmsg.toCell(),
            init: hr_init
        });
    }

    fun hrInit(hr_user_address: Address, company_address: Address): StateInit {
        let initData: HRInitData = HRInitData{
            lazy_bit: false,
            master_contract: myAddress(),
            hr_user_address: hr_user_address,
            company_address: company_address,
        };

        return StateInit{
            code: self.hr_code!!,
            data: initData.toCell()
        }
    }

    get fun hrAddress(hr_user_address: Address, company_address: Address, version: Int): Address {
        let version_contract_hr: ContractVersionsStruct? = self.version_contract_HR.get(version);
        let initCode: StateInit = self.hrInit(hr_user_address, company_address);

        if (version_contract_hr == null){
            return contractAddress(initCode);
        } else {
            return contractAddressFromHash(version_contract_hr!!.code_hash, version_contract_hr!!.code_depth, initCode.data)
        }
    }

    receive (msg: SetHRCode) {
        require(sender() == self.admin!!, "SetHRCode: sender is not a contract admin");
        self.hr_code = msg.hr_code;
    }
    //================================ HR END ================================

    //================================ EMPLOYEE ================================
    receive(msg: CreateEmployeeContractOwner) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.employee_creation_cost, "CreateEmployeeContractOwner: not enough funds for employee creation");
        require(msg.company_address == self.companyAddress(msg.company_creator_address!!, msg.company_hash!!, msg.version_contract_company!!), "CreateEmployeeContractOwner: sender is not msg company");
        require(ctx.sender == msg.company_address, "CreateEmployeeContractOwner: sender is not equal company address");

        msgValue -= self.deploy_gas_consumption;

        self.deployEmployee(DeployEmployee{
            msgValue: msgValue,
            company_address: msg.company_address,
            creator_address: msg.creator_address!!,
            date_start: msg.date_start,
            description: msg.description,
            duration: msg.duration,
            employee_address: msg.employee_address,
            employee_check_data: msg.employee_check_data,
            hours: msg.hours,
            schedule: msg.schedule,
            signature: msg.signature,
            tag: msg.tag
        });
    }

    receive(msg: CreateEmployeeContractCEO) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.employee_creation_cost, "CreateEmployeeContractCEO: not enough funds for employee creation");
        require(ctx.sender == self.ceoAddress(msg.creator_address!!, msg.company_address!!, msg.uid!!, msg.version_contract_CEO!!), "CreateEmployeeContractCEO: sender is not CEO address");

        msgValue -= self.deploy_gas_consumption;

        self.deployEmployee(DeployEmployee{
            msgValue: msgValue,
            company_address: msg.company_address!!,
            creator_address: msg.creator_address!!,
            date_start: msg.date_start,
            description: msg.description,
            duration: msg.duration,
            employee_address: msg.employee_address,
            employee_check_data: msg.employee_check_data,
            hours: msg.hours,
            schedule: msg.schedule,
            signature: msg.signature,
            tag: msg.tag
        });
    }

    receive(msg: CreateEmployeeContractHR) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        if (msg.from_company) {
            require(msgValue >= self.employee_creation_cost, "CreateEmployeeContractHR: not enough funds for employee creation");
            require(ctx.sender == self.companyAddress(msg.company_creator_address!!, msg.company_hash!!, msg.version_contract_company!!), "CreateEmployeeContractHR: sender is not company contract address");

            msgValue -= self.deploy_gas_consumption;

            self.deployEmployee(DeployEmployee{
                msgValue: msgValue,
                company_address: msg.company_address!!,
                creator_address: msg.creator_address!!,
                date_start: msg.date_start,
                description: msg.description,
                duration: msg.duration,
                employee_address: msg.employee_address,
                employee_check_data: msg.employee_check_data,
                hours: msg.hours,
                schedule: msg.schedule,
                signature: msg.signature,
                tag: msg.tag
            });
        } else {
            require(ctx.sender == self.hrAddress(msg.creator_address!!, msg.company_address!!, msg.version_contract_hr!!), "CreateEmployeeContractHR: sender is not HR contract address");

            msgValue -= self.gas_consumption;

            message(MessageParameters{
                to: msg.company_address!!,
                value: msgValue,
                body: msg.toCell(),
            });
        }

    }

    receive(msg: TerminateEmployeeContractHR) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.employee_termination_cost, "TerminateEmployeeContractHR: not enough funds for employee termination");
        require(ctx.sender == self.hrAddress(msg.initiator_address!!, msg.company_address!!, msg.version_contract_hr!!), "TerminateEmployeeContractHR: sender is not HR contract");

        msgValue -= self.gas_consumption;

        let terminateEmployeeMsg = TerminateEmployeeContract{
            initiator_address: msg.initiator_address!!,
            is_HR: true,
            company_address: msg.company_address!!,
            related_manager_contracts: msg.related_manager_contracts
        };

        message(MessageParameters{
            to: msg.employee_contract_address,
            value: msgValue,
            body: terminateEmployeeMsg.toCell(),
        });
    }

    receive(msg: ProlongateEmployeeContractOwner) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.employee_prolongation_cost, "ProlongateEmployeeContractOwner: not enough funds for employee contract prolongation");
        require(msg.company_address == self.companyAddress(msg.company_creator!!, msg.company_hash!!, msg.version_contract_company!!), "ProlongateEmployeeContractOwner: sender is not msg company");
        require(ctx.sender == msg.company_address, "ProlongateEmployeeContractOwner: sender is not equal company address");

        msgValue -= self.gas_consumption;

        self.prolongateEmployeeContract(
            msgValue,
            msg.data.employee_contract_address,
            msg.company_address,
            msg.data.duration,
            self.review_period_leaving)
        }

    receive(msg: ProlongateEmployeeContractCEO) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.employee_prolongation_cost, "ProlongateEmployeeContractCEO: not enough funds for employee contract prolongation");
        require(
            msg.ceo_contract_address == self.ceoAddress(msg.initiator_address!!, msg.company_address!!, msg.uid!!, msg.version_contract_CEO!!),
            "ProlongateEmployeeContractCEO: sender is not msg CEO"
        );
        require(ctx.sender == msg.ceo_contract_address, "ProlongateEmployeeContractCEO: sender is not equal ceo address");

        msgValue -= self.gas_consumption;

        self.prolongateEmployeeContract(
            msgValue,
            msg.data.employee_contract_address,
            msg.company_address!!,
            msg.data.duration,
            self.review_period_leaving)
        }

    receive(msg: ProlongateEmployeeContractHR) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        msgValue -= self.gas_consumption;

        if (msg.from_company) {
            require(msgValue >= self.employee_prolongation_cost, "ProlongateEmployeeContractHR: not enough funds for employee contract prolongation");
            require(msg.company_address == self.companyAddress(msg.company_creator!!, msg.company_hash!!, msg.version_contract_company!!), "ProlongateEmployeeContractHR: company_address is incorrect");
            require(ctx.sender == msg.company_address, "ProlongateEmployeeContractHR: sender is not equal hr address");

        self.prolongateEmployeeContract(
            msgValue,
            msg.data.employee_contract_address,
            msg.company_address!!,
            msg.data.duration,
            self.review_period_leaving
            )
        } else {
            require(msg.hr_contract_address == self.hrAddress(msg.initiator_address!!, msg.company_address!!, msg.version_contract_hr!!), "ProlongateEmployeeContractHR: sender is not msg HR");
            require(ctx.sender == msg.hr_contract_address, "ProlongateEmployeeContractHR: sender is not equal hr address");

            message(MessageParameters{
                to: msg.company_address!!,
                value: msgValue,
                body: msg.toCell(),
            });
        }
    }

    // ToDo delete and send ConfirmProlongationEmployeeContract from user profile to employee contract
    receive(msg: ConfirmProlongationEmployeeContract) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.employee_prolongation_cost, "ConfirmProlongationEmployeeContract: not enough funds for employee contract prolongation");
        require(ctx.sender == msg.initiator_address!!, "ConfirmProlongationEmployeeContract: invalid initiator_address");
        require(ctx.sender == self.userProfileAddress(msg.user_profile_creator!!, msg.user_hash!!, msg.version_contract_user_profile!!), "ConfirmProlongationEmployeeContract: sender is not user contract");

//         msgValue -= self.gas_consumption;

        msg.review_period_leaving = self.review_period_leaving;

        message(MessageParameters{
            to: msg.employee_contract_address,
            value: self.gas_consumption * 2,
            mode: SendPayGasSeparately,
            body: msg.toCell(),
        });
    }

    fun employeeInit(employee_address: Address, company_address: Address, tag: String, date_start: Int): StateInit {
        let initData: EmployeeInitData = EmployeeInitData{
            lazy_bit: false,
            master_contract: myAddress(),
            employee_address: employee_address,
            company_address: company_address,
            tag: tag,
            date_start: date_start
        };

        return StateInit{
            code: self.employee_contract_code!!,
            data: initData.toCell()
        }
    }

    get fun employeeAddress(employee_address: Address, company_address: Address, tag: String, date_start: Int, version: Int): Address {
        let version_contract_employee: ContractVersionsStruct? = self.version_contract_employee.get(version);
        let initCode: StateInit = self.employeeInit(employee_address, company_address, tag, date_start);

        if (version_contract_employee == null){
            return contractAddress(initCode);
        } else {
            return contractAddressFromHash(version_contract_employee!!.code_hash, version_contract_employee!!.code_depth, initCode.data)
        }
    }

    receive (msg: SetEmployeeContractCode) {
        require(sender() == self.admin!!, "SetEmployeeContractCode: sender is not a contract admin");
        self.employee_contract_code = msg.employee_contract_code;
    }

    fun deployEmployee(data: DeployEmployee) {
        let employeeAddress: Address = self.employeeAddress(data.employee_address, data.company_address, data.tag, data.date_start, -1);
        let ok: Bool = self.checkSignature(employeeAddress.asSlice(), data.signature);

        require(ok, "deployEmployee: invalid signature");

        require(
            data.employee_address == self.userProfileAddress(data.employee_check_data.creator_address, data.employee_check_data.hash, data.employee_check_data.version_contract_user_profile),
            "deployEmployee: employee_address is incorrect"
        );

        require(data.date_start <= now() + self.duration_data.max_employee_start_period, "deployEmployee: incorrect date_start period");

        let duration: Int = data.duration;
        require(
            duration >= self.duration_data.min_employee_contract_duration && duration <= self.duration_data.max_employee_contract_duration,
            "deployEmployee: incorrect duration"
        );

        require(data.msgValue > self.commission_creation_employee,"deployEmployee: not enough value for commission");

        let employee_init: StateInit = self.employeeInit(data.employee_address, data.company_address, data.tag, data.date_start);

        data.msgValue = data.msgValue - self.commission_creation_employee;

        let CreateEmployeeMsg = CreateEmployeeContract{
            admin_address: self.admin,
            company_address:data.company_address,
            creator_address: data.creator_address,
            comment_msg_val: self.comment_msg_val,
            description: data.description,
            duration: data.duration,
            gas_consumption: self.subcontract_gas_consumption,
            review_period_leaving: self.review_period_leaving,
            hours: data.hours,
            schedule: data.schedule,
            termination_manager_cost: self.employee_termination_manager_cost,
            signature: data.signature
        };

        deploy(DeployParameters{
            value: data.msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: CreateEmployeeMsg.toCell(),
            init: employee_init
        });
    }

    fun prolongateEmployeeContract(msgValue: Int, employee_contract_address: Address, company_address: Address, duration: Int, review_period_leaving: Int){
        require(
            duration >= self.duration_data.min_employee_contract_prolongation_duration && duration <= self.duration_data.max_employee_contract_prolongation_duration,
            "prolongateEmployeeContract: incorrect duration"
        );
        require(
            msgValue > self.commission_prolongation_employee,
            "prolongateEmployeeContract: not enough value for commission"
        );

        msgValue -= self.commission_prolongation_employee;

        let employeeProlongationMsg = ProlongateEmployeeContract{
            company_address: company_address,
            duration: duration,
            review_period_leaving: review_period_leaving
        };

        message(MessageParameters{
            to: employee_contract_address,
            value: msgValue,
            body: employeeProlongationMsg.toCell(),
        });
    }

    //================================ EMPLOYEE END ================================

    //=================================== MANAGER ===================================
    receive(msg: CreateManagerContractOwner) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.manager_creation_cost, "CreateManagerContractOwner: not enough funds for manager creation");
        require(msg.company_address == self.companyAddress(msg.data.company_creator!!, msg.data.company_hash!!, msg.version_contract_company!!), "CreateManagerContractOwner: sender is not msg company");
        require(ctx.sender == msg.company_address, "CreateManagerContractOwner: sender is not equal company address");

        msgValue -= self.gas_consumption;

        let data: CheckManagerStruct = CheckManagerStruct{
            company_address: msg.company_address,
            data: msg.data
        };

        // ToDo use msg instead data
        let resultMsg: CheckManager = self.createCheckManagerMessage(data);

        message(MessageParameters{
            to: resultMsg.data.employee_manager_contract,
            value: msgValue,
            body: resultMsg.toCell(),
        });
    }

    receive(msg: CreateManagerContractCEO) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.manager_creation_cost, "CreateManagerContractCEO: not enough funds for manager creation");
        require(ctx.sender == self.ceoAddress(msg.data.creator_address!!, msg.company_address!!, msg.uid!!, msg.version_contract_CEO!!), "CreateManagerContractCEO: sender is not equal CEO address");

        msgValue -= self.gas_consumption;

        let data: CheckManagerStruct = CheckManagerStruct{
            company_address: msg.company_address!!,
            data: msg.data
        };

        // ToDo use msg instead data
        let resultMsg: CheckManager = self.createCheckManagerMessage(data);

        message(MessageParameters{
            to: resultMsg.data.employee_manager_contract,
            value: msgValue,
            body: resultMsg.toCell(),
        });
    }

    receive(msg: CreateManagerContractHR) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        msgValue -= self.gas_consumption;

        if (msg.from_company) {
            require(msgValue >= self.manager_creation_cost, "CreateManagerContractHR: not enough funds for manager creation");
            require(ctx.sender == self.companyAddress(msg.data.company_creator!!, msg.data.company_hash!!, msg.version_contract_company!!), "CreateEmployeeContractHR: sender is not company contract address");

            let data: CheckManagerStruct = CheckManagerStruct{ // // ToDo use CreateManagerContractStruct
                company_address: msg.company_address!!,
                data: msg.data
            };

            // ToDo use msg instead data
            let resultMsg: CheckManager = self.createCheckManagerMessage(data);

            message(MessageParameters{
                to: resultMsg.data.employee_manager_contract,
                value: msgValue,
                body: resultMsg.toCell(),
            });
        } else {
            require(ctx.sender == self.hrAddress(msg.data.creator_address!!, msg.company_address!!, msg.version_contract_hr!!), "CreateManagerContractHR: sender is not equal HR address");

            message(MessageParameters{
                to: msg.company_address!!,
                value: msgValue,
                body: msg.toCell(),
            });
        }
    }

    receive(msg: CreateManagerContractManager) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.manager_creation_cost, "CreateManagerContractManager: not enough funds for manager creation");
        require(ctx.sender == msg.data.employee_manager, "CreateManagerContractManager: employee_manager is incorrect");
        require(ctx.sender == self.userProfileAddress(msg.user_creator_address!!,msg.user_hash!!, msg.version_contract_user_profile!!), "CreateManagerContractManager: sender is not one user contracts");

        msgValue -= self.gas_consumption;

        let data: CheckManagerStruct = CheckManagerStruct{
            company_address: msg.company_address,
            data: msg.data
        };

        // ToDo use msg instead data
        let resultMsg: CheckManager = self.createCheckManagerMessage(data);

        message(MessageParameters{
            to: resultMsg.data.employee_manager_contract,
            value: msgValue,
            body: resultMsg.toCell(),
        });
    }

    receive(msg: CreateManagerContractSubordinate) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.manager_creation_cost, "CreateManagerContractSubordinate: not enough funds for manager creation");
        require(ctx.sender == msg.data.employee_subordinate, "CreateManagerContractSubordinate: employee_subordinate is incorrect");
        require(ctx.sender == self.userProfileAddress(msg.user_creator_address!!,msg.user_hash!!, msg.version_contract_user_profile!!), "CreateManagerContractSubordinate: sender is not one user contracts");

        msgValue -= self.gas_consumption;

        let data: CheckManagerStruct = CheckManagerStruct{
            company_address: msg.company_address,
            data: msg.data
        };

        // ToDo use msg instead data
        let resultMsg: CheckManager = self.createCheckManagerMessage(data);

        message(MessageParameters{
            to: resultMsg.data.employee_manager_contract,
            value: msgValue,
            body: resultMsg.toCell(),
        });
    }

    receive(msg: CheckManager) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        if (msg.data.employee_manager_is_CEO){
            require(msg.data.employee_manager_contract == self.ceoAddress(msg.data.employee_manager, msg.company_address, msg.uid!!, msg.version_contract_CEO!!), "CheckManager: invalid employee_manager_contract for CEO");
        } else {
            require(msg.data.employee_manager_contract == self.employeeAddress(msg.data.employee_manager, msg.company_address, msg.data.tag_manager!!, msg.employee_date_start!!, msg.version_contract_employee!!), "CheckManager: invalid employee_manager_contract");
        }
        require(ctx.sender == msg.data.employee_manager_contract, "CheckManager: sender is not msg employee_manager_contract");

        msgValue -= self.gas_consumption;

        let data: CheckManagerStruct = CheckManagerStruct{
            company_address: msg.company_address,
            data: msg.data
        };

        let resultMsg: CheckSubordinate = self.createCheckSubordinateMessage(data);

        message(MessageParameters{
            to: resultMsg.data.employee_subordinate_contract,
            value: msgValue,
            body: resultMsg.toCell(),
        });
    }

    receive(msg: CheckSubordinate) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msg.data.employee_subordinate_contract == self.employeeAddress(msg.data.employee_subordinate, msg.company_address, msg.data.tag_subordinate!!, msg.employee_date_start!!, msg.version_contract_employee!!), "CheckSubordinate: invalid employee_subordinate_contract");
        require(ctx.sender == msg.data.employee_subordinate_contract, "CheckSubordinate: sender is not msg employee_subordinate_contract");

        msgValue -= self.deploy_gas_consumption;

        self.deployManager(DeployManager {
            msgValue: msgValue,
            company_address: msg.company_address,
            creator_address: msg.data.creator_address,
            date_start: msg.data.date_start,
            description: msg.data.description,
            duration: msg.data.duration,
            employee_manager: msg.data.employee_manager,
            employee_manager_contract: msg.data.employee_manager_contract,
            employee_subordinate: msg.data.employee_subordinate,
            employee_subordinate_contract: msg.data.employee_subordinate_contract,
            signature: msg.data.signature,
            tag_manager: msg.data.tag_manager,
            tag_subordinate: msg.data.tag_subordinate,
        })
    }

    receive(msg: TerminateManagerContractHR) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= self.manager_termination_cost, "TerminateManagerContractHR: not enough funds for manager termination");
        require(msg.hr_contract_address == self.hrAddress(msg.data.initiator_address!!, msg.data.company_address, msg.version_contract_hr!!), "TerminateManagerContractHR: invalid hr_contract_address");
        require(ctx.sender == msg.hr_contract_address, "TerminateManagerContractHR: sender is not equal HR address");

        msgValue -= self.gas_consumption;

        let resultMsg: TerminateManagerContractCompany = TerminateManagerContractCompany{
            initiator_address: msg.data.initiator_address!!,
            company_address: msg.data.company_address,
        };

        message(MessageParameters{
            to: msg.data.manager_contract_address,
            value: msgValue,
            body: resultMsg.toCell(),
        });
    }

    receive(msg: ProlongateEmployeeContractManagerContract) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(
            ctx.sender == self.managerAddress(msg.company_address, msg.manager_address, msg.manager_employee_contract, msg.subordinate_address, msg.subordinate_employee_contract, msg.date_start, msg.version_contract_manager!!),
            "ProlongateEmployeeContractManagerContract: sender is not manager contracts"
        );

        msgValue -= self.gas_consumption;

        msg.review_period_leaving = self.review_period_leaving;

        message(MessageParameters{
            to: msg.employee_contract_address!!,
            value: msgValue,
            mode: SendPayGasSeparately,
            body: msg.toCell(),
        });
    }

    fun managerInit(
        company_address: Address,
        manager_address:  Address, // user profile contract
        manager_employee_contract:  Address,
        subordinate_address:  Address, // user profile contract
        subordinate_employee_contract:  Address,
        date_start: Int
    ): StateInit {
        let initData: ManagerInitData = ManagerInitData{
            lazy_bit: false,
            master_contract: myAddress(),
            company_address: company_address,
            manager_address:  manager_address,
            manager_employee_contract:  manager_employee_contract,
            subordinate_address:  subordinate_address,
            subordinate_employee_contract:  subordinate_employee_contract,
            date_start: date_start
        };

        return StateInit{
            code: self.manager_contract_code!!,
            data: initData.toCell()
        }
    }

    get fun managerAddress(
        company_address: Address,
        manager_address: Address, // user profile contract
        manager_employee_contract: Address,
        subordinate_address: Address, // user profile contract
        subordinate_employee_contract: Address,
        date_start: Int,
        version: Int
    ): Address {
        let version_contract_manager: ContractVersionsStruct? = self.version_contract_manager.get(version);
        let initCode: StateInit = self.managerInit(company_address, manager_address, manager_employee_contract, subordinate_address, subordinate_employee_contract, date_start);

        if (version_contract_manager == null){
            return contractAddress(initCode);
        } else {
            return contractAddressFromHash(version_contract_manager!!.code_hash, version_contract_manager!!.code_depth, initCode.data)
        }
    }

    receive (msg: SetManagerContractCode) {
        require(sender() == self.admin!!, "SetManagerContractCode: sender is not a contract admin");
        self.manager_contract_code = msg.manager_contract_code;
    }

    fun createCheckManagerMessage(manager_struct: CheckManagerStruct): CheckManager {
        let resultMsg: CheckManager = CheckManager{
            company_address: manager_struct.company_address,
            data: CreateManagerContractStruct{
                creator_address: manager_struct.data.creator_address,
                date_start: manager_struct.data.date_start,
                description: manager_struct.data.description,
                duration: manager_struct.data.duration,
                employee_manager: manager_struct.data.employee_manager,
                employee_manager_contract: manager_struct.data.employee_manager_contract,
                employee_manager_is_CEO: manager_struct.data.employee_manager_is_CEO,
                employee_subordinate: manager_struct.data.employee_subordinate,
                employee_subordinate_contract: manager_struct.data.employee_subordinate_contract,
                review_period_leaving: manager_struct.data.review_period_leaving,
                signature: manager_struct.data.signature,
                tag_manager: manager_struct.data.tag_manager,
                tag_subordinate: manager_struct.data.tag_subordinate,
            },
        };

        return resultMsg;
    }

    fun createCheckSubordinateMessage(manager_struct: CheckManagerStruct): CheckSubordinate {
        let resultMsg: CheckSubordinate = CheckSubordinate{
            company_address: manager_struct.company_address,
            data: CreateManagerContractStruct{
                creator_address: manager_struct.data.creator_address,
                date_start: manager_struct.data.date_start,
                description: manager_struct.data.description,
                duration: manager_struct.data.duration,
                employee_manager: manager_struct.data.employee_manager,
                employee_manager_contract: manager_struct.data.employee_manager_contract,
                employee_manager_is_CEO: manager_struct.data.employee_manager_is_CEO,
                employee_subordinate: manager_struct.data.employee_subordinate,
                employee_subordinate_contract: manager_struct.data.employee_subordinate_contract,
                review_period_leaving: manager_struct.data.review_period_leaving,
                signature: manager_struct.data.signature,
                tag_manager: manager_struct.data.tag_manager,
                tag_subordinate: manager_struct.data.tag_subordinate,
            }
        };

        return resultMsg;
    }

    fun deployManager(data: DeployManager) {
        require(data.employee_manager != data.employee_subordinate, "DeployManager: forbidden create contract between same user");
        let managerAddress: Address = self.managerAddress(
            data.company_address,
            data.employee_manager,
            data.employee_manager_contract,
            data.employee_subordinate,
            data.employee_subordinate_contract,
            data.date_start,
            -1
        );
        let ok: Bool = self.checkSignature(managerAddress.asSlice(), data.signature);

        require(ok, "deployManager: invalid signature");

        require(data.date_start <= now() + self.duration_data.max_manager_start_period, "deployManager: incorrect date_start period");

        let duration: Int = data.duration;
        require(
            duration >= self.duration_data.min_manager_contract_duration && duration <= self.duration_data.max_manager_contract_duration,
            "deployManager: incorrect duration"
        );

        require(
            data.msgValue > self.commission_creation_manager,
            "deployManager: not enough value for commission"
        );

        data.msgValue = data.msgValue - self.commission_creation_manager;

        let manager_init: StateInit = self.managerInit(
            data.company_address,
            data.employee_manager,
            data.employee_manager_contract,
            data.employee_subordinate,
            data.employee_subordinate_contract,
            data.date_start
        );

        let CreateManagerMsg = CreateManagerContract{
            admin_address: self.admin,
            comment_msg_val: self.comment_msg_val,
            company_address:data.company_address,
            creator_address: data.creator_address,
            date_start: data.date_start,
            description: data.description,
            duration: duration,
            gas_consumption: self.subcontract_gas_consumption,
            review_period_leaving: self.review_period_leaving,
            signature: data.signature,
            tag_manager: data.tag_manager,
            tag_subordinate: data.tag_subordinate
        };

        deploy(DeployParameters{
            value: data.msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: CreateManagerMsg.toCell(),
            init: manager_init
        });
    }
    //================================ MANAGER END ================================

    //================================ COMPANY VOTING ================================

    receive(msg: CreateCompanyVotingContract) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        let companyVotingAddress: Address = self.companyVotingAddress(msg.company_address,-1);
        let ok: Bool = self.checkSignature(companyVotingAddress.asSlice(), msg.signature);

        require(ok, "CreateCompanyVotingContract: invalid signature");
        require(msgValue >= self.company_voting_cost, "CreateCompanyVotingContract: not enough funds for company voting creation");
        require(msg.company_address == self.companyAddress(msg.company_creator_address!!, msg.company_hash!!, msg.version_contract_company!!), "CreateCompanyVotingContract: sender is not msg company");
        require(ctx.sender == msg.company_address, "CreateCompanyVotingContract: sender is not equal company address");

        if (msg.new_coowner != null) {
            require(
                msg.new_coowner == self.userProfileAddress(msg.new_coowner_check_data!!.creator_address, msg.new_coowner_check_data!!.hash, msg.new_coowner_check_data!!.version_contract_user_profile),
                "CreateCompanyVotingContract: new_coowner is incorrect"
            );
        }

        msgValue -= self.deploy_gas_consumption;

        msg.admin_address = self.admin;

        msg.gas_consumption = self.subcontract_gas_consumption;
        msg.min_tons_for_storage = self.min_tons_for_storage_company_voting;
        msg.comment_tons = self.comment_msg_val_company_voting;
        msg.max_voting_duration = self.duration_data.max_voting_duration;
        msg.max_voting_duration_expel = self.duration_data.max_voting_duration_expel;

        let company_voting_init: StateInit = self.companyVotingInit(msg.company_address);

        deploy(DeployParameters{
            value: msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: msg.toCell(),
            init: company_voting_init
        });
    }

    receive(msg: HandleSuccessVoting) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        let company_voting_address = self.companyVotingAddress(msg.company_address, msg.version_contract_company_voting!!);

        require(msg.company_voting_address == company_voting_address, "HandleSuccessVoting: invalid msg company voting address");
        require(ctx.sender == company_voting_address, "HandleSuccessVoting: sender is not company voting address");

        msgValue -= self.gas_consumption;
        message(MessageParameters{
            to: msg.company_address,
            value: msgValue,
            body: msg.toCell(),
        });
    }

    receive (msg: SetCompanyVotingCode) {
        require(sender() == self.admin!!, "SetCompanyVotingCode: sender is not a contract admin");
        self.company_voting_code = msg.company_voting_code;
    }

    get fun companyVotingAddress(company_address: Address, version: Int): Address {
        let version_contract_company_voting: ContractVersionsStruct? = self.version_contract_company_voting.get(version);
        let initCode: StateInit = self.companyVotingInit(company_address);

        if (version_contract_company_voting == null){
            return contractAddress(initCode);
        } else {
            return contractAddressFromHash(version_contract_company_voting!!.code_hash, version_contract_company_voting!!.code_depth, initCode.data)
        }
    }

    fun companyVotingInit(company_address: Address): StateInit {
        let initData: CompanyVotingInitData = CompanyVotingInitData{
            lazy_bit: false,
            master_contract: myAddress(),
            company_address: company_address,
        };

        return StateInit{
            code: self.company_voting_code!!,
            data: initData.toCell()
        }
    }

    //================================ COMPANY VOTING END ================================

    fun checkSignature(dataToVerify: Slice, signature: Slice): Bool {
//         let ok: Bool = checkSignature(dataToVerify.hash(), signature, self.publicKey!!);
//
//         return ok
        return true
    }

    receive(msg: UpdateReviewPeriodLeaving) {
        require(sender() == self.admin, "UpdateUserProfileCreationCost: only admin can update review_period_leaving");
        self.review_period_leaving = msg.review_period_leaving;
    }

    receive(msg: UpdateContractServiceCosts) {
        require(sender() == self.admin, "UpdateContractServiceCosts: only admin can update contract service costs");

        self.user_profile_creation_cost = msg.user_profile_creation_cost;
        self.company_creation_cost = msg.company_creation_cost;
        self.employee_creation_cost = msg.employee_creation_cost;
        self.ceo_creation_cost = msg.ceo_creation_cost;
        self.hr_creation_cost = msg.hr_creation_cost;
        self.manager_creation_cost = msg.manager_creation_cost;
        self.employee_prolongation_cost = msg.employee_prolongation_cost;

        self.employee_termination_cost = msg.employee_termination_cost;
        self.manager_termination_cost = msg.manager_termination_cost;
        self.hr_termination_cost = msg.hr_termination_cost;
        self.ceo_termination_cost = msg.ceo_termination_cost;
        self.employee_termination_manager_cost = msg.employee_termination_manager_cost;

        self.comment_msg_val = msg.comment_msg_val;
        self.deploy_gas_consumption = msg.deploy_gas_consumption;
        self.subcontract_gas_consumption = msg.subcontract_gas_consumption;
        self.min_tons_for_storage_hr = msg.min_tons_for_storage_hr;
        self.created_comment_msg_val_hr = msg.created_comment_msg_val_hr;
        self.terminated_comment_msg_val_hr = msg.terminated_comment_msg_val_hr;

        self.company_voting_cost = msg.company_voting_cost;
        self.min_tons_for_storage_company_voting = msg.min_tons_for_storage_company_voting;
        self.comment_msg_val_company_voting = msg.comment_msg_val_company_voting;

        self.employee_grade_cost = msg.employee_grade_cost;
        self.company_grade_cost = msg.company_grade_cost;
        self.manager_grade_cost = msg.manager_grade_cost;

        self.terminate_val = msg.terminate_val;
        self.confirm_terminate_val = msg.confirm_terminate_val;
        self.confirmation_message_from_ceo_to_company_val = msg.confirmation_message_from_ceo_to_company_val;

        self.manager_confirmation_cost = msg.manager_confirmation_cost;
        self.employee_confirmation_cost = msg.employee_confirmation_cost;
    }

    receive(msg: UpdateContractDurationData) {
        require(sender() == self.admin, "UpdateContractDurationData: only admin can update duration_data");

        self.duration_data.max_employee_contract_duration = msg.max_employee_contract_duration;
        self.duration_data.min_employee_contract_duration = msg.min_employee_contract_duration;

        self.duration_data.max_employee_contract_prolongation_duration = msg.max_employee_contract_prolongation_duration;
        self.duration_data.min_employee_contract_prolongation_duration = msg.min_employee_contract_prolongation_duration;

        self.duration_data.max_employee_start_period = msg.max_employee_start_period;
        self.duration_data.max_manager_start_period = msg.max_manager_start_period;

        self.duration_data.min_manager_contract_duration = msg.min_manager_contract_duration;
        self.duration_data.max_manager_contract_duration = msg.max_manager_contract_duration;

        self.duration_data.max_voting_duration = msg.max_voting_duration;
        self.duration_data.max_voting_duration_expel = msg.max_voting_duration_expel;
    }

    receive(msg: SetVersionContract) {
        require(sender() == self.admin, "SetVersionContract: only admin can update version_contract values");

        if(msg.type == "ceo") {
            self.version_contract_CEO.set(msg.key, msg.value)
        } else if (msg.type == "user_profile") {
            self.version_contract_user_profile.set(msg.key, msg.value)
        } else if (msg.type == "company") {
            self.version_contract_company.set(msg.key, msg.value)
        } else if (msg.type == "hr") {
            self.version_contract_HR.set(msg.key, msg.value)
        } else if (msg.type == "employee") {
            self.version_contract_employee.set(msg.key, msg.value)
        } else if (msg.type == "manager") {
            self.version_contract_manager.set(msg.key, msg.value)
        } else if (msg.type == "company_voting") {
            self.version_contract_company_voting.set(msg.key, msg.value)
        }
    }

    receive(msg: SetCommission) {
        require(sender() == self.admin, "SetCommission: only admin can update commission values");

        self.commission_creation_employee = msg.commission_creation_employee!!;
        self.commission_creation_manager = msg.commission_creation_manager!!;
        self.commission_prolongation_employee = msg.commission_prolongation_employee!!;
    }

    receive(msg: SetPublicKey) {
        require(sender() == self.admin, "SetPublicKey: only admin can update commission values");

        self.publicKey = msg.publicKey;
    }

    get fun index(): Int {
        return self.index;
    }

    get fun publicKey(): Int? {
        return self.publicKey!!;
    }

    get fun reviewPeriodLeaving(): Int {
        return self.review_period_leaving;
    }

    get fun userProfileCreationCost(): Int {
        return self.user_profile_creation_cost;
    }

    get fun commentMsgVal(): Int {
        return self.comment_msg_val;
    }

    get fun companyCreationCost(): Int {
        return self.company_creation_cost;
    }

    get fun ceoCreationCost(): Int {
        return self.ceo_creation_cost;
    }

    get fun ceoTerminationCost(): Int {
        return self.ceo_termination_cost;
    }

    get fun employeeConfirmationCost(): Int {
        return self.employee_confirmation_cost;
    }

    get fun employeeCreationCost(): Int {
        return self.employee_creation_cost;
    }

    get fun employeeTerminationManagerCost(): Int { // ToDo test
        return self.employee_termination_manager_cost;
    }

    get fun employeeTerminationCost(): Int {
        return self.employee_termination_cost;
    }

    get fun employeeProlongationCost(): Int {
        return self.employee_prolongation_cost;
    }

    get fun hrCreationCost(): Int {
        return self.hr_creation_cost;
    }

    get fun hrTerminationCost(): Int {
        return self.hr_termination_cost;
    }

    get fun minTonsForStorageHr(): Int { // ToDo test
        return self.min_tons_for_storage_hr;
    }

    get fun createdCommentMsgValHr(): Int { // ToDo test
        return self.created_comment_msg_val_hr;
    }

    get fun terminatedCommentMsgValHr(): Int { // ToDo test
        return self.terminated_comment_msg_val_hr;
    }

    get fun managerConfirmationCost(): Int {
        return self.manager_confirmation_cost;
    }

    get fun managerCreationCost(): Int {
        return self.manager_creation_cost;
    }

    get fun managerTerminationCost(): Int {
        return self.manager_termination_cost;
    }

    get fun companyVotingCreationCost(): Int {
        return self.company_voting_cost;
    }

    get fun minTonsForStorageCompanyVoting(): Int {
        return self.min_tons_for_storage_company_voting;
    }

    get fun subcontractGasConsumption(): Int {
        return self.subcontract_gas_consumption;
    }

    get fun deployGasConsumption(): Int {
        return self.deploy_gas_consumption;
    }

    get fun commentMsgValCompanyVoting(): Int {
        return self.comment_msg_val_company_voting;
    }
    get fun durationData(): DurationStruct {
        return DurationStruct{
            max_employee_contract_duration: self.duration_data.max_employee_contract_duration,
            min_employee_contract_duration: self.duration_data.min_employee_contract_duration,

            max_employee_contract_prolongation_duration: self.duration_data.max_employee_contract_prolongation_duration,
            min_employee_contract_prolongation_duration: self.duration_data.min_employee_contract_prolongation_duration,

            max_manager_contract_duration: self.duration_data.max_manager_contract_duration,
            min_manager_contract_duration: self.duration_data.min_manager_contract_duration,

            max_employee_start_period: self.duration_data.max_employee_start_period,
            max_manager_start_period: self.duration_data.max_manager_start_period,

            max_voting_duration: self.duration_data.max_voting_duration,
            max_voting_duration_expel: self.duration_data.max_voting_duration_expel,
        }
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun GradeCost(): GradeCostValuesStruct{
        return GradeCostValuesStruct{
            company_grade_cost: self.company_grade_cost,
            employee_grade_cost: self.employee_grade_cost,
            manager_grade_cost: self.manager_grade_cost,
        };
    }

    get fun type(): String {
        return self.type;
    }

    get fun terminateVal(): Int { // ToDo test
        return self.terminate_val;
    }

    get fun confirmTerminateVal(): Int { // ToDo test
        return self.confirm_terminate_val;
    }

    get fun confirmationMessageFronCeoToCompanyVal(): Int { // ToDo test
        return self.confirmation_message_from_ceo_to_company_val;
    }

    get fun versionContract(type: String, key: Int): ContractVersionsStruct? {
        if (type == "ceo") {
            return self.version_contract_CEO.get(key);
        } else if (type == "user_profile") {
            return self.version_contract_user_profile.get(key)
        } else if (type == "company") {
            return self.version_contract_company.get(key)
        } else if (type == "hr") {
            return self.version_contract_HR.get(key)
        } else if (type == "employee") {
            return self.version_contract_employee.get(key)
        } else if (type == "manager") {
            return self.version_contract_manager.get(key)
        } else if (type == "company_voting") {
            return self.version_contract_company_voting.get(key)
        }

        return null;
    }

    get fun commissionCreationEmployee(): Int {
        return self.commission_creation_employee;
    }

    get fun commissionCreationManager(): Int {
        return self.commission_creation_manager;
    }

    get fun commissionProlongationEmployee(): Int {
        return self.commission_prolongation_employee;
    }
}

fun contractAddressFromHash(codeHash: Int, codeDepth: Int, data: Cell): Address {
    return newAddress(0, contractHashCustom(data.hash(), codeHash, data.depth(), codeDepth));
}

asm fun contractHashCustom(dataHash: Int, codeHash: Int, dataDepth: Int, codeDepth:Int): Int {
    // According to the https://docs.tact-lang.org/book/cells#cells-representation,
    // the layout for the Builder to hash goes as follows:
    // 1) refs_descriptor:bits8 | bits_descriptor:bits8 | data:bitsN
    //
    //  refs_descriptor: ref_count + ((exotic? & 1) * 8) + (mask * 32)
    //                   2 refs (code + data), non-exotic, zero-mask
    //
    //  bits_descriptor: floor(bit_count / 8) + ceil(bit_count, 8)
    //                   floor (5 bits / 8) + ceil(5 bits / 8) = 0 + 1 = 1
    //
    //  data: [0b00110] + [0b100] = [0b00110100] = 0x34 (data + augmented bits)
    //        0b00110 - data (split_depth, special, code, data, Library)
    //        0b100 - augmented bits (Leading 1 + zeroes to make section multiple of eight)
    //
    //  That is: (2 << 16) | (1 << 8) | 0x34 = 131380 for all three.
    //
    // 2) and 3) depth_descriptors: CDEPTH of `code` and CDEPTH of `data`
    // 4) and 5) ref hashes: HASHCU of `code` and HASHCU of `data`

    // Group 1: Computations and arrangements
    131380 INT     // (2 << 16) | (1 << 8) | 0x34

    // Group 2: Composition of the Builder
    NEWC
    24 STU  // store refs_descriptor | bits_descriptor | data
    16 STU  // store depth_descriptor for `code`
    16 STU  // store depth_descriptor for `data`
    256 STU // store `code` hash
    256 STU // store `data` hash

    // Group 3: SHA256 hash of the resulting Builder
    ONE HASHEXT_SHA256
}
