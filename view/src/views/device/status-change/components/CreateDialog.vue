<template>
  <el-dialog title="发起状态变更" :visible.sync="dialogVisible" width="600px" @open="handleOpen" @closed="resetForm">
    <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small">
      <el-form-item label="选择设备" prop="asset_id">
        <el-select v-model="form.asset_id" filterable remote reserve-keyword placeholder="输入设备名称或编码搜索"
                   :remote-method="searchDevice" :loading="deviceLoading" style="width:100%" @change="onDeviceChange">
          <el-option v-for="d in deviceOptions" :key="d.id" :label="`${d.device_code} - ${d.name}`" :value="d.id">
            <span>{{ d.device_code }} - {{ d.name }}</span>
            <span style="float:right;color:#909399;font-size:12px">{{ statusLabel(d.status) }}</span>
          </el-option>
        </el-select>
      </el-form-item>

      <el-form-item label="当前状态">
        <el-tag :type="currentStatusTag" size="small">{{ currentStatusLabel }}</el-tag>
        <span class="dev-info" v-if="selectedDevice">　{{ selectedDevice.device_type === 'special' ? '特种' : typeLabel(selectedDevice.device_type) }} / {{ selectedDevice.department_name || '未分配部门' }} / {{ selectedDevice.manager_name || '无负责人' }}</span>
      </el-form-item>

      <el-form-item label="目标状态" prop="to_status">
        <el-select v-model="form.to_status" placeholder="选择目标状态" style="width:100%">
          <el-option v-for="t in targets" :key="t.value" :label="statusLabel(t.value) + (t.require_order ? '（需关联单据）' : '')" :value="t.value" />
        </el-select>
        <div class="tip" v-if="!targets.length">当前状态不可变更为其他状态</div>
      </el-form-item>

      <el-form-item label="变更原因" prop="reason">
        <el-input v-model="form.reason" type="textarea" :rows="3" maxlength="500" show-word-limit placeholder="请输入变更原因" />
        <div class="preset-box" v-if="presetReasons.length">
          <span class="preset-title">常用原因：</span>
          <el-tag v-for="(r, i) in presetReasons" :key="i" size="mini" class="preset-tag" @click="form.reason = r">{{ r }}</el-tag>
        </div>
      </el-form-item>

      <el-form-item label="关联单据类型">
        <el-select v-model="form.related_order_type" clearable placeholder="可选" style="width:100%">
          <el-option v-for="t in orderTypeOptions" :key="t.value" :label="t.label" :value="t.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="关联单据编号">
        <el-input v-model="form.related_order_no" maxlength="50" placeholder="如维修单号、调拨单号（可选/按规则必填）" />
      </el-form-item>
    </el-form>

    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" :disabled="!targets.length" @click="submit">提交</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getAssetList } from '@/api/deviceAsset'
import { createStatusChange, getAvailableTargets, getPresetReasons } from '@/api/deviceStatusChange'
import { getDictionaryBatch } from '@/utils/dict'

export default {
  name: 'StatusChangeCreateDialog',
  props: { visible: Boolean, statusOptions: { type: Array, default: () => [] } },
  data() {
    return {
      dialogVisible: this.visible,
      submitting: false,
      deviceLoading: false,
      deviceOptions: [],
      selectedDevice: null,
      targets: [],
      presetReasons: [],
      orderTypeOptions: [],
      form: { asset_id: null, to_status: '', reason: '', related_order_type: '', related_order_no: '' },
      rules: {
        asset_id: [{ required: true, message: '请选择设备', trigger: 'change' }],
        to_status: [{ required: true, message: '请选择目标状态', trigger: 'change' }],
        reason: [{ required: true, message: '请输入变更原因', trigger: 'blur' }]
      }
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val }
  },
  computed: {
    currentStatusLabel() {
      const s = this.statusOptions.find(x => x.value === (this.selectedDevice && this.selectedDevice.status))
      return this.selectedDevice ? (s ? s.label : this.selectedDevice.status) : '-'
    },
    currentStatusTag() {
      const s = this.statusOptions.find(x => x.value === (this.selectedDevice && this.selectedDevice.status))
      return (s && s.style) || 'info'
    },
    typeLabel() {
      return (v) => ({ general: '普通设备', special: '特种设备', car: '轿车', truck: '货车' }[v] || v || '-')
    }
  },
  methods: {
    statusLabel(v) { const s = this.statusOptions.find(x => x.value === v); return s ? s.label : (v || '-') },
    async handleOpen() {
      this.form = { asset_id: null, to_status: '', reason: '', related_order_type: '', related_order_no: '' }
      this.selectedDevice = null
      this.targets = []
      this.deviceOptions = []
      try {
        const res = await getPresetReasons()
        if (res.code === 0) this.presetReasons = res.data || []
        const dict = await getDictionaryBatch(['order_type'])
        this.orderTypeOptions = dict['order_type'] || []
      } catch (e) {}
    },
    resetForm() {
      this.$refs.form && this.$refs.form.clearValidate()
    },
    async searchDevice(query) {
      if (!query) return
      this.deviceLoading = true
      try {
        const res = await getAssetList({ keyword: query, page: 1, limit: 20 })
        if (res.code === 0) this.deviceOptions = res.data.list || []
      } catch (e) {}
      this.deviceLoading = false
    },
    async onDeviceChange(id) {
      const d = this.deviceOptions.find(x => x.id === id)
      this.selectedDevice = d || null
      this.form.to_status = ''
      this.targets = []
      if (d) {
        try {
          const res = await getAvailableTargets(d.id)
          if (res.code === 0) this.targets = res.data.targets || []
        } catch (e) {}
      }
    },
    submit() {
      this.$refs.form.validate(async (valid) => {
        if (!valid) return
        this.$confirm(`确认变更设备 [${this.selectedDevice.name}] 状态？\n当前：${this.currentStatusLabel} → 目标：${this.statusLabel(this.form.to_status)}\n原因：${this.form.reason}`, '变更确认', {
          confirmButtonText: '确认变更', cancelButtonText: '取消', type: 'warning'
        }).then(async () => {
          this.submitting = true
          try {
            await createStatusChange({ ...this.form, from_status: this.selectedDevice.status })
            this.$message.success('状态变更成功')
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
.dev-info { color: #909399; font-size: 12px; }
.preset-box { margin-top: 6px; line-height: 2; }
.preset-title { color: #909399; font-size: 12px; }
.preset-tag { margin-right: 6px; cursor: pointer; }
</style>
