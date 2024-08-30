import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./distributor";

contract Claiming with Deployable, OwnableTransferable {
    owner: Address;
    distributorsCount: Int as uint32 = 0;

    init() {
        self.owner = sender();
    }

    receive(msg: CreateDistributor) {
        self.requireOwner();

        self.distributorsCount = self.distributorsCount + 1;
        let distributorInit: StateInit = initOf Distributor(myAddress(), self.distributorsCount);
        
        send(SendParameters {
            to: contractAddress(distributorInit),
            value: ton("0.2"),
            mode: 0,
            body: CreateDistributorInternal {
                creator: sender(),
                token: msg.token,
                merkleRoot: msg.merkleRoot,
                unlockPeriods: msg.unlockPeriods,
                totalAmount: msg.totalAmount,
                refundDate: msg.refundDate
            }.toCell(),
            code: distributorInit.code,
            data: distributorInit.data
        });

        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingBalance
        });
    }

    receive(msg: UpgradeCode) {
        self.requireOwner();

        setCode(msg.newCode);
    }

    receive(msg: UpgradeData) {
        self.requireOwner();

        setData(msg.newData);
    }
}
