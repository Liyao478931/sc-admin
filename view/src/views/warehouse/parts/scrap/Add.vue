<!--
  文件：admin/src/views/warehouse/parts/scrap/Add.vue
  功能：新增/编辑报废单（单物料，从物料选择带出库存/单价）
  权限：warehouse:scrap:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>报废出库</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑报废单' : '新增报废单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? `编辑报废单 - ${form.scrap_no || ''}` : '新增报废单' }}</span>
      <div>
        <el-button size="small" @click="handleBack">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="关联领料单">
              <el-select v-model="form.pick_id" clearable filterable placeholder="可选，追溯报废物料来源" style="width:100%">
                <el-option v-for="p in pickOptions" :key="p.id" :label="p.pick_no" :value="p.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="物料选择" prop="material_id">
              <el-select v-model="form.material_id" filterable remote :remote-method="searchMaterials" :loading="matLoading" placeholder="搜索选择物料" style="width:100%" @change="handleMaterialChange">
                <el-option v-for="m in materialOptions" :key="m.id" :label="`${m.material_code} ${m.material_name}`" :value="m.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="物料信息">
              <el-input :value="materialInfo" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="报废类型" prop="scrap_type">
              <el-select v-model="form.scrap_type" placeholder="请选择报废类型" style="width:100%">
                <el-option v-for="(t, v) in SCRAP_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="报废部门" prop="department_id">
              <el-select v-model="form.department_id" filterable placeholder="请选择部门" style="width:100%" @change="handleDepartmentChange">
                <el-option v-for="d in departmentOptions" :key="d.id" :label="d.name" :value="d.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="报废申请人" prop="applicant_id">
              <el-select v-model="form.applicant_id" filterable placeholder="请选择申请人" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="报废日期" prop="scrap_date">
              <el-date-picker v-model="form.scrap_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择日期" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="报废数量" prop="scrap_quantity">
              <el-input-number v-model="form.scrap_quantity" :min="0.01" :precision="4" :max="currentStock || undefined" style="width:180px" />
              <span class="unit">当前库存：{{ currentStock }}</span>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="报废单价">
              <el-input :value="'¥ ' + Number(form.scrap_price).toFixed(4)" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="报废总价">
              <el-input :value="'¥ ' + totalPrice.toFixed(2)" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="处理方式" prop="disposal_type">
              <el-select v-model="form.disposal_type" placeholder="请选择处理方式" style="width:100%">
                <el-option v-for="(t, v) in DISPOSAL_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="报废原因" prop="scrap_reason">
              <el-input v-model="form.scrap_reason" type="textarea" :rows="3" placeholder="请详细描述报废原因" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="请输入补充说明" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { getScrapDetail, saveScrap, getPickList, getMaterialList } from '../../../../api/warehouse'
import { getUserList } from '../../../../api/user'
import { getDepartmentList } from '../../../../api/organization'

const SCRAP_TYPES = { 1: '质量报废', 2: '过期报废', 3: '技术淘汰', 4: '事故损坏', 5: '其他报废' }
const DISPOSAL_TYPES = { 1: '销毁', 2: '退回供应商', 3: '废品回收', 4: '其他' }

