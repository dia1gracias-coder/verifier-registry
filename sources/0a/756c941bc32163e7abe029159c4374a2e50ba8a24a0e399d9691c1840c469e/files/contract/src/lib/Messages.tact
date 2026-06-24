// Common
message SendTon {
    dest: Address;
    amount: Int;
}
message SetName {
    name: String;
}

// DeviceGroup
message SendTonToElector {
    device: Address;
    amount: Int;
}
message SendTonToDevice {
    dest: Address;
    amount: Int;
}
message GroupEvent {
    name: String;
    data: String;
}

// Elector
message GetPayment {
    group: Address;
}

// Node
message DeviceRegisterEvent {
    device: Address;
    oldnode: Address?;
}
message DeviceUpdateEvent {
    device: Address;
}
