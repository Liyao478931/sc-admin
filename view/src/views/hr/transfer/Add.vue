<!--
  文件：admin/src/views/hr/transfer/Add.vue
  功能：新增/编辑员工异动（类型动态表单 / 员工带出原信息 / 离职专属 / 附件 / 审批人）
  权限：hr:transfer:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>员工异动</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑异动' : '新增异动' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? `编辑员工异动 - ${form.transfer_no || ''}` : '新增员工异动' }}</span>
      <div>
        <el-button size="small" @click="handleBack">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="140px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="异动类型" prop="transfer_type">
              <el-select v-model="form.transfer_type" placeholder="请选择异动类型" style="width:100%" @change="onTypeChange">
                <el-option v-for="(t, v) in TRANSFER_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="员工" prop="employee_id">
              <el-select v-model="form.employee_id" filterable clearable placeholder="请选择员工（工号 - 姓名 - 部门/岗位）" style="width:100%" @change="onEmployeeChange">
                <el-option v-for="e in filteredEmployees" :key="e.id" :label="`${e.employee_id} - ${e.name} - ${e.department_name}/${e.position_name}`" :value="e.id" />
              </el-select>
            </el-form-item>
          </el-col>

          <template v-if="form.employee_id">
            <el-col :span="12"><el-form-item label="原部门"><el-input :value="form.before_department_name" disabled /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="原岗位"><el-input :value="form.before_position_name" disabled /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="原职级"><el-input :value="form.before_rank_name" disabled /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="原薪资"><el-input-number v-model="form.before_salary" :min="0" :precision="2" :controls="false" style="width:100%" /></el-form-item></el-col>
</template>

          <template v-if="showAfter">
            <el-col :span="12">
              <el-form-item :label="form.transfer_type === 1 ? '新部门（选填）' : '新部门'" prop="after_department_id">
                <el-select v-model="form.after_department_id" clearable placeholder="请选择新部门" style="width:100%" @change="onAfterDeptChange">
                  <el-option v-for="d in departmentOptions" :key="d.id" :label="d.name" :value="d.id" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item :label="form.transfer_type === 1 ? '新岗位（选填）' : '新岗位'" prop="after_position_id">
                <el-select v-model="form.after_position_id" clearable placeholder="请选择新岗位" style="width:100%">
                  <el-option v-for="p in filteredPositions" :key="p.id" :label="p.name" :value="p.id" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item :label="form.transfer_type === 1 ? '新职级（选填）' : '新职级'" prop="after_rank_id">
                <el-select v-model="form.after_rank_id" clearable placeholder="请选择新职级" style="width:100%">
                  <el-option v-for="r in rankOptions" :key="r.id" :label="`${r.rank_name}（${r.rank_code}）`" :value="r.id" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item :label="form.transfer_type === 1 ? '新薪资（选填）' : '新薪资'" prop="after_salary">
                <el-input-number v-model="form.after_salary" :min="0" :precision="2" :controls="false" style="width:100%" />
              </el-form-item>
            </el-col>
          </template>

          <el-col :span="12">
            <el-form-item label="异动生效日期" prop="transfer_date">
              <el-date-picker v-model="form.transfer_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择异动生效日期" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="审批人">
              <el-select v-model="form.approver_id" filterable clearable placeholder="请选择审批人（默认管理员）" style="width:100%">
                <el-option v-for="u in approverOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
          </el-col>

          <template v-if="form.transfer_type === 5">
            <el-col :span="12">
              <el-form-item label="离职类型" prop="leave_type">
                <el-select v-model="form.leave_type" placeholder="请选择离职类型" style="width:100%">
                  <el-option v-for="(t, v) in LEAVE_TYPES" :key="v" :label="t" :value="Number(v)" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="最后工作日" prop="last_work_date">
                <el-date-picker v-model="form.last_work_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择最后工作日" style="width:100%" :picker-options="lastWorkDateOptions" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="交接人" prop="handover_person_id">
                <el-select v-model="form.handover_person_id" filterable clearable placeholder="请选择工作交接人" style="width:100%">
                  <el-option v-for="e in allEmployees" :key="e.id" :label="`${e.employee_id} - ${e.name}`" :value="e.id" />
                </el-select>
              </el-form-item>
            </el-col>
          </template>

          <el-col :span="24">
            <el-form-item label="异动原因" prop="transfer_reason">
              <el-input v-model="form.transfer_reason" type="textarea" :rows="3" maxlength="500" show-word-limit placeholder="请填写异动原因" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="附件">
              <el-upload :action="''" :auto-upload="false" :on-change="onFileChange" :file-list="uploadList" multiple :limit="10" list-type="text">
                <el-button size="small" icon="el-icon-upload2">选择文件</el-button>
                <div slot="tip" class="upload-tip">支持 jpg/jpeg/png/gif/pdf/docx，单个不超过 5MB</div>
              </el-upload>
              <div style="margin-top:6px">
                <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
              </div>
              <drive-file-picker :visible="driveVisible" mode="file" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="请输入备注信息" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { getTransferDetail, saveTransfer, uploadTransferAttachment, getTransferOptions, getTransferEmployees } from '@/api/hrTransfer'

