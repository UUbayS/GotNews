/**
 * Encodes a Date and ID into a Base64 string for cursor pagination
 */
export function encodeCursor(createdAt: Date, id: string): string {
  const payload = JSON.stringify({ createdAt: createdAt.toISOString(), id })
  return Buffer.from(payload).toString('base64')
}

/**
 * Decodes a Base64 string back into Date and ID
 */
export function decodeCursor(cursor: string): { createdAt: Date; id: string } | null {
  try {
    const payload = Buffer.from(cursor, 'base64').toString('ascii')
    const parsed = JSON.parse(payload)
    
    if (parsed.createdAt && parsed.id) {
      return {
        createdAt: new Date(parsed.createdAt),
        id: parsed.id
      }
    }
    return null
  } catch (e) {
    return null
  }
}
