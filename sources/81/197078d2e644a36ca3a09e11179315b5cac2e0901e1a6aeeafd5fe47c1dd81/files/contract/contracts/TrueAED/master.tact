/* ===== IMPORTS ===== */

/* StdLib */
import "@stdlib/deploy";

/* Jetton */
import "../Jetton/master";

/* ===== TRUE AED CONTRACT ===== */
contract TrueAED with Jetton, Deployable {
    /* ===== VARIABLES ===== */

    /* Jetton Trait */
    total_supply: Int as coins;
    content: Cell;
    mintable: Bool;

    /* OwnableTransferable Trait */
    owner: Address;

    /* Resumable Trait */
    stopped: Bool;

    /* ===== CONSTRUCTOR ===== */
    init(owner: Address, content: Cell) {
        self.total_supply = 0;
        self.mintable = true;
        self.content = content;
        self.owner = owner;
        self.stopped = false;
    }

    /* ===== RECEIVES ===== */
    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.receiver, msg.amount, self.owner);
    }

    fun hello(): String {
        return "hello-str";
    }
}
