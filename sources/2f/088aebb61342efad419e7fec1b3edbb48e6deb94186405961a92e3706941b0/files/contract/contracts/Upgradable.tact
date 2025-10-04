import "@stdlib/ownable";

@name(set_code)
native setCode(code: Cell);

@name(set_data)
native setData(data: Cell);

message(0x251e8f92) UpgradeCode {
  code: Cell;
  version: Int as uint32;
  origin: Address?;
}

trait Upgradable with Ownable  {
  /// Contract owner address that can perform upgrades.
  owner: Address;

  version: Int as uint32;

  // @dev  Upgrade
  receive(msg: UpgradeCode) {
    self._validateUpgrade();
    setCode(msg.code);
    self.version = msg.version;

    if (msg.origin != null) {
      cashback(msg.origin!!);
    } else {
      cashback(sender());
    }
  }
  /*
  receive("Migrate storage"){
    self._validateUpgrade();
    let data: Cell = self._getMigratedData();
    setData(data);
    nativeThrow(0);
  }
  */

  //abstract inline fun _getMigratedData(): Cell;  

  /// A getter to check if the contract uses this trait.
  get fun isUpgradable(): Bool {
    return true;
  }

  /// A getter returning the current version of the contract.
  get fun version(): Int {
    return self.version;
  }

  // @dev  _upgrade_validate conduct some custom validating before upgrade
  virtual inline fun _validateUpgrade() {
    self.requireOwner();
  }

}