@name(set_code)
native setCode(code: Cell);

@name(set_data)
native setData(data: Cell);

message UpgradeContract {
    code: Cell;
    data: Cell?;
}

trait Upgradable {
    owner: Address;
    
    receive(msg: UpgradeContract) {
        let ctx: Context = context();
        self._upgrade_validate(ctx, msg);
        self._upgrade(ctx, msg);
    }
    
    virtual inline fun _upgrade_validate(ctx: Context, msg: UpgradeContract) {
        require(ctx.sender == self.owner, "Upgradable: Sender is not a contract owner");
    }
    
    virtual inline fun _upgrade(ctx: Context, msg: UpgradeContract) {
        setCode(msg.code);
        if (msg.data != null) {
            setData(msg.data!!);
            // prevents second call of set_data later in funC compiled wrapper
            nativeThrow(0);
        }
    }
} 