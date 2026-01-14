import "@stdlib/deploy";

message HelloRequest {
}

message HelloResponse {
    message: String;
}

contract FirstContract with Deployable {
    
    init() {}

    receive(msg: HelloRequest) {
        self.reply(HelloResponse{message: "bxvzxcvzxvzxcvzxv"}.toCell());
    }
}