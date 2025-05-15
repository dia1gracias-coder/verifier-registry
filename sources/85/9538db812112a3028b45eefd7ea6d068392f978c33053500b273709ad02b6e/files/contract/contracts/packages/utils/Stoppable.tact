
message(0x65ae5ee8) Stop_Time {
    seconds: Int;
    query_id: Int as uint64;
}

message(0x4e6760a3) Stopped {
    query_id: Int as uint64;
}

message(0x7aa9a724) Unstopped {
    query_id: Int as uint64;
}

message(0xb55d2cd9) StopExcesses {
    query_id: Int as uint64;
}


trait Stoppable {

    stop: Bool;

    time_passed: Int;

    receive(msg: Stopped) {
        if(!self._is_stopped()) {
            self._stop();
        }
    }

    receive(msg: Unstopped) {
        if(self._is_stopped()) {
            self._unstop();
        }
    }

    receive(msg: Stop_Time) {
        self._stop_time(msg);
    }

    //*********************************//
    //       Internal functions        //
    //*********************************//

    virtual inline fun _is_stopped(): Bool {
        return self.stop || now() < self.time_passed;
    }

    virtual inline fun _stop_time(msg: Stop_Time) {
        self._canEditStop();
        self.time_passed = now() + msg.seconds;
        self._stop_excesses();
    }

    virtual inline fun _stop() {
        self._canEditStop();
        self.stop = true;
        self._stop_excesses();
    }

    virtual inline fun _unstop() {
        self._canEditStop();
        self.stop = false;
        self._stop_excesses();
    }

    inline fun _stop_excesses() {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: StopExcesses {
                query_id: 0
            }.toCell()
        });
    }

    virtual inline fun _ensureUnstopped() {
        require(!self.stop, "Stoppable: blocked");
        require(now() > self.time_passed, "Stoppable: no time has passed");
    }

    virtual inline fun _ensureStopped() {
        require(self.stop, "Stoppable: not blocked");
        require(now() < self.time_passed, "Stoppable: time passed");
    }

    virtual inline fun _canEditStop() {}

    //*********************************//
    //             Getters             //
    //*********************************//

    get fun is_stop(): Bool {
        return self._is_stopped();
    }

    get fun is_stopped(): Bool {
        return self.stop;
    }

    get fun stop_time(): Int {
        return self.time_passed;
    }
}