<template>
  <el-dialog :title="orderId ? '编辑工单' : '新增工单'" :visible.sync="visible" width="700px" :close-on-click-modal="false">
    <el-form :model="form" :rules="rules" ref="form" label-width="100px" size="small">
      <el-divider content-position="left">来源信息</el-divider>
      <el-form-item label="来源类型">
        <el-select v-model="form.source_type" :disabled="!!orderId" style="width:200px">
          <el-option v-for="s in sourceOptions" :key="s.value" :label="s.label" :value="s.value" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="!orderId" label="设备" prop="device_id">
        <el-select v-model="form.device_id" filterable clearable placeholder="请选择设备" style="width:400px">
          <el-option v-for="d in deviceOptions" :key="d.id" :label="`${d.name}（${d.device_code}）`" :value="d.id" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="!orderId && form.source_type !== 'manual'" label="来源ID">
        <el-input v-model="form.source_id" placeholder="来源记录ID（巡检/保养记录）" style="width:200px" />
      </el-form-item>

      <el-divider content-position="left">故障信息</el-divider>
      <el-form-item label="故障类型" prop="fault_type">
        <el-select v-model="form.fault_type" style="width:200px">
          <el-option v-for="f in faultOptions" :key="f.value" :label="f.label" :value="f.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="紧急程度" prop="emergency_level">
        <el-radio-group v-model="form.emergency_level">
          <el-radio-button v-for="e in emergencyOptions" :key="e.value" :label="e.value">{{ e.label }}</el-radio-button>
        </el-radio-group>
      </el-form-item>
      <el-form-item label="故障描述" prop="fault_description">
        <el-input v-model="form.fault_description" type="textarea" :rows="4" maxlength="2000" show-word-limit placeholder="请描述故障现象（10-2000字）" />
      </el-form-item>

      <el-divider v-if="!orderId" content-position="left">报修信息</el-divider>
      <el-form-item v-if="!orderId" label="报修人">
        <el-select v-model="form.reporter_id" filterable clearable style="width:200px">
          <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="!orderId" label="报修时间">
        <el-date-picker v-model="form.report_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" style="width:220px" />
      </el-form-item>

      <el-divider content-position="left">附件与备注</el-divider>
      <el-form-item label="附件">
        <el-upload action="/api/upload/image" list-type="picture-card" :limit="9" :headers="uploadHeaders"
          :file-list="fileList" :on-success="onUpload" :on-remove="onRemove" :on-preview="onPreview">
          <i class="el-icon-plus"></i>
        </el-upload>
        <div style="margin-top:6px">
          <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
        </div>
        <drive-file-picker :visible="driveVisible" mode="image" :multiple="true" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
      </el-form-item>
      <el-form-item label="备注">
        <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="255" placeholder="备注信息" />
      </el-form-item>
    </el-form>
    <span slot="footer">
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="handleSave">保存</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { addOrder, editOrder } from '@/api/repairOrder'
import { getAssetList } from '@/api/deviceAsset'
import { getUserList } from '@/api/user'

export default {
  name: 'OrderFormDialog',
  props: {
    visible: Boolean,
    orderId: { type: Number, default: 0 }
  },
  data() {
    return {
      saving: false, deviceOptions: [], userOptions: [], fileList: [], driveVisible: false,
      sourceOptions: [],
      faultOptions: [],
      emergencyOptions: [],
      form: { device_id: null, fault_type: '', fault_description: '', emergency_level: 'normal', source_type: 'manual', source_id: '', reporter_id: null, report_time: '', remark: '', attachments: [] },
      rules: {
        device_id: [{ required: true, message: '请选择设备', trigger: 'change' }],
        fault_type: [{ required: true, message: '请选择故障类型', trigger: 'change' }],
        fault_description: [{ required: true, min: 10, message: '故障描述至少10字', trigger: 'blur' }]
      }
    }
  },
  computed: {
    uploadHeaders() {
      const t = this.$store.state.user.token || localStorage.getItem('token') || ''
      return t ? { Authorization: 'Bearer ' + t } : {}
    }
  },
  watch: {
    visible(v) {
      if (v) {
        this.loadDevices(); this.loadUsers(); this.loadDicts()
        if (this.orderId) this.loadDetail()
        else this.form = { device_id: null, fault_type: '', fault_description: '', emergency_level: 'normal', source_type: 'manual', source_id: '', reporter_id: null, report_time: this.nowStr(), remark: '', attachments: [] }
      }
    }
  },
  methods: {
    nowStr() {
      const d = new Date(); const p = n => String(n).padStart(2, '0')
      return `${d.getFullYear()}-${p(d.getMonth()+1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
    },
    // 来源/故障/紧急程度从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('repair_source_type'); this.sourceOptions = r.data || [] } catch (e) { this.sourceOptions = [] }
      try { const r = await getDictByCode('repair_fault_type'); this.faultOptions = r.data || [] } catch (e) { this.faultOptions = [] }
      try { const r = await getDictByCode('repair_emergency_level'); this.emergencyOptions = r.data || [] } catch (e) { this.emergencyOptions = [] }
    },
    async loadDevices() { try { const r = await getAssetList({ limit: 200, status: '' }); if (r.code === 0) this.deviceOptions = r.data.list || [] } catch (e) {} },
    async loadUsers() { try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {} },
    async loadDetail() {
      try {
        const { getOrderDetail } = await import('@/api/repairOrder')
        const r = await getOrderDetail(this.orderId)
        if (r.code === 0) {
          const d = r.data
          this.form = { device_id: d.device_id, fault_type: d.fault_type, fault_description: d.fault_description, emergency_level: d.emergency_level, source_type: d.source_type, source_id: d.source_id || '', reporter_id: d.reporter_id, report_time: d.report_time, remark: d.remark, attachments: d.attachments || [] }
          this.fileList = (d.attachments || []).map(u => ({ name: u.split('/').pop(), url: u }))
        }
      } catch (e) {}
    },
    onUpload(res, file) {
      if (res.code === 0 && res.data.url) this.form.attachments.push(res.data.url)
      else { this.$message.error(res.msg || '上传失败'); this.fileList = this.fileList.filter(x => x !== file) }
    },
    onRemove(file) { this.form.attachments = this.form.attachments.filter(u => u !== file.url) },
    onDrivePick(list) {
      list.forEach(f => {
        if (this.form.attachments.length >= 9) return
        this.form.attachments.push(f.url)
        this.fileList.push({ name: f.name, url: f.url })
      })
    },
    onPreview(file) { window.open(file.url, '_blank') },
    async handleSave() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      this.saving = true
      try {
        const payload = {
          fault_type: this.form.fault_type, fault_description: this.form.fault_description,
          emergency_level: this.form.emergency_level, remark: this.form.remark, attachments: this.form.attachments
        }
        if (!this.orderId) {
          Object.assign(payload, {
            device_id: this.form.device_id, source_type: this.form.source_type,
            source_id: this.form.source_id || 0, reporter_id: this.form.reporter_id || 0, report_time: this.form.report_time
          })
        }
        const r = this.orderId ? await editOrder(this.orderId, payload) : await addOrder(payload)
        if (r.code === 0) { this.$message.success('保存成功'); this.$emit('saved'); this.visible = false }
        else this.$message.error(r.msg || '保存失败')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
