import "@stdlib/gas-payments"
import "errors"
import "w5-types"
import "storage"
import "messages"

contract SimpleExtension {
    author: "Acton User"
    version: "3.0.0"
    description: "Wallet V5 extension: signed, daily-limited, direct payments"
    storage: ExtensionStorage
    incomingMessages: AllowedInternalMessages
    incomingExternal: AllowedExternalMessages
}

type AllowedInternalMessages =
    | TopUp
    | CancelSubscription
    | UpdateSpendLimit
    | WithdrawToAdmin
    | SetPaused
    | RotateSigningKey
    | ConfirmSigningKey

type AllowedExternalMessages =
    | CollectPaymentFromWallet
    | WithdrawExtensionBalance

// АУДИТ #25: 0.5 TON было унаследовано от стандарта плагинов v4 и завышено
// на два порядка — контракту на газ нужно ~0.005. При старом пороге на 1 TON
// хватало всего ~8 платежей, дальше тихий отказ.
const MIN_PLUGIN_AMOUNT = ton("0.05")
// Сколько расширение платит СВОИМИ деньгами за уведомление кошельку.
const NOTIFY_WALLET_VALUE = ton("0.02")
// A6: без минимума можно было гонять неограниченное число платежей по
// 1 нанотону — экономически бессмысленно для атакующего (расширение теряет
// на уведомлении ~0.02 за раз, кошелёк на комиссии на два порядка меньше),
// но само по себе "дневной лимит" должен ограничивать что-то осмысленное,
// а не пропускать пыль. Заодно на этом фоне неучтённая форвард-комиссия
// (SEND_MODE_PAY_FEES_SEPARATELY — кошелёк платит её СВЕРХ amount, поэтому
// spentInWindow всегда немного занижен) становится статистически незначимой.
// A-9: константа перенесена в storage.tolk — она нужна и контракту, и
// функции availableAt(). Держать её в двух местах = ровно тот класс ошибки,
// который уже стрелял дважды (#18, вывод средств).
// НАЙДЕНО ТЕСТОМ: вывод средств оставлял MIN_PLUGIN_AMOUNT (0.05), а для
// работы нужно 0.07 — контракт после вывода переставал мочь платить. Это тот
// же класс ошибки, что #18. Один порог на все места убирает его целиком.
const OPERATIONAL_FLOOR = MIN_PLUGIN_AMOUNT + NOTIFY_WALLET_VALUE
const TOMBSTONE_RESERVE = ton("0.25")
// НАЙДЕНО ТЕСТОМ: резервировать при выводе РОВНО рабочий порог мало — газ
// списывается сверх, и по факту остаётся чуть меньше, контракт выходит из
// строя сразу после вывода. Резерв с запасом примерно на пару платежей.
// A2, ИСПРАВЛЕНИЕ ЗАПЕРТЫХ СРЕДСТВ. Раньше было OPERATIONAL_FLOOR + 0.05 =
// 0.12, а TOMBSTONE_RESERVE я поднял до 0.25 и соседнюю константу не
// пересмотрел. Порядок ИНВЕРТИРОВАЛСЯ: вывод на живом расширении оставлял
// 0.12, потом отмена, потом попытка забрать остаток требовала > 0.25 — отказ
// с сообщением "недостаточно баланса, чтобы забрать баланс", и 0.12 TON
// заперты навсегда (пополнять ради них дороже, чем они стоят).
//
// Держим порядок ЯВНО, а не надеемся, что следующая правка его заметит —
// на этом классе ошибки в проекте горели уже трижды.
// A-44: прежняя версия выводила WITHDRAW_RESERVE только из TOMBSTONE_RESERVE.
// Порядок держался, но по причине, к смыслу константы отношения не имеющей:
// WITHDRAW_RESERVE — про "не обездвижить работающее расширение"
// (операционная величина), TOMBSTONE_RESERVE — про аренду. Понизь второй
// ниже 0.02 (а его И НАДО понижать, он не измерен) — и первый ушёл бы ниже
// OPERATIONAL_FLOOR, то есть молча вернулся бы #18.
// Теперь оба ограничения выражены явно.
// max() в объявлении константы использовать нельзя — она вычисляется на
// этапе компиляции. Поэтому задаём число явно, а ИНВАРИАНТ закрепляем
// проверкой в платёжном пути (ниже) и тестом: если кто-то понизит
// TOMBSTONE_RESERVE, порядок сломается ГРОМКО, а не молча вернёт #18.
const WITHDRAW_RESERVE = ton("0.30")
// По разделу "Gas limitation" официального руководства: внутренние операции
// должны проверять, что присланного value хватит на обработку. Значение
// подобрано с запасом; по-хорошему его надо измерить тестами и уточнить.
const MIN_INTERNAL_VALUE = ton("0.02")
// АУДИТ #4: раньше validUntil не был ограничен сверху — бот ставил год 2096,
// то есть подписанное сообщение жило вечно. Теперь контракт сам отказывается
// принимать запросы со сроком годности дальше 10 минут от текущего момента.
const MAX_VALIDITY_WINDOW = 600

// ГЛАВНАЯ НАХОДКА СЕГОДНЯ: раньше ЛЮБОЙ, кто узнал бы адрес этого контракта,
// мог сам отправить CollectPaymentFromWallet со своим адресом как destination
// и вывести деньги в рамках лимита себе — проверки, КТО отправил запрос,
// не было вообще. Теперь используем ту же схему, что и настоящий WalletV5:
// подпись приватным ключом + защита от повторной отправки (seqno) + срок
// годности запроса (validUntil). Без подписи запрос отклоняется полностью.
const SIZE_SIGNATURE = 512
const ROTATION_TTL = 3600

