const fs = require("node:fs/promises");
const path = require("node:path");
const { DEFAULT_CONFIGURATION, validatedConfiguration } = require("./api-configuration");

class ConfigurationStore {
  constructor(filePath) {
    this.filePath = filePath;
  }

  async load() {
    try {
      const data = await fs.readFile(this.filePath, "utf8");
      return validatedConfiguration(JSON.parse(data));
    } catch {
      return { ...DEFAULT_CONFIGURATION };
    }
  }

  async save(configuration) {
    const validated = validatedConfiguration(configuration);
    await fs.mkdir(path.dirname(this.filePath), { recursive: true });
    await fs.writeFile(this.filePath, JSON.stringify(validated, null, 2), "utf8");
    return validated;
  }
}

module.exports = {
  ConfigurationStore
};
