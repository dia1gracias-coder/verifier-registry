import "./structs_trinity";
import "./ft_user_main";
import "./ft_trinity_program_user";

trait FtTrinityUserGetters {
    id: Int as uint64;
    owner: Address?;
    program: Address;
    master: Address;

    autoUpgrade: Bool;
    autoWithdraw: Bool;

    invitedId: Int as uint64;
    invitedAddress: Address?;

    canClaim: Int as coins;
    lastLevel: Int as uint8;
    overtakeInfo: map<Int as uint8, Int as uint16>;
    levelInfo: map<Int as uint8, TrinityInfo>;
    spentForActivate: Int as coins;

    autoActivatingFee: Int as coins;

    activating: Bool;
    activatingLevelPrice: map<Int as uint8, Int as coins>;
    autoActivatingLevelPrice: map<Int as uint8, Int as coins>;
    activatingLevelFees: map<Int as uint8, Int as coins>;

    finishActivatingLevel: Int as uint8;

    get fun id(): Int {
        return self.id;
    }

    get fun invitedId(): Int {
        return self.invitedId;
    }

    get fun owner(): Address? {
        return self.owner;
    }

    get fun master(): Address {
        return self.master;
    }

    get fun autoUpgrade(): Bool {
        return self.autoUpgrade;
    }

    get fun autoWithdraw(): Bool {
        return self.autoWithdraw;
    }

    get fun canClaim(): Int {
        return self.canClaim;
    }

    get fun lastLevel(): Int {
        return self.lastLevel;
    }

    get fun spentForActivate(): Int {
        return self.spentForActivate;
    }

    get fun activating(): Bool {
        return self.activating;
    }

    get fun autoActivatingFee(): Int {
        return self.autoActivatingFee;
    }

    get fun activatingLevelPrice(): map<Int as uint8, Int as coins> {
        return self.activatingLevelPrice;
    }

    get fun autoActivatingLevelPrice(): map<Int as uint8, Int as coins> {
        return self.autoActivatingLevelPrice;
    }

    get fun activatingLevelFees(): map<Int as uint8, Int as coins> {
        return self.activatingLevelFees;
    }

    get fun info(level: Int): TrinityInfo {
        return self.levelInfo.get(level)!!;
    }

    get fun allInfo(): map<Int as uint8, TrinityInfo> {
        return self.levelInfo;
    }

    get fun overtakeInfo(): map<Int as uint8, Int as uint16> {
        return self.overtakeInfo;
    }

    get fun balance(): Int {
        return myBalance();
    }

     get fun userMainAddress(id: Int): Address {
        let init: StateInit = initOf FtUserMain(id, self.master);
        return contractAddress(init);
    }

    get fun programUserAddress(id: Int): Address {
        let init: StateInit = initOf FtTrinityProgramUser(id, self.program);
        return contractAddress(init);
    }

    get fun programUserInit(id: Int): StateInit {
        return initOf FtTrinityProgramUser(id, self.program);
    }

    get fun matrixPlaces(level: Int): map<Int as uint8, Place> {
        let levelInfo: TrinityInfo = self.levelInfo.get(level)!!;
        return levelInfo.matrix.places;
    }
}
