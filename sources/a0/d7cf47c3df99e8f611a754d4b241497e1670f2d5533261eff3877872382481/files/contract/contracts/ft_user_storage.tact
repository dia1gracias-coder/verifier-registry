import "@stdlib/deploy";
import "./messages.tact";

import "./ft_user_main.tact";

contract FtUserStorage with Deployable {
    const minTonsForStorage: Int = ton("0.01");

    id: Int? as uint64;
    master: Address;
    owner: Address;

    init(owner: Address, master: Address) {
        nativeThrowUnless(132, sender() == master);

        self.master = master;
        self.owner = owner;
    }

    receive(msg: SetupUserStorage) {
        self.requireMaster();
        self.id = msg.userId;
        nativeReserve(self.minTonsForStorage, 0);

        let init: StateInit = initOf FtUserMain(msg.userId, self.master);
        send(SendParameters{
            to: contractAddress(init),
            value: 0,
            mode: SendRemainingBalance,
            body: msg.forwardPayload,
            code: init.code,
            data: init.data
        });
    }

    receive(msg: VerifyExistence) {
        self.requireMaster();
        nativeReserve(self.minTonsForStorage, 0);

        if (self.id != null) {
            self.sendAlreadyJoinedMessage();
        } else {
            self.registerUser(msg.invitedId);
        }
    }

    // ------------------ Private Function  ------------------ //

    fun registerUser(invitedId: Int) {
        send(SendParameters{
            to: self.master,
            value: 0,
            mode: SendRemainingBalance,
            body: Join{
                userAddress: self.owner,
                invitedId: invitedId
            }.toCell()
        });
    }

    fun sendAlreadyJoinedMessage() {
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
            body: "User with this address already join".asComment()
        });
    }

    fun requireMaster() {
        nativeThrowUnless(132, sender() == self.master);
    }

    // ------------------ Get Function  ------------------ //

    get fun balance(): Int {
        return myBalance();
    }

    get fun id(): Int? {
        return self.id;
    }

    get fun owner(): Address {
        return self.owner;
    }
}
