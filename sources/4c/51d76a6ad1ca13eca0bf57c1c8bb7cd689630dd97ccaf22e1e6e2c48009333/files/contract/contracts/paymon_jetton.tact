import "./lib/jetton-wallet.tact";
import "./lib/messages.tact";
import "./common/Stoppable";
import "./common/Taxable";
import "./lib/constants";
import "./lib/messages";

const Workchain: Int = 0;

struct JettonMinterState {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

struct PaymonMinterState {
    minterState: JettonMinterState;
    usdtWalletAddress: Address;
    usdtBalance: Int as coins;
    priceInUsdt: Int as coins;
    lockedUsdt: Int as coins;
    taxRate: Int as coins;
}

struct ActionResult {
    success: Bool;
}

message TransferOwnership {
    owner: Address;
}

message SetUsdtWallet {
    usdtWalletAddress: Address;
    taxRate: Int as coins
}

struct UsdtWalletUpdated {
    success: Bool
}

message ClaimAccumulatedTax {
    queryId: Int as uint64;
    amount: Int as coins;
    to: Address;
}

message UpdateUsdtPrice {
    newPrice: Int as coins;
}

message EmergencyWithdraw {
    queryId: Int as uint64;
    to: Address;
}

message ReveokeOwnership {
    queryId: Int as uint64;
}

contract PaymonMinter with Resumable, Taxable{
    queryId: Int as uint64;

    totalSupply: Int as coins;
    owner: Address;
    manager: Address;

    jettonContent: Cell;
    mintable: Bool;

    stopped: Bool;

    usdtWalletAddress: Address;
    priceInUsdt: Int as coins;

    usdtBalance: Int as coins = 0;
    lockedUsdt: Int as coins = 0;

    taxRate: Int as coins;


    init(queryId: Int, totalSupply: Int, owner: Address, jettonContent: Cell, priceInUsdt: Int) {
        self.queryId = queryId;
        self.totalSupply = totalSupply;
        self.usdtWalletAddress = myAddress();
        self.owner = owner;
        self.manager = owner;
        self.jettonContent = jettonContent;
        self.mintable = false;
        self.stopped = false;
        self.priceInUsdt = priceInUsdt;
        self.taxRate = 10_000;
    }

    receive(msg: SetUsdtWallet) {
        self.onlyManager();
        self.usdtWalletAddress = msg.usdtWalletAddress;
        self.taxRate = msg.taxRate;
        self.sendNotify(true);
    }

    receive(msg: ClaimAccumulatedTax) {
        self.onlyManager();
        require(msg.amount <= self.lockedUsdt, "Overdraw");
        let ctx = context();
        self.sendTransfer(ctx, msg.queryId, msg.amount, ctx.sender, ctx.sender);

        self.usdtBalance -= msg.amount;
        self.lockedUsdt -= msg.amount;
        self.sendNotify(true);
    }

    receive(msg: EmergencyWithdraw) {
        self.onlyOwner();
        let ctx = context();
        let available = self.usdtBalance - self.lockedUsdt;
        self.sendTransfer(ctx, msg.queryId, available, msg.to, msg.to);
        self.usdtBalance -= available;
        // self.sendNotify(true);
    }

    receive(msg: ClaimTON) {
        self.onlyManager();
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);

        // we allow bounce here and don't handle it, if claim fails we just accept the TONs back
        message(MessageParameters {
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive(msg: ProvideWalletAddress) {
        // we use message fwdFee for estimation of forward_payload costs
        let ctx = context();
        let fwdFee = ctx.readForwardFee();
        require(ctx.value > fwdFee + getComputeFee(gasForDiscovery, false), "Insufficient gas for discovery");
        let ownerWorkchain: Int = parseStdAddress(msg.ownerAddress.asSlice()).workchain;

        let targetJettonWallet: BasechainAddress = (ownerWorkchain == Workchain)
            ? contractBasechainAddress(getJettonWalletInit(msg.ownerAddress))
            : emptyBasechainAddress();

        message(MessageParameters {
            body: makeTakeWalletAddressMsg(targetJettonWallet, msg),
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
        });
    }

    receive(msg: JettonUpdateContent) {
        self.onlyManager();
        self.jettonContent = msg.content;
    }

    receive(msg: TransferOwnership) {
        self.onlyOwner();
        self.owner = msg.owner;
        self.sendNotify(true);
    }

    receive(msg: ReveokeOwnership) {
        self.onlyOwner();
        self.owner = newAddress(0, 0);
        self.sendNotify(true);
    }

    receive(msg: UpdateUsdtPrice) {
        self.onlyManager();
        self.priceInUsdt = msg.newPrice;
        self.sendNotify(true);
    }

    receive(msg: JettonBurnNotification) {
        require(msg.amount >= 0, "Token amount is negative");
        let ctx = context();
        validateBurnNotification(ctx, msg);
        self.executeBurnNotification(ctx, msg);
    }

    receive(msg: JettonNotification) {
        require(msg.amount >= 0, "Token amount is negative");
        if (self.stopped == false) {
            //User changed USDT address and resends previously withdrawed USDT using EmergencyWithdraw to the contract
            let bits = msg.forwardPayload.loadUint(1);
            require(
                sender() == self.usdtWalletAddress
                ||
                sender() == self.owner && bits == 1,
                "Incorrect sender");
        
            if (bits == 0) {
                self.swap(context(), msg);
            } 
            else {
                self.usdtBalance += msg.amount;
                cashback(sender());
            } 
        }
        else {
            self.sendTransfer(context(), msg.queryId, msg.amount, msg.sender, msg.sender);
        }
    }

    fun swap(ctx: Context, msg: JettonNotification) {
        let commission = (msg.amount * self.taxRate) / 1_000_000;
        let netAmount = msg.amount - commission; // represents the actual amount of DAI (or other token) that will be used to calculate how many MyTokens should be minted after subtracting the commission fee.
        let mintAmount = netAmount * self.priceInUsdt;

        self.usdtBalance += msg.amount;

        self.mint(ctx, mintAmount, msg.sender, msg.queryId, false);
        self.lockedUsdt += commission;
    }

    fun sendNotify(success: Bool) {
        self.notify(ActionResult {
           success
        }.toCell());
    }

    inline fun mint(ctx: Context, amount: Int, to: Address, queryId: Int, refund: Bool) {
        let tonBalanceBeforeMsg = myBalance() - ctx.value;
        let forwardFee = ctx.readForwardFee();
        
        ensureOperationFees(ctx, 2, forwardFee, gasForTransfer);

        nativeReserve(tonBalanceBeforeMsg + minTonsForStorage + forwardFee, ReserveAtMost);
        self.mintValidate(ctx, refund);

        let walletInit: StateInit = getJettonWalletInit(to);
        send(SendParameters{
            to: contractAddress(walletInit),
            value: 0,
            bounce: true,
            mode: SendRemainingBalance,
            code: walletInit.code,
            data: walletInit.data,
            body: JettonTransferInternal{
                queryId: queryId,
                amount,
                sender: myAddress(),
                responseDestination: to,
                forwardPayload: beginCell().storeUint(0, 1).endCell().asSlice(),
                forwardTonAmount: forwardFee,
            }.toCell(),
        });
        
        self.totalSupply += amount;
    }

    inline fun executeBurnNotification(ctx: Context, msg: JettonBurnNotification) {
        let grossUsdt = msg.amount / self.priceInUsdt;
        let commission = (grossUsdt * self.taxRate) / 1_000_000;
        let netUsdt = grossUsdt - commission;

        // Enusre enough USDT exists on wallet
        if (netUsdt <= self.usdtBalance - self.lockedUsdt && self.stopped == false) {
            self.sendTransfer(ctx, msg.queryId, netUsdt, msg.sender, msg.sender);
            self.totalSupply -= msg.amount;
            self.usdtBalance -= netUsdt;
            self.lockedUsdt += commission;
        }
        else { // Not enough USDT, Refund user Jettons back
            self.mint(ctx, msg.amount, msg.sender, msg.queryId, true);
        }
    }

    inline fun sendTransfer(ctx: Context, queryId: Int, amount: Int, destination: Address, responseDestination: Address) {
        let forwardFee = ctx.readForwardFee();
 
        ensureOperationFees(ctx, 4, forwardFee, gasForTransfer);
        let msg_value = ctx.value - minTonsForStorage - forwardFee;

        message(MessageParameters{
            to: self.usdtWalletAddress,
            value: msg_value,
            mode: SendPayGasSeparately,
            bounce: false,
            body: JettonTransfer{
                queryId,
                amount,
                destination,
                responseDestination,
                customPayload: null,
                forwardTonAmount: forwardFee,
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });
    }

    get fun getUsdtWalletAddress(): Address {
        return self.usdtWalletAddress;
    }

    inline fun onlyOwner() {
        require(sender() == self.owner, "Incorrect sender")
    }

    inline fun onlyManager() {
        require(sender() == self.manager, "Incorrect manager")
    }

    inline fun mintValidate(ctx: Context, refund: Bool) {
        self.requireNotStopped();
        // require(self.mintable, "Mint is closed");
        require(ctx.sender == self.usdtWalletAddress || refund, "Incorrect sender");
    }

    inline fun getJettonWalletCode(): Cell {
        return codeOf PaymonWallet;
    }

    get fun get_paymon_data(): PaymonMinterState {
        return PaymonMinterState {
            minterState: self.get_jetton_data(),
            priceInUsdt: self.priceInUsdt,
            usdtBalance: self.usdtBalance,
            lockedUsdt: self.lockedUsdt,
            usdtWalletAddress: self.usdtWalletAddress,
            taxRate: self.taxRate,
        };
    }

    get fun balance(): Int {
        return myBalance();
    }
    get fun get_jetton_data(): JettonMinterState {
        return JettonMinterState {
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            adminAddress: self.owner,
            jettonContent: self.jettonContent,
            jettonWalletCode: self.getJettonWalletCode(),
        };
    }
    get fun get_wallet_address(ownerAddress: Address): Address {
        return getJettonWalletByOwner(ownerAddress);
    }
    get fun usdtBalance(): Int {
        return self.usdtBalance;
    }
}

contract PaymonWallet with JettonWallet {
    balance: Int as coins;
    owner: Address;
    minter: Address;

    init(balance: Int, owner: Address, minter: Address) {
        self.balance = balance;
        self.owner = owner;
        self.minter = minter;
    }

    override fun getJettonWalletInit(balance: Int, owner: Address, minter: Address): StateInit {
        return initOf PaymonWallet(0, owner, minter);
    }
}

inline fun ensureOperationFees(ctx: Context, forwardCount: Int, forwardFee: Int, gas: Int) {
    let operationFees = forwardCount * (forwardFee + getComputeFee(gas, false)) + minTonsForStorage;
    require(ctx.value >= operationFees, "Insufficient TON balance to cover gas fees");
}

asm fun emptyAddress(): Address { b{00} PUSHSLICE }

inline fun makeTakeWalletAddressMsg(targetJettonWallet: BasechainAddress, msg: ProvideWalletAddress): Cell {
    return 
        beginCell()
            .storeUint(TakeWalletAddressOpcode, 32)
            .storeUint(msg.queryId, 64)
            .storeBasechainAddress(targetJettonWallet)
            .storeMaybeRef(msg.includeAddress ? beginCell().storeAddress(msg.ownerAddress).endCell() : null)
        .endCell();
}

inline fun getJettonWalletInit(address: Address): StateInit {
    return initOf PaymonWallet(0, address, myAddress());
}

inline fun getJettonWalletByOwner(jettonWalletOwner: Address): Address {
    return contractAddress(getJettonWalletInit(jettonWalletOwner));
}

inline fun getJettonBasechainWalletByOwner(jettonWalletOwner: Address): BasechainAddress {
    return contractBasechainAddress(getJettonWalletInit(jettonWalletOwner));
}

inline fun validateBurnNotification(ctx: Context, msg: JettonBurnNotification) {
    let sender = parseStdAddress(ctx.sender.asSlice());
    let wallet = getJettonBasechainWalletByOwner(msg.sender);
    require(sender.workchain == Workchain && sender.address == wallet.hash!!, "Unauthorized burn");
}