import { module, test } from 'qunit';
import { setupRenderingTest } from 'test-app/tests/helpers';
import { click, render, settled, clearRender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import Choices from 'choices-ember/components/choices';

class Option {
  @tracked value: string;
  @tracked label: string;
  @tracked disabled?: boolean;

  constructor(value: string, label: string, disabled = false) {
    this.value = value;
    this.label = label;
    this.disabled = disabled;
  }
}

class Context {
  @tracked options: { value: string; label: string; disabled?: boolean }[] = [
    { value: '1', label: 'One' },
    { value: '2', label: 'Two' },
    { value: '3', label: 'Three' },
  ];
  @tracked selected: string | null = null;
  onChangeCount = 0;
  lastChange: string | string[] | null | undefined = undefined;

  onChange = (value: string | string[] | null) => {
    this.onChangeCount++;
    this.lastChange = value;
    this.selected = value as string | null;
  };
}

function selectedLabel(): string | null | undefined {
  return document
    .querySelector('.choices__list--single .choices__item')
    ?.textContent?.trim();
}

function choiceLabels(): string[] {
  return Array.from(
    document.querySelectorAll(
      '.choices__list--dropdown .choices__item--choice',
    ),
  )
    .map((el) => el.textContent?.trim() ?? '')
    .filter(Boolean);
}

module('Integration | Component | Choices', function (hooks) {
  setupRenderingTest(hooks);

  test('controlled value from outside updates UI without spurious onChange loop', async function (assert) {
    const ctx = new Context();
    ctx.selected = '1';

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @placeholder='Pick one'
        />
      </template>,
    );

    assert.strictEqual(selectedLabel(), 'One', 'initial controlled value shown');
    const changesAfterRender = ctx.onChangeCount;

    ctx.selected = '2';
    await settled();

    assert.strictEqual(selectedLabel(), 'Two', 'UI updates when @value changes');
    assert.strictEqual(
      ctx.onChangeCount,
      changesAfterRender,
      'programmatic @value change does not fire onChange',
    );
  });

  test('options replace shows new labels in dropdown', async function (assert) {
    const ctx = new Context();
    ctx.selected = '1';

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    // Open dropdown
    await click('.choices');
    const initial = choiceLabels();
    assert.ok(initial.includes('One'), 'initial option One present');
    assert.ok(initial.includes('Two'), 'initial option Two present');
    assert.ok(initial.includes('Three'), 'initial option Three present');

    ctx.options = [
      { value: 'a', label: 'Alpha' },
      { value: 'b', label: 'Beta' },
    ];
    ctx.selected = 'a';
    await settled();

    await click('.choices');
    const labels = choiceLabels();
    assert.ok(labels.includes('Alpha'), 'new option Alpha present');
    assert.ok(labels.includes('Beta'), 'new option Beta present');
    assert.notOk(labels.includes('Two'), 'old option Two gone');
    assert.strictEqual(selectedLabel(), 'Alpha', 'selection shows new option');
  });

  test('nested tracked label updates dropdown text', async function (assert) {
    const item = new Option('1', 'Original');
    const ctx = new Context();
    ctx.options = [item, new Option('2', 'Other')];
    ctx.selected = '1';

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    assert.strictEqual(selectedLabel(), 'Original');

    item.label = 'Updated';
    await settled();

    assert.strictEqual(
      selectedLabel(),
      'Updated',
      'selected item label updates after nested tracked field change',
    );

    await click('.choices');
    assert.ok(
      choiceLabels().includes('Updated'),
      'dropdown list shows updated label',
    );
  });

  test('destroy removes Choices DOM; remount works', async function (assert) {
    const ctx = new Context();
    ctx.selected = '1';
    ctx.options = [
      { value: '1', label: 'One' },
      { value: '2', label: 'Two' },
    ];

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    assert.dom('.choices').exists('Choices container mounted');

    await clearRender();

    assert.dom('.choices').doesNotExist('Choices container removed after clear');
    // No leftover errors — if destroy failed, subsequent remount would throw
    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    assert.dom('.choices').exists('Choices remounts cleanly');
    assert.strictEqual(selectedLabel(), 'One');
  });

  test('feedback loop: parent sets @value inside onChange without infinite loop', async function (assert) {
    const ctx = new Context();
    ctx.selected = null;
    // onChange already sets selected — classic controlled loop risk
    let maxSafe = 50;
    const original = ctx.onChange;
    ctx.onChange = (value) => {
      maxSafe--;
      if (maxSafe <= 0) {
        throw new Error('onChange feedback loop exceeded safety limit');
      }
      original(value);
    };

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    await click('.choices');
    // Click a choice item (not the selected placeholder row)
    const choice = Array.from(
      document.querySelectorAll(
        '.choices__list--dropdown .choices__item--choice',
      ),
    ).find((el) => el.textContent?.trim() === 'Two');
    assert.ok(choice, 'found Two choice');
    await click(choice as Element);
    await settled();

    assert.strictEqual(ctx.selected, '2');
    assert.strictEqual(selectedLabel(), 'Two');
    assert.ok(
      ctx.onChangeCount >= 1 && ctx.onChangeCount < 10,
      `onChange fired a bounded number of times (got ${ctx.onChangeCount})`,
    );
    assert.ok(maxSafe > 0, 'did not hit infinite loop safety limit');
  });
});
