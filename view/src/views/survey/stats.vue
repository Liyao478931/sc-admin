<template>
  <div class="survey-stats" v-loading="loading">
    <div class="page-header">
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push('/survey/list')">返回列表</el-button>
        <h2 style="margin:10px 0 4px">{{ info.title || '问卷统计' }}</h2>
        <p class="page-subtitle" v-if="info.id">
          <el-tag size="mini" :type="info.status === 1 ? 'success' : (info.status === 0 ? 'info' : 'danger')">{{ info.status_text }}</el-tag>
          <span style="margin-left:8px">创建人：{{ info.created_name }}</span>
          <span style="margin-left:8px">创建时间：{{ info.create_time }}</span>
        </p>
      </div>
      <div style="display:flex;gap:8px">
        <el-button v-if="hasPerm('survey:export')" size="small" icon="el-icon-download" @click="doExport">导出答卷 CSV</el-button>
      </div>
    </div>

    <div class="cards">
      <div class="card"><div class="num">{{ total }}</div><div class="lab">总提交份数</div></div>
      <div class="card"><div class="num">{{ avgTotal !== null ? avgTotal : '-' }}</div><div class="lab">评分平均分</div></div>
      <div class="card"><div class="num">{{ questionCount }}</div><div class="lab">题目数量</div></div>
    </div>

    <div v-if="total === 0" class="empty">暂无提交数据，问卷链接发布后员工填写即可在此查看统计。</div>

    <div v-for="q in questions" :key="q.id" class="sec">
      <div class="sec-head">
        <span class="sec-title">{{ q.title }}</span>
        <el-tag size="mini" style="margin-left:8px">{{ q.type_text }}</el-tag>
        <el-tag v-if="q.required" size="mini" type="danger" style="margin-left:6px">必填</el-tag>
        <span class="sec-count">已答 {{ q.answer_count }} 人</span>
      </div>

      <!-- 单选/多选分布 -->
      <template v-if="q.type === 'radio' || q.type === 'multi'">
        <div v-for="d in q.distribution" :key="d.label" class="bar-row">
          <span class="lbl">{{ d.label }}</span>
          <span class="bar-bg"><span class="bar" :style="{ width: Math.max(d.pct, 1.5) + '%' }"></span></span>
          <span class="pct">{{ d.count }} 人 · {{ d.pct }}%</span>
        </div>
      </template>

      <!-- 评分题 -->
      <template v-else-if="q.type === 'score'">
        <div class="score-head">平均总分：<b style="color:#1e6fff">{{ q.avg_total }}</b> 分</div>
        <div v-for="d in q.dims" :key="d.label" class="bar-row">
          <span class="lbl">{{ d.label }}</span>
          <span class="bar-bg"><span class="bar orange" :style="{ width: Math.max(d.max ? (d.avg / d.max) * 100 : 0, 1.5) + '%' }"></span></span>
          <span class="pct">{{ d.avg }} / {{ d.max }} 分</span>
        </div>
      </template>

      <!-- 文本题 -->
      <template v-else-if="q.type === 'text'">
        <div v-if="q.texts.length === 0" class="no-text">暂无文字反馈</div>
        <div v-for="(t, ti) in q.texts" :key="ti" class="text-item">
          <span class="text-time">{{ t.time }}</span>
          <span class="text-val">{{ t.value }}</span>
        </div>
      </template>
    </div>
  </div>
</template>

<script>
import { getSurveyStats, exportSurveyCsv } from '@/api/survey'

export default {
  name: 'SurveyStats',
  data() {
    return {
      loading: false,
      id: 0,
      info: {},
      total: 0,
      avgTotal: null,
      questions: [],
      questionCount: 0,
    }
  },
  created() {
    this.id = parseInt(this.$route.query.id || '0', 10)
    if (this.id) this.load()
  },
  methods: {
    hasPerm(code) { const p = (this.$store.state.user && this.$store.state.user.permissions) || []; return p.indexOf(code) > -1 },
    async load() {
      this.loading = true
      try {
        const r = await getSurveyStats(this.id)
        if (r.code === 0) {
          const d = r.data
          this.info = d.survey || {}
          this.total = d.total || 0
          this.avgTotal = d.avg_total_score
          this.questions = d.questions || []
          this.questionCount = this.questions.length
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) { this.$message.error('加载失败') } finally { this.loading = false }
    },
    async doExport() {
      try {
        const res = await exportSurveyCsv(this.id)
        const blob = res.data instanceof Blob ? res.data : new Blob([res.data])
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = '问卷' + this.id + '_' + (this.info.title || '统计') + '.csv'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
    },
  },
}
</script>

<style scoped>
.survey-stats { padding: 16px; }
.page-header { margin-bottom: 14px; }
.page-header h2 { font-size: 19px; }
.page-subtitle { margin: 0; font-size: 12px; color: #888; }
.cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; margin-bottom: 14px; }
.card { background: #fff; border-radius: 8px; padding: 14px; text-align: center; box-shadow: 0 1px 4px rgba(0,0,0,.05); }
.card .num { font-size: 26px; font-weight: 700; color: #1e6fff; }
.card .lab { font-size: 12px; color: #888; margin-top: 4px; }
.sec { background: #fff; border-radius: 8px; padding: 14px 16px; margin-bottom: 12px; box-shadow: 0 1px 4px rgba(0,0,0,.05); }
.sec-head { display: flex; align-items: center; margin-bottom: 12px; }
.sec-title { font-size: 14px; font-weight: 600; padding-left: 8px; border-left: 4px solid #1e6fff; }
.sec-count { margin-left: auto; font-size: 12px; color: #888; }
.bar-row { display: flex; align-items: center; margin-bottom: 8px; font-size: 13px; }
.lbl { display: inline-block; width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.bar-bg { flex: 1; height: 16px; background: #f0f2f5; border-radius: 3px; margin: 0 10px; overflow: hidden; }
.bar { display: block; height: 100%; background: #1e6fff; border-radius: 3px; min-width: 3px; }
.bar.orange { background: #ff9800; }
.pct { width: 110px; text-align: right; color: #666; }
.score-head { font-size: 13px; color: #555; margin-bottom: 10px; }
.no-text { color: #999; font-size: 13px; }
.text-item { display: flex; gap: 12px; padding: 8px 10px; border-bottom: 1px dashed #eee; font-size: 13px; }
.text-time { color: #999; white-space: nowrap; }
.text-val { flex: 1; }
.empty { background: #fff; border-radius: 8px; padding: 30px; text-align: center; color: #999; font-size: 14px; }
</style>
