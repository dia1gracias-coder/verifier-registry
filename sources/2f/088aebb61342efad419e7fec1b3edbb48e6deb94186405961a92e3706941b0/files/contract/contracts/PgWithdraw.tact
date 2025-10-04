// this trait has to be imported
import "@stdlib/ownable";
import "./Includes";

contract PgWithdraw with Ownable, Upgradable {
    owner: Address; // factory
    version: Int as uint32 = 0;
    merchant: Address;

    wdExecutor: Address; 
    circularWdIds: CircularBuffer;
    wdIds:map<Int as uint256, Bool> = emptyMap();
    jettonLprAmts: map<Address, Int as coins>; //jetton => limit per request
    
    // extra state
    extra: map<Int as uint32, Cell>;

    init(factory: Address, merchant: Address) {
        self.owner = factory; 
        self.merchant = merchant;
        self.wdExecutor = _emptyAddress();
        self.circularWdIds = _emptyCircularBuffer(20000);
    }

    receive(msg: WdSupplyExecutorGasInternal) {
        
        self.requireOwner(); 
        require(self.wdExecutor != _emptyAddress(), "wdxecutor not exists");

        //forward ton as gas
        message(MessageParameters {
            mode: SendRemainingValue | SendIgnoreErrors,
            body: null,
            value: 0,
            to: self.wdExecutor,
            bounce: false,
        });

    }

    receive(msg: WdPayoutInternal) {

        self.requireOwner(); 
        require(msg.wdExecutor == self.wdExecutor, "invalid wdExecutor");

        let jetton= msg.jetton;
        foreach (idx, amount in msg.amounts) {

            let id: Int= msg.ids.get(idx)!!;
            require(!self.wdIds.exists(id), "id exists" );

            let recipient:Address = msg.recipients.get(idx)!!;
            let keyToDel = self.circularWdIds.put(id);
            if (keyToDel > 0) {
                require(id > keyToDel, "id too low");
            }
            let _ = self.wdIds.del(keyToDel);
            self.wdIds.set(id, true);

            if (jetton == zeroAccount) {
                _transferTonFromContract(recipient, msg.queryId, amount);
            } else {    
                _transferFromContract(msg.wdJWallet, msg.queryId, amount, recipient, self.merchant, gasNanoForTransfer);
            }   
        }

        //send excess
        message(MessageParameters {
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
            value: 0,
            to: self.merchant,
            bounce: false,
        });
    }

    receive() {
        //cashback(sender())
    }

    get fun checkWdIds(ids: map<Int as uint16, Int as uint256>): map<Int as uint256, Bool> {

        let res: map<Int as uint256, Bool> = emptyMap();
        foreach (_, id in ids) {
            res.set(id, self.wdIds.exists(id));
        }
        
        return res;
    } 

    get fun data(): WithdrawalData {
        return WithdrawalData{
            owner: self.owner,
            version: self.version,
            merchant: self.merchant,
        };
    } 

    get fun jettonWalletAddress(dataLayoutId: Int, code: Cell, minter: Address, owner: Address): Address {
        return _jettonWalletAddress(dataLayoutId, code, minter, owner);
    }   
}
