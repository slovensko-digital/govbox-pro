// app/javascript/custom/shift_select.js
document.addEventListener('turbo:load', () => {
    const checkboxes = document.querySelectorAll('.message-checkbox');
    let lastChecked = null;

    checkboxes.forEach(checkbox => {
        checkbox.addEventListener('click', (event) => {
            if (event.shiftKey && lastChecked) {
                const allCheckboxes = Array.from(checkboxes);
                const start = allCheckboxes.indexOf(checkbox);
                const end = allCheckboxes.indexOf(lastChecked);

                const inBetween = allCheckboxes.slice(Math.min(start, end), Math.max(start, end) + 1);

                inBetween.forEach(cb => {
                    cb.checked = checkbox.checked;
                });
            }

            lastChecked = checkbox;
        });
    });
});
