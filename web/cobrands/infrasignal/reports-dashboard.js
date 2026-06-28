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

  function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
  }

  function smoothPath(points) {
    if (!points.length) return '';
    if (points.length === 1) return 'M' + points[0].x + ' ' + points[0].y;

    var path = 'M' + points[0].x + ' ' + points[0].y;
    for (var index = 0; index < points.length - 1; index++) {
      var previous = points[index - 1] || points[index];
      var current = points[index];
      var next = points[index + 1];
      var after = points[index + 2] || next;
      var cp1x = current.x + (next.x - previous.x) / 6;
      var cp1y = current.y + (next.y - previous.y) / 6;
      var cp2x = next.x - (after.x - current.x) / 6;
      var cp2y = next.y - (after.y - current.y) / 6;
      path += ' C' + cp1x + ' ' + cp1y + ' ' + cp2x + ' ' + cp2y + ' ' + next.x + ' ' + next.y;
    }
    return path;
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

    function pointsFor(key) {
      return data.map(function (item, index) {
        return { x: x(index), y: y(item[key]) };
      });
    }

    function pathFor(key) {
      return smoothPath(pointsFor(key));
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

    var hoverLine = svgEl('line', {
      x1: pad.l,
      x2: pad.l,
      y1: pad.t,
      y2: pad.t + innerHeight,
      class: 'rd-chart__hover-line'
    });
    var reportedDot = svgEl('circle', { r: 4, class: 'rd-chart__hover-dot rd-chart__hover-dot--reported' });
    var fixedDot = svgEl('circle', { r: 4, class: 'rd-chart__hover-dot rd-chart__hover-dot--fixed' });
    svg.appendChild(hoverLine);
    svg.appendChild(reportedDot);
    svg.appendChild(fixedDot);

    el.innerHTML = '';
    el.appendChild(svg);

    var tooltip = document.createElement('div');
    tooltip.className = 'rd-chart__tooltip';
    el.appendChild(tooltip);

    function hideHover() {
      hoverLine.style.display = 'none';
      reportedDot.style.display = 'none';
      fixedDot.style.display = 'none';
      tooltip.style.display = 'none';
    }

    function showHover(event) {
      var rect = el.getBoundingClientRect();
      var mouseX = clamp(event.clientX - rect.left, pad.l, width - pad.r);
      var ratio = innerWidth ? (mouseX - pad.l) / innerWidth : 0;
      var index = clamp(Math.round(ratio * (data.length - 1)), 0, data.length - 1);
      var item = data[index];
      var pointX = x(index);
      var reportedY = y(item.reported);
      var fixedY = y(item.fixed);

      hoverLine.setAttribute('x1', pointX);
      hoverLine.setAttribute('x2', pointX);
      reportedDot.setAttribute('cx', pointX);
      reportedDot.setAttribute('cy', reportedY);
      fixedDot.setAttribute('cx', pointX);
      fixedDot.setAttribute('cy', fixedY);

      hoverLine.style.display = 'block';
      reportedDot.style.display = 'block';
      fixedDot.style.display = 'block';

      tooltip.innerHTML = '<strong>' + item.month + '</strong>' +
        '<span class="rd-chart__tooltip-reported">reported : ' + item.reported + '</span>' +
        '<span class="rd-chart__tooltip-fixed">fixed : ' + item.fixed + '</span>';
      tooltip.style.display = 'block';

      var tooltipWidth = tooltip.offsetWidth;
      var tooltipHeight = tooltip.offsetHeight;
      var tooltipLeft = pointX + 14;
      if (tooltipLeft + tooltipWidth > width - 8) tooltipLeft = pointX - tooltipWidth - 14;
      tooltip.style.left = clamp(tooltipLeft, 8, width - tooltipWidth - 8) + 'px';
      tooltip.style.top = clamp(Math.min(reportedY, fixedY) - 16, 8, height - tooltipHeight - 8) + 'px';
    }

    hideHover();
    el.onmousemove = showHover;
    el.onmouseleave = hideHover;
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

  function renderSpark(el) {
    var data = parseSeries(el).map(function (value) {
      return Number(value) || 0;
    });
    if (!data.length) return;

    var maxY = data.reduce(function (max, value) {
      return value > max ? value : max;
    }, 0);

    el.innerHTML = '';
    data.forEach(function (value, index) {
      var bar = document.createElement('span');
      var height = maxY ? Math.max(10, (value / maxY) * 100) : 0;
      bar.className = 'rd-spark__bar' + (index === data.length - 1 ? ' is-current' : '');
      bar.style.height = height + '%';
      el.appendChild(bar);
    });
  }

  function renderAll() {
    document.querySelectorAll('.rd-chart').forEach(function (el) {
      var type = el.getAttribute('data-chart');
      if (type === 'area') renderArea(el);
      if (type === 'bar') renderBar(el);
      if (type === 'spark') renderSpark(el);
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