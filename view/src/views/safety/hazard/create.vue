<template>
  <div class="hazard-create-page">
    <!-- 顶部 -->
    <div class="page-head">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>安全管理</el-breadcrumb-item>
        <el-breadcrumb-item>隐患管理</el-breadcrumb-item>
        <el-breadcrumb-item>新增隐患</el-breadcrumb-item>
      </el-breadcrumb>
      <h2 class="page-title">新增隐患记录</h2>
    </div>

    <el-row :gutter="20">
      <!-- 左栏 17/24 -->
      <el-col :span="17">
        <el-form ref="hazardForm" :model="form" :rules="rules" label-width="120px" label-position="right" size="small">
          <el-form-item label="隐患编号">
            <el-input v-model="form.hazard_code" disabled style="background:#f5f7fa" />
          </el-form-item>
          <el-form-item label="隐患名称" prop="hazard_name">
            <el-input v-model="form.hazard_name" maxlength="200" placeholder="请输入隐患名称" />
          </el-form-item>
          <el-row :gutter="16">
            <el-col :span="12">
              <el-form-item label="隐患类型" prop="hazard_type">
                <el-select v-model="form.hazard_type" placeholder="请选择隐患类型" style="width:100%">
                  <el-option v-for="t in dicts.type" :key="t.value" :label="t.label" :value="t.value" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="隐患等级" prop="hazard_level">
                <el-select v-model="form.hazard_level" placeholder="请选择隐患等级" style="width:100%">
                  <el-option v-for="t in dicts.level" :key="t.value" :label="t.label" :value="t.value">
                    <span :style="{ color: levelColor(t.value) }">{{ t.label }}</span>
                  </el-option>
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>
          <el-row :gutter="16">
            <el-col :span="12">
              <el-form-item label="来源类型" prop="source_type">
                <el-select v-model="form.source_type" placeholder="请选择来源类型" style="width:100%" @change="onSourceTypeChange">
                  <el-option v-for="t in dicts.source" :key="t.value" :label="t.label" :value="t.value" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item v-if="needSourceId" label="来源编号" prop="source_id">
                <div style="display:flex;gap:6px">
                  <el-input :value="sourceIdText" placeholder="请选择来源记录" readonly style="flex:1" />
                  <el-button icon="el-icon-search" @click="openSourceSelect" />
                </div>
              </el-form-item>
            </el-col>
          </el-row>
          <el-row :gutter="16">
            <el-col :span="12">
              <el-form-item label="发现位置">
                <el-input v-model="form.location" maxlength="200" placeholder="请输入发现位置" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="发现人" prop="discovered_by">
                <el-select v-model="form.discovered_by" filterable placeholder="请选择发现人" style="width:100%">
                  <el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" />
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>
          <el-form-item label="发现时间" prop="discovered_at">
            <el-date-picker v-model="form.discovered_at" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" placeholder="请选择发现时间" style="width:100%" />
          </el-form-item>
          <el-form-item label="隐患描述" prop="hazard_desc">
            <el-input v-model="form.hazard_desc" type="textarea" :rows="4" maxlength="1000" show-word-limit placeholder="请详细描述隐患情况，至少20个字符" />
          </el-form-item>
          <el-form-item label="指派人">
            <el-select v-model="form.assigned_to" clearable filterable placeholder="请选择指派人（清空则待处理，选择则整改中）" style="width:100%">
              <el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="备注">
            <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="500" show-word-limit placeholder="请输入备注信息" />
          </el-form-item>
        </el-form>
      </el-col>

      <!-- 右栏 7/24 -->
      <el-col :span="7">
        <el-card shadow="never" class="r-card">
          <div slot="header" class="card-head"><span>隐患图片</span><span class="img-count">已上传 {{ imageList.length }} 张</span></div>
          <el-upload action="/api/upload/image" :headers="uploadHeaders" list-type="picture-card" multiple :limit="9"
                     accept="image/jpeg,image/png,image/gif,image/webp" :file-list="imageList"
                     :before-upload="beforeUpload" :on-success="onUploadSuccess" :on-remove="onRemove" :on-preview="onPreview">
            <i class="el-icon-plus"></i>
          </el-upload>
          <div v-if="uploadError" style="color:#F56C6C;font-size:12px;margin-top:6px">{{ uploadError }}</div>
        </el-card>

        <el-card shadow="never" class="r-card">
          <div slot="header" class="card-head">来源信息预览</div>
          <div v-if="!needSourceId" style="color:#909399;font-size:13px">当前来源无需关联业务记录</div>
          <div v-else-if="sourcePreview" class="src-preview">
            <template v-if="form.source_type === 'inspection'">
              <div class="sp-row">巡检编号：{{ sourcePreview.record_code || '-' }}</div>
              <div class="sp-row">设备名称：{{ sourcePreview.device_name || '-' }}</div>
              <div class="sp-row">设备编码：{{ sourcePreview.device_code || '-' }}</div>
              <div class="sp-row">巡检时间：{{ sourcePreview.execute_time || '-' }}</div>
              <div class="sp-row">巡检结果：{{ sourcePreview.result === 'abnormal' ? '异常' : '正常' }}</div>
            </template>
            <div v-else style="color:#909399;font-size:13px">{{ (sourcePreview.summary && sourcePreview.summary.msg) || '请选择来源记录' }}</div>
          </div>
          <div v-else style="color:#909399;font-size:13px">请选择来源记录</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 底部操作 -->
    <div class="footer-bar">
      <el-button type="primary" :loading="submitting" @click="submit('pending')">提交</el-button>
      <el-button :loading="submitting" @click="submit('draft')">暂存</el-button>
      <el-button @click="onCancel">取消</el-button>
    </div>

    <!-- 来源选择对话框 -->
    <source-select-dialog :visible.sync="sourceSelectVisible" :source-type="form.source_type" @select="onSourceSelected" />
  </div>
