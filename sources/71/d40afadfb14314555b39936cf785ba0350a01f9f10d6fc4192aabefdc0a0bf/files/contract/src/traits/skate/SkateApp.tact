import "./ISkate.tact";

// WARN: DISCUSSION POINT 1 (TBC)
// All app must initiate task and expose an execution endpoint with `only_gateway()` modifier.
// Skate cant't check if the destination method actually implement it.
// Therefore it's the responsibility of RELAYER/AVS to whitelist
// ONLY IMPLEMENTATIONS WITH only_gateway() MODIFIER CAN BE EXECUTED VIA SKATE EXECUTION NETWORK.
trait SkateAppBase {
    skate_gateway: Address;

    // Initiate task to Gateway => task will be registered on Skate Kernel
    inline fun notify_gateway(ctx: Context, initiate_params: SkateInitiateTask) {
        send(SendParameters{
            to: self.skate_gateway,
            value: initiate_params.processing_fee,
            mode: SendPayGasSeparately, // App pay gas, not Skate

            // NOTE: App specific logic to be implemented by contract.
            // App implementation must handle `self.only_gateway()` lock according to their business requirements.
            body: SkateInitiateTaskNotification {
                query_id: initiate_params.query_id,
                user: ctx.sender,
                execution_info: initiate_params.execution_info
            }.toCell()
        });
    }

    inline fun only_gateway() {
        nativeThrowUnless(132, sender() == self.skate_gateway);
    }
}
