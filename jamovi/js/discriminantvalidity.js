'use strict';

function defaultConstructs() {
    return [
        { vars: [], reset: false },
        { vars: [], reset: false }
    ];
}

module.exports = {
    reset_changed: function(ui, event) {
        if (!ui.constructs || !ui.constructs.applyToItems)
            return;

        ui.constructs.applyToItems(0, function(item, index) {
            if (!item || !item.controls || item.controls.length < 2)
                return;

            var varsControl = item.controls[0];
            var resetControl = item.controls[1];
            var shouldReset = resetControl && resetControl.value && resetControl.value() === true;

            if (!shouldReset)
                return;

            if (varsControl && varsControl.setValue)
                varsControl.setValue([]);
            if (resetControl && resetControl.setValue)
                resetControl.setValue(false);
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
        });

        root.appendChild(button);
    }
};
