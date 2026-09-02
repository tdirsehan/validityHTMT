'use strict';

function defaultConstructs() {
    return [
        { vars: [], assign: false, reset: false },
        { vars: [], assign: false, reset: false }
    ];
}

function refreshSupplier(ui) {
    if (!ui.variablesupplier)
        return;

    if (ui.variablesupplier.filterSuppliersList)
        ui.variablesupplier.filterSuppliersList(true);

    if (ui.variablesupplier.supplier && ui.variablesupplier.supplier.clearSelection)
        ui.variablesupplier.supplier.clearSelection();
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

        if (!assignControl && item.controls.length > 0)
            assignControl = item.controls[0];
        if (!varsControl && item.controls.length > 1)
            varsControl = item.controls[1];
        if (!resetControl && item.controls.length > 2)
            resetControl = item.controls[2];

        callback(assignControl, varsControl, resetControl);
    }, 1);
}

function clickedRow(current, key) {
    for (var i = 0; i < current.length; i++) {
        if (current[i] && current[i][key] === true)
            return i;
    }
    return -1;
}

module.exports = {
    assign_changed: function(ui, event) {
        if (!ui.constructs || !ui.constructs.value || !ui.constructsTarget)
            return;

        var current = ui.constructs.value();
        if (!Array.isArray(current))
            return;

        var rowIndex = clickedRow(current, 'assign');
        if (rowIndex < 0)
            return;

        findRowControls(ui, rowIndex, function(assignControl, varsControl) {
            try {
                if (!varsControl)
                    return;

                // Use the same native transfer path used by jamovi's ordinary
                // TargetLayoutBox controls. This keeps the nested target list,
                // supplier state, and visible rows in sync on jamovi 2.4.x.
                if (ui.constructsTarget.setTargetGrid)
                    ui.constructsTarget.setTargetGrid(varsControl);
                if (ui.constructsTarget.setButtonsMode)
                    ui.constructsTarget.setButtonsMode(true);
                else
                    ui.constructsTarget.gainOnClick = true;

                if (ui.constructsTarget.onAddButtonClick)
                    ui.constructsTarget.onAddButtonClick();
            }
            finally {
                if (assignControl && assignControl.setValue)
                    assignControl.setValue(false);
            }
        });
    },

    reset_changed: function(ui, event) {
        if (!ui.constructs || !ui.constructs.value || !ui.constructsTarget)
            return;

        var current = ui.constructs.value();
        if (!Array.isArray(current))
            return;

        var rowIndex = clickedRow(current, 'reset');
        if (rowIndex < 0)
            return;

        findRowControls(ui, rowIndex, function(assignControl, varsControl, resetControl) {
            try {
                if (!varsControl)
                    return;

                if (ui.constructsTarget.setTargetGrid)
                    ui.constructsTarget.setTargetGrid(varsControl);

                if (varsControl.el && varsControl.el.selectAll)
                    varsControl.el.selectAll();

                if (ui.constructsTarget.setButtonsMode)
                    ui.constructsTarget.setButtonsMode(false);
                else
                    ui.constructsTarget.gainOnClick = false;

                if (ui.constructsTarget.onAddButtonClick &&
                    varsControl.el && varsControl.el.selectedCellCount &&
                    varsControl.el.selectedCellCount() > 0)
                    ui.constructsTarget.onAddButtonClick();
            }
            finally {
                if (assignControl && assignControl.setValue)
                    assignControl.setValue(false);
                if (resetControl && resetControl.setValue)
                    resetControl.setValue(false);
            }
        });
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
