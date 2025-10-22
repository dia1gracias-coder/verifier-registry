import "@stdlib/ownable";
import "./extensions/Array";
import "./extensions/errorCodes";
import "./extensions/gasConstants";
import "./extensions/RoyaltyCollector";
import "./extensions/Order";
import "./interfaces/IEvent";
import "./Ticket";
import "./interfaces/ITicket";

const TODO_MSG_FEE: Int = ton("0.4");
const TODO_FWD_FEE: Int = ton("0.01");

const ZERO_ADDRESS: Address = newAddress(0, 0);

const SCHEMA_HASH: Int = 2249901368;
const DOMAIN_HASH: Int = 108261408677849562057843282311472841925127618525520303375122013670478781224044;

contract Event with Ownable {
    owner: Address;
    id: Int as uint32;
    name: String;
    amounts: Array;
    prices: Array;
    endTimestamp: Int as uint64;
    sellRoyaltyCollectors: RoyaltyCollectorArray;
    resellRoyaltyCollectors: RoyaltyCollectorArray;
    baseUri: String;

    // Total royalty earnings
    royaltiesEarned: map<Address, Int>;

    // TODO: Reserved tickets (WITH TIERS). Maybe amounts & amountsReserved
    nextTicketIndex: Int as uint32 = 0;

    // TODO: Maybe combine these two maps as one, since values can be true, false, null
    marketplaceFilledOrders: map<Int, Bool>;
    marketplaceCanceledOrders: map<Int, Bool>;

    init(
        owner: Address,
        id: Int,
        name: String,
        baseUri: String,
        ticketAmounts: Array,
        ticketPrices: Array,
        endTimestamp: Int,
        sellRoyaltyCollectors: RoyaltyCollectorArray,
        resellRoyaltyCollectors: RoyaltyCollectorArray
    ) {
        self.owner = owner;
        self.id = id;
        self.name = name;
        self.baseUri = baseUri;
        self.amounts = ticketAmounts;
        self.prices = ticketPrices;
        self.endTimestamp = endTimestamp;
        self.sellRoyaltyCollectors = sellRoyaltyCollectors;
        self.resellRoyaltyCollectors = resellRoyaltyCollectors;

        // Since the set of royalty addresses is known in advance, we can pre-initialize them to 0 upon contract
        // creation. This way, we avoid checking for map entry existence each time BuyTickets is called.
        let i = 0;
        let n = sellRoyaltyCollectors.length;
        while(i < n) {
            let collector: RoyaltyCollector = sellRoyaltyCollectors.getCollectorByIndex(i);
            self.royaltiesEarned.set(collector.collectorAddress, 0);
            i += 1;
        }

        i = 0;
        n = resellRoyaltyCollectors.length;
        while(i < n) {
            let collector: RoyaltyCollector = resellRoyaltyCollectors.getCollectorByIndex(i);
            self.royaltiesEarned.set(collector.collectorAddress, 0);
            i += 1;
        }

        self.royaltiesEarned.set(self.owner, 0);
    }

    receive() {}

    // @dev: With this design we cannot check the account limit
    receive(msg: BuyTickets) {
        let n = msg.ticketTypes.length;

        // Revert if the ticketTypes array is empty
        throwIf(ERR_INVALID_ARRAY_LEN, n == 0);

        // Revert if the event has passed
        throwIf(ERR_EVENT_ENDED, now() > self.endTimestamp);

        let ctx: Context = context();
        let priceForTicketStorage = self.priceForTicketStorage(self.endTimestamp - now());
        let priceForTickets = self.getTotalValueOfCards(msg.ticketTypes);

        // Revert if message is underpriced
        throwIf(ERR_INVALID_MSG_VALUE, ctx.value < 
            priceForTickets +
            n * priceForTicketStorage + 
            TODO_MSG_FEE +
            TODO_FWD_FEE * (n+1)
        );

        // Return change
        if(ctx.value > priceForTickets + TODO_FWD_FEE) {
            send(SendParameters{
                to: ctx.sender,
                value: ctx.value - priceForTickets
            });
        }

        // Calculate royalties
        let totalRoyalties = 0;

        let i = 0;
        let m = self.sellRoyaltyCollectors.length;
        while(i < m) {
            let collector: RoyaltyCollector = self.sellRoyaltyCollectors.getCollectorByIndex(i);
            let collectorEarned = (priceForTickets * collector.royaltyFee) / 10000;

            let previousBalance = self.royaltiesEarned.get(collector.collectorAddress)!!;
            self.royaltiesEarned.set(collector.collectorAddress, previousBalance + collectorEarned);

            totalRoyalties += collectorEarned;
            i += 1;
        }

        let previousBalance = self.royaltiesEarned.get(self.owner)!!;
        self.royaltiesEarned.set(self.owner, previousBalance + (priceForTickets - totalRoyalties));

        // Deploy new tickets
        i = 0;
        while(i < n) {
            let ticketType = msg.ticketTypes.getIndex(i);

            let metadataCell = self.composeTicketMetadata(self.nextTicketIndex);

            deployTicket(
                myAddress(),
                sender(),
                self.nextTicketIndex,
                ticketType,
                TODO_FWD_FEE + priceForTicketStorage, // TODO: Calculate deployment fee
                metadataCell
            );

            // TODO: Emit an event with this address
            // let ticketContractAddress: Address = contractAddress(bytecode);

            self.nextTicketIndex += 1;
            i += 1;
        }
    }

    receive(msg: FillOrder) {
        let res = checkSignature(
            msg.signedOrder.hash(),
            msg.signature.beginParse(),
            msg.publicKey
        );
        throwIf(ERR_INVALID_SIGNATURE, !res);

        let ctx: Context = context();

        let buyer: Address = ctx.sender;
        let msgValue = ctx.value;
        
        let signedOrder: SignedOrder = SignedOrder.fromCell(msg.signedOrder);
        let order: Order = Order.fromCell(signedOrder.order);

        throwIf(ERR_SIG_INVALID_PREFIX, signedOrder.prefix != 0x75569022);
        throwIf(ERR_SIG_INVALID_SCHEMA, signedOrder.schemaHash != SCHEMA_HASH);
        throwIf(ERR_SIG_INVALID_DOMAIN, signedOrder.domain.hash() != DOMAIN_HASH);

        // @dev: The order maker cannot purchase their own ticket.
        throwIf(ERR_INVALID_SENDER, buyer == order.maker);

        let eventAddress = myAddress();
        throwIf(ERR_INVALID_EVENT_ADDRESS, eventAddress != order.eventAddress);
        throwIf(ERR_INVALID_TICKET_TYPE, order.ticketType >= self.prices.length);

        throwIf(ERR_ORDER_NOT_LISTED, now() < order.listingTime);
        throwIf(ERR_ORDER_EXPIRED, now() > order.expirationTime);

        let ticketOriginalPrice = self.prices.getIndex(order.ticketType);

        throwIf(ERR_INVALID_TICKET_PRICE, ticketOriginalPrice > order.ticketPrice);
        throwIf(ERR_INVALID_MSG_VALUE, msgValue <
            order.ticketPrice + 
            TODO_MSG_FEE + 
            2 * TODO_FWD_FEE
        );

        let dataCellHash = signedOrder.toCell().hash();

        throwIf(ERR_ORDER_FILLED, self.marketplaceFilledOrders.get(dataCellHash) != null);
        throwIf(ERR_ORDER_CANCELED, self.marketplaceCanceledOrders.get(dataCellHash) != null);

        // TODO: Return change 
        /*if(msgValue > ticketPrice + TODO_FEE) {
            send(SendParameters{
                to: buyer,
                value: ton("1") // TODO: REALLY CAREFUL: msgValue - ticketPrice
            });
        }*/

        // Calculate royalties
        let totalRoyalties = 0;

        let i = 0;
        let m = self.resellRoyaltyCollectors.length;
        while(i < m) {
            let collector: RoyaltyCollector = self.resellRoyaltyCollectors.getCollectorByIndex(i);
            let collectorEarned = (order.ticketPrice * collector.royaltyFee) / 10000;

            let previousBalance = self.royaltiesEarned.get(collector.collectorAddress)!!;
            self.royaltiesEarned.set(collector.collectorAddress, previousBalance + collectorEarned);

            totalRoyalties += collectorEarned;
            i += 1;
        }

        let previousBalance = self.royaltiesEarned.get(self.owner)!!;
        self.royaltiesEarned.set(self.owner, previousBalance + (order.ticketPrice - totalRoyalties));

        // Send funds to maker
        send(SendParameters{
            to: order.maker,
            value: TODO_FWD_FEE + order.ticketPrice - totalRoyalties
        });

        // @dev: Implicitly verifies that order.maker is the owner of the (ticketId, ticketType) and that the ticket has not been redeemed
        send(SendParameters{
            to: contractAddress(initOf Ticket(
                eventAddress,
                msg.firstOwner,
                order.ticketId,
                order.ticketType,
                false,
                self.composeTicketMetadata(order.ticketId),
                ZERO_ADDRESS
            )),
            value: TODO_FWD_FEE,
            body: MarketplaceTransfer {
                queryId: msg.queryId,
                previousOwner: order.maker,
                newOwner: buyer,
            }.toCell()
        });

        self.marketplaceFilledOrders.set(dataCellHash, true);
    }

    receive(msg: CancelOrder) {
        let res = checkSignature(
            msg.signedOrder.hash(),
            msg.signature.beginParse(),
            msg.publicKey
        );
        throwIf(ERR_INVALID_SIGNATURE, !res);

        let ctx: Context = context();
        let signedOrder: SignedOrder = SignedOrder.fromCell(msg.signedOrder);

        throwIf(ERR_INVALID_MSG_VALUE, ctx.value <
            3 * TODO_FWD_FEE
        );

        // @dev: Only the order maker cancels their own order.
        throwIf(ERR_INVALID_SENDER, ctx.sender != Order.fromCell(signedOrder.order).maker);

        let dataCellHash = signedOrder.toCell().hash();

        throwIf(ERR_ORDER_CANCELED, self.marketplaceCanceledOrders.get(dataCellHash) != null);

        self.marketplaceCanceledOrders.set(dataCellHash, true);
    }

    receive(msg: WithdrawRoyalty) {
        throwIf(ERR_INVALID_MSG_VALUE, context().value <
            TODO_FWD_FEE
        );
        self.withdrawRoyalty(sender()/*, msg.amount*/);
    }

    receive(msg: WithdrawRoyaltyFor) {
        let ctx: Context = context();
        throwIf(ERR_INVALID_MSG_VALUE, ctx.value <
            TODO_FWD_FEE
        );
        throwIf(ERR_INVALID_SENDER, ctx.sender != self.owner);       
        self.withdrawRoyalty(msg.collector/*, msg.amount*/);
    }

    fun withdrawRoyalty(collector: Address/*, amount: Int*/) {
        let royaltyCollected = self.royaltyCollected(collector);

        // TODO
        //throwIf(ERR_INVALID_AMOUNT, amount > royaltyCollected);
        //self.royaltiesEarned.set(collector, royaltyCollected - amount);

        self.royaltiesEarned.set(collector, 0); // TODO: delete

        send(SendParameters{
            to: collector,
            value: royaltyCollected
        });
    }

    get fun royaltyCollected(collector: Address): Int {
        return self.royaltiesEarned.exists(collector) ? self.royaltiesEarned.get(collector)!! : 0;
    }

    fun getTotalValueOfCards(ticketTypes: Array): Int {
        let n = ticketTypes.length;
        let totalValueOfCards = 0;
        let i = 0;

        while(i < n) {
            let ticketType = ticketTypes.getIndex(i);
            
            // TODO: Test this
            // Revert if the there are no more tickets with current ticketType
            throwIf(ERR_OUT_OF_STOCK, self.amounts.getIndex(ticketType) == 0);

            self.amounts.decrementIndex(ticketType);
            totalValueOfCards += self.prices.getIndex(ticketType);

            i += 1;
        }
        return totalValueOfCards;
    }

    fun composeTicketMetadata(ticketId: Int): Cell {
        let nameOfTicket = beginTailString();
        nameOfTicket.append(self.name);
        nameOfTicket.append(" ID: ");
        nameOfTicket.append(ticketId.toString());

        let imageUri = beginTailString();
        imageUri.append(self.baseUri);
        imageUri.append(ticketId.toString());
        imageUri.append(".json");

        let dict: map<Int as uint256, Cell> = emptyMap();

        dict.set(sha256("name"), nameOfTicket.toCell());
        //dict.set(sha256("description"), description.asMetadataCell());
        dict.set(sha256("image"), imageUri.toCell());

        return beginCell()
            .storeUint(0, 8)
            .storeRef(dict.asCell()!!)
            .endCell();
    }

    get fun priceForTicketStorage(amountOfSeconds: Int): Int {
        return getStorageFee(T_NO_CELLS, T_NO_BITS, amountOfSeconds, false);
    }

    get fun name(): String {
        return self.name;
    }

    get fun amount(ticketType: Int): Int {
        return self.amounts.getIndex(ticketType);
    }

    get fun price(ticketType: Int): Int {
        return self.prices.getIndex(ticketType);
    }

    get fun nextTicketIndex(): Int {
        return self.nextTicketIndex;
    }
}

inline fun deployTicket(
    eventAddress: Address,
    ownerAddress: Address,
    ticketId: Int,
    ticketType: Int,
    startingTicketBalance: Int,
    metadata: Cell
) {
    let ticketCode = codeOf Ticket;
    let ticketData = beginCell()
        .storeAddress(eventAddress)
        .storeAddress(ownerAddress)
        .storeUint(ticketId, 32)
        .storeUint(ticketType, 8)
        .storeBool(false)
        .storeRef(metadata)
        .storeAddress(ZERO_ADDRESS)
        .endCell();

    deploy(DeployParameters{
        init: StateInit { code: ticketCode, data: ticketData },
        mode: SendPayFwdFeesSeparately,
        value: startingTicketBalance
    });
}