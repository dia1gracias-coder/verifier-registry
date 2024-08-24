trait Initializable {
    is_initialized: Bool;

    fun requireInitialized() {
        require(self.is_initialized, "This contract is not initialized yet");
    }

    fun initialize() {
        require(!self.is_initialized, "This contract is initialized already");
        self.is_initialized = true;
    }
}
