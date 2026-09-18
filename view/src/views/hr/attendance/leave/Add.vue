<!--
  文件：admin/src/views/hr/attendance/leave/Add.vue
  功能：新增/编辑假勤申请（类型/日期/天数/事由/附件/审批人）
  权限：hr:attendance:leave:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>考勤管理</el-breadcrumb-item>
      <el-breadcrumb-item>假勤申请</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑申请' : '新增申请' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? `编辑假勤申请 - ${form.request_no || ''}` : '新增假勤申请' }}</span>
      <div>
        <el-button size="small" @click="handleBack">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="假勤类型" prop="leave_type">
              <el-select v-model="form.leave_type" placeholder="请选择假勤类型" style="width:100%">
                <el-option v-for="(t, v) in LEAVE_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="总天数" prop="total_days">
              <el-input-number v-model="form.total_days" :min="0.5" :step="0.5" :precision="1" :disabled="true" style="width:100%" />
              <div style="font-size:12px;color:#C0C4CC;line-height:1.5;margin-top:2px">根据开始/结束日期自动计算</div>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="开始日期" prop="start_date">
              <el-date-picker v-model="form.start_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择开始日期" style="width:100%" @change="calcDays" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="结束日期" prop="end_date">
              <el-date-picker v-model="form.end_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择结束日期" style="width:100%" @change="calcDays" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="开始时段">
              <el-select v-model="form.start_period" placeholder="请选择时段" style="width:100%">
                <el-option label="上午" value="上午" />
                <el-option label="下午" value="下午" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="结束时段">
              <el-select v-model="form.end_period" placeholder="请选择时段" style="width:100%">
                <el-option label="上午" value="上午" />
                <el-option label="下午" value="下午" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="审批人">
              <el-select v-model="form.approver_id" filterable clearable placeholder="请选择审批人" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="申请事由" prop="reason">
              <el-input v-model="form.reason" type="textarea" :rows="4" maxlength="500" show-word-limit placeholder="请详细描述申请事由" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="紧急联系人">
              <el-input v-model="form.emergency_contact_name" placeholder="紧急联系人姓名" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="联系电话">
              <el-input v-model="form.emergency_contact_phone" placeholder="紧急联系人电话" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="附件">
              <el-upload :action="''" :auto-upload="false" :on-change="onFileChange" :file-list="form.attachments" multiple :limit="10" list-type="text">
                <el-button size="small" icon="el-icon-upload2">选择文件</el-button>
                <div slot="tip" class="upload-tip">支持 jpg/jpeg/png/gif/pdf/docx，单个不超过 5MB</div>
              </el-upload>
              <div style="margin-top:6px">
                <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
              </div>
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="请输入备注信息" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>
    <drive-file-picker :visible="driveVisible" mode="file" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
  </div>
</template>

<script>
import { getLeaveDetail, saveLeave, uploadLeaveAttachment } from '@/api/attendanceLeave'
import { getUserList } from '@/api/user'

const LEAVE_TYPES = { 1: '年假', 2: '事假', 3: '病假', 4: '调休', 5: '加班', 6: '出差', 7: '婚假', 8: '丧假', 9: '产假', 10: '其他' }

