/**
 * Coerce selection values to string at the Choices API boundary.
 * Stable `setChoiceByValue` / comparisons.
 */

export function normalizeValue(value: unknown): string | null {
  if (value == null || value === '') {
    return null;
  }
  return String(value);
}

export function normalizeValues(value: unknown): string[] {
  if (value == null) {
    return [];
  }
  if (Array.isArray(value)) {
    return value.map((v) => String(v)).filter((v) => v !== '');
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
    return String(raw[0]);
  }
  return String(raw);
}
