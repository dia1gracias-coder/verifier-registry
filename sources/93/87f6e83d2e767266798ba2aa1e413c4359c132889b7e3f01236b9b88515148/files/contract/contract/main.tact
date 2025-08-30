import "@stdlib/deploy";

contract JettonMaster with Deployable {
    owner: Address;
        totalSupply: Int as coins;
            
                init(owner: Address) {
                        self.owner = owner;
                                self.totalSupply = 0;
                                    }
                                        
                                            // فقط مالک می‌تواند Mint کند
                                                fun mint(amount: Int, destination: Address) {
                                                        require(context().sender == self.owner, "Only owner can mint");
                                                                
                                                                        self.totalSupply = self.totalSupply + amount;
                                                                                
                                                                                        // ارسال Jetton به مقصد
                                                                                                send(SendParameters{
                                                                                                            to: destination,
                                                                                                                        value: ton("0.05"),
                                                                                                                                    body: beginCell()
                                                                                                                                                    .storeUint(0x7362d09c, 32) // internal_transfer
                                                                                                                                                                    .storeUint(0, 64) // query_id
                                                                                                                                                                                    .storeCoins(amount)
                                                                                                                                                                                                    .storeAddress(self.owner)
                                                                                                                                                                                                                    .storeAddress(destination)
                                                                                                                                                                                                                                    .storeMaybeRef(null) // no custom_payload - بدون پرانتز
                                                                                                                                                                                                                                                    .storeCoins(0) // no forward_ton_amount
                                                                                                                                                                                                                                                                    .storeMaybeRef(null) // no forward_payload - بدون پرانتز
                                                                                                                                                                                                                                                                                    .endCell()
                                                                                                                                                                                                                                                                                            });
                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                        // دریافت تراکنش
                                                                                                                                                                                                                                                                                                            receive() {
                                                                                                                                                                                                                                                                                                                    // فقط پرداخت‌های TON را قبول می‌کند
                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                        }