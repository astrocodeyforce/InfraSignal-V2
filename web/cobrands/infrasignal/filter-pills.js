(function() {
    'use strict';

    // Only run on map/around pages
    if (!document.body.classList.contains('mappage')) return;

    var wrapper = document.getElementById('report-list-filters');
    if (!wrapper) return;

    var pillsContainer;

    // ── Override multi-select button text to show "X selected" ──
    function updateButtonText(selectId) {
        var select = document.getElementById(selectId);
        if (!select) return;

        var container = select.closest ? select.closest('.report-list-filters') : null;
        if (!container) return;

        var btn = container.querySelector('.multi-select-button');
        if (!btn) return;

        var allText = select.getAttribute('data-all') || 'All';
        var totalOptions = select.options.length;
        var selectedCount = 0;
        for (var i = 0; i < select.options.length; i++) {
            if (select.options[i].selected) selectedCount++;
        }

        if (selectedCount === 0 || selectedCount === totalOptions) {
            btn.textContent = allText;
        } else if (selectedCount === 1) {
            // Show the single selected name
            for (var j = 0; j < select.options.length; j++) {
                if (select.options[j].selected) {
                    btn.textContent = select.options[j].textContent.trim();
                    break;
                }
            }
        } else {
            btn.textContent = selectedCount + ' selected';
        }
    }

    function updateAllButtonTexts() {
        updateButtonText('statuses');
        updateButtonText('filter_categories');
    }

    function createPillsContainer() {
        // Insert after the fieldset
        var fieldset = wrapper.querySelector('fieldset');
        if (!fieldset) return null;

        var el = document.createElement('div');
        el.className = 'js-filter-pills';
        fieldset.appendChild(el);
        return el;
    }

    function getSelectedFilters() {
        var pills = [];

        // Status filters
        var statusSelect = document.getElementById('statuses');
        if (statusSelect) {
            var allOptions = [];
            try {
                allOptions = JSON.parse(statusSelect.getAttribute('data-all-options') || '[]');
            } catch(e) {}

            var selectedStatuses = [];
            for (var i = 0; i < statusSelect.options.length; i++) {
                if (statusSelect.options[i].selected) {
                    selectedStatuses.push(statusSelect.options[i].value);
                }
            }

            // Don't show pills if "All" (all options selected or none)
            var isAll = selectedStatuses.length === 0 ||
                        (allOptions.length > 0 && selectedStatuses.length === allOptions.length);

            if (!isAll) {
                for (var j = 0; j < selectedStatuses.length; j++) {
                    var opt = statusSelect.querySelector('option[value="' + selectedStatuses[j] + '"]');
                    if (opt) {
                        pills.push({
                            type: 'status',
                            value: selectedStatuses[j],
                            label: opt.textContent.trim(),
                            selectId: 'statuses'
                        });
                    }
                }
            }
        }

        // Category filters
        var catSelect = document.getElementById('filter_categories');
        if (catSelect) {
            var selectedCats = [];
            for (var k = 0; k < catSelect.options.length; k++) {
                if (catSelect.options[k].selected) {
                    selectedCats.push(catSelect.options[k].value);
                }
            }

            // Don't show if all or none selected
            if (selectedCats.length > 0 && selectedCats.length < catSelect.options.length) {
                for (var m = 0; m < selectedCats.length; m++) {
                    var catOpt = catSelect.querySelector('option[value="' + CSS.escape(selectedCats[m]) + '"]');
                    if (catOpt) {
                        pills.push({
                            type: 'category',
                            value: selectedCats[m],
                            label: catOpt.textContent.trim(),
                            selectId: 'filter_categories'
                        });
                    }
                }
            }
        }

        return pills;
    }

    function renderPills() {
        if (!pillsContainer) {
            pillsContainer = createPillsContainer();
        }
        if (!pillsContainer) return;

        // Update button texts
        updateAllButtonTexts();

        var pills = getSelectedFilters();
        pillsContainer.innerHTML = '';

        if (pills.length === 0) {
            pillsContainer.style.display = 'none';
            return;
        }

        pillsContainer.style.display = '';

        for (var i = 0; i < pills.length; i++) {
            (function(pill) {
                var el = document.createElement('span');
                el.className = 'filter-pill filter-pill--' + pill.type;
                el.innerHTML = pill.label + ' <span class="filter-pill__x">\u00d7</span>';
                el.addEventListener('click', function() {
                    removePill(pill);
                });
                pillsContainer.appendChild(el);
            })(pills[i]);
        }

        // Clear all button
        var clearBtn = document.createElement('button');
        clearBtn.type = 'button';
        clearBtn.className = 'filter-pills__clear';
        clearBtn.textContent = 'Clear all';
        clearBtn.addEventListener('click', function() {
            clearAllFilters();
        });
        pillsContainer.appendChild(clearBtn);
    }

    function removePill(pill) {
        var select = document.getElementById(pill.selectId);
        if (!select) return;

        for (var i = 0; i < select.options.length; i++) {
            if (select.options[i].value === pill.value) {
                select.options[i].selected = false;
                break;
            }
        }

        if (window.jQuery) {
            jQuery(select).trigger('change');
        }

        renderPills();
    }

    function clearAllFilters() {
        var selects = ['statuses', 'filter_categories'];
        for (var s = 0; s < selects.length; s++) {
            var select = document.getElementById(selects[s]);
            if (!select) continue;

            for (var i = 0; i < select.options.length; i++) {
                select.options[i].selected = false;
            }

            if (window.jQuery) {
                jQuery(select).trigger('change');
            }
        }

        renderPills();
    }

    // ── Override the plugin's G (updateButtonText) method ──
    function patchMultiSelectPlugin() {
        if (!window.jQuery) return;

        // Intercept the plugin's button text updates
        jQuery('#statuses, #filter_categories').each(function() {
            var plugin = jQuery.data(this, 'plugin_multiSelect');
            if (plugin) {
                var selectEl = this;
                // Override the G method that sets button text
                plugin.G = function() {
                    updateButtonText(selectEl.id);
                };
                // Run once to set initial text
                updateButtonText(selectEl.id);
            }
        });
    }

    // Listen for changes on the multi-select selects
    if (window.jQuery) {
        jQuery('#statuses, #filter_categories').on('change', function() {
            setTimeout(renderPills, 50);
        });
    }

    // Initial render after page load
    function init() {
        patchMultiSelectPlugin();
        renderPills();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            setTimeout(init, 300);
        });
    } else {
        setTimeout(init, 300);
    }
})();
