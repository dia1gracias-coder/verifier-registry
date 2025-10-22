import "@stdlib/deploy";
import "@stdlib/ownable";
import "./extensions/Array";
import "./extensions/gasConstants";
import "./extensions/errorCodes";
import "./extensions/RoyaltyCollector";
import "./interfaces/IRegistry";
import "./Event";

const EVENT_STARTING_BALANCE: Int = ton("0.4");

contract Registry with Deployable, Ownable {

    owner: Address;
    nextEventId: Int as uint32;

    init() {
        self.owner = sender();
        self.nextEventId = 0;
    }

    receive() {}

    receive(msg: CreateEvent) {
        // TODO: Check who can deploy an Event

        throwIf(ERR_INVALID_TIMESTAMP, now() > msg.endTimestamp);

        let n = msg.ticketAmounts.length;
        let m = msg.ticketPrices.length;

        throwIf(ERR_INVALID_ARRAY_LEN, n != m || n == 0 || n > G_MAX_ARRAY_SIZE);

        throwIf(ERR_INVALID_ROYALTIES, !self.checkRoyaltyTotalFee(msg.sellRoyaltyCollectors, 0));
        throwIf(ERR_INVALID_ROYALTIES, !self.checkRoyaltyTotalFee(msg.resellRoyaltyCollectors, RESELL_OWNER_FEE));

        msg.resellRoyaltyCollectors.appendCollector(self.owner, RESELL_OWNER_FEE);

        let ctx: Context = context();
        let priceForEventStorage = self.priceForEventStorage(msg.endTimestamp - now());
        let priceForCreateEventExecution = getComputeFee(R_CREATE_EVENT__EXECUTION_GAS, false);
        let priceForSendBytecodeActionMsg = getSimpleForwardFee(R_CREATE_EVENT__DEPLOYMENT_ACTION_NO_CELLS, R_CREATE_EVENT__DEPLOYMENT_ACTION_NO_BITS, false);  
        let priceForSendDeploymentMsg = getComputeFee(R_CREATE_EVENT__SEND_DEPLOYMENT_MSG, false);

        throwIf(ERR_INVALID_MSG_VALUE, ctx.value < 
            priceForEventStorage +
            priceForCreateEventExecution +
            priceForSendBytecodeActionMsg +
            priceForSendDeploymentMsg
        );

        let bytecode: StateInit = initOf Event(
            self.owner,
            self.nextEventId,
            msg.eventName,
            msg.eventUri,
            msg.ticketAmounts,
            msg.ticketPrices,
            msg.endTimestamp,
            msg.sellRoyaltyCollectors,
            msg.resellRoyaltyCollectors
        );

        // TODO: @dev notice `gasConsumption` is the price of executing the deployment of Event contract, and the `priceFotEventStorage`
        //                   is a price for reserving the contract storage until event exists
        deploy(DeployParameters{
            init: bytecode,
            mode: SendPayFwdFeesSeparately,
            value: priceForEventStorage + EVENT_STARTING_BALANCE
        });

        // TODO: Emit an event with this address
        // let eventContractAddress: Address = contractAddress(bytecode);

        self.nextEventId += 1;
    }

    fun checkRoyaltyTotalFee(royaltyCollectors: RoyaltyCollectorArray, ownerFee: Int): Bool {
        let i = 0;
        let n = royaltyCollectors.length;

        let totalFee = 0;

        while(i < n) {
            totalFee += royaltyCollectors.getFeeByIndex(i);
            i += 1;
        }

        return (ownerFee + totalFee) <= 10000;
    }

    get fun priceForEventStorage(amountOfSeconds: Int): Int {
        return getStorageFee(E_NO_CELLS, E_NO_BITS, amountOfSeconds, false);
    }

    // TODO: How to test this?
    /*get fun registryStorageDebt(): Int {
        return myStorageDue();
    }*/
}