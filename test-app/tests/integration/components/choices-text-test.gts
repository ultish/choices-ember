import { module, test } from 'qunit';
import { setupRenderingTest } from 'test-app/tests/helpers';
import {
  click,
  fillIn,
  render,
  settled,
  triggerKeyEvent,
  waitUntil,
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
    this.tags = Array.isArray(value)
      ? value
      : value == null
        ? []
        : [String(value)];
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

function dropdownIsOpen(): boolean {
  return (
    document.querySelector('.choices.is-open') != null ||
    document.querySelector('.choices__list--dropdown.is-active') != null ||
    document.querySelector('.choices__list[aria-expanded="true"]') != null
  );
}

/**
 * Add a text-mode tag via the Choices UI.
 *
 * Choices 11 only commits on Enter when the dropdown is active
 * (`_onEnterKey` early-outs for text if !hasActiveDropdown). Typing must
 * open the “Press Enter to add” notice first — wait for that, then Enter.
 *
 * Use waitForTag=false when asserting rejection (e.g. maxItemCount).
 */
async function addTag(
  text: string,
  { waitForTag = true }: { waitForTag?: boolean } = {},
): Promise<void> {
  const input = textInput();
  await click(input);
  await fillIn(input, text);
  // Ensure Choices saw the value (fillIn can race with its input listener)
  input.dispatchEvent(new Event('input', { bubbles: true }));

  // Dropdown opens when Choices can create an item (“Press Enter to add”).
  // At maxItemCount it often stays closed — only require open when we expect success.
  if (waitForTag) {
    if (!dropdownIsOpen()) {
      input.dispatchEvent(
        new InputEvent('input', { bubbles: true, data: text }),
      );
    }
    await waitUntil(() => dropdownIsOpen(), { timeout: 2000 });
  }

  await triggerKeyEvent(input, 'keydown', 'Enter');

  if (waitForTag) {
    await waitUntil(() => tagValues().includes(text), { timeout: 2000 });
  }
}

module('Integration | Component | Choices | text', function (hooks) {
  setupRenderingTest(hooks);

  test('text add tag fires onChange with new value', async function (assert) {
    const ctx = new TextContext();

    await render(
      <template>
        <Choices
          @type="text"
          @value={{ctx.tags}}
          @onChange={{ctx.onChange}}
          @placeholder="Add a tag"
        />
      </template>,
    );

    assert.dom('.choices').exists();
    await addTag('hello');

    assert.ok(
      ctx.tags.includes('hello'),
      `tags include hello (got ${JSON.stringify(ctx.tags)})`,
    );
    assert.ok(ctx.onChangeCount >= 1, 'onChange fired');
    assert.ok(tagValues().includes('hello'), 'DOM shows tag');
  });

  test('text controlled from outside updates tags without loop', async function (assert) {
    const ctx = new TextContext();
    ctx.tags = ['a', 'b'];

    await render(
      <template>
        <Choices @type="text" @value={{ctx.tags}} @onChange={{ctx.onChange}} />
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
          @type="text"
          @value={{ctx.tags}}
          @onChange={{ctx.onChange}}
          @config={{config}}
        />
      </template>,
    );

    assert.strictEqual(ctx.tags.length, 2, 'starts at maxItemCount');
    assert.deepEqual(tagValues().sort(), ['one', 'two']);

    await addTag('three', { waitForTag: false });

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
          @type="text"
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
        <Choices @type="text" @value={{ctx.tags}} @onChange={{ctx.onChange}} />
      </template>,
    );

    const removeBtn = document.querySelector(
      '.choices__item[data-value="drop"] button',
    );
    assert.ok(removeBtn, 'remove button present for text tags');
    await click(removeBtn as Element);

    assert.deepEqual(ctx.tags, ['keep']);
  });
});
