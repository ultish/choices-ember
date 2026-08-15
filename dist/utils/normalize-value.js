/**
 * Coerce selection values to string at the Choices API boundary.
 * Stable `setChoiceByValue` / comparisons.
 */

function asBoundaryString(value) {
  if (value == null || value === '') {
    return null;
  }
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || typeof value === 'bigint') {
    return String(value);
  }
  // Objects / symbols are not valid choice values — drop them
  return null;
}
function normalizeValue(value) {
  return asBoundaryString(value);
}
function normalizeValues(value) {
  if (value == null) {
    return [];
  }
  if (Array.isArray(value)) {
    return value.map(v => asBoundaryString(v)).filter(v => v != null && v !== '');
  }
  const single = normalizeValue(value);
  return single == null ? [] : [single];
}

/**
 * Normalize Choices `getValue(true)` result for single select.
 */
function normalizeSingleFromGetValue(raw) {
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

export { normalizeSingleFromGetValue, normalizeValue, normalizeValues };
//# sourceMappingURL=normalize-value.js.map
