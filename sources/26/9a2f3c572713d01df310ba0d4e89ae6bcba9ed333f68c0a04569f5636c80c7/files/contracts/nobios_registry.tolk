import "@stdlib/tvm-dicts"

global admin: address
global domains: dict
global price_ton: int
global treasury: address
global total_registered: int

// Load data
fun loadData() {
    var ds: slice = contract.getData().beginParse();
    admin = ds.loadAddress();
    domains = ds.loadDict();
    price_ton = ds.loadCoins();
    treasury = ds.loadAddress();
    total_registered = ds.loadUint(32);
}

// Save data
fun saveData() {
    contract.setData(beginCell()
        .storeSlice(admin as slice)
        .storeDict(domains)
        .storeCoins(price_ton)
        .storeSlice(treasury as slice)
        .storeUint(total_registered, 32)
        .endCell());
}

// Helper to parse subdomain string
fun slice.parseSd(mutate self): slice {
    var subdomainSfx: slice = self;
    while (subdomainSfx.loadUint(8) != 0) { }
    self.removeLastBits(subdomainSfx.remainingBitsCount());
    return subdomainSfx;
}

const CATEGORY_SITE = 0xad01

// ============================================================================
//  DNS Resolve Method (Standard TEP-81)
// ============================================================================

get fun dnsresolve(subdomain: slice, category: int): (int, cell?) {
    var subdomainBits: int = subdomain.remainingBitsCount();
    assert(subdomainBits % 8 == 0) throw 70;

    if (subdomain.preloadUint(8) == 0) {
        subdomain.skipBits(8);
    }

    var subdomainSuffix: slice = subdomain.parseSd();
    var subdomainSuffixBits: int = subdomainSuffix.remainingBitsCount();

    loadData();

    var domainHash = subdomain.bitsHash();
    var (recordSlice: slice?, found: bool) = domains.uDictGet(256, domainHash);
    
    if (!found) {
        return (0, null);
    }

    var recordSliceMut: slice = recordSlice!;
    var owner: address = recordSliceMut.loadAddress();
    var adnlAddress: int = recordSliceMut.loadUint(256);
    var createdAt: int = recordSliceMut.loadUint(32);
    var expiresAt: int = recordSliceMut.loadUint(32);
    var metadataIpfs: cell = recordSliceMut.loadRef();

    // Do not return records if expired
    if (blockchain.now() > expiresAt) {
        return (0, null);
    }

    if (subdomainSuffixBits > 0) {
        category = stringSha256("dns_next_resolver");
    }

    var resolved: int = subdomainBits - subdomainSuffixBits;
    var records: dict = createEmptyDict();
    
    if (adnlAddress != 0) {
        var adnlValue = beginCell().storeUint(0xad01, 16).storeUint(adnlAddress, 256).endCell();
        records.uDictSetRef(256, CATEGORY_SITE, adnlValue);
    }
    
    if (category == 0) {
        return (resolved, records);
    }

    var (vCell: cell?, f2: bool) = records.uDictGetRef(256, category);
    if (!f2) { return (0, null); }
    return (resolved, vCell);
}

get fun get_domain_info(domainHash: int): (address, int, int, int, cell) {
    loadData();
    var (recordSlice: slice?, found: bool) = domains.uDictGet(256, domainHash);
    assert(found) throw 404;
    var recordSliceMut: slice = recordSlice!;
    var owner: address = recordSliceMut.loadAddress();
    var adnlAddress: int = recordSliceMut.loadUint(256);
    var createdAt: int = recordSliceMut.loadUint(32);
    var expiresAt: int = recordSliceMut.loadUint(32);
    var metadataIpfs: cell = recordSliceMut.loadRef();
    return (owner, adnlAddress, createdAt, expiresAt, metadataIpfs);
}

get fun get_price(): int {
    loadData();
    return price_ton;
}

get fun get_total_registered(): int {
    loadData();
    return total_registered;
}

get fun is_expired(domainHash: int): int {
    loadData();
    var (recordSlice: slice?, found: bool) = domains.uDictGet(256, domainHash);
    if (!found) { return -1; }
    var recordSliceMut: slice = recordSlice!;
    recordSliceMut.loadAddress();
    recordSliceMut.loadUint(256);
    recordSliceMut.loadUint(32);
    var expiresAt: int = recordSliceMut.loadUint(32);
    if (blockchain.now() > expiresAt) {
        return -1;
    }
    return 0;
}

const OP_REGISTER_SUBDOMAIN = 0x01
const OP_UPDATE_RECORD      = 0x02
const OP_TRANSFER_SUBDOMAIN = 0x03
const OP_RENEW_SUBDOMAIN    = 0x04
const OP_ADMIN_SET_PRICE    = 0x10
const OP_ADMIN_WITHDRAW     = 0x11
const OP_ADMIN_FORCE_DELETE = 0x12

const ONE_YEAR = 31536000

