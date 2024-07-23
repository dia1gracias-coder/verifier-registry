trait ReentrancyGuard {
    const _NOT_ENTERED: Int = 1;
    const _ENTERED: Int = 2;
    reentrancyGuardStatus: Int;

    fun _nonReentrantBefore() {
        require(self.reentrancyGuardStatus != self._ENTERED, "ReentrancyGuard: reentrant call");
        self.reentrancyGuardStatus = self._ENTERED;
    }

    fun _nonReentrantAfter() {
        self.reentrancyGuardStatus = self._NOT_ENTERED;
    }

    fun _reentrancyGuardEntered(): Bool {
        return self.reentrancyGuardStatus == self._ENTERED;
    }
}