<template>
  <el-dialog :title="mode === 'add' ? '新增设备' : '编辑设备'" :visible.sync="dialogVisible" width="900px" top="5vh" @open="handleOpen" @closed="handleClosed">
    <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
      <!-- 基础信息 -->
      <el-divider content-position="left">基础信息</el-divider>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="设备编码" prop="device_code">
            <div style="display:flex;gap:6px">
              <el-input v-model="form.device_code" maxlength="50" placeholder="留空自动生成" />
              <el-button size="mini" type="text" icon="el-icon-magic-stick" :loading="codeLoading" @click="autoCode">自动生成</el-button>
            </div>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="设备名称" prop="name">
            <el-input v-model="form.name" maxlength="100" placeholder="请输入设备名称" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="设备类型" prop="device_type">
            <el-select v-model="form.device_type" placeholder="请选择" style="width:100%" @change="onTypeChange">
              <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="所属分类" prop="category_id">
            <el-cascader v-model="form.category_id" :options="categories" :props="cascaderProps"
                         placeholder="选择叶子节点分类" clearable filterable style="width:100%" @change="onCategoryChange" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="型号"><el-input v-model="form.model" maxlength="50" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="规格参数"><el-input v-model="form.specification" maxlength="255" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="品牌"><el-input v-model="form.brand" maxlength="50" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="生产厂家"><el-input v-model="form.manufacturer" maxlength="100" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="供应商">
            <el-select v-model="form.supplier_id" clearable filterable placeholder="选择供应商" style="width:100%">
              <el-option v-for="s in supplierList" :key="s.id" :label="s.name" :value="s.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="采购日期"><el-date-picker v-model="form.purchase_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="采购价格"><el-input-number v-model="form.purchase_price" :min="0" :precision="2" style="width:100%" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="投入使用日期"><el-date-picker v-model="form.put_into_use_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="使用部门">
            <el-select v-model="form.department_id" clearable filterable placeholder="选择部门" style="width:100%">
              <el-option v-for="d in departmentList" :key="d.id" :label="d.name" :value="d.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="存放位置"><el-input v-model="form.location" maxlength="100" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="负责人">
            <el-select v-model="form.manager_id" clearable filterable placeholder="选择负责人" style="width:100%">
              <el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="状态">
            <el-select v-model="form.status" style="width:100%">
              <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="设备图片">
            <div class="asset-uploader-wrap">
              <el-upload class="asset-uploader" action="/api/upload" :headers="uploadHeaders" :show-file-list="false" :on-success="onImageSuccess">
                <img v-if="form.image" :src="form.image" class="asset-img" />
                <i v-else class="el-icon-plus asset-uploader-icon"></i>
              </el-upload>
              <div v-if="form.image" class="asset-img-del" title="删除图片" @click.stop="removeImage">×</div>
            </div>
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="3" /></el-form-item>
        </el-col>
      </el-row>

      <!-- 普通设备扩展 -->
      <template v-if="form.device_type === 'general'">
        <el-divider content-position="left">普通设备扩展</el-divider>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="额定功率"><el-input v-model="ext.general.power_rating" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="电压等级"><el-input v-model="ext.general.voltage" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="重量(kg)"><el-input-number v-model="ext.general.weight" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="外形尺寸"><el-input v-model="ext.general.dimensions" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="保修截止日期"><el-date-picker v-model="ext.general.warranty_expire_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="校准周期(月)"><el-input-number v-model="ext.general.calibration_cycle" :min="0" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="上次校准日期"><el-date-picker v-model="ext.general.last_calibration_date" type="date" value-format="yyyy-MM-dd" style="width:100%" @change="calcGeneralCalibration" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="下次校准日期"><el-date-picker v-model="ext.general.next_calibration_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
        </el-row>
      </template>

      <!-- 特种设备扩展 -->
      <template v-if="form.device_type === 'special'">
        <el-divider content-position="left">特种设备扩展</el-divider>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="特种设备类型">
              <el-select v-model="ext.special.special_type" clearable style="width:100%">
                <el-option v-for="s in specialTypeOptions" :key="s.value" :label="s.label" :value="s.value" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="使用登记证编号"><el-input v-model="ext.special.registration_code" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="登记机关"><el-input v-model="ext.special.registration_authority" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="检验周期(月)"><el-input-number v-model="ext.special.inspection_cycle" :min="0" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="上次检验日期"><el-date-picker v-model="ext.special.last_inspection_date" type="date" value-format="yyyy-MM-dd" style="width:100%" @change="calcSpecialInspection" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="下次检验日期"><el-date-picker v-model="ext.special.next_inspection_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="最近检验结果">
              <el-select v-model="ext.special.inspection_result" clearable style="width:100%">
                <el-option label="合格" value="合格" /><el-option label="不合格" value="不合格" /><el-option label="整改" value="整改" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="是否需要操作证"><el-switch v-model="ext.special.operator_cert_required" :active-value="1" :inactive-value="0" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="操作证编号"><el-input v-model="ext.special.operator_cert_number" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="持证操作人员">
              <el-select v-model="ext.special.operator_ids" multiple filterable style="width:100%">
                <el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="设计单位"><el-input v-model="ext.special.design_unit" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="安装单位"><el-input v-model="ext.special.install_unit" /></el-form-item></el-col>
        </el-row>
      </template>

      <!-- 车辆扩展 -->
      <template v-if="form.device_type === 'car' || form.device_type === 'truck'">
        <el-divider content-position="left">车辆扩展</el-divider>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="车牌号"><el-input v-model="ext.vehicle.license_plate" maxlength="10" @input="v => (ext.vehicle.license_plate = (v || '').toUpperCase())" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="车架号"><el-input v-model="ext.vehicle.vin" maxlength="17" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="发动机号"><el-input v-model="ext.vehicle.engine_no" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="排量(L)"><el-input-number v-model="ext.vehicle.displacement" :min="0" :precision="1" :step="0.1" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="燃料类型">
              <el-select v-model="ext.vehicle.fuel_type" clearable style="width:100%">
                <el-option v-for="f in fuelTypeOptions" :key="f.value" :label="f.label" :value="f.value" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item v-if="form.device_type === 'truck'" label="核定载重(kg)"><el-input-number v-model="ext.vehicle.load_capacity" :min="0" :precision="2" style="width:100%" /></el-form-item>
            <el-form-item v-else label="核定载客数"><el-input-number v-model="ext.vehicle.seat_count" :min="0" style="width:100%" /></el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="当前里程(km)"><el-input-number v-model="ext.vehicle.mileage" :min="0" :precision="1" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="保险到期日"><el-date-picker v-model="ext.vehicle.insurance_expire_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="年检到期日"><el-date-picker v-model="ext.vehicle.inspection_expire_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="下次保养里程(km)"><el-input-number v-model="ext.vehicle.next_maintenance_mileage" :min="0" :precision="1" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="上次保养日期"><el-date-picker v-model="ext.vehicle.last_maintenance_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
        </el-row>
      </template>
    </el-form>

    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" @click="submit">确认提交</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addAsset, editAsset, suggestAssetCode } from '@/api/deviceAsset'
