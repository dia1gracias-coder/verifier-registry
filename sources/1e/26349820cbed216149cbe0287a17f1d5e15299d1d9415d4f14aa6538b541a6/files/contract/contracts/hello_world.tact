contract HelloWorld {
    
    // Variable untuk menyimpan pesan
    message: String;
    
    // Fungsi init dipanggil sekali saat deploy
    init() {
        self.message = "Hello World from TON!";
    }
    
    // Receiver untuk handle message deploy dan lainnya
    receive() {
        // Tidak perlu melakukan apa-apa, cukup terima message
    }
    
    // Fungsi untuk membaca pesan (get method)
    get fun greeting(): String {
        return self.message;
    }
}