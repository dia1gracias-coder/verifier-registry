import "@stdlib/deploy";
import "@stdlib/ownable";

// ─────────────────────────────────────────────
//  TON INSCRIPTION SMART CONTRACT  v2
//  Total Supply : 50 000 mints
//  Price / mint : 0.2 TON (platform fee)
//                + ~0.02 TON gas = 0.22 TON total
//  Max / wallet : 20 mints
//  Inscription  : {"p":"ton-20","op":"mint","tick":"TONS","amt":"420"}
// ─────────────────────────────────────────────

message Mint {}
message Withdraw {}
message SetPrice { newPrice: Int as coins; }
message SetMaxPerUser { newMax: Int as uint8; }
message SetPaused { paused: Bool; }

contract InscribV2 with Deployable, Ownable {

    owner:       Address;
    totalSupply: Int as uint32;
    minted:      Int as uint32;
    mintPrice:   Int as coins;
    maxPerUser:  Int as uint8;
    isPaused:    Bool;

    userMints: map<Address, Int as uint8>;

    init(owner: Address) {
        self.owner       = owner;
        self.totalSupply = 50000;
        self.minted      = 0;
        self.mintPrice   = ton("0.2");   // platform fee per mint
        self.maxPerUser  = 20;           // max 20 mints per wallet
        self.isPaused    = false;
        self.userMints   = emptyMap();
    }

    // ── helper: get user mint count ──────────
    fun getUserCount(addr: Address): Int {
        let raw: Int? = self.userMints.get(addr);
        if (raw != null) {
            return raw!!;
        }
        return 0;
    }

    // ── MINT (message opcode) ─────────────────
    receive(msg: Mint) {
        require(!self.isPaused,                    "Minting is paused");
        require(self.minted < self.totalSupply,    "Sold out");
        let addr: Address = sender();
        let count: Int    = self.getUserCount(addr);
        require(count < self.maxPerUser,           "Max 20 mints per wallet");
        require(context().value >= self.mintPrice, "Insufficient TON sent");

        self.userMints.set(addr, count + 1);
        self.minted = self.minted + 1;

        // Refund any excess above platform fee
        let excess: Int = context().value - self.mintPrice;
        if (excess > ton("0.01")) {
            send(SendParameters{
                to:    addr,
                value: excess,
                mode:  SendIgnoreErrors
            });
        }
    }

    // ── MINT (text comment "mint") ───────────
    receive("mint") {
        require(!self.isPaused,                    "Minting is paused");
        require(self.minted < self.totalSupply,    "Sold out");
        let addr: Address = sender();
        let count: Int    = self.getUserCount(addr);
        require(count < self.maxPerUser,           "Max 20 mints per wallet");
        require(context().value >= self.mintPrice, "Insufficient TON sent");

        self.userMints.set(addr, count + 1);
        self.minted = self.minted + 1;

        let excess: Int = context().value - self.mintPrice;
        if (excess > ton("0.01")) {
            send(SendParameters{
                to:    addr,
                value: excess,
                mode:  SendIgnoreErrors
            });
        }
    }

    // ── WITHDRAW ─────────────────────────────
    receive(msg: Withdraw) {
        self.requireOwner();
        let balance: Int = myBalance() - ton("0.05");
        require(balance > 0, "Nothing to withdraw");
        send(SendParameters{
            to:    self.owner,
            value: balance,
            mode:  SendIgnoreErrors
        });
    }

    // ── SET PRICE (owner only) ───────────────
    receive(msg: SetPrice) {
        self.requireOwner();
        require(msg.newPrice > 0, "Price must be > 0");
        self.mintPrice = msg.newPrice;
    }

    // ── SET MAX PER USER (owner only) ────────
    receive(msg: SetMaxPerUser) {
        self.requireOwner();
        require(msg.newMax > 0, "Max must be > 0");
        self.maxPerUser = msg.newMax;
    }

    // ── PAUSE / UNPAUSE ──────────────────────
    receive("pause")   { self.requireOwner(); self.isPaused = true;  }
    receive("unpause") { self.requireOwner(); self.isPaused = false; }

    // ── GETTERS ──────────────────────────────
    get fun minted():      Int  { return self.minted;                      }
    get fun totalSupply(): Int  { return self.totalSupply;                 }
    get fun mintPrice():   Int  { return self.mintPrice;                   }
    get fun maxPerUser():  Int  { return self.maxPerUser;                  }
    get fun isPaused():    Bool { return self.isPaused;                    }
    get fun remaining():   Int  { return self.totalSupply - self.minted;   }

    get fun userMintCount(addr: Address): Int {
        return self.getUserCount(addr);
    }

    get fun canMint(addr: Address): Bool {
        if (self.isPaused)                   { return false; }
        if (self.minted >= self.totalSupply) { return false; }
        return self.getUserCount(addr) < self.maxPerUser;
    }
}
