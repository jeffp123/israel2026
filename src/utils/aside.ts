// A paragraph/list item written entirely as "[bracketed]" text is one of my
// after-the-trip notes inside a journal entry. Detect it and strip the brackets
// (they're only an authoring marker; the styling replaces them).
export function parseAside(html: string): { html: string; aside: boolean } {
  const trimmed = html.trim();
  const text = trimmed.replace(/<[^>]*>/g, '').trim();
  if (!(text.startsWith('[') && text.endsWith(']'))) return { html: trimmed, aside: false };
  const stripped = trimmed
    .replace(/^((?:\s*<[^>]+>)*\s*)\[/, '$1')
    .replace(/\](\s*(?:<\/[^>]+>\s*)*)$/, '$1');
  return { html: stripped, aside: true };
}