fun onInternalMessage(msgValue: int, inMsg: cell, inMsgBody: slice) {
    if (inMsgBody.isEmpty()) { return; }
    
    var inMsgFull: slice = inMsg.beginParse();
    var flags: int = inMsgFull.loadUint(4);
    if ((flags & 1) != 0) { return; }
    
    var sender: address = inMsgFull.loadAddress();
    loadData();
    
    var op: int = inMsgBody.loadUint(32);
    
    if (op == OP_REGISTER_SUBDOMAIN) {
        assert(msgValue >= price_ton) throw 100;
        
        var domainStr: slice = inMsgBody.loadRef().beginParse();
        var domainHash: int = domainStr.bitsHash();
        
        var (existingSlice: slice?, found: bool) = domains.uDictGet(256, domainHash);
        if (found) {
            var existingSliceMut: slice = existingSlice!;
            existingSliceMut.loadAddress();
            existingSliceMut.loadUint(256);
            existingSliceMut.loadUint(32);
            var existingExpiresAt: int = existingSliceMut.loadUint(32);
            assert(blockchain.now() > existingExpiresAt) throw 101;
        }
        
        var adnlAddress: int = inMsgBody.loadUint(256);
        var metadataIpfs: cell = inMsgBody.loadRef();
        
        var createdAt: int = blockchain.now();
        var expiresAt: int = createdAt + ONE_YEAR;
        
        var newRecord: slice = beginCell()
            .storeSlice(sender as slice)
            .storeUint(adnlAddress, 256)
            .storeUint(createdAt, 32)
            .storeUint(expiresAt, 32)
            .storeRef(metadataIpfs)
            .endCell().beginParse();
            
        domains.uDictSet(256, domainHash, newRecord);
        if (!found) {
            total_registered += 1;
        }
        
        saveData();
        return;
    }
    
    if (op == OP_UPDATE_RECORD) {
        var domainStr: slice = inMsgBody.loadRef().beginParse();
        var domainHash: int = domainStr.bitsHash();
        
        var (recordSlice: slice?, found: bool) = domains.uDictGet(256, domainHash);
        assert(found) throw 404;
        
        var recordSliceMut: slice = recordSlice!;
        var owner: address = recordSliceMut.loadAddress();
        assert((sender as slice).bitsEqual(owner as slice)) throw 403;
        
        var adnlAddress: int = recordSliceMut.loadUint(256);
        var createdAt: int = recordSliceMut.loadUint(32);
        var expiresAt: int = recordSliceMut.loadUint(32);
        var metadataIpfs: cell = recordSliceMut.loadRef();
        
        var newAdnl: int = inMsgBody.loadUint(256);
        var newMetadata: cell = inMsgBody.loadRef();
        
        var newRecord: slice = beginCell()
            .storeSlice(owner as slice)
            .storeUint(newAdnl, 256)
            .storeUint(createdAt, 32)
            .storeUint(expiresAt, 32)
            .storeRef(newMetadata)
            .endCell().beginParse();
            
        domains.uDictSet(256, domainHash, newRecord);
        saveData();
        return;
    }
    
    if (op == OP_TRANSFER_SUBDOMAIN) {
        var domainStr: slice = inMsgBody.loadRef().beginParse();
        var domainHash: int = domainStr.bitsHash();
        
        var (recordSlice: slice?, found: bool) = domains.uDictGet(256, domainHash);
        assert(found) throw 404;
        
        var recordSliceMut: slice = recordSlice!;
        var owner: address = recordSliceMut.loadAddress();
        assert((sender as slice).bitsEqual(owner as slice)) throw 403;
        
        var adnlAddress: int = recordSliceMut.loadUint(256);
        var createdAt: int = recordSliceMut.loadUint(32);
        var expiresAt: int = recordSliceMut.loadUint(32);
        var metadataIpfs: cell = recordSliceMut.loadRef();
        
        var newOwner: address = inMsgBody.loadAddress();
        
        var newRecord: slice = beginCell()
            .storeSlice(newOwner as slice)
            .storeUint(adnlAddress, 256)
            .storeUint(createdAt, 32)
            .storeUint(expiresAt, 32)
            .storeRef(metadataIpfs)
            .endCell().beginParse();
            
        domains.uDictSet(256, domainHash, newRecord);
        saveData();
        return;
    }
    
    if (op == OP_RENEW_SUBDOMAIN) {
        var domainStr: slice = inMsgBody.loadRef().beginParse();
        var domainHash: int = domainStr.bitsHash();
        
        var (recordSlice: slice?, found: bool) = domains.uDictGet(256, domainHash);
        assert(found) throw 404;
        
        assert(msgValue >= price_ton) throw 100;
        
        var recordSliceMut: slice = recordSlice!;
        var owner: address = recordSliceMut.loadAddress();
        var adnlAddress: int = recordSliceMut.loadUint(256);
        var createdAt: int = recordSliceMut.loadUint(32);
        var expiresAt: int = recordSliceMut.loadUint(32);
        var metadataIpfs: cell = recordSliceMut.loadRef();
        
        if (blockchain.now() > expiresAt) {
            expiresAt = blockchain.now() + ONE_YEAR;
        } else {
            expiresAt += ONE_YEAR;
        }
        
        var newRecord: slice = beginCell()
            .storeSlice(owner as slice)
            .storeUint(adnlAddress, 256)
            .storeUint(createdAt, 32)
            .storeUint(expiresAt, 32)
            .storeRef(metadataIpfs)
            .endCell().beginParse();
            
        domains.uDictSet(256, domainHash, newRecord);
        saveData();
        return;
    }
    
    assert((sender as slice).bitsEqual(admin as slice)) throw 403;
    
    if (op == OP_ADMIN_SET_PRICE) {
        price_ton = inMsgBody.loadCoins();
        saveData();
        return;
    }
    
    if (op == OP_ADMIN_WITHDRAW) {
        var amount: int = inMsgBody.loadCoins();
        sendRawMessage(beginCell()
            .storeUint(0x18, 6)
            .storeSlice(treasury as slice)
            .storeCoins(amount)
            .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
            .endCell(), 1);
        return;
    }
    
    if (op == OP_ADMIN_FORCE_DELETE) {
        var domainStr: slice = inMsgBody.loadRef().beginParse();
        var domainHash: int = domainStr.bitsHash();
        
        var (recordSlice: slice?, found: bool) = domains.uDictGet(256, domainHash);
        if (found) {
            domains.uDictDelete(256, domainHash);
            total_registered -= 1;
            saveData();
        }
        return;
    }
    
    throw 0xffff;
}
