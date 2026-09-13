/// PotRelay: the Pot's whitelisted "escrow" for stock rounds.
///
/// Why it exists: Omniston resolvers deliver the bought stock to the position owner with `forward_ton_amount = 0`,
/// so a Pot receiving stock directly never gets the `transfer_notification` that settles a round (mainnet, 2026-09-10).
/// The relay takes the position instead, then anyone can `Flush` what it holds to the Pot with forward TON attached,
/// which produces the notification the Pot needs. The relay never decides amounts: the jetton wallets enforce balances.

/// Forward payload of the Pot's USDT transfer to the relay. The Pot checks it exactly like an escrow payload:
/// opcode at bit 0, `owner` (the Pot) at bit 96, `minOut` (Coins) at bit 363 of the root cell.
struct (0x52454c41) RelayOrder {
    queryId: uint64
    /// Position owner as seen by the Pot: must be the Pot itself.
    owner: address
    /// Minimum stock the resolver must deliver (the Pot requires it to be >= the Round's declared `minOut`).
    minOut: coins
    /// TON to forward with the USDT transfer to the escrow minter (Omniston requires ~0.3).
    swapForwardTon: coins
    /// Omniston forward payload, built by the API for a position owned by the relay.
    swap: cell
}

/// Move `amount` of the jetton held in `jettonWallet` (a wallet owned by the relay) to the Pot with forward TON.
/// Permissionless for stock wallets; the relay's USDT wallet needs the keeper (see Flush guard).
struct (0x50520001) Flush {
    queryId: uint64
    jettonWallet: address
    amount: coins
}

/// Admin: rotate the admin / keeper.
struct (0x50520002) SetRelayRoles {
    queryId: uint64
    admin: address
    keeper: address
}

/// Admin: pin the relay's USDT jetton wallet (depends on the relay address, so it is set right after deploy).
struct (0x50520003) SetUsdtWallet {
    queryId: uint64
    usdtWallet: address
}

struct PotRelayStorage {
    /// Only recipient of everything the relay ever transfers out.
    pot: address
    /// Omniston escrow minter: destination of the relay's USDT transfer that opens a position.
    escrowMinter: address
    /// The relay's own USDT jetton wallet: the only notification source that triggers a swap. Null until pinned.
    usdtWallet: address?
    /// admin + keeper (a cell: five addresses do not fit one cell)
    roles: Cell<RelayRoles>
}

struct RelayRoles {
    admin: address
    /// May flush the USDT wallet (refunds); stock wallets are flushable by anyone.
    keeper: address
}

fun PotRelayStorage.load(): PotRelayStorage {
    return PotRelayStorage.fromCell(contract.getData());
}

fun PotRelayStorage.save(self) {
    contract.setData(self.toCell());
}

struct RelayDataReply {
    pot: address
    escrowMinter: address
    usdtWallet: address?
    admin: address
    keeper: address
}
