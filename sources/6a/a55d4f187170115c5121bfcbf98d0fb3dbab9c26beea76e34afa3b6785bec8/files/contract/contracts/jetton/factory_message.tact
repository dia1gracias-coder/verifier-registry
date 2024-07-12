struct TokenContent {
    symbol: String;
    uri: String?;
}

message Create {
    query_id: Int as uint64;
    response_destination: Address;
    forward_payload: Slice;
    content: TokenContent;
}

message SetCurveRouter {
    curve_router: Address;
}