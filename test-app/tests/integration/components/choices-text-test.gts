import { module, test } from 'qunit';
import { setupRenderingTest } from 'test-app/tests/helpers';
import {
  click,
  fillIn,
  render,
  settled,
  triggerKeyEvent,
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import Choices from 'choices-ember/components/choices';

class TextContext {
  @tracked tags: string[] = [];
  onChangeCount = 0;
  lastChange: string | string[] | null | undefined = undefined;

  onChange = (value: string | string[] | null) => {
    this.onChangeCount++;
    this.lastChange = value;
    this.tags = Array.isArray(value) ? value : value == null ? [] : [String(value)];
  };
}

function tagValues(): string[] {
  return Array.from(
    document.querySelectorAll(
      '.choices__list--multiple .choices__item[data-value], .choices__list .choices__item[data-value]',
    ),
  )
    .map((el) => el.getAttribute('data-value') ?? '')
    .filter(Boolean);
}

function textInput(): HTMLInputElement {
  const el =
    document.querySelector<HTMLInputElement>('.choices__input--cloned') ??
    document.querySelector<HTMLInputElement>('.choices input[type="text"]') ??
    document.querySelector<HTMLInputElement>('input[type="text"]');
  if (!el) {
    throw new Error('text input not found');
  }
  return el;
}

async function addTag(text: string): Promise<void> {
  const input = textInput();
  // Focus first so Choices opens the text "add" UI; Enter only commits when
  // the dropdown/input path is active (Choices 11).
  input.focus();
  await settled();
  await fillIn(input, text);
  await settled();
  await triggerKeyEvent(input, 'keydown', 'Enter');
  await settled();
}

module('Integration | Component | Choices | text', function (hooks) {
  setupRenderingTest(hooks);

  test('text add tag fires onChange with new value', async function (assert) {
    const ctx = new TextContext();

    await render(
      <template>
        <Choices
          @type='text'
          @value={{ctx.tags}}
          @onChange={{ctx.onChange}}
          @placeholder='Add a tag'
        />
      </template>,
    );

    assert.dom('.choices').exists();
    await addTag('hello');

    assert.ok(ctx.tags.includes('hello'), `tags include hello (got ${JSON.stringify(ctx.tags)})`);
    assert.ok(ctx.onChangeCount >= 1, 'onChange fired');
    assert.ok(tagValues().includes('hello'), 'DOM shows tag');
  });

  test('text controlled from outside updates tags without loop', async function (assert) {
    const ctx = new TextContext();
    ctx.tags = ['a', 'b'];

    await render(
      <template>
        <Choices @type='text' @value={{ctx.tags}} @onChange={{ctx.onChange}} />
      </template>,
    );

    assert.deepEqual(tagValues().sort(), ['a', 'b']);
    const afterRender = ctx.onChangeCount;

    ctx.tags = ['x'];
    await settled();

    assert.deepEqual(tagValues(), ['x']);
    assert.strictEqual(
      ctx.onChangeCount,
      afterRender,
      'programmatic tags update does not fire onChange',
    );
  });

  test('text maxItemCount via @config limits tags', async function (assert) {
    const ctx = new TextContext();
    // Start at the limit via controlled value (avoids flaky Enter timing),
    // then assert the UI path cannot grow past maxItemCount.
    ctx.tags = ['one', 'two'];
    const config = { maxItemCount: 2, removeItemButton: true };

    await render(
      <template>
        <Choices
          @type='text'
          @value={{ctx.tags}}
          @onChange={{ctx.onChange}}
          @config={{config}}
        />
      </template>,
    );

    assert.strictEqual(ctx.tags.length, 2, 'starts at maxItemCount');
    assert.deepEqual(tagValues().sort(), ['one', 'two']);

    await addTag('three');
    await settled();

    assert.strictEqual(
      ctx.tags.length,
      2,
      `maxItemCount blocks third tag (got ${JSON.stringify(ctx.tags)})`,
    );
    assert.notOk(ctx.tags.includes('three'), 'third tag not accepted');
  });

  test('text ignores @options without throwing', async function (assert) {
    const ctx = new TextContext();
    const options = [
      { value: '1', label: 'One' },
      { value: '2', label: 'Two' },
    ];

    await render(
      <template>
        <Choices
          @type='text'
          @options={{options}}
          @value={{ctx.tags}}
          @onChange={{ctx.onChange}}
        />
      </template>,
    );

    await addTag('ok');
    assert.ok(ctx.tags.includes('ok'));
  });

  test('default removeItemButton allows removing a tag', async function (assert) {
    const ctx = new TextContext();
    ctx.tags = ['keep', 'drop'];

    await render(
      <template>
        <Choices @type='text' @value={{ctx.tags}} @onChange={{ctx.onChange}} />
      </template>,
    );

    const removeBtn = document.querySelector(
      '.choices__item[data-value="drop"] button',
    );
    assert.ok(removeBtn, 'remove button present for text tags');
    await click(removeBtn as Element);
    await settled();

    assert.deepEqual(ctx.tags, ['keep']);
  });
});
