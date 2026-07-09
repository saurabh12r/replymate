# ReplyMet Admin & Broker Management Panel

A production-ready Flutter Web administrative console.

## Running Locally (Mirroring Netlify)

To run the application locally on `http://localhost:8080` with the same SPA routing fallback rules as Netlify (ensuring direct link navigation and page refreshes work correctly):

### 1. Build the Flutter Web application
This creates the release assets in `build/web`:
```bash
flutter build web --release
```

### 2. Start the local server
Run the zero-dependency local Node.js server:
```bash
node serve.js
```

The app will be served at **[http://localhost:8080](http://localhost:8080)**.

