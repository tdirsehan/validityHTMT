// Exercise the actual event handler with an API-shaped mock ListBox.
const assert = require('node:assert/strict');
const { onConstructAdded } =
    require('../jamovi/js/discriminantvalidity.events.js');

function field(initial) {
    let current = initial;
    return {
        value() { return current; },
        setValue(next) { current = next; }
    };
}
const items = ['Construct 1', 'Construct 2', '', 'Custom', ' ']
    .map(label => ({ controls: [field(label)] }));
onConstructAdded({
    constructs: {
        applyToItems(_mode, callback) {
            items.forEach((item, index) => callback(item, index));
        }
    }
});
assert.deepEqual(items.map(item => item.controls[0].value()),
    ['Construct 1', 'Construct 2', 'Construct 3', 'Custom', 'Construct 5']);
console.log('Construct label event tests passed.');
