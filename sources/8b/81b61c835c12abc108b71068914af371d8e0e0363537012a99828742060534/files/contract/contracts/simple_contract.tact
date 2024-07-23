import "@stdlib/deploy";


message Add {
    amount : Int as uint32;
}




contract SimpleContract with Deployable {
    // Empty init() function is present by default in all Tact contracts
    // since v1.3.0, so the following may be omitted:
    //

    owner:Address;
    counter : Int as uint32;
     init(owner:Address) {
        self.owner = owner;
        self.counter = 0;
     }

     fun add (v:Int){
        let ctx:Context = context();
        require(ctx.sender == self.owner ,"Invalid sender");
        self.counter = self.counter + v;
     }

    receive (msg: Add){
        self.add(msg.amount);
    }

    receive("increment"){
        self.add(1);
        self.reply("incremented".asComment());
    }

     get fun counter(): Int {
        return self.counter;
    }

}

