<template>
  <el-dialog title="批量状态变更" :visible.sync="dialogVisible" width="700px" @open="handleOpen" @closed="resetForm">
    <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small">
      <el-form-item label="添加设备">
        <el-select v-model="tempDeviceId" filterable remote reserve-keyword placeholder="输入设备名称或编码搜索添加"
                   :remote-method="searchDevice" :loading="deviceLoading" style="width:100%" @change="addDevice">
          <el-option v-for="d in deviceOptions" :key="d.id" :label="`${d.device_code} - ${d.name}`" :value="d.id" />
        </el-select>
      </el-form-item>

      <el-form-item label="已选设备">
        <el-table :data="selectedDevices" size="mini" border max-height="220" style="width:100%">
          <el-table-column prop="device_code" label="设备编码" width="140" />
          <el-table-column prop="name" label="设备名称" min-width="120" />
          <el-table-column label="当前状态" width="100">
            <template slot-scope="{ row }"><el-tag :type="statusTagType(row.status)" size="mini">{{ statusLabel(row.status) }}</el-tag></template>
          </el-table-column>
          <el-table-column label="校验" width="100">
            <template slot-scope="{ row }">
              <el-tag v-if="row._allowed" type="success" size="mini">可变更</el-tag>
              <el-tag v-else-if="row._checked" type="danger" size="mini">不可变更</el-tag>
              <span v-else>-</span>
            </template>
          </el-table-column>
          <el-table-column label="" width="50" align="center">
            <template slot-scope="{ $index }"><el-button type="text" size="mini" icon="el-icon-delete" @click="selectedDevices.splice($index, 1)" /></template>
          </el-table-column>
        </el-table>
        <div v-if="!selectedDevices.length" style="color:#C0C4CC;font-size:12px;padding:8px 0">请搜索并添加设备</div>
      </el-form-item>

      <el-form-item label="目标状态" prop="to_status">
        <el-select v-model="form.to_status" placeholder="选择目标状态" style="width:100%" @change="checkAllTargets">
          <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" :disabled="s.value === 'scrapped' ? false : false" />
        </el-select>
        <div class="tip">选择目标状态后将逐台校验流转规则，不可变更的设备会标红</div>
      </el-form-item>

      <el-form-item label="变更原因" prop="reason">
        <el-input v-model="form.reason" type="textarea" :rows="2" maxlength="500" show-word-limit placeholder="统一填写变更原因" />
      </el-form-item>
      <el-form-item label="关联单据编号">
        <el-input v-model="form.related_order_no" maxlength="50" placeholder="可选" />
      </el-form-item>
    </el-form>

    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" :disabled="!selectedDevices.length" @click="submit">提交</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getAssetList } from '@/api/deviceAsset'
import { batchCreateStatusChange, getAvailableTargets } from '@/api/deviceStatusChange'

export default {
  name: 'StatusChangeBatchDialog',
  props: { visible: Boolean, statusOptions: { type: Array, default: () => [] } },
  data() {
    return {
      dialogVisible: this.visible,
      submitting: false,
      deviceLoading: false,
      deviceOptions: [],
      tempDeviceId: null,
      selectedDevices: [],
      form: { to_status: '', reason: '', related_order_no: '' },
      rules: {
        to_status: [{ required: true, message: '请选择目标状态', trigger: 'change' }],
        reason: [{ required: true, message: '请输入变更原因', trigger: 'blur' }]
      }
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val }
  },
  methods: {
    statusLabel(v) { const s = this.statusOptions.find(x => x.value === v); return s ? s.label : (v || '-') },
    statusTagType(v) { const s = this.statusOptions.find(x => x.value === v); return (s && s.style) || 'info' },
    handleOpen() {
      this.selectedDevices = []
      this.form = { to_status: '', reason: '', related_order_no: '' }
      this.tempDeviceId = null
      this.deviceOptions = []
    },
    resetForm() { this.$refs.form && this.$refs.form.clearValidate() },
    async searchDevice(query) {
      if (!query) return
      this.deviceLoading = true
      try {
        const res = await getAssetList({ keyword: query, page: 1, limit: 20 })
        if (res.code === 0) this.deviceOptions = res.data.list || []
      } catch (e) {}
      this.deviceLoading = false
    },
    async addDevice(id) {
      const d = this.deviceOptions.find(x => x.id === id)
      if (!d) { this.tempDeviceId = null; return }
      if (!this.selectedDevices.find(x => x.id === d.id)) {
        this.selectedDevices.push({ ...d, _checked: false, _allowed: false })
      }
      this.tempDeviceId = null
      this.checkAllTargets()
    },
    async checkAllTargets() {
      const toStatus = this.form.to_status
      if (!toStatus) return
      for (const dev of this.selectedDevices) {
        if (!dev.id) continue
        try {
          const res = await getAvailableTargets(dev.id)
          const targets = (res.data && res.data.targets) || []
          dev._checked = true
          dev._allowed = targets.some(t => t.value === toStatus)
        } catch (e) { dev._checked = true; dev._allowed = false }
      }
    },
    submit() {
      this.$refs.form.validate(async (valid) => {
        if (!valid) return
        const blocked = this.selectedDevices.filter(d => d._checked && !d._allowed)
        if (blocked.length) {
          this.$message.warning(`有 ${blocked.length} 台设备不可变更为目标状态，请调整后重试`)
          return
        }
        this.$confirm(`确认对 ${this.selectedDevices.length} 台设备执行批量状态变更？\n目标状态：${this.statusLabel(this.form.to_status)}`, '批量变更确认', {
          confirmButtonText: '确认变更', cancelButtonText: '取消', type: 'warning'
        }).then(async () => {
          this.submitting = true
          try {
            const res = await batchCreateStatusChange({
              asset_ids: this.selectedDevices.map(d => d.id),
              to_status: this.form.to_status, reason: this.form.reason,
              related_order_no: this.form.related_order_no
            })
            this.$message.success(res.msg || '批量变更成功')
            this.$emit('saved')
            this.dialogVisible = false
          } catch (e) { /* 拦截器已提示 */ }
          this.submitting = false
        }).catch(() => {})
      })
    }
  }
}
</script>

<style scoped>
.tip { color: #909399; font-size: 12px; }
</style>
