import { module, test } from 'qunit';
import { setupRenderingTest } from 'test-app/tests/helpers';
import { render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import ChoicesFieldset from 'choices-ember/components/choices-fieldset';

class Context {
  @tracked options = [
    { value: '1', label: 'One' },
    { value: '2', label: 'Two' },
  ];
  @tracked selected: string | null = '1';
  onChange = (v: string | string[] | null) => {
    this.selected = v as string | null;
  };
}

function selectedLabel(): string | null | undefined {
  return document
    .querySelector('.choices__list--single .choices__item')
    ?.textContent?.trim();
}

module('Integration | Component | ChoicesFieldset', function (hooks) {
  setupRenderingTest(hooks);

  test('fieldset renders legend and description', async function (assert) {
    const ctx = new Context();

    await render(
      <template>
        <ChoicesFieldset
          @legend="Charge code"
          @description="Search by name or id"
          @type="single"
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    assert.dom('fieldset.fieldset').exists();
    assert.dom('legend.fieldset-legend').hasText('Charge code');
    assert.dom('p.label').hasText('Search by name or id');
    assert.dom('.choices').exists('inner Choices mounted');
  });

  test('named blocks for legend and description', async function (assert) {
    const ctx = new Context();

    await render(
      <template>
        <ChoicesFieldset
          @type="single"
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        >
          <:legend>Custom legend</:legend>
          <:description>Custom help</:description>
        </ChoicesFieldset>
      </template>,
    );

    assert.dom('legend.fieldset-legend').hasText('Custom legend');
    assert.dom('p.label').hasText('Custom help');
  });

  test('pass-through value updates selection via shared bridge', async function (assert) {
    const ctx = new Context();
    ctx.selected = '1';

    await render(
      <template>
        <ChoicesFieldset
          @legend="Pick"
          @type="single"
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    assert.strictEqual(selectedLabel(), 'One');
    ctx.selected = '2';
    await settled();
    assert.strictEqual(selectedLabel(), 'Two');
  });

  test('label associates via for/id', async function (assert) {
    const ctx = new Context();

    await render(
      <template>
        <ChoicesFieldset
          @label="Station"
          @type="single"
          @options={{ctx.options}}
          @value={{ctx.selected}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    const label = document.querySelector('label.label');
    const forId = label?.getAttribute('for');
    assert.ok(forId, 'label has for');
    assert.dom(`#${forId}`).exists('host control has matching id');
  });
});