import { getToken } from '@/utils/auth'

export default {
  name: 'AssetFormDialog',
  props: {
    visible: Boolean,
    mode: { type: String, default: 'add' }, // add / edit
    assetId: { type: Number, default: 0 },
    categories: { type: Array, default: () => [] },
    typeOptions: { type: Array, default: () => [] },
    statusOptions: { type: Array, default: () => [] },
    specialTypeOptions: { type: Array, default: () => [] },
    fuelTypeOptions: { type: Array, default: () => [] },
    supplierList: { type: Array, default: () => [] },
    managerList: { type: Array, default: () => [] },
    departmentList: { type: Array, default: () => [] }
  },
  data() {
    return {
      dialogVisible: this.visible,
      submitting: false,
      codeLoading: false,
      cascaderProps: { checkStrictly: true, emitPath: false, value: 'id', label: 'name', children: 'children' },
      form: this.emptyForm(),
      ext: this.emptyExt(),
      rules: {
        name: [{ required: true, message: '请输入设备名称', trigger: 'blur' }],
        device_type: [{ required: true, message: '请选择设备类型', trigger: 'change' }],
        category_id: [{ required: true, message: '请选择所属分类', trigger: 'change' }]
      }
    }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } }
  },
  watch: {
    visible(val) { this.dialogVisible = val },
    dialogVisible(val) { this.$emit('update:visible', val) }
  },
  methods: {
    emptyForm() {
      return {
        device_code: '', name: '', device_type: 'general', category_id: '',
        model: '', specification: '', brand: '', manufacturer: '', supplier_id: null,
        purchase_date: null, purchase_price: null, put_into_use_date: null, department_id: null,
        location: '', manager_id: null, status: 'in_use', image: '', remark: ''
      }
    },
    emptyExt() {
      return {
        general: { power_rating: '', voltage: '', weight: null, dimensions: '', warranty_expire_date: null, calibration_cycle: null, last_calibration_date: null, next_calibration_date: null },
        special: { special_type: '', registration_code: '', registration_authority: '', inspection_cycle: null, last_inspection_date: null, next_inspection_date: null, inspection_result: '', operator_cert_required: 0, operator_cert_number: '', operator_ids: [], design_unit: '', install_unit: '' },
        vehicle: { license_plate: '', vin: '', engine_no: '', displacement: null, fuel_type: '', load_capacity: null, seat_count: null, mileage: 0, insurance_expire_date: null, inspection_expire_date: null, next_maintenance_mileage: null, last_maintenance_date: null }
      }
    },
    async handleOpen() {
      this.form = this.emptyForm()
      this.ext = this.emptyExt()
      this.codeLoading = true
      try {
        const res = await suggestAssetCode()
        if (res.code === 0 && res.data) this.form.device_code = res.data.device_code
      } catch (e) { /* 忽略 */ }
      this.codeLoading = false
      if (this.mode === 'edit' && this.assetId) {
        await this.loadDetail(this.assetId)
      }
    },
    handleClosed() {
      this.$refs.form && this.$refs.form.clearValidate()
    },
    async loadDetail(id) {
      const { getAssetDetail } = await import('@/api/deviceAsset')
      try {
        const res = await getAssetDetail(id)
        if (res.code !== 0) return
        const d = res.data
        this.form = {
          device_code: d.device_code, name: d.name, device_type: d.device_type, category_id: d.category_id,
          model: d.model || '', specification: d.specification || '', brand: d.brand || '', manufacturer: d.manufacturer || '',
          supplier_id: d.supplier_id || null, purchase_date: d.purchase_date || null, purchase_price: d.purchase_price === null ? null : Number(d.purchase_price),
          put_into_use_date: d.put_into_use_date || null, department_id: d.department_id || null, location: d.location || '',
          manager_id: d.manager_id || null, status: d.status || 'in_use', image: d.image || '', remark: d.remark || ''
        }
        const ext = d.ext || {}
        Object.keys(this.ext.general).forEach(k => { if (ext[k] !== undefined) this.ext.general[k] = ext[k] })
        Object.keys(this.ext.special).forEach(k => { if (ext[k] !== undefined) this.ext.special[k] = ext[k] })
        Object.keys(this.ext.vehicle).forEach(k => { if (ext[k] !== undefined) this.ext.vehicle[k] = ext[k] })
        if (this.ext.special.operator_ids && typeof this.ext.special.operator_ids === 'string') {
          this.ext.special.operator_ids = this.ext.special.operator_ids ? String(this.ext.special.operator_ids).split(',').map(Number) : []
        }
      } catch (e) { /* 拦截器已提示 */ }
    },
    async autoCode() {
      this.codeLoading = true
      try {
        const res = await suggestAssetCode()
        if (res.code === 0 && res.data) this.form.device_code = res.data.device_code
      } catch (e) { /* 忽略 */ }
      this.codeLoading = false
    },
    onTypeChange() {
      this.ext = this.emptyExt()
    },
    onCategoryChange(val) {
      if (!val) return
      const findNode = (nodes, id) => {
        for (const n of nodes || []) {
          if (n.id === id) return n
          const r = findNode(n.children, id)
          if (r) return r
        }
        return null
      }
      const node = findNode(this.categories, val)
      if (node && node.children && node.children.length) {
        this.$message.warning('请选择叶子节点分类')
        this.form.category_id = ''
      }
    },
    calcGeneralCalibration() {
      if (this.ext.general.last_calibration_date && this.ext.general.calibration_cycle) {
        const d = new Date(this.ext.general.last_calibration_date)
        d.setMonth(d.getMonth() + Number(this.ext.general.calibration_cycle))
        const y = d.getFullYear(); const m = String(d.getMonth() + 1).padStart(2, '0'); const day = String(d.getDate()).padStart(2, '0')
        this.ext.general.next_calibration_date = `${y}-${m}-${day}`
      }
    },
    calcSpecialInspection() {
      if (this.ext.special.last_inspection_date && this.ext.special.inspection_cycle) {
        const d = new Date(this.ext.special.last_inspection_date)
        d.setMonth(d.getMonth() + Number(this.ext.special.inspection_cycle))
        const y = d.getFullYear(); const m = String(d.getMonth() + 1).padStart(2, '0'); const day = String(d.getDate()).padStart(2, '0')
        this.ext.special.next_inspection_date = `${y}-${m}-${day}`
      }
    },
    onImageSuccess(res, file) {
      if (res.code === 0 && res.data && res.data.url) this.form.image = res.data.url
      else this.$message.error('图片上传失败')
    },
    removeImage() {
      this.form.image = ''
    },
    buildPayload() {
      const t = this.form.device_type
      const payload = {
        device_code: this.form.device_code, name: this.form.name, device_type: t, category_id: this.form.category_id,
        model: this.form.model, specification: this.form.specification, brand: this.form.brand, manufacturer: this.form.manufacturer,
        supplier_id: this.form.supplier_id || '', purchase_date: this.form.purchase_date || '', purchase_price: this.form.purchase_price === null ? '' : this.form.purchase_price,
        put_into_use_date: this.form.put_into_use_date || '', department_id: this.form.department_id || '', location: this.form.location,
        manager_id: this.form.manager_id || '', status: this.form.status, image: this.form.image, remark: this.form.remark
      }
      if (t === 'general') Object.assign(payload, this.ext.general)
      if (t === 'special') Object.assign(payload, { ...this.ext.special, operator_ids: (this.ext.special.operator_ids || []).join(',') })
      if (t === 'car' || t === 'truck') Object.assign(payload, this.ext.vehicle)
      return payload
    },
    submit() {
      this.$refs.form.validate(async (valid) => {
        if (!valid) return
        this.submitting = true
        try {
          const payload = this.buildPayload()
          if (this.mode === 'add') {
            await addAsset(payload)
            this.$message.success('创建成功')
          } else {
            await editAsset(this.assetId, payload)
            this.$message.success('更新成功')
          }
          this.$emit('saved')
          this.dialogVisible = false
        } catch (e) { /* 拦截器已提示 */ }
        this.submitting = false
      })
    }
  }
}
</script>

<style scoped>
.asset-uploader-wrap { position: relative; width: 100px; height: 100px; }
.asset-uploader { border: 1px dashed #d9d9d9; border-radius: 6px; cursor: pointer; width: 100px; height: 100px; display: flex; align-items: center; justify-content: center; overflow: hidden; }
.asset-img-del { position: absolute; top: -8px; right: -8px; width: 20px; height: 20px; border-radius: 50%; background: rgba(0,0,0,.6); color: #fff; font-size: 14px; line-height: 20px; text-align: center; cursor: pointer; z-index: 2; }
.asset-img-del:hover { background: #F56C6C; }
.asset-uploader-icon { font-size: 28px; color: #8c939d; }
.asset-img { width: 100%; height: 100%; object-fit: cover; }
</style>
