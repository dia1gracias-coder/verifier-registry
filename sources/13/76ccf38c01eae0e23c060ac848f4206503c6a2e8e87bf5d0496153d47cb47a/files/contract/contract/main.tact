import "@stdlib/deploy";

contract TactCounter {
    receive() {
        let ctx: Context = context();
        let requiredAmount = ton("0.1");
        let amount: Int = ctx.value;
        let user = sender();

        if (amount == requiredAmount) {
            // Мок: отправляем сообщение о выдаче NFT
            send(SendParameters {
                to: user,
                value: 0,
                mode: SendRemainingValue,
                body: "Вы получили NFT!".asComment(),
            });
        } else if (amount < requiredAmount) {
            // Мало денег: возвращаем средства и коммент
            send(SendParameters {
                to: user,
                value: 0,
                mode: SendRemainingValue,
                body: "Слишком мало! Скиньте ровно 0.1 TON.".asComment(),
            });
        } else {
            // Сдача + NFT
            let refund = amount - requiredAmount;
            // 1. Отдаем NFT (мок)
            send(SendParameters {
                to: user,
                value: requiredAmount,
                mode: 0,
                body: "Вы получили NFT!".asComment(),
            });
            // 2. Отдаем сдачу отдельным сообщением
            send(SendParameters {
                to: user,
                value: refund,
                mode: 0,
                body: "Вам вернули сдачу!".asComment(),
            });
        }
    }
}
