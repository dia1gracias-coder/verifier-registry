struct Role {
	hasRole: map<Address, Bool>;
	adminRole: Int;
}
message GrantRole {
	role: Int;
	assignee: Address;
}
message RevokeRole {
	role: Int;
	assignee: Address;
}
// =============================
// Access Control trait
// =============================
trait AccessControl {
	roles: map<Int, Role>;
	virtual const DEFAULT_ADMIN_ROLE: Int = sha256("DEFAULT_ADMIN_ROLE");

	receive(msg: GrantRole){
		self.grantRole(msg.role, msg.assignee);
	}

	receive(msg: RevokeRole){
		self.revokeRole(msg.role, msg.assignee);
	}

	virtual inline fun grantRole(roleHash: Int, assignee: Address) {
		// grant role
		let roleStruct: Role? = self.roles.get(roleHash);  // prettier-ignore
		if (roleStruct != null) {
			let nonNullRoleStruct: Role = roleStruct!!;
			self._assignRole(nonNullRoleStruct, roleHash, assignee);
		} else {
			let nonNullRoleStruct: Role = Role{hasRole: emptyMap(), adminRole: self.DEFAULT_ADMIN_ROLE};
			self._assignRole(nonNullRoleStruct, roleHash, assignee);
		}
	}

	virtual inline fun revokeRole(roleHash: Int, assignee: Address) {
		// only adminRole can execute this call
		require(self.hasAdminRole(roleHash, sender()),
			"AccessControl: Only user with adminRole can revoke a role to a user"
		);
		// revoke role
		let roleStruct: Role? = self.roles.get(roleHash);  // prettier-ignore
		if (roleStruct != null) {
			let nonNullRoleStruct: Role = roleStruct!!;
			nonNullRoleStruct.hasRole.set(assignee, null);
			self.roles.set(roleHash, nonNullRoleStruct);
		}
	}

	inline fun _assignRole(roleStruct: Role, roleHash: Int, assignee: Address) {
		// only address with adminRole can assign role
		require(self.hasAdminRole(roleHash, sender()),
			"AccessControl: Only user with adminRole can assign a role from a user"
		);
		// set role
		roleStruct.hasRole.set(assignee, true);
		self.roles.set(roleHash, roleStruct);
	}

	virtual get fun hasAdminRole(roleHash: Int, user: Address): Bool {
		let roleStruct: Role? = self.roles.get(roleHash);  // prettier-ignore
		if (roleStruct != null) {
			let nonNullRoleStruct: Role = roleStruct!!;
			return self.hasRole(nonNullRoleStruct.adminRole, user);
		}
		else {
			return self.hasRole(self.DEFAULT_ADMIN_ROLE, user);
		}
	}

	virtual get fun hasRole(roleHash: Int, user: Address): Bool {
		let roleStruct: Role? = self.roles.get(roleHash);  // prettier-ignore
		if (roleStruct != null) {
			let nonNullRoleStruct: Role = roleStruct!!;
			let hasRole: Bool? = nonNullRoleStruct.hasRole.get(user);  // prettier-ignore
			if (hasRole != null) {
				return hasRole!!;
			}
		}
		return false;
	}

	virtual inline fun initDefaultAdminRole(user: Address) {
		// set role
		let hasRole: map<Address, Bool> = emptyMap();
		hasRole.set(user, true);
		let role: Role = Role{hasRole: hasRole, adminRole: self.DEFAULT_ADMIN_ROLE};
		self.roles.set(self.DEFAULT_ADMIN_ROLE, role);
	}

	virtual get fun defaultAdminRole(): Int {
		return self.DEFAULT_ADMIN_ROLE;
	}
}