struct RoleData {
    hasRole: map<Address, Bool>;
}

message GrantRole {
    role: Int;
    account: Address;
}
message RevokeRole {
    role: Int;
    account: Address;
}

trait AccessControl {
    const DEFAULT_ADMIN_ROLE: Int = sha256("DEFAULT_ADMIN_ROLE");
    roles: map<Int, RoleData>;

    receive(msg: GrantRole) {
        self._checkRole(self.DEFAULT_ADMIN_ROLE, sender());
        self._grantRole(msg.role, msg.account);
        self.reply("GrantRole".asComment());

    }

    receive(msg: RevokeRole) {
        require(self.getRole(self.DEFAULT_ADMIN_ROLE, sender()) || 
        (sender() == msg.account && self.getRole(msg.role, sender()))
        , "Access denied" );
        self._revokeRole(msg.role, msg.account);
        self.reply("RevokeRole".asComment());
    }

    get fun defaultRole(): Int {
        return self.DEFAULT_ADMIN_ROLE;
    }

    get fun getRole(role: Int, account: Address): Bool {
        let roleData: RoleData? = self.roles.get(role);
        if (roleData == null) {
            return false;
        }

        let status:Bool? = roleData!!.hasRole.get(account);
        if(status==null){
            return false;
        }
        return status!!;
    }

    fun __AccessControlInit__(account: Address) {
        self.roles = emptyMap();
        self._initRole(self.DEFAULT_ADMIN_ROLE, account);
    }

    fun _checkRole(role: Int, account: Address) {
        require(self.getRole(role, account), "Access denied");
    }

    fun _grantRole(role: Int, account: Address) {
        if(self.roles.get(role) == null) {
            self._initRole(role, account);
            return;
        }

        let roleData: RoleData = self.roles.get(role)!!; 
        roleData.hasRole.set(account, true);
        self.roles.set(role, roleData);
    }

    fun _initRole(role: Int, account: Address){
        let roleData: RoleData = RoleData{hasRole: emptyMap()};
        roleData.hasRole.set(account, true);
        self.roles.set(role, roleData);
        return;
    }

    fun _revokeRole(role: Int, account: Address) {
        let roleData: RoleData = self.roles.get(role)!!;
        roleData.hasRole.del(account);
        self.roles.set(role, roleData);
    }
}