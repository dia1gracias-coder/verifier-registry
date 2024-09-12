import "@stdlib/deploy";

contract Text with Deployable {
    init() {
        
    }

    fun greet(){
        let ctx: Context = context();
         send(SendParameters{to:sender(),
                                bounce: true,
                                value: ctx.value,
                                mode: 0,
                                body: "Hello,Ton".asComment()});  
                                                }
    
}
