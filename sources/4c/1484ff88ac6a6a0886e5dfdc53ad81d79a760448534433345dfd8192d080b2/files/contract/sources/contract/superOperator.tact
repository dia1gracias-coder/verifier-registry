
message AuthorizeOperator {
    address: Address;
}

message RevokeOperator {
    address: Address;
}

trait SuperOperator {
    superOperators: map<Address, Bool>;

    receive(msg: AuthorizeOperator){
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self.superOperators.set(msg.address, true);
    }

    receive(msg: RevokeOperator){
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self.superOperators.set(msg.address, false);
    }

    fun _isInsuperOperators(sender: Address) {
        let isInsuperOperators: Bool? = self.superOperators.get(sender);
        require(isInsuperOperators != null, "Not super operator");
        require(isInsuperOperators, "Not super operator");
    }
}