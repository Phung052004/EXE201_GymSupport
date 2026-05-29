const fs = require("fs");
const http = require("http");
const path = require("path");

const samplePngBase64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7vN8kAAAAASUVORK5CYII=";

function buildMultipartBody({ boundary, email, filename, fileBuffer }) {
  const parts = [
    Buffer.from(
      `--${boundary}\r\n` +
        `Content-Disposition: form-data; name="email"\r\n\r\n` +
        `${email}\r\n`,
      "utf8",
    ),
    Buffer.from(
      `--${boundary}\r\n` +
        `Content-Disposition: form-data; name="image"; filename="${filename}"\r\n` +
        `Content-Type: image/png\r\n\r\n`,
      "utf8",
    ),
    fileBuffer,
    Buffer.from(`\r\n--${boundary}--\r\n`, "utf8"),
  ];

  return Buffer.concat(parts);
}

(async () => {
  try {
    const backendBaseUrl =
      process.env.BACKEND_URL || "http://10.87.40.163:3000";
    const samplePath = path.join(__dirname, "sample.png");
    fs.writeFileSync(samplePath, Buffer.from(samplePngBase64, "base64"));

    const boundary = `----GymSupportBoundary${Date.now()}`;
    const body = buildMultipartBody({
      boundary,
      email: "test@example.com",
      filename: "sample.png",
      fileBuffer: fs.readFileSync(samplePath),
    });

    const requestUrl = new URL(backendBaseUrl);
    requestUrl.pathname = "/api/scan-equipment";

    const requestOptions = {
      method: "POST",
      headers: {
        "Content-Type": `multipart/form-data; boundary=${boundary}`,
        "Content-Length": body.length,
      },
    };

    console.log(`Posting scan request to ${backendBaseUrl}/api/scan-equipment`);

    const req = http.request(requestUrl, requestOptions, (res) => {
      let responseBody = "";
      res.on("data", (chunk) => {
        responseBody += chunk;
      });
      res.on("end", () => {
        console.log("Status:", res.statusCode);
        console.log("Response:", responseBody);
      });
    });

    req.on("error", (error) => {
      console.error("Request error:", error.message);
      process.exitCode = 1;
    });

    req.write(body);
    req.end();
  } catch (error) {
    console.error("Test setup failed:", error.message);
    process.exitCode = 1;
  }
})();
