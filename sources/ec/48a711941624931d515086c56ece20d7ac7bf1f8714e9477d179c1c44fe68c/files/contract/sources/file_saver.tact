

contract Main {

    init() { }

    receive(msg: DataInput) {
        let ctx: Context = context();
        let winit: StateInit = initOf Saver(myAddress(), ctx.sender, msg.key);

        send(SendParameters {
            to: contractAddress(winit),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: Data {
                data: msg.data
            }.toCell(),
            code: winit.code,
            data: winit.data
        });

    }

    get fun getInitAddress(owner: Address, key: String): Address {
        let winit: StateInit = initOf Saver(myAddress(), owner, key);
        return contractAddress(winit);
    }

}

contract Saver {
    
    master: Address;
    owner: Address;
    key: String;
    data: String;

    init(master: Address, owner: Address, key: String) {
        self.master = master;
        self.owner = owner;
        self.key = key;
        self.data = "";
    }

    receive(msg: Data) {
        let ctx: Context = context();
        
        if (ctx.sender != self.master) {
            require(ctx.sender == self.owner, "ERR: Invalid sender");
        }
        self.data = msg.data;
    }

    get fun get_contract_data(): DataResponse {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "ERR: Invalid sender");

        return DataResponse {
            master: self.master,
            owner: self.owner,
            key: self.key,
            data: self.data
        };
    }

}

struct DataResponse {
    master: Address;
    owner: Address;
    key: String;
    data: String;
}

message Data {
    data: String;
}

message DataInput {
    key: String;
    data: String;
}