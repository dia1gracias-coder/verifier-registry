import "@stdlib/deploy";
struct ItemContent {
    name: String;
    age: Int as uint16;
}
message SetGreeting {
    greeting: String;
}

contract GettersContract with Deployable {
    id: Int as uint32;
    greeting: String;
    items: map<Int as uint16, ItemContent>;
    init(id: Int, items: map<Int as uint16, ItemContent>){
        self.id = id;
        self.items = items;
        self.greeting = "hello world";
    }

    receive(msg: SetGreeting){
        self.greeting = msg.greeting;
    }

    get fun id(): Int {
        return self.id;
    }

    get fun greeting(): String {
        return self.greeting;
    }

    get fun oneItem(key: Int): ItemContent? {
        return self.items.get(key);
    }

    get fun allItems(): map<Int as uint16, ItemContent> {
        return self.items;
    }
}