</template>

<script>
import { addHazard, suggestHazardCode, getSourcePreview } from '@/api/safetyHazard'
import { getDictionaryBatch } from '@/utils/dict'
import { getManagers } from '@/api/deviceAsset'
import { getToken } from '@/utils/auth'
import SourceSelectDialog from './components/SourceSelectDialog.vue'

export default {
  name: 'HazardCreate',
  components: { SourceSelectDialog },
  data() {
    const now = this.nowStr()
    return {
      submitting: false,
      dicts: { type: [], level: [], source: [] },
      managerList: [],
      imageList: [], uploadError: '',
      sourceSelectVisible: false, sourceIdText: '', sourcePreview: null, selectedSourceRow: null,
      form: {
        hazard_code: '', hazard_name: '', hazard_type: 'equipment', hazard_level: 'general',
        source_type: 'manual', source_id: null, location: '', discovered_by: 0, discovered_at: now,
        hazard_desc: '', assigned_to: null, remark: ''
      },
      rules: {
        hazard_name: [{ required: true, message: '请输入隐患名称', trigger: 'blur' }],
        hazard_type: [{ required: true, message: '请选择隐患类型', trigger: 'change' }],
        hazard_level: [{ required: true, message: '请选择隐患等级', trigger: 'change' }],
        source_type: [{ required: true, message: '请选择来源类型', trigger: 'change' }],
        source_id: [{ validator: (r, v, cb) => { if (this.needSourceId && !this.form.source_id) cb(new Error('请选择来源记录')); else cb() }, trigger: 'change' }],
        discovered_by: [{ required: true, message: '请选择发现人', trigger: 'change' }],
        discovered_at: [{ required: true, message: '请选择发现时间', trigger: 'change' }],
        hazard_desc: [
          { required: true, message: '请输入隐患描述', trigger: 'blur' },
          { min: 20, message: '隐患描述至少20个字符', trigger: 'blur' }
        ]
      }
    }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } },
    needSourceId() { return ['inspection', 'safety_check', 'repair'].includes(this.form.source_type) }
  },
  async created() {
    const dict = await getDictionaryBatch(['safety_hazard_type', 'safety_hazard_level', 'safety_hazard_source'])
    this.dicts = { type: dict['safety_hazard_type'] || [], level: dict['safety_hazard_level'] || [], source: dict['safety_hazard_source'] || [] }
    const m = await getManagers()
    this.managerList = m.data || []
    // 默认发现人=当前用户（从 store userInfo 取 id）
    const user = this.$store.state.user && this.$store.state.user.userInfo
    this.form.discovered_by = (user && user.id) || 0
    // 自动生成编号
    try { const r = await suggestHazardCode(); if (r.code === 0) this.form.hazard_code = r.data.hazard_code } catch (e) {}
    // 离开确认
    window.addEventListener('beforeunload', this.beforeUnload)
  },
  beforeDestroy() { window.removeEventListener('beforeunload', this.beforeUnload) },
  methods: {
    nowStr() { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}` },
    levelColor(v) { return { minor: '#909399', general: '#409EFF', serious: '#E6A23C', emergency: '#F56C6C' }[v] || '' },
    onSourceTypeChange() { this.form.source_id = null; this.sourceIdText = ''; this.sourcePreview = null; this.selectedSourceRow = null },
    openSourceSelect() { if (this.needSourceId) this.sourceSelectVisible = true },
    onSourceSelected({ sourceType, sourceId, row }) {
      this.form.source_id = sourceId
      this.sourceIdText = row.record_code || row.check_code || row.repair_code || String(sourceId)
      this.selectedSourceRow = row
      this.loadSourcePreview()
    },
    async loadSourcePreview() {
      try {
        const r = await getSourcePreview(this.form.source_type, this.form.source_id)
        if (r.code === 0) this.sourcePreview = r.data
      } catch (e) {}
    },
    beforeUpload(file) {
      if (file.size > 5 * 1024 * 1024) { this.uploadError = '单张图片不能超过5MB'; return false }
      this.uploadError = ''
      return true
    },
    onUploadSuccess(res, file) {
      if (res.code === 0 && res.data && res.data.url) {
        file.url = res.data.url
        this.imageList.push({ name: file.name, url: res.data.url, status: 'success' })
      } else this.uploadError = '图片上传失败'
    },
    onRemove(file) {
      const i = this.imageList.findIndex(x => x.uid === file.uid || x.url === file.url)
      if (i > -1) this.imageList.splice(i, 1)
    },
    onPreview(file) {
      if (file.url) window.open(file.url, '_blank')
    },
    submit(status) {
      this.$refs.hazardForm.validate(async (valid) => {
        if (!valid) return
        this.submitting = true
        try {
          const payload = {
            ...this.form,
            source_id: this.form.source_id || undefined,
            hazard_images: this.imageList.map(x => x.url),
            status
          }
          const res = await addHazard(payload)
          this.$message.success(res.msg || '保存成功')
          setTimeout(() => this.$router.push('/safety/hazard'), 800)
        } catch (e) {}
        this.submitting = false
      })
    },
    onCancel() {
      if (this.hasUnsaved()) {
        this.$confirm('您有未保存的数据，确定要离开吗？', '提示', { type: 'warning' })
          .then(() => this.$router.push('/safety/hazard')).catch(() => {})
      } else this.$router.push('/safety/hazard')
    },
    hasUnsaved() {
      return this.form.hazard_name || this.form.hazard_desc || this.form.location || this.imageList.length
    },
    beforeUnload(e) { if (this.hasUnsaved()) { e.preventDefault(); e.returnValue = '' } }
  }
}
</script>

<style scoped>
.hazard-create-page { padding: 16px; }
.page-head { margin-bottom: 16px; }
.page-title { font-size: 20px; margin: 10px 0 0; }
.r-card { margin-bottom: 16px; }
.card-head { display: flex; justify-content: space-between; align-items: center; }
.img-count { color: #909399; font-size: 12px; }
.src-preview { font-size: 13px; }
.sp-row { color: #606266; padding: 3px 0; }
.footer-bar { position: fixed; bottom: 0; left: 50%; transform: translateX(-50%); width: 100%; max-width: 1200px; background: #fff; padding: 10px 20px; box-shadow: 0 -2px 8px rgba(0,0,0,.06); display: flex; gap: 8px; z-index: 10; }
</style>
