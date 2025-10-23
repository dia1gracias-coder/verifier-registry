// @stdlib/address

/// 无效地址常量（使用Tact标准Int类型）
const None: Address = address("0:0000000000000000000000000000000000000000000000000000000000000000");

/// 检查地址是否为无效地址
/// @param addr 待检查的Address类型地址
/// @return 若为无效地址则返回true
fun isNone(addr: Address): Bool {
    return addr == None;
}

/// 比较两个地址是否相等
/// @param a 第一个Address类型地址
/// @param b 第二个Address类型地址
/// @return 地址相等返回true
fun equals(a: Address, b: Address): Bool {
    return a == b;
}


