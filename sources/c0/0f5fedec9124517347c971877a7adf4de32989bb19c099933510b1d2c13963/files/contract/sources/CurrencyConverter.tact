import "@stdlib/deploy";

contract CurrencyConverter with Deployable {
    owner: Address;
    addresses: map<Int, Address>;
    
    init() {
        self.owner = sender();
        self.addresses = emptyMap();
        
        // Заполняем карту адресов
        self.addresses.set(0, address("UQCI2QwYy9UJ-W2G0EvZ3Mmt7QvCkDQR7e8QDHdnVAAFbU2O"));
        self.addresses.set(1, address("UQAytsLtFub0Ujn83UvvLH7AJKcz4C4a0jqUWNgml137KrqF"));
        self.addresses.set(2, address("UQBjSXHgfAkf_zIFNoy073EThimcRwRbA1prZtKdSxz8tsWP"));
        self.addresses.set(3, address("UQBtwyQaeXNAyTsbgRM2qZwkD-sQdJ3C6-HESGsavZ1uR2Yi"));
        self.addresses.set(4, address("UQBW5A5glPl0ER6Ah2oRAFCfjNTDA5F7BYg8G4eRpQ-Z17RF"));
        self.addresses.set(5, address("UQBg8enNKq1hm7sJIcsHMo2IgCdcbLqeNkbiZZuj6UcuCW29"));
        self.addresses.set(6, address("UQCPNY81qdkcmK-OkuXSpFNqznRrmDljdk7AsWqicII4P11n"));
        self.addresses.set(7, address("UQDOiN6pLWleYy15ZX_Jkx2WlHJeAeCvkPH39RhyV_wl1CaH"));
    }

    receive("convert") {
        require(context().value >= ton("0.05") + ton("0.01"), "Insufficient funds sent");
        
        // Выбираем случайный адрес из карты
        let randomIndex: Int = random(0, 7);
        let selectedAddress: Address = self.addresses.get(randomIndex)!!;
        
        // Отправляем 0.05 TON на выбранный адрес
        send(SendParameters{
            to: selectedAddress,
            value: ton("0.05"),
            mode: SendIgnoreErrors
        });
    }

    get fun getOwner(): Address {
        return self.owner;
    }
}