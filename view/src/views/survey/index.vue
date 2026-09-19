<template>
  <div class="survey-admin">
    <div class="page-header">
      <div><h2>问卷管理</h2><p class="page-subtitle">创建员工调研、满意度问卷并查看统计 · 共 {{ total }} 份</p></div>
      <div style="display:flex;gap:8px">
        <el-select v-model="filterStatus" size="small" placeholder="状态" clearable style="width:120px" @change="load">
          <el-option label="草稿" :value="0" />
          <el-option label="发布中" :value="1" />
          <el-option label="已停止" :value="2" />
        </el-select>
        <el-input v-model="keyword" size="small" placeholder="搜索问卷标题" prefix-icon="el-icon-search" clearable style="width:220px" @keyup.enter.native="load" @clear="load" />
        <el-button v-if="hasPerm('survey:add')" type="primary" size="small" icon="el-icon-plus" @click="openAdd">新建问卷</el-button>
      </div>
    </div>

    <div class="survey-body" v-loading="loading">
      <el-table :data="list" stripe style="width:100%">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column label="问卷标题" min-width="220">
          <template slot-scope="{ row }">
            <span>{{ row.title }}</span>
            <el-tag v-if="row.status === 1" type="success" size="mini" style="margin-left:6px">发布中</el-tag>
            <el-tag v-else-if="row.status === 0" type="info" size="mini" style="margin-left:6px">草稿</el-tag>
            <el-tag v-else type="danger" size="mini" style="margin-left:6px">已停止</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="题目" width="70" align="center">
          <template slot-scope="{ row }">{{ row.question_count }}</template>
        </el-table-column>
        <el-table-column label="已提交" width="90" align="center">
          <template slot-scope="{ row }">{{ row.answer_count }}</template>
        </el-table-column>
        <el-table-column label="匿名" width="70" align="center">
          <template slot-scope="{ row }">
            <span>{{ row.anonymous == 1 ? '是' : '否' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="created_name" label="创建人" width="100">
          <template slot-scope="{ row }">{{ row.created_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="create_time" label="创建时间" width="160">
          <template slot-scope="{ row }">{{ row.create_time }}</template>
        </el-table-column>
        <el-table-column label="操作" width="270" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('survey:edit')" type="text" size="small" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('survey:edit')" type="text" size="small" @click="doToggle(row)">{{ row.status === 1 ? '停止' : '发布' }}</el-button>
            <el-button v-if="hasPerm('survey:stats')" type="text" size="small" @click="goStats(row)">统计</el-button>
            <el-button v-if="hasPerm('survey:export')" type="text" size="small" @click="doExport(row)">导出</el-button>
            <el-button v-if="hasPerm('survey:delete')" type="text" size="small" class="danger" @click="doDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="limit" :current-page.sync="page" @current-change="load" />
      </div>
    </div>

    <!-- 新建/编辑问卷 -->
    <el-dialog :title="form.id ? '编辑问卷' : '新建问卷'" :visible.sync="showForm" width="860px" top="4vh" @closed="resetForm" custom-class="survey-dialog">
      <div class="dlg-scroll">
        <el-form :model="form" label-width="90px" size="small">
          <el-form-item label="问卷标题" required>
            <el-input v-model="form.title" maxlength="200" placeholder="请输入问卷标题" />
          </el-form-item>
          <el-form-item label="问卷说明">
            <el-input v-model="form.description" type="textarea" :rows="2" maxlength="2000" placeholder="填写引导语/说明（选填）" />
          </el-form-item>
          <el-form-item label="状态">
            <el-radio-group v-model="form.status">
              <el-radio :label="0">草稿</el-radio>
              <el-radio :label="1">发布</el-radio>
              <el-radio :label="2">停止</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="填写设置">
            <el-checkbox v-model="form.anonymous" :true-label="1" :false-label="0">匿名填写</el-checkbox>
            <el-checkbox v-model="form.need_login" :true-label="1" :false-label="0" style="margin-left:14px">需登录填写</el-checkbox>
            <el-checkbox v-model="form.limit_once" :true-label="1" :false-label="0" style="margin-left:14px">每人限填一次</el-checkbox>
          </el-form-item>
          <el-form-item label="有效时间">
            <el-date-picker v-model="timeRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width:400px" />
          </el-form-item>
        </el-form>

        <div class="q-title-row">
          <span class="q-title">题目设置</span>
          <el-button type="text" icon="el-icon-plus" @click="addQuestion">添加题目</el-button>
        </div>
        <div v-if="form.questions.length === 0" class="q-empty">暂无题目，请点击右上角"添加题目"</div>
        <div v-for="(q, qi) in form.questions" :key="qi" class="q-item">
          <div class="q-head">
            <span class="q-no">第 {{ qi + 1 }} 题</span>
            <el-select v-model="q.type" size="mini" style="width:110px" @change="t => onTypeChange(q, t)">
              <el-option label="单选题" value="radio" />
              <el-option label="多选题" value="multi" />
              <el-option label="文本题" value="text" />
              <el-option label="评分题" value="score" />
            </el-select>
            <el-checkbox v-model="q.required" style="margin-left:10px">必填</el-checkbox>
            <span style="flex:1"></span>
            <el-button type="text" size="mini" icon="el-icon-top" :disabled="qi === 0" @click="moveQuestion(qi, -1)">上移</el-button>
            <el-button type="text" size="mini" icon="el-icon-bottom" :disabled="qi === form.questions.length - 1" @click="moveQuestion(qi, 1)">下移</el-button>
            <el-button type="text" size="mini" class="danger" icon="el-icon-delete" @click="removeQuestion(qi)">删除</el-button>
          </div>
          <el-input v-model="q.title" size="small" maxlength="500" placeholder="请输入题目内容" style="margin:8px 0" />

          <!-- 单选/多选选项 -->
          <template v-if="q.type === 'radio' || q.type === 'multi'">
            <div v-for="(opt, oi) in q.options" :key="oi" class="opt-row">
              <el-input v-model="q.options[oi]" size="mini" :placeholder="'选项 ' + (oi + 1)" style="width:340px" />
              <el-button type="text" size="mini" icon="el-icon-close" @click="q.options.splice(oi, 1)" />
            </div>
            <el-button type="text" size="mini" icon="el-icon-plus" @click="q.options.push('')">添加选项</el-button>
          </template>

          <!-- 评分维度 -->
          <template v-else-if="q.type === 'score'">
            <div v-for="(d, di) in q.options" :key="di" class="opt-row">
              <el-input v-model="q.options[di].label" size="mini" placeholder="评分项名称" style="width:340px" />
              <span class="score-max">满分</span>
              <el-input-number v-model="q.options[di].max" size="mini" :min="1" :max="100" style="width:110px" />
              <el-button type="text" size="mini" icon="el-icon-close" @click="q.options.splice(di, 1)" />
            </div>
            <el-button type="text" size="mini" icon="el-icon-plus" @click="q.options.push({ label: '', max: 5 })">添加评分项</el-button>
          </template>
        </div>
      </div>
      <span slot="footer">
        <el-button size="small" @click="showForm = false">取消</el-button>
        <el-button type="primary" size="small" :loading="saving" @click="save">保存问卷</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getSurveyList, getSurveyDetail, saveSurvey, toggleSurvey, deleteSurvey, exportSurveyCsv } from '@/api/survey'

export default {
  name: 'SurveyAdmin',
  data() {
    return {
      loading: false, saving: false,
      list: [], total: 0, page: 1, limit: 20,
      keyword: '', filterStatus: '',
      showForm: false,
      timeRange: [],
      form: this.emptyForm(),
    }
  },
  created() { this.load() },
  methods: {
    hasPerm(code) { const p = (this.$store.state.user && this.$store.state.user.permissions) || []; return p.indexOf(code) > -1 },
    emptyForm() {
      return { id: 0, title: '', description: '', status: 1, anonymous: 1, need_login: 0, limit_once: 0, questions: [] }
    },
    resetForm() { this.form = this.emptyForm(); this.timeRange = [] },
    async load() {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.limit }
        if (this.keyword) params.keyword = this.keyword
        if (this.filterStatus !== '') params.status = this.filterStatus
        const r = await getSurveyList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
        else this.$message.error(r.msg || '加载失败')
      } catch (e) { this.$message.error('加载失败') } finally { this.loading = false }
    },
    openAdd() {
      this.resetForm()
      this.showForm = true
    },
    async openEdit(row) {
      this.resetForm()
      try {
        const r = await getSurveyDetail(row.id)
        if (r.code !== 0) return this.$message.error(r.msg || '加载失败')
        const d = r.data
        this.form = {
          id: d.id, title: d.title, description: d.description || '',
          status: d.status, anonymous: d.anonymous, need_login: d.need_login, limit_once: d.limit_once,
          questions: (d.questions || []).map(q => ({
            type: q.type, title: q.title, required: q.required,
            options: q.type === 'score'
              ? (q.options || []).map(o => ({ label: o.label || '', max: o.max || 5 }))
              : (q.options || []).map(String),
          })),
        }
        this.timeRange = d.start_time && d.end_time ? [d.start_time, d.end_time] : []
        this.showForm = true
      } catch (e) { this.$message.error('加载失败') }
    },
    addQuestion() {
      this.form.questions.push({ type: 'radio', title: '', required: 1, options: ['', ''] })
    },
    onTypeChange(q, type) {
      if (type === 'score') q.options = [{ label: '', max: 5 }, { label: '', max: 5 }]
      else if (type === 'text') q.options = []
      else if (!Array.isArray(q.options) || q.options.length === 0) q.options = ['', '']
      else if (type === 'radio' || type === 'multi') q.options = q.options.map(o => (typeof o === 'object' ? (o.label || '') : o))
    },
    moveQuestion(i, dir) {
      const arr = this.form.questions
      const j = i + dir
      if (j < 0 || j >= arr.length) return
      const tmp = arr[i]; arr.splice(i, 1); arr.splice(j, 0, tmp)
    },
    removeQuestion(i) { this.form.questions.splice(i, 1) },
    async save() {
      if (!this.form.title.trim()) return this.$message.error('请填写问卷标题')
      if (this.form.questions.length === 0) return this.$message.error('请至少添加一道题目')
      for (let i = 0; i < this.form.questions.length; i++) {
        const q = this.form.questions[i]
        if (!q.title.trim()) return this.$message.error('第 ' + (i + 1) + ' 题缺少题目内容')
        if ((q.type === 'radio' || q.type === 'multi') && q.options.some(o => !String(o).trim())) return this.$message.error('第 ' + (i + 1) + ' 题存在空选项')
        if (q.type === 'score' && q.options.some(o => !o.label || !o.max)) return this.$message.error('第 ' + (i + 1) + ' 题评分项不完整')
      }
      this.saving = true
      try {
        const payload = {
          id: this.form.id,
          title: this.form.title.trim(),
          description: this.form.description,
          status: this.form.status,
          anonymous: this.form.anonymous,
          need_login: this.form.need_login,
          limit_once: this.form.limit_once,
          start_time: this.timeRange && this.timeRange[0] ? this.timeRange[0] : '',
          end_time: this.timeRange && this.timeRange[1] ? this.timeRange[1] : '',
          questions: JSON.stringify(this.form.questions),
        }
        const r = await saveSurvey(payload)
        if (r.code === 0) {
          this.$message.success(r.msg || '保存成功')
          this.showForm = false
          this.load()
        } else this.$message.error(r.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') } finally { this.saving = false }
    },
    async doToggle(row) {
      const next = row.status === 1 ? 2 : (row.status === 0 ? 1 : 1)
      const action = next === 1 ? '发布' : '停止'
      try {
        const r = await toggleSurvey({ id: row.id, status: next })
        if (r.code === 0) { this.$message.success('已' + action); this.load() }
        else this.$message.error(r.msg || '操作失败')
      } catch (e) { this.$message.error('操作失败') }
    },
    async doDelete(row) {
      try {
        await this.$confirm('确定删除问卷「' + row.title + '」吗？其答卷数据将一并隐藏，删除后不可恢复。', '删除确认', { type: 'warning' })
      } catch (e) { return }
      try {
        const r = await deleteSurvey(row.id)
        if (r.code === 0) { this.$message.success('删除成功'); this.load() }
        else this.$message.error(r.msg || '删除失败')
      } catch (e) { this.$message.error('删除失败') }
    },
    async doExport(row) {
      try {
        const res = await exportSurveyCsv(row.id)
        const blob = res.data instanceof Blob ? res.data : new Blob([res.data])
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = '问卷' + row.id + '_' + row.title + '.csv'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
    },
    goStats(row) {
      this.$router.push({ path: '/survey/stats', query: { id: row.id } })
    },
  },
}
</script>

<style scoped>
.survey-admin { padding: 16px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.page-header h2 { margin: 0 0 4px; font-size: 19px; }
.page-subtitle { margin: 0; font-size: 12px; color: #888; }
.survey-body { background: #fff; border-radius: 8px; padding: 14px; }
.pager { margin-top: 12px; text-align: right; }
.danger { color: #e53935 !important; }
.dlg-scroll { max-height: 62vh; overflow-y: auto; padding: 2px 6px 2px 2px; }
.q-title-row { display: flex; justify-content: space-between; align-items: center; margin: 6px 0 8px; padding-top: 10px; border-top: 1px dashed #e8e8e8; }
.q-title { font-size: 14px; font-weight: 600; color: #1e6fff; padding-left: 8px; border-left: 4px solid #1e6fff; }
.q-empty { color: #999; text-align: center; padding: 18px 0; font-size: 13px; background: #fafbfc; border-radius: 6px; }
.q-item { border: 1px solid #e8e8e8; border-radius: 8px; padding: 10px 12px; margin-bottom: 10px; background: #fafbfc; }
.q-head { display: flex; align-items: center; }
.q-no { font-size: 13px; font-weight: 600; color: #555; margin-right: 10px; }
.opt-row { display: flex; align-items: center; margin-bottom: 6px; gap: 6px; }
.score-max { font-size: 12px; color: #888; }
</style>