fun onExternalMessage(inMsg: slice) {
    // РЕФАКТОРИНГ, ШАГ 1. Раньше тело и подпись лежали в ОДНОЙ ячейке: тело,
    // а следом дописанные 512 бит подписи. Вместе они упирались в предел
    // ячейки в 1023 бита, и из-за этого:
    //   - потолок суммы одного платежа был ~1099 TON;
    //   - не влезал ни memo для площадки, ни идентификатор сети.
    // Теперь тело лежит в отдельной ref-ячейке — у него свои полные 1023
    // бита, а подпись занимает место во внешней. Формат внешнего сообщения:
    //   [512 бит подписи][ref на ячейку с телом]
    val signature = inMsg.loadBits(SIZE_SIGNATURE);
    val bodyCell = inMsg.loadRef();

    // A12: пробовал добавить проверку "тело разобрано полностью, мусора не
    // осталось" — сломала ВСЕ настоящие сообщения (fromSlice не меняет
    // исходную переменную, она продолжает указывать на полные данные).
    // Откатил: цена такой гигиены оказалась неприемлемой без более точного
    // способа проверить остаток, а не выдуманного на скорую руку.
    val msg = lazy AllowedExternalMessages.fromSlice(
        bodyCell.beginParse(),
        { throwIfOpcodeDoesNotMatch: Errors.UnsupportedExternalMessage },
    );

    var storage = lazy ExtensionStorage.load();

    // Подписывается хэш ячейки с телом. crypto.sign(privateKey, cell) на
    // стороне отправителя делает ровно это же — хэширует ячейку и подписывает.
    // ConfirmSigningKey — единственное сообщение, которое подписывается НЕ
    // текущим ключом, а заявленным новым: в этом и смысл подтверждения.
    // Доказывается, что приватная часть нового ключа реально существует.
    // A3: терминальный флаг — раньше выключение держалось на обнулении
    // ключа, что опиралось на непроверенное свойство ed25519.
    val rotationNow = lazy storage.rotation.load();
    assert (!rotationNow.cancelled) throw Errors.ExtensionCancelled;

    // R1/R3: выбора ключа по опкоду больше нет — подтверждение ушло во
    // внутренние сообщения. Внешние ВСЕГДА проверяются текущим ключом, без
    // исключений. Заодно исчез класс риска: прежняя схема подставляла
    // pendingPublicKey и держалась на том, что проверка "заявка существует"
    // стоит раньше по коду.
    assert (
        isSignatureValid(bodyCell.hash(), signature, storage.publicKey as int)
    ) throw Errors.InvalidSignature;

    // R4 БЫЛ ЗДЕСЬ И УБРАН — по результатам замера, не по недосмотру.
    //
    // Когда блок-лист довели до полного (19 значений вместо 3), эта проверка
    // уронила 35 тестов с "Out of gas". Причина: у внешних сообщений есть
    // лимит БЕСПЛАТНОГО газа до acceptExternalMessage(), и всё, что стоит до
    // него, обязано в него уложиться. Девятнадцать сравнений 256-битных
    // чисел НА КАЖДОМ ПЛАТЕЖЕ в кредит не влезают.
    //
    // Почему убрать безопасно: ключ малого порядка проверяется в ДВУХ
    // местах, где лимита кредита нет —
    //   1) install-extension.tolk, до установки (офчейн-проверка);
    //   2) ветка RotateSigningKey, внутреннее сообщение от админа.
    // Оба пути — единственные, которыми ключ вообще может появиться в
    // хранилище. Проверка на платеже была ТРЕТЬЕЙ страховкой на тот же
    // случай и стоила газа на каждой покупке.
    //
    // Настоящий компромисс: если кто-то развернёт расширение с таким ключом
    // и установит его В ОБХОД нашего скрипта, контракт не откажет. Но такой
    // человек и так поставил себе расширение с ключом, подпись под который
    // подделывается кем угодно — то есть навредил себе сам, а не был атакован.

    // АУДИТ #3: подписываемое тело раньше НИЧЕМ не было привязано к конкретному
    // экземпляру расширения. Если один и тот же ключ подписи окажется у двух
    // развёрнутых контрактов — сообщение для одного прошло бы и на другом
    // (у каждого свой seqno, оба начинают с нуля). У настоящего WalletV5 от
    // этого защищает walletId в подписываемых данных. Здесь берём младшие
    // 32 бита хэша собственного адреса — уникально для каждого развёртывания
    // и не стоит ни бита в хранилище.
    // Мелочь из аудита: contract.getAddress() вызывался трижды за платёж.
    val myAddress = contract.getAddress();
    val (myWorkchain, myAddrHash) = myAddress.getWorkchainAndHash();
    // ШАГ 2: полный хэш вместо младших 32 бит — подобрать офчейн нельзя.
    val expectedDomainTag = myAddrHash;

    match (msg) {
        CollectPaymentFromWallet => {
            assert (msg.domainTag == expectedDomainTag) throw Errors.WrongDomainTag;
            assert (msg.seqno == storage.seqno) throw Errors.InvalidSeqno;
            assert (msg.validUntil > blockchain.now()) throw Errors.Expired;
            assert (
                msg.validUntil <= blockchain.now() + MAX_VALIDITY_WINDOW
            ) throw Errors.ValidityWindowTooLong;
            // АУДИТ #5: нулевая сумма тратила seqno и газ впустую.
            assert (msg.amount > 0) throw Errors.ZeroAmount;
            assert (msg.amount >= MIN_PAYMENT_AMOUNT) throw Errors.AmountTooSmall;
            // ШАГ 2: потолок в ~1099 TON СНЯТ. Он существовал потому, что
            // тело и подпись делили одну ячейку. Теперь тело в своей ячейке:
            // opcode 32 + queryId 64 + destination 267 + seqno 32 +
            // validUntil 32 + domainTag 256 + bounceable 1 = 684, плюс сумма
            // (максимум 124 бита) = 808 из 1023. Любая реально существующая
            // сумма TON помещается с запасом, отдельная проверка не нужна.
            // АУДИТ #8: при windowSeconds == 0 условие "окно истекло" всегда
            // истинно, spentInWindow сбрасывается на КАЖДОМ запросе, и дневной
            // лимит перестаёт существовать — при этом внешне всё выглядит
            // нормально. Проверка здесь, а не только при разворачивании,
            // потому что она должна держать даже если контракт уже развёрнут
            // с битым значением.
            // A-44: инвариант резервов. Константы нельзя связать выражением
            // на этапе компиляции, поэтому проверяем здесь — стоит копейки
            // газа и ловит любую будущую правку, которая сломает порядок.
            assert (
                WITHDRAW_RESERVE >= TOMBSTONE_RESERVE
                && TOMBSTONE_RESERVE >= OPERATIONAL_FLOOR
            ) throw Errors.InvalidLimitParams;

            var policy = lazy storage.policy.load();
            // A-6: полная проверка инвариантов вместо одиночной. Начальное
            // хранилище задаёт разворачивающий, контракт его не валидировал.
            policy.assertConsistent();
            // АУДИТ #13: получатель не был ограничен по воркчейну. В мастерчейне
            // комиссии примерно в 1000 раз выше, и если кошелёк платит их СВЕРХ
            // суммы сообщения (а каким режимом он шлёт — отдельный неясный
            // вопрос, см. SECURITY.md), реальная трата окажется больше того
            // amount, который мы записали в spentInWindow — лимит недосчитает.
            // Все наши площадки в обычном воркчейне, поэтому просто запрещаем
            // чужой вместо того, чтобы разбираться с режимами комиссий.
            val (destWorkchain, destHash) = msg.destination.getWorkchainAndHash();
            assert (destWorkchain == myWorkchain) throw Errors.DestinationWrongWorkchain;

            // A1, КРИТИЧНО. Раньше держатель ключа подписи мог указать
            // destination = адрес САМОГО расширения и положить в payload
            // сообщение UpdateSpendLimit. Кошелёк послушно его отправлял, и
            // расширение получало внутреннее сообщение, у которого отправитель
            // — кошелёк. А в продакшн-топологии admin == кошелёк, поэтому
            // проверка "только админ" проходила: бот поднимал сам себе лимит
            // до любого значения и выносил весь баланс двумя сообщениями.
            // Обесценивало разом dailyLimit, maxSinglePayment, скользящее окно
            // и всё разделение ролей.
            // A-22: сравниваем ХЭШ, а не сериализованный адрес. Прежняя версия
            // держалась на допущении, что тот же аккаунт нельзя закодировать
            // иначе (anycast, addr_var). Допущение скорее всего верное, но
            // стоило ноль, чтобы его убрать: хэш уже посчитан строкой выше.
            assert (destHash != myAddrHash) throw Errors.SelfPaymentForbidden;
            // Пауза останавливает платежи, но НЕ админские операции и не смену
            // ключа — иначе она мешала бы устранять саму причину остановки.
            assert (!rotationNow.paused) throw Errors.ExtensionPaused;

            // Защита в глубину: memo обязан быть либо пустым, либо обычным
            // текстовым комментарием (32 нулевых бита в начале). Так дыра не
            // откроется заново, если завтра появится ещё один контракт,
            // доверяющий этому кошельку.
            var memoSlice = msg.payload.beginParse();
            // A5: сбой сборки сообщения происходил бы уже ПОСЛЕ коммита —
            // seqno и лимит сгорели бы, а платежа не было. Проверяем ДО.
            assert (memoSlice.remainingRefsCount() == 0) throw Errors.PayloadTooComplex;
            assert (memoSlice.remainingBitsCount() <= 700) throw Errors.PayloadTooComplex;
            assert (
                memoSlice.isEmpty() || memoSlice.preloadUint(32) == 0
            ) throw Errors.PayloadNotAComment;
            // АУДИТ #2: проверки собственного баланса не было вообще. Если бы
            // не хватило на NOTIFY_WALLET_VALUE — падала бы фаза отправки, и в
            // связке с отсутствующим commit (АУДИТ #1) это окирпичивало контракт.
            assert (
                contract.getOriginalBalance() >= OPERATIONAL_FLOOR
            ) throw Errors.NotEnoughExtensionBalance;

            // ШАГ 3б (#33): потолок на один платёж — ограничивает ущерб от
            // утечки ключа одной транзакцией.
            assert (msg.amount <= policy.maxSinglePayment)
                throw Errors.SinglePaymentTooLarge;

            // СКОЛЬЗЯЩЕЕ окно (#22) — классический sliding window counter.
            //
            // ЧЕСТНО О ЕГО ГРАНИЦАХ (найдено аудитом A-4, раньше здесь было
            // написано, что двойная трата предотвращена — это неверно):
            // алгоритм убирает МГНОВЕННЫЙ всплеск (2х лимита за две секунды
            // на границе), но НЕ убирает сам факт 2х за скользящее окно.
            // Худший случай: потратить лимит в последнюю секунду окна, затем
            // ещё раз в последнюю секунду следующего — вес прошлой траты к
            // этому моменту почти нулевой, и оба платежа проходят. Итого
            // ~2х dailyLimit за ровно W секунд.
            //
            // Практический вывод: выставляй dailyLimit ВДВОЕ НИЖЕ той суммы,
            // которую реально готов потерять за сутки в худшем случае.
            // Полное устранение требует перехода на N подокон (корзин) —
            // худший случай упал бы до (1 + 1/N) от лимита.
            // A-4: сдвигаем корзины ко времени и считаем сумму всех четырёх.
            // Прежняя схема (текущее + предыдущее окно с убывающим весом)
            // допускала 2х лимита за окно по построению — см. SECURITY.md.
            val nowTs = blockchain.now();
            policy.rollTo(nowTs);
            val used = policy.b0 + policy.b1 + policy.b2 + policy.b3 + policy.b4;

            assert (used + msg.amount <= policy.dailyLimit)
                throw Errors.SpendLimitExceeded;

            acceptExternalMessage();

            // Увеличиваем seqno СРАЗУ — то же самое сообщение больше нельзя
            // отправить второй раз (защита от replay-атаки).
            storage.seqno += 1;
            policy.b0 += msg.amount;
            storage.policy = policy.toCell();
            storage.save();

            // АУДИТ #1, КРИТИЧНО: без этого вызова падение фазы отправки
            // откатывало ВСЁ хранилище, включая увеличенный seqno — и то же
            // самое подписанное сообщение снова становилось валидным. Так как
            // за внешние сообщения платит сам контракт, любой мог рассылать
            // перехваченное сообщение по кругу и слить баланс до нуля, после
            // чего контракт мёртв. Ровно так же делает настоящий WalletV5.
            commitContractDataAndActions();

            val w5PayMsg = createMessage({
                // ШАГ 2 (#11): комментарий к платежу для площадки. Пустая
                // ячейка = без комментария, как было раньше.
                body: msg.payload.beginParse(),
                // АУДИТ #23: было жёстко false — деньги терялись при неверном
                // адресе. Теперь решает отправитель, по умолчанию бот ставит
                // true. Учти: возврат вернёт деньги в кошелёк, но spentInWindow
                // НЕ откатится (это #1) — лимит всё равно сгорит.
                bounce: msg.bounceable,
                dest: msg.destination,
                value: msg.amount,
            });
            val outActions = createSingleWalletSendAction(w5PayMsg.messageCell);

            val collectPaymentMsg = createMessage({
                body: W5ExtensionActionRequest {
                    queryId: msg.queryId,
                    outActions,
                    hasExtraActions: false,
                    extraActions: createEmptySlice(),
                },
                bounce: false,
                dest: storage.walletAddress,
                value: NOTIFY_WALLET_VALUE,
            });
            collectPaymentMsg.send(SEND_MODE_REGULAR);

            // ИДИОМА "Emit events and logs": след наружу для индексаторов.
            // Внешние сообщения дешевле внутренних по газу.
            val eventMsg = createExternalLogMessage({
                dest: createAddressNone(),
                body: PaymentRequestedEvent {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    destination: msg.destination,
                    spentInWindowAfter: policy.b0 + policy.b1 + policy.b2 + policy.b3 + policy.b4,
                },
            });
            eventMsg.send(SEND_MODE_REGULAR);
        }
        WithdrawExtensionBalance => {
            // A-24: без этого скомпрометированный бот, только что
            // поставленный на паузу, мог осушить рабочий баланс расширения и
            // вывести его из строя — ровно то состояние, из которого админ
            // собирался разбираться. Деньги идут админу, кражи нет, но это
            // бесплатный способ помешать.
            assert (!rotationNow.paused) throw Errors.ExtensionPaused;
            assert (msg.domainTag == expectedDomainTag) throw Errors.WrongDomainTag;
            assert (msg.seqno == storage.seqno) throw Errors.InvalidSeqno;
            assert (msg.validUntil > blockchain.now()) throw Errors.Expired;
            assert (
                msg.validUntil <= blockchain.now() + MAX_VALIDITY_WINDOW
            ) throw Errors.ValidityWindowTooLong;
            assert (
                contract.getOriginalBalance() > WITHDRAW_RESERVE
            ) throw Errors.NotEnoughExtensionBalance;

            acceptExternalMessage();

            storage.seqno += 1;
            storage.save();
            commitContractDataAndActions();

            val withdrawMsg = createMessage({
                dest: storage.admin,
                bounce: false,
                value: contract.getOriginalBalance() - WITHDRAW_RESERVE,
            });
            withdrawMsg.send(SEND_MODE_REGULAR);
        }
        else => {
            throw Errors.UnsupportedExternalMessage;
        }
    }
}

