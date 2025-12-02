import "cron-storage"

const SEND_MODE_BASIC = 3;
const ERROR_UNSUPPORTED_OPCODE = 0xffff;

@pure
fun getCronCode(): cell
    asm "B{b5ee9c7241020a0100028d000114ff00f4a413f4bcf2c80b01020120020902014803080236d0f891f240d72c21720e9d64e302d72c2000000004e302840ff2f0040601fc30ed44d0d200d31fd31fd31ffa00fa40d4d3ffd70b0908f2d193f8276f10821005f5e100bef2e0c825c200f2e0caf89223c705f2e0cbc000f2e0cc06c000f2e0cd25d0d70b0520c01801c010b1f2e064ed4420d76501f90026c0009636f82325a006dec8cf8317cb1f15cb1f13cb1f01fa02ce13cc21cf0bff22cf0b09c9050088ed5482080f42408d0860000000000000000000000000000000000000000000000000000000000383123f24c8cf8508ce01fa028210d027efe5cf0b8acbffcb09c971fb0001f28b764657374726f798c7058e6af897820afaf080be8e5fed44d0d20031d31f31d31f31d31f31fa0031fa4031d431d3ffd70b0982080f42408d0860000000000000000000000000000000000000000000000000000000000383123f24c8cf8508ce01fa028210d027efe5cf0b8a12cbffcb09c971fb00dee30d0700f4ed44d0d20031d31f31d31f31d31f31fa0031fa40d431d3ffd70b09f89223c705f2e19182080f42408d0860000000000000000000000000000000000000000000000000000000000383123f24c8cf8508ce01fa028210d027efe5cf0b8a12cbffcb09c971fb00c8cf8508ce8210bbe27821cf0b8ec98100a0fb00004ba060b7da89a1a60063a63fa63fa63e63f401ae99a1020223ae43f40061f04ede20a2254142b100dcf2840fed44d0d600d31f20d31fd31f31fa00d74cf8235005bef2e19206d72c2108a3816c16f2f404fa403020d72c053121fa4430c000b0f2e190f800f8235005a003c8ce13cb1f12cec9ed5422c2008e16c8cf850812ce58fa0282102e04891acf0b8ac973fb00926c21e273fb0057a59bfe} B>boc PUSHREF";


struct (0x56f6110e) CalcAndTopup  {
    firstCallTime: uint32
    repeatEvery: uint32
    salt: uint32
    reward: coins
    ownerAddress: address
    renewalActionsCell: cell
    topupAmount: coins
    msgToWalletAmount: coins
}

struct (0x6578746E) ExtensionActionRequest {
    queryId: uint64
    outActions: cell?
    hasExtraActions: bool = false
}

struct (0x0ec3c86d) OutActionWithSendMessageOnly {
    prev: cell
    sendMode: uint8
    outMsg: cell
}


fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }
    val msg = lazy CalcAndTopup.fromSlice(in.body,
     { throwIfOpcodeDoesNotMatch: ERROR_UNSUPPORTED_OPCODE });

    // make it in a classic way to store body without ref
    // val msgToThisContract: OutMessage = createMessage(
    //     {
    //         dest: contract.getAddress(),
    //         bounce: true,
    //         value: msg.topupAmount,
    //         body: in.body
    //     }
    // );
    val msgToThisContractCell = beginCell()
        .storeUint(0x18, 6) // bounceable
        .storeAddress(contract.getAddress())
        .storeCoins(msg.topupAmount)
        .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
        .storeSlice(in.body)
        .endCell();
    val fullActions = OutActionWithSendMessageOnly {
        prev: msg.renewalActionsCell,
        sendMode: SEND_MODE_BASIC,
        outMsg: msgToThisContractCell
    };
    val msgBodyToWallet = ExtensionActionRequest {
        queryId: 0,
        outActions: fullActions.toCell()
    };
    val msgToWallet = createMessage(
        {
            dest: msg.ownerAddress,
            bounce: false,
            value: msg.msgToWalletAmount,
            body: msgBodyToWallet.toCell()
        }
    );
    val cronInitData = Storage { // from cron-storage.tolk
        initialized: false,
        nextCallTime: msg.firstCallTime,
        repeatEvery: msg.repeatEvery,
        salt: msg.salt,
        reward: msg.reward,
        ownerAddress: msg.ownerAddress,
        message: msgToWallet.toCell().beginParse().loadRef(),
        initStateHash: 0,
        initStateDepth: 0
    };
    val cronAddrHash = StateInit.calcHashCodeData(getCronCode(), cronInitData.toCell());
    val msgToCron = createMessage(
        {
            dest: (0, cronAddrHash),
            bounce: false,
            value: 0,
            body: beginCell().storeUint(0, 32).storeSlice("topup").endCell()
        }
    );
    msgToCron.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}