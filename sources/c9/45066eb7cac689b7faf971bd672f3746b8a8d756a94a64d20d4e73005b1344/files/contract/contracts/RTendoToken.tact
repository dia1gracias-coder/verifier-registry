import "@stdlib/deploy";
import "./imports/token/jetton/JettonMaster.tact";
import "./imports/token/jetton/JettonWallet.tact";
import "./imports/utils/AccessControl.tact";

contract RTendoTokenWallet with JettonWallet {
	balance: Int as coins = 0;
	owner: Address;
	jetton_master: Address;
	init(owner: Address, jetton_master: Address){
		self.owner = owner;
		self.jetton_master = jetton_master;
	}

	override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
		return initOf RTendoTokenWallet(owner_address, self.jetton_master);
	}
}
message Mint {
	to: Address;
	amount: Int as coins;
}
message ClaimRTendoFromIGP {
	signature: Cell;
	amount: Int;
}

contract RTendoTokenMaster with Deployable, JettonMaster, AccessControl {
	// =========================
	//  Access Control
	// =========================
	const MINTER_ROLE: Int = sha256("MINTER_ROLE");
	roles: map<Int, Role>;
	// =========================
	//  Token info
	// =========================
	total_supply: Int as coins = 0;
	mintable: Bool = true;
	owner: Address;
	jetton_content: Cell;
	// =========================
	//  ClaimRTendo Info
	// =========================
	public_key: Int;
	// =========================
	//  Init
	// =========================
	init(owner: Address, jetton_content: Cell, public_key: Int){
		self.owner = owner;
		self.jetton_content = jetton_content;
		self.public_key = public_key;
		// grant DEFAULT_ADMIN_ROLE role to owner
		self.initDefaultAdminRole(owner);
	}

	receive(mintParams: Mint){
		let ctx: Context = context();
		let msg: JettonMint = JettonMint{
			origin: ctx.sender,
			receiver: mintParams.to,
			amount: mintParams.amount,
			custom_payload: emptyCell(),
			forward_ton_amount: 0,
			forward_payload: emptySlice()
		};
		self._mint_validate(ctx, msg);
		self._mint(ctx, msg);
	}

	receive(msg: ClaimRTendoFromIGP){
		let ctx: Context = context();
		// validation
		require(self.verifySignature(msg.signature, ctx.sender, msg.amount), "RTendoTokenMaster: Invalid signature");
		// mint token
		let msgMint: JettonMint = JettonMint{
			origin: ctx.sender,
			receiver: ctx.sender,
			amount: msg.amount,
			custom_payload: emptyCell(),
			forward_ton_amount: 0,
			forward_payload: emptySlice()
		};
		self._mint(context(), msgMint);
	}

	get fun verifySignature(signature: Cell, callerAddress: Address, amount: Int): Bool {
		let hash: Int = beginCell().storeAddress(callerAddress).storeCoins(amount).endCell().hash();
		return checkSignature(hash, signature.asSlice(), self.public_key);
	}

	override inline fun _mint_validate(ctx: Context, msg: JettonMint) {
		require(self.hasRole(self.MINTER_ROLE, ctx.sender), "JettonMaster: Caller is not authorized to mint Jetton");
		require(self.mintable, "JettonMaster: Jetton is not mintable");
	}

	override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
		return initOf RTendoTokenWallet(owner_address, myAddress());
	}

	get fun ton_balance(): Int {
		return myBalance();
	}

	get fun minter_role(): Int {
		return self.MINTER_ROLE;
	}
}