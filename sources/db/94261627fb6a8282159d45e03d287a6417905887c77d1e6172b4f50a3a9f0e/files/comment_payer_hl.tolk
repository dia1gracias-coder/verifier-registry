tolk 1.4.2

import "@stdlib/gas-payments"
import "@stdlib/tvm-dicts"

/**
 * CommentPayerHL — платёж с комментарием без seqno.
 *
 * Зачем. У seqno-версии жёсткое свойство: сообщение с seqno N+1 отвергается
 * ДО accept, пока в контракте всё ещё N. Подписать вторую отправку, не дождавшись
 * подтверждения первой, физически нельзя. Здесь seqno заменён на защиту от
 * повторов по query_id, как в highload-кошельках: сообщения независимы, порядок
 * не важен, знать текущее состояние контракта, чтобы подписать, НЕ НУЖНО.
 *
 * Это не копия highload-wallet-v3, а самый дешёвый вариант того же приёма:
 * без subwallet_id, без ^message_to_send в теле платежа, без фан-аута через
 * внутреннее сообщение самому себе, и с маской использованных id в uint256
 * вместо 1023-битного слайса — целочисленные операции вместо разрезания
 * и склейки слайсов.
 *
 * -------------------------------------------------------------------------
 * ОДИН КЛЮЧ
 *
 * publicKey подписывает и платежи, и админские операции — вывод баланса
 * и произвольное исходящее сообщение. Решение заказчика: один секрет вместо
 * двух, storage короче на 256 бит, деплой и эксплуатация проще.
 *
 * Цена названа прямо, чтобы её не пришлось узнавать на практике: ключ лежит
 * в окружении сервиса, на машине с сетью. Его компрометация теперь означает
 * потерю ВСЕГО баланса контракта, а не только тех переводов зашитому
 * получателю, что успеют уйти до опустошения.
 *
 * Отсюда правило эксплуатации, которое заменяет собой разделение ключей:
 * на контракте держится оборотный остаток на несколько часов работы,
 * а не весь запас. Пополнение — отдельная операция снаружи сервиса.
 *
 * Вернуть разделение можно только новым деплоем: обновления кода (SETCODE)
 * здесь намеренно НЕТ — изменяемый код обесценил бы любые гарантии,
 * доказанные тестами для текущего.
 * -------------------------------------------------------------------------
 * Формат внешнего сообщения (body):
 *
 *   signature : bits512   — ed25519(payloadCell.hash(), publicKey)
 *   ---------- подписанный payload ----------
 *   isAdmin   : 1 бит     — 0 платёж, 1 админская операция
 *   queryId   : uint32    — старшие 24 бита ключ словаря, младшие 8 номер бита
 *   createdAt : uint32    — unixtime подписания
 *   далее по isAdmin: батч платежей либо админская операция
 *
 * Элемент батча:
 *   hasMore : 1 бит
 *   если hasMore = 1: реф0 = комментарий, реф1 = следующий элемент
 *   если hasMore = 0: комментарий рефом, если реф ровно один, иначе инлайн
 *
 * Инлайн у последнего элемента — не украшение: он убирает лишнюю ячейку
 * из внешнего сообщения и экономит около 25 000 нанотон на одиночной отправке,
 * то есть на основном режиме работы.
 *
 * Один query_id на всю внешку, а не на элемент: защита от повторов работает
 * на уровне сообщения целиком.
 * -------------------------------------------------------------------------
 * ЗАЩИТА ОТ ПОВТОРОВ
 *
 * Использованные query_id помнятся в двух поколениях словаря. Раз в
 * ROTATION_PERIOD текущее поколение становится старым, а старое выбрасывается.
 * Проверка идёт по обоим, поэтому id помнится не меньше ROTATION_PERIOD секунд
 * после использования.
 *
 * Отсюда обязательное соотношение:
 *
 *     MESSAGE_TTL + CLOCK_SKEW <= ROTATION_PERIOD
 *
 * Слева максимальное время жизни сообщения от момента, когда его МОГЛИ принять,
 * справа гарантия памяти. Нарушить соотношение — открыть окно, в котором
 * сообщение ещё валидно, а его id уже забыт: платёж пройдёт дважды. Поэтому
 * ROTATION_PERIOD не задаётся отдельно, а выводится из двух других констант.
 *
 * Проверка «createdAt не из будущего» — часть этого соотношения, а не гигиена:
 * без неё можно подписать сообщение с createdAt на год вперёд, оно будет валидно
 * год, а его id забудется через два поколения.
 * -------------------------------------------------------------------------
 */

