import "@stdlib/deploy";
struct ItemContent {
    name: String;
    age: Int as uint16;
}

contract GettersContract with Deployable {
    id: Int as uint32;
    items: map<Int as uint16, ItemContent>;
    init(id: Int, items: map<Int as uint16, ItemContent>){
        self.id = id;
        self.items = items;
    }

    get fun id(): Int {
        return self.id;
    }

    get fun greeting(): String {
        return "hello world";
    }

    get fun oneItem(key: Int): ItemContent? {
        return self.items.get(key);
    }

    get fun allItems(): map<Int as uint16, ItemContent> {
        return self.items;
    }
}