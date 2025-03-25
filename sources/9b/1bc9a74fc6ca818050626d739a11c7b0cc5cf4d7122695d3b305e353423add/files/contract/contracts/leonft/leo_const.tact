const service_address: Address = address("0QALF1r0i3nbgArFSXAnth_xd5389Oj2fVR_pH1fn8mToWil"); //Сервисный адрес
const service_numerator: Int = 20; //Сервисные отчисления
const service_denominator: Int = 1000; //Сервисные отчисления
const hundred_percent: Int = 100000000000;

const gasConsumption: Int = ton("0.02"); //Газ за операцию
const nftMintCommission: Int = ton("0.08"); //Комиссия за МИНТ NFT
const TonTransferValue: Int = ton("0.007"); //Плата за отправку TON
const TokenMintCommission: Int = ton("0.04"); //Коммисия за МИНТ JETTON
const minTonsForStorage: Int = ton("0.02"); //Минимальное количество TON на хранение

@name(muldiv)
native muldiv(a: Int, b: Int, c: Int): Int;