import "@stdlib/ownable";
import "@stdlib/deploy";

import "./messages.tact";
import "./ft_user_storage.tact";

contract FtUserMain with Deployable, Ownable {
    const minTonsForStorage: Int = ton("0.1");
    owner: Address;
    master: Address;
    joinAt: Int;

    id: Int as uint64;
    invitedId: Int as uint64 = 0;
    referralCount: Int as uint32 = 0;

    programs: map<Int as uint8, Address> = emptyMap();

    init(id: Int, master: Address){
        self.id = id;
        self.owner = sender();
        self.master = master;
        self.joinAt = now();
    }

    receive(msg: SetupUserMain){
        nativeThrowUnless(132, sender() == self.userStorageAddress(msg.owner));
        nativeReserve(self.minTonsForStorage, 0);

        self.owner = msg.owner;
        self.invitedId = msg.invitedId;
        self.programs = msg.programs;

        self.addReferral();
        self.buy(0, 1, msg.owner);
    }

    receive(msg: AddReferral){
        nativeThrowUnless(132, sender() == self.userMainAddress(msg.userId));
        self.referralCount += 1;
        commit();
        
        send(SendParameters{
            to: msg.userAddress,
            value: 0,
            mode: SendIgnoreErrors | SendRemainingValue,
            body: "Excesses".asComment(),
        });
    }

    receive(msg: Buy){
        nativeThrowUnless(131, self.programs.get(msg.programId) != null);
        nativeReserve(self.minTonsForStorage, 0);
        self.buy(msg.programId, msg.levelNumber, sender());
    }

    receive("UpdatePrograms"){
        send(SendParameters{
            to: self.master,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: "GetProgramAddresses".asComment()
        });
    }

    receive(msg: GetInvitedId) {
        self.reply(UpdateInvitedId{
            invitedId: self.invitedId,
            forwardPayload: msg.forwardPayload
        }.toCell());
    }

    receive(msg: ProgramAddresses){
        nativeThrowUnless(132, sender() == self.master);
        self.programs = msg.programs;
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: "Excesses".asComment()
        });
    }

    // ------------------ Private Function  ------------------ //

    fun buy(programId: Int, levelNumber: Int, recipientExcesses: Address){
        send(SendParameters{
            to: self.programs.get(programId)!!,
            value: 0,
            mode: SendRemainingBalance | SendPayFwdFeesSeparately,
            body: BuyLevel{
                owner: self.owner,
                userId: self.id,
                invitedId: self.invitedId,
                levelNumber: levelNumber,
                recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    fun addReferral(){
        send(SendParameters{
            to: self.userMainAddress(self.invitedId),
            value: ton("0.05"),
            mode: SendIgnoreErrors | SendPayFwdFeesSeparately,
            body: AddReferral {
                userId: self.id,
                userAddress: self.owner
            }.toCell()
        });
    }

    // ------------------ Get Function  ------------------ //

    get fun id(): Int {
        return self.id;
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun invitedId(): Int? {
        return self.invitedId;
    }

    get fun referralCount(): Int {
        return self.referralCount;
    }

    get fun programs(): map<Int as uint8, Address> {
        return self.programs;
    }

    get fun userMainAddress(id: Int): Address{
        let init: StateInit = initOf FtUserMain(id, self.master);
        return contractAddress(init);
    }

    get fun userStorageAddress(address: Address): Address{
        let init: StateInit = initOf FtUserStorage(address, self.master);
        return contractAddress(init);
    }

    get fun joinAt(): Int {
        return self.joinAt;
    }
}
