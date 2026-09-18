<template>
  <div class="hazard-form-page">
    <el-breadcrumb separator="/" class="crumb">
      <el-breadcrumb-item>安全管理</el-breadcrumb-item>
      <el-breadcrumb-item>隐患管理</el-breadcrumb-item>
      <el-breadcrumb-item>隐患整改</el-breadcrumb-item>
    </el-breadcrumb>
    <div class="panel" v-loading="loading">
      <!-- 隐患信息展示 -->
      <el-descriptions :column="3" border size="small" title="隐患信息">
        <el-descriptions-item label="隐患编号">{{ d.hazard_code || '-' }}</el-descriptions-item>
        <el-descriptions-item label="隐患名称">{{ d.hazard_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="状态"><el-tag :type="statusType" size="mini">{{ statusLabel }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="隐患类型">{{ typeLabel }}</el-descriptions-item>
        <el-descriptions-item label="隐患等级">{{ levelLabel }}</el-descriptions-item>
        <el-descriptions-item label="发现位置">{{ d.location || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发现人">{{ d.discovered_by_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发现时间">{{ d.discovered_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="整改期限">{{ form.handler_deadline || '-' }}</el-descriptions-item>
        <el-descriptions-item label="隐患描述" :span="3">{{ d.hazard_desc || '-' }}</el-descriptions-item>
        <el-descriptions-item label="隐患图片" :span="3">
          <el-image v-for="(img, i) in hazardImages" :key="i" :src="img" style="width:60px;height:60px;margin-right:6px" fit="cover" :preview-src-list="hazardImages" />
          <span v-if="!hazardImages.length">-</span>
        </el-descriptions-item>
      </el-descriptions>

      <!-- 整改表单 -->
      <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small" style="margin-top:20px;max-width:800px">
        <el-form-item v-if="d.status === 'pending'" label="整改人">
          <el-select v-model="form.handler_id" clearable filterable style="width:300px"><el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" /></el-select>
        </el-form-item>
        <el-form-item label="整改期限">
          <el-date-picker v-model="form.handler_deadline" type="date" value-format="yyyy-MM-dd" style="width:300px" />
        </el-form-item>
        <el-form-item label="整改措施" prop="handle_measure">
          <el-input v-model="form.handle_measure" type="textarea" :rows="4" maxlength="500" show-word-limit placeholder="请填写整改措施" />
        </el-form-item>
        <el-form-item label="整改附件">
          <el-upload action="/api/upload/image" :headers="uploadHeaders" list-type="picture-card" multiple :limit="5" accept="image/jpeg,image/png,image/gif,image/webp"
                     :before-upload="beforeUpload" :on-success="onUploadSuccess" :on-remove="onRemove" :on-preview="onPreview">
            <i class="el-icon-plus"></i>
          </el-upload>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="submitting" @click="submit">提交整改完成</el-button>
          <el-button @click="$router.back()">返回</el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script>
import { getHazardDetail, handleComplete } from '@/api/safetyHazard'
import { getDictionaryBatch } from '@/utils/dict'
import { getManagers } from '@/api/deviceAsset'
import { getToken } from '@/utils/auth'

export default {
  name: 'HazardHandle',
  data() {
    return {
      id: 0, d: {}, loading: false, submitting: false,
      dicts: { type: [], level: [], status: [] }, managerList: [], attachments: [],
      form: { handler_id: null, handler_deadline: null, handle_measure: '' },
      rules: { handle_measure: [{ required: true, message: '请填写整改措施', trigger: 'blur' }] }
    }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } },
    hazardImages() { const v = this.d.hazard_images; return Array.isArray(v) ? v : (typeof v === 'string' && v ? JSON.parse(v) : []) },
    statusLabel() { const s = this.dicts.status.find(x => x.value === this.d.status); return s ? s.label : (this.d.status || '-') },
    statusType() { const s = this.dicts.status.find(x => x.value === this.d.status); return (s && s.style) || 'info' },
    typeLabel() { const t = this.dicts.type.find(x => x.value === this.d.hazard_type); return t ? t.label : (this.d.hazard_type || '-') },
    levelLabel() { const t = this.dicts.level.find(x => x.value === this.d.hazard_level); return t ? t.label : (this.d.hazard_level || '-') }
  },
  async created() {
    this.id = Number(this.$route.query.id || 0)
    const dict = await getDictionaryBatch(['safety_hazard_type', 'safety_hazard_level', 'safety_hazard_status'])
    this.dicts = { type: dict['safety_hazard_type'] || [], level: dict['safety_hazard_level'] || [], status: dict['safety_hazard_status'] || [] }
    const m = await getManagers()
    this.managerList = m.data || []
    if (this.id) this.loadData()
  },
  async loadData() {
    this.loading = true
    try {
      const res = await getHazardDetail(this.id)
      if (res.code === 0) {
        this.d = res.data
        this.form.handler_id = res.data.handler_id || res.data.assigned_to || null
        this.form.handler_deadline = res.data.handler_deadline || null
        this.form.handle_measure = res.data.handle_measure || ''
      }
    } catch (e) {}
    this.loading = false
  },
  beforeUpload(file) { if (file.size > 5 * 1024 * 1024) { this.$message.error('附件不能超过5MB'); return false } return true },
  onUploadSuccess(res, file) { if (res.code === 0 && res.data && res.data.url) this.attachments.push(res.data.url) },
  onRemove(file) {
    const url = file.url || (file.response && file.response.data && file.response.data.url)
    this.attachments = this.attachments.filter(x => x !== url)
  },
  onPreview(file) { if (file.url) window.open(file.url, '_blank') },
  submit() {
    this.$refs.form.validate(async (valid) => {
      if (!valid) return
      this.submitting = true
      try {
        await handleComplete(this.id, {
          handle_measure: this.form.handle_measure,
          handler_deadline: this.form.handler_deadline || '',
          handle_attachments: this.attachments,
          handler_id: this.form.handler_id || undefined
        })
        this.$message.success('整改完成，已进入验证')
        setTimeout(() => this.$router.push('/safety/hazard'), 800)
      } catch (e) {}
      this.submitting = false
    })
  }
}
</script>

<style scoped>
.hazard-form-page { padding: 16px; }
.crumb { margin-bottom: 14px; }
.panel { background: #fff; border-radius: 8px; padding: 16px; }
</style>
