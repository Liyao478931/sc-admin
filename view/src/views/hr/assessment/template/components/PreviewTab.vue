<!--
  文件：admin/src/views/hr/assessment/template/components/PreviewTab.vue
  功能：预览（模拟考核表展示 + 导出 Excel + 打印预览）
-->
<template>
  <div class="preview-tab">
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'assessment:template:export'" type="primary" size="small" icon="el-icon-download" :loading="exporting" @click="doExport">导出为 Excel</el-button>
        <el-button size="small" icon="el-icon-printer" @click="doPrint">打印预览</el-button>
      </div>
      <span class="total-text">共 {{ summary.total }} 个计分项 · 总分 {{ summary.score }} 分 · {{ summary.groups }} 个分组</span>
    </div>

    <div class="preview-table-wrap" id="previewArea">
      <table class="preview-table" border="1" cellspacing="0" cellpadding="0">
        <thead>
          <tr>
            <th colspan="6">{{ template.name || '考核模板' }}（{{ template.code || '' }}）</th>
          </tr>
          <tr>
            <th colspan="6" class="sub-head">适用岗位：{{ template.category || '-' }}　周期：{{ periodText }}　总分：{{ summary.score }} 分</th>
          </tr>
          <tr>
            <th style="width:52px">序号</th>
            <th style="width:120px">考核大类</th>
            <th>考核内容</th>
            <th style="width:70px">分值</th>
            <th style="width:220px">评分标准</th>
            <th style="width:90px">数据来源</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="(group, gi) in tree">
            <template v-if="group.children && group.children.length">
              <tr :key="'g' + group.id" class="group-row">
                <td class="center">{{ gi + 1 }}</td>
                <td :rowspan="rowspan(group)" class="center">{{ group.name }}</td>
                <td></td>
                <td class="center">{{ group.score }}</td>
                <td></td>
                <td></td>
              </tr>
              <tr v-for="(item, ii) in group.children" :key="'i' + item.id" :class="{ disabled: item.status !== 1 }">
                <td class="center">{{ gi + 1 + '.' + (ii + 1) }}</td>
                <td class="center">{{ item.name }}</td>
                <td class="center">{{ item.score }}</td>
                <td>{{ ruleText(item) }}</td>
                <td class="center">{{ dataSourceText(item.data_source) }}</td>
              </tr>
            </template>
            <tr v-else :key="'l' + group.id">
              <td class="center">{{ gi + 1 }}</td>
              <td></td>
              <td class="center">{{ group.name }}</td>
              <td class="center">{{ group.score }}</td>
              <td>{{ ruleText(group) }}</td>
              <td class="center">{{ dataSourceText(group.data_source) }}</td>
            </tr>
          </template>
        </tbody>
        <tfoot>
          <tr class="total-row">
            <td colspan="3" class="right">合计</td>
            <td class="center">{{ summary.score }}</td>
            <td colspan="2"></td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</template>

<script>
import { exportTemplatePreview } from '@/api/assessment'

const PERIOD_TEXT = { 1: '月度', 2: '季度', 3: '年度', 4: '半年度' }
const DATA_SOURCES = {
  attendance: '考勤', production: '生产', quality: '质检', maintenance: '保养',
  training: '培训', exam: '考试', safety: '安全', manual: '手动'
}
// 扣分规则字段/操作符/值中文映射（预置指标库规则使用数据源内部字段，展示时转为中文）
const FIELD_MAP = {
  violation_type: '违规类型', violation_level: '违规等级', score: '成绩',
  attend_status: '出勤状态', maintenance_status: '保养状态', task_status: '任务状态',
  reject_type: '不合格类型', check_result: '检查结果', record: '记录'
}
const OP_MAP = { eq: '等于', gt: '大于', lt: '小于', contains: '包含', ne: '不等于' }
const VALUE_MAP = {
  late: '迟到', absent: '旷工/缺席', leave_post: '脱岗', normal: '一般', serious: '严重',
  not_pass: '不达标', missed: '未保养', not_finished: '未完成', unqualified: '不合格',
  meeting: '会议', trigger: '触发'
}

