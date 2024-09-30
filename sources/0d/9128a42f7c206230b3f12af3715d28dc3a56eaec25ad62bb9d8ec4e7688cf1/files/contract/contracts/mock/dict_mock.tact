import "@stdlib/deploy";

message(0x7362d09c) FizzAsCell{
    dict: map<Int,Int>;
}

contract DictMock with Deployable {

    // Empty map
    fizz: map<Int, Int> = emptyMap();
 
    init(){
        // Setting a couple of values under different keys
        self.fizz.set(42, 321);
        self.fizz.set(7, 123);       
    }


    get fun getLastValue(): Int{
        let val =  self.fizz.get(7);
        if(val != null){
            return val!!;
        }else{
            return 0;
        }
    }

    // Getter function for obtaining the value of self.record
    get fun getFizz(): map<Int, Int> {
        return self.fizz;
    }


    receive("hola") {
        // Here we're converting the map to a Cell and making a reply with it
        self.reply(self.fizz.asCell());
    }

    receive(msg: FizzAsCell){
        self.fizz.set(42,323);
    }

}

// Alternatively, we can check for the key in the if statement
// if (gotButUnsure != null) {
//     // Hooray, let's use !! without fear now and cast Int? to Int
//     let definitelyGotIt: Int = fizz.get(68)!!;
// } else {
//     // Do something else...
// }

