import { d as defineComponent, x as computed, h_ as GRANULARITY_DATE_FORMAT_MASK, c as useI18n, e as createBlock, g as openBlock, m as unref, i2 as index, i3 as transformInsightsTimeSaved, i1 as INSIGHTS_UNIT_MAPPING } from "./index-CKxPg00R.js";
import { a as generateLineChartOptions, b as generateLinearGradient } from "./chartjs.utils-BaFuULEH.js";
import { L as Line } from "./index-DakiuyrJ.js";
import "./InsightsSummary-CzLvoz3i.js";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "InsightsChartTimeSaved",
  props: {
    data: {},
    type: {},
    granularity: {}
  },
  setup(__props) {
    const props = __props;
    const i18n = useI18n();
    const chartOptions = computed(
      () => generateLineChartOptions({
        plugins: {
          tooltip: {
            callbacks: {
              label: (context) => {
                const label = context.dataset.label ?? "";
                const value = Number(context.parsed.y);
                return `${label} ${transformInsightsTimeSaved(value).toLocaleString("en-US")}${INSIGHTS_UNIT_MAPPING[props.type](value)}`;
              }
            }
          }
        },
        scales: {
          y: {
            ticks: {
              // eslint-disable-next-line id-denylist
              callback(tickValue) {
                return transformInsightsTimeSaved(Number(tickValue));
              }
            }
          }
        }
      })
    );
    const chartData = computed(() => {
      const labels = [];
      const data = [];
      for (const entry of props.data) {
        labels.push(GRANULARITY_DATE_FORMAT_MASK[props.granularity](entry.date));
        data.push(entry.values.timeSaved);
      }
      return {
        labels,
        datasets: [
          {
            label: i18n.baseText("insights.banner.title.timeSaved"),
            data,
            fill: "origin",
            cubicInterpolationMode: "monotone",
            backgroundColor: (ctx) => generateLinearGradient(ctx.chart.ctx, 292),
            borderColor: "rgba(255, 64, 39, 1)"
          }
        ]
      };
    });
    return (_ctx, _cache) => {
      return openBlock(), createBlock(unref(Line), {
        data: chartData.value,
        options: chartOptions.value,
        plugins: [unref(index)]
      }, null, 8, ["data", "options", "plugins"]);
    };
  }
});
export {
  _sfc_main as default
};
