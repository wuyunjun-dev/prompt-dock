const fs = require("node:fs/promises");
const path = require("node:path");
const { spawn } = require("node:child_process");

function runPowerShell(script, input) {
  return new Promise((resolve, reject) => {
    const child = spawn("powershell.exe", [
      "-NoProfile",
      "-NonInteractive",
      "-ExecutionPolicy",
      "Bypass",
      "-Command",
      script
    ], {
      windowsHide: true,
      stdio: ["pipe", "pipe", "pipe"]
    });

    let stdout = "";
    let stderr = "";
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) {
        resolve(stdout.trim());
      } else {
        reject(new Error(stderr.trim() || `PowerShell exited with code ${code}`));
      }
    });
    child.stdin.end(input, "utf8");
  });
}

const protectScript = `
Add-Type -AssemblyName System.Security
$plain = [Console]::In.ReadToEnd()
$bytes = [Text.Encoding]::UTF8.GetBytes($plain)
$protected = [Security.Cryptography.ProtectedData]::Protect($bytes, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)
[Convert]::ToBase64String($protected)
`;

const unprotectScript = `
Add-Type -AssemblyName System.Security
$payload = [Console]::In.ReadToEnd()
$bytes = [Convert]::FromBase64String($payload)
$plain = [Security.Cryptography.ProtectedData]::Unprotect($bytes, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)
[Text.Encoding]::UTF8.GetString($plain)
`;

class SecureStore {
  constructor(filePath) {
    this.filePath = filePath;
  }

  async saveAPIKey(apiKey) {
    const trimmed = String(apiKey ?? "").trim();
    if (!trimmed) {
      await this.deleteAPIKey();
      return;
    }
    if (process.platform !== "win32") {
      throw new Error("Windows 版 API Key 使用 DPAPI 存储，请在 Windows 上保存密钥。");
    }

    const encrypted = await runPowerShell(protectScript, trimmed);
    await fs.mkdir(path.dirname(this.filePath), { recursive: true });
    await fs.writeFile(this.filePath, encrypted, "utf8");
  }

  async readAPIKey() {
    let encrypted;
    try {
      encrypted = await fs.readFile(this.filePath, "utf8");
    } catch (error) {
      if (error.code === "ENOENT") return null;
      throw new Error(`密钥读取失败：${error.message}`);
    }

    if (!encrypted.trim()) return null;
    if (process.platform !== "win32") {
      throw new Error("Windows 版 API Key 使用 DPAPI 存储，请在 Windows 上读取密钥。");
    }

    return runPowerShell(unprotectScript, encrypted.trim());
  }

  async hasAPIKey() {
    try {
      const encrypted = await fs.readFile(this.filePath, "utf8");
      return encrypted.trim().length > 0;
    } catch {
      return false;
    }
  }

  async deleteAPIKey() {
    try {
      await fs.unlink(this.filePath);
    } catch (error) {
      if (error.code !== "ENOENT") {
        throw new Error(`密钥删除失败：${error.message}`);
      }
    }
  }
}

module.exports = {
  SecureStore
};
