// ============================================================================
// XionTon - Decentralized Matrix System
// Smart Contract v2.1 (Tact Language)
// ============================================================================

import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

const TABLE_1_PRICE:  Int = ton("0.0001");
const TABLE_2_PRICE:  Int = ton("0.0002");
const TABLE_3_PRICE:  Int = ton("0.0004");
const TABLE_4_PRICE:  Int = ton("0.0008");
const TABLE_5_PRICE:  Int = ton("0.0016");
const TABLE_6_PRICE:  Int = ton("0.0032");
const TABLE_7_PRICE:  Int = ton("0.0064");
const TABLE_8_PRICE:  Int = ton("0.0128");
const TABLE_9_PRICE:  Int = ton("0.0256");
const TABLE_10_PRICE: Int = ton("0.0512");
const TABLE_11_PRICE: Int = ton("0.1024");
const TABLE_12_PRICE: Int = ton("0.2048");

const ENTRY_FEE:          Int = ton("0.000005");
const EXIT_FEE:           Int = ton("0.000005");
const SYSTEM_FEE_PERCENT: Int = 10;
const MIN_CONTRACT_BALANCE: Int = ton("1");
const GAS_RESERVE:          Int = ton("0.000003");
const MAX_TABLES: Int = 12;
const MAX_SLOTS:  Int = 4;
const MAX_HOPS:   Int = 100;

message(0x100) Register { referrer: Address; }
message(0x101) BuyTable { tableNum: Int as uint8; }
message(0x200) ChangeMaster { newMaster: Address; coSigner: Address; }
message(0x201) ConfirmAdminAction { actionId: Int as uint32; }
message(0x202) ChangeSystemWallet { newSystemWallet: Address; coSigner: Address; }
message(0x203) UpgradeLogic { newCode: Cell; coSigner: Address; }
message(0x204) EmergencyWithdraw { amount: Int as coins; to: Address; coSigner: Address; }
message(0x205) SetPaused { paused: Bool; }
message(0x206) SetCoSigner { coSigner: Address; }
message(0x207) WithdrawExcess {}

message(0x300) EventSlotFilled { tableNum: Int as uint8; slotNum: Int as uint8; owner: Address; source: Address; amount: Int as coins; }
message(0x301) EventPayout { tableNum: Int as uint8; slotNum: Int as uint8; receiver: Address; amount: Int as coins; }
message(0x302) EventFrozen { tableNum: Int as uint8; owner: Address; frozenAmount: Int as coins; }
message(0x303) EventUnfrozen { tableNum: Int as uint8; owner: Address; totalAmount: Int as coins; nextTableActivated: Int as uint8; }
message(0x304) EventSpillover { tableNum: Int as uint8; fromUser: Address; toUser: Address; amount: Int as coins; hops: Int as uint32; }
message(0x305) EventReactivation { tableNum: Int as uint8; owner: Address; cycleCount: Int as uint32; }
message(0x306) EventTableActivated { tableNum: Int as uint8; owner: Address; triggeredBy: Address; }
message(0x307) EventPayoutBounced { tableNum: Int as uint8; receiver: Address; amount: Int as coins; }
message(0x308) EventUserRegistered { user: Address; upline: Address; }
message(0x309) EventSystemFee { tableNum: Int as uint8; amount: Int as coins; feeType: Int as uint8; }

struct UserTable {
    active:        Bool;
    slotsFilled:   Int as uint8;
    slot1:         Address?;
    slot2:         Address?;
    slot3:         Address?;
    slot4:         Address?;
    frozen2Amount: Int as coins;
    cycleCount:    Int as uint32;
}

struct UserData {
    registered: Bool;
    upline:     Address;
    isMaster:   Bool;
}

struct PendingAction {
    actionType: Int as uint8;
    initiator:  Address;
    coSigner:   Address;
    newAddress: Address?;
    amount:     Int as coins;
    newCode:    Cell?;
    expiry:     Int as uint32;
}

