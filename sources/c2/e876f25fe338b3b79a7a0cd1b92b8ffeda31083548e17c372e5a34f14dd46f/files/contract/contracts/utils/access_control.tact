import "./messages.tact";

trait AccessControl {
    
    roles: map<Int, RoleData>;

    receive (msg: GrantRole) {
        self.only_admin();
        self.grant_role(msg.role_id, msg.to);
    }

    receive (msg: RevokeRole) {
        self.only_admin();
        self.revoke_role(msg.role_id, msg.to);
    }

    receive (msg: RenounceRole) {
        require(msg.address == context().sender, "AccessControl: BadConfirmation");
        self.revoke_role(msg.role_id, msg.address);
    }

    receive (msg: UpdateRoleAdmin) {
        let role_data: RoleData? = self.roles.get(msg.role_id);
        require(role_data != null, "AccessControl: Role doesn't exist");
        let rd: RoleData = (role_data!!);
        rd.admin_role = msg.role_admin;
        self.roles.set(msg.role_id, rd);
    }

    //********************************************//
    //             Internal functions             //
    //********************************************//

    inline fun only_admin() {
        let roles_opt: RoleData? = self.roles.get(self.admin_role_id());
        require(roles_opt != null, "AccessControl: Role ADMIN is undefined");
        let roles: RoleData = (roles_opt!!);
        let has_role_opt: Bool? = roles.roles.get(context().sender);
        require(has_role_opt != null && (has_role_opt!!) == true, "AccessControl: Doesn't have the ADMIN role");
    }

    inline fun only_bridge() {
        let roles_opt: RoleData? = self.roles.get(self.bridge_role_id());
        require(roles_opt != null, "AccessControl: Role BRIDGE is undefined");
        let roles: RoleData = (roles_opt!!);
        let has_role_opt: Bool? = roles.roles.get(context().sender);
        require(has_role_opt != null && (has_role_opt!!) == true, "AccessControl: Doesn't have the BRIDGE role");
    }

    inline fun only_cfo() {
        let roles_opt: RoleData? = self.roles.get(self.cfo_role_id());
        require(roles_opt != null, "AccessControl: Role CFO is undefined");
        let roles: RoleData = (roles_opt!!);
        let has_role_opt: Bool? = roles.roles.get(context().sender);
        require(has_role_opt != null && (has_role_opt!!) == true, "AccessControl: Doesn't have the CFO role");
    }

    inline fun only_role(role_id: Int) {
        require(self.has_role(context().sender, role_id), "AccessControl: Doesnt have the role");
    }

    inline fun grant_role(role_id: Int, to: Address) {
        let role_admin: Int = self.role_admin(role_id);
        self.only_role(role_admin);
        let role_data: RoleData = self.roles.get(role_id)!!;
        role_data.roles.set(to, true);
        self.roles.set(role_id, role_data);
    }

    inline fun revoke_role(role_id: Int, to: Address) {
        let role_admin: Int = self.role_admin(role_id);
        self.only_role(role_admin);
        let role_data: RoleData = self.roles.get(role_id)!!;
        role_data.roles.set(to, false);
        self.roles.set(role_id, role_data);
    }

    // ----------------------------------------------

    inline fun _grant_role(role_id: Int, to: Address) {
        let role_data: RoleData? = self.roles.get(role_id);
        if (role_data == null) {
            let roles: map<Address, Bool> = emptyMap();
            roles.set(to, true);
            role_data = RoleData{roles: roles, admin_role: self.admin_role_id()};
            self.roles.set(role_id, role_data);
        }
        let rd: RoleData = role_data!!;
        rd.roles.set(to, true);
        self.roles.set(role_id, rd);
    }

    inline fun _revoke_role(role_id: Int, to: Address) {
        let role_data: RoleData? = self.roles.get(role_id);
        require(role_data != null, "AccessControl: Role ID doesn't exist");
        let rd: RoleData = role_data!!;
        rd.roles.set(to, false);
        self.roles.set(role_id, rd);
    }

    //*********************************//
    //             Getters             //
    //*********************************//

    get fun admin_role_id(): Int {
        return sha256("ADMIN"); //0;
    }

    get fun bridge_role_id(): Int {
        return sha256("BRIDGE");
    }

    get fun cfo_role_id(): Int {
        return sha256("CFO");
    }

    get fun has_role(address: Address, role_id: Int): Bool {
        let prev_roles: RoleData? = self.roles.get(role_id);
        if (prev_roles == null) {
            return false;
        }
        let has_role_opt: Bool? = (prev_roles!!).roles.get(address);
        if (has_role_opt == null) {
            return false;
        }
        return (has_role_opt!!);
    }

    get fun role_admin(role_id: Int): Int {
        let role_data: RoleData? = self.roles.get(role_id);
        require(role_data != null, "AccessControl: Role doesn't exist");
        return (role_data!!).admin_role;
    }
}

