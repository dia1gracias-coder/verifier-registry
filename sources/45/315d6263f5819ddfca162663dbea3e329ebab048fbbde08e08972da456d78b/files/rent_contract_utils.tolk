import "errors"
import "storage"

fun updateCurrentMonthState(mutate storage: RentStorage, newState: MonthState) {
    var month: MonthStorage = storage.months.mustGet(storage.currentMonth);
    month.state = newState;
    storage.months.set(storage.currentMonth, month);
}

fun setDisputeStartTime(mutate storage: RentStorage) {
    var timestamps: TimeFields = storage.timestamps.load();
    timestamps.disputeOpen = blockchain.now() as uint32;
    storage.timestamps = timestamps.toCell();
}

fun setCheckInConfirmedTime(mutate storage: RentStorage) {
    var timestamps: TimeFields = storage.timestamps.load();
    timestamps.checkInConfirmed = blockchain.now() as uint32;
    storage.timestamps = timestamps.toCell();
}

fun getCheckInConfirmedTime(storage: RentStorage) {
    var timestamps: TimeFields = storage.timestamps.load();
    return timestamps.checkInConfirmed;
}

fun setCheckOutConfirmedTime(mutate storage: RentStorage) {
    var timestamps: TimeFields = storage.timestamps.load();
    timestamps.checkOutConfirmed = blockchain.now() as uint32;
    storage.timestamps = timestamps.toCell();
}

fun getCheckOutConfirmedTime(storage: RentStorage) {
    var timestamps: TimeFields = storage.timestamps.load();
    return timestamps.checkOutConfirmed;
}

fun setLastMonthDueTsTime(mutate storage: RentStorage) {
    var timestamps: TimeFields = storage.timestamps.load();
    timestamps.lastMonthDueTs = storage.months.mustGet(storage.currentMonth - 1).dueTs;
    storage.timestamps = timestamps.toCell();
}

fun getLastMonthDueTsTime(storage: RentStorage) {
    var timestamps: TimeFields = storage.timestamps.load();
    return timestamps.lastMonthDueTs;
}

fun onlyAdmin(senderAddress: address, storage: RentStorage) {
    assert (senderAddress == storage.extra.load().administrative.load().admin) throw ERR_NOT_ADMIN;
}

fun onlyFactory(senderAddress: address, storage: RentStorage) {
    assert (senderAddress == storage.extra.load().administrative.load().factory) throw ERR_NOT_FACTORY;
}

fun onlyTenant(senderAddress: address, storage: RentStorage) {
    assert (senderAddress == storage.extra.load().clients.load().tenant) throw ERR_NOT_TENANT;
}

fun onlyLandlord(senderAddress: address, storage: RentStorage) {
    assert (senderAddress == storage.extra.load().clients.load().landlord) throw ERR_NOT_LANDLORD;
}
