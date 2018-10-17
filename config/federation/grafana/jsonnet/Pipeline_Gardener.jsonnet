local grafana = import 'grafonnet/grafana.libsonnet';
local graphPanel = grafana.graphPanel;
local dashboard = grafana.dashboard;
local target = grafana.prometheus.target;
local height = 6;

dashboard.new('AAA: jsonnet Gardener',
  schemaVersion=16,
  editable=true,
  time_from='now-24h',
  timezone='utc')
.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    'Data Proc (mlab-oti)',
    label='Datasource',
    regex='/Data Proc.*/',
  )
)
.addTemplate(
  grafana.template.new(
    'deployment',
    '$datasource',
    'label_values(up{deployment=~"etl-gardener-.*"}, deployment)',
    label='Gardener Deployment',
    includeAll=true,
    allValues='.*',
    refresh=2,
    sort=1,
  )
)
.addPanel(
  graphPanel.new('Tasks In Flight',
    datasource='$datasource', legend_show=false)
  .addTarget(target(
    'gardener_tasks_in_flight{deployment=~"$deployment"}',
    legendFormat='{{deployment}}', intervalFactor=1)),
  gridPos={x: 0, y: 0, w: 6, h: height}
)
.addPanel(
  graphPanel.new('GoRoutine Count',
    datasource='$datasource', legend_show=false, min=0)
  .addTarget(target(
    'go_goroutines{container="etl-gardener", deployment=~"$deployment"}',
    legendFormat='{{deployment}}', intervalFactor=1)),
  gridPos={x: 6, y: 0, w: 6, h: height}
)
.addPanel(
  graphPanel.new('CPU Utilization',
    datasource='$datasource', legend_show=false, format="percentunit")
  .addTarget(target(
    'rate(process_cpu_seconds_total{container="etl-gardener", deployment=~"$deployment"}[5m])',
    legendFormat='{{deployment}}', intervalFactor=1)),
  gridPos={x: 12, y: 0, w: 6, h: height}
)
.addPanel(
  graphPanel.new('Virtual Memory',
    datasource='$datasource', legend_show=false, min=0, format="decbytes")
  .addTarget(target(
    'process_virtual_memory_bytes{container="etl-gardener", deployment=~"$deployment"}',
    legendFormat='{{deployment}}', intervalFactor=1)),
  gridPos={x: 18, y: 0, w: 6, h: height}
)
.addPanel(
  // next row.
  graphPanel.new('Warnings and Failures Total',
    datasource='$datasource', legend_show=false)
  .addTarget(target(
    'gardener_warning_total{container="etl-gardener", deployment=~"$deployment"}',
    legendFormat='Warning: {{status}}', intervalFactor=1))
  .addTarget(target(
    'gardener_fail_total{container="etl-gardener", deployment=~"$deployment"}',
    legendFormat='Failure: {{status}}', intervalFactor=1))
  .addSeriesOverride({alias: "/Warning:/", color: "#e5ac0e"})
  .addSeriesOverride({alias: "/Failure:/", color: "#bf1b00"}),
  gridPos={x: 0, y: height, w: 12, h: height}
)
.addPanel(
  // next row.
  graphPanel.new('Start and Completion Rate (hourly)',
    description="Number of tasks started and completed, per hour.",
    datasource='$datasource', legend_show=false)
  .addTarget(target(
    'sum by(deployment) (increase(gardener_started_total{deployment=~"$deployment"}[1h]))',
    legendFormat='Started: {{deployment}}', intervalFactor=1))
  .addTarget(target(
    'sum by(deployment) (-increase(gardener_completed_total{deployment=~"$deployment"}[1h]))',
    legendFormat='Completed: {{deployment}}', intervalFactor=1))
  .resetYaxes().addYaxis('short', label='Tasks / Hour').addYaxis('short')
  .addSeriesOverride({"alias": "/disco/", "color": "#508642" })
  .addSeriesOverride({"alias": "/ndt/", "color": "#cca300" })
  .addSeriesOverride({"alias": "/sidestream/", "color": "#e24d42" }),
  gridPos={x: 0, y: 2*height, w: 12, h: height}
)
.addPanel(
  graphPanel.new('Time in State',
    datasource='$datasource', legend_show=false,
    nullPointMode='connected', points=true, fill=0)
    {pointradius: 0.5}
  .addTarget(target(
    'sum by(deployment, quantile, state)(-gardener_state_time_summary{quantile="0.5", deployment=~"$deployment"})',
    legendFormat='q:{{quantile}} {{state}} {{deployment}}', intervalFactor=1))
  .resetYaxes().addYaxis('s', logBase=10, min=0.1).addYaxis('short'),
  gridPos={x: 12, y: 7, w: 12, h: 2*height}
)
/*.addPanel(
  graphPanel.new('Instance Uptime',
    datasource='$datasource', legend_show=false, fill=0)
  .addTarget(target(
    'sum by(instance)(time()-process_start_time_seconds{container="etl-gardener", deployment=~".*"})',
    legendFormat='{{deployment}}'))
  .resetYaxes().addYaxis('dtdurations', logBase=10, min=60).addYaxis('short'),
  gridPos={x: 0, y: 3*height, w: 12, h: height}
)*/
.addPanel(
  graphPanel.new('SLO: Completion Rate (Tasks / day)',
    datasource='$datasource', legend_show=false)
  .addTarget(target(
    'sum by(deployment) (increase(gardener_completed_total{deployment=~"$deployment"}[24h]))',
    legendFormat='Completed: {{deployment}}', intervalFactor=1))
  .resetYaxes().addYaxis('short', label='Tasks / Day').addYaxis('short')
  .addSeriesOverride({"alias": "/disco/", "color": "#508642" })
  .addSeriesOverride({"alias": "/ndt/", "color": "#cca300" })
  .addSeriesOverride({"alias": "/sidestream/", "color": "#e24d42" }) {
    thresholds: [{
      "colorMode": "critical",
      "fill": true,
      "line": true,
      "op": "lt",
      "value": 40,
      "yaxis": "left"
    }],
  },
  gridPos={x: 0, y: 3*height, w: 12, h: height}
)
.addPanel(
  // Example using raw JSON panel definition.
  {
  "aliasColors": {},
  "bars": false,
  "dashLength": 10,
  "dashes": false,
  "datasource": "$datasource",
  "description": "Task dates of the most recent updates to each task state.",
  "fill": 0,
  "id": 15,
  "legend": {
    "avg": false,
    "current": false,
    "max": false,
    "min": false,
    "show": false,
    "total": false,
    "values": false
  },
  "lines": true,
  "linewidth": 1,
  "links": [],
  "nullPointMode": "null",
  "percentage": false,
  "pointradius": 5,
  "points": false,
  "renderer": "flot",
  "seriesOverrides": [],
  "spaceLength": 10,
  "stack": false,
  "steppedLine": false,
  "targets": [
    {
      "expr": "1000*min_over_time(gardener_state_date{deployment=~\"$deployment\"}[1h])",
      "format": "time_series",
      "hide": false,
      "intervalFactor": 1,
      "legendFormat": "{{deployment}} {{state}}",
      "refId": "A"
    }
  ],
  "thresholds": [],
  "timeFrom": null,
  "timeShift": null,
  "title": "Task Date of Recent State Updates",
  "tooltip": {
    "shared": true,
    "sort": 2,
    "value_type": "individual"
  },
  "type": "graph",
  "xaxis": {
    "buckets": null,
    "mode": "time",
    "name": null,
    "show": true,
    "values": []
  },
  "yaxes": [
    {
      "decimals": null,
      "format": "dateTimeAsIso",
      "label": "State update for task date",
      "logBase": 1,
      "max": null,
      "min": null,
      "show": true
    },
    {
      "format": "short",
      "label": null,
      "logBase": 1,
      "max": null,
      "min": null,
      "show": true
    }
  ],
  "yaxis": {
    "align": false,
    "alignLevel": null
  }
},
  gridPos={x: 12, y: 3*height, w: 12, h: height},
)