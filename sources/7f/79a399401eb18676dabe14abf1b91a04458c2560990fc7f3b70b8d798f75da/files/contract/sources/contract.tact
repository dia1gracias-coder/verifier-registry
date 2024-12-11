import "@stdlib/deploy";

contract Strings with Deployable {
    get fun greeting(): String {
     return "hello world infinite8.ae";
    }
}