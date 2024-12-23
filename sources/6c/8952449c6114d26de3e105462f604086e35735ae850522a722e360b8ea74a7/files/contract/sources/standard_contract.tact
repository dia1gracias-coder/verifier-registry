import "./message.tact";

contract ZkmeVerifyLite {



    owner_address: Address;

    approve_lite_map: map<Int,Int>;
    threshold_map: map<Int,ThresholdValue>;


    init(owner_address: Address,  cooperator:Address){
        self.owner_address = owner_address;
    }

    receive(msg:ApproveLite){
        let ctx: Context = context(); // get sender Info
        let msgValue: Int = ctx.value;

        let b: StringBuilder = beginString();
        b.append(msg.cooperator.toString());
        b.append(ctx.sender.toString());
        self.approve_lite_map.set(b.toSlice().hash(),b.toSlice().hash());
        let threshold:ThresholdValue = ThresholdValue{
            thresholdKey: msg.cooperatorThresholdKey,
        };
        self.threshold_map.set(b.toSlice().hash(), threshold);


        emit(AprroveLiteRecord { cooperator: msg.cooperator ,user: ctx.sender  }.toCell());
    }

    get fun get_has_approved(cooperator: Address, user: Address):Bool{
        let b: StringBuilder = beginString();
        b.append(cooperator.toString());
        b.append(user.toString());
        if(self.approve_lite_map.get(b.toSlice().hash()) == null){
            return false;
        }
        return true;
    }

    get fun get_user_data(cooperator: Address,user: Address):String?{
        let b: StringBuilder = beginString();
        b.append(cooperator.toString());
        b.append(user.toString());
        if(self.threshold_map.get(b.toSlice().hash()) == null){
            return null;
        }
        let value:ThresholdValue =  self.threshold_map.get(b.toSlice().hash())!!;
        return value.thresholdKey;
    }
}
