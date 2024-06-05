import "@stdlib/deploy";
import "./messages.tact";

// Минимальный расход газа для операций
const gasConsumption: Int = ton("0.05");
// Минимальный остаток на балансе контракта
const minTonsForStorage: Int = ton("0.05");

contract Nft {

    // Переменные контракта NFT
    index: Int as uint64; // Уникальный индекс NFT
    collection_address: Address; // Адрес коллекции, к которой принадлежит NFT
    owner_address: Address?; // Адрес текущего владельца NFT
    individual_content: Cell?; // Индивидуальный контент NFT
    is_initialized: Bool; // Флаг инициализации NFT


    // Инициализация контракта NFT
    init(index: Int, collection_address: Address){
         // Установка значений переменных
        self.index = index;
        self.collection_address = collection_address;
        self.owner_address = null;
        self.individual_content = null;
        self.is_initialized = false;
    }

    // Обработка входящих сообщений без тела (не принимаем поплнения контракта)
    receive(){
        nativeThrow(0xffff);  // Бросаем исключение для неизвестных сообщений
    }

   // Обработка сообщений передачи NFT
    receive(msg: Transfer) {
        let ctx: Context = context();
        self.isOwner(ctx.sender);  // Проверка, является ли отправитель владельцем
        if(self.is_initialized == false) {
            self.mint(ctx, msg);  // Инициализация NFT
        } else {
            self.transfer(ctx, msg);  // Передача прав на NFT
        }
    }

    // Смена контента NFT, может выполнить только коллекция
    receive(msg: InteralChangeIndividualContent){
        let ctx: Context = context();
        nativeThrowUnless(401, self.collection_address == ctx.sender);// Проверка, что отправитель - коллекция
        self.content_change(ctx, msg);
    }

    // Обработка запроса статических данных
    receive(msg: GetStaticData) {
        let ctx: Context = context();
        self.report_static_data(ctx, msg);  // Отправка данных обратно
    }

    // Обработка некорректных сообщений (Фильтруем не известные запросы)
    receive(msg: Slice) {
        throw(0xffff);  // Исключение для неизвестных сообщений
    }

    // Проверка, является ли адрес владельцем
    fun isOwner(address: Address) {
        let checkOwner : Bool = false;
        if(self.owner_address != null){
            if(self.owner_address!! == address){
                checkOwner = true;
            }
        }
        nativeThrowUnless(401, checkOwner == true || self.collection_address == address);
    }


    // Изменение контента NFT
    fun content_change(ctx: Context, msg: InteralChangeIndividualContent)
    {
        self.individual_content = msg.individual_content;
    }

    // Инициализация и выдача NFT
    fun mint(ctx: Context, msg: Transfer)
    {
        self.is_initialized = true;  // Установка флага инициализации
        self.owner_address = msg.new_owner_address;  // Установка нового владельца
        self.individual_content = msg.custom_payload;  // Установка индивидуального контента

        // if(msg.response_destination != null) {
        //     let msgValue: Int = self.msgValue(ctx.value);
        //     if(msgValue > 0){
        //         send(SendParameters{
        //             to: msg.response_destination!!,
        //             value: msgValue,
        //             mode: SendPayGasSeparately + SendIgnoreErrors,
        //             body: Excesses { query_id: msg.query_id }.toCell()
        //         });
        //     }
        // } 
    }

     // Передача прав владения NFT
    fun transfer(ctx: Context, msg: Transfer)
    {
        let sender_address: Address = ctx.sender;
        let new_owner_address: Address = msg.new_owner_address;

        // TODO: check work chain is same as new_owner_address

        let response_destination: Address? = msg.response_destination;
        let forward_amount: Int = msg.forward_amount;
        let fwd_fee: Int = ctx.readForwardFee() * 3 / 2;//Расчитываем коммиссию запроса
        let rest_amount: Int = (myBalance() - minTonsForStorage);
        if (forward_amount > 0) {
            rest_amount -= (forward_amount + fwd_fee);
        }
        if (response_destination != null) {
            rest_amount -= fwd_fee;
        }
        nativeThrowUnless(402, rest_amount >= 0); // base nft spends fixed amount of gas, will not check for response

        if (forward_amount > 0) {
            send(SendParameters{
                    to: new_owner_address,
                    value: forward_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner: self.owner_address!!,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }
            );
        }
        if (response_destination != null) {
            // TODO: check work chain is same as response_destination
            send(SendParameters{
                    to: response_destination!!,
                    value: rest_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: Excesses{ query_id: msg.query_id }.toCell()
                }
            );
        }
        self.owner_address = new_owner_address;// Обновление владельца
    }

    // Отправка статических данных о контракте
    fun report_static_data(ctx: Context, msg: GetStaticData) {
        let sender_address: Address = ctx.sender;
        send(SendParameters{
            to: sender_address,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ReportStaticData{
                query_id: msg.query_id,
                index: self.index,
                collection_address: self.collection_address
            }.toCell()
        }
    );
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // Получение данных о текущем состоянии NFT
    get fun get_nft_data(): NftData {

        if(self.is_initialized == true){

            return NftData{
                is_initialized: true,
                index: self.index,
                collection_address: self.collection_address,
                owner_address: self.owner_address!!,
                individual_content: self.individual_content!!
            };

        }else{

            return NftData{
                is_initialized: false,
                index: self.index,
                collection_address: self.collection_address,
                owner_address: null,
                individual_content: null
            };
        }
      
    }
}



contract NftCollection with Deployable {

    // Переменные контракта коллекции
    owner: Address; // Владелец контракта   
    next_item_index: Int as uint64; // Количество предметов в контракте (индексация NFTItem начинается с 0 = (NFTItem1), 1 = (NFTItem2) и т.д.)
    content: Cell; // Описание NFTCollection, ссылка на JSON-файл
    nft_item_content_common: Cell; // Описание NFTItem, ссылка на место, где будут храниться файлы
    royalty_params: RoyaltyParams; // Информация для биржи, получения комиссии с продаж
    second_owner: Address?; // Второй владелец контракта

    specialData: SpecialData;//Данные о розыгрыши специальных NFT

    // Инициализация коллекции NFT
    init(collectionContentUrl: Cell, nftContentBaseUrl: Cell, royaltyPercent: Int, royaltyAddress: Address){

        self.owner = context().sender;
        self.next_item_index = 0;
        self.content = collectionContentUrl;
        self.nft_item_content_common = nftContentBaseUrl;
        self.royalty_params = RoyaltyParams{ 
            numerator: royaltyPercent, //Процент 1% до 100%
            denominator: 100, 
            destination: royaltyAddress 
            };


        // Инициализация данных для специальных NFT
        self.specialData = SpecialData {

            // Количество доступных для деплоя предметов
            nft_basic: 264,
            nft_silver: 25,
            nft_gold: 10,
            nft_platinum: 1,

            // Параметры для индексации картинок 0 и 100.. (0.json, 1.json и т.д)
            next_basic_index: 0,
            next_silver_index: 0,
            next_gold_index: 0,
            next_platinum_index: 0,

            // Минимальный порог входа в вайтлист
            coin_minial: ton("100000"),

            // Включает и отключает проверку на вайтлист для деплоя
            address_check: true,

            // Массив разрешенных адресов и количество выполняемых операций
            address_mint: emptyMap()
        };

    }

   
    // Получение данных о роялти
    receive(msg: GetRoyaltyParams){
        let ctx: Context = context();
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ReportRoyaltyParams{
                query_id: msg.query_id,
                royalty_params: self.royalty_params
            }.toCell()
        });
    }

    // Создание нового NFTItem
    receive(msg: NftCollectionDeployNewNft){
        let ctx: Context = context();
        self.isOwner(ctx.sender);
        let new_owner: Address = ctx.sender;
        if(msg.new_owner != null){
            new_owner = msg.new_owner!!;
        }
        self.mint(new_owner, ctx.sender, msg.nft_content);
    }

    // Создание множества NFTItem
    // receive(msg: NftCollectionBatchDeployNewNft){
    //     let ctx: Context = context();
    //     self.isOwner(ctx.sender);

    //     //Написать код
    // }

    // Смена владельца контракта
    receive(msg: NftCollectionChangeOwner){
        let ctx: Context = context();
        nativeThrowUnless(401, ctx.sender == self.owner);//Only the contract owner can perform this operation
        self.owner = msg.new_owner;
        self.second_owner = msg.new_owner;
        self.remainTransfer(ctx);
    }

    // Изменить заместителя главы контракта
    receive(msg: NftCollectionChangeSecondOwner){
        let ctx: Context = context();
        self.isOwner(ctx.sender);
        self.second_owner = msg.new_second_owner;
        self.remainTransfer(ctx);
    }


    // Возврат всего баланса контракта с оставлением минимального баланса
    receive(msg: NftCollectionReturnBalance){
        let ctx: Context = context();
        self.isOwner(ctx.sender);
        nativeReserve(minTonsForStorage, 0);
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendRemainingBalance,
            bounce: true,
            body: NftCollectionReturnBalance{
                query_id: msg.query_id
            }.toCell()
        });
    }


    // Изменить метаданные контракта
    receive(msg: NftCollectionChangeContent){
        let ctx: Context = context();
        self.isOwner(ctx.sender);
        self.content = msg.content;
        self.nft_item_content_common = msg.nft_item_content_common;
        self.remainTransfer(ctx);
    }

    // Изменить метаданные (в данном случае меняем только имя файла "0.json", "1.json", "newcard/1.json" и т.д.) одного NFTItem
    receive(msg: NftCollectionChangeItemContent){
        let ctx: Context = context();
        self.isOwner(ctx.sender);
        self.changeNft(msg.item_index, null, msg.individual_content);
    }


    // Изменить данные о количестве доступных карточек в особых NFT для розыгрыша
    receive(msg: NftCollectionChangeSpecialDataItem){

        let ctx: Context = context();
        self.isOwner(ctx.sender);
        self.specialData.nft_basic = msg.nft_basic;
        self.specialData.nft_silver = msg.nft_silver;
        self.specialData.nft_gold = msg.nft_gold;
        self.specialData.nft_platinum = msg.nft_platinum;
        self.remainTransfer(ctx);
    }

    // Изменить минимальное количество коинов для входа в вайтлист особых NFT
    receive(msg: NftCollectionChangeSpecialDataTonMin){

        let ctx: Context = context();
        self.isOwner(ctx.sender);
        self.specialData.coin_minial = msg.value;
        self.remainTransfer(ctx);
    }

    // Добавить или заменить данные в массиве адресов участников и количество раз, которое можно выполнить условие в особых NFT
    receive(msg: NftCollectionChangeSpecialDataAddAddress){
        let ctx: Context = context();
        self.isOwner(ctx.sender);
        let i: Int = 0;
        repeat (msg.length_list) {
            let cnt: Int? = msg.count_list.get(i);
            let adr: Address? = msg.address_list.get(i);
            if(cnt != null && adr != null){
                self.specialData.address_mint.set(adr!!, cnt!!);
            }
            i = i + 1;
        }
        self.remainTransfer(ctx);
    }

    // Очистить данные в массиве адресов участников в особых NFT
    receive(msg: NftCollectionChangeSpecialDataClearAddress){
        let ctx: Context = context();
        self.isOwner(ctx.sender);
        self.specialData.address_mint = emptyMap();
        self.remainTransfer(ctx);
    }


    // Включить или отключить проверку массива адресов участников в особых NFT
    receive(msg: NftCollectionChangeSpecialDataCheckAddress){
        let ctx: Context = context();
        self.isOwner(ctx.sender);
        self.specialData.address_check = msg.address_check;
        self.remainTransfer(ctx);
    }

    // Деплой специльных NTF либо по вайтлисту либо без ограничений
    receive("special")
    {
        let ctx: Context = context();
        self.mint_special(ctx.sender);
    }

    // Добавить пользователя в вайтлист при прохождении минимальной суммы
    receive("special_list")
    {
        let ctx: Context = context();
        let cnt: Int = (ctx.value / self.specialData.coin_minial);
        nativeThrowUnless(20001, ctx.value >= self.specialData.coin_minial && cnt > 0);//Insufficient funds to participate.
        let cntMap: Int? = self.specialData.address_mint.get(ctx.sender);
        if(cntMap != null){
            cnt = cnt + cntMap!!;
        }
        self.specialData.address_mint.set(ctx.sender, cnt);
    }
   
   
    // Может получать коины, если не вызвать throw
    receive(){
        //nativeThrow(0xffff);
    }

     // Обработка некорректных сообщений (Фильтруем не известные запросы)
    receive(msg: Slice){
        throw(0xffff);
    }


    // Проверить, может ли только глава контракта или его заместитель выполнить команды
    fun isOwner(address: Address) {
        nativeThrowUnless(402, self.owner == address || self.second_owner == address);//You are not the owner of the contract.
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // Возвращает оставшиеся коины в запросе
    fun remainTransfer(ctx: Context){
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            bounce: false,
            mode:  SendIgnoreErrors + SendRemainingValue,
            body: Excesses { query_id: 0 }.toCell()
        });
    }



    //Генерация приоритетнее в пользу большим количествам числа в категории 
    fun get_type_special_nft() : Int{
        let nonEmptyCount: Int = self.specialData.nft_basic+self.specialData.nft_silver+self.specialData.nft_gold+self.specialData.nft_platinum;
        if(nonEmptyCount > 0)
        {
            // Генерируем случайное число от 0 до суммарного количества предметов - 1
            let randomIndex: Int = randomInt() % nonEmptyCount;
             // Определяем категорию на основе случайного индекса
            if (randomIndex < self.specialData.nft_basic) {
                return 0; // Категория NFT Basic
            } else if (randomIndex < self.specialData.nft_basic + self.specialData.nft_silver) {
                return 1; // Категория NFT Silver
            } else if (randomIndex < self.specialData.nft_basic + self.specialData.nft_silver + self.specialData.nft_gold) {
                return 2; // Категория NFT Gold
            } else {
                return 3; // Категория NFT Platinum
            }
        }
        return -1;
    }
  


    // Функция деплоя предметов
    fun mint(new_owner: Address, response_owner: Address?, individual_content: Cell) {

         let nftItemInit: StateInit = initOf Nft(self.next_item_index, myAddress());
         
         let transferData: Transfer = 
            Transfer {
                query_id: 0,
                new_owner_address: new_owner,
                response_destination: null,
                custom_payload: individual_content,//custom set individual_content mint
                forward_amount: 0,
                forward_payload: emptySlice()
            };

        if(response_owner != null){
            transferData.response_destination = response_owner!!;
        }
         send(SendParameters{
                to: contractAddress(nftItemInit), 
                value: ton("0.1"), 
                bounce: false,
                mode: SendPayGasSeparately,//Платим отдельно за комиссию с баланса нашего контракта
                body: transferData.toCell(),
                code: nftItemInit.code,
                data: nftItemInit.data
        });
    
        self.next_item_index = self.next_item_index + 1;
    }

    // Функция деплоя специальных предметов (папки - special/base/, special/silver/, special/gold/, special/platinum/)
    fun mint_special(address: Address){
        let sender_address: Address = address;
        let counterAddress: Int? = null;

        // Проверяем включена проверка или нет вайтлиста участников
        if(self.specialData.address_check == true){
            
            let next: Bool = false;
            counterAddress = self.specialData.address_mint.get(sender_address);
            if(counterAddress != null){
                if(counterAddress!! > 0){
                    next = true;
                }
            }
            nativeThrowUnless(20003, next == true);//You are not on the list of authorized participants.
        }

        // Получаем выигрышную позицию (если -1 то нету доступных позиций)
        let typeSpec: Int = self.get_type_special_nft();

        nativeThrowUnless(20004, typeSpec != -1);//Special offers are not available.

      
        //Генерируем путь в папку с json файлом, описания NTFItem
        let sb: StringBuilder = beginString();
        sb.append("special/");
        if(typeSpec == 0){
            sb.append("basic/");
            sb.append((self.specialData.next_basic_index + 1).toString());
        }
        if(typeSpec == 1){
            sb.append("silver/");
            sb.append((self.specialData.next_silver_index + 1).toString());
        }
        if(typeSpec == 2){
           sb.append("gold/");
           sb.append((self.specialData.next_gold_index + 1).toString());
        }
        if(typeSpec == 3){
            sb.append("platinum/");
            sb.append((self.specialData.next_platinum_index + 1).toString());
        }
        sb.append(".json");

        //Деплоим NFTItem
        self.mint(sender_address, sender_address/*null*/, sb.toCell());

        //Выполняем добавления индекции для немераций файлов 
        if(typeSpec == 0){
            self.specialData.next_basic_index = self.specialData.next_basic_index + 1;
            self.specialData.nft_basic = self.specialData.nft_basic - 1;
        }
        if(typeSpec == 1){
            self.specialData.next_silver_index = self.specialData.next_silver_index + 1;
            self.specialData.nft_silver = self.specialData.nft_silver - 1;
        }
        if(typeSpec == 2){
           self.specialData.next_gold_index = self.specialData.next_gold_index + 1;
           self.specialData.nft_gold = self.specialData.nft_gold - 1;
        }
        if(typeSpec == 3){
            self.specialData.next_platinum_index = self.specialData.next_platinum_index + 1;
            self.specialData.nft_platinum = self.specialData.nft_platinum - 1;
        }

        // Если весь код выше выполнился успешно, отнимаем количество успешных попыток пользователя
        if(self.specialData.address_check == true && counterAddress != null){
            self.specialData.address_mint.set(sender_address, counterAddress!! - 1);
        }
    }

    // Функция смены имени файла nft (1.json, path/1.json, path/path2/1.json и т. д.)
    fun changeNft(index: Int, value: Int?, individual_content: Cell)
    {
        let stateInit: StateInit = initOf Nft(index, myAddress());
        let nft_address: Address = contractAddress(stateInit);

        if(value != null){
            send(SendParameters{
                to: nft_address,
                value: value!!,
                mode: SendPayGasSeparately,
                body: InteralChangeIndividualContent{query_id: 0,individual_content: individual_content}.toCell()
            });
        }
        else
        {
            send(SendParameters{
                to: nft_address,
                value: ton("0.1"),
                mode: SendPayGasSeparately,
                body: InteralChangeIndividualContent{query_id: 0,individual_content: individual_content}.toCell(),
            });
        }
    }

    // Информация о специальных NFT
    get fun get_special_info_data(): SpecialData{
        return self.specialData;
    }

    // Информация о специальных NFT списко адресов
    get fun get_special_list_data(): map<Address, Int>{
        return self.specialData.address_mint;
    }

    // Информация о специальных NFT список разрешенных адресов, конкретного адреса
    get fun get_special_use_list_data(address: Address): Int{
        let count : Int? =  self.specialData.address_mint.get(address);
        if(count != null){
            return count!!;
        }
        return -1;
    }

    // Информация о коллекции, сколько предметов, описание коллекции json ссылка и владелец
    get fun get_collection_data(): NftCollectionData {
        return NftCollectionData{
            next_item_index: self.next_item_index,
            content: self.content,
            owner_address: self.owner
        };
    }

    // Получает адрес NFTItem по индексу
    get fun get_nft_address_by_index(index: Int): Address {
        let stateInit: StateInit = initOf Nft(index, myAddress());
        let nft_address: Address = contractAddress(stateInit);
        return nft_address;
    }


    // Информация для бирж, выплаты с продаж
    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params;
    }

    // Информация о владельце
    get fun get_second_owner_address(): Address {
        if(self.second_owner != null){
            return self.second_owner!!;
        } else {
            return self.owner;
        }
    }

    // Информация о коллекции json ссылка и ссылка на домен nftitem, где хранятся файлы json
    get fun get_nft_content(index: Int, individual_nft_content: Cell): Cell {
        let nft_content: Cell = beginCell()
                                .storeSlice(self.nft_item_content_common.beginParse())
                                .storeRef(individual_nft_content)
                                .endCell();
        return nft_content;
    }

    // Баланс контракта
    get fun get_balance() : Int{
        return myBalance();
    }

    
    // Функция перемешивание файлов NTFItem (В разработке, данная функция работает но не подходит если использовать NFT у которых картинки разбиты по папкам, требуется доработка)
    // fun rand_changeNfts(ctx: Context)
    // {
    //     nativeThrowUnless(1000, self.next_item_index > 0);
    //     let msgValue: Int = self.estimate_rest_value(ctx.value,self.next_item_index);
    //     nativeThrowUnless(1001, msgValue > 0);
    //     let index: Int = 0;
    //     let randomContent: map<Int, Cell> = emptyMap();
    //     repeat(self.next_item_index )
    //     {
    //         let indexContent: Int = index + 1;
    //         let strContent: StringBuilder = beginString();
    //         strContent.append(indexContent.toString());
    //         strContent.append(indexContent.toString());
    //         randomContent.set(index, strContent.toCell());
    //         index += 1;
    //     }

    //     let n: Int = self.next_item_index;
    //     let i: Int = n - 1;

    //     while (i > 0) {
    //         let j: Int = randomInt() % (i + 1);
    //         let temp: Cell = randomContent.get(i)!!;
    //         randomContent.set(i,randomContent.get(j)!!);
    //         randomContent.set(j,temp);
    //         i -= 1;
    //     }

    //     index = 0;
    //     repeat(self.next_item_index)
    //     {
    //         let cellContent: Cell = randomContent.get(index)!!;
    //         self.changeNft(index, msgValue, cellContent);
    //         index += 1;
    //     }
    // }
}
