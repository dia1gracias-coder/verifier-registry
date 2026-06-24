// Owner-gated in-place code upgrade via the TVM SETCODE primitive.
//
// Lets a contract's LOGIC change WITHOUT changing its address — the account
// already exists, so set_code replaces the code in place and state (c4) is kept.
// This is the TON-native way to evolve contracts (no proxy/delegatecall).
//
// Caveats the new code must respect:
//   • Storage layout: new code reads the SAME c4. Keep fields compatible or
//     migrate on the first message after upgrade.
//   • SETCODE takes effect from the NEXT transaction, not mid-execution.
//   • Trust: the owner can replace code arbitrarily — gate the owner key
//     (multisig / timelock) for production.

asm fun setContractCode(code: Cell) { SETCODE }

message Upgrade {
    code: Cell;
}

trait Upgradable {
    owner: Address;

    receive(msg: Upgrade) {
        require(sender() == self.owner, "Upgradable: only owner");
        setContractCode(msg.code);
    }
}
