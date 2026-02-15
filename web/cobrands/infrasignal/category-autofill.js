/**
 * InfraSignal - Category Auto-fill
 * Pre-populates the title and detail fields with default text
 * based on the selected category. Users can edit the pre-filled text.
 */
(function() {
    'use strict';

    var categoryDefaults = {
        'Abandoned Vehicle': {
            title: 'Abandoned vehicle on the road',
            detail: 'There is an abandoned vehicle at this location. It appears to have been left here for an extended period. Please investigate and arrange for removal if necessary.'
        },
        'Bridge / Guardrail Damage': {
            title: 'Damaged bridge/guardrail needs repair',
            detail: 'There is damage to the bridge or guardrail at this location. The damage may pose a safety risk to pedestrians and vehicles. Please inspect and repair as soon as possible.'
        },
        'Drainage / Flooding': {
            title: 'Drainage issue / flooding at this location',
            detail: 'There is a drainage problem or flooding at this location. Water is accumulating and may be affecting traffic or pedestrian access. Please investigate and resolve the drainage issue.'
        },
        'Fallen Tree / Vegetation': {
            title: 'Fallen tree / overgrown vegetation',
            detail: 'There is a fallen tree or overgrown vegetation at this location that is obstructing the roadway, sidewalk, or public area. Please arrange for removal or trimming.'
        },
        'Graffiti / Vandalism': {
            title: 'Graffiti or vandalism reported',
            detail: 'There is graffiti or vandalism at this location on public property. Please arrange for cleanup or repair of the affected area.'
        },
        'Illegal Dumping': {
            title: 'Illegal dumping of waste/debris',
            detail: 'There is evidence of illegal dumping at this location. Waste or debris has been improperly disposed of in a public area. Please investigate and arrange for cleanup.'
        },
        'Park / Public Space Issue': {
            title: 'Issue in park / public space',
            detail: 'There is an issue at this park or public space that requires attention. The problem is affecting the usability or safety of the area. Please inspect and address accordingly.'
        },
        'Pothole / Road Damage': {
            title: 'Pothole / road damage needs repair',
            detail: 'There is a pothole or road damage at this location that poses a hazard to vehicles and may cause accidents. Please repair the road surface as soon as possible.'
        },
        'Sidewalk Damage': {
            title: 'Damaged sidewalk needs repair',
            detail: 'There is damage to the sidewalk at this location. The uneven or broken surface may pose a tripping hazard to pedestrians. Please repair or replace the affected section.'
        },
        'Streetlight Outage': {
            title: 'Streetlight out / malfunctioning',
            detail: 'A streetlight at this location is not working or is malfunctioning. The lack of lighting may create safety concerns for pedestrians and drivers during nighttime. Please inspect and repair.'
        },
        'Traffic Signal / Sign Issue': {
            title: 'Traffic signal or sign issue',
            detail: 'There is an issue with a traffic signal or road sign at this location. It may be damaged, obscured, or not functioning properly. Please inspect and repair to ensure traffic safety.'
        },
        'Water / Sewer Issue': {
            title: 'Water or sewer issue reported',
            detail: 'There is a water or sewer issue at this location, such as a leak, backup, or broken main. Please investigate and repair to prevent further damage or health concerns.'
        },
        'Other': {
            title: '',
            detail: ''
        }
    };

    function applyDefaults(category) {
        if (!category) return;

        var defaults = categoryDefaults[category];
        if (!defaults) return;

        var $title = $('#form_title');
        var $detail = $('#form_detail');

        // Only auto-fill if the field is empty or contains a previous auto-fill
        if ($title.length && defaults.title) {
            var currentTitle = $title.val().trim();
            var isAutoFilled = $title.data('autofilled');
            var previousDefault = $title.data('default-text') || '';

            if (!currentTitle || (isAutoFilled && currentTitle === previousDefault)) {
                $title.val(defaults.title);
                $title.data('autofilled', true);
                $title.data('default-text', defaults.title);
            }
        }

        if ($detail.length && defaults.detail) {
            var currentDetail = $detail.val().trim();
            var isDetailAutoFilled = $detail.data('autofilled');
            var previousDetailDefault = $detail.data('default-text') || '';

            if (!currentDetail || (isDetailAutoFilled && currentDetail === previousDetailDefault)) {
                $detail.val(defaults.detail);
                $detail.data('autofilled', true);
                $detail.data('default-text', defaults.detail);
            }
        }
    }

    function init() {
        if (typeof $ === 'undefined' || typeof fixmystreet === 'undefined') {
            return;
        }

        // Listen for category changes
        $(fixmystreet).on('report_new:category_change', function() {
            var selected = fixmystreet.reporting.selectedCategory();
            if (selected && selected.category) {
                applyDefaults(selected.category);
            }
        });

        // Also handle direct radio button changes
        $(document).on('change', '#form_category_fieldset input[type="radio"]', function() {
            var category = $(this).data('valuealone') || $(this).val();
            if (category) {
                applyDefaults(category);
            }
        });

        // Clear auto-fill flag when user manually edits
        $(document).on('input', '#form_title, #form_detail', function() {
            $(this).data('autofilled', false);
        });
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        // Small delay to ensure fixmystreet object is ready
        setTimeout(init, 100);
    }
})();
