import "./jetton-common-structs";

inline fun calculateJettonWalletAddress(
    ownerAddress: Address,
    jettonMasterAddress: Address,
    jettonWalletCode: Cell,
    type: Int,
): Address {
    let initDataCell: Cell? = null;
    if (type == 0) {
        initDataCell = JettonWalletData {
            balance: 0,
            owner: ownerAddress,
            master: jettonMasterAddress,
            walletCode: jettonWalletCode,
        }.toCell();
    }
    else if (type == 1) {
        initDataCell = USDTJettonWalletData {
            status: 0,
            balance: 0,
            ownerAddress: ownerAddress,
            jettonMasterAddress: jettonMasterAddress,
        }.toCell();
    }
    else {
        throw(400);
    }

    return contractAddress(StateInit {
        code: jettonWalletCode,
        data: initDataCell!!,
    });

}
