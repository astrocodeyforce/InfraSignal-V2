// InfraSignal — Dashboard chart overrides
// Runs after dashboard.js to restyle the "All Time" chart to match Lovable design
$(function(){
    // Wait for dashboard.js to create the chart
    if (!window.chartAllReports) return;

    var chart = window.chartAllReports;
    var datasets = chart.config.data.datasets;

    // Reported line: blue (#1E40AF) instead of orange
    if (datasets[0]) {
        datasets[0].borderColor = '#1E40AF';
        datasets[0].pointBackgroundColor = '#1E40AF';
        datasets[0].borderWidth = 2;
        datasets[0].fill = false;
    }
    // Fixed line: green (#059669) instead of green with different shade
    if (datasets[1]) {
        datasets[1].borderColor = '#059669';
        datasets[1].pointBackgroundColor = '#059669';
        datasets[1].borderWidth = 2;
        datasets[1].fill = false;
    }

    // Show y-axis ticks and gridlines, hide x-axis gridlines
    var opts = chart.config.options;
    if (opts.scales && opts.scales.yAxes && opts.scales.yAxes[0]) {
        opts.scales.yAxes[0].ticks.display = true;
        opts.scales.yAxes[0].ticks.fontColor = '#6B7280';
        opts.scales.yAxes[0].ticks.fontSize = 12;
        opts.scales.yAxes[0].ticks.beginAtZero = true;
        opts.scales.yAxes[0].gridLines = {
            display: true,
            color: 'rgba(0,0,0,0.06)',
            drawBorder: false
        };
    }
    if (opts.scales && opts.scales.xAxes && opts.scales.xAxes[0]) {
        opts.scales.xAxes[0].ticks = opts.scales.xAxes[0].ticks || {};
        opts.scales.xAxes[0].ticks.fontColor = '#6B7280';
        opts.scales.xAxes[0].ticks.fontSize = 12;
    }

    // Ensure smooth curves
    opts.elements = opts.elements || {};
    opts.elements.line = opts.elements.line || {};
    opts.elements.line.cubicInterpolationMode = 'monotone';
    opts.elements.line.tension = 0.4;

    chart.update();
});
