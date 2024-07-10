import "@stdlib/ownable";
import "@stdlib/deploy";

message WinRait {
    winraittable: map<Int as uint8, Int as uint8>;
    winraitlenght: Int as uint8;
  }
message WinNumbersReply {
    winnumbers: map<Int as uint8, Int as uint8>;
  }
contract Spin with Deployable, Ownable {
owner: Address;
seqno: Int as uint8;
winnumbers: map<Int as uint8, Int as uint8>;

init(owner: Address, seqno: Int){self.owner = sender();self.seqno = seqno;}

receive(winrait: WinRait)
{self.spinwithwinrait(winrait); 
 self.reply(WinNumbersReply{winnumbers: self.winnumbers}.toCell());}

get fun getchildrandnumbers(): map<Int as uint8, Int as uint8>{return self.winnumbers;}

get fun spinwithwinrait(winrait: WinRait){
        let i: Int  = 0 ;
         repeat(5) {
        self.winnumbers.set(i,  winrait.winraittable.get(random(0, winrait.winraitlenght)));
        i=i+1;
        }}
}

contract OneArmedBandit with Deployable 
{
seqno: Int as uint8 = 0;
winraitlenght: Int as uint8 = 0;
childseqno: Int as uint8 = 0;
winraittable: map<Int as uint8, Int as uint8>;

  init(){
        self.addnumberwithweight(0,6);
        self.addnumberwithweight(1,5);
        self.addnumberwithweight(2,4);
        self.addnumberwithweight(3,2);
        self.addnumberwithweight(4,1);
        self.getwinratetablereadble(self.winraittable);
    }
        get  fun getchildseqno(): Int{
      return self.childseqno;
    }

            get  fun getwinratetablereadble(winraittableq: map<Int as uint8, Int as uint8>): String{
              let fizz: StringBuilder = beginString();
              foreach (key, value in winraittableq) { 
                fizz.append(value.toString());
                fizz.append(",");
              }
              return fizz.toString();
              }

     fun addnumberwithweight(number: Int, weight: Int) {
        repeat (weight) {
            self.winraittable.set(self.winraitlenght, number);
            self.winraitlenght = self.winraitlenght + 1;
        }
    }

    fun initchild(){ self.sendinitchild(); self.childseqno = self.childseqno + 1;}

  receive("spin"){}
  
  receive(winnumbers: WinNumbersReply){}

  fun sendinitchild(){
    send(SendParameters{
        to: contractAddress(initOf Spin(myAddress(), self.childseqno)),
        body: WinRait{winraittable: self.winraittable, winraitlenght: self.winraitlenght}.toCell(),
        value: ton("0.1"), // pay for message and potential deployment
        mode: SendIgnoreErrors,
        code: initOf Spin(myAddress(), self.childseqno).code, // if child is not deployed, also deploy it
        data: initOf Spin(myAddress(), self.childseqno).data
      }
    );
    self.childseqno = self.childseqno + 1;
  }
}