/// Подпись не прошла проверку ed25519 против нужного ключа. Нересторимо.
const ERROR_INVALID_SIGNATURE = 35;
/// createdAt вышел из окна валидности. Переподписать с ТЕМ ЖЕ query_id.
const ERROR_EXPIRED = 36;
/// createdAt из будущего дальше CLOCK_SKEW. Нересторимо: врут часы подписанта.
const ERROR_CREATED_IN_FUTURE = 37;
/// query_id уже исполнен. Ровно это защищает от двойной выплаты.
const ERROR_ALREADY_EXECUTED = 38;
/// Комментарий не влезает в отведённый бюджет.
const ERROR_COMMENT_TOO_LONG = 40;
/// Комментарий не линейная цепочка: у ячейки больше одного рефа.
const ERROR_COMMENT_MALFORMED = 41;
/// В батче больше MAX_BATCH элементов.
const ERROR_BATCH_TOO_LARGE = 42;
/// Неизвестный админский op-код.
const ERROR_UNKNOWN_OP = 43;

/// Вывести весь баланс на адрес из сообщения. Только админским ключом.
const OP_WITHDRAW_ALL = 1;
/// Отправить произвольное сообщение с произвольным режимом. Только админским ключом.
const OP_EXECUTE = 2;

const CELL_MAX_BITS = 1023;

/// Потолок ячеек в одном комментарии: корневая плюс продолжения.
const MAX_COMMENT_CELLS = 4;

/// Потолок платежей в одной внешке. Сервис вправе использовать меньше.
const MAX_BATCH = 5;

/// Сколько живёт подписанное сообщение.
const MESSAGE_TTL = 240;

/// Насколько часы подписанта могут убежать вперёд относительно валидатора.
const CLOCK_SKEW = 60;

/// Период ротации поколений. ВЫВОДИТСЯ, а не задаётся: см. соотношение выше.
const ROTATION_PERIOD = MESSAGE_TTL + CLOCK_SKEW;

/// query_id = ключ словаря (24 бита) : номер бита в маске (8 бит).
const QUERY_KEY_BITS = 24;
const QUERY_BIT_BITS = 8;
const QUERY_BITS_PER_ENTRY = 1 << QUERY_BIT_BITS;

/// Режим вывода баланса: всё, что есть, с игнорированием ошибок отправки.
const WITHDRAW_MODE = SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS;

/**
 * Storage:
 *   publicKey   : uint256  — единственный ключ: платежи и админские операции
 *   lastCleaned : uint32   — когда в последний раз крутили поколения
 *   msgPrefix   : ^Cell    — статический заголовок исходящего платежа
 *   queries     : dict     — текущее поколение: ключ 24 бита -> маска uint256
 *   oldQueries  : dict     — предыдущее поколение
 *
 * 288 бит и три рефа из четырёх возможных.
 */
