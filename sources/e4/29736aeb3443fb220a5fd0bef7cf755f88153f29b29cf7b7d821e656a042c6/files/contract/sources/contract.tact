
//contractstaticcopy
import "@stdlib/ownable";
import "@stdlib/deploy";

struct Array {
    winraittable: map<Int as uint8, Int as uint8>; // array of Int values as a map of Ints to Ints,
                                  // with serialization of its keys to uint16 to save space
    length: Int = 0;              // length of the array, defaults to 0
}

fun getwinraitArray(): Array {
    return Array{winraittable: initwinratetableloop(),length: 20}; // length defaults to 0
}

fun initwinratetableloop(): map<Int as uint8, Int as uint8> {
    let i: Int = 0 ;// number
    let y: Int = 6 ;// weight
    let numberscount: Int = 5 ;// weight
    let winraitlength: Int = 0;// length
    let winraittable: map<Int as uint8, Int as uint8> = null;

    repeat(numberscount) {
        repeat(y) {
            winraittable.set(winraitlength, i);
            winraitlength = winraitlength + 1;
        }
        i = i + 1;
        y = y - 1;
    }
    return winraittable;
}

    fun spinWithWinRaitStr(): String  {
        let winraittable :map<Int as uint8, Int as uint8> = initwinratetableloop();
        let i: Int = 0;
        let winraitlenght: Int = 20;
        let numberscount: Int = 5 ;
        let winnumbers: map<Int as uint8, Int as uint8> = null;
        let fizz: StringBuilder = beginString();
        fizz.append("numbers");
        repeat(numberscount) {
            let numberwithrate: Int? = winraittable.get(random(0, winraitlenght));
            winnumbers.set(i, numberwithrate);
            i += 1;
            fizz.append(numberwithrate!!.toString());
        }
        return fizz.toString();
    }

      fun getWinRateTableReadable(): String {
        let fizz: StringBuilder = beginString();
        let table: map<Int as uint8, Int as uint8> = getwinraitArray().winraittable;
        foreach (key, value in  table) { 
            fizz.append(value.toString());
            fizz.append(",");
        }
        return fizz.toString();
    }

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

    init(owner: Address, seqno: Int) {
        self.owner = owner;
        self.seqno = seqno;
    }

    receive(winrait: WinRait) {
        self.spinWithWinRait(winrait); 
        self.reply(WinNumbersReply { winnumbers: self.winnumbers }.toCell());
    }

    get fun getChildRandNumbers(): map<Int as uint8, Int as uint8> {
        return self.winnumbers;
    }

    get fun spinWithWinRait(winrait: WinRait) {
        let i: Int = 0;
        repeat(5) {
            self.winnumbers.set(i, winrait.winraittable.get(random(0, winrait.winraitlenght)));
            i += 1;
        }
    }
}

contract OneArmedBandit with Deployable {
    seqno: Int as uint8 = 0;
    winraitlenght: Int as uint8 = 0;
    childseqno: Int as uint8 = 0;
    winraittable: map<Int as uint8, Int as uint8>;

    init() { }

    get fun getChildSeqno(): Int {
        return self.childseqno;
    }



    fun addNumberWithWeight(number: Int, weight: Int) {
        repeat(weight) {
            self.winraittable.set(self.winraitlenght, number);
            self.winraitlenght += 1;
        }
    }

   get fun initChild() {
        self.sendInitChild();
    }

    receive() {}

    receive(winnumbers: WinNumbersReply) {}

    fun sendInitChild() {
      let childinit : StateInit = initOf Spin(myAddress(), self.childseqno);
        let childAddress: Address = contractAddress(childinit);
        let winRait: WinRait = WinRait { winraittable: self.winraittable, winraitlenght: self.winraitlenght };

        send(SendParameters {
            to: childAddress,
            body: winRait.toCell(),
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            code: childinit.code,
            data: childinit.data
        });
        self.childseqno += 1;
    }
}
