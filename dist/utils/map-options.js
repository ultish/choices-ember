import { normalizeValue } from './normalize-value.js';

function isGroup(option) {
  return option != null && typeof option === 'object' && Array.isArray(option.choices);
}
function toLabelText(label) {
  if (label == null) {
    return '';
  }
  if (typeof label === 'string' || typeof label === 'number' || typeof label === 'boolean') {
    return String(label);
  }
  return '';
}

/**
 * Map Ember/domain option objects to plain Choices InputChoice / InputGroup
 * snapshots. **Reads** value, label, disabled, selected, placeholder,
 * customProperties, and group fields so nested tracked properties invalidate
 * the bridge.
 */
function mapOptions(options) {
  if (!options?.length) {
    return [];
  }
  return options.map(option => {
    if (isGroup(option)) {
      // Read group fields for autotracking
      const groupLabel = option.label;
      const groupDisabled = option.disabled;
      const groupValue = option.value;
      const groupId = option.id;
      const groupActive = option.active;
      const childChoices = option.choices ?? [];
      return {
        ...(groupId !== undefined ? {
          id: groupId
        } : {}),
        ...(groupActive !== undefined ? {
          active: groupActive
        } : {}),
        label: toLabelText(groupLabel),
        value: normalizeValue(groupValue) ?? '',
        disabled: Boolean(groupDisabled),
        choices: childChoices.map(mapChoice)
      };
    }
    return mapChoice(option);
  });
}
function mapChoice(choice) {
  // Explicit reads for autotracking on nested tracked domain objects
  const value = normalizeValue(choice.value) ?? '';
  const label = toLabelText(choice.label);
  const disabled = Boolean(choice.disabled);
  const selected = Boolean(choice.selected);
  const placeholder = Boolean(choice.placeholder);
  const customProperties = choice.customProperties;
  const id = choice.id;
  const labelClass = choice.labelClass;
  const labelDescription = choice.labelDescription;
  const active = choice.active;
  const highlighted = choice.highlighted;
  const mapped = {
    value,
    label,
    disabled,
    selected,
    placeholder
  };
  if (customProperties !== undefined) {
    mapped.customProperties = customProperties;
  }
  if (id !== undefined) {
    mapped.id = id;
  }
  if (labelClass !== undefined) {
    mapped.labelClass = labelClass;
  }
  if (labelDescription !== undefined) {
    mapped.labelDescription = labelDescription;
  }
  if (active !== undefined) {
    mapped.active = active;
  }
  if (highlighted !== undefined) {
    mapped.highlighted = highlighted;
  }
  return mapped;
}

export { mapOptions };
//# sourceMappingURL=map-options.js.map
