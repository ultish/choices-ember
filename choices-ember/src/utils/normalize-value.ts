/**
 * Coerce selection values to string at the Choices API boundary.
 * Stable `setChoiceByValue` / comparisons.
 */

function asBoundaryString(value: unknown): string | null {
  if (value == null || value === '') {
    return null;
  }
  if (
    typeof value === 'string' ||
    typeof value === 'number' ||
    typeof value === 'boolean' ||
    typeof value === 'bigint'
  ) {
    return String(value);
  }
  // Objects / symbols are not valid choice values — drop them
  return null;
}

export function normalizeValue(value: unknown): string | null {
  return asBoundaryString(value);
}

export function normalizeValues(value: unknown): string[] {
  if (value == null) {
    return [];
  }
  if (Array.isArray(value)) {
    return value
      .map((v) => asBoundaryString(v))
      .filter((v): v is string => v != null && v !== '');
  }
  const single = normalizeValue(value);
  return single == null ? [] : [single];
}

/**
 * Normalize Choices `getValue(true)` result for single select.
 */
export function normalizeSingleFromGetValue(raw: unknown): string | null {
  if (raw == null || raw === '') {
    return null;
  }
  if (Array.isArray(raw)) {
    if (raw.length === 0) {
      return null;
    }
    return asBoundaryString(raw[0]);
  }
  return asBoundaryString(raw);
}
