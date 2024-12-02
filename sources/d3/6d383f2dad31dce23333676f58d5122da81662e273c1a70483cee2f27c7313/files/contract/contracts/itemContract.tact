import "./message.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/content";

struct ValueMap {
    value: String;
}



struct FullContent {
    data: map<Int as uint256, Cell>;
}

//QmUeUbtWw3fG6rPcJRqZcrEr3yYPvFQdgi5EBqbNGwqosa
contract NftItem with  Ownable{
    
    collection_address: Address;
    index: Int as uint256; 
    owner: Address;
    content: Cell; 

    is_init: Bool = false;    
    game_attributes_distans: Int as uint16;    
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;
    nonce: Int as uint32;    
    mapdata: map<Int as uint256, Cell>;
    init(collection_address: Address, item_index: Int ){
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.index = item_index;        
        self.owner = sender();
        self.game_attributes_distans = 7;        
        self.royalty_destination = sender();
        self.numerator = 5;
        self.denominator = 100;
        self.content = beginCell().storeSlice("https://drivecoin.io:3001/nft/1.json".asSlice()).endCell();       
        self.nonce = 0;
        
        
    }
    receive(msg: InitDeployed) {
        require(sender() == self.collection_address, "Invalid sender");
        require(!self.is_init, "Already deployed");
        
        // Подтверждаем успешный деплой
        send(SendParameters{
            to: self.collection_address,
            value: 0,
            mode: SendRemainingValue,
            body: InitDeployedTrue{
                query_id: msg.query_id,
                nft_address: myAddress(),
                sender: msg.sender,
                individual_content: msg.individual_content
            }.toCell()  // Возвращаем то же сообщение как подтверждение
        });
    }
    
    receive(msg: Transfer){
        let ctx: Context = context();
        
        if (self.is_init == false) {
            require(ctx.sender == self.collection_address, "initialized tx need from collection");
            self.is_init = true;
            self.owner = msg.new_owner;
            //self.content = msg.custom_payload;

            // Возвращаем весь остаток на адрес коллекции
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0,
                mode: SendRemainingValue, // Режим 128 - отправляет весь остаток
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        } else {
            require(ctx.sender == self.owner, "not owner");
            self.owner = msg.new_owner;  // change current owner to the new_owner
            if (msg.forward_amount > 0) {
                send(SendParameters{
                    to: msg.new_owner,
                    value: msg.forward_amount,
                    mode:  SendPayGasSeparately, 
                    bounce: false,
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner: ctx.sender,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }); 
            }

            let msgValue = ctx.value - ctx.readForwardFee(); 
            if (msg.response_destination != null) { 
                send(SendParameters{ 
                    to: msg.response_destination!!,
                    value: msgValue - msg.forward_amount,
                    mode: SendPayGasSeparately,
                    bounce: true,
                    body: Excesses { query_id: msg.query_id }.toCell()
                });
            } 
        }
    }
    receive("get_static_data"){ 
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,
            bounce: true,
            body: ReportStaticData{
                query_id: 0,
                index_id: self.index,
                collection: self.collection_address
            }.toCell()
        });
    }

    receive(msg: UpdateMeta){ 
        let ctx: Context = context();
        // // Проверяем, что запрос пришел от адреса коллекции
        // // Только владелец коллекции может обновлять контент NFT
        // require(ctx.sender == self.collection_address, "not from collection");
        
        // Обновляем индивидуальный контент NFT новым значением
        // content должен прийти в сообщении UpdateContent
        //QmUTj4n5znFTLkGXMvF55WdFUc5JkxhqeUjAC2kTa7QQzG
        self.content = beginCell().storeSlice("QmPzo9NKgSFKdTtq2GpoDCzGvTzrKnSyZNP2yEAKkYqPia".asSlice()).endCell();
        
        // Отправляем ответное сообщение отправителю
        send(SendParameters {
            to: ctx.sender,        // Отправляем ответ тому, к прислал сообщение
            value: 0,              // Не отправляем TON
            mode: 64,              // Режим 64 возвращает оставшиеся газы
            bounce: true,          // Разрешаем возврат сообщения в случае ошибки
            body: Excesses{        // Отправляем стандартное сообщение об успехе
                query_id: msg.query_id  // Возвращаем тот же query_id для отслеживания
            }.toCell()
        });
    }





    receive(msg: UpdateContent){ 
        let ctx: Context = context();
        // Проверяем, что запрос пришел от адреса коллекции
        // Только владелец коллекции может обновлять контент NFT
        require(ctx.sender == self.collection_address, "not from collection");
        
        // Обновляем индивидуальный контент NFT новым значением
        // content должен прийти в сообщении UpdateContent
        self.content = msg.content;
        
        // Отправляем ответное сообщение отправителю
        send(SendParameters {
            to: ctx.sender,        // Отправляем ответ тому, к прислал сообщение
            value: 0,              // Не отправляем TON
            mode: 64,              // Режим 64 возвращает оставшиеся газы
            bounce: true,          // Разрешаем возврат сообщения в случае ошибки
            body: Excesses{        // Отправляем стандартное сообщение об успехе
                query_id: msg.query_id  // Возвращаем тот же query_id для отслеживания
            }.toCell()
        });
    }
   
   
    receive(msg: SetGameAttributes){        
        let ctx: Context = context();
        require(sender() == self.owner, "not from collection");
        require(msg.nonce > self.nonce, "Invalid nonce");
        self.nonce = msg.nonce; 
        let hash: Int = beginCell().storeUint(msg.distans, 256).storeUint(msg.nonce, 32).endCell().hash();//Проверяем подпись
        let isValid = checkSignature(hash, msg.signature, msg.public_key);
        
        
        require(isValid, "Invalid signature");       
        self.game_attributes_distans = msg.distans;
         send(SendParameters {
            to: ctx.sender,        // Отправляем ответ тому, к прислал сообщение
            value: 0,              // Не отправляем TON
            mode: 64,              // Режим 64 возвращает оставшиеся газы
            bounce: true,          // Разрешаем возврат сообщения в случае ошибки
            body: Excesses{        // Отправляем стандартное сообщение об успехе
                query_id: msg.query_id  // Возвращаем тот же query_id для отслеживания
            }.toCell()
        });

    }



    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // --------- Get Function  --------- //
    fun createOffchainContent(link: String): Cell {
        let builder: StringBuilder = beginStringFromBuilder(beginCell().storeUint(0x01, 8));
        builder.append(link);        
        return builder.toCell();
    }

    // Вспомогательная функция для формирования JSON с атрибутом distance
    fun getAttributesJson(): String {
        let json: StringBuilder = beginString();
        json.append("{");
        json.append("\"attributes\":[");
        json.append("{\"trait_type\":\"Distance\",\"value\":");
        json.append(self.game_attributes_distans.toString());
        json.append("}");
        json.append("]}");
        return json.toString();
        }
   
    get fun get_static_data(): ReportStaticData { 
        return ReportStaticData {
            query_id: 0,
            index_id: self.index,
            collection: self.collection_address
        };
        }
    
    get fun get_game_attributes(): GameAttributes{
        return GameAttributes{
            distans: self.game_attributes_distans
        };
    }
  
   
   
    get fun get_statistic(): GetState {
        return GetState {
            collection_address: self.collection_address,
            item_index: self.index,
            is_init: self.is_init,
            owner: self.owner,
            game_attributes_distans: self.game_attributes_distans,
            individual_content: self.content,
            royalty_destination: self.royalty_destination,
            numerator: self.numerator,
            denominator: self.denominator
        };
        }

      
    
    get fun get_nft_data(): GetNftData {
        let uri = self.content.beginParse().asString();        
        let newContent: StringBuilder = beginStringFromBuilder(beginCell().storeUint(0x01, 8));
        newContent.append("https://drivecoin.io:3001/nft/");
        newContent.append(self.game_attributes_distans.toString());  
        newContent.append(".json");
        
        // let content_url: Slice = self.content_n.beginParse();

        // let newContent: StringBuilder = beginStringFromBuilder(beginCell().storeUint(0x01, 8));
        // newContent.append("ipfs://");
        // newContent.append(content_url.asString());
        // let uu = newContent.toCell(); 
        

        return GetNftData{
            init: self.is_init? 1:0,
            index: self.index,
            collection_address: self.collection_address,
            owner_address: self.owner,
            individual_content: newContent.toCell()        
        };
    }
    
}

