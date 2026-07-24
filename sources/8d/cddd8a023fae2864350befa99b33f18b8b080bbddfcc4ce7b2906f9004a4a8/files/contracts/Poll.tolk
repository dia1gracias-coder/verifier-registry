import "../gen/Voter.code"
import "types"

type AllowedPollMessage = Vote | ClosePoll 

contract Poll {
    storage: PollStorage
    incomingMessages: AllowedPollMessage
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedPollMessage.fromSlice(in.body);

    match (msg) {
        Vote => {
            var storage = lazy PollStorage.load();
            assert (!storage.isClosed) throw Errors.PollClosed;
            assert (msg.option == 0 || msg.option == 1) throw Errors.InvalidOption;
            if (msg.option == 0) {
                storage.option0 += 1;
            } else {
                storage.option1 += 1;
            }
            storage.save();

            // Deploy or message the Voter for this sender.
            // If Voter doesn't exist, the stateInit deploys it.
            // If it already exists, the stateInit is ignored; only the body is processed.

            val voterInit = ContractState {
                code: voterCompiledCode(),
                data: VoterStorage {
                    poll: contract.getAddress(),
                    voter: in.senderAddress,
                    hasVoted: false,
                }.toCell(),
            };
            val outMsg = createMessage(
                {
                    bounce: BounceMode.Only256BitsOfBody,
                    value: ton("0.05"),
                    dest: { stateInit: voterInit },
                    body: msg,
                },
            );
            outMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }
        ClosePoll => {
            var storage = lazy PollStorage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            storage.isClosed = true;
            storage.save();

            val returnMessage = createMessage({
                bounce: false,
                value: 0,
                dest: storage.owner
            });
            //SAFETY: only owner can get here, to destroy the vote
            returnMessage.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_DESTROY); //Note this boolean operator | instead of +
        }

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy Vote.fromSlice(in.bouncedBody);
    var storage = lazy PollStorage.load();

    if (msg.option == 1) {
        storage.option1 -=1;
    }
    if (msg.option == 0) {
        storage.option0 -=1;
    }
    storage.save();
}

get fun results(): (uint32, uint32) {
    val storage = lazy PollStorage.load();
    return (storage.option0, storage.option1);
}

get fun owner(): address {
    val storage = lazy PollStorage.load();
    return storage.owner;
}

get fun isClosed():bool {
    val storage = lazy PollStorage.load();
    return storage.isClosed;

}

get fun calcVoterAddress(voter: address): address {
    val init = ContractState {
        code: voterCompiledCode(),
        data: VoterStorage {
            poll: contract.getAddress(),
            voter,
            hasVoted: false,
        }.toCell(),
    };
    return AutoDeployAddress { stateInit: init }.calculateAddress();
}
