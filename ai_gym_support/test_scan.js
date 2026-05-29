const fs = require("fs");
const http = require("http");
const path = require("path");

(async () => {
  try {
    const filePath = path.join(__dirname, "sample.jpg");
    const fileName = path.basename(filePath);
    const fileBuffer = fs.readFileSync(filePath);

    const boundary = "----WebKitFormBoundary" + Date.now().toString(16);
    const payloadStart = `--${boundary}\r\nContent-Disposition: form-data; name="email"\r\n\r\ntest@example.com\r\n--${boundary}\r\nContent-Disposition: form-data; name="image"; filename="${fileName}"\r\nContent-Type: application/octet-stream\r\n\r\n`;
    const payloadEnd = `\r\n--${boundary}--\r\n`;

    const options = {
      hostname: "localhost",
      port: 3000,
      path: "/api/scan-equipment",
      method: "POST",
      headers: {
        "Content-Type": "multipart/form-data; boundary=" + boundary,
      },
    };

    const req = http.request(options, (res) => {
      console.log("Status:", res.statusCode);
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        console.log("Response body:", data);
      });
    });

    req.on("error", (e) => {
      console.error("Request error:", e);
    });

    req.write(Buffer.from(payloadStart, "utf8"));
    req.write(fileBuffer);
    req.write(Buffer.from(payloadEnd, "utf8"));
    req.end();
  } catch (err) {
    console.error("Failed to run test:", err);
  }
})();
