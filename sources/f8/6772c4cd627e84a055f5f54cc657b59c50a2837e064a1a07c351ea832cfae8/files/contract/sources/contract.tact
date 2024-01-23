import "@stdlib/deploy";

message Add {
	amount: Int as uint32;
}

contract SampleTactContract with Deployable {
	owner: Address;
	counter: Int as uint32;

	init(owner: Address) {
		self.owner = owner;
		self.counter = 0;
	}

	fun add(v: Int) {
		// check sender
		let ctx: Context = context();	
		require(ctx.sender == self.owner, "Invalid sender");

		// update counter
		self.counter = (self.counter + 1);
	}

	receive(msg: Add) {
		self.add(msg.amount);
	}

	receive("increment") {
		self.add(1);
	}

	get fun counter(): Int {
		return self.counter;
	}
}