// A-12: официальный чек-лист TON требует явной обработки bounced-сообщений.
// Сейчас они недостижимы ТОЛЬКО потому, что все исходящие внутренние
// сообщения расширения имеют bounce: false — безопасно по совпадению, а не
// по замыслу. Одна будущая правка с bounce: true открыла бы это молча.
//
// В Tolk для этого есть ОТДЕЛЬНАЯ точка входа onBouncedMessage — поэтому
// ни аннотация @on_bounced_policy, ни проверка внутри onInternalMessage не
// нужны (сначала попробовал именно так, поля isBounced у InMessage нет).
fun onBouncedMessage(_in: InMessageBounced) {
    // Наше же сообщение вернулось — молча принимаем деньги обратно.
    // Ничего не откатываем: spentInWindow намеренно не уменьшается, лимит
    // "сгорает" (см. #1 в SECURITY.md) — это осознанный компромисс ради
    // скорости, а не упущение.
    return;
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedInternalMessages.fromSlice(in.body);

    match (msg) {
        CancelSubscription => {
            var storage = lazy ExtensionStorage.load();

            assert (storage.admin == in.senderAddress) throw Errors.OnlyAdmin;
            // АУДИТ #30: с малым value кошельку не хватит на обработку
            // RemoveExtension — ключ обнулится, а расширение останется в
            // списке доверенных. Состояние невосстановимое штатно.
            assert (in.valueCoins >= MIN_INTERNAL_VALUE) throw Errors.NotEnoughValueForCancel;

            // АУДИТ #9: раньше отменённое расширение продолжало принимать
            // подписанные запросы и наращивать свой счётчик вникуда (это было
            // записано как известное ограничение). Чиним бесплатно, не тратя
            // ни бита хранилища: обнуляем ключ подписи. Против нулевого ключа
            // не проходит ни одна подпись — контракт замолкает окончательно.
            storage.publicKey = 0;
            // A-25: тот же урок, что A-11, применённый и здесь. Прежняя
            // версия пересобирала структуру целиком и писала paused: false —
            // безопасно ТОЛЬКО потому, что cancelled доминирует во всех
            // проверках. Меняем то, что должны, остальное не трогаем.
            var rotCancel = lazy storage.rotation.load();
            // A11: повторная отмена на надгробии проходила, жгла газ из
            // резерва аренды (того самого, что R5 поднял РАДИ аренды) и слала
            // кошельку удаление расширения, которого там уже нет.
            assert (!rotCancel.cancelled) throw Errors.ExtensionCancelled;
            rotCancel.pendingPublicKey = 0;
            rotCancel.requestedAtSeqno = 0;
            rotCancel.requestedAt = 0;
            rotCancel.cancelled = true;
            storage.rotation = rotCancel.toCell();
            storage.save();

            val removeExtensionMsg = createMessage({
                body: W5ExtensionActionRequest {
                    queryId: msg.queryId,
                    outActions: null,
                    hasExtraActions: true,
                    extraActions: W5RemoveExtensionExtraAction {
                        addr: contract.getAddress(),
                    }.toCell()
                        .beginParse(),
                },
                bounce: false,
                dest: storage.walletAddress,
                value: 0,
            });

            val cancelEvent = createExternalLogMessage({
                dest: createAddressNone(),
                body: AdminActionEvent { queryId: msg.queryId, action: 1 },
            });
            cancelEvent.send(SEND_MODE_REGULAR);

            removeExtensionMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }
        WithdrawToAdmin => {
            val storage = lazy ExtensionStorage.load();

            // АУДИТ #19: путь вывода, не зависящий от ключа подписи. Работает
            // и после отмены (когда publicKey уже обнулён), и если приватный
            // ключ бота потерян. Отправитель проверяется сетью, подпись не нужна.
            assert (storage.admin == in.senderAddress) throw Errors.OnlyAdmin;
            assert (in.valueCoins >= MIN_INTERNAL_VALUE) throw Errors.NotEnoughGasValue;

            // ПО ОФИЦИАЛЬНОМУ РУКОВОДСТВУ, раздел "Account destruction":
            // перед выметанием всего баланса нужен ЯВНЫЙ терминальный статус.
            // Раньше проверки не было — админ мог опустошить РАБОТАЮЩЕЕ
            // расширение в ноль, оно осталось бы установленным и включённым,
            // но платить бы не смогло: нечем платить за газ.
            // Терминальный статус здесь — отменённое расширение (ключ обнулён).
            // A-10: терминальный признак — ЯВНЫЙ флаг, а не publicKey. A3
            // ввёл флаг именно потому, что на publicKey опираться нельзя;
            // единственная операция, УНИЧТОЖАЮЩАЯ контракт, продолжала
            // смотреть на publicKey. Два места, одно неписаное предположение.
            val rotForWithdraw = lazy storage.rotation.load();
            if (rotForWithdraw.cancelled) {
                // A2: R9 чинил это не с той стороны — отказом. Отказ в момент,
                // когда админ спасает остаток, хуже, чем "вывести нечего".
                // Теперь просто ничего не отправляем, если сверх резерва
                // ничего нет, и не роняем транзакцию.
                if (contract.getOriginalBalance() <= TOMBSTONE_RESERVE) {
                    // A-30: раньше здесь был молчаливый return. Он не ронял
                    // транзакцию (урок A2), но и не сообщал ничего: присланный
                    // value контракт оставлял себе, событий не было, и отказ
                    // от успеха было не отличить. Повторные попытки не просто
                    // не помогали — каждая ДОКАРМЛИВАЛА надгробие.
                    val back = createMessage({
                        dest: in.senderAddress,
                        bounce: false,
                        value: 0,
                        body: Excesses {},
                    });
                    back.send(
                        SEND_MODE_IGNORE_ERRORS | SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
                    val nothingEvent = createExternalLogMessage({
                        dest: createAddressNone(),
                        body: AdminActionEvent { queryId: msg.queryId, action: 8 },
                    });
                    nothingEvent.send(SEND_MODE_REGULAR);
                    return;
                }
                // Отменено: выметаем всё, контракт больше не нужен.
                    val sweepMsg = createMessage({
                    dest: storage.admin,
                    bounce: false,
                    // A-14: оставляем на аренду, а не выметаем в ноль.
                    value: contract.getOriginalBalance() - TOMBSTONE_RESERVE,
                });
                // A-14, КРИТИЧНО. Раньше здесь стоял SEND_MODE_DESTROY — я
                // добавил его в десятом раунде, думая про аренду, и не
                // пересмотрел смысл флага cancelled, заведённого в восьмом.
                //
                // Уничтожение аккаунта стирает и cancelled, и обнулённый
                // publicKey — весь терминальный статус. А state_init первого
                // развёртывания лежит в блокчейне открыто: кто угодно может
                // отправить на тот же адрес 0.1 TON и ВОСКРЕСИТЬ контракт в
                // ИСХОДНОМ состоянии — cancelled=false, исходный (возможно
                // скомпрометированный) ключ, seqno=0, полный лимит. Если
                // расширение осталось в списке кошелька (а cancel.tolk сам
                // печатает, что так бывает) — трата продолжается с нуля,
                // причём пользователь уверен, что всё отменил.
                //
                // Оставляем "надгробие": аккаунт продолжает существовать с
                // флагом cancelled, и адрес нельзя занять другим state_init.
                sweepMsg.send(SEND_MODE_REGULAR);
            } else {
                // Ещё работает: оставляем рабочий резерв, чтобы не обездвижить.
                assert (
                    contract.getOriginalBalance() > WITHDRAW_RESERVE
                ) throw Errors.NotEnoughExtensionBalance;
                val partialMsg = createMessage({
                    dest: storage.admin,
                    bounce: false,
                    value: contract.getOriginalBalance() - WITHDRAW_RESERVE,
                });
                partialMsg.send(SEND_MODE_REGULAR);
                // A-33: идиома "события наружу" применена к пяти операциям и
                // не донесена до шестой — при том, что именно она перемещает
                // средства. По цепочке нельзя было отличить "остаток забрали"
                // от "попытка была, выводить было нечего".
                val withdrawEvent = createExternalLogMessage({
                    dest: createAddressNone(),
                    body: AdminActionEvent { queryId: msg.queryId, action: 7 },
                });
                withdrawEvent.send(SEND_MODE_REGULAR);
            }
        }
        RotateSigningKey => {
            // A-15: право менять ключ теперь у ВЛАДЕЛЬЦА КОШЕЛЬКА, не у бота.
            // Бот этим правом ничего полезного не достигал (против
            // компрометации ротация бесполезна — заявку подписывает тот же
            // подозреваемый ключ), зато мог назначить ключ малого порядка,
            // после чего тратить смог бы кто угодно.
            var storage = lazy ExtensionStorage.load();
            assert (storage.admin == in.senderAddress) throw Errors.OnlyAdmin;
            assert (in.valueCoins >= MIN_INTERNAL_VALUE) throw Errors.NotEnoughGasValue;
            assert (
                !isSmallOrderKey(msg.newPublicKey)
            ) throw Errors.SmallOrderPublicKey;

            var rot = lazy storage.rotation.load();
            assert (!rot.cancelled) throw Errors.ExtensionCancelled;
            rot.pendingPublicKey = msg.newPublicKey;
            rot.requestedAtSeqno = storage.seqno;
            rot.requestedAt = blockchain.now();
            storage.rotation = rot.toCell();
            storage.save();

            val rotEvent = createExternalLogMessage({
                dest: createAddressNone(),
                body: AdminActionEvent { queryId: msg.queryId, action: 3 },
            });
            rotEvent.send(SEND_MODE_REGULAR);
        }
        ConfirmSigningKey => {
            var storage = lazy ExtensionStorage.load();
            assert (storage.admin == in.senderAddress) throw Errors.OnlyAdmin;
            assert (in.valueCoins >= MIN_INTERNAL_VALUE) throw Errors.NotEnoughGasValue;

            var rot = lazy storage.rotation.load();
            assert (!rot.cancelled) throw Errors.ExtensionCancelled;
            assert (rot.pendingPublicKey != 0) throw Errors.NoPendingKeyRotation;
            assert (
                !isSmallOrderKey(rot.pendingPublicKey)
            ) throw Errors.SmallOrderPublicKey;

            // R3: у проверки срока не было НИЖНЕЙ границы. requestedAt из
            // предзаряженного хранилища мог дать отрицательную разность,
            // которая всегда меньше лимита — защита обходилась одним полем.
            assert (
                blockchain.now() >= rot.requestedAt
            ) throw Errors.RotationExpired;
            assert (
                blockchain.now() - rot.requestedAt <= ROTATION_TTL
            ) throw Errors.RotationExpired;

            // Подпись НОВОГО ключа над содержимым, привязанным к этому
            // контракту и к заявленному ключу — доказательство, что приватная
            // часть существует. Именно ради этого схема и двухшаговая.
            val (_, myHash) = contract.getAddress().getWorkchainAndHash();
            val challenge = beginCell()
                .storeUint(myHash, 256)
                .storeUint(rot.pendingPublicKey, 256)
                .endCell();
            assert (
                isSignatureValid(challenge.hash(), msg.newKeySignature as slice, rot.pendingPublicKey as int)
            ) throw Errors.InvalidSignature;

            storage.publicKey = rot.pendingPublicKey;
            rot.pendingPublicKey = 0;
            rot.requestedAtSeqno = 0;
            rot.requestedAt = 0;
            storage.rotation = rot.toCell();
            storage.save();

            val confirmEvent = createExternalLogMessage({
                dest: createAddressNone(),
                body: AdminActionEvent { queryId: msg.queryId, action: 4 },
            });
            confirmEvent.send(SEND_MODE_REGULAR);
        }
        SetPaused => {
            var storage = lazy ExtensionStorage.load();
            assert (storage.admin == in.senderAddress) throw Errors.OnlyAdmin;
            // R12: три ветки знали про флаг отмены, две нет — тот же почерк,
            // из которого выросли A-10 и A-18.
            val rotCheck = lazy storage.rotation.load();
            assert (!rotCheck.cancelled) throw Errors.ExtensionCancelled;
            assert (in.valueCoins >= MIN_INTERNAL_VALUE) throw Errors.NotEnoughGasValue;

            var rot = lazy storage.rotation.load();
            // A-39: A11 ввёл правило "операция, ничего не меняющая, не должна
            // проходить и жечь газ" и применил его к отмене. Сюда не донесли:
            // повторная пауза на уже приостановленном проходила и тратила
            // баланс на второе лог-сообщение.
            assert (rot.paused != msg.paused) throw Errors.InvalidLimitParams;
            rot.paused = msg.paused;
            storage.rotation = rot.toCell();
            storage.save();

            val pauseEvent = createExternalLogMessage({
                dest: createAddressNone(),
                body: AdminActionEvent {
                    queryId: msg.queryId,
                    action: msg.paused ? 5 : 6,
                },
            });
            pauseEvent.send(SEND_MODE_REGULAR);
        }
        UpdateSpendLimit => {
            var storage = lazy ExtensionStorage.load();

            // Только владелец кошелька, и намеренно НЕ подписью — иначе бот,
            // держащий ключ подписи, мог бы сам себе поднять лимит.
            assert (storage.admin == in.senderAddress) throw Errors.OnlyAdmin;
            // R12: на отменённом контракте менять лимит бессмысленно, но
            // операция тратила бы баланс надгробия на событие.
            val rotLimitCheck = lazy storage.rotation.load();
            assert (!rotLimitCheck.cancelled) throw Errors.ExtensionCancelled;
            assert (in.valueCoins >= MIN_INTERNAL_VALUE) throw Errors.NotEnoughGasValue;
            // A-38: границы окна и ненулевой лимит раньше проверялись здесь
            // ОТДЕЛЬНО, при том что тот же раунд объявил isConsistent()
            // единственным источником истины и удалил дубликаты из скриптов.
            // В самой операции они остались, причём с составом, отличавшимся
            // от предиката (MAX_DAILY_LIMIT тут не проверялся вовсе).
            // Всё проверяет policy.assertConsistent() ниже.

            // A-44: инвариант резервов. Константы нельзя связать выражением
            // на этапе компиляции, поэтому проверяем здесь — стоит копейки
            // газа и ловит любую будущую правку, которая сломает порядок.
            assert (
                WITHDRAW_RESERVE >= TOMBSTONE_RESERVE
                && TOMBSTONE_RESERVE >= OPERATIONAL_FLOOR
            ) throw Errors.InvalidLimitParams;

            var policy = lazy storage.policy.load();
            // A10: раньше смена windowSeconds не трогала windowStart и счётчики —
            // сужение окна могло мгновенно обнулить обе траты (попадание в
            // ветку полного сброса), расширение — растянуть вес старой траты
            // почти на неделю. Не уязвимость сама по себе (операция админская),
            // но неочевидное поведение. Теперь смена лимита явно обнуляет
            // окно — предсказуемо в любом случае.
            policy.dailyLimit = msg.newDailyLimit;
            policy.windowSeconds = msg.newWindowSeconds;
            policy.maxSinglePayment = msg.newMaxSinglePayment;
            // A-18: тот же предикат, что проверяет платёжный путь. Раньше
            // здесь были свои assert БЕЗ нижней границы maxSinglePayment —
            // три места из четырёх знали про неё, а четвёртое, единственное
            // работающее на живом контракте, нет. Политика сохранялась с виду
            // успешно, и после этого КАЖДЫЙ платёж падал.
            policy.assertConsistent();
            policy.windowStart = null;
            policy.b0 = 0;
            policy.b1 = 0;
            policy.b2 = 0;
            policy.b3 = 0;
            policy.b4 = 0;
            storage.policy = policy.toCell();
            storage.save();

            val limitEvent = createExternalLogMessage({
                dest: createAddressNone(),
                body: AdminActionEvent { queryId: msg.queryId, action: 2 },
            });
            limitEvent.send(SEND_MODE_REGULAR);

            // Возврат неиспользованного отправителю — иначе средства
            // понемногу оседают в контракте.
            val excessMsg = createMessage({
                dest: in.senderAddress,
                bounce: false,
                value: 0,
                body: Excesses {},
            });
            excessMsg.send(
                SEND_MODE_IGNORE_ERRORS | SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }
        TopUp => {
            // simply accept payment
        }
        else => {
            // ИДИОМА "Use unions to handle incoming messages": пустое тело —
            // это обычное пополнение с кошелька, его пропускаем. А вот ЧУЖОЙ
            // опкод раньше глотался молча — теперь падает с ошибкой, чтобы
            // отправитель увидел, что сообщение не понято.
            assert (in.body.isEmpty()) throw Errors.UnsupportedExternalMessage;
        }
    }
}

// ШАГ 3: наружу отдаём ПЛОСКИЙ вид, а не внутреннюю структуру с ячейкой —
// клиентам и тестам не нужно знать, что политика лежит отдельно.
// R8a: прокрутка на копии — та же арифметика, что на платёжном пути.
fun rolledStart(p: SpendPolicy): uint32? {
    // ВАЖНО: rollTo при ПУСТОМ окне УСТАНАВЛИВАЕТ его в текущее время —
    // это правильно для платежа (окно как раз начинается), но неправильно
    // для геттера: свежий контракт показывал бы "окно началось прямо
    // сейчас" вместо "не начиналось". Так я сломал два теста, исправляя
    // рассогласование A-35 — то есть создал новое рассогласование,
    // устраняя старое.
    if (p.windowStart == null) {
        return null;
    }
    var probe = p;
    probe.rollTo(blockchain.now());
    return probe.windowStart;
}

fun spentNow(p: SpendPolicy): coins {
    var probe = p;
    probe.rollTo(blockchain.now());
    return probe.b0 + probe.b1 + probe.b2 + probe.b3 + probe.b4;
}

get fun extensionInfo(): ExtensionInfo {
    val s = lazy ExtensionStorage.load();
    val p = lazy s.policy.load();
    val rotationState = lazy s.rotation.load();
    return ExtensionInfo {
        walletAddress: s.walletAddress,
        admin: s.admin,
        publicKey: s.publicKey,
        seqno: s.seqno,
        dailyLimit: p.dailyLimit,
        windowSeconds: p.windowSeconds,
        // A-35: R8a починил сумму и не тронул соседнее поле той же структуры.
        // Клиент, считающий "когда окно освободится" как
        // windowStart + windowSeconds, получал метку времени, не
        // соответствующую отданной ему же сумме трат.
        windowStart: rolledStart(p),
        // R8a: раньше суммировались корзины БЕЗ прокрутки ко времени —
        // старые траты, которые контракт при платеже уже выбросил бы,
        // продолжали учитываться. Бот получал ЗАНИЖЕННЫЙ остаток и не
        // отправлял платежи, которые прошли бы.
        spentInWindow: spentNow(p),
        maxSinglePayment: p.maxSinglePayment,
        globalId: s.globalId,
        pendingPublicKey: rotationState.pendingPublicKey,
        requestedAt: rotationState.requestedAt,
        cancelled: rotationState.cancelled,
        paused: rotationState.paused,
    };
}

// Чтобы бот не вычислял domainTag вручную и не ошибся — контракт сам скажет.
// Версия контракта. За десять раундов правок развёрнутых экземпляров разных
// версий накопилось несколько, и снаружи их было не различить никак —
// индексатору и клиенту нужен способ понять, с чем он имеет дело.
get fun contractVersion(): int {
    return 10;
}

get fun domainTag(): int {
    val (_, myAddrHash) = contract.getAddress().getWorkchainAndHash();
    return myAddrHash;
}

get fun remainingLimit(): coins {
    val storage = lazy ExtensionStorage.load();
    val rotationState = lazy storage.rotation.load();
    // A-17: пауза добавилась в одиннадцатом раунде, а геттеры не пересмотрели.
    // A-31 частично откачен вместе с проверкой на платёжном пути: раз её
    // там больше нет (см. комментарий в onExternalMessage — 19 сравнений не
    // влезают в кредит газа), то и геттеры не должны её повторять. Иначе
    // вернётся ровно то расхождение, ради устранения которого A-31 писался,
    // только зеркальное: геттер строже контракта.
    if (storage.publicKey == 0
        || rotationState.cancelled
        || rotationState.paused) {
        return 0 as coins;
    }
    // A2: та же самая функция, что использует контракт при платеже —
    // разойтись они больше не могут по построению.
    val policy = lazy storage.policy.load();
    // R8b: isNotDisabled() проверяет согласованность, платёжный путь тоже —
    // а этот геттер нет. Для несогласованной политики он возвращал бы
    // положительное число, хотя каждый платёж падал бы.
    if (!policy.isConsistent()) {
        return 0 as coins;
    }
    return policy.availableAt(blockchain.now());
}

// АУДИТ #24: одним вызовом — готов ли контракт вообще работать, чтобы бот
// не собирал этот вывод из extensionInfo() сам и не ошибался.
// НАЙДЕНО ТЕСТОМ: первая версия этих геттеров читала contract.get\
// OriginalBalance(). Внутри транзакции это работает правильно (проверка
// баланса при платеже отклоняет как надо), но в get-методе — вне транзакции —
// реального баланса не даёт. Геттеры тихо врали боту: тест с двойным запасом
// по балансу всё равно получал false.
//
// Чинить это не нужно — нужно убрать зависимость. Баланс контракта клиент и
// так видит обычным запросом к сети, get-метод для этого лишний. А вот эти
// две величины клиент сам знать не может — их и отдаём.

// Порог баланса, ниже которого контракт откажется платить. Клиент сравнивает
// с балансом, который прочитал сам.
// A2: без этого геттера клиент физически не мог посчитать, сколько ему
// вернётся при выводе с отменённого расширения и вернётся ли вообще.
// A-36: срок жизни заявки на смену ключа — наружу, по образцу
// tombstoneReserve(). Без него клиент не мог посчитать остаток времени.
get fun rotationTtl(): int {
    return ROTATION_TTL;
}

get fun tombstoneReserve(): coins {
    return TOMBSTONE_RESERVE;
}

get fun operationalFloor(): coins {
    return OPERATIONAL_FLOOR;
}

// Во сколько обходится один платёж (уведомление кошельку плюс примерный газ).
// Клиент делит на это свой остаток и получает, сколько платежей осталось.
get fun costPerPayment(): coins {
    // A-7, ИЗМЕРЕНО НА ЖИВОМ TESTNET (не подобрано):
    //   расширение: gas=14400 => ~0.0013 TON собственного газа
    //   кошелёк на обработке запроса: gas=3545
    //   кошелёк на отправке платежа:  gas=778
    //   баланс расширения: 0.8 -> 0.778696695 за один платёж
    //   итого реальная стоимость платежа для расширения: 0.0213 TON
    // Прежняя оценка 0.006 была завышена вчетверо — в безопасную сторону,
    // но неточна. Берём измеренные 0.0013 с двойным запасом на колебания
    // цены газа и на более длинный memo.
    return NOTIFY_WALLET_VALUE + ton("0.003");
}

// Только состояние контракта, без баланса — эта часть в get-методе честная.
// A-8: ПЕРЕИМЕНОВАНО из isEnabled(). Прежнее имя обещало ответ на вопрос
// "готов ли контракт работать", на который этот геттер ответить НЕ МОЖЕТ:
// установленность расширения живёт в ДРУГОМ контракте (в списке кошелька).
// Если расширение сняли напрямую через RemoveExtensionExtraAction, минуя
// CancelSubscription, — здесь по-прежнему будет true, а платежи молча не
// пройдут: кошелёк игнорирует запросы от неустановленных расширений, при
// этом баланс расширения выжигается по NOTIFY_WALLET_VALUE за попытку.
//
// Клиент ОБЯЗАН дополнительно читать wallet.get_extensions() — этот геттер
// отвечает только за внутреннее состояние самого расширения.
get fun isNotDisabled(): bool {
    val storage = lazy ExtensionStorage.load();
    val policy = lazy storage.policy.load();
    val rotationState = lazy storage.rotation.load();
    return storage.publicKey != 0
        && !rotationState.cancelled
        && !rotationState.paused
        // A-17: тот же предикат, что проверяет платёжный путь. Раньше тут было
        // windowSeconds > 0, а контракт требует >= 3600 — контракт с окном
        // в 100 секунд рапортовал "не выключен" и не мог платить.
        && policy.isConsistent();
}
