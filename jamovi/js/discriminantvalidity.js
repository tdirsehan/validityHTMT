'use strict';

function defaultConstructs() {
    return [
        { vars: [], assign: false, reset: false },
        { vars: [], assign: false, reset: false }
    ];
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

function findRowControls(ui, rowIndex, callback) {
    if (!ui.constructs || !ui.constructs.applyToItems)
        return;

    ui.constructs.applyToItems(rowIndex, function(item, index) {
        if (index !== rowIndex || !item || !item.controls)
            return;

        var assignControl = null;
        var varsControl = null;
        var resetControl = null;

        item.controls.forEach(function(control) {
            var name = null;
            if (control && control.getPropertyValue)
                name = control.getPropertyValue('name');

            if (name === 'assign')
                assignControl = control;
            else if (name === 'vars')
                varsControl = control;
            else if (name === 'reset')
                resetControl = control;
        });

        // Fallback for jamovi 2.4.x where template child names may not be
        // exposed through getPropertyValue('name').
        if (!assignControl && item.controls.length > 0)
            assignControl = item.controls[0];
        if (!varsControl && item.controls.length > 1)
            varsControl = item.controls[1];
        if (!resetControl && item.controls.length > 2)
            resetControl = item.controls[2];

        callback(assignControl, varsControl, resetControl);
    }, 1);
}

module.exports = {
    assign_changed: function(ui, event) {
        if (!ui.constructs || !ui.constructs.value ||
            !ui.variablesupplier || !ui.variablesupplier.getSelectedItems)
            return;

        var current = ui.constructs.value();
        if (!Array.isArray(current))
            return;

        var clickedIndex = -1;
        for (var i = 0; i < current.length; i++) {
            if (current[i] && current[i].assign === true) {
                clickedIndex = i;
                break;
            }
        }

        if (clickedIndex < 0)
            return;

        var selected = ui.variablesupplier.getSelectedItems();
        var usedElsewhere = {};
        current.forEach(function(item, index) {
            if (!item || !Array.isArray(item.vars) || index === clickedIndex)
                return;
            item.vars.forEach(function(v) {
                usedElsewhere[v] = true;
            });
        });

        findRowControls(ui, clickedIndex, function(assignControl, varsControl) {
            if (!varsControl || !varsControl.setValue) {
                if (assignControl && assignControl.setValue)
                    assignControl.setValue(false);
                return;
            }

            var existing = varsControl.value && varsControl.value();
            var vars = Array.isArray(existing) ? existing.slice() : [];

            selected.forEach(function(supplierItem) {
                var varName = supplierRaw(supplierItem);
                if (varName === null || usedElsewhere[varName] || vars.indexOf(varName) !== -1)
                    return;

                vars.push(varName);
                if (supplierItem.used === undefined || supplierItem.used === null)
                    supplierItem.used = 0;
                supplierItem.used += 1;
            });

            // Updating the row's VariablesListBox directly is important for
            // jamovi 2.4.x: replacing the complete Array option updates the
            // backend value but does not reliably repaint the nested list.
            varsControl.setValue(vars);

            if (assignControl && assignControl.setValue)
                assignControl.setValue(false);
        });

        refreshSupplier(ui);
    },

    reset_changed: function(ui, event) {
        if (!ui.constructs || !ui.constructs.value)
            return;

        var current = ui.constructs.value();
        if (!Array.isArray(current))
            return;

        var clickedIndex = -1;
        for (var i = 0; i < current.length; i++) {
            if (current[i] && current[i].reset === true) {
                clickedIndex = i;
                break;
            }
        }

        if (clickedIndex < 0)
            return;

        findRowControls(ui, clickedIndex, function(assignControl, varsControl, resetControl) {
            var vars = [];
            if (varsControl && varsControl.value) {
                var currentVars = varsControl.value();
                if (Array.isArray(currentVars))
                    vars = currentVars.slice();
            }
            else if (current[clickedIndex] && Array.isArray(current[clickedIndex].vars)) {
                vars = current[clickedIndex].vars.slice();
            }

            releaseVars(ui, vars);

            if (varsControl && varsControl.setValue)
                varsControl.setValue([]);
            if (assignControl && assignControl.setValue)
                assignControl.setValue(false);
            if (resetControl && resetControl.setValue)
                resetControl.setValue(false);
        });

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
