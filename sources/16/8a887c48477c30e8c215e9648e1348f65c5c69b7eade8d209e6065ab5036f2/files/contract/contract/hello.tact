import "@stdlib/deploy";

struct Room {
    gameType: Int as uint8;
}

contract TestContract with Deployable {
    m_rooms: map<Int, Room>;

    init() {
        self.m_rooms = emptyMap();
        self.m_rooms.set(1, Room{ gameType: 1 });
    }

    get fun getRoomInfo(roomId: Int): Room {
        let roomOpt: Room? = self.m_rooms.get(roomId);
        require(roomOpt != null, "Room not found");
        return roomOpt!!;
    }
}
