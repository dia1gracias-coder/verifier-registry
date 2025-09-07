import "@stdlib/deploy";
import "@stdlib/ownable";
import "./nft_item.tact";
import "./messages.tact";

message Mint {}

const OFFCHAIN_PREFIX: Int = 0x01;

contract NftCollection(
    owner: Address,
    id: Int as uint32,
    next_item_index: Int as uint32,
    collection_content: String

) with Deployable, Ownable {
    const minTonForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03");
    const minItemDeployValue: Int = ton("0.05");

    receive(m: Mint){
        self.requireOwner();
        // let receiver: Address = m.to ?? sender();
        // self.mint(receiver);
        self.mint(sender());
    }

    inline fun mint(receiver: Address) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        let msgValue: Int = context().value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonForStorage - min(tonBalanceBeforeMsg, self.minTonForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);

        let fwdAmt: Int = ton("0.02");                       // ПРИМЕР: 0.02 TON (подбери сам)
    // Что переслать (можно null, если ничего не шлёшь)
        let fwdPayload: Cell? = null;

        send(SendParameters{
            to: contractAddress(nft_init),
            value: msgValue,
            mode: SendIgnoreErrors,
            bounce: true,
            body: Transfer{
                query_id: 0,
                new_owner: receiver,
                response_destination: null, // или myAddress() если хочешь уведомление
                custom_payload: null,
                forward_amount: fwdAmt,
                forward_payload: fwdPayload
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });
        self.next_item_index = self.next_item_index + 1;
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        let b: StringBuilder = beginString();
        b.append("Item # -- ");
        b.append(item_index.toString());

        return initOf NftItem(self.owner, myAddress(), item_index, b.toCell());
    }

    // get fun get_nft_content(index: Int, individual_content: Cell): Cell {
    //     // Адрес коллекции в user-friendly формате
    //     let collStr: String = myAddress().toString();

    //     // Собираем ссылку
    //     let sb = beginString();
    //     sb.append("https://teex.app/nft/");
    //     sb.append(collStr);
    //     sb.append("/");
    //     sb.append(index.toString());
    //     sb.append(".json");

    //     let fullUri: String = sb.toString();

    //     // Возвращаем ячейку с префиксом 0x01 (off-chain) и ASCII-URI
    //     return beginCell()
    //         .storeUint(0x01, 8)           // off-chain prefix
    //         .storeSlice(fullUri.asSlice())
    //         .endCell();
    // }

    get fun get_nft_address_by_index(item_index: Int): Address {
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    inline fun offchainUriCell(uri: String): Cell {
    // 0x01 + ref(ASCII-URI)
    return beginCell()
        .storeUint(OFFCHAIN_PREFIX, 8)
        .storeRef(beginCell().storeSlice(uri.asSlice()).endCell())
        .endCell();
    }


    get fun get_collection_data(): CollectionData {
        // Сборка полного URI для метаданных коллекции, если нужно:
        // base + myAddress + "/collection.json" (или "meta.json" — как договоришься)
        let sb = beginString();
        sb.append(self.collection_content);              // String из state
        sb.append(myAddress().toString());
        sb.append("/collection.json");                   // или "meta.json"
        let uri: String = sb.toString();

        return CollectionData{
            next_item_index: self.next_item_index,
            owner_address: self.owner,
            collection_content: self.offchainUriCell(uri)       // <-- строго TEP-64 off-chain
        };
    }
}
