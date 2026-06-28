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
        if (textarea) {
            textarea.removeAttribute('cols');
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
            var stateText = 'Open';
            var stateClass = 'banner--open';
            var badgeText = 'AWAITING REVIEW';
            var metaItems = sideReport.querySelectorAll('.meta-2');
            for (var i = 0; i < metaItems.length; i++) {
                var txt = metaItems[i].textContent.toLowerCase();
                if (txt.indexOf('state changed to:') !== -1) {
                    if (txt.indexOf('fixed') !== -1) { stateText = 'Fixed'; stateClass = 'banner--fixed'; badgeText = 'RESOLVED'; }
                    else if (txt.indexOf('investigating') !== -1) { stateText = 'Investigating'; stateClass = 'banner--investigating'; badgeText = 'UNDER REVIEW'; }
                    else if (txt.indexOf('in progress') !== -1) { stateText = 'In Progress'; stateClass = 'banner--in-progress'; badgeText = 'IN PROGRESS'; }
                    else if (txt.indexOf('closed') !== -1) { stateText = 'Closed'; stateClass = 'banner--closed'; badgeText = 'CLOSED'; }
                    else if (txt.indexOf('action scheduled') !== -1) { stateText = 'Action Scheduled'; stateClass = 'banner--in-progress'; badgeText = 'SCHEDULED'; }
                }
            }
            var newBanner = document.createElement('div');
            newBanner.className = 'banner ' + stateClass;
            newBanner.innerHTML = '<p>' + stateText + '</p><span class="rpt-status-badge">' + badgeText + '</span>';
            backLink.parentNode.insertBefore(newBanner, backLink.nextSibling);
        }

        // Inject badge into existing banners that don't have one
        var existingBanner = sideReport.querySelector('.banner');
        if (existingBanner && !existingBanner.querySelector('.rpt-status-badge')) {
            var bText = existingBanner.textContent.trim().toLowerCase();
            var bannerClass = existingBanner.className || '';
            var eBadge = 'AWAITING REVIEW';
            if (bannerClass.indexOf('banner--fixed') !== -1 || bText.indexOf('fixed') !== -1) eBadge = 'RESOLVED';
            else if (bannerClass.indexOf('banner--progress') !== -1 || bText.indexOf('investigating') !== -1) eBadge = 'UNDER REVIEW';
            else if (bText.indexOf('in progress') !== -1) eBadge = 'IN PROGRESS';
            else if (bannerClass.indexOf('banner--closed') !== -1 || bText.indexOf('closed') !== -1) eBadge = 'CLOSED';
            var badgeEl = document.createElement('span');
            badgeEl.className = 'rpt-status-badge';
            badgeEl.textContent = eBadge;
            existingBanner.appendChild(badgeEl);
        }

        // --- 4. Inject icon box before h1 (Lovable reference: layers/stack icon in primary-10 box) ---
        var h1 = problemHeader ? problemHeader.querySelector('h1') : null;
        if (h1 && !problemHeader.querySelector('.rpt-icon-box')) {
            // Wrap h1 + category in a .rpt-header-content div so layout matches reference (flex row)
            var iconBox = document.createElement('div');
            iconBox.className = 'rpt-icon-box';
            iconBox.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2 2 7l10 5 10-5-10-5Z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>';

            var contentWrap = document.createElement('div');
            contentWrap.className = 'rpt-header-content';
            // Move h1 into contentWrap
            h1.parentNode.insertBefore(contentWrap, h1);
            contentWrap.appendChild(h1);
            // Insert icon box before contentWrap
            contentWrap.parentNode.insertBefore(iconBox, contentWrap);
        }

        // --- 5. Inject category badge after h1 (inside header content wrapper) ---
        if (h1 && !problemHeader.querySelector('.rpt-cat-badge')) {
            var metaInfo = problemHeader.querySelector('.report_meta_info');
            if (problemHeader.getAttribute('data-report-category')) {
                var catBadge = document.createElement('span');
                catBadge.className = 'rpt-cat-badge';
                catBadge.textContent = problemHeader.getAttribute('data-report-category');
                if (h1.parentNode) {
                    h1.parentNode.appendChild(catBadge);
                }
            } else if (metaInfo) {
                var metaText = metaInfo.textContent || '';
                var catMatch = metaText.match(/in the (.+?) category/);
                if (catMatch) {
                    var catBadge = document.createElement('span');
                    catBadge.className = 'rpt-cat-badge';
                    catBadge.textContent = catMatch[1];
                    // Append after h1 inside its parent (the rpt-header-content wrapper)
                    if (h1.parentNode) {
                        h1.parentNode.appendChild(catBadge);
                    }
                }
            }
        }

        // --- 5b. Move report photo into its own section so it doesn't affect header spacing ---
        if (problemHeader && !sideReport.querySelector('.rpt-photo-section')) {
            var reportPhoto = problemHeader.querySelector('.update-img');
            if (reportPhoto) {
                problemHeader.classList.add('rpt-has-photo');
                var photoSection = document.createElement('div');
                photoSection.className = 'rpt-photo-section';
                problemHeader.parentNode.insertBefore(photoSection, problemHeader.nextElementSibling);
                photoSection.appendChild(reportPhoto);
            }
        }

        // --- 5c. Photo lightbox fallback/override ---
        // The report redesign moves the photo in the DOM; this keeps clicks in-page
        // even if the original Fancybox binding is missed by the platform scripts.
        if (!sideReport.getAttribute('data-rpt-photo-lightbox')) {
            sideReport.setAttribute('data-rpt-photo-lightbox', '1');

            function closePhotoLightbox() {
                var existing = document.querySelector('.rpt-photo-lightbox');
                if (existing) existing.parentNode.removeChild(existing);
                document.documentElement.classList.remove('rpt-photo-lightbox-open');
                document.removeEventListener('keydown', onPhotoLightboxKeydown);
            }

            function onPhotoLightboxKeydown(event) {
                if (event.key === 'Escape' || event.keyCode === 27) {
                    closePhotoLightbox();
                }
            }

            function openPhotoLightbox(link) {
                closePhotoLightbox();

                var image = link.querySelector('img');
                var overlay = document.createElement('div');
                overlay.className = 'rpt-photo-lightbox';
                overlay.setAttribute('role', 'dialog');
                overlay.setAttribute('aria-modal', 'true');
                overlay.setAttribute('aria-label', 'Report photo');

                var frame = document.createElement('div');
                frame.className = 'rpt-photo-lightbox__frame';

                var closeButton = document.createElement('button');
                closeButton.type = 'button';
                closeButton.className = 'rpt-photo-lightbox__close';
                closeButton.setAttribute('aria-label', 'Close photo');
                closeButton.textContent = 'x';

                var fullImage = document.createElement('img');
                fullImage.className = 'rpt-photo-lightbox__image';
                fullImage.src = link.href;
                fullImage.alt = image ? image.alt : 'Report photo';

                frame.appendChild(closeButton);
                frame.appendChild(fullImage);
                overlay.appendChild(frame);
                document.body.appendChild(overlay);
                document.documentElement.classList.add('rpt-photo-lightbox-open');
                closeButton.focus();

                overlay.addEventListener('click', function(event) {
                    if (event.target === overlay) closePhotoLightbox();
                });
                closeButton.addEventListener('click', closePhotoLightbox);
                document.addEventListener('keydown', onPhotoLightboxKeydown);
            }

            sideReport.addEventListener('click', function(event) {
                var target = event.target;
                var link = target && target.closest ? target.closest('.update-img a[rel="fancy"]') : null;
                if (!link || !sideReport.contains(link)) return;

                event.preventDefault();
                event.stopPropagation();
                openPhotoLightbox(link);
            }, true);
        }

        // --- 6. Build 2×2 details grid (Lovable reference: icon + label/value pairs) ---
        if (problemHeader && !sideReport.querySelector('.rpt-details-grid')) {
            var refEl = problemHeader.querySelectorAll('.council_sent_info');
            var metaEl = problemHeader.querySelector('.report_meta_info');

            // Extract ref number
            var refNum = '';
            var authority = '';
            for (var r = 0; r < refEl.length; r++) {
                if (!refNum && refEl[r].getAttribute('data-ref-number')) {
                    refNum = refEl[r].getAttribute('data-ref-number');
                }
                if (!authority && refEl[r].getAttribute('data-authority') && !/^\d+$/.test(refEl[r].getAttribute('data-authority'))) {
                    authority = refEl[r].getAttribute('data-authority');
                }
                var rText = refEl[r].textContent.trim();
                if (rText.indexOf('ref:') !== -1 || rText.indexOf('Ref:') !== -1) {
                    var rMatch = rText.match(/ref:\s*(\S+)/i);
                    if (rMatch) refNum = rMatch[1].replace(/\.$/, '');
                } else if (rText.indexOf('Authority') !== -1 || rText.indexOf('Responsible') !== -1) {
                    authority = rText.replace(/Responsible Authority:\s*/i, '').replace(/\s+/g, ' ').trim();
                } else if (!authority && rText.indexOf(':') !== -1 && rText.toLowerCase().indexOf('ref') === -1) {
                    authority = rText.replace(/^.*?:\s*/, '').replace(/\s+/g, ' ').trim();
                }
            }

            // Extract date from meta
            var reportedDate = '';
            var reportSource = 'Desktop';
            if (metaEl) {
                var localtime = metaEl.querySelector('.js-localtime');
                if (localtime) {
                    var epoch = localtime.getAttribute('data-epoch');
                    if (epoch) {
                        var dt = new Date(parseInt(epoch) * 1000);
                        reportedDate = dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
                    }
                    var ltText = localtime.textContent || '';
                    if (ltText.indexOf('desktop') !== -1) reportSource = 'Desktop';
                    else if (ltText.indexOf('mobile') !== -1) reportSource = 'Mobile';
                    else if (ltText.indexOf('app') !== -1) reportSource = 'App';
                }
            }

            // Icons from the reference template
            var svgRef       = '<svg class="rpt-detail-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16"/><path d="M4 12h16"/><path d="M4 20h16"/></svg>';
            var svgAuthority = '<svg class="rpt-detail-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2"/><path d="M8 6h8"/><path d="M8 10h8"/><path d="M8 14h4"/></svg>';
            var svgReported  = '<svg class="rpt-detail-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>';
            var svgSource    = '<svg class="rpt-detail-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0116 0Z"/><circle cx="12" cy="10" r="3"/></svg>';

            var gridHTML = '<div class="rpt-details-grid">';
            gridHTML += '<div class="rpt-detail-item">' + svgRef + '<div><p class="rpt-detail-label">Ref</p><p class="rpt-detail-value">' + (refNum || 'N/A') + '</p></div></div>';
            gridHTML += '<div class="rpt-detail-item">' + svgAuthority + '<div><p class="rpt-detail-label">Authority</p><p class="rpt-detail-value">' + (authority || 'N/A') + '</p></div></div>';
            gridHTML += '<div class="rpt-detail-item">' + svgReported + '<div><p class="rpt-detail-label">Reported</p><p class="rpt-detail-value">' + (reportedDate || 'N/A') + '</p></div></div>';
            gridHTML += '<div class="rpt-detail-item">' + svgSource + '<div><p class="rpt-detail-label">Source</p><p class="rpt-detail-value">' + reportSource + '</p></div></div>';
            gridHTML += '</div>';

            // Insert grid after the photo section if one exists, otherwise after the header
            var gridWrapper = document.createElement('div');
            gridWrapper.innerHTML = gridHTML;
            var gridAnchor = sideReport.querySelector('.rpt-photo-section') || problemHeader;
            gridAnchor.parentNode.insertBefore(gridWrapper.firstChild, gridAnchor.nextElementSibling);

            // Hide originals
            for (var h = 0; h < refEl.length; h++) {
                refEl[h].classList.add('rpt-details-moved');
            }
            if (metaEl) metaEl.classList.add('rpt-details-moved');

            // Move description block after details grid (Lovable order: Header → Grid → Description)
            var modDispEl = problemHeader.querySelector('.moderate-display');
            var detailsGridEl = sideReport.querySelector('.rpt-details-grid');
            if (modDispEl && detailsGridEl) {
                var descBlock = document.createElement('div');
                descBlock.className = 'rpt-description-block';
                // Wrap the original content in a quote div per reference
                descBlock.innerHTML = '<div class="rpt-description-quote">' + modDispEl.innerHTML + '</div>';
                detailsGridEl.parentNode.insertBefore(descBlock, detailsGridEl.nextElementSibling);
                modDispEl.style.display = 'none';
            }
        }

        // --- 7. Build status timeline ---
        if (sideReport.querySelector('.stl') || !problemHeader) return;

        var currentBanner = sideReport.querySelector('.banner');
        var currentState = 'reported';
        var rawProblemState = problemHeader.getAttribute('data-problem-state') || '';
        if (rawProblemState) {
            if (/^fixed|^closed/.test(rawProblemState)) currentState = 'resolved';
            else if (rawProblemState.indexOf('in progress') !== -1 || rawProblemState.indexOf('action') !== -1) currentState = 'in-progress';
            else if (rawProblemState.indexOf('investigating') !== -1 || rawProblemState.indexOf('acknowledged') !== -1) currentState = 'acknowledged';
        } else if (currentBanner) {
            var bt = currentBanner.textContent.trim().toLowerCase();
            var bc = currentBanner.className || '';
            if (bc.indexOf('banner--fixed') !== -1 || bc.indexOf('banner--closed') !== -1 || bt.indexOf('fixed') !== -1 || bt.indexOf('closed') !== -1) currentState = 'resolved';
            else if (bc.indexOf('banner--progress') !== -1 || bt.indexOf('in progress') !== -1 || bt.indexOf('action') !== -1) currentState = 'in-progress';
            else if (bt.indexOf('investigating') !== -1 || bt.indexOf('acknowledged') !== -1) currentState = 'acknowledged';
        }

        var reportDate = '';
        var lt = problemHeader.querySelector('.report_meta_info .js-localtime');
        if (lt) {
            var ep = lt.getAttribute('data-epoch');
            if (ep) {
                var dd = new Date(parseInt(ep) * 1000);
                reportDate = dd.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
            }
        }

        var updateDate = '';
        var updateItemsForTimeline = sideReport.querySelectorAll('.item-list__item--updates[data-update-epoch]');
        for (var j = updateItemsForTimeline.length - 1; j >= 0; j--) {
            var updateEpoch = updateItemsForTimeline[j].getAttribute('data-update-epoch');
            if (updateEpoch) {
                var pd = new Date(parseInt(updateEpoch) * 1000);
                if (!isNaN(pd.getTime())) {
                    updateDate = pd.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
                    break;
                }
            }
        }

        var order = ['reported', 'acknowledged', 'in-progress', 'resolved'];
        var ci = order.indexOf(currentState);
        if (ci === -1) ci = 0;

        var steps = [
            { label: 'Reported',     date: reportDate },
            { label: 'Acknowledged', date: ci >= 1 ? (updateDate || '') : '' },
            { label: 'In Progress',  date: ci >= 2 ? (updateDate || '') : '' },
            { label: 'Resolved',     date: ci >= 3 ? (updateDate || '') : '' }
        ];

        // Check icon from reference template
        var checkSvg = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="m9 11 3 3L22 4"/></svg>';

        // Horizontal flex timeline: each step is a column
        // with a row containing [left-line, dot, right-line] and labels below
        var html = '<div class="stl"><div class="stl-heading">Timeline</div><div class="stl-grid">';

        for (var s = 0; s < steps.length; s++) {
            var done = s <= ci;
            var prevDone = s - 1 >= 0 && s - 1 < ci;   // line BEFORE this step is done if previous step is done
            var nextDone = s < ci;                      // line AFTER this step is done if this step is done

            html += '<div class="stl-step">';
            html += '<div class="stl-step__row">';

            // Left line (except on first step)
            if (s > 0) {
                html += '<div class="stl-line' + (prevDone ? ' stl-line--done' : '') + '"></div>';
            } else {
                html += '<div class="stl-line" style="visibility:hidden"></div>';
            }

            // Dot
            html += '<div class="stl-dot' + (done ? ' stl-dot--done' : '') + '">';
            if (done) html += checkSvg;
            html += '</div>';

            // Right line (except on last step)
            if (s < steps.length - 1) {
                html += '<div class="stl-line' + (nextDone ? ' stl-line--done' : '') + '"></div>';
            } else {
                html += '<div class="stl-line" style="visibility:hidden"></div>';
            }

            html += '</div>'; // end .stl-step__row

            html += '<div class="stl-lbl-name">' + steps[s].label + '</div>';
            html += '<div class="stl-lbl-date">' + (steps[s].date || 'Pending') + '</div>';

            html += '</div>'; // end .stl-step
        }

        html += '</div></div>';

        // Insert after details grid (or after problem-header)
        var detailsGrid = sideReport.querySelector('.rpt-details-grid');
        var timelineAnchor = detailsGrid || problemHeader;
        var wrapper = document.createElement('div');
        wrapper.innerHTML = html;
        timelineAnchor.parentNode.insertBefore(wrapper.firstChild, timelineAnchor.nextElementSibling);

        // --- 8. Enhance updates section ---
        var updatesSection = sideReport.querySelector('section.full-width');
        if (updatesSection) {
            var updateItems = updatesSection.querySelectorAll('.item-list__item--updates');

            // Inject chat icon + count badge into heading
            var updatesH2 = updatesSection.querySelector('h2.static-with-rule');
            if (updatesH2 && !updatesH2.querySelector('.rpt-updates-icon')) {
                var chatIcon = '<span class="rpt-updates-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg></span>';
                var countBadge = updateItems.length > 0 ? '<span class="rpt-updates-count">' + updateItems.length + '</span>' : '';
                updatesH2.innerHTML = chatIcon + 'Updates' + countBadge;
            }

            // Restructure each update card
            for (var u = 0; u < updateItems.length; u++) {
                var item = updateItems[u];
                if (item.getAttribute('data-enhanced')) continue;
                item.setAttribute('data-enhanced', '1');

                var updateText = item.querySelector('.item-list__update-text');
                if (!updateText) continue;

                var modDisplay = updateText.querySelector('.moderate-display');
                var bodyText = '';
                if (modDisplay) {
                    var bodyP = modDisplay.querySelector('p');
                    if (bodyP) bodyText = bodyP.textContent.trim();
                }

                var metas = updateText.querySelectorAll('.meta-2');
                var authorName = '';
                var dateStr = '';
                var stateChange = '';
                var isOfficial = false;

                for (var m = 0; m < metas.length; m++) {
                    var metaText2 = metas[m].textContent.trim();
                    if (metaText2.indexOf('State changed to:') !== -1 || metaText2.indexOf(':') !== -1 && !metas[m].querySelector('strong')) {
                        stateChange = metaText2;
                    }
                    var strongEl = metas[m].querySelector('strong');
                    if (strongEl && !authorName) {
                        authorName = strongEl.textContent.trim();
                        // Check if it's an official/authority update (has a comma = place name)
                        if (authorName.indexOf(',') !== -1 || authorName.indexOf('Council') !== -1 || authorName.indexOf('Authority') !== -1) {
                            isOfficial = true;
                        }
                    }
                    if (metaText2.indexOf('Posted by') !== -1) {
                        var dMatch = metaText2.match(/at\s+\d{1,2}:\d{2},?\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4})/);
                        if (dMatch) {
                            try {
                                var dp = new Date(dMatch[2] + ' ' + dMatch[1] + ', ' + dMatch[3]);
                                if (!isNaN(dp.getTime())) {
                                    dateStr = dp.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
                                }
                            } catch(e) {}
                        }
                    }
                }
                if (!dateStr && item.getAttribute('data-update-epoch')) {
                    var updDate = new Date(parseInt(item.getAttribute('data-update-epoch')) * 1000);
                    if (!isNaN(updDate.getTime())) {
                        dateStr = updDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
                    }
                }

                var newHTML = '';

                // Official badge
                if (isOfficial) {
                    newHTML += '<div class="rpt-official-badge">\uD83C\uDFDB Official Response</div>';
                }

                // Header row
                newHTML += '<div class="upd-header">';
                newHTML += '<span class="upd-author">' + (authorName || 'Unknown') + '</span>';
                newHTML += '<span class="upd-date">' + (dateStr || '') + '</span>';
                newHTML += '</div>';

                if (stateChange) {
                    newHTML += '<div class="upd-state">' + stateChange + '</div>';
                }

                if (bodyText) {
                    newHTML += '<div class="upd-body">\u201C' + bodyText + '\u201D</div>';
                }

                updateText.innerHTML = newHTML;
            }
        }

        // --- 9. Inject "Step 1" label in form section ---
        var updateForm = document.getElementById('update_form');
        if (updateForm && !updateForm.querySelector('.rpt-step-label')) {
            var formH2 = updateForm.querySelector('h2');
            if (formH2) {
                var step1Label = document.createElement('div');
                step1Label.className = 'rpt-step-label';
                step1Label.textContent = 'STEP 1';
                formH2.parentNode.insertBefore(step1Label, formH2);
            }
        }

        // --- 9b. Inject "Step 2" label in auth section ---
        var authSection = sideReport.querySelector('.form-section-preview--next');
        if (authSection && !authSection.querySelector('.rpt-step-label')) {
            var authHeading = authSection.querySelector('h2.form-section-heading');
            if (authHeading) {
                authHeading.textContent = authHeading.textContent.replace(/^\s*Next:\s*/i, '');
            }
            var stepLabel = document.createElement('div');
            stepLabel.className = 'rpt-step-label';
            stepLabel.textContent = 'STEP 2';
            authSection.insertBefore(stepLabel, authSection.firstChild);
        }

        // --- 9c. Compact bottom action labels to match the reference ---
        var nearbyLink = document.querySelector('#key-tools a[href*="/around"]');
        if (nearbyLink && nearbyLink.textContent.indexOf('Problems nearby') !== -1) {
            for (var nl = 0; nl < nearbyLink.childNodes.length; nl++) {
                var node = nearbyLink.childNodes[nl];
                if (node.nodeType === 3 && node.nodeValue.indexOf('Problems nearby') !== -1) {
                    node.nodeValue = node.nodeValue.replace('Problems nearby', 'Nearby');
                }
            }
        }

        // --- 10. Fix dropzone: inject icon, fix text ---
        function ensureDropzone() {
            var rawPhotoFields = sideReport.querySelector('#form_photos');
            var existingDropzone = sideReport.querySelector('.dropzone');
            if (!rawPhotoFields || existingDropzone) return;

            // The platform normally runs this after loading the side report. If it
            // misses the report sidebar (for example after an async language/page
            // transition), force the same setup so users do not see raw file inputs.
            if (window.fixmystreet && fixmystreet.set_up && fixmystreet.set_up.dropzone && window.jQuery) {
                fixmystreet.set_up.dropzone(jQuery(sideReport));
            }
        }

        function fixDropzoneText() {
            ensureDropzone();
            var dzMessages = sideReport.querySelectorAll('.dropzone .dz-message');
            for (var d = 0; d < dzMessages.length; d++) {
                var msgEl = dzMessages[d];
                if (msgEl.getAttribute('data-dz-fixed')) continue;

                var span = msgEl.querySelector('span') || msgEl.querySelector('button');
                if (!span) continue;

                var uEl = span.querySelector('u');
                if (!uEl) continue;

                msgEl.setAttribute('data-dz-fixed', '1');

                span.innerHTML = '';

                var iconWrap = document.createElement('span');
                iconWrap.className = 'dz-icon-circle';
                iconWrap.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#6B7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>';
                span.appendChild(iconWrap);

                var textNode = document.createTextNode('Drag photos here or ');
                span.appendChild(textNode);

                var btn = document.createElement('u');
                btn.textContent = 'choose photos';
                span.appendChild(btn);
            }
        }

        fixDropzoneText();
        setTimeout(fixDropzoneText, 500);
        setTimeout(fixDropzoneText, 1500);
    }

    var enhanceTimer;
    function scheduleEnhanceReportDetail() {
        clearTimeout(enhanceTimer);
        enhanceTimer = setTimeout(enhanceReportDetail, 50);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', scheduleEnhanceReportDetail);
    } else {
        scheduleEnhanceReportDetail();
    }

    if (window.MutationObserver) {
        var sidebarRoot = document.getElementById('map_sidebar') || document.body;
        var observer = new MutationObserver(function(mutations) {
            for (var i = 0; i < mutations.length; i++) {
                var mutation = mutations[i];
                for (var j = 0; j < mutation.addedNodes.length; j++) {
                    var node = mutation.addedNodes[j];
                    if (node.nodeType !== 1) continue;
                    if (
                        node.id === 'side-report' ||
                        (node.querySelector && node.querySelector('#side-report, .problem-header'))
                    ) {
                        scheduleEnhanceReportDetail();
                        return;
                    }
                }
            }
        });
        observer.observe(sidebarRoot, { childList: true, subtree: true });
    }
})();
