
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


contract Spin with Deployable, Ownable {
    owner: Address;
    seqno: Int as uint8;
    winnumbers: map<Int as uint8, Int as uint8>;

    init(owner: Address, seqno: Int) {
        self.owner = owner;
        self.seqno = seqno;
    }

    receive("Spin!") {
        self.reply(spinWithWinRaitStr().asComment());
    }
}

contract OneArmedBandit with Deployable {
    seqno: Int as uint8 = 0;
    childseqno: Int as uint8 = 0;

    init() { }

    receive() {}


    receive("Spin!") {
        self.sendInitChild();
    }
    fun sendInitChild() {
      let childinit : StateInit = initOf Spin(myAddress(), self.childseqno);
        let childAddress: Address = contractAddress(childinit);

        send(SendParameters {
            to: childAddress,
            body:  "Spin!".asComment(),
            value: ton("0.1"),
            mode:  SendRemainingValue | SendIgnoreErrors,
            code: childinit.code,
            data: childinit.data
        });
        self.childseqno += 1;
    }
}
