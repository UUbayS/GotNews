const SCRIPT_TAG_REGEX = /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi
const EVENT_HANDLER_REGEX = /\s+on\w+\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)/gi
const DANGEROUS_TAGS_REGEX = /<(iframe|object|embed|form|input|button|select|textarea)\b[^>]*>/gi
const HTML_TAG_REGEX = /<[^>]+>/g
const MULTIPLE_SPACES_REGEX = /\s{2,}/g
const MULTIPLE_NEWLINES_REGEX = /\n{3,}/g

export function sanitizeContent(html: string): string {
  if (!html) return ''

  let clean = html
    .replace(SCRIPT_TAG_REGEX, '')
    .replace(EVENT_HANDLER_REGEX, '')
    .replace(DANGEROUS_TAGS_REGEX, '')

  const isRichText = /<[a-z][\s\S]*>/i.test(clean)

  if (!isRichText) {
    return clean
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(MULTIPLE_SPACES_REGEX, ' ')
      .trim()
  }

  return clean
    .replace(HTML_TAG_REGEX, (match) => {
      const tag = match.toLowerCase()
      if (['<p>', '</p>', '<br>', '<br/>', '<br />', '<strong>', '</strong>', '<em>', '</em>', '<b>', '</b>', '<i>', '</i>', '<blockquote>', '</blockquote>', '<ul>', '</ul>', '<ol>', '</ol>', '<li>', '</li>', '<h1>', '<h2>', '<h3>', '<h4>', '<h5>', '<h6>', '</h1>', '</h2>', '</h3>', '</h4>', '</h5>', '</h6>', '<a', '</a>', '<figure>', '</figure>', '<figcaption>', '</figcaption>', '<img'].some(allowed => tag.startsWith(allowed))) {
        return match
      }
      return ''
    })
    .replace(MULTIPLE_SPACES_REGEX, ' ')
    .replace(MULTIPLE_NEWLINES_REGEX, '\n\n')
    .trim()
}

export function sanitizeText(text: string): string {
  if (!text) return ''
  return text
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .trim()
}
