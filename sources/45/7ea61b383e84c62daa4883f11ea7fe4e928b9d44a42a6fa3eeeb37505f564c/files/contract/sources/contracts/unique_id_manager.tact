import "@stdlib/ownable";
import "@stdlib/deploy";
import "./messages.tact";
import "./unique_id_item.tact";


contract UniqueIdManager with Deployable, Ownable {
    owner: Address;
    box_manager: Address?;

    id: Int as uint32;

    init (id: Int, owner: Address) {
        require(sender() == owner, "Only owner allowed");
        self.id = id;
        self.owner = owner;
        self.box_manager = null;
    }

    fun onlyBoxManager() {
        require(self.box_manager != null, "Box Manager not set");
        require(sender() == self.box_manager, "Only for Box Manager");
    }

    get fun getUniqueIdManagerData(): UniqueIdManagerData {
        return UniqueIdManagerData {
            owner: self.owner,
            box_manager: self.box_manager,
        }
    }

    get fun getItemInit(operation_id: String): StateInit {
        return initOf UniqueIdItem(myAddress(), operation_id);
    }

    receive(msg: SetBoxManager) {
        self.requireOwner();
        self.box_manager = msg.box_manager;
        send(SendParameters {
            bounce: false,
            to: sender(),
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
        });
    }

    receive(msg: DepositeRewardInitiated) {
        self.onlyBoxManager();
        let item_init: StateInit = self.getItemInit(msg.id);
        
        send(SendParameters {
            to: contractAddress(item_init),  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: msg.toCell(),
            code: item_init.code,
            data: item_init.data,
        });

    }

    receive(msg: DepositeRewardIdChecked) {
        require(sender() == contractAddress(self.getItemInit(msg.id)), "Only for item contracts.");
        
        send(SendParameters {
            to: self.box_manager!!,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: msg.toCell()
        });
    }

    receive(msg: PayForBoxInitiated) {
        self.onlyBoxManager();
        let item_init: StateInit = self.getItemInit(msg.id);
        
        send(SendParameters {
            to: contractAddress(item_init),  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: msg.toCell(),
            code: item_init.code,
            data: item_init.data,
        });
    }

    receive(msg: PayForBoxIdChecked) {
        require(sender() == contractAddress(self.getItemInit(msg.id)), "Only for item contracts.");
        
        send(SendParameters {
            to: self.box_manager!!,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: msg.toCell()
        });
    }



    receive(msg: ClaimRewardInitiated) {
        self.onlyBoxManager();
        let item_init: StateInit = self.getItemInit(msg.id);
        
        send(SendParameters {
            to: contractAddress(item_init),  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: msg.toCell(),
            code: item_init.code,
            data: item_init.data,
        });
    }

    receive(msg: ClaimRewardIdChecked) {
        require(sender() == contractAddress(self.getItemInit(msg.id)), "Only for item contracts.");
        
        send(SendParameters {
            to: self.box_manager!!,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: msg.toCell(),
        });
    }


    receive(msg: ClaimIncomeInitiated) {
        self.onlyBoxManager();
        let item_init: StateInit = self.getItemInit(msg.id);
        
        send(SendParameters {
            to: contractAddress(item_init),  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: msg.toCell(),
            code: item_init.code,
            data: item_init.data,
        });
    
    }

    receive(msg: ClaimIncomeIdChecked) {
        require(sender() == contractAddress(self.getItemInit(msg.id)), "Only for item contracts.");
        
        send(SendParameters {
            to: self.box_manager!!,  
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: msg.toCell(),
        });
    }
}