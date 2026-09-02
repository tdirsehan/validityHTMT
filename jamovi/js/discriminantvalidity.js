'use strict';

function defaultConstructs() {
    return [
        { vars: [], assign: false, reset: false },
        { vars: [], assign: false, reset: false }
    ];
}

function cloneItem(item) {
    var copy = {};
    if (!item)
        return copy;
    Object.keys(item).forEach(function(key) {
        copy[key] = item[key];
    });
    return copy;
}

function supplierRaw(item) {
    if (!item || !item.value)
        return null;
    if (item.value.raw !== undefined && item.value.raw !== null)
        return item.value.raw;
    if (item.value.toString)
        return item.value.toString();
    return null;
}

function refreshSupplier(ui) {
    if (!ui.variablesupplier)
        return;
    if (ui.variablesupplier.filterSuppliersList)
        ui.variablesupplier.filterSuppliersList(true);
    if (ui.variablesupplier.supplier && ui.variablesupplier.supplier.clearSelection)
        ui.variablesupplier.supplier.clearSelection();
}

function releaseVars(ui, vars) {
    if (!ui.variablesupplier || !Array.isArray(ui.variablesupplier._items) || !Array.isArray(vars))
        return;

    vars.forEach(function(varName) {
        for (var i = 0; i < ui.variablesupplier._items.length; i++) {
            var supplierItem = ui.variablesupplier._items[i];
            if (supplierRaw(supplierItem) === varName) {
                if (supplierItem.used && supplierItem.used > 0)
                    supplierItem.used -= 1;
                break;
            }
        }
    });
}

module.exports = {
    assign_changed: function(ui, event) {
        if (!ui.constructs || !ui.constructs.value || !ui.constructs.setValue ||
            !ui.variablesupplier || !ui.variablesupplier.getSelectedItems)
            return;

        var current = ui.constructs.value();
        if (!Array.isArray(current))
            return;

        var selected = ui.variablesupplier.getSelectedItems();
        var clickedIndex = -1;
        for (var i = 0; i < current.length; i++) {
            if (current[i] && current[i].assign === true) {
                clickedIndex = i;
                break;
            }
        }

        if (clickedIndex < 0)
            return;

        var used = {};
        current.forEach(function(item, index) {
            if (!item || !Array.isArray(item.vars))
                return;
            item.vars.forEach(function(v) {
                if (index !== clickedIndex)
                    used[v] = true;
            });
        });

        var next = current.map(function(item, index) {
            var copy = cloneItem(item);
            copy.assign = false;
            copy.reset = false;

            if (index === clickedIndex) {
                var vars = Array.isArray(copy.vars) ? copy.vars.slice() : [];
                selected.forEach(function(supplierItem) {
                    var varName = supplierRaw(supplierItem);
                    if (varName === null || used[varName] || vars.indexOf(varName) !== -1)
                        return;

                    vars.push(varName);
                    if (supplierItem.used === undefined || supplierItem.used === null)
                        supplierItem.used = 0;
                    supplierItem.used += 1;
                });
                copy.vars = vars;
            }

            return copy;
        });

        ui.constructs.setValue(next);
        refreshSupplier(ui);
    },

    reset_changed: function(ui, event) {
        if (!ui.constructs || !ui.constructs.value || !ui.constructs.setValue)
            return;

        var current = ui.constructs.value();
        if (!Array.isArray(current))
            return;

        var changed = false;
        var next = current.map(function(item) {
            var copy = cloneItem(item);
            copy.assign = false;

            if (!item || item.reset !== true) {
                copy.reset = false;
                return copy;
            }

            changed = true;
            releaseVars(ui, Array.isArray(item.vars) ? item.vars : []);
            copy.vars = [];
            copy.reset = false;
            return copy;
        });

        if (!changed)
            return;

        ui.constructs.setValue(next);
        refreshSupplier(ui);
    },

    resetControl_creating: function(ui, event) {
        var root = ui.resetControl && ui.resetControl.$el && ui.resetControl.$el[0];
        if (!root || root.querySelector('[data-validity-htmt-reset]'))
            return;

        var button = document.createElement('button');
        button.type = 'button';
        button.textContent = 'Reset all';
        button.setAttribute('data-validity-htmt-reset', '1');
        button.style.cssText = 'margin-top:8px;padding:5px 12px;cursor:pointer;';

        button.addEventListener('click', function() {
            var options = ui.view && ui.view.model && ui.view.model.options;
            if (options && options.beginEdit)
                options.beginEdit();

            try {
                if (ui.variablesupplier && Array.isArray(ui.variablesupplier._items)) {
                    ui.variablesupplier._items.forEach(function(item) {
                        item.used = 0;
                    });
                }
                if (ui.constructs)
                    ui.constructs.setValue(defaultConstructs());
                if (ui.correlation)
                    ui.correlation.setValue('pearson');
                if (ui.missing)
                    ui.missing.setValue('pairwise');
                if (ui.threshold)
                    ui.threshold.setValue('liberal90');
                if (ui.showPairs)
                    ui.showPairs.setValue(true);
            }
            finally {
                if (options && options.endEdit)
                    options.endEdit();
            }

            refreshSupplier(ui);
        });

        root.appendChild(button);
    }
};
