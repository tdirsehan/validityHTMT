'use strict';

function elementOf(control) {
    if (!control)
        return null;
    if (control.el)
        return control.el;
    if (control.$el && control.$el[0])
        return control.$el[0];
    return null;
}

function setControlVisible(control, visible) {
    var el = elementOf(control);
    if (el)
        el.style.display = visible ? '' : 'none';
}

function valueLength(control) {
    if (!control || !control.value)
        return 0;
    var value = control.value();
    return Array.isArray(value) ? value.length : 0;
}

function initialVisibleCount(ui) {
    var count = 2;

    for (var i = 3; i <= 8; i++) {
        var vars = ui['c' + i];
        var name = ui['n' + i];
        var nameValue = name && name.value ? name.value() : ('Construct ' + i);

        if (valueLength(vars) > 0 || (nameValue && nameValue !== ('Construct ' + i)))
            count = i;
    }

    return count;
}

function setVisibleCount(ui, count) {
    count = Math.max(2, Math.min(8, count));
    ui.__htmtVisibleCount = count;

    for (var i = 1; i <= 8; i++) {
        var visible = i <= count;
        setControlVisible(ui['t' + i], visible);
        setControlVisible(ui['n' + i], visible);

        if (ui.__htmtResetHolders && ui.__htmtResetHolders[i])
            ui.__htmtResetHolders[i].style.display = visible ? '' : 'none';
    }

    if (ui.__htmtAddButton)
        ui.__htmtAddButton.style.display = count < 8 ? '' : 'none';
}

function clearConstruct(ui, index) {
    var list = ui['c' + index];
    if (!list || !list.setValue)
        return;

    list.setValue([]);
}

function resetAll(ui) {
    for (var i = 1; i <= 8; i++)
        clearConstruct(ui, i);

    for (var j = 1; j <= 8; j++) {
        var nameControl = ui['n' + j];
        if (nameControl && nameControl.setValue)
            nameControl.setValue('Construct ' + j);
    }

    if (ui.correlation && ui.correlation.setValue)
        ui.correlation.setValue('pearson');
    if (ui.missing && ui.missing.setValue)
        ui.missing.setValue('pairwise');
    if (ui.threshold && ui.threshold.setValue)
        ui.threshold.setValue('liberal90');
    if (ui.showPairs && ui.showPairs.setValue)
        ui.showPairs.setValue(true);

    setVisibleCount(ui, 2);
}

function makeButton(label, handler) {
    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'jmv-action-button';
    button.textContent = label;
    button.style.cursor = 'pointer';
    button.addEventListener('click', handler);
    return button;
}

function installResetButton(ui, index) {
    var targetEl = elementOf(ui['t' + index]);
    if (!targetEl || !targetEl.parentNode)
        return;

    if (!ui.__htmtResetHolders)
        ui.__htmtResetHolders = {};

    if (ui.__htmtResetHolders[index])
        return;

    var holder = document.createElement('div');
    holder.setAttribute('data-htmt-reset', String(index));
    holder.style.cssText = 'margin:4px 0 8px 0;';

    var button = makeButton('Reset Construct', function() {
        clearConstruct(ui, index);
    });

    holder.appendChild(button);
    targetEl.parentNode.insertBefore(holder, targetEl.nextSibling);
    ui.__htmtResetHolders[index] = holder;
}

function installGlobalControls(ui) {
    var root = elementOf(ui.uiControls);
    if (!root)
        return;

    if (ui.__htmtGlobalBar)
        return;

    var bar = document.createElement('div');
    bar.setAttribute('data-htmt-global-controls', '1');
    bar.style.cssText = 'display:flex;gap:8px;margin:8px 0;align-items:center;';

    var addButton = makeButton('+ Construct', function() {
        var count = ui.__htmtVisibleCount || 2;
        if (count < 8)
            setVisibleCount(ui, count + 1);
    });

    var resetAllButton = makeButton('Reset all', function() {
        resetAll(ui);
    });

    ui.__htmtAddButton = addButton;
    ui.__htmtResetAllButton = resetAllButton;
    ui.__htmtGlobalBar = bar;

    bar.appendChild(addButton);
    bar.appendChild(resetAllButton);
    root.appendChild(bar);
}

function initialise(ui) {
    for (var i = 1; i <= 8; i++)
        installResetButton(ui, i);

    installGlobalControls(ui);
    setVisibleCount(ui, initialVisibleCount(ui));
}

module.exports = {
    view_loaded: function(ui, event) {
        initialise(ui);
    },

    view_updated: function(ui, event) {
        initialise(ui);
        setVisibleCount(ui, initialVisibleCount(ui));
    }
};
