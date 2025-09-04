import "@stdlib/deploy";

message Withdraw { queryId: Int as uint64; }

const ONE_TON: Int = 1_000_000_000;
const PAYOUT:  Int = 200_000_000;

contract Cashback {
    owner: Address;

        init(owner: Address) {
                self.owner = owner;
                    }

                        receive() {
                                let incoming: Int = context().value;
                                        let sender: Address = context().sender;
                                                require(incoming == ONE_TON, "send exactly 1 TON");
                                                        
                                                                send(SendParameters{
                                                                            to: sender,
                                                                                        value: PAYOUT,
                                                                                                    bounce: true,
                                                                                                                mode: SendPayGasSeparately
                                                                                                                        });
                                                                                                                            }

                                                                                                                                receive(msg: Withdraw) {
                                                                                                                                        require(context().sender == self.owner, "not owner");
                                                                                                                                                send(SendParameters{
                                                                                                                                                            to: self.owner,
                                                                                                                                                                        value: 0,
                                                                                                                                                                                    bounce: false,
                                                                                                                                                                                                mode: 128 // SendAllRemaining
                                                                                                                                                                                                        });
                                                                                                                                                                                                            }

                                                                                                                                                                                                                get fun getOwner(): Address {
                                                                                                                                                                                                                        return self.owner;
                                                                                                                                                                                                                            }
                                                                                                                                                                                                                            }