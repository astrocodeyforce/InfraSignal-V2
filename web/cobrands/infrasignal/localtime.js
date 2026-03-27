// Progressive enhancement: convert server-rendered timestamps to the viewer's
// local timezone. Elements with class "js-localtime" and a data-epoch attribute
// (Unix seconds) get their displayed time replaced. The server-rendered text
// (in America/Chicago) is the fallback for no-JS.
(function() {
    'use strict';

    function pad(n) { return n < 10 ? '0' + n : '' + n; }

    function formatLocalTime(dt) {
        return pad(dt.getHours()) + ':' + pad(dt.getMinutes());
    }

    function relativeDate(dt) {
        var now = new Date();
        var today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        var target = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate());
        var diffDays = Math.round((today - target) / 86400000);

        if (diffDays === 0) return 'today';
        if (diffDays === 1) return 'yesterday';
        if (diffDays > 1 && diffDays < 7) {
            return dt.toLocaleDateString(undefined, { weekday: 'long' });
        }
        if (dt.getFullYear() === now.getFullYear()) {
            return dt.toLocaleDateString(undefined, {
                weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
            });
        }
        return dt.toLocaleDateString(undefined, {
            weekday: 'short', day: 'numeric', month: 'long', year: 'numeric'
        });
    }

    function formatLocalDateTime(dt) {
        var time = formatLocalTime(dt);
        var date = relativeDate(dt);
        return date === 'today' ? time + ' today' : time + ', ' + date;
    }

    function convertAll() {
        var elements = document.querySelectorAll('.js-localtime[data-epoch]');
        for (var i = 0; i < elements.length; i++) {
            var el = elements[i];
            var epoch = parseInt(el.getAttribute('data-epoch'), 10);
            if (isNaN(epoch)) continue;

            var dt = new Date(epoch * 1000);
            if (isNaN(dt.getTime())) continue;

            var localStr = formatLocalDateTime(dt);
            var text = el.textContent || el.innerText;

            // Report detail meta_line: "Reported via X anonymously at HH:MM today"
            // The time+date is always after the last " at " in the string.
            var atIdx = text.lastIndexOf(' at ');
            if (atIdx !== -1) {
                el.textContent = text.substring(0, atIdx + 4) + localStr;
            } else {
                // Report list items: just the formatted date/time string
                el.textContent = localStr;
            }
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', convertAll);
    } else {
        convertAll();
    }
})();