export default {
  name: 'WarehouseScrapAdd',
  data () {
    return {
      SCRAP_TYPES, DISPOSAL_TYPES,
      isEdit: false, saving: false, matLoading: false,
      pickOptions: [], materialOptions: [], departmentOptions: [], userOptions: [],
      materialMap: {}, currentStock: 0,
      form: {
        id: 0, scrap_no: '', pick_id: 0, scrap_type: 1, material_id: 0,
        department_id: 0, department_name: '', applicant_id: 0,
        scrap_date: this.today(), scrap_quantity: 1, scrap_price: 0,
        disposal_type: 1, scrap_reason: '', remark: ''
      },
      rules: {
        material_id: [{ required: true, message: '请选择物料', trigger: 'change' }],
        scrap_type: [{ required: true, message: '请选择报废类型', trigger: 'change' }],
        department_id: [{ required: true, message: '请选择部门', trigger: 'change' }],
        applicant_id: [{ required: true, message: '请选择申请人', trigger: 'change' }],
        scrap_date: [{ required: true, message: '请选择日期', trigger: 'change' }],
        scrap_quantity: [{ required: true, message: '请输入报废数量', trigger: 'change' }],
        disposal_type: [{ required: true, message: '请选择处理方式', trigger: 'change' }],
        scrap_reason: [{ required: true, message: '请填写报废原因', trigger: 'blur' }]
      }
    }
  },
  computed: {
    materialInfo () {
      const m = this.materialMap[this.form.material_id]
      return m ? `${m.material_code} ${m.material_name}${m.spec ? ' / ' + m.spec : ''}（${m.unit || '-'}）` : ''
    },
    totalPrice () {
      return (Number(this.form.scrap_quantity) || 0) * (Number(this.form.scrap_price) || 0)
    }
  },
  created () {
    this.isEdit = !!this.$route.params.id
    this.loadPicks(); this.loadDepartments(); this.loadUsers()
    if (this.isEdit) this.loadDetail(Number(this.$route.params.id))
  },
  methods: {
    today () {
      const d = new Date()
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    },
    async loadPicks () {
      try {
        const r = await getPickList({ page: 1, pageSize: 100, status: 3 })
        this.pickOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.pickOptions = [] }
    },
    async loadDepartments () {
      try {
        const r = await getDepartmentList()
        this.departmentOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.departmentOptions = [] }
    },
    async loadUsers () {
      try {
        const r = await getUserList({ page: 1, limit: 200 })
        this.userOptions = (r.data && r.data.list) || []
        if (!this.isEdit && this.userOptions.length) {
          const cur = this.userOptions.find(u => u.id === (this.$store.state.user.userInfo && this.$store.state.user.userInfo.id))
          this.form.applicant_id = cur ? cur.id : this.userOptions[0].id
        }
      } catch (e) { this.userOptions = [] }
    },
    async loadDetail (id) {
      try {
        const r = await getScrapDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            id: d.id, scrap_no: d.scrap_no, pick_id: d.pick_id, scrap_type: d.scrap_type,
            material_id: d.material_id, department_id: d.department_id, department_name: d.department_name || '',
            applicant_id: d.applicant_id, scrap_date: d.scrap_date, scrap_quantity: Number(d.scrap_quantity),
            scrap_price: Number(d.scrap_price), disposal_type: d.disposal_type,
            scrap_reason: d.scrap_reason || '', remark: d.remark || ''
          }
          this.currentStock = Number(d.current_stock) || 0
          this.materialMap[d.material_id] = { id: d.material_id, material_code: d.material_code, material_name: d.material_name, spec: d.spec, unit: d.unit, avg_cost_price: d.scrap_price }
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    async searchMaterials (kw) {
      this.matLoading = true
      try {
        const r = await getMaterialList({ page: 1, pageSize: 50, status: 1, material_name: kw || '' })
        this.materialOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
        this.materialOptions.forEach(m => { this.materialMap[m.id] = m })
      } catch (e) {} finally { this.matLoading = false }
    },
    handleDepartmentChange (did) {
      const d = this.departmentOptions.find(x => x.id === did)
      this.form.department_name = d ? d.name : ''
    },
    handleMaterialChange (mid) {
      const m = this.materialMap[mid]
      if (!m) return
      this.currentStock = Number(m.current_stock) || 0
      this.form.scrap_price = Number(m.avg_cost_price) || 0
    },
    handleBack () {
      if (this.form.scrap_reason || this.form.material_id) {
        this.$confirm('当前有未保存的内容，确认离开吗？', '提示', { type: 'warning' }).then(() => {
          this.$router.push({ path: '/warehouse/parts/scrap/list' })
        }).catch(() => {})
        return
      }
      this.$router.push({ path: '/warehouse/parts/scrap/list' })
    },
    handleSave () {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (!this.form.scrap_quantity || this.form.scrap_quantity <= 0) { this.$message.warning('报废数量必须大于 0'); return }
        if (this.currentStock > 0 && this.form.scrap_quantity > this.currentStock) {
          this.$message.warning(`库存不足，当前库存为 ${this.currentStock}，报废数量为 ${this.form.scrap_quantity}`)
          return
        }
        this.saving = true
        try {
          const r = await saveScrap({ ...this.form, scrap_total: this.totalPrice })
          if (r.code === 0) {
            this.$message.success(r.msg || '保存成功')
            this.$router.push({ path: '/warehouse/parts/scrap/list' })
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
.unit { margin-left: 8px; color: #909399; font-size: 12px; }
</style>
