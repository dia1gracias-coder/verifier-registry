import "./messages.tact";
import "./constants.tact";
import "./jetton_minter.tact";

/// JettonFactory V4 — deployed ONCE by the platform.
/// Collects platform fees and deploys independent JettonMinter V2 contracts.
/// Each deployed minter is fully owned by the user — platform has zero control post-deploy.
contract JettonFactory {
    owner:         Address;           // Platform treasury
    totalDeployed: Int as uint32 = 0;
    paused:        Bool = false;

    init(owner: Address) {
        self.owner = owner;
    }

    // ─── Main entry point: deploy a new jetton ────────────────────────────────
    receive(msg: DeployJetton) {
        require(!self.paused, "JettonFactory: platform is paused");

        // Validate fee
        let requiredFee: Int = msg.tierPro ? PRO_FEE : BASE_FEE;
        require(
            context().value >= requiredFee + TOTAL_DEPLOY_GAS,
            "JettonFactory: insufficient fee attached"
        );

        // Build TEP-64 off-chain metadata cell
        let contentCell: Cell = self._buildContentCell(msg.metadataUri);

        // Derive deterministic minter address
        let minterInit: StateInit = initOf JettonMinter(
            sender(),           // admin = user's wallet (NOT factory)
            msg.maxSupply,
            msg.mintable,
            msg.burnable,
            msg.pausable,
            msg.freezable,
            contentCell
        );
        let minterAddr: Address = contractAddress(minterInit);

        // Gas reserved for this computation
        let gasReserve: Int = ton("0.05");

        // Transfer platform fee to treasury (paid from contract balance separately)
        send(SendParameters{
            to:    self.owner,
            value: requiredFee,
            mode:  SendIgnoreErrors,
            body:  emptyCell()
        });

        // Deploy the minter with remaining value minus gas reserve.
        // MintInitial is sent as body — mints maxSupply to owner on first execution.
        let minterValue: Int = context().value - requiredFee - gasReserve;
        send(SendParameters{
            to:    minterAddr,
            value: minterValue,
            mode:  SendIgnoreErrors,
            code:  minterInit.code,
            data:  minterInit.data,
            body:  "MintInitial".asComment()
        });

        self.totalDeployed += 1;
    }

    // ─── Admin: pause/resume deployments ─────────────────────────────────────
    receive("Pause") {
        self.requireOwner();
        self.paused = true;
    }

    receive("Resume") {
        self.requireOwner();
        self.paused = false;
    }

    // ─── Admin: withdraw accumulated TON ─────────────────────────────────────
    receive("Withdraw") {
        self.requireOwner();
        require(myBalance() > MIN_TON_RESERVE, "JettonFactory: nothing to withdraw");
        send(SendParameters{
            to:    self.owner,
            value: myBalance() - MIN_TON_RESERVE,
            mode:  SendPayGasSeparately
        });
    }

    // ─── Admin: renounce ownership ────────────────────────────────────────────
    receive("RenounceOwnership") {
        self.requireOwner();
        self.owner = newAddress(0, 0);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────
    fun requireOwner() {
        require(sender() == self.owner, "JettonFactory: caller is not owner");
    }

    fun _buildContentCell(uri: String): Cell {
        return beginCell()
            .storeUint(1, 8)
            .storeSlice(uri.asSlice())
            .endCell();
    }

    // ─── Getters ──────────────────────────────────────────────────────────────
    get fun totalDeployed(): Int  { return self.totalDeployed; }
    get fun isPaused(): Bool      { return self.paused; }
    get fun owner(): Address      { return self.owner; }
    get fun baseFee(): Int        { return BASE_FEE; }
    get fun proFee(): Int         { return PRO_FEE; }
}
