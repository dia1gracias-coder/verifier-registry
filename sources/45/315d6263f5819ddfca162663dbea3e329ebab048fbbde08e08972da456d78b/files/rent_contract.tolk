import "errors"
import "messages"
import "rent_contract_utils"
import "rent_finance"
import "storage"

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);
    match (msg) {
        //ADMIN
        InitContract => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyFactory(in.senderAddress, storage);
            // Step 1: ask the minter for OUR jetton wallet address
            val out = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: 0,
                dest: USDT_JETTON_MASTER,
                body: ProvideWalletAddress {
                    queryId: 0,
                    ownerAddress: contract.getAddress(), // we want OUR wallet
                    includeAddress: false,
                },
            });
            out.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }
        TakeWalletAddress => {
            // Step 2: minter replies — store the address, but ONLY if it really came from the minter
            var storage: RentStorage = lazy RentStorage.load();
            assert(USDT_JETTON_MASTER == in.senderAddress, ERR_NOT_FROM_MINTER);
            var extra: ExtraFields = storage.extra.load();
            var administrative = extra.administrative.load();
            administrative.jettonWallet = msg.walletAddress;
            extra.administrative = administrative.toCell();
            storage.extra = extra.toCell();
            storage.save();
        }
        TransferNotification => {
            var storage: RentStorage = lazy RentStorage.load();
            val extra: ExtraFields = storage.extra.load();
            assert (extra.administrative.load().jettonWallet != null) throw ERR_INVALID_JETTON;
            assert (in.senderAddress == extra.administrative.load().jettonWallet!) throw ERR_INVALID_JETTON;
            var balances: Balances = storage.balances.load();
            if (storage.globalState == GlobalState.CREATED) {
                assert (msg.jettonAmount >= storage.depositAmount + storage.monthRent) throw ERR_INSUFFICIENT_FUNDS;
                balances.deposit = storage.depositAmount;
                balances.rentBalance = msg.jettonAmount - storage.depositAmount;
                balances.rentPaid = msg.jettonAmount - storage.depositAmount;
                var month0: MonthStorage = storage.months.mustGet(0);
                month0.state = MonthState.PAID;
                storage.months.set(0, month0);
                storage.globalState = GlobalState.CHECK_IN;
            } else if (storage.globalState == GlobalState.ACTIVE) {
                balances.rentBalance += msg.jettonAmount;
                balances.rentPaid += msg.jettonAmount;
                var monthData: MonthStorage = storage.months.mustGet(storage.currentMonth);
                if (monthData.state == MonthState.PENDING && balances.rentBalance >= storage.monthRent) {
                    monthData.state = MonthState.PAID;
                    storage.months.set(storage.currentMonth, monthData);
                }
            } else {
                throw ERR_WRONG_STATE;
            }
            storage.balances = balances.toCell();
            storage.save();
        }
        OpenDisput => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyAdmin(in.senderAddress, storage);
            assert (storage.globalState != GlobalState.DISPUTE) throw ERR_DISPUTE_OPENED;
            assert (storage.globalState != GlobalState.COMPLETED) throw ERR_CONTRACT_COMPLETED;
            storage.globalState = GlobalState.DISPUTE;
            updateCurrentMonthState(mutate storage, MonthState.DISPUTE);
            storage.save();
        }

        ReleaseMonthRent => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyAdmin(in.senderAddress, storage);
            assert (storage.globalState == GlobalState.ACTIVE) throw ERR_CONTRACT_NOT_ACTIVE;
            var month = msg.month;
            var queryId = msg.queryId;
            var ts = blockchain.now() as uint32;
            var monthData: MonthStorage = storage.months.mustGet(month);
            assert (monthData.dueTs < ts) throw ERR_WRONG_MONTH;
            assert (monthData.state == MonthState.PAID) throw ERR_WRONG_MONTH_STATE;
            var balances: Balances = storage.balances.load();
            assert (balances.rentBalance >= storage.monthRent) throw ERR_INSUFFICIENT_FUNDS;
            sendRentToLandlord(mutate storage, month, queryId, null);
            balances.rentBalance -= storage.monthRent;
            balances.rentReleased += storage.monthRent;
            monthData.state = MonthState.RELEASED;
            storage.months.set(month, monthData);
            storage.balances = balances.toCell();
            if (month == MONTHS_IN_LEASE - 1) {
                storage.globalState = GlobalState.CHECK_OUT;
            } else {
                storage.currentMonth += 1;
                setLastMonthDueTsTime(mutate storage);
                var nextMonth: MonthStorage = storage.months.mustGet(storage.currentMonth);
                if (nextMonth.state == MonthState.PENDING && balances.rentBalance >= storage.monthRent) {
                    nextMonth.state = MonthState.PAID;
                    storage.months.set(storage.currentMonth, nextMonth);
                }
            }
            storage.save();
        }

        ResolveDispute => {
            var storage = lazy RentStorage.load();
            onlyAdmin(in.senderAddress, storage);
            assert (storage.globalState == GlobalState.DISPUTE) throw ERR_WRONG_STATE;
            var rentToTenant = msg.rentToTenant;
            var rentToLandlord = msg.rentToLandlord;
            var depositToTenant = msg.depositToTenant;
            var depositToLandlord = msg.depositToLandlord;
            var balances: Balances = storage.balances.load();
            assert (rentToTenant + rentToLandlord <= balances.rentBalance) throw ERR_INVALID_AMOUNT;
            assert (depositToTenant + depositToLandlord <= balances.deposit) throw ERR_INVALID_AMOUNT;
            if (rentToTenant > 0) {
                balances.rentBalance -= rentToTenant;
                balances.rentReleased += rentToTenant;
                sendRentToTenant(mutate storage, DISPUTE_MONTH as uint8, msg.queryId, rentToTenant);
            }
            if (rentToLandlord > 0) {
                balances.rentBalance -= rentToLandlord;
                balances.rentReleased += rentToLandlord;
                sendRentToLandlord(mutate storage, DISPUTE_MONTH as uint8, msg.queryId, rentToLandlord);
            }
            if (depositToTenant > 0) {
                balances.deposit -= depositToTenant;
                sendDepositToTenant(mutate storage, msg.queryId, depositToTenant);
            }
            if (depositToLandlord > 0) {
                balances.deposit -= depositToLandlord;
                sendDepositToLandlord(mutate storage, msg.queryId, depositToLandlord);
            }
            if (rentToTenant == 0 && rentToLandlord == 0 && depositToTenant == 0 && depositToLandlord == 0) {
                storage.globalState = GlobalState.ACTIVE;
            }
            storage.balances = balances.toCell();
            storage.save();
        }

        CloseRentContract => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyAdmin(in.senderAddress, storage);
            assert (storage.globalState == GlobalState.ACTIVE) throw ERR_CONTRACT_NOT_ACTIVE;
            var balances: Balances = storage.balances.load();
            if (balances.deposit > 0) {
                sendDepositToTenant(mutate storage, 0, balances.deposit);
                balances.deposit = 0;
                storage.balances = balances.toCell();
            }
            storage.globalState = GlobalState.COMPLETED;
            storage.save();
        }
        //TENANT
        ConfirmCheckIn => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyTenant(in.senderAddress, storage);
            assert (storage.globalState == GlobalState.CHECK_IN) throw ERR_WRONG_STATE;
            storage.globalState = GlobalState.ACTIVE;
            setCheckInConfirmedTime(mutate storage);
            storage.save();
        }
        OpenCheckInDispute => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyTenant(in.senderAddress, storage);
            assert (storage.globalState == GlobalState.ACTIVE) throw ERR_WRONG_STATE;
            assert (
                blockchain.now() - getCheckInConfirmedTime(storage) < 24 * 60 * 60
            ) throw ERR_WRONG_TIME;
            storage.globalState = GlobalState.DISPUTE;
            updateCurrentMonthState(mutate storage, MonthState.DISPUTE);
            setDisputeStartTime(mutate storage);
            storage.save();
        }
        OpenMonthDispute => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyTenant(in.senderAddress, storage);
            assert (storage.globalState == GlobalState.ACTIVE) throw ERR_WRONG_STATE;
            assert (
                blockchain.now() - getLastMonthDueTsTime(storage) < 24 * 60 * 60
            ) throw ERR_WRONG_TIME;
            storage.globalState = GlobalState.DISPUTE;
            updateCurrentMonthState(mutate storage, MonthState.DISPUTE);
            setDisputeStartTime(mutate storage);
            storage.save();
        }
        ConfirmCheckOutTenant => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyTenant(in.senderAddress, storage);
            assert (storage.globalState == GlobalState.CHECK_OUT) throw ERR_WRONG_STATE;
            setCheckOutConfirmedTime(mutate storage);
            storage.save();
        }
        OpenCheckOutDispute => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyLandlord(in.senderAddress, storage);
            assert (storage.globalState == GlobalState.CHECK_OUT) throw ERR_WRONG_STATE;
            assert (
                blockchain.now() - getCheckOutConfirmedTime(storage) < 24 * 60 * 60
            ) throw ERR_WRONG_TIME;
            storage.globalState = GlobalState.DISPUTE;
            updateCurrentMonthState(mutate storage, MonthState.DISPUTE);
            setDisputeStartTime(mutate storage);
            storage.save();
        }
        ConfirmCheckOutLandloard => {
            var storage: RentStorage = lazy RentStorage.load();
            onlyLandlord(in.senderAddress, storage);
            assert (storage.globalState == GlobalState.CHECK_OUT) throw ERR_WRONG_STATE;
            assert (blockchain.now() - getCheckOutConfirmedTime(storage) > 24 * 60 * 60) throw ERR_WRONG_TIME;
            var balances: Balances = storage.balances.load();
            if (balances.deposit > 0) {
                sendDepositToTenant(mutate storage, 0, balances.deposit);
                balances.deposit = 0;
                storage.balances = balances.toCell();
            }
            storage.globalState = GlobalState.COMPLETED;
            storage.save();
        }
    }
}

