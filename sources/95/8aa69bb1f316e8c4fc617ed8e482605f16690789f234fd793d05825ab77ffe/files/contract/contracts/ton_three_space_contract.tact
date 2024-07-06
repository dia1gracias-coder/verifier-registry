import "@stdlib/deploy";

// Define the structure for User
struct User {
    address : map<Int, Address>;
    lengthAddress: Int = 0;
    aliase : String;
    followers : map<Int, Address>;
    lengthFollowers : Int = 0;
    image : String;
}

// Function to add a wallet address
extends mutates fun addWalletAddress (self: User, address: Address){
    self.address.set(self.lengthAddress, address);
    self.lengthAddress += 1; // Increment lengthAddress to reflect the addition
}

// Function to create an empty User
fun emptyUser(): User {
    return User{
        address: emptyMap(),
        lengthAddress: 0,
        aliase: "",
        followers: emptyMap(),
        lengthFollowers: 0,
        image: ""
    };
}

// Define the smart contract CheckUser
contract TonThreeSpaceContract with Deployable {
    user : User;

    init() {
        self.user = emptyUser();
    }

    // Function to check if a wallet address is contained in the map
    fun contains(item: Address): Bool {
        // Check if the item exists in the address map
        foreach(key, value in self.user.address){
            if(value == item){
                return true;
            }
        }
        return false;
    }

    // Function to create a user wallet
    get fun createUserWallet(address: Address) {
        self.user.addWalletAddress(address);
    }

    // Function to check if a wallet address is stored
    get fun isWalletStored(address: Address): Bool {
        return self.contains(address);
    }
}
