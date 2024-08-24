import "../item/messages.tact";
import "../collection/messages.tact";
import "./tep64_serialization.tact";

fun createEmtyNftMetadata(): NftMetadata {
    return NftMetadata {
        name: "",
        description: "",
        image: ""
    };
}

fun createEmtyNftCollectionMetadata(): NftCollectionMetadata {
    return NftCollectionMetadata {
        name: "",
        description: "",
        image: ""
    };
}

fun nftItemToCollectionMetadata(item: NftMetadata): NftCollectionMetadata {
    return NftCollectionMetadata {
        name: item.name,
        description: item.description,
        image: item.image
    };
}

fun nftCollectionToItemMetadata(collection: NftCollectionMetadata): NftMetadata {
    return NftMetadata {
        name: collection.name,
        description: collection.description,
        image: collection.image
    };
}

fun serializeNftItemIndividualContent(individual_content: NftMetadata): Cell {
    let tep64Dict: Cell? = beginTep64Dict();
    tep64Dict = storeTep64SnakeString(tep64Dict, "name", individual_content.name);
    tep64Dict = storeTep64SnakeString(tep64Dict, "description", individual_content.description);
    tep64Dict = storeTep64SnakeString(tep64Dict, "image", individual_content.image);
    return buildTep64OnchainContent(tep64Dict!!);
}

fun serializeNftCollectionContent(collection_content: NftCollectionMetadata): Cell {
    let item_data: NftMetadata = nftCollectionToItemMetadata(collection_content);
    return serializeNftItemIndividualContent(item_data);
}
