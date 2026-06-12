import { describe, it, expect } from 'bun:test'
import { logger } from '../lib/logger'

describe('logger', () => {
  it('has all log methods', () => {
    expect(typeof logger.info).toBe('function')
    expect(typeof logger.warn).toBe('function')
    expect(typeof logger.error).toBe('function')
    expect(typeof logger.debug).toBe('function')
  })

  it('does not throw on info call', () => {
    expect(() => logger.info('test message', 'TestContext')).not.toThrow()
  })

  it('does not throw on warn call', () => {
    expect(() => logger.warn('test warning', 'TestContext', { key: 'value' })).not.toThrow()
  })

  it('does not throw on error call', () => {
    expect(() => logger.error('test error', 'TestContext')).not.toThrow()
  })
})
