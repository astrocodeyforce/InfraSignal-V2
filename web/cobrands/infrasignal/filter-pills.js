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

// Report detail page enhancements (Lovable match)
(function() {
    'use strict';
    if (!document.body.classList.contains('mappage')) return;

    function enhanceReportDetail() {
        var sideReport = document.getElementById('side-report');
        if (!sideReport) return;

        // --- 1. Add placeholder to update textarea ---
        var textarea = document.getElementById('form_update');
        if (textarea && !textarea.getAttribute('placeholder')) {
            textarea.setAttribute('placeholder', 'Describe what you observed...');
        }

        // --- 2. Replace back arrow SVG with simple ← arrow ---
        var backLink = sideReport.querySelector('a.problem-back');
        if (backLink) {
            var svg = backLink.querySelector('svg');
            if (svg) {
                var arrow = document.createElement('span');
                arrow.textContent = '\u2190';
                arrow.className = 'back-arrow-icon';
                svg.parentNode.replaceChild(arrow, svg);
            }
        }

        // --- 3. Inject status bar if missing (open reports have no banner) ---
        var banner = sideReport.querySelector('.banner');
        var problemHeader = sideReport.querySelector('.problem-header');
        if (!banner && problemHeader && backLink) {
            // Determine state from updates or default to "open"
            var stateText = 'Open';
            var stateClass = 'banner--open';
            var metaItems = sideReport.querySelectorAll('.meta-2');
            for (var i = 0; i < metaItems.length; i++) {
                var txt = metaItems[i].textContent.toLowerCase();
                if (txt.indexOf('state changed to:') !== -1) {
                    if (txt.indexOf('fixed') !== -1) { stateText = 'Fixed'; stateClass = 'banner--fixed'; }
                    else if (txt.indexOf('investigating') !== -1) { stateText = 'Investigating'; stateClass = 'banner--investigating'; }
                    else if (txt.indexOf('in progress') !== -1) { stateText = 'In Progress'; stateClass = 'banner--in-progress'; }
                    else if (txt.indexOf('closed') !== -1) { stateText = 'Closed'; stateClass = 'banner--closed'; }
                    else if (txt.indexOf('action scheduled') !== -1) { stateText = 'Action Scheduled'; stateClass = 'banner--in-progress'; }
                }
            }
            var newBanner = document.createElement('div');
            newBanner.className = 'banner ' + stateClass;
            newBanner.innerHTML = '<p>' + stateText + '</p>';
            backLink.parentNode.insertBefore(newBanner, backLink.nextSibling);
        }

        // --- 4. Build status timeline ---
        var existingTimeline = sideReport.querySelector('.status-timeline');
        if (!existingTimeline && problemHeader) {
            // Get current state
            var currentBanner = sideReport.querySelector('.banner');
            var currentState = 'reported'; // default
            if (currentBanner) {
                var bannerText = currentBanner.textContent.trim().toLowerCase();
                if (bannerText.indexOf('fixed') !== -1 || bannerText.indexOf('closed') !== -1) currentState = 'resolved';
                else if (bannerText.indexOf('in progress') !== -1 || bannerText.indexOf('action') !== -1) currentState = 'in-progress';
                else if (bannerText.indexOf('investigating') !== -1 || bannerText.indexOf('acknowledged') !== -1) currentState = 'acknowledged';
                else currentState = 'reported';
            }

            // Get report date from .report_meta_info
            var metaInfo = problemHeader.querySelector('.report_meta_info');
            var reportDate = '';
            if (metaInfo) {
                var localtime = metaInfo.querySelector('.js-localtime');
                if (localtime) {
                    var epoch = localtime.getAttribute('data-epoch');
                    if (epoch) {
                        var d = new Date(parseInt(epoch) * 1000);
                        reportDate = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
                    }
                }
            }

            // Get latest update date
            var updateDate = '';
            var metaItems2 = sideReport.querySelectorAll('.meta-2');
            for (var j = metaItems2.length - 1; j >= 0; j--) {
                var metaText = metaItems2[j].textContent;
                var dateMatch = metaText.match(/(\d{1,2}:\d{2},?\s+\w+\s+\d{1,2}\s+\w+\s+\d{4})/);
                if (dateMatch) {
                    // Parse the platform date format
                    try {
                        var parts = dateMatch[1].replace(/,/g, '').split(/\s+/);
                        // Format: "14:07, Tuesday 17 March 2026" -> parts after time
                        if (parts.length >= 4) {
                            var dp = new Date(parts[parts.length - 3] + ' ' + parts[parts.length - 2] + ', ' + parts[parts.length - 1]);
                            if (!isNaN(dp.getTime())) {
                                updateDate = dp.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
                            }
                        }
                    } catch(e) {}
                    break;
                }
            }

            var steps = [
                { key: 'reported', label: 'Reported', date: reportDate },
                { key: 'acknowledged', label: 'Acknowledged', date: '' },
                { key: 'in-progress', label: 'In Progress', date: '' },
                { key: 'resolved', label: 'Resolved', date: '' }
            ];

            // Mark which steps are complete
            var stateOrder = ['reported', 'acknowledged', 'in-progress', 'resolved'];
            var currentIdx = stateOrder.indexOf(currentState);
            if (currentIdx === -1) currentIdx = 0;

            // If we have an update date and state is beyond reported, assign it
            if (currentIdx >= 1 && updateDate) {
                steps[currentIdx].date = updateDate;
            }

            var timelineHTML = '<div class="status-timeline">';
            timelineHTML += '<h3 class="status-timeline__heading">STATUS TIMELINE</h3>';
            timelineHTML += '<div class="status-timeline__track">';

            for (var s = 0; s < steps.length; s++) {
                var isComplete = s <= currentIdx;
                var isCurrent = s === currentIdx;
                var stepClass = 'status-timeline__step';
                if (isComplete) stepClass += ' status-timeline__step--complete';
                if (isCurrent) stepClass += ' status-timeline__step--current';

                timelineHTML += '<div class="' + stepClass + '">';
                timelineHTML += '<div class="status-timeline__dot">';
                if (isComplete) {
                    timelineHTML += '<svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="6" stroke="white" stroke-width="2"/><path d="M4 7l2 2 4-4" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';
                }
                timelineHTML += '</div>';
                if (s < steps.length - 1) {
                    var lineClass = 'status-timeline__line';
                    if (s < currentIdx) lineClass += ' status-timeline__line--complete';
                    else lineClass += ' status-timeline__line--pending';
                    timelineHTML += '<div class="' + lineClass + '"></div>';
                }
                timelineHTML += '</div>';

                // Label row (built below track)
            }
            timelineHTML += '</div>'; // end track

            // Labels row
            timelineHTML += '<div class="status-timeline__labels">';
            for (var l = 0; l < steps.length; l++) {
                var labelComplete = l <= currentIdx;
                timelineHTML += '<div class="status-timeline__label' + (labelComplete ? ' status-timeline__label--complete' : '') + '">';
                timelineHTML += '<span class="status-timeline__label-text">' + steps[l].label + '</span>';
                timelineHTML += '<span class="status-timeline__label-date">' + (steps[l].date || 'Pending') + '</span>';
                timelineHTML += '</div>';
            }
            timelineHTML += '</div>'; // end labels

            timelineHTML += '</div>'; // end timeline

            // Insert after problem-header, before updates section or update_form
            var insertPoint = problemHeader.nextElementSibling;
            var timelineDiv = document.createElement('div');
            timelineDiv.innerHTML = timelineHTML;
            problemHeader.parentNode.insertBefore(timelineDiv.firstChild, insertPoint);
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', enhanceReportDetail);
    } else {
        enhanceReportDetail();
    }
})();
