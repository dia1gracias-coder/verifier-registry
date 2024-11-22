import "@stdlib/deploy";
import "@stdlib/ownable";

// Structures
struct Event {
    id: Int;
    creator: Address;
    name: String;
    date: Int;
    ticketPrice: Int;
    maxTickets: Int;
    ticketsSold: Int;
    isActive: Bool;
}

struct Ticket {
    id: Int;
    eventId: Int;
    owner: Address;
    purchaseDate: Int;
    isUsed: Bool;
}

// Messages for contract interaction
message CreateEvent {
    name: String;
    date: Int;
    ticketPrice: Int;
    maxTickets: Int;
}

message BuyTicket {
    eventId: Int;
}

message UseTicket {
    ticketId: Int;
}

message DeactivateEvent {
    eventId: Int;
}

contract SecureTon with Deployable{
    // State variables
    events: map<Int,Event>;
    tickets: map<Int,Ticket>;
    nextEventId: Int;
    nextTicketId: Int;
    
    init() {
        self.nextEventId = 0;
        self.nextTicketId = 0;
        self.events = emptyMap();
        self.tickets = emptyMap();
    }

    // Create new event
    receive(msg: CreateEvent) {
        // Validate inputs
        require(msg.date > now(), "Event date must be in future");
        require(msg.ticketPrice >= 0, "Ticket price must be >= 0");
        require(msg.maxTickets > 0, "Max tickets must be > 0");
        
        // Create new event
        let newEvent: Event = Event{
            id: self.nextEventId,
            creator: sender(),
            name: msg.name,
            date: msg.date,
            ticketPrice: msg.ticketPrice,
            maxTickets: msg.maxTickets,
            ticketsSold: 0,
            isActive: true
        };
        
        // Store event
        self.events.set(self.nextEventId, newEvent);
        self.nextEventId = self.nextEventId + 1;
    }

    // Buy ticket
    receive(msg: BuyTicket) {
        // Get event
        let event: Event = self.events.get(msg.eventId)!!;
        
        // Validate event status
        require(event.isActive, "Event is not active");
        require(event.ticketsSold < event.maxTickets, "Event is sold out");
        require(context().value >= event.ticketPrice, "Insufficient payment");
        
        // Create new ticket
        let newTicket: Ticket = Ticket{
            id: self.nextTicketId,
            eventId: msg.eventId,
            owner: sender(),
            purchaseDate: now(),
            isUsed: false
        };
        
        // Update event and store ticket
        event.ticketsSold = event.ticketsSold + 1;
        self.events.set(msg.eventId, event);
        self.tickets.set(self.nextTicketId, newTicket);
        
        // Send payment to event creator
        send(SendParameters{
            to: event.creator,
            value: event.ticketPrice,
            mode: SendPayGasSeparately
        });
        
        self.nextTicketId = self.nextTicketId + 1;
    }

    // Use ticket
    receive(msg: UseTicket) {
        // Get ticket
        let ticket: Ticket = self.tickets.get(msg.ticketId)!!;
        
        // Validate ticket
        require(!ticket.isUsed, "Ticket already used");
        
        // Mark ticket as used
        ticket.isUsed = true;
        self.tickets.set(msg.ticketId, ticket);
    }

    // Deactivate event (only creator can deactivate)
    receive(msg: DeactivateEvent) {
        let event: Event = self.events.get(msg.eventId)!!;
        require(event.creator == sender(), "Only creator can deactivate");
        
        event.isActive = false;
        self.events.set(msg.eventId, event);
    }

    // Getter functions
    get fun event(eventId: Int): Event {
        return self.events.get(eventId)!!;
    }

    get fun ticket(ticketId: Int): Ticket {
        return self.tickets.get(ticketId)!!;
    }

    // Verify ticket ownership
    get fun verifyTicket(ticketId: Int, userAddress: Address): Bool {
        let ticket: Ticket = self.tickets.get(ticketId)!!;
        return (ticket.owner == userAddress) && (!ticket.isUsed);
    }

    // Get active events
    get fun getActiveEvents(): map<Int,Event> {
        let activeEvents: map<Int,Event> = emptyMap();
        let id:Int = 0;
        repeat(self.nextEventId) {
            let event: Event = self.events.get(id)!!;
            if (event.isActive) {
                activeEvents.set(id, event);
            }
            id+=1;
        }
        
        return activeEvents;
    }
}