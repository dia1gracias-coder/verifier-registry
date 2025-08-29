import "@stdlib/deploy";

contract PaymentReceiver with Deployable {
    owner: Address;
        
            init(owner: Address) {
                    self.owner = owner;
                        }
                            
                                receive(msg: String) {
                                        let amount = context().value;
                                                send(SendParameters{
                                                            to: self.owner,
                                                                        value: amount,
                                                                                    bounce: false,
                                                                                                mode: SendIgnoreErrors
                                                                                                        });
                                                                                                            }
                                                                                                                
                                                                                                                    receive() {
                                                                                                                            let amount = context().value;
                                                                                                                                    send(SendParameters{
                                                                                                                                                to: self.owner,
                                                                                                                                                            value: amount,
                                                                                                                                                                        bounce: false,
                                                                                                                                                                                    mode: SendIgnoreErrors
                                                                                                                                                                                            });
                                                                                                                                                                                                }
                                                                                                                                                                                                }