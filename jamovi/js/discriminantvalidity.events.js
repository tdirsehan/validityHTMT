// Native jamovi ListBox event handler: keep visible labels in sync with results.
// The existing R-side name fallback remains as a safety net for old analyses.
const events = {
    onConstructAdded: function(ui) {
        ui.constructs.applyToItems(0, (item, index) => {
            const control = item.controls[0];
            const label = control.value();
            if (!label || !label.trim())
                control.setValue('Construct ' + (index + 1));
        });
    }
};

module.exports = events;
