import "@stdlib/ownable";
struct DocumentData {
        lastModified: Int as uint64; // Timestamp at which document details was last modified
        uri: String; // URI of the document that exist off-chain
        hash: Int; // Hash of the document
        name: String; // name of the document
}

message SetDocument {
        uri: String; // URI of the document that exist off-chain
        hash: Int; // Hash of the document
        name: String; // name of the document
}

message RemoveDocument {
        name: String; // name of the document to be removed
}

@interface("org.ton.jetton.trc1643")
trait TRC1643 with OwnableTransferable  {
        owner: Address;
        documents: map<Int, DocumentData>;
        nameHashs: map<Int, Int>;
        documentLength: Int;

        receive(msg: SetDocument) {
                self.requireOwner();
                let id: Int = self.documentLength;
                if(self.nameHashs.get(msg.name.asSlice().hash()) != null) {
                        id = self.nameHashs.get(msg.name.asSlice().hash())!!;
                } else {
                        self.nameHashs.set(msg.name.asSlice().hash(), id);
                        self.documentLength = id + 1;
                }

                self.documents.set(id, DocumentData{
                        name: msg.name,
                        lastModified: now(),
                        uri: msg.uri,
                        hash: msg.hash
                });
        }

        receive(msg: RemoveDocument) {
                self.requireOwner();
                let id: Int? = self.nameHashs.get(msg.name.asSlice().hash());
                require(id != null, "Document not found");
                if(self.documentLength == 1) {
                        self.documents.del(id!!);
                } else {
                        let last: DocumentData = self.documents.get(self.documentLength - 1)!!;
                        self.documents.set(id!!, last);
                        self.nameHashs.set(last.name.asSlice().hash(), id!!);
                        self.documents.del(self.documentLength - 1);
                }
                self.documentLength = self.documentLength - 1;
                self.nameHashs.del(msg.name.asSlice().hash());
        }

        get fun get_document(name: String): DocumentData? {
                let id: Int? = self.nameHashs.get(name.asSlice().hash());
                if(id == null) {
                        return null;
                }
                return self.documents.get(id!!);
        }

        get fun get_document_by_index(index: Int): DocumentData? {
                return self.documents.get(index);
        }

        get fun get_all_names(): map<Int, Cell> {
                let result: map<Int, Cell> = emptyMap();
                let i: Int = 0;
                while (i < self.documentLength) {
                        result.set(i, self.documents.get(i)!!.name.asSlice().asCell());
                        i += 1;
                }
                return result;
        }

        get fun get_all_documents(): map<Int, DocumentData> {
                return self.documents;
        }

        get fun get_document_length(): Int {
                return self.documentLength;
        }
}