# Docker Assignment - Hello World Applications

Six Hello World web apps, each in its own folder with its own `Dockerfile`.
All six were built and run, and all six return **HTTP 200** with *Hello World*
on the page.

## Folder structure

```
docker-assignment/
├── nodejs-app/     Node.js + Express
├── python-app/     Python + Flask
├── java-app/       Java (com.sun.net.httpserver), multi-stage build
├── Apache-app/     Apache HTTP Server (httpd) serving static HTML
├── React-app/      React + Vite, multi-stage build served by nginx
├── nginx-app/      Nginx serving static HTML
├── README.md
└── verification.log   raw output of docker ps + curl for all six
```

## Ports

Each app uses a different host port so all six can run at the same time.

| App | Image | Container port | Host port | URL |
|---|---|---|---|---|
| nodejs-app | `hello-nodejs-app` | 3000 | 3001 | http://localhost:3001 |
| python-app | `hello-python-app` | 5000 | 5001 | http://localhost:5001 |
| java-app | `hello-java-app` | 8080 | 8081 | http://localhost:8081 |
| Apache-app | `hello-apache-app` | 80 | 8082 | http://localhost:8082 |
| React-app | `hello-react-app` | 80 | 3002 | http://localhost:3002 |
| nginx-app | `hello-nginx-app` | 80 | 8083 | http://localhost:8083 |

---

## Build and run

### 1. nodejs-app

```bash
cd nodejs-app
docker build -t hello-nodejs-app .
docker run -d --name hello-nodejs -p 3001:3000 hello-nodejs-app
curl http://localhost:3001
```

```html
<h1>Hello World</h1>
<p>Served by <strong>Node.js + Express</strong> inside Docker</p>
<p>Hostname (container id): 51e6f18773d9</p>
```

`Dockerfile` copies `package*.json` and runs `npm install` **before** copying
the source, so the dependency layer stays cached when only `server.js` changes.

### 2. python-app

```bash
cd python-app
docker build -t hello-python-app .
docker run -d --name hello-python -p 5001:5000 hello-python-app
curl http://localhost:5001
```

```html
<h1>Hello World</h1>
<p>Served by <strong>Python + Flask</strong> inside Docker</p>
<p>Hostname (container id): 3d9559c050fa</p>
```

Same caching idea with `requirements.txt`, and `pip install --no-cache-dir`
keeps the image smaller.

### 3. java-app

```bash
cd java-app
docker build -t hello-java-app .
docker run -d --name hello-java -p 8081:8080 hello-java-app
curl http://localhost:8081
```

```html
<h1>Hello World</h1>
<p>Served by <strong>Java (com.sun.net.httpserver)</strong> inside Docker</p>
<p>Hostname (container id): 805a7f2f4660</p>
```

**Multi-stage build:** stage 1 compiles with the JDK (`javac HelloWorld.java`),
stage 2 copies only `HelloWorld.class` onto a JRE image — the compiler never
ships in the final image. Uses the JDK's built-in HTTP server, so there is no
Maven/Gradle step and no external dependency.

### 4. Apache-app

```bash
cd Apache-app
docker build -t hello-apache-app .
docker run -d --name hello-apache -p 8082:80 hello-apache-app
curl http://localhost:8082
```

```html
<h1>Hello World</h1>
<p>Served by the <strong>Apache HTTP Server (httpd)</strong> inside Docker</p>
```

The whole Dockerfile is a `COPY` into `/usr/local/apache2/htdocs/` — the
`httpd` base image already ends with `CMD ["httpd-foreground"]`.

### 5. React-app

```bash
cd React-app
docker build -t hello-react-app .
docker run -d --name hello-react -p 3002:80 hello-react-app
curl http://localhost:3002
```

```html
<!doctype html>
<html lang="en">
  <head>
    <title>React Hello World</title>
    <script type="module" crossorigin src="/assets/index-Cf3Fu0f3.js"></script>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
```

`curl` returns the shell page because React renders into `<div id="root">` in
the browser. The text is in the bundle — this confirms it:

