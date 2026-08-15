/**
 * Coerce selection values to string at the Choices API boundary.
 * Stable `setChoiceByValue` / comparisons.
 */
export declare function normalizeValue(value: unknown): string | null;
export declare function normalizeValues(value: unknown): string[];
/**
 * Normalize Choices `getValue(true)` result for single select.
 */
export declare function normalizeSingleFromGetValue(raw: unknown): string | null;
//# sourceMappingURL=normalize-value.d.ts.map