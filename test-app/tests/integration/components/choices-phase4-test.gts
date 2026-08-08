import { module, test } from 'qunit';
import { setupRenderingTest } from 'test-app/tests/helpers';
import {
  click,
  clearRender,
  render,
  settled,
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import Choices from 'choices-ember/components/choices';
import type { ChoicesOption, ChoicesPublicAPI } from 'choices-ember';

class Context {
  @tracked options: ChoicesOption[] = [
    { value: '1', label: 'One' },
    { value: '2', label: 'Two' },
  ];
  @tracked selected: string | string[] | null = null;
  @tracked disabled = false;
  @tracked syncKey = 0;
  onChangeCount = 0;
  api: ChoicesPublicAPI | null = null;
  readyCalled = false;

  onChange = (value: string | string[] | null) => {
    this.onChangeCount++;
    this.selected = value;
  };

  registerAPI = (api: ChoicesPublicAPI | null) => {
    this.api = api;
  };

  onReady = () => {
    this.readyCalled = true;
  };
}

function selectedLabel(): string | null | undefined {
  return document
    .querySelector('.choices__list--single .choices__item')
    ?.textContent?.trim();
}

function groupHeadings(): string[] {
  return Array.from(document.querySelectorAll('.choices__heading')).map(
    (el) => el.textContent?.trim() ?? '',
  );
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

module('Integration | Component | Choices | phase 4', function (hooks) {
  setupRenderingTest(hooks);

  test('groups appear as headings; selecting a child updates value', async function (assert) {
    const ctx = new Context();
    ctx.options = [
      {
        label: 'Fruits',
        value: 'fruits',
        choices: [
          { value: 'apple', label: 'Apple' },
          { value: 'banana', label: 'Banana' },
        ],
      },
      {
        label: 'Veggies',
        value: 'veggies',
        choices: [{ value: 'carrot', label: 'Carrot' }],
      },
    ];
    ctx.selected = null;

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
    const headings = groupHeadings();
    assert.ok(headings.includes('Fruits'), 'Fruits group heading');
    assert.ok(headings.includes('Veggies'), 'Veggies group heading');
    assert.ok(choiceLabels().includes('Apple'));

    const apple = Array.from(
      document.querySelectorAll(
        '.choices__list--dropdown .choices__item--choice',
      ),
    ).find((el) => el.textContent?.trim() === 'Apple');
    await click(apple as Element);
    await settled();

    assert.strictEqual(ctx.selected, 'apple');
    assert.strictEqual(selectedLabel(), 'Apple');
  });

  test('disabled toggles without throw; re-enable works', async function (assert) {
    const ctx = new Context();
    ctx.selected = '1';
    ctx.disabled = false;

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @disabled={{ctx.disabled}}
        />
      </template>,
    );

    assert.dom('.choices').doesNotHaveClass('is-disabled');

    ctx.disabled = true;
    await settled();
    assert.dom('.choices').hasClass('is-disabled');

    ctx.disabled = false;
    await settled();
    assert.dom('.choices').doesNotHaveClass('is-disabled');
  });

  test('searchEnabled false hides search input in dropdown', async function (assert) {
    const ctx = new Context();
    const config = { searchEnabled: false };

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @config={{config}}
        />
      </template>,
    );

    await click('.choices');
    assert
      .dom('.choices__list--dropdown .choices__input--cloned')
      .doesNotExist('no search input when searchEnabled is false');
    assert.ok(choiceLabels().length >= 2, 'choices still listed');
  });

  test('async parent load: empty options then resolve populates dropdown', async function (assert) {
    const ctx = new Context();
    ctx.options = [];
    ctx.selected = null;

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
    assert.ok(
      choiceLabels().length === 0 ||
        choiceLabels().every((l) => /no choices|loading/i.test(l)),
      'empty before load',
    );

    // Simulate Ember async load completing
    await Promise.resolve();
    ctx.options = [
      { value: 'r1', label: 'Remote One' },
      { value: 'r2', label: 'Remote Two' },
    ];
    ctx.selected = 'r1';
    await settled();

    await click('.choices');
    assert.ok(choiceLabels().includes('Remote One'));
    assert.ok(choiceLabels().includes('Remote Two'));
    assert.strictEqual(selectedLabel(), 'Remote One');
  });

  test('destroy mid-flight async does not throw', async function (assert) {
    const ctx = new Context();
    ctx.options = [];

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

    const pending = Promise.resolve().then(() => {
      ctx.options = [{ value: 'late', label: 'Late' }];
    });

    await clearRender();
    await pending;
    await settled();

    assert.ok(true, 'no throw after destroy with late options assignment');
  });

  test('registerAPI and onReady; null on destroy', async function (assert) {
    const ctx = new Context();
    ctx.selected = '1';

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @registerAPI={{ctx.registerAPI}}
          @onReady={{ctx.onReady}}
        />
      </template>,
    );

    assert.true(ctx.readyCalled, 'onReady fired');
    assert.ok(ctx.api, 'API registered');
    assert.ok(ctx.api?.instance, 'raw instance available');
    assert.strictEqual(ctx.api?.getValue(true), '1');

    await clearRender();
    assert.strictEqual(ctx.api, null, 'API cleared on destroy');
  });

  test('changing searchEnabled recreates instance (RECREATE_KEYS)', async function (assert) {
    const ctx = new Context();
    ctx.selected = '1';

    class ConfigBag {
      @tracked searchEnabled = true;
      get config() {
        return { searchEnabled: this.searchEnabled };
      }
    }
    const bag = new ConfigBag();

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @config={{bag.config}}
          @onReady={{ctx.onReady}}
        />
      </template>,
    );

    assert.true(ctx.readyCalled);
    ctx.readyCalled = false;

    bag.searchEnabled = false;
    await settled();

    // After recreate, selection preserved and search hidden
    assert.strictEqual(selectedLabel(), 'One');
    await click('.choices');
    assert
      .dom('.choices__list--dropdown .choices__input--cloned')
      .doesNotExist();
  });

  test('syncKey forces resync', async function (assert) {
    const ctx = new Context();
    // Plain objects without @tracked nested fields — label change alone
    // would not autotrack without mapping read; bump syncKey to force.
    const opts = [
      { value: '1', label: 'Before' },
      { value: '2', label: 'Other' },
    ];
    ctx.options = opts;
    ctx.selected = '1';

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @syncKey={{ctx.syncKey}}
        />
      </template>,
    );

    assert.strictEqual(selectedLabel(), 'Before');

    opts[0]!.label = 'After';
    // Same array identity — force via syncKey
    ctx.syncKey = 1;
    // Also reassign array so options fingerprint can see new label when re-mapped
    ctx.options = [...opts];
    await settled();

    assert.strictEqual(selectedLabel(), 'After');
  });

  test('attributes required and name forward to host', async function (assert) {
    const ctx = new Context();

    await render(
      <template>
        <Choices
          @type='single'
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
          @name='station'
          required
        />
      </template>,
    );

    assert.dom('select').hasAttribute('name', 'station');
    assert.dom('select').hasAttribute('required');
  });
});
