import "@stdlib/deploy";

contract HelloWorld with Deployable {
    get fun greeting(): String {
        return "hello world";
    }
}