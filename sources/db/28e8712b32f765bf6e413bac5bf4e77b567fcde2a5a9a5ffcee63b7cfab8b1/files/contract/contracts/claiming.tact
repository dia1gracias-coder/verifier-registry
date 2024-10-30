import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./distributor";

contract Claiming with Deployable, OwnableTransferable {
    owner: Address;
    distributorsCount: Int as uint32 = 0;
    admins: map<Address, Bool>;

    init() {
        self.owner = sender();
    }

    receive(msg: CreateDistributor) {
        nativeThrowUnless(132, sender() == self.owner || self.isAdmin(sender()));

        self.distributorsCount = self.distributorsCount + 1;
        let distributorInit: StateInit = initOf Distributor(myAddress(), self.distributorsCount);
        let distributorAddress: Address = contractAddress(distributorInit);
        
        send(SendParameters {
            to: distributorAddress,
            value: ton("0.3"),
            mode: 0,
            body: InitDistributor {
                queryId: msg.queryId,
                creator: sender(),
                token: msg.token,
                vault: msg.vault,
                merkleRoot: msg.merkleRoot,
                unlockPeriods: msg.unlockPeriods,
                totalAmount: msg.totalAmount,
                refundDate: msg.refundDate
            }.toCell(),
            code: distributorInit.code,
            data: distributorInit.data
        });

        emit(CreateDistributorEvent { 
            queryId: msg.queryId,
            type: "CreateDistributor",
            id: self.distributorsCount,
            address: distributorAddress
        }.toCell());

        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingBalance
        });
    }

    receive(msg: SetAdmin) {
        self.requireOwner();

        self.admins.set(msg.address, msg.value);

        emit(SetAdminEvent { 
            queryId: msg.queryId, 
            type: "SetAdmin",
            address: msg.address,
            value: msg.value
        }.toCell());

        self.reply(emptyCell());
    }

    receive(msg: UpgradeCode) {
        self.requireOwner();

        setCode(msg.newCode);
    }

    receive(msg: UpgradeData) {
        self.requireOwner();

        setData(msg.newData);
    }

    get fun distributorsCount(): Int {
        return self.distributorsCount;
    }

    get fun admins(): map<Address, Bool> {
        return self.admins;
    }
    
    get fun isAdmin(user: Address): Bool {
        let value: Bool? = self.admins.get(user);
        return value != null && value!! == true;
    }
}