contract MatrixTON with Deployable, Ownable, Resumable {

    owner:        Address;
    masterWallet: Address;
    systemWallet: Address;
    stopped:      Bool = false;
    coSigner:     Address;
    processing:   Bool = false;

    users: map<Address, UserData>;

    userTables1:  map<Address, UserTable>;
    userTables2:  map<Address, UserTable>;
    userTables3:  map<Address, UserTable>;
    userTables4:  map<Address, UserTable>;
    userTables5:  map<Address, UserTable>;
    userTables6:  map<Address, UserTable>;
    userTables7:  map<Address, UserTable>;
    userTables8:  map<Address, UserTable>;
    userTables9:  map<Address, UserTable>;
    userTables10: map<Address, UserTable>;
    userTables11: map<Address, UserTable>;
    userTables12: map<Address, UserTable>;

    pendingActions: map<Int, PendingAction>;
    nextActionId:   Int as uint32 = 0;
    version:        Int as uint32 = 2;
    bouncedPayouts: map<Address, Int>;

    totalUsers:      Int as uint32 = 0;
    totalPayouts:    Int as coins  = 0;
    totalSystemFees: Int as coins  = 0;

    init(masterWallet: Address, systemWallet: Address, coSigner: Address) {
        self.owner        = sender();
        self.masterWallet = masterWallet;
        self.systemWallet = systemWallet;
        self.coSigner     = coSigner;
        self._registerMaster();
    }

    receive(msg: Register) {
        self.requireNotStopped();
        require(!self.processing, "Reentrant call detected");
        self.processing = true;
        let user: Address = sender();
        require(self.users.get(user) == null, "Already registered");
        let referrer: Address = msg.referrer;
        if (self.users.get(referrer) == null) { referrer = self.masterWallet; }
        let required: Int = TABLE_1_PRICE + ENTRY_FEE + GAS_RESERVE;
        require(context().value >= required, "Insufficient payment");
        self.users.set(user, UserData{ registered: true, upline: referrer, isMaster: false });
        self.totalUsers += 1;
        self._activateTable(user, 1, user);
        let systemFee: Int = self._calcSystemFee(TABLE_1_PRICE);
        self._sendSystem(ENTRY_FEE + systemFee, 1, 1);
        let payout: Int = self._calcPayout(TABLE_1_PRICE);
        let target: Address = self._findSpilloverTarget(referrer, 1);
        emit(EventSpillover{ tableNum: 1, fromUser: user, toUser: target, amount: payout, hops: 0 }.toCell());
        emit(EventUserRegistered{ user: user, upline: referrer }.toCell());
        self._processSlot(target, 1, user, payout);
        self.processing = false;
    }

    receive(msg: BuyTable) {
        self.requireNotStopped();
        require(!self.processing, "Reentrant call detected");
        self.processing = true;
        let user: Address = sender();
        let tableNum: Int = msg.tableNum;
        require(self.users.get(user) != null, "Not registered");
        require(tableNum >= 2 && tableNum <= MAX_TABLES, "Invalid table number");
        let prevTable: UserTable? = self._getUserTable(user, tableNum - 1);
        require(prevTable != null && prevTable!!.active, "Previous table not active");
        let curTable: UserTable? = self._getUserTable(user, tableNum);
        require(curTable == null || !curTable!!.active, "Table already active");
        let price: Int = self._getPrice(tableNum);
        require(context().value >= price + ENTRY_FEE + GAS_RESERVE, "Insufficient payment");
        self._activateTable(user, tableNum, user);
        self._sendSystem(ENTRY_FEE + self._calcSystemFee(price), tableNum, 1);
        let payout: Int = self._calcPayout(price);
        let target: Address = self._findSpilloverTarget(user, tableNum);
        emit(EventSpillover{ tableNum: tableNum, fromUser: user, toUser: target, amount: payout, hops: 0 }.toCell());
        self._processSlot(target, tableNum, user, payout);
        // Auto-withdraw excess gas to system wallet
        let contractBalance: Int = myBalance();
        let threshold: Int = ton("10") + MIN_CONTRACT_BALANCE;
        if (contractBalance > threshold) {
            let excess: Int = contractBalance - threshold;
            self._sendTON(self.systemWallet, excess, "EXCESS:GAS");
        }
        self.processing = false;
    }

    receive(msg: SetCoSigner) { self.requireOwner(); self.coSigner = msg.coSigner; }
    receive(msg: SetPaused)   { self.requireOwner(); self.stopped = msg.paused; }

    receive(msg: ChangeMaster) {
        self.requireOwner();
        require(msg.coSigner == self.coSigner, "Invalid co-signer");
        let actionId: Int = self.nextActionId;
        self.nextActionId += 1;
        self.pendingActions.set(actionId, PendingAction{ actionType: 1, initiator: sender(), coSigner: msg.coSigner, newAddress: msg.newMaster, amount: 0, newCode: null, expiry: now() + 3600 });
    }

    receive(msg: ChangeSystemWallet) {
        self.requireOwner();
        require(msg.coSigner == self.coSigner, "Invalid co-signer");
        let actionId: Int = self.nextActionId;
        self.nextActionId += 1;
        self.pendingActions.set(actionId, PendingAction{ actionType: 2, initiator: sender(), coSigner: msg.coSigner, newAddress: msg.newSystemWallet, amount: 0, newCode: null, expiry: now() + 3600 });
    }

    receive(msg: UpgradeLogic) {
        self.requireOwner();
        require(msg.coSigner == self.coSigner, "Invalid co-signer");
        let actionId: Int = self.nextActionId;
        self.nextActionId += 1;
        self.pendingActions.set(actionId, PendingAction{ actionType: 3, initiator: sender(), coSigner: msg.coSigner, newAddress: null, amount: 0, newCode: msg.newCode, expiry: now() + 3600 });
    }

    receive(msg: EmergencyWithdraw) {
        self.requireOwner();
        require(msg.coSigner == self.coSigner, "Invalid co-signer");
        let available: Int = myBalance() - MIN_CONTRACT_BALANCE;
        require(msg.amount > 0 && msg.amount <= available, "Invalid amount");
        let actionId: Int = self.nextActionId;
        self.nextActionId += 1;
        self.pendingActions.set(actionId, PendingAction{ actionType: 4, initiator: sender(), coSigner: msg.coSigner, newAddress: msg.to, amount: msg.amount, newCode: null, expiry: now() + 3600 });
    }

    receive(msg: ConfirmAdminAction) {
        require(sender() == self.coSigner, "Only co-signer can confirm");
        let action: PendingAction? = self.pendingActions.get(msg.actionId);
        require(action != null, "Action not found");
        let a: PendingAction = action!!;
        require(now() <= a.expiry, "Action expired");
        if (a.actionType == 1) {
            let oldMaster: UserData? = self.users.get(self.masterWallet);
            if (oldMaster != null) {
                let od: UserData = oldMaster!!;
                self.users.set(self.masterWallet, UserData{ registered: od.registered, upline: od.upline, isMaster: false });
            }
            self.masterWallet = a.newAddress!!;
            self._registerMaster();
        } else if (a.actionType == 2) {
            self.systemWallet = a.newAddress!!;
        } else if (a.actionType == 3) {
            self.pendingActions.del(msg.actionId);
            // upgrade via migration - setCode not available in this tact version
            return;
        } else if (a.actionType == 4) {
            let available: Int = myBalance() - MIN_CONTRACT_BALANCE;
            require(a.amount <= available, "Insufficient balance now");
            self._sendTON(a.newAddress!!, a.amount, "EMERGENCY");
        }
        self.pendingActions.del(msg.actionId);
    }

    bounced(src: Slice) {





    }

    fun _processSlot(owner: Address, tableNum: Int, sourceUser: Address, payoutAmount: Int) {
        let ownerData: UserData? = self.users.get(owner);
        require(ownerData != null, "Owner not registered");
        let od: UserData = ownerData!!;
        let table: UserTable? = self._getUserTable(owner, tableNum);
        require(table != null, "Table not found");
        let t: UserTable = table!!;
        require(t.active, "Table not active");
        require(t.slotsFilled < MAX_SLOTS, "Table full");
        let nextSlot: Int = t.slotsFilled + 1;
        let updatedTable: UserTable = self._setSlot(t, nextSlot, sourceUser);
        updatedTable.slotsFilled = nextSlot;

        if (od.isMaster) {
            let netPayout: Int = payoutAmount - EXIT_FEE;
            if (netPayout > 0) {
                self._sendTON(owner, netPayout, "PAYOUT:MASTER");
                self.totalPayouts += netPayout;
                self._sendSystem(EXIT_FEE, tableNum, 2);
            }
            if (nextSlot == MAX_SLOTS) {
                updatedTable = self._reactivateTable(updatedTable);
                emit(EventReactivation{ tableNum: tableNum, owner: owner, cycleCount: updatedTable.cycleCount }.toCell());
            }
            self._setUserTable(owner, tableNum, updatedTable);
            emit(EventSlotFilled{ tableNum: tableNum, slotNum: nextSlot, owner: owner, source: sourceUser, amount: payoutAmount }.toCell());
            emit(EventPayout{ tableNum: tableNum, slotNum: nextSlot, receiver: owner, amount: netPayout }.toCell());
            return;
        }

        if (nextSlot == 1) {
            let netPayout: Int = payoutAmount - EXIT_FEE;
            if (netPayout > 0) { self._sendTON(owner, netPayout, "PAYOUT:S1"); self.totalPayouts += netPayout; self._sendSystem(EXIT_FEE, tableNum, 2); }
            emit(EventPayout{ tableNum: tableNum, slotNum: 1, receiver: owner, amount: netPayout }.toCell());
        } else if (nextSlot == 2) {
            let nextActive: Bool = self._isNextTableActive(owner, tableNum);
            if (nextActive) {
                let netPayout: Int = payoutAmount - EXIT_FEE;
                if (netPayout > 0) { self._sendTON(owner, netPayout, "PAYOUT:S2"); self.totalPayouts += netPayout; self._sendSystem(EXIT_FEE, tableNum, 2); }
                emit(EventPayout{ tableNum: tableNum, slotNum: 2, receiver: owner, amount: netPayout }.toCell());
            } else {
                updatedTable.frozen2Amount = payoutAmount;
                emit(EventFrozen{ tableNum: tableNum, owner: owner, frozenAmount: payoutAmount }.toCell());
            }
        } else if (nextSlot == 3) {
            let nextActive: Bool = self._isNextTableActive(owner, tableNum);
            if (nextActive) {
                let netPayout: Int = payoutAmount - EXIT_FEE;
                if (netPayout > 0) { self._sendTON(owner, netPayout, "PAYOUT:S3"); self.totalPayouts += netPayout; self._sendSystem(EXIT_FEE, tableNum, 2); }
                emit(EventPayout{ tableNum: tableNum, slotNum: 3, receiver: owner, amount: netPayout }.toCell());
            } else {
                let totalAmount: Int = updatedTable.frozen2Amount + payoutAmount;
                updatedTable.frozen2Amount = 0;
                let nextTableNum: Int = tableNum + 1;
                if (nextTableNum <= MAX_TABLES) { self._activateTable(owner, nextTableNum, owner); }
                emit(EventUnfrozen{ tableNum: tableNum, owner: owner, totalAmount: totalAmount, nextTableActivated: nextTableNum }.toCell());
                self._setUserTable(owner, tableNum, updatedTable);
                if (nextTableNum <= MAX_TABLES) {
                    let spillTarget: Address = self._findSpilloverTarget(owner, nextTableNum);
                    emit(EventSpillover{ tableNum: nextTableNum, fromUser: owner, toUser: spillTarget, amount: totalAmount, hops: 0 }.toCell());
                    self._processSlot(spillTarget, nextTableNum, owner, totalAmount);
                }
                emit(EventSlotFilled{ tableNum: tableNum, slotNum: nextSlot, owner: owner, source: sourceUser, amount: payoutAmount }.toCell());
                return;
            }
        } else if (nextSlot == MAX_SLOTS) {
            updatedTable = self._reactivateTable(updatedTable);
            emit(EventReactivation{ tableNum: tableNum, owner: owner, cycleCount: updatedTable.cycleCount }.toCell());
            let spillTableNum: Int = tableNum + 1;
            if (tableNum == MAX_TABLES) { spillTableNum = MAX_TABLES; }
            self._setUserTable(owner, tableNum, updatedTable);
            let spillTarget: Address = self._findSpilloverTarget(owner, spillTableNum);
            emit(EventSpillover{ tableNum: spillTableNum, fromUser: owner, toUser: spillTarget, amount: payoutAmount, hops: 0 }.toCell());
            self._processSlot(spillTarget, spillTableNum, owner, payoutAmount);
            emit(EventSlotFilled{ tableNum: tableNum, slotNum: nextSlot, owner: owner, source: sourceUser, amount: payoutAmount }.toCell());
            return;
        }

        self._setUserTable(owner, tableNum, updatedTable);
        emit(EventSlotFilled{ tableNum: tableNum, slotNum: nextSlot, owner: owner, source: sourceUser, amount: payoutAmount }.toCell());
    }

    fun _findSpilloverTarget(startUser: Address, tableNum: Int): Address {
        let current: Address = startUser;
        let hops: Int = 0;
        while (hops < MAX_HOPS) {
            let userData: UserData? = self.users.get(current);
            if (userData == null) { return self.masterWallet; }
            let ud: UserData = userData!!;
            let parent: Address = ud.upline;
            let parentData: UserData? = self.users.get(parent);
            if (parentData == null) { return self.masterWallet; }
            let pd: UserData = parentData!!;
            if (pd.isMaster) { return parent; }
            let parentTable: UserTable? = self._getUserTable(parent, tableNum);
            if (parentTable != null) {
                let pt: UserTable = parentTable!!;
                if (pt.active && pt.slotsFilled < MAX_SLOTS) { return parent; }
            }
            current = parent;
            hops += 1;
        }
        return self.masterWallet;
    }

    fun _isNextTableActive(user: Address, tableNum: Int): Bool {
        if (tableNum >= MAX_TABLES) { return true; }
        let nextTable: UserTable? = self._getUserTable(user, tableNum + 1);
        return nextTable != null && nextTable!!.active;
    }

    fun _registerMaster() {
        self.users.set(self.masterWallet, UserData{ registered: true, upline: self.masterWallet, isMaster: true });
        let i: Int = 1;
        while (i <= MAX_TABLES) { self._activateTable(self.masterWallet, i, self.masterWallet); i += 1; }
    }

    fun _activateTable(user: Address, tableNum: Int, triggeredBy: Address) {
        let cycleCount: Int = 0;
        let existing: UserTable? = self._getUserTable(user, tableNum);
        if (existing != null) { cycleCount = existing!!.cycleCount; }
        self._setUserTable(user, tableNum, UserTable{ active: true, slotsFilled: 0, slot1: null, slot2: null, slot3: null, slot4: null, frozen2Amount: 0, cycleCount: cycleCount });
        emit(EventTableActivated{ tableNum: tableNum, owner: user, triggeredBy: triggeredBy }.toCell());
    }

    fun _reactivateTable(table: UserTable): UserTable {
        return UserTable{ active: true, slotsFilled: 0, slot1: null, slot2: null, slot3: null, slot4: null, frozen2Amount: 0, cycleCount: table.cycleCount + 1 };
    }

    fun _setSlot(table: UserTable, slotNum: Int, user: Address): UserTable {
        let result: UserTable = table;
        if (slotNum == 1) { result.slot1 = user; }
        else if (slotNum == 2) { result.slot2 = user; }
        else if (slotNum == 3) { result.slot3 = user; }
        else if (slotNum == 4) { result.slot4 = user; }
        return result;
    }

    fun _getPrice(tableNum: Int): Int {
        if (tableNum == 1)  { return TABLE_1_PRICE;  }
        if (tableNum == 2)  { return TABLE_2_PRICE;  }
        if (tableNum == 3)  { return TABLE_3_PRICE;  }
        if (tableNum == 4)  { return TABLE_4_PRICE;  }
        if (tableNum == 5)  { return TABLE_5_PRICE;  }
        if (tableNum == 6)  { return TABLE_6_PRICE;  }
        if (tableNum == 7)  { return TABLE_7_PRICE;  }
        if (tableNum == 8)  { return TABLE_8_PRICE;  }
        if (tableNum == 9)  { return TABLE_9_PRICE;  }
        if (tableNum == 10) { return TABLE_10_PRICE; }
        if (tableNum == 11) { return TABLE_11_PRICE; }
        if (tableNum == 12) { return TABLE_12_PRICE; }
        return 0;
    }

    fun _calcSystemFee(price: Int): Int { return price * SYSTEM_FEE_PERCENT / 100; }
    fun _calcPayout(price: Int): Int { return price * (100 - SYSTEM_FEE_PERCENT) / 100; }

    fun _sendTON(to: Address, amount: Int, comment: String) {
        if (amount <= 0) { return; }
        send(SendParameters{ to: to, value: amount, mode: SendPayGasSeparately, body: comment.asComment(), bounce: true });
    }

    fun _sendSystem(amount: Int, tableNum: Int, feeType: Int) {
        if (amount <= 0) { return; }
        send(SendParameters{ to: self.systemWallet, value: amount, mode: SendPayGasSeparately | SendIgnoreErrors, bounce: false, body: "SYS:FEE".asComment() });
        self.totalSystemFees += amount;
        emit(EventSystemFee{ tableNum: tableNum, amount: amount, feeType: feeType }.toCell());
    }

    fun _getUserTable(user: Address, tableNum: Int): UserTable? {
        if (tableNum == 1)  { return self.userTables1.get(user);  }
        if (tableNum == 2)  { return self.userTables2.get(user);  }
        if (tableNum == 3)  { return self.userTables3.get(user);  }
        if (tableNum == 4)  { return self.userTables4.get(user);  }
        if (tableNum == 5)  { return self.userTables5.get(user);  }
        if (tableNum == 6)  { return self.userTables6.get(user);  }
        if (tableNum == 7)  { return self.userTables7.get(user);  }
        if (tableNum == 8)  { return self.userTables8.get(user);  }
        if (tableNum == 9)  { return self.userTables9.get(user);  }
        if (tableNum == 10) { return self.userTables10.get(user); }
        if (tableNum == 11) { return self.userTables11.get(user); }
        if (tableNum == 12) { return self.userTables12.get(user); }
        return null;
    }

    fun _setUserTable(user: Address, tableNum: Int, table: UserTable) {
        if (tableNum == 1)  { self.userTables1.set(user, table);  }
        if (tableNum == 2)  { self.userTables2.set(user, table);  }
        if (tableNum == 3)  { self.userTables3.set(user, table);  }
        if (tableNum == 4)  { self.userTables4.set(user, table);  }
        if (tableNum == 5)  { self.userTables5.set(user, table);  }
        if (tableNum == 6)  { self.userTables6.set(user, table);  }
        if (tableNum == 7)  { self.userTables7.set(user, table);  }
        if (tableNum == 8)  { self.userTables8.set(user, table);  }
        if (tableNum == 9)  { self.userTables9.set(user, table);  }
        if (tableNum == 10) { self.userTables10.set(user, table); }
        if (tableNum == 11) { self.userTables11.set(user, table); }
        if (tableNum == 12) { self.userTables12.set(user, table); }
    }

    receive(msg: WithdrawExcess) {
        self.requireOwner();
        let threshold: Int = ton("10");
        let available: Int = myBalance() - MIN_CONTRACT_BALANCE;
        if (available > threshold) {
            let excess: Int = available - threshold;
            self._sendTON(self.masterWallet, excess, "EXCESS:GAS");
        }
    }

    get fun getUserData(user: Address): UserData? { return self.users.get(user); }
    get fun getUserTable(user: Address, tableNum: Int): UserTable? { return self._getUserTable(user, tableNum); }
    get fun isRegistered(user: Address): Bool { return self.users.get(user) != null; }
    get fun getUpline(user: Address): Address? { let d: UserData? = self.users.get(user); if (d != null) { return d!!.upline; } return null; }
    get fun getTablePrice(tableNum: Int): Int { return self._getPrice(tableNum); }
    get fun getPayoutAmount(tableNum: Int): Int { return self._calcPayout(self._getPrice(tableNum)) - EXIT_FEE; }
    get fun getSystemFee(tableNum: Int): Int { return self._calcSystemFee(self._getPrice(tableNum)) + ENTRY_FEE + EXIT_FEE; }
    get fun getMasterWallet(): Address { return self.masterWallet; }
    get fun getSystemWallet(): Address { return self.systemWallet; }
    get fun getCoSigner(): Address { return self.coSigner; }
    get fun getContractBalance(): Int { return myBalance(); }
    get fun isStopped(): Bool { return self.stopped; }
    get fun getBouncedPayouts(user: Address): Int { let b: Int? = self.bouncedPayouts.get(user); if (b != null) { return b!!; } return 0; }
    get fun findSpilloverTarget(startUser: Address, tableNum: Int): Address { return self._findSpilloverTarget(startUser, tableNum); }
    get fun getPendingAction(actionId: Int): PendingAction? { return self.pendingActions.get(actionId); }

    get fun getStats(): map<Int, Int> {
        let s: map<Int, Int> = emptyMap();
        s.set(1, self.totalUsers);
        s.set(2, self.totalPayouts);
        s.set(3, self.totalSystemFees);
        return s;
    }

    get fun getUserAllTables(user: Address): map<Int, Int> {
        let result: map<Int, Int> = emptyMap();
        let i: Int = 1;
        while (i <= MAX_TABLES) {
            let t: UserTable? = self._getUserTable(user, i);
            if (t != null) {
                let tt: UserTable = t!!;
                let encoded: Int = 0;
                if (tt.active) { encoded = 1000000; }
                encoded = encoded + tt.slotsFilled * 10000 + tt.cycleCount;
                result.set(i, encoded);
            }
            i += 1;
        }
        return result;
    }
}
