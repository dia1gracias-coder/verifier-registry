import "@stdlib/deploy";

message HelloRequest {
}

message HelloResponse {
    message: String;
}

contract HelloWorld with Deployable {
    
    init() {}

    receive(msg: HelloRequest) {
        self.reply(HelloResponse{message: "wefawefwef"}.toCell());
    }
}