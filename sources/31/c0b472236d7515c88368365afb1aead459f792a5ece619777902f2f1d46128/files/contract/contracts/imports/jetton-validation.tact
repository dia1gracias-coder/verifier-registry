fun calculateJettonWalletGovernedAddress(ownerAddress: Address, masterAddress: Address, code: Cell): Address {
    let initData = beginCell()
        .storeUint(0, 4)
        .storeCoins(0)
        .storeAddress(ownerAddress)
        .storeAddress(masterAddress)
        .endCell();
    return contractAddress(StateInit{code: code, data: initData});
}

trait JettonValidator {
    jettonWalletGovernedCode: Cell;

    fun calculateMyJettonGovernedAddress(jettonMasterAddress: Address): Address {
        return calculateJettonWalletGovernedAddress(myAddress(), jettonMasterAddress, self.jettonWalletGovernedCode);
    }

    fun assertJettonGovernedIsValid(jettonAddress: Address, jettonMasterAddress: Address) {
        let calculatedAddress = self.calculateMyJettonGovernedAddress(jettonMasterAddress);
        nativeThrowUnless(999, jettonAddress == calculatedAddress);
    }
}