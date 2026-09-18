<template>
  <div class="execute-page">
    <!-- 面包屑 -->
    <el-breadcrumb separator="/" class="crumb">
      <el-breadcrumb-item>设备管理</el-breadcrumb-item>
      <el-breadcrumb-item>设备巡检</el-breadcrumb-item>
      <el-breadcrumb-item>巡检执行</el-breadcrumb-item>
    </el-breadcrumb>

    <div v-loading="loading">
      <!-- 任务信息 -->
      <div class="panel" v-if="task">
        <div class="task-head">
          <span class="task-title">{{ task.device_name }}</span>
          <el-tag :type="taskStatusType(task.status)" size="mini">{{ taskStatusLabel(task.status) }}</el-tag>
        </div>
        <div class="task-line">设备编码：{{ task.device_code }} · 任务：{{ task.task_code }}</div>
        <div class="task-line">计划：{{ task.plan_name }} · 计划执行：{{ task.plan_execute_date }}</div>
        <div class="task-line">执行人：{{ task.executor_name || '未分配' }}</div>
      </div>

      <!-- 检查项 -->
      <div class="panel" v-if="items.length">
        <div class="section-title">检查项填写（{{ items.length }} 项）</div>
        <div v-for="(item, idx) in items" :key="idx" class="item-card">
          <div class="item-top">
            <span class="item-name">{{ item.name }}</span>
            <el-tag v-if="item.required" size="mini" type="danger">必填</el-tag>
          </div>
          <div class="item-line">检查标准：{{ item.standard || '-' }}　正常值：{{ item.normal_range || '-' }}</div>
          <el-radio-group v-model="item.result" size="small" @change="() => onResultChange(item)">
            <el-radio-button label="normal">正常</el-radio-button>
            <el-radio-button label="abnormal">异常</el-radio-button>
            <el-radio-button label="na">不适用</el-radio-button>
          </el-radio-group>
          <div v-if="item.result === 'abnormal'" class="abnormal-box">
            <el-input v-model="item.desc" type="textarea" :rows="2" maxlength="500" placeholder="请填写异常描述（不少于10字）" />
            <el-upload :action="uploadUrl" :headers="uploadHeaders" :show-file-list="false" :on-success="res => onUploadSuccess(res, item)" style="margin-top:6px">
              <el-button size="mini" type="text" icon="el-icon-plus">上传照片</el-button>
            </el-upload>
            <div v-if="item.images && item.images.length" class="img-list">
              <el-image v-for="(img, i) in item.images" :key="i" :src="img" style="width:60px;height:60px" fit="cover" :preview-src-list="item.images" />
            </div>
          </div>
        </div>
      </div>
      <el-empty v-else-if="!loading" description="该任务无检查项" />

      <!-- 备注 -->
      <div class="panel">
        <el-input v-model="remark" type="textarea" :rows="3" maxlength="1000" placeholder="整体备注（选填）" />
        <div class="btn-row">
          <el-button size="small" type="primary" :loading="submitting" @click="submit">提交审核</el-button>
          <el-button size="small" @click="draft">暂存</el-button>
          <el-button size="small" @click="$router.back()">返回</el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getTaskDetail, getCheckItems, submitExecute, draftExecute, startExecute } from '@/api/deviceInspection'
import { getToken } from '@/utils/auth'

export default {
  name: 'InspectionExecute',
  data() {
    return {
      taskId: 0, task: null, items: [], remark: '', loading: false, submitting: false,
      uploadUrl: '/api/device/inspection/execute/upload-attachment'
    }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } }
  },
  created() {
    this.taskId = Number(this.$route.query.task_id || 0)
    if (this.taskId) this.loadData()
    else this.$message.error('缺少任务ID')
  },
  methods: {
    taskStatusLabel(v) { return { pending: '待执行', in_progress: '执行中', completed: '已完成', overdue: '已逾期', cancelled: '已取消' }[v] || v },
    taskStatusType(v) { return { pending: 'info', in_progress: 'primary', completed: 'success', overdue: 'danger', cancelled: 'warning' }[v] || 'info' },
    async loadData() {
      this.loading = true
      try {
        const [t, c] = await Promise.all([getTaskDetail(this.taskId), getCheckItems(this.taskId)])
        this.task = t.data || {}
        const saved = (c.data && c.data.saved_result) || null
        this.items = ((c.data && c.data.items) || []).map(x => ({
          ...x, result: saved ? (saved.find(s => s.item_id === x.id)?.result || x.result || 'normal') : (x.result || 'normal'),
          desc: saved ? (saved.find(s => s.item_id === x.id)?.desc || '') : '',
          images: saved ? (saved.find(s => s.item_id === x.id)?.images || []) : []
        }))
        this.remark = t.data.remark || ''
      } catch (e) {}
      this.loading = false
    },
    onResultChange(item) {
      if (item.result !== 'abnormal') { item.desc = ''; item.images = [] }
    },
    onUploadSuccess(res, item) {
      if (res.code === 0 && res.data && res.data.url) {
        if (!item.images) item.images = []
        item.images.push(res.data.url)
      } else this.$message.error('上传失败')
    },
    validateItems() {
      for (const it of this.items) {
        if (it.required && !it.result) { this.$message.warning(`必填项【${it.name}】未填写`); return false }
        if (it.result === 'abnormal') {
          const desc = (it.desc || '').trim()
          if (desc.length < 10) { this.$message.warning(`异常项【${it.name}】必须填写异常描述（不少于10字）`); return false }
        }
      }
      return true
    },
    buildPayload() {
      return {
        task_id: this.taskId,
        remark: this.remark,
        items: this.items.map((x, i) => ({
          item_id: x.id, name: x.name, result: x.result, desc: x.desc || '', images: x.images || [], sort: i + 1
        }))
      }
    },
    async submit() {
      if (!this.validateItems()) return
      if (!this.items.length) { this.$message.warning('该任务无检查项，无法提交'); return }
      this.$confirm('确认提交巡检结果？提交后生成巡检记录并进入审核。', '提交确认', { type: 'warning' })
        .then(async () => {
          this.submitting = true
          try {
            await startExecute(this.taskId)
            const res = await submitExecute(this.buildPayload())
            this.$message.success(res.msg || '提交成功')
            setTimeout(() => this.$router.push({ path: '/device/inspection' }), 800)
          } catch (e) { /* 拦截器已提示 */ }
          this.submitting = false
        }).catch(() => {})
    },
    async draft() {
      try {
        await draftExecute(this.buildPayload())
        this.$message.success('草稿已保存')
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.execute-page { padding: 16px; }
.crumb { margin-bottom: 14px; }
.panel { background: #fff; border-radius: 8px; padding: 14px; margin-bottom: 12px; }
.task-head { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.task-title { font-size: 17px; font-weight: 700; }
.task-line { color: #606266; font-size: 13px; margin: 3px 0; }
.section-title { font-size: 15px; font-weight: 600; margin-bottom: 10px; }
.item-card { border: 1px solid #ebeef5; border-radius: 8px; padding: 12px; margin-bottom: 10px; }
.item-top { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; }
.item-name { font-size: 14px; font-weight: 600; }
.item-line { color: #909399; font-size: 12px; margin-bottom: 8px; }
.abnormal-box { margin-top: 8px; background: #fef0f0; border-radius: 6px; padding: 10px; }
.img-list { display: flex; gap: 8px; margin-top: 8px; flex-wrap: wrap; }
.btn-row { display: flex; gap: 8px; margin-top: 12px; }
</style>
