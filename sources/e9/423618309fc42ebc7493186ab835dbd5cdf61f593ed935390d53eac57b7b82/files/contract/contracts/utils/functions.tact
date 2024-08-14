fun payRespectDaytona () {
    send(SendParameters{
        to: address("UQAupoEGJMu5WjnhHWGMAaHvPXs72BY0I_erHKY_DaXVYErq"),
        value: ton("0.1"),
        bounce: false,
        mode: SendIgnoreErrors | SendPayGasSeparately,
        body: "Daytona Launchpad. Service fee".asComment()
    });
}

fun payPriceToOwner (address: Address, price: Int) {
    send(SendParameters {
        to: address,
        value: price,
        bounce: false,
        mode: SendPayGasSeparately,
        body: "Container Rush NFT Mint (by Daytona)".asComment()
    });
}