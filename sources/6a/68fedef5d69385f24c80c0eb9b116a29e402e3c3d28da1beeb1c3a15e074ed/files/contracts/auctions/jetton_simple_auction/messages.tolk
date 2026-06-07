import "../../imports/messages"
import "../../imports/types"
import "../messages"



type AllowedMessage = (
    DeployAndSetWalletMessage
    | JettonsTransferNotificationMessage<SerializableSlice>
    | RenewDomainMessage
    | MakeHotMessage
    | MakeColoredMessage
    | ExcessesMessage
); 