import "@stdlib/deploy";

import "./tournament.tact";

message JoinTournament {
    initData: TournamentInitData;
    nonce: Int as uint64;
}

contract TournamentFactory with Deployable {
    elympicsTreasury: Address;
    elympicsCommission: Int as uint32;

    init(elympicsTreasury: Address, elympicsCommission: Int) {
        require(elympicsCommission < SHARE_PRECISION, "Commission too high");
        self.elympicsTreasury = elympicsTreasury;
        self.elympicsCommission = elympicsCommission;
    }

    receive(msg: JoinTournament) {
        let computeFees: Int = (msg.initData.rewardDistributionPercents.length * INIT_FEE_PER_PLAYER) + (2 * REGISTER_USER_FEE_BASE);
        require(context().value > msg.initData.entryFee + computeFees, "Insufficient value sent");
        let init: StateInit = initOf Tournament(msg.initData);
        let address: Address = contractAddress(init);
        send(
            SendParameters{
                to: address,
                value: 0,
                mode: SendRemainingValue,
                code: init.code,
                data: init.data,
                body: RegisterUser{userAddress: sender(), nonce: msg.nonce}.toCell(),
            }
        );
    }
}
