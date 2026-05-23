/* InfraSignal reports dashboard charts. Vanilla JS, no dependencies. */
(function () {
  'use strict';

  function parseSeries(el) {
    try {
      return JSON.parse(el.getAttribute('data-series') || '[]');
    } catch (e) {
      return [];
    }
  }

  function size(el) {
    var rect = el.getBoundingClientRect();
    return {
      w: Math.max(280, Math.floor(rect.width)),
      h: Math.max(120, Math.floor(rect.height))
    };
  }

  function svgEl(name, attrs) {
    var node = document.createElementNS('http://www.w3.org/2000/svg', name);
    if (attrs) {
      Object.keys(attrs).forEach(function (key) {
        node.setAttribute(key, attrs[key]);
      });
    }
    return node;
  }

  function renderArea(el) {
    var data = parseSeries(el);
    if (!data.length) return;

    var dim = size(el);
    var pad = { t: 16, r: 16, b: 28, l: 36 };
    var width = dim.w;
    var height = dim.h;
    var innerWidth = width - pad.l - pad.r;
    var innerHeight = height - pad.t - pad.b;
    var maxY = 0;

    data.forEach(function (item) {
      if (item.reported > maxY) maxY = item.reported;
      if (item.fixed > maxY) maxY = item.fixed;
    });
    maxY = Math.ceil(maxY / 10) * 10 || 10;

    var x = function (index) {
      return pad.l + (innerWidth * index) / (data.length - 1 || 1);
    };
    var y = function (value) {
      return pad.t + innerHeight - (innerHeight * value) / maxY;
    };

    var svg = svgEl('svg', {
      viewBox: '0 0 ' + width + ' ' + height,
      width: '100%',
      height: '100%'
    });

    var defs = svgEl('defs');
    [
      ['rd-grad-reported', '#1E40AF', 0.25],
      ['rd-grad-fixed', '#059669', 0.2]
    ].forEach(function (gradient) {
      var linear = svgEl('linearGradient', { id: gradient[0], x1: '0', y1: '0', x2: '0', y2: '1' });
      linear.appendChild(svgEl('stop', { offset: '5%', 'stop-color': gradient[1], 'stop-opacity': gradient[2] }));
      linear.appendChild(svgEl('stop', { offset: '95%', 'stop-color': gradient[1], 'stop-opacity': '0' }));
      defs.appendChild(linear);
    });
    svg.appendChild(defs);

    for (var tick = 0; tick <= 4; tick++) {
      var value = (maxY / 4) * tick;
      var gridY = y(value);
      svg.appendChild(svgEl('line', {
        x1: pad.l,
        x2: width - pad.r,
        y1: gridY,
        y2: gridY,
        class: 'rd-chart__grid'
      }));
      var label = svgEl('text', {
        x: pad.l - 8,
        y: gridY + 4,
        'text-anchor': 'end',
        class: 'rd-chart__axis'
      });
      label.textContent = Math.round(value);
      svg.appendChild(label);
    }

    data.forEach(function (item, index) {
      var label = svgEl('text', {
        x: x(index),
        y: height - 8,
        'text-anchor': 'middle',
        class: 'rd-chart__axis'
      });
      label.textContent = item.month;
      svg.appendChild(label);
    });

    function pathFor(key) {
      return data.map(function (item, index) {
        return (index === 0 ? 'M' : 'L') + x(index) + ' ' + y(item[key]);
      }).join(' ');
    }

    function areaFor(key) {
      var line = pathFor(key);
      return line + ' L' + x(data.length - 1) + ' ' + (pad.t + innerHeight) +
        ' L' + x(0) + ' ' + (pad.t + innerHeight) + ' Z';
    }

    svg.appendChild(svgEl('path', { d: areaFor('reported'), class: 'rd-chart__area-a' }));
    svg.appendChild(svgEl('path', { d: areaFor('fixed'), class: 'rd-chart__area-b' }));
    svg.appendChild(svgEl('path', { d: pathFor('reported'), class: 'rd-chart__line-a' }));
    svg.appendChild(svgEl('path', { d: pathFor('fixed'), class: 'rd-chart__line-b' }));

    el.innerHTML = '';
    el.appendChild(svg);
  }

  function renderBar(el) {
    var data = parseSeries(el);
    if (!data.length) return;

    var dim = size(el);
    var pad = { t: 8, r: 8, b: 22, l: 28 };
    var width = dim.w;
    var height = dim.h;
    var innerWidth = width - pad.l - pad.r;
    var innerHeight = height - pad.t - pad.b;
    var maxY = data.reduce(function (max, item) {
      return item.reports > max ? item.reports : max;
    }, 0);
    maxY = Math.ceil(maxY / 5) * 5 || 5;

    var barWidth = (innerWidth / data.length) * 0.6;
    var gap = (innerWidth / data.length) * 0.4;
    var svg = svgEl('svg', {
      viewBox: '0 0 ' + width + ' ' + height,
      width: '100%',
      height: '100%'
    });

    data.forEach(function (item, index) {
      var barHeight = (innerHeight * item.reports) / maxY;
      var barX = pad.l + index * (barWidth + gap) + gap / 2;
      var barY = pad.t + innerHeight - barHeight;

      svg.appendChild(svgEl('rect', {
        x: barX,
        y: barY,
        width: barWidth,
        height: barHeight,
        rx: 6,
        ry: 6,
        class: 'rd-chart__bar'
      }));

      var label = svgEl('text', {
        x: barX + barWidth / 2,
        y: height - 6,
        'text-anchor': 'middle',
        class: 'rd-chart__axis'
      });
      label.textContent = item.day;
      svg.appendChild(label);
    });

    el.innerHTML = '';
    el.appendChild(svg);
  }

  function renderAll() {
    document.querySelectorAll('.rd-chart').forEach(function (el) {
      var type = el.getAttribute('data-chart');
      if (type === 'area') renderArea(el);
      if (type === 'bar') renderBar(el);
    });
  }

  function syncPickerAutocomplete() {
    var input = document.querySelector('.rd-picker .autocomplete__input');
    var select = document.querySelector('.rd-picker select');
    if (!input || !select || input.getAttribute('placeholder')) return;

    var firstOption = select.querySelector('option');
    if (firstOption && firstOption.textContent) {
      input.setAttribute('placeholder', firstOption.textContent.trim());
    }
  }

  function init() {
    renderAll();
    window.setTimeout(syncPickerAutocomplete, 0);
  }

  var resizeTimer = null;
  window.addEventListener('resize', function () {
    window.clearTimeout(resizeTimer);
    resizeTimer = window.setTimeout(renderAll, 120);
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();