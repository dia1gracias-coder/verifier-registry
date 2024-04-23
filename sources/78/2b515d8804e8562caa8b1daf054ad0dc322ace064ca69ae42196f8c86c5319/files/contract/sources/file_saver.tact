

// contract Main {

//     init() { }

//     receive(msg: DataInput) {
//         let ctx: Context = context();
//         let winit: StateInit = initOf Saver(myAddress(), ctx.sender, msg.key);

//         send(SendParameters {
//             to: contractAddress(winit),
//             value: 0,
//             bounce: false,
//             mode: SendRemainingValue,
//             body: Data {
//                 data: msg.data
//             }.toCell(),
//             code: winit.code,
//             data: winit.data
//         });

//     }

//     get fun getInitAddress(owner: Address, key: String): Address {
//         let winit: StateInit = initOf Saver(myAddress(), owner, key);
//         return contractAddress(winit);
//     }

// }

// contract Saver {
    
//     master: Address;
//     owner: Address;
//     key: String;
//     data: String;

//     init(master: Address, owner: Address, key: String) {
//         self.master = master;
//         self.owner = owner;
//         self.key = key;
//         self.data = "";
//     }

//     receive(msg: Data) {
//         let ctx: Context = context();
        
//         if (ctx.sender != self.master) {
//             require(ctx.sender == self.owner, "ERR: Invalid sender");
//         }
//         self.data = msg.data;
//     }

//     get fun get_contract_data(): DataResponse {
//         let ctx: Context = context();

//         return DataResponse {
//             master: self.master,
//             owner: self.owner,
//             key: self.key,
//             data: self.data
//         };
//     }

// }

struct DataResponse {
    master: Address;
    owner: Address;
    key: String;
    data: String;
}

message DataInput {
    key: String;
    data: String;
}

message DataInputTest {
    key: String;
    data: String;
}

/////////////////////////

struct Holder {
    total: Int;
    holder: map<Int, Int>;
}

struct Data {
    key: String;
    data: String;
}

contract DataSaver {

    index: Int = 0;
    owner: map<Int, Address>;
    holder: map<Address, Holder>;
    data: map<Int, Data>;

    init() {

    }

    receive(msg: DataInput) {
        let ctx: Context = context();

        self.index += 1;
        self.owner.set(self.index, ctx.sender);

        if (self.holder.get(ctx.sender) == null){
            let init_map: map<Int, Int> = null;
            init_map.set(0, self.index);
            let _holder: Holder = Holder{total: 1, holder: init_map};
            self.holder.set(ctx.sender, _holder);
        }
        else {
            let _holder: Holder = self.holder.get(ctx.sender)!!;
            _holder.holder.set(_holder.total, self.index);
            _holder.total += 1;

            self.holder.set(ctx.sender, _holder);
        }

        let data: Data = Data{key: msg.key, data: msg.data};
        self.data.set(self.index, data);
    }

    receive(msg: DataInputTest) {
        let ctx: Context = context();

        self.index += 1;
        self.owner.set(self.index, ctx.sender);

        if (self.holder.get(ctx.sender) == null){
            let init_map: map<Int, Int> = null;
            init_map.set(0, self.index);
            let _holder: Holder = Holder{total: 1, holder: init_map};
            self.holder.set(ctx.sender, _holder);
        }
        else {
            let _holder: Holder = self.holder.get(ctx.sender)!!;
            _holder.holder.set(_holder.total, self.index);
            _holder.total += 1;
        }

        let data: Data = Data{key: msg.key, data: msg.data};
        self.data.set(self.index, data);
    }

    get fun get_data(index: Int): Data {
        return self.data.get(index)!!;
    }

    get fun get_address(): Holder {
        let ctx: Context = context();

        return self.holder.get(ctx.sender)!!;
    }


}