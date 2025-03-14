import "@stdlib/deploy";
import "@stdlib/ownable";
import "./jetton.tact";
import "./upgradable.tact";


contract JettonContract with Deployable, Jetton, Upgradable {
    total_supply: Int as coins; // Tracks total supply of Jettons
    owner: Address;             // Address of the contract owner
    content: Cell;              // Metadata/content associated with the Jetton
    mintable: Bool;             // Flag to indicate if minting is allowed
    _version: Int as uint32;
    max_supply: Int as coins;   // Maximum supply of Jettons (not part of Jetton Standards)
    admins: map<Address, Bool>;

    // @owner The address of the Jetton contract owner
    // @content The initial metadata content of the Jetton
    // @max_supply The maximum supply of Jettons that can be minted
    init(owner: Address, content: Cell, max_supply: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
        self._version = 1;
        self.admins = emptyMap();
        self.admins.set(owner, true); // オーナーを管理者として設定
        self.mint(self.owner, max_supply, self.owner);
        self.mintable = false;
    }

    receive(msg: TokenUpdateCode) {
        self.requireOwner();

        if (msg.query_id != 0) {
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: TokenExcesses{
                    query_id: msg.query_id
                }.toCell()
            });
        }
    }

    // fun requireAdmin() {
    //     require(self.admins.get(sender()) == true, "この機能は管理者のみが呼び出せます");
    // }

    // // 送信者がオーナーまたは管理者かチェック
    // fun requireOwnerOrAdmin() {
    //     require(sender() == self.owner || self.admins.get(sender()) == true, "この機能はオーナーまたは管理者のみが呼び出せます");
    // }

    // receive(msg: AddAdmin) {
    //     self.requireOwner();
    //     self.admins.set(msg.admin_address, true);
    // }

    // receive(msg: RemoveAdmin) {
    //     self.requireOwner();
    //     self.admins.set(msg.admin_address, false);
    // }

    // get fun isAdmin(addr: Address): Bool {
    //     return self.admins.get(addr) == true;
    // }
}
