// this trait has to be imported
import "@stdlib/ownable";
import "./Includes.tact";
import "./Upgradable.tact";
import "./PgDepositV0";
import "./PgDeposit";
import "./PgWithdrawV0";
import "./PgWithdraw";

contract PgFactory with Ownable, Upgradable {
    
    // general
    id: Int as uint32; //contract id
    owner: Address;
    version: Int as uint32 = 0;
    signers: map<Int as uint8, Int as uint256>; // index => public key

    // deposit
    wkCompany: Address;
    shareRevenue: Int as uint16 = 5000;
    fees: Int as uint16 = 50;
    minterCode: map<Address, Cell>;
    minterDataLayout: map<Address, Int as uint8>;

    // extra state
    extra: map<Int as uint32, Cell>;
    
    init(id: Int) {
        self.id = id;
        self.owner = sender(); 
        self.wkCompany = newAddress(
            0, 
            0x9dfefc5379cafb1bb726c077fda759f49c71a1693f98762dac83672bbab3f282,
        );
    }

    // ===== admin =====
    receive(msg: SetSigners) {
        self.requireOwner();
        self.signers = msg.signers;
    }

    receive(msg: AddNewMinter) {
        self.requireOwner();
        require(!self.minterCode.exists(msg.jettonMinter), "jetton exists");

        self.minterCode.set(msg.jettonMinter, msg.jettonWalletCode);
        self.minterDataLayout.set(msg.jettonMinter, msg.dataLayoutId);
    }

    receive(msg: UpgradeDepositCode) {
        
        self.requireOwner();
        
        foreach (_, contract in msg.depositContracts/* deposit contracts */) {
            message(MessageParameters {
                to: contract,
                value: msg.value,
                mode: SendPayGasSeparately | SendIgnoreErrors,
                bounce: false,
                body: UpgradeCode { 
                    code: codeOf PgDeposit,
                    version: msg.version,
                    origin: sender(),
                }.toCell(),
            });
        }
    }

    receive(msg: UpgradeWithdrawCode) {
        
        self.requireOwner();
        
        foreach (_, contract in msg.withdrawContracts/* deposit contracts */) {
            message(MessageParameters {
                to: contract,
                value: msg.value,
                mode: SendPayGasSeparately | SendIgnoreErrors,
                bounce: false,
                body: UpgradeCode { 
                    code: codeOf PgWithdraw,
                    version: msg.version,
                    origin: sender(),
                }.toCell(),
            });
        }
    }

    receive(msg: ClaimTON) {
        self.requireOwner();
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);

        // we allow bounce here and don't handle it, if claim fails we just accept the TONs back
        message(MessageParameters {
            bounce: true,
            to: self.wkCompany,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive(msg: SetFees){

        self.requireOwner();

        message(MessageParameters {
            value: 0, 
            bounce: false,
            to: _getDepositContract(myAddress(), sender()), 
            mode: SendRemainingValue | SendIgnoreErrors,
            body: SetFeesInternal{ 
                queryId: msg.queryId,
                fees: msg.fees
            }.toCell(),
        });
    }     

    receive(msg: SetShareRevenue){
        self.requireOwner();
        
        message(MessageParameters {
            value: 0, 
            bounce: false,
            to: _getDepositContract(myAddress(), sender()), 
            mode: SendRemainingValue | SendIgnoreErrors,
            body: SetShareRevenueInternal{ 
                queryId: msg.queryId,
                shareRevenue: msg.shareRevenue
            }.toCell(),
        });
    }     
    
   
    // ===== deposit contract =====
    receive(msg: Register) {

        let ctx = context();
        forceBasechain(msg.referral);

        let nextFees = 
            minTonsForStorage + 
            ctx.readForwardFee() /*refund excess from registerInternal*/ + 
            getComputeFee(gasForRegister, false) + 
            (getForwardFee(depositStateInitCells / 3, depositStateInitBits / 3, false)) /* v0 */ + 
            (getForwardFee(depositStateInitCells, depositStateInitBits, false)) /* newCode */;
        //dump(nextFees);

        require(ctx.value > nextFees , "Insufficient ton for gas");

        require(msg.beneficiaries.exists(0), "Beneficiary not found");

        foreach (k, beneficiary in msg.beneficiaries) {
            require(k<= maxBeneficiaries, "Reach max beneficiaries");
            forceBasechain(beneficiary); // check is basechain address
        }

        deploy(DeployParameters {
            value: 0, 
            bounce: false,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: RegisterInternal{ 
                queryId: msg.queryId,
                beneficiaries: msg.beneficiaries,
                referral: msg.referral,
                fees: self.fees,
                shareRevenue: self.shareRevenue,
                newCode: codeOf PgDeposit
            }.toCell(),
            init: _getDepositInit(myAddress(), sender()),
        });

    }

    receive(msg: DepFundout) {

        let ctx = context();

        let numTransfers: Int = 2; //trf to wk beneficiary & referral
        foreach (_, _ in msg.beneficiaryIdxes) {
            numTransfers+=1;
        }

        let nextFees = 
            minTonsForStorage + 
            ctx.readForwardFee() + /* send depFundoutInternal message */
            ctx.readForwardFee() + /* send excess from depFundoutInternal */
            getComputeFee(gasForDepFundout, false) + /*gasUsed less by jetton transfer*/
            (numTransfers * gasNanoForTransfer);
        //dump(nextFees);

        require(ctx.value > nextFees, "Insufficient ton for gas");
        require(self.minterCode.exists(msg.jettonMinter), "Minter not found");
        require(msg.beneficiaryIdxes.exists(0), "Beneficiary not found");

        let depositContract = _getDepositContract(myAddress(), sender());
        let depositJWallet = _jettonWalletAddress(self.minterDataLayout.get(msg.jettonMinter)!!, self.minterCode.get(msg.jettonMinter)!!, msg.jettonMinter, depositContract);
        
        message(MessageParameters {
            value: 0, 
            bounce: false,
            to: depositContract, 
            mode: SendRemainingValue | SendIgnoreErrors,
            body: DepFundoutInternal{ 
                queryId: msg.queryId,
                jettonMinter: msg.jettonMinter,
                depositJWallet: depositJWallet,
                beneficiaryIdxes: msg.beneficiaryIdxes,
                wkCompany: self.wkCompany,
                amount: msg.amount
            }.toCell(),
        });
    }

    receive(msg: DepFundoutTon) {

        require(msg.beneficiaryIdxes.exists(0), "Beneficiary not found");

        let ctx = context();

        let numTransfers: Int = 2; //trf to wk beneficiary & referral
        foreach (_, _ in msg.beneficiaryIdxes) {
            numTransfers+=1;
        }

        let nextFees = 
            minTonsForStorage + 
            ctx.readForwardFee() + /* send DepFundoutTonInternal message */
            getComputeFee(gasForDepFundoutTon, false) + /*gasUsed less by jetton transfer*/
            (numTransfers * gasNanoForTonTransfer);
        //dump(nextFees);
        require(ctx.value > nextFees, "Insufficient ton for gas");
        
        message(MessageParameters {
            value: 0, 
            bounce: false,
            to: _getDepositContract(myAddress(), sender()), 
            mode: SendRemainingValue | SendIgnoreErrors,
            body: DepFundoutTonInternal{ 
                queryId: msg.queryId,
                beneficiaryIdxes: msg.beneficiaryIdxes,
                wkCompany: self.wkCompany,
                amount: msg.amount,
            }.toCell(),
        });
    }

    receive(msg: WdEnable) { 
        
        let ctx = context();
        
        let nextFees = 
            minTonsForStorage + 
            ctx.readForwardFee() /*refund excess from wdEnableInternal*/ + 
            getComputeFee(gasForWdEnable, false) + 
            (getForwardFee(withdrawStateInitCells / 3, withdrawStateInitBits / 3, false)) /* v0 */ + 
            (getForwardFee(withdrawStateInitCells, withdrawStateInitBits, false)) /* newCode */;

        require(ctx.value > nextFees, "Insufficient ton for gas");

        let signBody:WdEnableSignBody = WdEnableSignBody{
            sender: sender(),
            contract: myAddress(),
            wdExecutor: msg.wdExecutor,
        };

        // check signature
        foreach (_, signer in self.signers) {
            require(checkSignature(signBody.toCell().hash(), msg.signature, signer), "Invalid signature!");
        }

        deploy(DeployParameters {
            value: 0, 
            bounce: false,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: WdEnableInternal{ 
                queryId: msg.queryId,
                wdExecutor: msg.wdExecutor,
                newCode: codeOf PgWithdraw
            }.toCell(),
            init: _getWithdrawInit(myAddress(), sender()),
        });
    }

    receive(msg: WdSupplyExecutorGas) { 

        let ctx = context();
        let nextFees = 
            minTonsForStorage + 
            ctx.readForwardFee() + /* send WdSupplyExecutorGasIinternal message */
            getComputeFee(gasForWdSupplyExecutorGas, false);

        require(ctx.value > nextFees, "Insufficient ton for gas");

        message(MessageParameters {
            value: 0, 
            bounce: false,
            to: _getWithdrawContract(myAddress(), sender()), 
            mode: SendRemainingValue | SendIgnoreErrors,
            body: WdSupplyExecutorGasInternal{ 
                queryId: msg.queryId,
            }.toCell(),
        });
    }

    receive(msg: WdSupplyRollingTon)  {

        let ctx = context();
        let nextFees = 
            minTonsForStorage + 
            ctx.readForwardFee() + /* send WdSupplyRollingTonInternal message */
            gasNanoForTonTransfer;

        require(ctx.value > nextFees, "Insufficient ton for gas");

        message(MessageParameters {
            value: 0, 
            bounce: false,
            to: _getWithdrawContract(myAddress(), sender()), 
            mode: SendRemainingValue | SendIgnoreErrors,
        });
    }

     receive(msg: JettonTransferNotification) {

        let ctx = context();


        let _ = msg.forwardPayload.loadBit();
        let ref = msg.forwardPayload.loadRef();
        let payload = WdSupplyRollingPayload.fromCell(ref);
        
        require(self.minterCode.exists(payload.jettonMinter), "jetton not exists");

        let dataLayoutId = self.minterDataLayout.get(payload.jettonMinter)!!;
        let code = self.minterCode.get(payload.jettonMinter)!!;
        let factoryJWallet = _jettonWalletAddress(dataLayoutId, code, payload.jettonMinter, myAddress());
        
        require(sender() == factoryJWallet, "invalid notification");
        
        let nextFees = 
            minTonsForStorage + 
            ctx.readForwardFee() + /* send wdSupplyRollingInternal message */
            ctx.readForwardFee() + /* send excess from wdSupplyRollingInternal */
            getComputeFee(gasForWdSupplyRolling, false);
        //dump(nextFees);

        require(ctx.value > nextFees, "Insufficient ton for gas");

        //transfer jetton to merchant contract
        let withdrawContract = _getWithdrawContract(myAddress(), msg.sender);

        _transferFromContract(factoryJWallet, msg.queryId, msg.amount, withdrawContract, msg.sender, gasNanoForTransfer);

    }

    receive(msg: WdPayout) {
       
        let ctx = context();
        let jetton = msg.jetton;
        let numTransfers: Int = 0;
        let wdContract = _getWithdrawContract(myAddress(), msg.merchantExecutor);
        let wdJWallet:Address = zeroAccount;

       
        if (self.minterCode.exists(msg.jetton)) {
            let dataLayoutId = self.minterDataLayout.get(jetton)!!;
            let jettonWalletCode: Cell = self.minterCode.get(jetton)!!;
            wdJWallet = _jettonWalletAddress(dataLayoutId, jettonWalletCode, jetton, wdContract);
        } 

        foreach (idx, recipient in msg.recipients) {
            numTransfers+=1;
        }

        let nextFees = 
            minTonsForStorage + 
            ctx.readForwardFee() + /* send WdPayoutinternal message */
            getComputeFee(gasForWdPayout, false)+ /*gasUsed less by jetton transfer*/
            (numTransfers * gasNanoForTransfer);

        require(ctx.value > nextFees, "Insufficient ton for gas");
       
        message(MessageParameters {
            value: 0, 
            bounce: false,
            to: wdContract, 
            mode: SendRemainingValue | SendIgnoreErrors,
            body: WdPayoutInternal{ 
                queryId: msg.queryId,
                jetton: msg.jetton,
                recipients: msg.recipients,
                amounts: msg.amounts,
                ids: msg.ids,
                wdExecutor: sender(),
                wdJWallet: wdJWallet,
            }.toCell(),
        });
    }

    // default(null) receive for deploy
    receive() {
        //cashback(sender())
    }

    get fun data(): FactoryData {
        return FactoryData{
            id: self.id, 
            owner: self.owner, 
            version: self.version, 
            wkCompany: self.wkCompany,
            shareRevenue: self.shareRevenue,
            fees: self.fees
        };
    }

    get fun depositCode() : Cell {
        return codeOf PgDepositV0;
    }

    get fun depositInit(merchant: Address) : StateInit {
        return _getDepositInit(myAddress(), merchant );
    }

    get fun depositContract(merchant: Address): Address {
        return _getDepositContract(myAddress(), merchant);
    }

    get fun depositBasechainContract(merchant: Address): BasechainAddress {
        return _getDepositBasechainContract(myAddress(), merchant);
    }

     get fun withdrawCode() : Cell {
        return codeOf PgWithdrawV0;
    }

    get fun withdrawInit(merchant: Address) : StateInit {
        return _getWithdrawInit(myAddress(), merchant );
    }

    get fun withdrawContract(merchant: Address): Address {
        return _getWithdrawContract(myAddress(), merchant);
    }

    get fun withdrawBasechainContract(merchant: Address): BasechainAddress {
        return _getWithdrawBasechainContract(myAddress(), merchant);
    }

    get fun extra(): Address {
        let num = 123;
        return self.extra.get(0)!!.asSlice().loadAddress();
    }

    get fun minterCode(minter:Address): Cell {
        return self.minterCode.get(minter)!!;
    }

    get fun testSignBody(address:Address) :Cell {
        return WdEnableSignBody {sender: address, contract:address, wdExecutor: address}.toCell();
    }
}

// FUNCTIONS
inline fun _getDepositInit(factory: Address, owner: Address): StateInit {

    let initData = initOf PgDepositV0(factory, owner);

    return StateInit { code: cell("te6cckECDgEAAo4AAij/AI6I9KQT9LzyyAvtUyDjA+1D2QEJAgN4oAIEAXG6p37UTQ0gABjhT6QNMf+kDTD9MP+kD0BPQEVXBsGI4T+kD6QFkC0QFwbW1TIosCEFZVEuLbPGyBgDAAImAgEgBQcBcbSjvaiaGkAAMcKfSBpj/0gaYfph/0gegJ6Aiq4NgxHCf0gfSAsgWiAuDa2qZFFgQgrKolxbZ42QMAYAAicBcbVjfaiaGkAAMcKfSBpj/0gaYfph/0gegJ6Aiq4NgxHCf0gfSAsgWiAuDa2qZFFgQgrKolxbZ42QMAgAAn8C3jAB0HLXIdIA0gD6QCEQNFBmbwT4YQL4Yu1E0NIAAY4U+kDTH/pA0w/TD/pA9AT0BFVwbBiOE/pA+kBZAtEBcG1tUyKLAhBWVRLiCZJfCeAH1w0f8uCCIYIQYzrAUbrjAgGCECUej5K64wJfCfLAggoMAv4x0z8x9AT6QNMP0w/0BDAQehBpEFgQShA5SLzbPGxBggiYloCAEPsCJnAoePSGb6UgkRKVMW0ybQHikI4pE3hSMiBulTBZ9FswlEEz9BbiAaR4VEoUWfR8b6UgkRKVMW0ybQHiEDToXwM3KG6zmAggbvLQgPsEkTjicCFwgQCCDQsAeANtUDPIz4WAygDPhEDOAfoCgGrPQPQAyQH7AEdVBgNEFMh/AcoAVXBQeM4Vyx8TzssPyw/O9AD0AMntVAHa1NMf1ywBkW2T+kAB4jEQeBBoEFgQSBA4SJrbPDYH+wQobrOOFAggbvLQgMjPhQjOcM8LbsmAQvsAjhE4+ELIz4UIznDPC27JgEL7AOIQR1UiEsh/AcoAVXBQeM4Vyx8TzssPyw/O9AD0AMntVA0AEPhCKMcF8uCEJa9rGA=="), data: initData.data };
    
}

inline fun _getDepositContract(factory: Address, owner: Address): Address {
    return contractAddress(_getDepositInit(factory, owner));
}

inline fun _getDepositBasechainContract(factory: Address, owner: Address): BasechainAddress {
    return contractBasechainAddress(_getDepositInit(factory, owner));
}

inline fun _getWithdrawInit(factory: Address, owner: Address): StateInit {

    let initData = initOf PgWithdrawV0(factory, owner);

    return StateInit { code: cell("te6cckECDgEAAuAAAij/AI6I9KQT9LzyyAvtUyDjA+1D2QEJAgN4oAIEAb+6p37UTQ0gABjjb6QNMf+kD6QNQB0IEBAdcA9ASBAQHXAIEBAdcAVTAE9AT0BPQEMBB7EHoQeRB4EFYQRRA0bBuOGPpA+kBZAtEBcG1tbYsCgU4gbXAgEIlVJOLbPGyxgDAAIpAgEgBQcBv7SjvaiaGkAAMcbfSBpj/0gfSBqAOhAgIDrgHoCQICA64BAgIDrgCqYAnoCegJ6AhgIPYg9CDyIPAgrCCKIGjYNxwx9IH0gLIFogLg2trbFgUCnEDa4EAhEqpJxbZ42WMAYAAioBv7VjfaiaGkAAMcbfSBpj/0gfSBqAOhAgIDrgHoCQICA64BAgIDrgCqYAnoCegJ6AhgIPYg9CDyIPAgrCCKIGjYNxwx9IH0gLIFogLg2trbFgUCnEDa4EAhEqpJxbZ42WMAgAAn8B9DAB0HLXIdIA0gD6QCEQNFBmbwT4YQL4Yu1E0NIAAY42+kDTH/pA+kDUAdCBAQHXAPQEgQEB1wCBAQHXAFUwBPQE9AT0BDAQexB6EHkQeBBWEEUQNGwbjhj6QPpAWQLRAXBtbW2LAoFOIG1wIBCJVSTiDJJfDOAK1w0fCgPY8uCCIYIQyEWgabqPTzHTPzH6QPQEMFC82zw3ggiYloCAEPsCK26zmAsgbvLQgPsEkTvicCdwgQCCA21QM8jPhYDKAM+EQM4B+gKAas9A9ADJAfsAEIoQeRBoVRTgAYIQJR6PkrrjAl8M8sCCDA0LArDU0x/XLAGRbZP6QAHiMRCrEJsQixB7EGsQWxBLEDtLzds8OQr7BCtus44UCyBu8tCAyM+FCM5wzwtuyYBC+wCOETv4QsjPhQjOcM8LbsmAQvsA4hB6VSUSDA0AEPhCK8cF8uCEAGrIfwHKAFWgUKvOGMsfFs4UzshQRAVQNIEBAc8A9ACBAQHPAIEBAc8AEvQAEvQAEvQAzcntVI7uWio="), data: initData.data };
    
}

inline fun _getWithdrawContract(factory: Address, owner: Address): Address {
    return contractAddress(_getWithdrawInit(factory, owner));
}

inline fun _getWithdrawBasechainContract(factory: Address, owner: Address): BasechainAddress {
    return contractBasechainAddress(_getWithdrawInit(factory, owner));
}
