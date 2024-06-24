import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./token";

contract JD with Deployable, Ownable {
    owner: Address;
    init(owner: Address){
        self.owner = owner;
    }

    receive(msg: ChangeOwnerMsg){
        self.requireOwner();
        self.owner = msg.new_owner;
        self.reply(NewOwnerEvent{new_owner: msg.new_owner}.toCell());
    }

    receive(msg: NewToken){
        // Deploy the token
        let token: StateInit = initOf Token(myAddress(),
            msg.content,
            msg.max_supply,
            msg.tokenLauncher,
            msg.website,
            msg.telegram,
            msg.twitter
        );
        send(SendParameters{
                to: contractAddress(token),
                body: MintAll{receiver: self.owner}.toCell(),
                value: ton("0"),
                mode: SendRemainingValue | SendIgnoreErrors,
                code: token.code,
                data: token.data
            }
        );
        // send(SendParameters{
        //         to: sender(),
        //         body: beginCell().endCell(),
        //         value: 0,
        //         mode: SendRemainingValue | SendIgnoreErrors
        //     }
        // );
        //self.reply(beginCell().endCell());
    }

    get fun balance(): Int {
        return myBalance();
    }

    receive("Withdraw"){
        self.requireOwner();
        if (myBalance() > ton("0.2")) {}
        send(SendParameters{to: self.owner, value: (myBalance() - ton("0.2"))});
    }
}