// Message triggering end of round
message EndRound { 
    tonPrice: Int as uint32;
    jettonPrice: map<Address, Int as uint32>;
}