import "../includes/messages";

trait NFTRoyaltyStandard {
    royalty_params: RoyaltyParams;
    owner_address: Address;

    //********************************************//
    //                  Messages                  //
    //********************************************//

    receive(msg: GetRoyaltyParams) {
        self.report_royalty_params(msg);
    }

    //********************************************//
    //             Internal functions             //
    //********************************************//

    virtual inline fun report_royalty_params(msg: GetRoyaltyParams) {
        let ctx: Context = context();
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue, 
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator:  self.royalty_params.numerator,
                denominator: self.royalty_params.denominator,
                destination: self.owner_address
            }.toCell()
        });
    }


    //*********************************//
    //             Getters             //
    //*********************************//

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params;
    }
}