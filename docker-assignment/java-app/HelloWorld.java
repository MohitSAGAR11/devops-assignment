import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

public class HelloWorld {

    private static final int PORT = 8080;

    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", PORT), 0);
        server.createContext("/", HelloWorld::handle);
        server.createContext("/health", exchange -> respond(exchange, "{\"status\":\"ok\"}"));
        server.setExecutor(null);
        server.start();
        System.out.println("Java app listening on port " + PORT);
    }

    private static void handle(HttpExchange exchange) throws IOException {
        String host = InetAddress.getLocalHost().getHostName();
        String body = "<!doctype html>\n"
                + "<html>\n"
                + "  <head><title>Java Hello World</title></head>\n"
                + "  <body style=\"font-family: system-ui, sans-serif; text-align: center; padding: 60px;\">\n"
                + "    <h1>Hello World</h1>\n"
                + "    <p>Served by <strong>Java (com.sun.net.httpserver)</strong> inside Docker</p>\n"
                + "    <p>Hostname (container id): " + host + "</p>\n"
                + "  </body>\n"
                + "</html>";
        respond(exchange, body);
    }

    private static void respond(HttpExchange exchange, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "text/html; charset=utf-8");
        exchange.sendResponseHeaders(200, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }
}
