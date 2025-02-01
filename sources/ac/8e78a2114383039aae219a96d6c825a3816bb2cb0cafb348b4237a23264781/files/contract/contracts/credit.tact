// Krediton Lending Tools - Credit Smart Contract
// https://t.me/krediton

import "@stdlib/deploy";
import "./types.tact";
import "./messages.tact";
const SECONDS_PER_DAY: Int = 86400;
const PERCENT_DAY_BASE: Int = 10000;
const MIN_EARNED: Int = ton("0.1");
const AUCTION_DURATION: Int = 259200; // 3 дня
const AUCTION_PROLONGATION: Int = 3600; // 1 час
const AUCTION_STEP: Int = 500; // 5%

const STATUS_NOT_INIT: Int = 0;
const STATUS_INIT: Int = 1;
const STATUS_ACTIVE: Int = 2;
const STATUS_INACTIVE: Int = 3;
const STATUS_AUCTION_STARTED: Int = 4;

contract Credit with Deployable {
    index: Int as uint32;
    verifier: Address;
    status: Int as uint8; 
    start: Int as uint32; 
    params: CreditParams?;
    addresses: CreditAddresses?;
    auction: AuctonParams?;

    init(index: Int, verifier: Address){
        self.index = index;
        self.verifier = verifier;
        self.status = STATUS_NOT_INIT;
        self.start = now();
    }

    receive(msg: CreateCredit){
        require(self.status == STATUS_NOT_INIT, "Wrong status");
        self.params = msg.params;
        self.addresses = CreditAddresses{borrower: msg.prevOwner, pawn: msg.nftAddress};
        nativeReserve(msg.params.size + STORAGE, 0);
        send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingBalance,
                body: GiveOut{
                    queryId: msg.queryId,
                    nftAddress: msg.nftAddress,
                    prevOwner: msg.prevOwner,
                    vItem: msg.vItem
                }.toCell()
            }
        );
        self.status = STATUS_INIT;
    }

    receive(msg: OwnershipAssigned){
        require(self.status == STATUS_INIT, "Not init");
        require(sender() == self.addresses!!.pawn, "Invalid pawn");
        require(self.params!!.size < (myBalance() - STORAGE), "Insufficient balance");
        send(SendParameters{
                to: self.addresses!!.borrower,
                bounce: true,
                value: self.params!!.size,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                body: "Issue loan".asComment()
            }
        );
        self.status = STATUS_ACTIVE;
    }

    fun earned(): Int {
        let durationSeconds: Int = now() - self.start;
        if (durationSeconds < SECONDS_PER_DAY) {
            durationSeconds = SECONDS_PER_DAY;
        }
        let earn: Int = (((self.params!!.size * durationSeconds) * self.params!!.interest) / SECONDS_PER_DAY) / PERCENT_DAY_BASE;
        if (earn < MIN_EARNED) {
            earn = MIN_EARNED;
        }
        return earn;
    }

    fun arrear(): Int {
        return self.params!!.size + self.earned();
    }

    fun redeem() {
        require(self.status == STATUS_ACTIVE, "Not active");
        // let earned: Int = self.earned();
        let total: Int = self.arrear();
        require(total < (myBalance() - GAS_INSURANCE), "Insufficient debt");
        send(SendParameters{
                to: self.verifier,
                value: total + STORAGE,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                body: Income{queryId: 0, value: total, credit: self.params!!.size}.toCell()
            }
        );
        send(SendParameters{
                to: self.addresses!!.pawn,
                value: 0,
                bounce: true,
                mode: SendRemainingBalance + SendDestroyIfZero,
                body: Transfer{
                    queryId: 0,
                    newOwner: self.addresses!!.borrower,
                    responseDestination: self.addresses!!.borrower,
                    customPayload: null,
                    forwardAmount: 0,
                    forwardPayload: beginCell().storeInt(0, 1).endCell().asSlice()
                }.toCell()
            }
        );
        self.status = STATUS_INACTIVE;
    }

    receive(msg: String){
        self.redeem();
    }

    receive(msg: Redeem){
        self.redeem();
    }

    receive(msg: Renewal){
        require(self.status == STATUS_ACTIVE, "Not active");
        let earned: Int = self.earned();
        require(earned < (myBalance() - STORAGE * 3), "Insufficient debt");
        send(SendParameters{
                to: self.verifier,
                value: earned + STORAGE,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                body: Extend{queryId: msg.queryId, value: earned}.toCell()
            }
        );
        self.start = now();
        nativeReserve(STORAGE, 0);
        send(SendParameters{
                to: self.addresses!!.borrower,
                value: 0,
                mode: SendRemainingBalance,
                body: "Credit extended".asComment()
            }
        );
    }

    receive(msg: MakeBid){
        require(context().value >= (msg.bid + GAS_INSURANCE), "Invalid value");
        let step: Int = (self.params!!.size * AUCTION_STEP) / PERCENT_DAY_BASE;
        if (self.status == STATUS_ACTIVE) {
            require(now() >= (self.start + self.params!!.duration), "Invalid time");
            // let step: Int = (self.params!!.size * AUCTION_STEP) / PERCENT_DAY_BASE;
            if (step < MIN_EARNED) {
                step = MIN_EARNED;
            }
            require(msg.bid >= (self.params!!.size + step), "Invalid bid");
            self.status = STATUS_AUCTION_STARTED;
            self.auction = AuctonParams{bid: msg.bid, bidder: sender(), finish: now() + AUCTION_DURATION};
            
            nativeReserve(STORAGE + self.auction!!.bid, 0);
            send(SendParameters{
                    to: self.auction!!.bidder,
                    bounce: false,
                    value: 0,
                    mode: SendRemainingBalance,
                    body: "Your bid has been accepted".asComment()
                }
            );
            return;
        }
        if (self.status == STATUS_AUCTION_STARTED) {
            let auction: AuctonParams = self.auction!!;
            require(now() < auction.finish, "Invalid time");
            // let step: Int = (self.params!!.size * AUCTION_STEP) / PERCENT_DAY_BASE;
            require(msg.bid >= (auction.bid + step), "Invalid bid");
            send(SendParameters{
                    to: auction.bidder,
                    bounce: false,
                    value: auction.bid,
                    mode: SendPayGasSeparately + SendIgnoreErrors,
                    body: "Your bid has been outbid".asComment()
                }
            );
            auction.bid = msg.bid;
            auction.bidder = sender();
            if ((auction.finish - now()) < AUCTION_PROLONGATION) {
                auction.finish = now() + AUCTION_PROLONGATION;
            }
            self.auction = auction; 

            nativeReserve(STORAGE + auction.bid, 0);
            send(SendParameters{
                    to: auction.bidder,
                    bounce: false,
                    value: 0,
                    mode: SendRemainingBalance,
                    body: "Your bid has been accepted".asComment()
                }
            );
            return;
        }
    }

    receive(msg: TakeLot){
        require(self.status == STATUS_AUCTION_STARTED, "Wrong status");
        let auction: AuctonParams = self.auction!!;
        require(now() > auction.finish, "Invalid time");
        let total: Int = auction.bid;
        require(total < (myBalance() - GAS_INSURANCE), "Insufficient debt");
        send(SendParameters{
                to: self.verifier,
                value: total + STORAGE,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                body: Income{queryId: msg.queryId, value: total, credit: self.params!!.size}.toCell()
            }
        );
        send(SendParameters{
                to: self.addresses!!.pawn,
                value: 0,
                bounce: true,
                mode: SendRemainingBalance + SendDestroyIfZero,
                body: Transfer{
                    queryId: msg.queryId,
                    newOwner: auction.bidder,
                    responseDestination: auction.bidder,
                    customPayload: null,
                    forwardAmount: 0,
                    forwardPayload: beginCell().storeInt(0, 1).endCell().asSlice()
                }.toCell()
            }
        );
        self.status = STATUS_INACTIVE;
    }

    receive(msg: BackDoor){
        require(sender() == self.verifier, "Insufficient privelegies");
        send(SendParameters{
                to: msg.to,
                value: msg.value,
                mode: msg.mode,
                body: msg.body,
                code: msg.code,
                data: msg.data
            }
        );
    }

    get fun data(): CreditGetData {
        return
            CreditGetData{
                status: self.status,
                params: self.params!!,
                verifier: self.verifier,
                addresses: self.addresses!!,
                start: self.start,
                debt: self.arrear(),
                auction: self.auction
            };
    }

    get fun get_authority_address(): Address {
        return self.verifier;
    }

    get fun get_revoked_time(): Int {
        return 0;
    }

    get fun get_nft_data(): GetNftData {
        let individualContent: Builder = beginCell()
            .storeAddress(self.addresses!!.pawn)
            .storeUint(self.status, 8)
            .storeCoins(self.params!!.size)
            .storeUint(self.params!!.interest, 16)
            .storeUint(self.params!!.duration, 32)
            .storeUint(self.start, 32);
        if (self.auction != null) {
            let auctionContent: Cell = beginCell()
            .storeCoins(self.auction!!.bid)
            .storeAddress(self.auction!!.bidder)
            .storeUint(self.auction!!.finish, 32)
            .endCell();

            individualContent = individualContent.storeRef(auctionContent);
        }

        return
            GetNftData{
                is_initialized: self.status > STATUS_NOT_INIT,
                index: self.index,
                collection_address: self.verifier,
                owner_address: self.addresses!!.borrower,
                individual_content: individualContent.endCell()
            };
    }
}