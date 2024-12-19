import "@stdlib/deploy";

message SaveResult {
    queryId: Int as uint64;             // 64비트 정수
    sender: Address;                   // 메시지 보낸 사람의 주소
    userAddress: Address;              // 사용자 주소
    startTime: Int as uint64;          // 게임 시작 시간
    endTime: Int as uint64;            // 게임 종료 시간
    cookies: Int as uint32;            // 쿠키 데이터
}

struct Result {
    userAddress: Address;
    startTime: Int as uint64;
    endTime: Int as uint64;
    cookies: Int as uint32;
}

contract GameResult with Deployable {
    owner: Address;                     // 재단 지갑 주소
    id: Int;                  // 컨트랙트 ID
    results: map<Int as uint32, Result>; // 게임 결과 저장
    nextResultId: Int as uint32;        // 다음 저장될 결과 ID

    init(owner: Address, id: Int) {
        self.owner = owner;             // 소유자 주소 설정
        self.id = id;                   // 컨트랙트 ID 초기화
        self.nextResultId = 0;          // 결과 ID 초기화
    }

    receive(msg: SaveResult) {
        require(msg.sender == self.owner, "Unauthorized"); // 재단 지갑만 호출 가능

        let result = Result {
            userAddress: msg.userAddress,
            startTime: msg.startTime,
            endTime: msg.endTime,
            cookies: msg.cookies
        };

        self.results.set(self.nextResultId, result); // 결과 저장
        self.nextResultId += 1;                      // 다음 결과 ID 증가

        self.notify("Game result saved".asComment());
    }

    get fun resultCount(): Int {
        return self.nextResultId; // 저장된 결과 수 반환
    }

    get fun getResult(id: Int): Result? {
        return self.results.get(id); // 특정 결과 반환
    }
}
