import "@stdlib/ownable";
import "./pot_game";

message(0x1cc071ad) NewPot {
    nonce: Int as uint32;
    creator: Address;
    creatorTelegramId: Int as uint64;
    description: String;
    imageLink: String;
    tokenAddress: Address;
    initialPrize: Int as coins;
    timer: Int as uint32;
    ticketPrice: Int as coins;
    ticketPriceStaticIncrease: Int as coins;
    ticketPricePercentIncrease: Int as uint8;
    lastPlayersWinnersCount: Int as uint8;
    randomWinnersCount: Int as uint8;
    lastPlayersPercent: Int as uint8;
    randomWinnersPercent: Int as uint8;
    referrerPercent: Int as uint8;
    creatorPercent: Int as uint8;
    burnPercent: Int as uint8;
}

message(0x2d800d4a) UpdatePubKey {
    pubKey: Int as uint256;
}

message(0x2b4b04b3) UpdateGnomeTreasury {
    gnomeTreasury: Address;
}

message(0xcb140e63) UpdateGnomeCommission {
    gnomeCommission: Int as coins;
}

contract PotFactory with OwnableTransferable {

    id: Int as uint32;
    seqno: Int as uint32 = 10;
    pubKey: Int as uint256;
    owner: Address;
    gnomeTreasury: Address;
    gnomeCommission: Int as coins;

    init(id: Int, pubKey: Int, gnomeTreasury: Address, gnomeCommission: Int){
        self.id = id;
        self.owner = context().sender;
        self.pubKey = pubKey;
        self.gnomeTreasury = gnomeTreasury;
        self.gnomeCommission = gnomeCommission;
    }

    receive(deploy: Deploy) {
        //do nothing
    }

    receive(msg: UpdatePubKey){
        self.requireOwner();
        self.pubKey = msg.pubKey;
    }

    receive(msg: UpdateGnomeTreasury){
        self.requireOwner();
        self.gnomeTreasury = msg.gnomeTreasury;
    }

    receive(msg: UpdateGnomeCommission){
        self.requireOwner();
        self.gnomeCommission = msg.gnomeCommission;
    }

    receive(msg: NewPot) {
        let stateInit: StateInit = initOf PotGame(
            self.seqno,
            msg.nonce,
            msg.creator,
            msg.creatorTelegramId,
            msg.description,
            msg.imageLink,
            msg.tokenAddress,
            self.pubKey,
            msg.timer,
            msg.initialPrize,
            msg.ticketPrice,
            msg.ticketPriceStaticIncrease,
            msg.ticketPricePercentIncrease,
            msg.lastPlayersWinnersCount,
            msg.randomWinnersCount,
            msg.lastPlayersPercent,
            msg.randomWinnersPercent,
            msg.referrerPercent,
            msg.creatorPercent,
            msg.burnPercent,
            self.gnomeTreasury,
            self.gnomeCommission,
        );

        send(SendParameters{
            to: contractAddress(stateInit),
            value: ton("0.4"),
            mode: SendPayGasSeparately,
            code: stateInit.code,
            data: stateInit.data,
            bounce: false,
            body: Deploy{ queryId: self.seqno }.toCell()
        });

        self.seqno += 1;
    }

    get fun seqno(): Int {
        return self.seqno;
    }

    get fun pubKey(): Int {
        return self.pubKey;
    }

    get fun gnomeTreasury(): Address {
        return self.gnomeTreasury;
    }
}