const fs = require("node:fs/promises");
const path = require("node:path");
const { spawn } = require("node:child_process");
const { downloadArtifact } = require("@electron/get");

const root = path.resolve(__dirname, "..");
const electronVersion = require("electron/package.json").version;

function parseArch() {
  const index = process.argv.indexOf("--arch");
  if (index >= 0 && process.argv[index + 1]) {
    return process.argv[index + 1];
  }
  const equalsArg = process.argv.find((arg) => arg.startsWith("--arch="));
  if (equalsArg) {
    return equalsArg.split("=")[1];
  }
  return "x64";
}

async function copyDir(source, destination) {
  await fs.mkdir(destination, { recursive: true });
  const entries = await fs.readdir(source, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.name === ".DS_Store") continue;
    const sourcePath = path.join(source, entry.name);
    const destinationPath = path.join(destination, entry.name);
    if (entry.isDirectory()) {
      await copyDir(sourcePath, destinationPath);
    } else if (entry.isFile()) {
      await fs.copyFile(sourcePath, destinationPath);
    }
  }
}

function unzip(zipPath, destination) {
  return new Promise((resolve, reject) => {
    const child = spawn("unzip", ["-q", zipPath, "-d", destination], {
      stdio: ["ignore", "pipe", "pipe"]
    });
    let stderr = "";
    child.stderr.setEncoding("utf8");
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(stderr.trim() || `unzip exited with code ${code}`));
      }
    });
  });
}

async function packageWindows() {
  const arch = parseArch();
  const outDir = path.join(root, "dist", `PromptDock-win32-${arch}`);
  const resourcesDir = path.join(outDir, "resources");
  const appDir = path.join(resourcesDir, "app");

  await fs.rm(outDir, { recursive: true, force: true });
  await fs.mkdir(outDir, { recursive: true });

  const artifact = await downloadArtifact({
    version: electronVersion,
    platform: "win32",
    arch,
    artifactName: "electron"
  });

  await unzip(artifact, outDir);
  await fs.rename(path.join(outDir, "electron.exe"), path.join(outDir, "PromptDock.exe"));
  await fs.rm(path.join(resourcesDir, "default_app.asar"), { force: true });
  await fs.rm(path.join(outDir, "LICENSE"), { force: true });

  await fs.mkdir(appDir, { recursive: true });
  await copyDir(path.join(root, "src"), path.join(appDir, "src"));
  await fs.copyFile(path.join(root, "README.md"), path.join(appDir, "README.md"));
  await fs.writeFile(path.join(appDir, "package.json"), JSON.stringify({
    name: "promptdock-windows",
    productName: "PromptDock",
    version: require(path.join(root, "package.json")).version,
    main: "src/main/main.js"
  }, null, 2), "utf8");

  console.log(`Windows package created: ${outDir}`);
  console.log(`Executable: ${path.join(outDir, "PromptDock.exe")}`);
}

packageWindows().catch((error) => {
  console.error(error);
  process.exit(1);
});