```bash
curl -s http://localhost:3002/assets/index-Cf3Fu0f3.js | grep -o "Hello World"
```
```
Hello World
```

Open http://localhost:3002 in a browser to see the rendered heading plus a
click counter button, which proves React is actually running rather than
static HTML being served.

**Multi-stage build:** stage 1 (`node:20-alpine`) runs `npm install` and
`npm run build` to produce `/app/dist`; stage 2 copies only `dist` into
`nginx:1.27-alpine`. Node and `node_modules` are not in the final image, which
is why it is **73.8 MB** instead of a few hundred MB.

### 6. nginx-app

```bash
cd nginx-app
docker build -t hello-nginx-app .
docker run -d --name hello-nginx -p 8083:80 hello-nginx-app
curl http://localhost:8083
```

```html
<h1>Hello World</h1>
<p>Served by <strong>Nginx</strong> inside Docker</p>
```

Ships a custom `default.conf` as well as the HTML, so it also serves a
`/health` endpoint:

```bash
curl http://localhost:8083/health
```
```
ok
```

---

## Verification

### Images

```bash
docker images
```

```
REPOSITORY         TAG             SIZE
hello-nginx-app    latest          73.6MB
hello-react-app    latest          73.8MB
hello-apache-app   latest          96.1MB
hello-java-app     latest          286MB
hello-python-app   latest          208MB
hello-nodejs-app   latest          208MB
```

### Running containers

```bash
docker ps
```

```
NAMES          IMAGE              PORTS                                         STATUS
hello-nginx    hello-nginx-app    0.0.0.0:8083->80/tcp, [::]:8083->80/tcp       Up 8 seconds
hello-react    hello-react-app    0.0.0.0:3002->80/tcp, [::]:3002->80/tcp       Up 9 seconds
hello-apache   hello-apache-app   0.0.0.0:8082->80/tcp, [::]:8082->80/tcp       Up 9 seconds
hello-java     hello-java-app     0.0.0.0:8081->8080/tcp, [::]:8081->8080/tcp   Up 10 seconds
hello-python   hello-python-app   0.0.0.0:5001->5000/tcp, [::]:5001->5000/tcp   Up 11 seconds
hello-nodejs   hello-nodejs-app   0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp   Up 12 seconds
```

### HTTP status of every app

```bash
for p in 3001 5001 8081 8082 3002 8083; do
  printf "localhost:%s -> " $p
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:$p/
done
```

```
localhost:3001 -> 200
localhost:5001 -> 200
localhost:8081 -> 200
localhost:8082 -> 200
localhost:3002 -> 200
localhost:8083 -> 200
```

Full raw output of `docker ps` plus every page body is in
[`verification.log`](verification.log).

---

## Cleanup

```bash
docker rm -f hello-nodejs hello-python hello-java hello-apache hello-react hello-nginx
docker rmi hello-nodejs-app hello-python-app hello-java-app hello-apache-app hello-react-app hello-nginx-app
```

---

## Notes / what I took away

- **Pick the right base image.** `alpine` variants keep things small;
  `python:3.12-slim` is the middle ground when alpine's musl libc causes
  trouble with compiled Python packages.
- **Layer order matters.** Copy the dependency manifest and install *before*
  copying the source, otherwise every code change re-installs everything.
- **Multi-stage builds** are the big win: the React image is 73.8 MB because
  the build toolchain is thrown away after producing `dist`, and the Java image
  ships a JRE rather than a JDK.
- **`EXPOSE` documents, `-p` publishes.** `EXPOSE 3000` alone does not open
  anything; `-p 3001:3000` (host:container) is what makes it reachable.
- Servers must bind **`0.0.0.0`**, not `127.0.0.1` — binding to loopback inside
  a container makes it unreachable from the host even with `-p`.
- For the two web servers (Apache, Nginx) the Dockerfile is only a `COPY`,
  since the base images already define the right `CMD`.

Built and run with Docker Engine 29.1.3 on Ubuntu (WSL2).
