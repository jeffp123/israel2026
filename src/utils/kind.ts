export type Kind = 'journal' | 'recollection' | 'family';

// Label shown in the badge under an entry's title.
export function kindLabel(kind: Kind | undefined, author?: string): string {
  if (kind === 'journal') return 'From my journal';
  if (kind === 'family') return author ? `By ${author}` : 'From the family';
  return 'Written from memory';
}