export default {
  name: 'HrLeaveAdd',
  data () {
    return {
      driveVisible: false,
      LEAVE_TYPES,
      isEdit: false, saving: false, userOptions: [],
      form: {
        id: 0, request_no: '', leave_type: 1, start_date: '', end_date: '', start_time: '', end_time: '',
        start_period: '上午', end_period: '上午',
        total_days: 1, reason: '', emergency_contact_name: '', emergency_contact_phone: '', approver_id: 0, remark: '', attachments: []
      },
      rules: {
        leave_type: [{ required: true, message: '请选择假勤类型', trigger: 'change' }],
        start_date: [{ required: true, message: '请选择开始日期', trigger: 'change' }],
        end_date: [{ required: true, message: '请选择结束日期', trigger: 'change' }],
        total_days: [{ required: true, message: '请输入总天数', trigger: 'change' }],
        reason: [{ required: true, message: '请填写申请事由', trigger: 'blur' }]
      }
    }
  },
  computed: {},
  watch: {
    'form.start_period' () { this.calcDays() },
    'form.end_period' () { this.calcDays() }
  },
  created () {
    this.isEdit = !!this.$route.params.id
    this.loadUsers()
    if (this.isEdit) this.loadDetail(Number(this.$route.params.id))
  },
  methods: {
    async loadUsers () {
      try {
        const r = await getUserList({ page: 1, limit: 500 })
        this.userOptions = (r.data && r.data.list) || []
      } catch (e) { this.userOptions = [] }
    },
    calcDays () {
      if (this.form.start_date && this.form.end_date) {
        if (this.form.start_date === this.form.end_date) {
          // 同一天：时段相同=0.5天，时段不同=1天
          this.form.total_days = this.form.start_period === this.form.end_period ? 0.5 : 1
        } else {
          // 跨天：整天数 - 开始日下午减0.5 - 结束日上午减0.5
          const s = new Date(this.form.start_date)
          const e = new Date(this.form.end_date)
          const base = Math.round((e - s) / 86400000) + 1
          let days = base
          if (this.form.start_period === '下午') days -= 0.5
          if (this.form.end_period === '上午') days -= 0.5
          this.form.total_days = days > 0 ? days : 0.5
        }
      }
    },
    onDrivePick(list) {
      const f = list[0]
      if (!f) return
      fetch(f.url).then(res => res.blob()).then(blob => {
        const raw = new File([blob], f.name, { type: blob.type || 'application/octet-stream' })
        this.onFileChange({ status: 'ready', raw, name: f.name, size: raw.size }, [])
      }).catch(() => this.$message.error('读取网盘文件失败'))
    },
    onFileChange (file, fileList) {
      // 本地选择后自动上传
      if (file.status === 'ready' && file.raw) {
        const fd = new FormData()
        fd.append('file', file.raw)
        uploadLeaveAttachment(fd).then(r => {
          if (r.code === 0 && r.data) {
            const att = { attachment_type: 1, file_name: r.data.name, file_path: r.data.url, file_size: r.data.size, remark: '' }
            const idx = this.form.attachments.findIndex(a => a.file_name === r.data.name)
            if (idx > -1) this.form.attachments.splice(idx, 1, att)
            else this.form.attachments.push(att)
            this.$message.success('上传成功')
          } else this.$message.error(r.msg || '上传失败')
        })
      }
    },
    async loadDetail (id) {
      try {
        const r = await getLeaveDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            id: d.id, request_no: d.request_no, leave_type: d.leave_type, start_date: d.start_date,
            end_date: d.end_date, start_time: d.start_time || '', end_time: d.end_time || '',
            start_period: (d.start_time || '').slice(0, 2) === '13' ? '下午' : '上午',
            end_period: (d.end_time || '').slice(0, 2) === '13' ? '下午' : '上午',
            total_days: Number(d.total_days) || 1, reason: d.reason || '', emergency_contact_name: d.emergency_contact_name || '',
            emergency_contact_phone: d.emergency_contact_phone || '', approver_id: d.approver_id || 0,
            remark: d.remark || '',
            attachments: (d.attachments || []).map(a => ({ attachment_type: a.attachment_type, file_name: a.file_name, file_path: a.file_path, file_size: a.file_size, remark: a.remark || '' }))
          }
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    handleBack () {
      if (this.form.reason || this.form.start_date) {
        this.$confirm('当前有未保存的内容，确认离开吗？', '提示', { type: 'warning' }).then(() => {
          this.$router.push({ path: '/hr/attendance/leave' })
        }).catch(() => {})
        return
      }
      this.$router.push({ path: '/hr/attendance/leave' })
    },
    handleSave () {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (this.form.end_date < this.form.start_date) { this.$message.warning('结束日期不能早于开始日期'); return }
        this.saving = true
        try {
          const payload = {
            id: this.form.id, leave_type: this.form.leave_type, start_date: this.form.start_date,
            end_date: this.form.end_date,
            start_time: this.form.start_period === '下午' ? '13:00' : '09:00',
            end_time: this.form.end_period === '下午' ? '18:00' : '12:00',
            total_days: this.form.total_days, reason: this.form.reason,
            emergency_contact_name: this.form.emergency_contact_name || '', emergency_contact_phone: this.form.emergency_contact_phone || '',
            approver_id: this.form.approver_id,
            remark: this.form.remark,
            attachments: (this.form.attachments || []).map(a => ({ attachment_type: a.attachment_type || 1, file_name: a.file_name, file_path: a.file_path, file_size: a.file_size || 0, remark: a.remark || '' }))
          }
          const r = await saveLeave(payload)
          if (r.code === 0) {
            this.$message.success(r.msg || '保存成功')
            this.$router.push({ path: '/hr/attendance/leave' })
          } else this.$message.error(r.msg || '保存失败')
        } catch (e) {} finally { this.saving = false }
      })
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-title { font-size: 18px; font-weight: bold; }
.form-card { margin-bottom: 16px; }
.upload-tip { color: #909399; font-size: 12px; line-height: 1.6; }
</style>
