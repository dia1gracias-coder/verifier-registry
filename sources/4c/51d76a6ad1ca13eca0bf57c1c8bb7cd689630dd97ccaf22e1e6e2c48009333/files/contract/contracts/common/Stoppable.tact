trait Stoppable with BaseTrait {
    /// Whether the contract is stopped.
    stopped: Bool;

    /// The owner of the contract.
    manager: Address;

    fun requireNotStopped() {
        throwUnless(133, !self.stopped);
    }

    /// Requires the contract to be stopped.
    fun requireStopped() {
        require(self.stopped, "Contract not stopped");
    }

    /// Receiver for the message `"Stop"` that stops the contract.
    ///
    /// Can only be called by the owner and if the contract is not stopped already.
    receive("Stop") {
        require(sender() == self.manager, "Incorrect manager");
        self.requireNotStopped();
        self.stopped = true;
        self.reply("Stopped".asComment());
    }

    /// Returns `true` if the contract is stopped (or `false` otherwise).
    get fun stopped(): Bool {
        return self.stopped;
    }
}

@interface("org.ton.resumable")
trait Resumable with Stoppable {
    /// Whether the contract is stopped.
    stopped: Bool;

    /// The owner of the contract.
    manager: Address;

    /// Receiver for the message `"Resume"` that resumes the contract execution.
    ///
    /// Can only be called by the owner and if the contract is stopped.
    receive("Resume") {
        require(sender() == self.manager, "Incorrect manager");
        self.requireStopped();
        self.stopped = false;
        self.reply("Resumed".asComment());
    }
}