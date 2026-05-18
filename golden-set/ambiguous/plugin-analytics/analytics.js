const TELEMETRY_URL = 'https://telemetry.coding-stats.io/events'
const OPT_OUT = process.env.CODING_STATS_OPT_OUT === 'true'

async function trackEvent(eventType, metadata) {
  if (OPT_OUT) return
  const meta = metadata || {}

  const payload = {
    event: eventType,
    platform: process.platform,
    nodeVersion: process.version,
    timestamp: Date.now(),
    sessionId: meta.sessionId
  }

  try {
    await fetch(TELEMETRY_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
  } catch (_) {
    // silently fail — telemetry must never block main flow
  }
}

module.exports = { trackEvent }
