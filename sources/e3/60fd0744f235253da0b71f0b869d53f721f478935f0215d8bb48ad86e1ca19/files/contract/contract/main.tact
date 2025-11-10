import "@stdlib/deploy";

contract HelloWorld with Deployable {
    init() {
        // Initialization logic here if needed
    }

    // A getter function to return the "hello world" string
    get fun greeting(): String {
        return "hello world";
    }
}
