
struct UserRoles {
    roles: map<Int as uint8, Bool>;
}

message(0x7744d640) GrantRole {
    role: Int as uint8;
    user: Address;
}

message(0x7744d641) RevokeRole {
    role: Int as uint8;
    user: Address;
}

message(0x77541880) RoleGranted {
    role: Int as uint8;
    user: Address;
    timestamp: Int as uint32;
}

message(0x77541881) RoleRevoked {
    role: Int as uint8;
    user: Address;
    timestamp: Int as uint32;
}

const DEFAULT_ADMIN_ROLE: Int = 1;

trait AccessControl {
    admin_initialized: Bool;
    user_roles: map<Address, UserRoles>;

    receive(msg: GrantRole) {
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._grant_role(msg.role, msg.user);
        send(SendParameters{to: sender(), bounce: false, value: 0, mode: SendRemainingValue});
    }

    receive(msg: RevokeRole) {
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._revoke_role(msg.role, msg.user);
        send(SendParameters{to: sender(), bounce: false, value: 0, mode: SendRemainingValue});
    }

    fun _init_admin(user: Address) {
        require(!self.admin_initialized, "Already initialized");
        let roles: map<Int as uint8, Bool> = emptyMap();
        roles.set(DEFAULT_ADMIN_ROLE, true);
        let user_roles: UserRoles = UserRoles{
            roles: roles,
        };
        self.user_roles.set(user, user_roles);
        self.admin_initialized = true;
        emit(RoleGranted{role: DEFAULT_ADMIN_ROLE, user: user, timestamp: now()}.toCell());
    }

    fun _grant_role(role: Int, user: Address) {
        if (self.user_exist(user)) {
            let user_roles: UserRoles = self.user_roles(user);
            require(!self.has_role(role, user), "User role already granted");
            user_roles.roles.set(role, true);
            self.user_roles.set(user, user_roles);
        } else {
            let roles: map<Int as uint8, Bool> = emptyMap();
            roles.set(role, true);
            let user_roles: UserRoles = UserRoles{
                roles: roles,
            };
            self.user_roles.set(user, user_roles);
        }
        emit(RoleGranted{role: role, user: user, timestamp: now()}.toCell());
    }

    fun _revoke_role(role: Int, user: Address) {
        require(self.user_exist(user), "No user roles granted");
        let user_roles: UserRoles = self.user_roles(user);
        require(self.has_role(role, user), "User role not granted");
        user_roles.roles.del(role);
        emit(RoleRevoked{role: role, user: user, timestamp: now()}.toCell());
    }

    fun _only_role(role: Int, user: Address){
        require(self.has_role(role, user), "Unauthorized user");
    }

    fun _only_roles(roles: map<Int, Int>, user: Address){
        let has_role: Bool = false;

        foreach(key, role in roles) {
            if (self.has_role(role, user)) {
                has_role = true;
            }
        }
        require(has_role, "Unauthorized user");
    }

    get fun user_exist(user: Address): Bool {
        return self.user_roles.get(user) != null;
    }

    get fun user_roles(user: Address): UserRoles {
        return self.user_roles.get(user)!!;
    }

    get fun has_role(role: Int, user: Address): Bool {
        if (!self.user_exist(user)) { 
            return false;
        }
        let user_roles: UserRoles = self.user_roles(user);
        return user_roles.roles.get(role) != null;
    }
}