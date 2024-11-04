import "@stdlib/deploy";
import "@stdlib/ownable";
import "./item";

struct CollectionData {
    next_index: Int;
    content: Cell;
    owner: Address;
}

message AdminWithdraw {
    queryId: Int as uint64;
}

message ClearStuckMint {
    queryId: Int as uint64;
    index: Int as uint256;
}

message ClearMintCooldown {
    queryId: Int as uint64;
    addr: Address;
}

contract NftCollection with Ownable, Deployable, NftRoyalty {
    owner: Address;
    next_index: Int as uint256 = 0;
    content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;
    supply: Int;
    pending_mints: map<Int, Bool>;  // Отслеживаем минты по индексу
    last_mint_time: map<Address, Int>;  // Время последнего минта для адреса

    const MINT_COOLDOWN: Int = 2; // Задержка между минтами в секундах

    init(owner: Address, content: Cell, royalty_destination: Address, numerator: Int, denominator: Int) {
        self.supply = 9999;
        self.owner = owner;
        self.content = content;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
    }

    receive(msg: RequestNftDeploy) {
        let ctx: Context = context();
        
        // Проверка времени последнего минта
        let last_mint_opt: Int? = self.last_mint_time.get(ctx.sender);
        if (last_mint_opt != null) {
            let last_mint: Int = last_mint_opt!!;
            require(now() - last_mint > self.MINT_COOLDOWN, "Please wait before minting again");
        }

        require(self.next_index < self.supply, "Drop ended");
        
        // Проверяем, не минтится ли уже этот индекс
        let is_pending_opt: Bool? = self.pending_mints.get(self.next_index);
        require(is_pending_opt == null || !is_pending_opt!!, "This index is being minted");
        
        // Помечаем индекс как минтящийся
        self.pending_mints.set(self.next_index, true);
        
        // Обновляем время последнего минта
        self.last_mint_time.set(ctx.sender, now());
        
        let current_index: Int = self.next_index;
        let nft_init: StateInit = initOf NftItem(myAddress(), current_index);
        let nft_address: Address = contractAddress(nft_init);
        
        send(SendParameters{
            to: nft_address,
            value: ton("0.03"),
            mode: SendPayGasSeparately,
            bounce: false,
            data: nft_init.data,
            code: nft_init.code,
            body: NftDeploy{
                index: current_index,
                owner: ctx.sender,
                content: msg.asset_metadata,
                royalty_destination: self.royalty_destination,
                numerator: self.numerator,
                denominator: self.denominator
            }.toCell()
        });

        // Увеличиваем индекс
        self.next_index = self.next_index + 1;
        
        // Снимаем пометку о минте
        self.pending_mints.set(current_index, false);
    }

    receive(msg: AdminWithdraw) {
        require(sender() == self.owner, "only owner!");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - ton("0.01"),
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    // Очистка зависшего минта (только owner)
    receive(msg: ClearStuckMint) {
        require(sender() == self.owner, "only owner!");
        self.pending_mints.set(msg.index, false);
    }

    // Очистка задержки минта (только owner)
    receive(msg: ClearMintCooldown) {
        require(sender() == self.owner, "only owner!");
        self.last_mint_time.set(msg.addr, 0);
    }

    get fun get_collection_data(): CollectionData {
        return CollectionData{next_index: self.next_index, content: self.content, owner: self.owner};
    }

    get fun get_nft_address_by_index(index: Int): Address {
        return contractAddress(initOf NftItem(myAddress(), index));
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        return individual_content;
    }

    get fun get_next_index(): Int {
        return self.next_index;
    }

    // Геттеры для проверки статуса
    get fun get_mint_state(index: Int): Bool {
        let state_opt: Bool? = self.pending_mints.get(index);
        return state_opt != null && state_opt!!;
    }

    get fun can_user_mint(addr: Address): Bool {
        let last_mint_opt: Int? = self.last_mint_time.get(addr);
        if (last_mint_opt == null) { 
            return true; 
        }
        return now() - last_mint_opt!! > self.MINT_COOLDOWN;
    }
}