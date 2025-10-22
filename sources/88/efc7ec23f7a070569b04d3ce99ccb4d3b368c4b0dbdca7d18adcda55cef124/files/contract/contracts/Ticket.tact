import "@stdlib/ownable";
import "./interfaces/ITicket";
import "./extensions/errorCodes";

/**
 * @dev The `owner` denotes the operator's address for this contract, which is the event contract due to the `Ownable` trait. 
 *      The `ticketOwner` refers to the individual who actually possesses the ticket.
 */
contract Ticket (
    owner: Address,
    firstOwner: Address,
    ticketId: Int as uint32,
    ticketType: Int as uint8,
    redeemed: Bool,
    metadata: Cell,
    currentOwner: Address,
) with Ownable {

    // TODO: Storage fee during deployment (NO TICKET_STARTING_BALANCE)

    receive(msg: MarketplaceTransfer) {
        self.initCurrentOwner();
        throwIf(ERR_SENDER_NOT_EVENT_CONTRACT, sender() != self.owner());
        throwIf(ERR_INVALID_SENDER, msg.previousOwner != self.currentOwner);
        self.currentOwner = msg.newOwner;
    }

    receive(msg: RedeemTicket) {
        self.initCurrentOwner();
        let ctx: Context = context();
        throwIf(ERR_INVALID_MSG_VALUE, ctx.value <
            ton("0.01") // TODO_FWD_FEE
        );
        throwIf(ERR_SENDER_NOT_OWNER, ctx.sender != self.currentOwner);
        throwIf(ERR_TICKET_REDEEMED, self.redeemed == true);
        self.redeemed = true;
    }

    // TODO: Disabled for MVP
    // TODO: Who can send transfer message?
    // TODO: Maybe delete
    /*receive(msg: TransferTicket) {
        // TODO: Check initialization
        // TODO: Force basechain

        self.initCurrentOwner();

        let msgSender = sender();
        throwIf(ERR_SENDER_NOT_OWNER, msgSender != self.currentOwner && msgSender != self.owner);
        self.currentOwner = msg.receiver;
    }*/
    
    get fun ticketId(): Int {
        return self.ticketId;
    }

    get fun ticketType(): Int {
        return self.ticketType;
    }

    get fun currentOwner(): Address {
        return self.currentOwner;
    }

    get fun redeemed(): Bool {
        return self.redeemed;
    }

    get fun uri(): Cell {
        let slice = self.metadata.beginParse();
        let _prefix = slice.loadUint(8);
        let dictCell = slice.loadRef();
        let dict = cellToMap(dictCell);

        return dict.get(sha256("image"))!!;
    }

    fun initCurrentOwner() {
        if(self.currentOwner == newAddress(0, 0) /* ZERO_ADDRESS */) {
            self.currentOwner = self.firstOwner;
        }
    }
}

asm fun cellToMap(x: Cell): map<Int as uint256, Cell> { NOP }