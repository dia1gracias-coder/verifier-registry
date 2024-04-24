struct Data {
    data: String;
}

message DataInput {
    index: Int;
    data: String;
}


contract Storage {

    init() {}

    data: map<Int, Data>;
    owner: map<Int, Address>;

    receive(msg: DataInput) {
        require(self.data.get(msg.index) != null, "ERR: Invalid index");
        
        let ctx: Context = context();
        self.owner.set(msg.index, ctx.sender);
        self.data.set(msg.index, Data {data: msg.data});
    }

    get fun get_data(owner: Address, index: Int): String {
        if (self.owner.get(index) == null) {
            return "ERR: Invalid index";
        }

        if (self.owner.get(index)!! != owner) {
            return "ERR: Invalid owner";
        }

        return (self.data.get(index)!!).data;
    }
}