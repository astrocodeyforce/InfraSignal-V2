(function () {
    'use strict';

    function text(node) {
        return (node && node.textContent || '').replace(/\s+/g, ' ').trim();
    }

    function parseDate(value) {
        var match = value.match(/Created:\s*(\d{4}-\d{2}-\d{2})/i);
        if (!match) {
            return null;
        }
        var parts = match[1].split('-').map(Number);
        return new Date(parts[0], parts[1] - 1, parts[2]);
    }

    function dateKey(date) {
        return [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');
    }

    function addDays(date, days) {
        var next = new Date(date.getTime());
        next.setDate(next.getDate() + days);
        return next;
    }

    function getDashboardData() {
        var node = document.querySelector('[data-admin-dashboard]');
        if (!node) {
            return null;
        }

        var json = node.getAttribute('data-admin-dashboard');
        if (!json) {
            return null;
        }

        try {
            return JSON.parse(json);
        } catch (error) {
            return null;
        }
    }

    function getReports() {
        return Array.prototype.slice.call(document.querySelectorAll('.infra-admin-table tr')).slice(1).map(function (row) {
            var cells = row.querySelectorAll('td');
            if (cells.length < 5) {
                return null;
            }

            var bodyLines = (cells[3].innerText || '').split('\n').map(function (line) { return line.trim(); }).filter(Boolean);
            var stateLines = (cells[4].innerText || '').split('\n').map(function (line) { return line.trim(); }).filter(Boolean);

            return {
                category: bodyLines[0] || 'Other',
                status: stateLines[0] || 'Unknown',
                created: parseDate(cells[4].innerText || '')
            };
        }).filter(Boolean);
    }

    function countBy(items, key) {
        return items.reduce(function (counts, item) {
            var value = item[key] || 'Unknown';
            counts[value] = (counts[value] || 0) + 1;
            return counts;
        }, {});
    }

    function sortedEntries(counts) {
        return Object.keys(counts).map(function (name) {
            return { name: name, count: counts[name] };
        }).sort(function (a, b) {
            return b.count - a.count || a.name.localeCompare(b.name);
        });
    }

    function renderBarValues(days) {
        var chart = document.querySelector('[data-admin-bar-chart]');
        if (!chart) {
            return;
        }

        var bars = Array.prototype.slice.call(chart.querySelectorAll('.infra-admin-bar'));
        var values = days.map(function (day) { return day.count || 0; });
        var max = Math.max.apply(Math, values.concat([1]));

        bars.forEach(function (bar, index) {
            var day = days[index] || { label: '', date: '', count: 0 };
            var value = day.count || 0;
            var percent = value ? Math.max(12, Math.round((value / max) * 100)) : 0;
            bar.classList.toggle('infra-admin-bar--empty', !value);
            bar.style.setProperty('--bar', percent + '%');
            bar.querySelector('strong').textContent = value;
            bar.querySelector('span').textContent = day.label || day.date || '';
            bar.setAttribute('title', value + ' reports on ' + day.date);
        });
    }

    function renderBars(reports) {
        var chart = document.querySelector('[data-admin-bar-chart]');
        if (!chart) {
            return;
        }

        var datedReports = reports.filter(function (report) { return report.created; });
        var bars = Array.prototype.slice.call(chart.querySelectorAll('.infra-admin-bar'));
        if (!datedReports.length) {
            bars.forEach(function (bar) {
                bar.classList.add('infra-admin-bar--empty');
                bar.style.setProperty('--bar', '0%');
                bar.querySelector('strong').textContent = '0';
            });
            return;
        }

        var latest = datedReports.reduce(function (max, report) {
            return report.created > max ? report.created : max;
        }, datedReports[0].created);

        var days = [];
        for (var offset = -6; offset <= 0; offset += 1) {
            days.push(addDays(latest, offset));
        }

        var counts = datedReports.reduce(function (accumulator, report) {
            var key = dateKey(report.created);
            accumulator[key] = (accumulator[key] || 0) + 1;
            return accumulator;
        }, {});

        var values = days.map(function (day) { return counts[dateKey(day)] || 0; });
        var max = Math.max.apply(Math, values.concat([1]));
        var formatter = new Intl.DateTimeFormat(undefined, { weekday: 'short' });

        renderBarValues(days.map(function (day, index) {
            return { date: dateKey(day), label: formatter.format(day), count: values[index] || 0 };
        }));
    }

    function colorClass(index, name) {
        var normalized = (name || '').toLowerCase();
        if (/fixed|closed/.test(normalized)) {
            return 'infra-admin-dot--green';
        }
        if (/progress|investigating|confirmed|planned/.test(normalized)) {
            return 'infra-admin-dot--amber';
        }
        return ['infra-admin-dot--blue', 'infra-admin-dot--sky', 'infra-admin-dot--pale', 'infra-admin-dot--gray'][index % 4];
    }

    function renderDonut(selector, legendSelector, entries, limit) {
        var donut = document.querySelector(selector);
        var legend = document.querySelector(legendSelector);
        if (!donut || !legend) {
            return;
        }

        var total = entries.reduce(function (sum, entry) { return sum + entry.count; }, 0);
        legend.innerHTML = '';

        if (!total) {
            donut.style.background = '#e5e7eb';
            legend.innerHTML = '<div><span class="infra-admin-dot infra-admin-dot--gray"></span><span>No data</span><strong>0%</strong></div>';
            return;
        }

        var visible = entries.slice(0, limit);
        var remainder = entries.slice(limit).reduce(function (sum, entry) { return sum + entry.count; }, 0);
        if (remainder) {
            visible.push({ name: 'Other', count: remainder });
        }

        var colorStops = [];
        var cursor = 0;
        var colors = ['#1e40af', '#3b82f6', '#93c5fd', '#d1d5db', '#d97706', '#10b981'];

        visible.forEach(function (entry, index) {
            var start = cursor;
            var size = (entry.count / total) * 100;
            cursor += size;
            colorStops.push(colors[index % colors.length] + ' ' + start.toFixed(2) + '% ' + cursor.toFixed(2) + '%');

            var percent = Math.round((entry.count / total) * 100);
            var row = document.createElement('div');
            row.innerHTML = '<span class="infra-admin-dot ' + colorClass(index, entry.name) + '"></span><span></span><strong></strong>';
            row.querySelector('span:nth-child(2)').textContent = entry.name;
            row.querySelector('strong').textContent = percent + '%';
            row.setAttribute('title', entry.count + ' reports');
            legend.appendChild(row);
        });

        donut.style.background = 'conic-gradient(' + colorStops.join(', ') + ')';
    }

    function init() {
        var dashboardData = getDashboardData();
        if (dashboardData) {
            renderBarValues(dashboardData.dailyReports || []);
            renderDonut('[data-admin-category-donut]', '[data-admin-category-legend]', dashboardData.categories || [], 3);
            renderDonut('[data-admin-status-donut]', '[data-admin-status-legend]', dashboardData.statuses || [], 4);
            return;
        }

        var reports = getReports();
        if (!reports.length) {
            return;
        }

        renderBars(reports);
        renderDonut('[data-admin-category-donut]', '[data-admin-category-legend]', sortedEntries(countBy(reports, 'category')), 3);
        renderDonut('[data-admin-status-donut]', '[data-admin-status-legend]', sortedEntries(countBy(reports, 'status')), 4);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
}());