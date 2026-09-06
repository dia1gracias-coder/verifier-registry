import "errors"

/// Состояние расписания окон вывода (DESIGN §2.3): окно открыто,
/// когда (now − epoch_start) mod period < window_length.
struct WindowState {
    isOpen: bool
    index: uint32        // номер окна (0 — открывается в epoch_start): текущего, если открыто, иначе ближайшего
    openedAt: uint32     // начало этого окна
    closesAt: uint32     // конец этого окна
    nextWindowAt: uint32 // когда откроется следующее окно: openedAt, если сейчас закрыто, иначе следующее
}

fun calcWindowState(period: int, windowLength: int, epochStart: int, now: int): WindowState {
    assert (period > 0 && windowLength > 0 && windowLength < period) throw Errors.BadConfig;
    if (now < epochStart) {
        return {
            isOpen: false,
            index: 0,
            openedAt: epochStart,
            closesAt: epochStart + windowLength,
            nextWindowAt: epochStart,
        };
    }
    val elapsed = now - epochStart;
    val k = elapsed / period;
    val start = now - elapsed % period; // начало окна k
    if (now - start < windowLength) {
        return {
            isOpen: true,
            index: k,
            openedAt: start,
            closesAt: start + windowLength,
            nextWindowAt: start + period,
        };
    }
    return {
        isOpen: false,
        index: k + 1,
        openedAt: start + period,
        closesAt: start + period + windowLength,
        nextWindowAt: start + period,
    };
}
