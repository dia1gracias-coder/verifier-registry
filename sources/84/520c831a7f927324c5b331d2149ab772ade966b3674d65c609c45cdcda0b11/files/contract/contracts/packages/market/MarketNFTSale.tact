import "../nft//extension/NFTRoyalty.tact";
import "../nft/NFTItem.tact";
/*
    Trait Standard NFT Sale
    Oriented - https://github.com/getgems-io/nft-contracts/blob/main/packages/contracts/nft-fixprice-sale-v3/description-ru.md
*/

/* 
    Этот контракт используется когда продавец хочет продать нфт за фиксированную цену в тонах. 
    Продавец деплоит контракт продажи и передает нфт на этот контракт. 
    Покупатель отправляет на контракт продажи тоны + ~0.1 для оплаты газа. 
    Контракт передает нфт покупателю, а тоны продавцу, после этого покупка считается совершенной. 
    Продавец может отменить продажу в любой момент до покупки.

    Перед покупкой необходимо убедиться что нфт достаточно 0.1 тон для смены владельца, если этого недостаточно то надо прислать больше тонов. 
    Если нет возможности рассчитать сумму заранее, то для совершения покупки рекомендуется прислать full_price + 1 тон.
*/


// Sale message/struct

struct MarketSaleData {
    is_complete: Bool; // завершена ли продажа или нет
    created_at: Int; // время создания контракта, используется чтобы одинаковые контракты имели разные адреса
    marketplace_address: Address;
    nft_address: Address;
    nft_owner_address: Address;
    full_price: Int as coins;
    marketplace_fee_address: Address; // адрес для комиссии маркетплейса
    marketplace_fee: Int; // Размер комиссии маркетплейса
    royalty_amount: Int; // размер роялти коллекции
    royalty_address: Address; // адрес для роялти коллекции
    sold_at: Int = 0; // Дата продажи нфт, если она состоялась
    query_id: Int = 0; // query_id который привёл к продаже nft
}

message(0xb55d2cd9) KefiriumBuy {
    query_id: Int as uint64;   
    transfer_address: Address;
}

message(0xa33e485c) KefiriumCancel {
    query_id: Int as uint64;   
}

message Init {
    owner: Address;
}



// Для деления на 100%
const hundred_percent: Int = 100000000000;

// ~ необходимо для метода Transfer
const nft_transfer_value: Int = ton("0.1");

// Для вычесления процентов
@name(muldiv)
native mulDiv(a: Int, b: Int, c: Int): Int;


trait MarketNFTSale {

    is_complete: Bool; 
    created_at: Int; 
    marketplace_address: Address;
    nft_address: Address;
    nft_owner_address: Address;
    full_price: Int;
    marketplace_fee_address: Address;
    marketplace_fee: Int; 
    royalty_amount: Int; 
    royalty_address: Address; 
    sold_at: Int;
    query_id: Int;


    nft_collection: Address?;

    is_init: Bool;



    //*********************************//
    //             Messages            //
    //*********************************//


    // Need to kefirium buy
    receive(msg: KefiriumBuy) {
        self._buy(msg);
    }

    // Need to kefirium cancel
    receive(msg: KefiriumCancel) {
        self._cancel(msg);
    }

    // Need to get collection royalty
    receive(msg: ReportRoyaltyParams) {
        self._get_nft_royalty_data(msg);
    }

    // Need to get collection address
    receive(msg: ReportStaticData) {
        self._send_nft_royalty_data(msg);
    }


    receive(msg: Init) {
        require(!self.is_init, "Owner inited");
        self.nft_owner_address = msg.owner;
    }




    //*********************************//
    //       Internal functions        //
    //*********************************//

    virtual inline fun _cancel(msg: KefiriumCancel) {
        let ctx: Context = context();

        require(
            ctx.sender == self.nft_owner_address || 
            ctx.sender == self.marketplace_address, 
            "You not owner"
        );
        require(!self.is_complete, "Dont have NFT");


        self._transfer_cancel(msg, ctx);
    } 


