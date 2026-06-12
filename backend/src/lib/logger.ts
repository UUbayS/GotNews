type LogLevel = 'info' | 'warn' | 'error' | 'debug'

interface LogEntry {
  timestamp: string
  level: LogLevel
  message: string
  context?: string
  meta?: Record<string, any>
}

function formatLog(entry: LogEntry): string {
  const meta = entry.meta ? ` ${JSON.stringify(entry.meta)}` : ''
  return `[${entry.timestamp}] [${entry.level.toUpperCase()}]${entry.context ? ` [${entry.context}]` : ''} ${entry.message}${meta}`
}

export const logger = {
  info(message: string, context?: string, meta?: Record<string, any>) {
    const entry: LogEntry = { timestamp: new Date().toISOString(), level: 'info', message, context, meta }
    console.log(formatLog(entry))
  },
  warn(message: string, context?: string, meta?: Record<string, any>) {
    const entry: LogEntry = { timestamp: new Date().toISOString(), level: 'warn', message, context, meta }
    console.warn(formatLog(entry))
  },
  error(message: string, context?: string, meta?: Record<string, any>) {
    const entry: LogEntry = { timestamp: new Date().toISOString(), level: 'error', message, context, meta }
    console.error(formatLog(entry))
  },
  debug(message: string, context?: string, meta?: Record<string, any>) {
    if (process.env.NODE_ENV === 'development') {
      const entry: LogEntry = { timestamp: new Date().toISOString(), level: 'debug', message, context, meta }
      console.debug(formatLog(entry))
    }
  }
}
