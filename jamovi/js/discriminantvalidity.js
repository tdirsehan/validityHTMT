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
        setControlVisible(ui['reset' + i], visible);
        setControlVisible(ui['n' + i], visible);
    }

    setControlVisible(ui.addConstruct, count < 8);
}

function clearConstructNative(ui, index) {
    var target = ui['t' + index];
    var list = ui['c' + index];

    if (!target || !list || valueLength(list) === 0)
        return;

    var listEl = list.el;

    try {
        if (target.setTargetGrid)
            target.setTargetGrid(list);

        if (listEl && listEl.clearSelection)
            listEl.clearSelection();
        if (listEl && listEl.selectAll)
            listEl.selectAll();

        if (target.setButtonsMode)
            target.setButtonsMode(false);
        else
            target.gainOnClick = false;

        if (target.onAddButtonClick && listEl && listEl.selectedCellCount && listEl.selectedCellCount() > 0)
            target.onAddButtonClick();
        else if (list.setValue)
            list.setValue([]);
    }
    finally {
        if (target.setButtonsMode)
            target.setButtonsMode(true);
        else
            target.gainOnClick = true;
    }
}

function releaseActionButton(control) {
    if (control && control.setValue)
        control.setValue(false);
}

function resetOne(ui, index) {
    clearConstructNative(ui, index);
    releaseActionButton(ui['reset' + index]);
}

function addConstruct(ui) {
    var count = ui.__htmtVisibleCount || initialVisibleCount(ui);
    if (count < 8)
        setVisibleCount(ui, count + 1);
    releaseActionButton(ui.addConstruct);
}

function resetAll(ui) {
    for (var i = 1; i <= 8; i++)
        clearConstructNative(ui, i);

    for (var j = 1; j <= 8; j++) {
        var nameControl = ui['n' + j];
        if (nameControl && nameControl.setValue)
            nameControl.setValue('Construct ' + j);
        releaseActionButton(ui['reset' + j]);
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
    releaseActionButton(ui.resetAll);
}

function bindButton(control, handler) {
    var el = elementOf(control);
    if (!el || el.getAttribute('data-htmt-bound') === '1')
        return;

    el.setAttribute('data-htmt-bound', '1');
    el.addEventListener('click', function() {
        setTimeout(handler, 0);
    });
}

function initialise(ui) {
    setVisibleCount(ui, initialVisibleCount(ui));

    bindButton(ui.addConstruct, function() {
        addConstruct(ui);
    });

    bindButton(ui.resetAll, function() {
        resetAll(ui);
    });

    for (var i = 1; i <= 8; i++) {
        (function(index) {
            bindButton(ui['reset' + index], function() {
                resetOne(ui, index);
            });
        })(i);
    }
}

module.exports = {
    uiInit_creating: function(ui, event) {
        setTimeout(function() {
            initialise(ui);
        }, 0);
    }
};
