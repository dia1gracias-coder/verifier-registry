import "@stdlib/deploy";
import "./raffle-instance";

message CreateRaffle {
    duration: Int as uint32;
    salt: Int as uint256;
}

message RaffleCreated {
    raffle: Address;
    creator: Address;
    endsAt: Int as uint64;
}

contract TON5050Master with Deployable {

    platformWallet: Address;
    raffleCount: Int as uint32;
    creationFee: Int as coins;

    init(platformWallet: Address) {
        self.platformWallet = platformWallet;
        self.raffleCount = 0;
        self.creationFee = ton("10");
    }

    receive(msg: CreateRaffle) {
        let ctx: Context = context();

        require(ctx.value >= self.creationFee, "Must send 10 TON creation fee");
        require(msg.duration >= 300, "Minimum raffle duration is 5 minutes (300s)");
        require(msg.duration <= 31536000, "Maximum raffle duration is 1 year (31536000s)");

        let raffleInit: StateInit = initOf RaffleInstance(
            myAddress(),
            ctx.sender,
            now() + msg.duration,
            msg.salt
        );
        let raffleAddr: Address = contractAddress(raffleInit);

        send(SendParameters{
            to: self.platformWallet,
            value: self.creationFee,
            mode: SendPayGasSeparately | SendIgnoreErrors,
            body: "TON5050 creation fee".asComment()
        });

        send(SendParameters{
            to: raffleAddr,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            bounce: false,
            code: raffleInit.code,
            data: raffleInit.data,
            body: "deploy".asComment()
        });

        self.raffleCount += 1;

        emit(RaffleCreated{
            raffle: raffleAddr,
            creator: ctx.sender,
            endsAt: now() + msg.duration
        }.toCell());
    }

    get fun platformWallet(): Address {
        return self.platformWallet;
    }

    get fun raffleCount(): Int {
        return self.raffleCount;
    }

    get fun creationFee(): Int {
        return self.creationFee;
    }
}
