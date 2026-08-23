// Split — the 95/5 payout contract (onchain-contracts-spec §5). Stateless per trade:
// receives a server-authorised `Settle` carrying the full `price`, sends the seller
// (price - commission) and the house `commission`, keeps nothing. Commission is taken
// ONLY from the sale price (never from bond/deposit — auction-build-spec invariant #6).
//
// `price` is expected to arrive intact as the incoming message value: the payer (the
// winner's BondEscrow via PayWin) forwards it with SendPayGasSeparately so fees don't
// eat into it. Exact fee/dust routing is an audit-time detail (§13).

import "./messages";

struct SplitConfig {
    house: Address;
    serverPubKey: Int as uint256;
    commissionBps: Int as uint16;
}

contract Split(
    house: Address,           // our 5% recipient
    serverPubKey: Int as uint256,
    commissionBps: Int as uint16,  // 500 = 5%
) {
    // Plain-value / deploy message: accept and keep (bootstrap gas). No-op body.
    receive() {}

    receive(msg: Settle) {
        let terms: SettleTerms = msg.terms;
        require(now() < terms.expiry, "settle: voucher expired");
        require(
            checkSignature(terms.toCell().hash(), msg.signature, self.serverPubKey),
            "settle: bad server signature",
        );
        require(context().value >= terms.price, "settle: underpaid");

        let commission: Int = (terms.price * self.commissionBps) / 10000;
        let sellerAmount: Int = terms.price - commission;

        // Both shares are exact; gas + forward fees come from the contract's own small
        // balance (funded at deploy). `price` is expected to arrive intact (payer uses
        // SendPayGasSeparately), so seller + house == price exactly. Any overpayment
        // above `price` stays as sweepable dust (audit-time refund is a §13 detail).
        send(SendParameters{
            to: self.house,
            value: commission,
            mode: SendPayGasSeparately,
            bounce: false,
        });
        send(SendParameters{
            to: terms.seller,
            value: sellerAmount,
            mode: SendPayGasSeparately,
            bounce: false,
        });
    }

    // --- getters (read-only, for the server / tests) ---
    get fun config(): SplitConfig {
        return SplitConfig{ house: self.house, serverPubKey: self.serverPubKey, commissionBps: self.commissionBps };
    }
}
