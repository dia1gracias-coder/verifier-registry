import "@stdlib/deploy";
import "@stdlib/ownable";
import "./utilities.fc";

asm fun setRandomSeed(seed: Int) { SETRAND }

@name(get_sbt_item_code)
native getSbtItemCode(): Cell;

asm fun cellHash(cell: Cell): Int { HASHCU }

inline fun getStateInit(index: Int): Cell {
    let data = beginCell().storeUint(index, 64).storeSlice(address("EQDKwL0-xRmlucApdVCADF2e7spGsYmrldMwHc_tyewulFys").asSlice()).endCell(); //TODO replace collection address.
    return beginCell().storeUint(0, 2).storeMaybeRef(getSbtItemCode()).storeMaybeRef(data).storeUint(0, 1).endCell();
}

inline fun calculateNftAddressByIndex(index: Int): Slice {
    return beginCell()
        .storeUint(4, 3)
        .storeInt(0, 8) //Since our nft collection is in mainnet
        .storeUint(cellHash(getStateInit(index)), 256)
        .endCell()
        .beginParse();
}

asm extends fun storeIntAsString(self: Builder, x: Int): Builder {
    ZERO SWAP
    UNTIL:<{
    10 PUSHINT DIVMOD
    48 ADDCONST
    s2 XCHG0
    s2 s3 XCHG
    INC SWAP
    DUP ISZERO
    }> DROP
    REPEAT:<{ 8 STU }>
}

message(0x1703470F) StartRaffle {
    seed: Int as uint256;
    groupNumber: Int as uint22; //Should be 0 in the beginning.
    totalParticipants: Int as uint32;
    groupSizes: Slice as remaining; // List of 31-bit integers - number of groups.
    //For now there will be no ref in body, so max number of groups is 23.
}

contract Raffle with Deployable {

    winners: map<Int as uint31, Bool>; //More like a set<uint31>, but set<> does not introduced yet.

    receive(msg: StartRaffle) {
        let sender = sender();
        require(sender == address("EQBGhqLAZseEqRXz4ByFPTGV7SVMlI4hrbs-Sps_Xzx01x8G") || //Deployer in sandbox
                sender == address("UQBXZb9T1PHZGuKUaAUhgV_BTV8zgxYJlxts99WmEX8DFfKU") ||
                sender == address("UQBOseInfo2uq2FNj1E-H3dBYehY4THCrEEc7lAxB_Q0Zp6s") ||
                sender == address("UQAQB9mDGk0CzF4lEwdNsCu2CtWSbMdqUZgajNUAxUYVl-iC") ||
                sender == myAddress(), "Only owner can start raffle");

        //require(context().value > ton("0.4"), "Not enough TONs");
        setRandomSeed(msg.seed);

        let groupSize: Int = msg.groupSizes.loadUint(31);
        let totalWinners: Int = 0;
        while(groupSize > 0) {
            let winnersInGroup: Int = 0;
            while(winnersInGroup < groupSize && totalWinners < 90) {
                let winner: Int = nativeRandomInterval(msg.totalParticipants);

                if (!self.winners.exists(winner)) {
                    self.winners.set(winner, true);
                    winnersInGroup += 1;
                    totalWinners += 1;
                    nativeSendMessage(beginCell()
                        .storeUint(0x10, 6)
                        .storeSlice(calculateNftAddressByIndex(winner))
                        .storeUint(179102859875699067105458737377207153344905216, 151)
                        .storeSlice("Winner - ".asSlice())
                        .storeIntAsString(msg.groupNumber + 1)
                        .storeSlice(" group".asSlice())
                    .endCell(), SendPayGasSeparately);
                }
            }
            if(winnersInGroup < groupSize) {
                send(SendParameters{
                    to: myAddress(),
                    value: context().value - ton("0.4"),
                    bounce: false,
                    mode: 0, //TODO add gas consumption here
                    body: StartRaffle{
                        seed: nativeRandom(),
                        totalParticipants: msg.totalParticipants,
                                                        //Store remaining amout of winners in group
                        groupSizes: beginCell().storeUint(groupSize - winnersInGroup, 31).storeSlice(msg.groupSizes).endCell().beginParse(),
                        groupNumber: msg.groupNumber
                    }.toCell()
                });
                return;
            }
            msg.groupNumber += 1;
            if(msg.groupSizes.bits() == 0) {
                msg.groupSizes = msg.groupSizes.loadRef().beginParse();
            }
            groupSize = msg.groupSizes.loadUint(31);
        }
        self.winners = emptyMap();
    }
    receive("Clear cache") {
        let sender = sender();
        require(sender == address("UQBXZb9T1PHZGuKUaAUhgV_BTV8zgxYJlxts99WmEX8DFfKU") ||
                sender == address("UQBOseInfo2uq2FNj1E-H3dBYehY4THCrEEc7lAxB_Q0Zp6s") ||
                sender == address("UQAQB9mDGk0CzF4lEwdNsCu2CtWSbMdqUZgajNUAxUYVl-iC") ||
                sender == myAddress(), "Only owner can clearCache");
        self.winners = emptyMap();
    }
}

