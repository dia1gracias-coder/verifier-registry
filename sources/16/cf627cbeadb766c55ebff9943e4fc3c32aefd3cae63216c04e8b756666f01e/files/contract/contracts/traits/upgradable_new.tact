/// Message for upgrading contract code and data.
message Upgrade {
/// New code of the contract.
/// Defaults to `null`, which keeps the previous code.
    code: Cell? = null;

/// New data of the contract.
/// Defaults to `null`, which keeps the previous data.
    data: Cell? = null;
}

message SetAdmin {
    new_admin_address: Address;
}

/// Implements a basic upgrade mechanism with admin validation.
trait Upgradable {
/// Contract admin address that can perform upgrades.
    admin: Address?;

/// Current contract version, auto-increments after each upgrade.
/// Meant to be private and only accessible through the relevant getter.
    _version: Int as uint32;

/// Checks the sender, performs an upgrade, and increments the version.
    receive(msg: Upgrade) {
        let ctx = context();
        self.validateUpgrade(ctx);
        self.upgrade(ctx, msg);
    }

    receive(msg: SetAdmin) { // ToDo test; masrter, user profile, company
        let ctx: Context = context();
        self._upgrade_admin(ctx, msg)
    }

    virtual inline fun _upgrade_admin(ctx: Context, msg: SetAdmin){
        require(ctx.sender == self.admin!!, "upgrade_admin: sender is not a admin");
        self.admin = msg.new_admin_address;
    }

/// Checks that the sender is the admin.
/// Can be overridden.
    virtual inline fun validateUpgrade(ctx: Context) {
        require(ctx.sender == self.admin!!, "validateUpgrade: sender is not a admin");
    }

/// Sets the code if it's not `null`.
/// Sets the data if it's not `null`.
/// Can be overridden.
    virtual inline fun upgrade(_: Context, msg: Upgrade) {
        if (msg.code != null) {
            // Change of code will be applied at the end of this transaction
            setCode(msg.code!!);
        }
        if (msg.data != null) {
            // Change of data will be immediate
            setData(msg.data!!);

            // By the end of every transaction,
            // the Tact compiler automatically adds a call to setData() for your convenience.
            // However, we've already set the data ourselves,
            // so let's stop the execution now to prevent a secondary call to setData().
            throw(0);
        }
    }

    get fun adminAddress(): Address? {
        return self.admin;
    }

/// A getter to check if the contract uses this trait.
    get fun isUpgradable(): Bool {
        return true;
    }

/// A getter returning the current version of the contract.
    get fun version(): Int {
        return self._version;
    }
}

trait TimeLimitUpgradable with Upgradable {
    admin: Address?;
    date_termination: Int? as uint32;
    date_review_end: Int? as uint32;
    reviews_published: Bool;

    _version: Int as uint32;

    override inline fun validateUpgrade(ctx: Context) {
        require(ctx.sender == self.admin!!, "validateUpgrade: Sender is not a contract admin");
        require(self.date_review_end!! > now(), "validateUpgrade: date_review_end is passed");
        require(self.reviews_published == false, "validateUpgrade: reviews are published");
    }
}

trait TimeLimitUpgradableCEO with Upgradable {
    admin: Address?;
    date_termination: Int? as uint32;
    date_review_end: Int? as uint32;
    reviews_published: Bool;

    _version: Int as uint32;

    override inline fun validateUpgrade(ctx: Context) {
        require(ctx.sender == self.admin!!, "validateUpgrade: Sender is not a contract admin");
        if (self.date_termination != null){
            require(self.date_review_end!! > now(), "validateUpgrade: date_review_end is passed");
            require(self.reviews_published == false, "validateUpgrade: reviews are published");
        }
    }
}

/// Change of code will be applied by the end of the current transaction.
asm fun setCode(code: Cell) { SETCODE }

@name(set_data)
native setData(data: Cell);