// ─── GET methods ──────────────────────────────────────────────────────────────

/** Current global state as integer (see GlobalState enum). */
get fun getGlobalState(): int {
    return RentStorage.load().globalState as int;
}

/**
 * Main contract info in one call.
 * Returns: (admin, tenant, landlord, globalState, currentMonth, startTs, monthRent, depositAmount)
 */
get fun getInfo() {
    val s = RentStorage.load();
    return (
        s.extra.load().administrative.load().admin,
        s.extra.load().clients.load().tenant,
        s.extra.load().clients.load().landlord,
        s.globalState as int,
        s.currentMonth as int,
        s.startTs as int,
        s.monthRent,
        s.depositAmount,
    );
}

/**
 * Current balance snapshot.
 * Returns: (deposit, rentPaid, rentReleased, rentBalance)
 */
get fun getBalances() {
    val s = RentStorage.load();
    val b: Balances = s.balances.load();
    return (b.deposit, b.rentPaid, b.rentReleased, b.rentBalance);
}

/**
 * Info for a specific month (0-11).
 * Returns: (state, dueTs)
 */
get fun getMonthInfo(month: uint8) {
    val s = RentStorage.load();
    val m: MonthStorage = s.months.mustGet(month);
    return (m.state as int, m.dueTs as int);
}

