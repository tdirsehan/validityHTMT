'use strict';

function defaultConstructs() {
    return [
        { vars: [], reset: false },
        { vars: [], reset: false }
    ];
}

module.exports = {
    reset_changed: function(ui, event) {
        if (!ui.constructs || !ui.constructs.value || !ui.constructs.setValue)
            return;

        var current = ui.constructs.value();
        if (!Array.isArray(current))
            return;

        var changed = false;
        var next = current.map(function(item) {
            if (!item || item.reset !== true)
                return item;

            changed = true;
            var copy = {};
            Object.keys(item).forEach(function(key) {
                copy[key] = item[key];
            });
            copy.vars = [];
            copy.reset = false;
            return copy;
        });

        if (!changed)
            return;

        var options = ui.view && ui.view.model && ui.view.model.options;
        if (options && options.beginEdit)
            options.beginEdit();

        try {
            ui.constructs.setValue(next);
        }
        finally {
            if (options && options.endEdit)
                options.endEdit();
        }
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
