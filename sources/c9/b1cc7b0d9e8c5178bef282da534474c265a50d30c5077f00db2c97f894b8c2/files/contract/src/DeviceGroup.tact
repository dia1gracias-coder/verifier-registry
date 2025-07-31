contract DeviceGroup {
    publicKey: Int;
    name: String;
    init(
        publicKey: Int,
        name: String,
    ) {
        self.publicKey = publicKey;
        self.name = name;
    }
}