struct Storage {
    publicKey: uint256
    lastCleaned: uint32
    msgPrefix: cell
    queries: dict
    oldQueries: dict
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

/// Проверяет один комментарий: корневой кусок влезает, цепочка линейная и не длиннее лимита.
fun validateComment(comment: slice, maxRootBits: int): void {
    assert (comment.remainingBitsCount() <= maxRootBits) throw ERROR_COMMENT_TOO_LONG;

    var tail = comment;
    var cellsUsed = 1;
    while (!tail.isEndOfRefs()) {
        assert (cellsUsed < MAX_COMMENT_CELLS) throw ERROR_COMMENT_TOO_LONG;
        assert (tail.remainingRefsCount() == 1) throw ERROR_COMMENT_MALFORMED;
        val next = tail.loadRef();
        tail = next.beginParse();
        cellsUsed += 1;
    }
}

/**
 * Единственная точка входа.
 *
 * Как и в seqno-версии, ВСЕ проверки идут до acceptExternalMessage(): падение
 * после accept списало бы газ, откатило состояние и оставило внешку в вечном
 * ретрае. До accept сообщение просто отвергается нодой, бесплатно.
 *
 * Приятное следствие для ретраев: повторная отправка уже исполненного сообщения
 * отвергается кодом 38 БЕЗ транзакции и без газа, сколько бы раз её ни повторили.
 */
fun onExternalMessage(inMsg: slice) {
    val signature: slice = inMsg.loadBits(512);
    val payloadHash: uint256 = inMsg.hash();

    var storage = Storage.load();

    val isAdmin = inMsg.loadBool();
    assert (isSignatureValid(payloadHash, signature, storage.publicKey)) throw ERROR_INVALID_SIGNATURE;

    val queryId = inMsg.loadUint(32);
    val createdAt = inMsg.loadUint(32);
    val nowTime = blockchain.now();

    assert (createdAt > nowTime - MESSAGE_TTL) throw ERROR_EXPIRED;
    assert (createdAt <= nowTime + CLOCK_SKEW) throw ERROR_CREATED_IN_FUTURE;

    // --- ротация поколений -------------------------------------------------
    // Крутим ДО проверки повтора: иначе протухшее поколение считалось бы
    // актуальным, и словарь рос бы без границы.
    if (nowTime > storage.lastCleaned + ROTATION_PERIOD) {
        storage.oldQueries = nowTime > storage.lastCleaned + 2 * ROTATION_PERIOD
            ? createEmptyDict()   // простой длиннее двух окон: оба поколения протухли
            : storage.queries;
        storage.queries = createEmptyDict();
        storage.lastCleaned = nowTime;
    }

    // --- защита от повторов ------------------------------------------------
    val queryKey = queryId >> QUERY_BIT_BITS;
    val queryBit = 1 << (queryId & (QUERY_BITS_PER_ENTRY - 1));

    if (!storage.oldQueries.dictIsEmpty()) {
        val (oldValue, oldFound) = storage.oldQueries.uDictGet(QUERY_KEY_BITS, queryKey);
        if (oldFound) {
            var oldSlice = oldValue!;
            assert ((oldSlice.loadUint(256) & queryBit) == 0) throw ERROR_ALREADY_EXECUTED;
        }
    }

    var mask = 0;
    if (!storage.queries.dictIsEmpty()) {
        val (currentValue, currentFound) = storage.queries.uDictGet(QUERY_KEY_BITS, queryKey);
        if (currentFound) {
            var currentSlice = currentValue!;
            mask = currentSlice.loadUint(256);
            assert ((mask & queryBit) == 0) throw ERROR_ALREADY_EXECUTED;
        }
    }

    if (isAdmin) {
        handleAdmin(mutate storage, mutate inMsg, queryKey, mask | queryBit);
        return;
    }

    // --- платежи -----------------------------------------------------------
    val prefix: slice = storage.msgPrefix.beginParse();
    val maxRootBits = CELL_MAX_BITS - prefix.remainingBitsCount();

    // Проход 1: валидация всех элементов до accept.
    // break в Tolk 1.4.2 ещё не поддержан, выход из цикла через флаг.
    var cursor = inMsg;
    var count = 0;
    var more = true;
    while (more) {
        count += 1;
        assert (count <= MAX_BATCH) throw ERROR_BATCH_TOO_LARGE;

        val hasMore = cursor.loadBool();
        val comment: slice = hasMore
            ? cursor.loadRef().beginParse()
            : (cursor.remainingRefsCount() == 1 ? cursor.loadRef().beginParse() : cursor);
        validateComment(comment, maxRootBits);

        more = hasMore;
        if (hasMore) {
            val nextItem = cursor.loadRef();
            cursor = nextItem.beginParse();
        }
    }

    acceptExternalMessage();

    // Проход 2: отправка. Обхода цепочек комментариев здесь уже нет.
    var sendCursor = inMsg;
    var sendMore = true;
    while (sendMore) {
        val hasMore = sendCursor.loadBool();
        val comment: slice = hasMore
            ? sendCursor.loadRef().beginParse()
            : (sendCursor.remainingRefsCount() == 1 ? sendCursor.loadRef().beginParse() : sendCursor);

        sendRawMessage(
            beginCell()
                .storeSlice(prefix)
                .storeSlice(comment)
                .endCell(),
            SEND_MODE_PAY_FEES_SEPARATELY
        );

        sendMore = hasMore;
        if (hasMore) {
            val nextItem = sendCursor.loadRef();
            sendCursor = nextItem.beginParse();
        }
    }

    storage.queries.uDictSetBuilder(
        QUERY_KEY_BITS,
        queryKey,
        beginCell().storeUint(mask | queryBit, 256)
    );
    storage.save();
}

/**
 * Админские операции. Вызывается после успешной проверки подписи и всех
 * оконных проверок.
 *
 * Обе операции дают полный контроль над балансом. Ключ тот же, что у платежей,
 * поэтому единственное, что отделяет обычную работу сервиса от вывода всего
 * баланса, — это то, что сервис таких сообщений не собирает. Кода, способного
 * построить OP_WITHDRAW_ALL или OP_EXECUTE, в сервисе нет.
 */
fun handleAdmin(mutate storage: Storage, mutate inMsg: slice, queryKey: int, newMask: int): void {
    val op = inMsg.loadUint(32);

    if (op == OP_WITHDRAW_ALL) {
        val dest = inMsg.loadAddress();

        acceptExternalMessage();

        // Здесь createMessage, а не ручная сборка: заголовок собирается один раз
        // и не переиспользуется, экономить на нём нечего, а ручная раскладка
        // int_msg_info — источник трудноуловимых ошибок в редко исполняемом коде.
        //
        // В платёжном пути наоборот: там заголовок заранее лежит в msgPrefix и
        // копируется одним storeSlice, и createMessage сериализовал бы адрес
        // с суммой заново на каждой отправке. Разные задачи — разные средства.
        //
        // bounce = false намеренно: адрес вывода чаще всего ещё не развёрнут,
        // и с bounce = true вывод на него просто отскочил бы назад. Обратная
        // сторона — опечатка в адресе необратима, адрес проверяет человек.
        // Кому нужен bounce, у того есть OP_EXECUTE с полным контролем.
        //
        // Режим 128 отправляет весь баланс, +2 гасит ошибку отправки, чтобы
        // неудача не откатила транзакцию и не оставила внешку в ретрае.
        createMessage({
            bounce: BounceMode.NoBounce,
            value: 0,          // сумму подставит режим 128
            dest: dest,
        }).send(WITHDRAW_MODE);
    } else if (op == OP_EXECUTE) {
        val mode = inMsg.loadUint(8);
        val message = inMsg.loadRef();

        acceptExternalMessage();

        sendRawMessage(message, mode);
    } else {
        assert (false) throw ERROR_UNKNOWN_OP;
    }

    storage.queries.uDictSetBuilder(
        QUERY_KEY_BITS,
        queryKey,
        beginCell().storeUint(newMask, 256)
    );
    storage.save();
}

/// Приём пополнений баланса.
fun onInternalMessage(in: InMessage) {
}

get fun publicKey(): int {
    return Storage.load().publicKey;
}

get fun paymentInfo(): (address, coins) {
    var prefix = Storage.load().msgPrefix.beginParse();
    prefix.skipBits(4 + 2);
    val dest = prefix.loadAddress();
    val value = prefix.loadCoins();
    return (dest, value);
}

get fun commentLimits(): (int, int) {
    val maxRootBits = CELL_MAX_BITS - Storage.load().msgPrefix.beginParse().remainingBitsCount();
    return (maxRootBits, MAX_COMMENT_CELLS);
}

get fun maxBatch(): int {
    return MAX_BATCH;
}

/**
 * Исполнен ли уже этот query_id.
 *
 * Заменяет seqno как способ подтверждения: сервис спрашивает про КОНКРЕТНОЕ
 * сообщение, а не про общее состояние контракта, и ответ не зависит ни от
 * порядка, ни от других отправок.
 *
 * ВАЖНО: ответ достоверен только внутри окна памяти (ROTATION_PERIOD после
 * исполнения). Для давно подтверждённых платежей вернётся false — их надо
 * искать в истории транзакций по хешу тела, а не спрашивать здесь.
 */
get fun processed(queryId: int): bool {
    val storage = Storage.load();
    val queryKey = queryId >> QUERY_BIT_BITS;
    val queryBit = 1 << (queryId & (QUERY_BITS_PER_ENTRY - 1));

    val (currentValue, currentFound) = storage.queries.uDictGet(QUERY_KEY_BITS, queryKey);
    if (currentFound) {
        var s = currentValue!;
        if ((s.loadUint(256) & queryBit) != 0) {
            return true;
        }
    }

    val (oldValue, oldFound) = storage.oldQueries.uDictGet(QUERY_KEY_BITS, queryKey);
    if (oldFound) {
        var s = oldValue!;
        if ((s.loadUint(256) & queryBit) != 0) {
            return true;
        }
    }

    return false;
}

/// Параметры окна: (сколько живёт сообщение, допуск часов, период ротации).
/// Сервис читает их отсюда, а не хардкодит: от MESSAGE_TTL зависит, когда
/// безопасно переподписывать.
get fun windowParams(): (int, int, int) {
    return (MESSAGE_TTL, CLOCK_SKEW, ROTATION_PERIOD);
}

/// Когда в последний раз крутили поколения. Для диагностики.
get fun lastCleaned(): int {
    return Storage.load().lastCleaned;
}
