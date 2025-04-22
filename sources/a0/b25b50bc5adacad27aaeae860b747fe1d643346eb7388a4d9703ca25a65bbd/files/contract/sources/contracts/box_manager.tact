import "@stdlib/ownable";
import "@stdlib/deploy";
import "./messages.tact";


contract BoxManager with Deployable, Ownable {
    owner: Address;
    income_vault: Address;
    reward_vault: Address;

    gas_required: Int as coins;
    pub_key: Int;

    unique_id_manager: Address?;

    init (owner: Address, income_vault: Address, reward_vault: Address, pub_key: Int) {
        require(sender() == owner, "Only owner allowed");
        self.owner = owner;
        self.income_vault = income_vault;
        self.reward_vault = reward_vault;
        self.pub_key = pub_key;
        self.gas_required = ton("0.01"); 

        self.unique_id_manager = null;
    }

    receive(msg: SetUniqueIdManager) {
        self.requireOwner();
        self.unique_id_manager = msg.unique_id_manager;
        send(SendParameters {
            bounce: false,
            to: sender(),
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
        });
    }

    fun checkServerSignature(signature: Slice, id: String, amount: Int, expired_at: Int) {
        let hash: Int = beginCell().storeSlice(id.asSlice()).storeUint(amount, 256).storeUint(expired_at, 256).endCell().hash();
        let check: Bool = checkSignature(hash, signature, self.pub_key);
        require(check, "Incorrect Signature");
    }

    fun checkMsgTimestamp(expire_at: Int) {
        require(now() < expire_at, "Message Expired");
    }

    fun checkTonValue(expected: Int) {
        let ctx: Context = context();
        require(ctx.value >= self.gas_required + expected, "Not enough TON");
    }

    get fun getBoxManagerData(): BoxManagerData {
        return BoxManagerData {
            owner: self.owner,
            income_vault: self.income_vault,
            reward_vault: self.reward_vault,
            gas_required: self.gas_required,
            unique_id_manager: self.unique_id_manager,
        }
    }

    receive(msg: PayForBoxOriginal) {
        self.checkServerSignature(msg.signature, msg.id, msg.box_price, msg.expire_at);
        self.checkMsgTimestamp(msg.expire_at);
        self.checkTonValue(msg.box_price);

        send(SendParameters {
            to: self.unique_id_manager!!,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: PayForBoxInitiated {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                box_price: msg.box_price,
                box_id: msg.box_id,
                user_id: msg.user_id,
                initiator: sender(),
            }.toCell()
        });
    }

    receive(msg: PayForBoxIdChecked) {
        require(sender() == self.unique_id_manager, "Only Id Manager allowed");
        require(msg.id_checked == true, "OperationId check failed");

        send(SendParameters {
            to: self.income_vault,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: PayForBoxConfirm {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                box_price: msg.box_price,
                box_id: msg.box_id,
                user_id: msg.user_id,
                initiator: msg.initiator,
            }.toCell()
        });
    }

    receive(msg: DepositeRewardOriginal) {
        self.checkServerSignature(msg.signature, msg.id, msg.amount_reward, msg.expire_at);
        self.checkMsgTimestamp(msg.expire_at);
        self.checkTonValue(msg.amount_reward);

        send(SendParameters {
            to: self.unique_id_manager!!,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: DepositeRewardInitiated {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                box_id: msg.box_id,
                amount_reward: msg.amount_reward,
                amount_winners: msg.amount_winners,
                initiator: sender(),
            }.toCell()
        });
    }

    receive(msg: DepositeRewardIdChecked) {
        require(sender() == self.unique_id_manager, "Only Id Manager allowed");
        require(msg.id_checked == true, "OperationId check failed");

        send(SendParameters {
            to: self.reward_vault,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: DepositeRewardConfirm {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                box_id: msg.box_id,
                amount_reward: msg.amount_reward,
                amount_winners: msg.amount_winners,
                initiator: msg.initiator,
            }.toCell()
        });
    }

    receive(msg: ClaimRewardOriginal) {
        self.checkServerSignature(msg.signature, msg.id, msg.amount_reward, msg.expire_at);
        self.checkMsgTimestamp(msg.expire_at);
        self.checkTonValue(0);

        send(SendParameters {
            to: self.unique_id_manager!!,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ClaimRewardInitiated {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                box_id: msg.box_id,
                amount_reward: msg.amount_reward,
                initiator: sender(),
            }.toCell()
        });
    }

    receive(msg: ClaimRewardIdChecked) {
        require(sender() == self.unique_id_manager, "Only Id Manager allowed");
        require(msg.id_checked == true, "OperationId check failed");

        send(SendParameters {
            to: self.reward_vault,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ClaimRewardConfirm {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                amount_reward: msg.amount_reward,
                box_id: msg.box_id,
                initiator: msg.initiator,
            }.toCell()
        });
    }

    receive(msg: ClaimIncomeOriginal) {

        self.checkServerSignature(msg.signature, msg.id, msg.amount, msg.expire_at);
        self.checkMsgTimestamp(msg.expire_at);
        self.checkTonValue(0);
        
        send(SendParameters {
            to: self.unique_id_manager!!,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ClaimIncomeInitiated {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                amount: msg.amount,
                box_id: msg.box_id,
                user_id: msg.user_id,
                initiator: sender(),
            }.toCell()
        });
    }

    receive(msg: ClaimIncomeIdChecked) {
        require(sender() == self.unique_id_manager, "Only Id Manager allowed");
        require(msg.id_checked == true, "OperationId check failed");

        send(SendParameters {
            to: self.income_vault,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ClaimIncomeConfirm {
                signature: msg.signature,
                id: msg.id,
                expire_at: msg.expire_at,
                amount: msg.amount,
                box_id: msg.box_id,
                user_id: msg.user_id,
                initiator: msg.initiator,
            }.toCell()
        });
    }
}