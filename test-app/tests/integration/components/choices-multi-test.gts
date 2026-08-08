import { module, test } from 'qunit';
import { setupRenderingTest } from 'test-app/tests/helpers';
import { click, render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import Choices from 'choices-ember/components/choices';

class MultiContext {
  @tracked options: { value: string; label: string }[] = [
    { value: '1', label: 'One' },
    { value: '2', label: 'Two' },
    { value: '3', label: 'Three' },
  ];
  @tracked selected: string[] = [];
  onChangeCount = 0;
  lastChange: string | string[] | null | undefined = undefined;
  lastAdd: string | undefined;
  lastRemove: string | undefined;

  onChange = (value: string | string[] | null) => {
    this.onChangeCount++;
    this.lastChange = value;
    this.selected = Array.isArray(value) ? value : value == null ? [] : [String(value)];
  };

  onAdd = (detail: { value?: unknown }) => {
    this.lastAdd = detail?.value != null ? String(detail.value) : undefined;
  };

  onRemove = (detail: { value?: unknown }) => {
    this.lastRemove = detail?.value != null ? String(detail.value) : undefined;
  };
}

function selectedItemLabels(): string[] {
  return Array.from(
    document.querySelectorAll('.choices__list--multiple .choices__item'),
  )
    .map((el) => {
      // Button text is often empty/"Remove item"; prefer data-value or clone without button
      const value = el.getAttribute('data-value');
      if (value) {
        // Label is text content minus button
        const clone = el.cloneNode(true) as HTMLElement;
        clone.querySelector('button')?.remove();
        return clone.textContent?.trim() ?? value;
      }
      const clone = el.cloneNode(true) as HTMLElement;
      clone.querySelector('button')?.remove();
      return clone.textContent?.trim() ?? '';
    })
    .filter(Boolean);
}

function selectedValuesFromDom(): string[] {
  return Array.from(
    document.querySelectorAll('.choices__list--multiple .choices__item[data-value]'),
  )
    .map((el) => el.getAttribute('data-value') ?? '')
    .filter(Boolean);
}

async function openDropdown(): Promise<void> {
  await click('.choices');
}

async function pickChoiceByLabel(label: string): Promise<void> {
  await openDropdown();
  const choice = Array.from(
    document.querySelectorAll(
      '.choices__list--dropdown .choices__item--choice',
    ),
  ).find((el) => el.textContent?.trim() === label);
  if (!choice) {
    throw new Error(`Choice not found: ${label}`);
  }
  await click(choice);
  await settled();
}

module('Integration | Component | Choices | multiple', function (hooks) {
  setupRenderingTest(hooks);

  test('multi user select fires onChange with both string values', async function (assert) {
    const ctx = new MultiContext();

    await render(
      <template>
        <Choices
          @type='multiple'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @onAdd={{ctx.onAdd}}
          @onRemove={{ctx.onRemove}}
        />
      </template>,
    );

    await pickChoiceByLabel('One');
    await pickChoiceByLabel('Two');

    assert.deepEqual(
      [...ctx.selected].sort(),
      ['1', '2'],
      'controlled value holds both selections',
    );
    assert.ok(ctx.onChangeCount >= 2, 'onChange fired for selections');
    assert.deepEqual(
      selectedValuesFromDom().sort(),
      ['1', '2'],
      'DOM chips match selection',
    );
    assert.strictEqual(ctx.lastAdd, '2', 'onAdd received last added value');
  });

  test('multi controlled from outside updates chips without onChange loop', async function (assert) {
    const ctx = new MultiContext();
    ctx.selected = ['1'];

    await render(
      <template>
        <Choices
          @type='multiple'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    assert.deepEqual(selectedValuesFromDom(), ['1']);
    const changesAfterRender = ctx.onChangeCount;

    ctx.selected = ['2', '3'];
    await settled();

    assert.deepEqual(
      selectedValuesFromDom().sort(),
      ['2', '3'],
      'UI matches programmatic multi value',
    );
    assert.strictEqual(
      ctx.onChangeCount,
      changesAfterRender,
      'programmatic multi value change does not fire onChange',
    );
  });

  test('multi remove button fires onChange with remaining values', async function (assert) {
    const ctx = new MultiContext();
    ctx.selected = ['1', '2'];

    await render(
      <template>
        <Choices
          @type='multiple'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @onRemove={{ctx.onRemove}}
        />
      </template>,
    );

    assert.deepEqual(selectedValuesFromDom().sort(), ['1', '2']);

    const removeBtn = document.querySelector(
      '.choices__list--multiple .choices__item[data-value="1"] button',
    );
    assert.ok(removeBtn, 'remove button present (default removeItemButton)');
    await click(removeBtn as Element);
    await settled();

    assert.deepEqual(ctx.selected, ['2'], 'remaining value after remove');
    assert.deepEqual(selectedValuesFromDom(), ['2']);
    assert.strictEqual(ctx.lastRemove, '1', 'onRemove received removed value');
  });

  test('config can disable removeItemButton', async function (assert) {
    const ctx = new MultiContext();
    ctx.selected = ['1'];
    const config = { removeItemButton: false };

    await render(
      <template>
        <Choices
          @type='multiple'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @config={{config}}
        />
      </template>,
    );

    assert
      .dom('.choices__list--multiple .choices__item button')
      .doesNotExist('remove button suppressed via @config');
  });

  test('maxItemCount via @config is respected', async function (assert) {
    const ctx = new MultiContext();
    const config = { maxItemCount: 2 };

    await render(
      <template>
        <Choices
          @type='multiple'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @config={{config}}
        />
      </template>,
    );

    await pickChoiceByLabel('One');
    await pickChoiceByLabel('Two');
    assert.strictEqual(ctx.selected.length, 2);

    // Third add should be blocked (or not increase value length)
    try {
      await pickChoiceByLabel('Three');
    } catch {
      // dropdown may not offer it / click may fail — either way length stays 2
    }
    await settled();

    assert.ok(
      ctx.selected.length <= 2,
      `maxItemCount blocks third item (got ${ctx.selected.length})`,
    );
    assert.deepEqual(
      [...ctx.selected].sort(),
      ['1', '2'],
      'only first two remain when limited',
    );
  });

  test('switching @type from single to multiple recreates the instance', async function (assert) {
    class TypeCtx {
      @tracked type: 'single' | 'multiple' = 'single';
      @tracked options = [
        { value: '1', label: 'One' },
        { value: '2', label: 'Two' },
      ];
      @tracked selected: string | string[] | null = '1';
      onChange = (v: string | string[] | null) => {
        this.selected = v;
      };
    }
    const ctx = new TypeCtx();

    await render(
      <template>
        <Choices
          @type={{ctx.type}}
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    assert.dom('select').doesNotHaveAttribute('multiple');
    assert.dom('.choices__list--single').exists();

    ctx.type = 'multiple';
    ctx.selected = ['1', '2'];
    await settled();

    assert.dom('select').hasAttribute('multiple');
    assert.dom('.choices__list--multiple').exists();
    assert.deepEqual(selectedValuesFromDom().sort(), ['1', '2']);
  });

  test('nested tracked label updates multi option list', async function (assert) {
    class Opt {
      @tracked value: string;
      @tracked label: string;
      constructor(value: string, label: string) {
        this.value = value;
        this.label = label;
      }
    }
    const a = new Opt('a', 'Alpha');
    const ctx = new MultiContext();
    ctx.options = [a, { value: 'b', label: 'Beta' }];
    ctx.selected = ['a'];

    await render(
      <template>
        <Choices
          @type='multiple'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    assert.ok(selectedItemLabels().some((l) => l.includes('Alpha')));

    a.label = 'Alpha-Updated';
    await settled();

    assert.ok(
      selectedItemLabels().some((l) => l.includes('Alpha-Updated')),
      'selected chip label updates from nested tracked field',
    );
  });
});