    virtual inline fun _buy(msg: KefiriumBuy) {
        let ctx: Context = context();

        require(self.full_price <= ctx.value, "Need more TON");
        require(!self.is_complete, "Dont have NFT");

        self._payments(ctx);

        self._transfer_buy(msg, ctx);

        self.nft_owner_address = sender();
        self.query_id = msg.query_id;
        self.is_complete = true;
        self.sold_at = now();

        // Переводим все деньги при продаже
        send(SendParameters{
            to: self.marketplace_address,
            value: 0,
            mode: SendRemainingBalance
        });
    }

    inline fun _transfer_buy(msg: KefiriumBuy, ctx: Context) {
        send(SendParameters{
            to: self.nft_address,
            value: nft_transfer_value,
            mode: SendIgnoreErrors,
            body: Transfer{
                query_id: msg.query_id,
                new_owner: msg.transfer_address,
                response_destination: msg.transfer_address,
                custom_payload: emptyCell(),
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });
    }


    inline fun _transfer_cancel(msg: KefiriumCancel, ctx: Context) {
        send(SendParameters{
            to: self.nft_address,
            value: nft_transfer_value,
            mode: SendIgnoreErrors + SendRemainingValue,
            body: Transfer{
                query_id: msg.query_id,
                new_owner: self.nft_owner_address,
                response_destination: self.nft_owner_address,
                custom_payload: emptyCell(),
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });
    }

    inline fun _payments(ctx: Context) {
        if(self.royalty_address != newAddress(0, 0)) {
        
            // Отправка роялти на royalty_address
            send(SendParameters{
                to: self.royalty_address,
                value: self.royalty_amount
            });

            ctx.value = ctx.value - self.royalty_amount;
        }

        if(self.marketplace_fee_address != newAddress(0, 0)) {
            // Отправка комиссии площадке
            send(SendParameters{
                to: self.marketplace_fee_address,
                value: self.marketplace_fee
            });

            ctx.value = ctx.value - self.marketplace_fee;
        }


    }


    virtual inline fun _get_nft_royalty_data(msg: ReportRoyaltyParams) {
        require(self.nft_collection == sender(), "Only nft collection method");

        let denominator: Int = msg.denominator;
        let numerator: Int = msg.numerator;

        self.royalty_address = msg.destination;

        // Для предотвращения ошибки при numerator / 0, При некоректном royalty коллекции
        if(denominator == 0) {
            numerator = 0;
            denominator = 1;
        }

        self.royalty_amount = mulDiv(
            self.full_price, 
            mulDiv(numerator, hundred_percent, denominator), 
            hundred_percent
        );

    }

    virtual inline fun _send_nft_royalty_data(msg: ReportStaticData) {
        require(sender() == self.nft_address, "Only nft method");
        self.nft_collection = msg.collection;
        send(SendParameters{
            to: msg.collection,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue,
            body: GetRoyaltyParams{
                query_id: now()
            }.toCell()
        });
    }

    virtual inline fun _send_nft_static_data() {
        // Отправляю сообщения на nft_address, для получения адреса коллекции
        send(SendParameters{
            to: self.nft_address,
            value: ton("0.02"),
            bounce: false,
            body: GetStaticData{
                query_id: now(),
            }.toCell()
        });
    }

    virtual inline fun _get_fix_price_data(): MarketSaleData {
        return MarketSaleData{
            is_complete: self.is_complete,
            created_at: self.created_at,
            marketplace_address: self.marketplace_address,
            nft_address: self.nft_address,
            nft_owner_address: self.nft_owner_address,
            full_price: self.full_price,
            marketplace_fee_address: self.marketplace_fee_address,
            marketplace_fee: self.marketplace_fee,
            royalty_address: self.royalty_address,
            royalty_amount: self.royalty_amount,
            sold_at: self.sold_at,
            query_id: self.query_id,
        }
    }

    //*********************************//
    //             Getters             //
    //*********************************//

    get fun get_fix_price_data(): MarketSaleData {
        return self._get_fix_price_data();
    }
}