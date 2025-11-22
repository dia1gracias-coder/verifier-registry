import "@stdlib/deploy";

// ============================================================================
// MESSAGE STRUCTURES
// ============================================================================

// Message to register a new QR code with merchant name
message RegisterQr {
    qrData: String;        // The QR code string
    merchantName: String;  // Merchant's business name
}

// Event emitted when QR code is registered
message QrRegistered {
    qrData: String;
    merchantName: String;
    merchantAddress: Address;
    timestamp: Int as uint32;
}

// ============================================================================
// DATA STRUCTURES
// ============================================================================

// Store merchant info for each QR code
struct MerchantInfo {
    merchantAddress: Address;
    merchantName: String;
}

// ============================================================================
// MAIN CONTRACT
// ============================================================================

contract QrRegistry with Deployable {
    
    // Main mapping: hash(qrData) => MerchantInfo
    qrToMerchant: map<Int, MerchantInfo>;
    
    // Counter mapping: merchant address => number of QR codes
    merchantQrCount: map<Address, Int>;
    
    // Total registered QR codes
    totalRegistrations: Int as uint32;
    
    // ========================================================================
    // INITIALIZATION
    // ========================================================================
    
    init() {
        self.totalRegistrations = 0;
    }
    
    // ========================================================================
    // REGISTRATION FUNCTION
    // ========================================================================
    
    // Register a QR code with merchant name
    receive(msg: RegisterQr) {
        let ctx: Context = context();
        
        // Validate inputs
        require(msg.qrData != "", "QR data cannot be empty");
        require(msg.merchantName != "", "Merchant name cannot be empty");
        
        // Hash the QR data
        let qrHash: Int = self.hashString(msg.qrData);
        
        // Check if QR already exists
        let existing: MerchantInfo? = self.qrToMerchant.get(qrHash);
        require(existing == null, "QR code already registered");
        
        // Store QR => Merchant info
        self.qrToMerchant.set(qrHash, MerchantInfo{
            merchantAddress: ctx.sender,
            merchantName: msg.merchantName
        });
        
        // Update merchant's QR count
        let currentCount: Int? = self.merchantQrCount.get(ctx.sender);
        if (currentCount == null) {
            self.merchantQrCount.set(ctx.sender, 1);
        } else {
            self.merchantQrCount.set(ctx.sender, currentCount!! + 1);
        }
        
        self.totalRegistrations = self.totalRegistrations + 1;
        
        // Emit event
        emit(QrRegistered{
            qrData: msg.qrData,
            merchantName: msg.merchantName,
            merchantAddress: ctx.sender,
            timestamp: now()
        }.toCell());
    }
    
    // ========================================================================
    // HELPER FUNCTIONS
    // ========================================================================
    
    // Hash a string
    fun hashString(s: String): Int {
        let cell: Cell = beginCell().storeSlice(s.asSlice()).endCell();
        return cell.hash();
    }
    
    // ========================================================================
    // GETTER FUNCTIONS
    // ========================================================================
    
    // Get merchant name and address by QR code
    get fun getMerchantByQr(qrData: String): MerchantInfo? {
        let qrHash: Int = self.hashString(qrData);
        return self.qrToMerchant.get(qrHash);
    }
    
    // Get QR count for a merchant
    get fun getMerchantQrCount(merchantAddress: Address): Int {
        let count: Int? = self.merchantQrCount.get(merchantAddress);
        if (count == null) {
            return 0;
        }
        return count!!;
    }
    
    // Check if QR is registered
    get fun isQrRegistered(qrData: String): Bool {
        let qrHash: Int = self.hashString(qrData);
        let info: MerchantInfo? = self.qrToMerchant.get(qrHash);
        return info != null;
    }
    
    // Get total registrations
    get fun getTotalRegistrations(): Int {
        return self.totalRegistrations;
    }
}