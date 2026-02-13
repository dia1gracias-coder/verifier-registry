import "constant"
import "error"
import "storage"

// throw error to stop the execution if the sender is not the owner
fun requireOwner(ownerAddress: address, owners: map<address, OwnerData>) {
    assert (checkIsOwner(ownerAddress, owners)) throw ERROR_NOT_OWNER;
}

fun checkIsOwner(checkAddress: address, owners: map<address, OwnerData>): bool {
    val result = owners.get(checkAddress);

    if (!result.isFound) {
        return false;
    }

    val ownerInfo = result.loadValue();

    return ownerInfo.isActive;
}

fun isValidRole(role: uint8): bool {
    return role == ROLE_OWNER;
}

fun requireValidRole(role: uint8) {
    assert (isValidRole(role)) throw ERROR_INVALID_ROLE;
}

fun requireValidAddress(address: address) {
    assert (address.getWorkchain() == 0) throw ERROR_INVALID_WORKCHAIN;
}

fun getCurrentTimestamp(): uint64 {
    return blockchain.now();
}
