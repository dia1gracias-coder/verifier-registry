import "../tact-utils/contracts/jetton/jetton.tact";

contract TestJetton with JettonMaster {
    owner: Address;
    staticTax: Int as coins = ton("0.001");
    lockedValue: Int as coins = 0;
    content: Cell;
    totalSupply: Int as coins;
    mintable: Bool;

    init(owner: Address, content: Tep64TokenData) {
        self.owner = owner;

        self.content = content.toCell();
        self.totalSupply = 0;
        self.mintable = true;
    }
}