const TRANSFER_TYPES = { 1: '转正', 2: '调岗', 3: '晋升', 4: '降职', 5: '离职', 6: '复职' }
const LEAVE_TYPES = { 1: '主动辞职', 2: '协商解除', 3: '辞退', 4: '合同到期不续签' }

export default {
  name: 'HrTransferAdd',
  data () {
    return {
      driveVisible: false,
      TRANSFER_TYPES, LEAVE_TYPES,
      isEdit: false, saving: false,
      departmentOptions: [], positionOptions: [], rankOptions: [], approverOptions: [], allEmployees: [],
      uploadList: [],
      form: {
        id: 0, transfer_no: '', transfer_type: 1, employee_id: 0,
        before_department_id: 0, before_department_name: '', before_position_id: 0, before_position_name: '',
        before_rank_id: 0, before_rank_name: '', before_salary: 0,
        after_department_id: 0, after_position_id: 0, after_rank_id: 0, after_salary: 0,
        transfer_reason: '', transfer_date: '', approver_id: 0,
        leave_type: 1, last_work_date: '', handover_person_id: 0,
        remark: '', attachments: []
      },
      rules: {
        transfer_type: [{ required: true, message: '请选择异动类型', trigger: 'change' }],
        employee_id: [{ required: true, message: '请选择员工', trigger: 'change' }],
        transfer_date: [{ required: true, message: '请选择异动生效日期', trigger: 'change' }],
        transfer_reason: [{ required: true, message: '请填写异动原因', trigger: 'blur' }],
        after_department_id: [{ required: true, message: '请选择新部门', trigger: 'change' }],
        after_position_id: [{ required: true, message: '请选择新岗位', trigger: 'change' }],
        after_rank_id: [{ required: true, message: '请选择新职级', trigger: 'change' }],
        leave_type: [{ required: true, message: '请选择离职类型', trigger: 'change' }],
        last_work_date: [{ required: true, message: '请选择最后工作日', trigger: 'change' }],
        handover_person_id: [{ required: true, message: '请选择交接人', trigger: 'change' }]
      }
    }
  },
  computed: {
    showAfter () { return [1, 2, 3, 4, 6].includes(this.form.transfer_type) },
    filteredEmployees () {
      // 离职：全部员工；复职：已离职（4）；其他：在职（1试用 2正式 3实习）
      if (this.form.transfer_type === 5) return this.allEmployees
      if (this.form.transfer_type === 6) return this.allEmployees.filter(e => e.employee_status === 4)
      return this.allEmployees.filter(e => [1, 2, 3].includes(e.employee_status))
    },
    filteredPositions () {
      if (!this.form.after_department_id) return this.positionOptions
      return this.positionOptions.filter(p => !p.department_id || p.department_id === this.form.after_department_id)
    },
    lastWorkDateOptions () {
      const min = this.form.transfer_date
      return { disabledDate: time => (min ? time.getTime() < new Date(min).getTime() : false) }
    }
  },
  created () {
    this.isEdit = !!this.$route.params.id
    this.loadOptions()
    if (this.isEdit) this.loadDetail(Number(this.$route.params.id))
  },
  methods: {
    async loadOptions () {
      try {
        const r = await getTransferOptions()
        if (r.code === 0 && r.data) {
          this.departmentOptions = r.data.departments || []
          this.positionOptions = r.data.positions || []
          this.rankOptions = r.data.ranks || []
          this.approverOptions = r.data.approvers || []
        }
      } catch (e) {}
      try {
        const r = await getTransferEmployees({})
        if (r.code === 0 && r.data) this.allEmployees = r.data.list || []
      } catch (e) { this.allEmployees = [] }
    },
    onTypeChange () {
      // 切换类型：重置员工（不同类型可选员工范围不同）与变更后字段
      this.form.employee_id = 0
      this.resetBefore()
      this.resetAfter()
      if (this.form.transfer_type !== 5) { this.form.leave_type = 1; this.form.last_work_date = ''; this.form.handover_person_id = 0 }
    },
    resetBefore () {
      this.form.before_department_id = 0; this.form.before_department_name = ''
      this.form.before_position_id = 0; this.form.before_position_name = ''
      this.form.before_rank_id = 0; this.form.before_rank_name = ''
      this.form.before_salary = 0
    },
    resetAfter () {
      this.form.after_department_id = 0; this.form.after_position_id = 0; this.form.after_rank_id = 0; this.form.after_salary = 0
    },
    onEmployeeChange (id) {
      const e = this.allEmployees.find(x => x.id === id)
      if (!e) return
      this.form.before_department_id = e.department_id
      this.form.before_department_name = e.department_name
      this.form.before_position_id = e.position_id
      this.form.before_position_name = e.position_name
      this.form.before_rank_id = e.rank_id
      this.form.before_rank_name = e.rank_name
      this.form.before_salary = Number(e.salary) || 0
      // 转正/复职默认沿用原值
      if (this.form.transfer_type === 1 || this.form.transfer_type === 6) {
        this.form.after_department_id = e.department_id
        this.form.after_position_id = e.position_id
        this.form.after_rank_id = e.rank_id
        this.form.after_salary = Number(e.salary) || 0
      }
    },
    onAfterDeptChange () {
      if (this.form.after_position_id && !this.filteredPositions.some(p => p.id === this.form.after_position_id)) {
        this.form.after_position_id = 0
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
      if (file.status === 'ready' && file.raw) {
        const fd = new FormData()
        fd.append('file', file.raw)
        uploadTransferAttachment(fd).then(r => {
          if (r.code === 0 && r.data) {
            const att = { attachment_type: 4, file_name: r.data.name, file_path: r.data.url, file_size: r.data.size, file_type: (file.raw.type || '') }
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
        const r = await getTransferDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            id: d.id, transfer_no: d.transfer_no || '', transfer_type: d.transfer_type, employee_id: d.employee_id,
            before_department_id: d.before_department_id, before_department_name: d.before_department_name,
            before_position_id: d.before_position_id, before_position_name: d.before_position_name,
            before_rank_id: d.before_rank_id, before_rank_name: d.before_rank_name, before_salary: Number(d.before_salary) || 0,
            after_department_id: d.after_department_id, after_position_id: d.after_position_id,
            after_rank_id: d.after_rank_id, after_salary: Number(d.after_salary) || 0,
            transfer_reason: d.transfer_reason || '', transfer_date: d.transfer_date || '', approver_id: d.approver_id || 0,
            leave_type: d.leave_type || 1, last_work_date: d.last_work_date || '', handover_person_id: d.handover_person_id || 0,
            remark: d.remark || '',
            attachments: (d.attachments || []).map(a => ({ attachment_type: a.attachment_type, file_name: a.file_name, file_path: a.file_path, file_size: a.file_size, file_type: a.file_type || '' }))
          }
          this.uploadList = (d.attachments || []).map(a => ({ name: a.file_name, url: a.file_path }))
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    handleBack () {
      if (this.form.transfer_reason || this.form.employee_id) {
        this.$confirm('当前有未保存的内容，确认离开吗？', '提示', { type: 'warning' }).then(() => {
          this.$router.push({ path: '/hr/transfer/list' })
        }).catch(() => {})
        return
      }
      this.$router.push({ path: '/hr/transfer/list' })
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (this.form.transfer_type === 5 && this.form.last_work_date && this.form.transfer_date && this.form.last_work_date < this.form.transfer_date) {
          this.$message.warning('最后工作日不能早于异动生效日期'); return
        }
        this.saving = true
        try {
          const payload = {
            id: this.form.id, transfer_type: this.form.transfer_type, employee_id: this.form.employee_id,
            before_department_id: this.form.before_department_id, before_position_id: this.form.before_position_id,
            before_rank_id: this.form.before_rank_id, before_salary: this.form.before_salary,
            after_department_id: this.form.after_department_id || 0, after_position_id: this.form.after_position_id || 0,
            after_rank_id: this.form.after_rank_id || 0, after_salary: this.form.after_salary || 0,
            transfer_reason: this.form.transfer_reason, transfer_date: this.form.transfer_date,
            approver_id: this.form.approver_id || 0,
            leave_type: this.form.transfer_type === 5 ? this.form.leave_type : 0,
            last_work_date: this.form.transfer_type === 5 ? this.form.last_work_date : '',
            handover_person_id: this.form.transfer_type === 5 ? this.form.handover_person_id : 0,
            remark: this.form.remark,
            attachments: (this.form.attachments || []).map(a => ({ attachment_type: a.attachment_type || 4, file_name: a.file_name, file_path: a.file_path, file_size: a.file_size || 0, file_type: a.file_type || '' }))
          }
          saveTransfer(payload).then(r => {
            if (r.code === 0) {
              this.$message.success(r.msg || '保存成功')
              this.$router.push({ path: '/hr/transfer/list' })
            } else this.$message.error(r.msg || '保存失败')
          }).catch(() => {}).finally(() => { this.saving = false })
        } catch (e) { this.saving = false }
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
