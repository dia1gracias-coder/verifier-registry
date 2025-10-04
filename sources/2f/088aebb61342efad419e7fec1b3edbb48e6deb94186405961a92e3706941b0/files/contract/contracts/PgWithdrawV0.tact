// this trait has to be imported
import "@stdlib/ownable";

contract PgWithdrawV0 with Ownable, Upgradable {
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

    receive(msg: WdEnableInternal) {

        self.requireOwner(); 
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);
        
        self.wdExecutor = msg.wdExecutor;

        if (msg.newCode != null) {
            setCode(msg.newCode!!);
        }   

        // send excess
        message(MessageParameters {
            bounce: false,
            to: self.merchant,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
        });

    }
}