@name(set_code)
native setCode(code: Cell);

@name(set_data)
native setData(data: Cell);

message UpgradeContract {
  code: Cell;
  data: Cell?;
}

trait Upgradeable {
  owner: Address;

  // @dev  Upgrade
  receive(msg: UpgradeContract) {
    let ctx: Context = context();
    self._upgrade_validate(ctx, msg);
    self._upgrade(ctx, msg);
  }

  // @dev  _upgrade_validate conduct some custom validating before upgrade
  virtual inline fun _upgrade_validate(ctx: Context, msg: UpgradeContract) {
    require(ctx.sender == self.owner, "Upgradable: Sender is not a contract owner");
  }

  // @dev  _upgrade
  virtual inline fun _upgrade(ctx: Context, msg: UpgradeContract) {
    setCode(msg.code);
    if (msg.data != null) {
      setData(msg.data!!);
      // prevents second call of set_data later in funC compiled wrapper
      nativeThrow(0);
    }
  }
}