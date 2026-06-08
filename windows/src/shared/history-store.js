const fs = require("node:fs/promises");
const path = require("node:path");
const crypto = require("node:crypto");

class HistoryStore {
  constructor(filePath) {
    this.filePath = filePath;
  }

  async load() {
    try {
      const data = await fs.readFile(this.filePath, "utf8");
      const items = JSON.parse(data);
      return Array.isArray(items) ? items : [];
    } catch (error) {
      if (error.code === "ENOENT") return [];
      throw new Error(`历史记录错误：${error.message}`);
    }
  }

  async save(items) {
    await fs.mkdir(path.dirname(this.filePath), { recursive: true });
    await fs.writeFile(this.filePath, JSON.stringify(items, null, 2), "utf8");
  }

  async append(request, result) {
    const items = await this.load();
    const item = {
      id: crypto.randomUUID(),
      request,
      result,
      createdAt: new Date().toISOString()
    };
    items.unshift(item);
    await this.save(items);
    return item;
  }

  async delete(ids) {
    const idSet = new Set(Array.isArray(ids) ? ids : [ids]);
    if (idSet.size === 0) return 0;
    const items = await this.load();
    const nextItems = items.filter((item) => !idSet.has(item.id));
    await this.save(nextItems);
    return items.length - nextItems.length;
  }

  async clear() {
    try {
      await fs.unlink(this.filePath);
    } catch (error) {
      if (error.code !== "ENOENT") {
        throw new Error(`历史记录错误：${error.message}`);
      }
    }
  }
}

module.exports = {
  HistoryStore
};