export default {
  name: 'AssessmentPreviewTab',
  props: {
    template: { type: Object, default: () => ({}) },
    tree: { type: Array, default: () => [] },
    totalScore: { type: Number, default: 0 }
  },
  data () {
    return { exporting: false }
  },
  computed: {
    periodText () {
      return PERIOD_TEXT[this.template.period_type] || '月度'
    },
    summary () {
      let groups = 0
      let total = 0
      const walk = nodes => {
        nodes.forEach(n => {
          if (n.children && n.children.length) {
            groups++
            walk(n.children)
          } else if (n.status === 1) total++
        })
      }
      walk(this.tree)
      return { groups, total, score: Number(this.totalScore || 0) }
    }
  },
  methods: {
    rowspan (group) {
      return (group.children ? group.children.length : 1) + 1
    },
    dataSourceText (ds) {
      return DATA_SOURCES[ds] || '手动'
    },
    ruleText (node) {
      const rule = node.auto_deduct_rule
      if (node.scoring_type === 3) return '等级折算'
      if (node.scoring_type === 2) return '加分制'
      if (!rule) return '手动评分'
      const conds = rule.conditions || []
      if (conds.length) {
        const desc = conds.map(c => {
          const field = FIELD_MAP[c.field] || c.field
          const op = OP_MAP[c.operator] || c.operator
          const val = VALUE_MAP[c.value] !== undefined ? VALUE_MAP[c.value] : c.value
          let s = field + op + String(val)
          if (c.deduct_per_unit) s += '，每次扣' + c.deduct_per_unit + '分'
          if (c.max_deduct) s += '，上限' + c.max_deduct + '分'
          return s
        }).join('；')
        return desc
      }
      const rm = rule.remark_template
      if (rm) return String(rm).replace(/\{\{count\}\}/g, '次数').replace(/\{\{deduct\}\}/g, '分值').replace(/\{\{score\}\}/g, '分数').replace(/\{\{\w+\}\}/g, '')
      return '按规则扣分'
    },
    async doExport () {
      if (!this.template.id) { this.$message.warning('请先保存模板'); return }
      this.exporting = true
      try {
        const r = await exportTemplatePreview(this.template.id)
        const blob = new Blob([r.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `考核模板_${this.template.name || this.template.id}.xlsx`
        a.click()
        URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    },
    doPrint () {
      this.$nextTick(() => {
        const html = document.getElementById('previewArea').outerHTML
        const win = window.open('', '_blank')
        if (!win) { this.$message.warning('浏览器已阻止弹窗，请允许后重试'); return }
        win.document.write(`<html><head><title>考核模板预览</title><style>
          body{font-family:"Microsoft YaHei",sans-serif;padding:20px;}
          table{width:100%;border-collapse:collapse;}
          th,td{border:1px solid #333;padding:6px 8px;font-size:13px;}
          th{background:#f0f0f0;}
          .group-row td{background:#fafafa;font-weight:600;}
          .total-row td{font-weight:600;}
          .center{text-align:center;}
          .right{text-align:right;font-weight:600;}
          .disabled td{color:#999;}
        </style></head><body>${html}</body></html>`)
        win.document.close()
        win.print()
      })
    }
  }
}
</script>

<style scoped>
.preview-tab { padding: 12px 16px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; flex-wrap: wrap; gap: 8px; }
.toolbar-left { display: flex; gap: 8px; }
.total-text { font-size: 13px; color: #8c8f9c; }
.preview-table-wrap { background: #fff; padding: 16px; border: 1px solid #e8ecf1; border-radius: 12px; overflow-x: auto; }
.preview-table { width: 100%; border-collapse: collapse; }
.preview-table th, .preview-table td { border: 1px solid #dcdfe6; padding: 8px 10px; font-size: 13px; }
.preview-table thead th { background: #e8ecf1; font-weight: 600; color: #1d2129; }
.preview-table .sub-head { font-weight: 400; color: #5a6f86; font-size: 12px; }
.group-row td { background: #fafafa; font-weight: 600; }
.total-row td { font-weight: 600; background: #f5f7fa; }
.center { text-align: center; }
.right { text-align: right; }
.disabled td { color: #c0c4cc; }
</style>
