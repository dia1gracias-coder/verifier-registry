import "@stdlib/deploy";

contract Shop with Deployable {
 owner: Address;
 destination: Address;

    init(owner: Address) {
        self.owner = owner;
        self.destination = address("0QDOy2aKr65PC0Bx3KWN534ftQgMaz2WT7Fb-Ay1NDpWZ-7p")
    }

       fun setReceiver(newReceiver: Address) {
        let ctx: Context = context();
        
        require(ctx.sender == self.owner, "Only the owner can set the receiver");
        self.destination = newReceiver;
    }


    fun sendMoney(amount: Int) {
        send(SendParameters{
            to: self.destination,        
            value: amount,         
            mode: 1,                
            bounce: true          
        });
    }

    receive() {
        send(SendParameters{
            to: sender(),      
            value: 0,       
            body: "Reply: Hello!".asComment(),
        });
    }
}
