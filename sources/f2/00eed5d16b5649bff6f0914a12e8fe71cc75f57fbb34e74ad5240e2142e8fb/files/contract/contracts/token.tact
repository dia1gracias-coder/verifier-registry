import "@stdlib/deploy";
import "@stdlib/ownable";
import "./jetton";
import "./messages";

contract Token with Jetton, Deployable, Ownable {
    tokenLauncher: Address;
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    max_supply: Int as coins;
    website: String;
    telegram: String;
    twitter: String;
    init(_owner: Address,
        _content: Cell,
        _max_supply: Int,
        _tokenLauncher: Address,
        _website: String,
        _telegram: String,
        _twitter: String){
        self.tokenLauncher = _tokenLauncher;
        self.total_supply = 0;
        self.owner = _owner;
        self.mintable = true;
        self.content = _content;
        self.max_supply = _max_supply;
        self.website = _website;
        self.telegram = _telegram;
        self.twitter = _twitter;
    }

    receive(msg: MintAll){
        self.requireOwner();
        require(self.mintable, "Not mintable");
        self.mint(msg.receiver, self.max_supply, self.tokenLauncher); // (to, amount, response_destination)
        self.mintable = false;
        self.owner = address("0:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"); // set the _owner as the zero address

        // send(SendParameters{
        //         to: self.tokenLauncher,
        //         body: beginCell().endCell(),
        //         value: 0,
        //         mode: SendRemainingValue | SendIgnoreErrors
        //     }
        // );
        self.reply(beginCell().endCell());
    }

    get fun _tokenLauncher(): Address {
        return self.tokenLauncher;
    }

    get fun socialLinks(): String {
        let sb: StringBuilder = beginString();
        sb.append(self.website);
        sb.append("***");
        sb.append(self.telegram);
        sb.append("***");
        sb.append(self.twitter);
        return sb.toString();
    }
}