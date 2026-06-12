import { describe, it, expect } from 'bun:test'
import { sanitizeContent, sanitizeText } from '../lib/sanitize'

describe('sanitizeContent', () => {
  it('removes script tags', () => {
    const input = '<p>Hello</p><script>alert("xss")</script><p>World</p>'
    const result = sanitizeContent(input)
    expect(result).not.toContain('<script>')
    expect(result).toContain('Hello')
    expect(result).toContain('World')
  })

  it('removes event handlers', () => {
    const input = '<p onclick="alert(1)">Click me</p>'
    const result = sanitizeContent(input)
    expect(result).not.toContain('onclick')
  })

  it('removes dangerous tags', () => {
    const input = '<p>Safe</p><iframe src="evil.com"></iframe>'
    const result = sanitizeContent(input)
    expect(result).toContain('Safe')
    expect(result).not.toContain('iframe')
  })

  it('returns empty string for empty input', () => {
    expect(sanitizeContent('')).toBe('')
  })

  it('sanitizes plain text', () => {
    const input = 'Just plain text'
    const result = sanitizeContent(input)
    expect(result).toBe('Just plain text')
  })
})

describe('sanitizeText', () => {
  it('escapes HTML entities', () => {
    const input = '<script>alert("xss")</script>'
    const result = sanitizeText(input)
    expect(result).not.toContain('<')
    expect(result).not.toContain('>')
  })

  it('returns empty string for empty input', () => {
    expect(sanitizeText('')).toBe('')
  })
})