/**
 * Returns the contract's own USDT jetton wallet address.
 * Returns addr_none (null) if InitContract hasn't completed yet.
 */
get fun getJettonWallet(): address? {
    val extra: ExtraFields = RentStorage.load().extra.load();
    return extra.administrative.load().jettonWallet;
}

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix(); // skip 0xFFFFFFFF

    val msg = lazy TheoreticallyBounceable.fromSlice(in.bouncedBody);
    match (msg) {
        AskToTransfer => {
            // The jetton wallet rejected the transfer — roll back state
            val purpose = (msg.queryId >> 56) & 0xFF;
            val month = ((msg.queryId >> 48) & 0xFF) as uint8;
            var storage: RentStorage = lazy RentStorage.load();
            var balances = storage.balances.load();
            match (purpose as Purpose) {
                Purpose.DEPOSIT => {
                    balances.deposit += msg.jettonAmount;
                }
                Purpose.RENT => {
                    balances.rentReleased -= msg.jettonAmount;
                    balances.rentBalance += msg.jettonAmount;
                    // restore month state only for regular releases, not dispute resolution
                    if (month != DISPUTE_MONTH as uint8) {
                        var monthData: MonthStorage = storage.months.mustGet(month);
                        monthData.state = MonthState.PAID;
                        storage.months.set(month, monthData);
                        if (month == MONTHS_IN_LEASE - 1 && storage.globalState == GlobalState.CHECK_OUT) {
                            storage.globalState = GlobalState.ACTIVE;
                        }
                    }
                }
            }
            storage.balances = balances.toCell();
            storage.save();
        }
        ProvideWalletAddress => {
            var storage: RentStorage = lazy RentStorage.load();
            var extra: ExtraFields = storage.extra.load();
            var administrative = extra.administrative.load();
            administrative.jettonWallet = null;
            extra.administrative = administrative.toCell();
            storage.extra = extra.toCell();
            storage.save();
        }
    }
}
