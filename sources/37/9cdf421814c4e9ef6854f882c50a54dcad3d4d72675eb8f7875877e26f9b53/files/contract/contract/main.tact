import "@stdlib/deploy";

message Withdraw { 
        queryId: Int as uint64; 
        }

        message TokenTransfer {
            queryId: Int as uint64;
                amount: Int as uint128;
                    destination: Address;
                        notify: Bool;
                            payload: Cell?;
                            }

                            const ONE_TON: Int = 1_000_000_000;
                            const TOKEN_AMOUNT: Int = 1000;

                            contract Cashback {
                                owner: Address;
                                    tokenWallet: Address;
                                        
                                            init(owner: Address, tokenWallet: Address) {
                                                    self.owner = owner;
                                                            self.tokenWallet = tokenWallet;
                                                                }
                                                                    
                                                                        receive() {
                                                                                let incoming: Int = context().value;
                                                                                        let sender: Address = context().sender;
                                                                                                require(incoming == ONE_TON, "Send exactly 1 TON");
                                                                                                        
                                                                                                                let transferBody: Cell = beginCell()
                                                                                                                            .storeUint(0xf8a7ea5, 6)
                                                                                                                                        .storeUint(TOKEN_AMOUNT, 64)
                                                                                                                                                    .storeAddress(sender)
                                                                                                                                                                .storeAddress(self.owner)
                                                                                                                                                                            .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
                                                                                                                                                                                        .storeCoins(0)
                                                                                                                                                                                                    .endCell();
                                                                                                                                                                                                            
                                                                                                                                                                                                                    send(SendParameters{
                                                                                                                                                                                                                                to: self.tokenWallet,
                                                                                                                                                                                                                                            value: 0,
                                                                                                                                                                                                                                                        bounce: true,
                                                                                                                                                                                                                                                                    mode: 64,
                                                                                                                                                                                                                                                                                body: transferBody
                                                                                                                                                                                                                                                                                        });
                                                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                                                    receive(msg: Withdraw) {
                                                                                                                                                                                                                                                                                                            require(context().sender == self.owner, "Not authorized: only owner can withdraw");
                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                            send(SendParameters{
                                                                                                                                                                                                                                                                                                                                        to: self.owner,
                                                                                                                                                                                                                                                                                                                                                    value: 0,
                                                                                                                                                                                                                                                                                                                                                                bounce: false,
                                                                                                                                                                                                                                                                                                                                                                            mode: 128
                                                                                                                                                                                                                                                                                                                                                                                    });
                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                                                                                                                                get fun getOwner(): Address {
                                                                                                                                                                                                                                                                                                                                                                                                        return self.owner;
                                                                                                                                                                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                                                                                                                                                                    get fun getTokenWallet(): Address {
                                                                                                                                                                                                                                                                                                                                                                                                                            return self.tokenWallet;
                                                                                                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                                                                                                                }
