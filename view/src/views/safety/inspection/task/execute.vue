<template>
  <div class="task-execute-page">
    <!-- 任务信息展示区 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <div slot="header" class="card-header">
        <b>检查任务执行</b>
        <el-tag size="mini" :type="statusTagType(task.status)">{{ task.status_text || '执行中' }}</el-tag>
      </div>
      <el-descriptions :column="3" size="small" border>
        <el-descriptions-item label="任务编号">{{ task.task_code }}</el-descriptions-item>
        <el-descriptions-item label="计划名称">{{ task.plan_name }}</el-descriptions-item>
        <el-descriptions-item label="检查类型">{{ task.inspection_type_name }}</el-descriptions-item>
        <el-descriptions-item label="检查区域">{{ task.area || '-' }}</el-descriptions-item>
        <el-descriptions-item label="执行人">{{ task.executor_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="计划执行日期">{{ task.plan_execute_date }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 检查项目列表区 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <div slot="header"><b>检查项目</b><span style="color:#909399;font-size:12px;margin-left:8px">共 {{ items.length }} 项</span></div>
      <div v-loading="itemsLoading">
        <div v-if="!items.length" class="empty">该任务未关联检查标准模板，无检查项目</div>
        <div v-for="(item, idx) in items" :key="idx" class="check-item">
          <div class="ci-head">
            <div class="ci-title">
              <span class="ci-no">{{ idx + 1 }}</span>
              <span class="ci-name">{{ item.item_name }}</span>
              <el-tag v-if="item.is_required" size="mini" type="danger">必查</el-tag>
            </div>
            <el-radio-group v-model="item.result" size="small" @change="() => onResultChange(item)">
              <el-radio-button :label="'qualified'">合格</el-radio-button>
              <el-radio-button :label="'unqualified'">不合格</el-radio-button>
              <el-radio-button :label="'na'">不适用</el-radio-button>
            </el-radio-group>
          </div>
          <div class="ci-meta">
            <div v-if="item.check_standard" class="ci-line"><span class="ci-lb">检查标准：</span>{{ item.check_standard }}</div>
            <div v-if="item.check_method" class="ci-line"><span class="ci-lb">检查方法：</span>{{ item.check_method }}</div>
          </div>
          <div v-if="item.result === 'unqualified'" class="ci-issue">
            <el-form label-width="80px" size="small">
              <el-form-item label="问题描述" required>
                <el-input v-model="item.issue_description" type="textarea" :rows="2" maxlength="1000" placeholder="请描述发现的问题（必填）" />
              </el-form-item>
              <el-form-item label="整改建议">
                <el-input v-model="item.suggest" type="textarea" :rows="2" maxlength="500" placeholder="整改建议（可选）" />
              </el-form-item>
              <el-form-item label="严重程度">
                <el-radio-group v-model="item.severity">
                  <el-radio :label="'minor'">一般</el-radio>
                  <el-radio :label="'major'">严重</el-radio>
                  <el-radio :label="'critical'">紧急</el-radio>
                </el-radio-group>
              </el-form-item>
            </el-form>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 检查总结区 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <div slot="header"><b>检查总结</b></div>
      <el-input v-model="summary" type="textarea" :rows="3" maxlength="2000" placeholder="本次检查总结（可选）" />
    </el-card>

    <!-- 底部操作按钮区 -->
    <div class="bottom-bar">
      <el-button size="medium" @click="goBack">返回</el-button>
      <el-button size="medium" @click="handleDraft">暂存</el-button>
      <el-button size="medium" type="primary" :loading="submitting" @click="handleSubmit">提交检查结果</el-button>
    </div>
  </div>
</template>

<script>
import { getTaskDetail, getTaskItems, startTask, submitTask } from '@/api/safetyInspectionTask'

export default {
  name: 'SafetyInspectionTaskExecute',
  data() {
    return {
      taskId: 0,
      task: {},
      items: [],
      itemsLoading: false,
      summary: '',
      submitting: false,
    }
  },
  created() {
    this.taskId = Number(this.$route.query.id) || 0
    if (!this.taskId) { this.$message.error('缺少任务ID'); this.goBack(); return }
    this.init()
  },
  methods: {
    statusTagType(v) {
      return { pending: 'primary', in_progress: 'warning', completed: 'success', overdue: 'danger', cancelled: 'info' }[v] || 'info'
    },
    async init() {
      this.itemsLoading = true
      try {
        // 1. 加载任务详情
        const r = await getTaskDetail(this.taskId)
        if (r.code !== 0) { this.$message.error(r.msg || '加载任务失败'); return }
        this.task = r.data || {}
        // 2. 未开始则自动开始执行
        if (['pending', 'overdue'].indexOf(this.task.status) > -1) {
          try { await startTask(this.taskId) } catch (e) {}
          this.task.status = 'in_progress'
          this.task.status_text = '执行中'
        }
        // 3. 加载检查项目
        const it = await getTaskItems(this.taskId)
        const tplItems = (it.code === 0 && it.data && it.data.items) ? it.data.items : []
        this.items = tplItems.map(x => ({
          item_name: x.item_name,
          check_standard: x.check_standard || '',
          check_method: x.check_method || '',
          is_required: !!x.is_required,
          result: '',
          issue_description: '',
          suggest: '',
          severity: 'minor',
        }))
        // 若已有结果回显（重新进入）
        if (this.task.result && this.task.result.length) {
          this.items = this.task.result
          this.summary = this.task.summary || ''
        }
      } catch (e) {}
      this.itemsLoading = false
    },
    onResultChange(item) {
      if (item.result !== 'unqualified') { item.issue_description = ''; item.suggest = '' }
    },
    handleDraft() {
      try {
        localStorage.setItem('safety_task_draft_' + this.taskId, JSON.stringify({ items: this.items, summary: this.summary }))
        this.$message.success('已暂存到本地')
      } catch (e) { this.$message.error('暂存失败') }
    },
    validateSubmit() {
      // 校验必查项目必须选择结果
      for (const it of this.items) {
        if (it.is_required && !it.result) { this.$message.warning(`必查项目「${it.item_name}」请选择检查结果`); return false }
        if (it.result === 'unqualified' && !(it.issue_description && it.issue_description.trim())) {
          this.$message.warning(`项目「${it.item_name}」不合格，请填写问题描述`); return false
        }
      }
      return true
    },
    handleSubmit() {
      if (!this.validateSubmit()) return
      // 组装提交数据
      const items = this.items.map(it => ({
        item_name: it.item_name,
        result: it.result || 'na',
        remark: it.result === 'unqualified' ? (it.issue_description || '') : '',
      }))
      const issues = this.items
        .filter(it => it.result === 'unqualified')
        .map(it => ({
          item_name: it.item_name,
          issue_description: it.issue_description || '',
          suggest: it.suggest || '',
          severity: it.severity || 'minor',
        }))
      this.$confirm('确认提交检查结果？不合格项目将自动创建隐患记录。', '提交确认', { type: 'warning' }).then(async () => {
        this.submitting = true
        try {
          const r = await submitTask(this.taskId, { items, summary: this.summary, issues })
          if (r.code === 0) {
            this.$message.success(r.msg || '提交成功')
            localStorage.removeItem('safety_task_draft_' + this.taskId)
            this.goBack()
          }
        } catch (e) {}
        this.submitting = false
      }).catch(() => {})
    },
    goBack() { this.$router.back() },
  },
}
</script>

<style scoped>
.task-execute-page { padding: 16px; max-width: 960px; margin: 0 auto; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.empty { text-align: center; color: #909399; padding: 30px 0; }
.check-item { border: 1px solid #ebeef5; border-radius: 6px; padding: 12px 14px; margin-bottom: 12px; }
.ci-head { display: flex; justify-content: space-between; align-items: center; }
.ci-title { display: flex; align-items: center; gap: 8px; }
.ci-no { width: 22px; height: 22px; border-radius: 50%; background: #409EFF; color: #fff; font-size: 12px; display: inline-flex; align-items: center; justify-content: center; flex-shrink: 0; }
.ci-name { font-weight: 600; font-size: 14px; }
.ci-meta { margin-top: 8px; font-size: 13px; color: #606266; }
.ci-line { line-height: 1.7; }
.ci-lb { color: #909399; }
.ci-issue { margin-top: 12px; background: #fdf6ec; border-radius: 6px; padding: 10px 12px; }
.bottom-bar { position: fixed; bottom: 0; left: 0; right: 0; background: #fff; border-top: 1px solid #ebeef5; padding: 10px 16px; display: flex; justify-content: flex-end; gap: 10px; z-index: 9; box-shadow: 0 -2px 8px rgba(0,0,0,.05); }
</style>
