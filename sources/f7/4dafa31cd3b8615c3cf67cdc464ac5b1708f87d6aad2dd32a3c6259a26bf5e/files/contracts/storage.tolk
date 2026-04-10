const FEE_DENOMINATOR: int = 100000;

struct FeesData {
    marketplaceFeeAddress: address
    marketplacePercent: uint17
    royaltyAddress: address?
    royaltyPercent: uint17
}

struct JettonData {
    jettonMasterAddress: address
    jettonWalletAddress: address?
    publicKey: uint256
}

struct Storage {
    isComplete: bool
    createdAt: uint32
    validUntil: uint32
    acceptedAt: uint32
    marketplaceAddress: address
    nftAddress: address
    offerOwnerAddress: address
    fullPrice: coins
    feesData: Cell<FeesData>
    jettonData: Cell<JettonData>?
}

fun Storage.load() {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

fun Storage.isJettonOffer(self): bool {
    return self.jettonData != null;
}

fun FeesData.calcProfit(self, fullPrice: int): (int, int, int) {
    val royaltyAmount = mulDivFloor(fullPrice, self.royaltyPercent as int, FEE_DENOMINATOR);
    val marketplaceFee = mulDivFloor(fullPrice, self.marketplacePercent as int, FEE_DENOMINATOR);
    val profitPrice = fullPrice - royaltyAmount - marketplaceFee;
    return (royaltyAmount, marketplaceFee, profitPrice);
}
