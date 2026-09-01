struct RegistryData {
    owner: Address;
    url: String;
    revision: Int;
    updatedAt: Int;
}

/// A deterministic, owner-controlled pointer to the current URL.
/// The contract address depends only on this code and `owner`.
contract LinkRegistry {
    owner: Address;
    url: String;
    revision: Int as uint32;
    updatedAt: Int as uint32;

    init(owner: Address) {
        self.owner = owner;
        self.url = "";
        self.revision = 0;
        self.updatedAt = 0;
    }

    // A String receiver accepts the standard TON plaintext-comment format:
    // 32 zero bits followed by UTF-8 text. Explorers display such payloads.
    receive(newUrl: String) {
        require(sender() == self.owner, "only owner can update");
        let s: Slice = newUrl.asSlice();
        require(s.bits() > 0, "URL cannot be empty");

        self.url = newUrl;
        self.revision += 1;
        self.updatedAt = now();
    }

    get fun getRegistryData(): RegistryData {
        return RegistryData {
            owner: self.owner,
            url: self.url,
            revision: self.revision,
            updatedAt: self.updatedAt,
        };
    }

    /// Simple getters are convenient for explorers and RPC clients.
    get fun get_links(): String {
        return self.url;
    }

    get fun getLinks(): String {
        return self.url;
    }

    get fun getCurrentLink(): String {
        return self.url;
    }

    get fun getOwner(): Address {
        return self.owner;
    }

    get fun getRevision(): Int {
        return self.revision;
    }

    get fun getUpdatedAt(): Int {
        return self.updatedAt;
    }
}
