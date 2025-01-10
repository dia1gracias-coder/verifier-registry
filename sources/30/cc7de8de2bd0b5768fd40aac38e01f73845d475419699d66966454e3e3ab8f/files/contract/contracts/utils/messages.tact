
message GrantRole {
    to:         Address;
    role_id:    Int;
}

message RenounceRole {
    role_id:    Int;
    address:    Address;
}

message RevokeRole {
    to:         Address;
    role_id:    Int;
}

struct RoleData {
    roles:      map<Address, Bool>;
    admin_role: Int;
}

message UpdateRoleAdmin {
    role_id:    Int;
    role_admin: Int;
}
