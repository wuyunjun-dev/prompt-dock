function sanitizeMessage(message) {
  return String(message ?? "")
    .replace(/Authorization:\s*Bearer\s+[A-Za-z0-9._\-+/=]+/gi, "Authorization: Bearer [REDACTED]")
    .replace(/Bearer\s+[A-Za-z0-9._\-+/=]+/gi, "Bearer [REDACTED]");
}

function limitForDisplay(message, maxLength = 500) {
  const value = String(message ?? "");
  return value.length > maxLength ? `${value.slice(0, maxLength)}...` : value;
}

module.exports = {
  sanitizeMessage,
  limitForDisplay
};
