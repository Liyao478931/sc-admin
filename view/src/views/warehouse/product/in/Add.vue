<!--
  文件：admin/src/views/warehouse/product/in/Add.vue
  功能：新增/编辑产品入库单（上架确认，多明细 + 货位分配）
  权限：warehouse:product:in:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>设备出入库</el-breadcrumb-item>
      <el-breadcrumb-item>产品入库</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑产品入库单' : '新增产品入库单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? `编辑产品入库单 - ${form.in_no || ''}` : '新增产品入库单' }}</span>
      <div>
        <el-button size="small" @click="handleBack">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="来源类型" prop="source_type">
              <el-select v-model="form.source_type" placeholder="请选择来源类型" style="width:100%">
                <el-option v-for="(t, v) in SOURCE_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col v-if="form.source_type === 1" :span="12">
            <el-form-item label="来源单据" prop="source_id">
              <el-select v-model="form.source_id" filterable placeholder="请选择产品接收单" style="width:100%" @change="handleSourceChange">
                <el-option v-for="p in sourceOptions" :key="p.id" :label="`${p.receipt_no} - ${p.source_location || p.customer_name || ''}`" :value="p.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="入库仓库" prop="warehouse_id">
              <el-select v-model="form.warehouse_id" filterable placeholder="请选择仓库" style="width:100%" @change="handleWarehouseChange">
                <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="入库人" prop="in_user_id">
              <el-select v-model="form.in_user_id" filterable placeholder="请选择入库人" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="入库日期" prop="in_date">
              <el-date-picker v-model="form.in_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择日期" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="never" class="logs-card">
      <div slot="header" class="logs-header">
        <span>入库明细（共 {{ items.length }} 项，总数量 {{ totalQuantity }}，总金额 ¥{{ totalAmount.toFixed(2) }}）</span>
        <el-button v-if="form.source_id" size="mini" icon="el-icon-download" @click="importFromSource">从来源单据导入明细</el-button>
      </div>
      <el-table :data="items" size="small" border empty-text="请选择来源单据后导入明细">
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="product_code" label="产品编码" width="100" />
        <el-table-column prop="product_name" label="产品名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="50" align="center" />
        <el-table-column label="入库数量" width="110">
          <template slot-scope="s"><el-input-number v-model="s.row.quantity" :min="0.01" :max="s.row.remaining_quantity" :precision="4" size="mini" style="width:100%" /></template>
        </el-table-column>
        <el-table-column label="入库单价" width="120">
          <template slot-scope="s"><el-input-number v-model="s.row.unit_price" :min="0.0001" :precision="4" size="mini" style="width:100%" /></template>
        </el-table-column>
        <el-table-column label="设备编号" width="120">
          <template slot-scope="s"><el-input v-model="s.row.serial_number" size="mini" placeholder="必填" /></template>
        </el-table-column>
        <el-table-column label="存放货位" width="130">
          <template slot-scope="s">
            <el-select v-model="s.row.location_id" filterable size="mini" placeholder="货位" style="width:100%">
              <el-option v-for="l in locationOptions" :key="l.id" :label="l.location_name" :value="l.id" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="65" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="items.splice(s.$index, 1)">删除</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="never" class="logs-card">
      <el-form label-width="120px" size="small">
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" placeholder="补充说明（可选）" /></el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { getProductInDetail, saveProductIn, getReadyReceiveList, getWarehouseList, getLocationList } from '../../../../api/warehouse'
import { getUserList } from '../../../../api/user'

const SOURCE_TYPES = { 1: '产品接收单', 2: '调拨入库', 3: '盘盈入库', 4: '其他入库' }

export default {
  name: 'WarehouseProductInAdd',
  data () {
    return {
      SOURCE_TYPES,
      isEdit: false, saving: false,
      sourceOptions: [], warehouseOptions: [], locationOptions: [], userOptions: [], sourceMap: {},
      form: {
        id: 0, in_no: '', source_type: 1, source_id: 0, warehouse_id: 0, warehouse_name: '',
        in_user_id: 0, in_date: this.today(), remark: ''
      },
      items: [],
      rules: {
        source_type: [{ required: true, message: '请选择来源类型', trigger: 'change' }],
        warehouse_id: [{ required: true, message: '请选择入库仓库', trigger: 'change' }],
        in_user_id: [{ required: true, message: '请选择入库人', trigger: 'change' }],
        in_date: [{ required: true, message: '请选择入库日期', trigger: 'change' }]
      }
    }
  },
  computed: {
    totalQuantity () { return this.items.reduce((s, it) => s + (Number(it.quantity) || 0), 0) },
    totalAmount () { return this.items.reduce((s, it) => s + (Number(it.quantity) || 0) * (Number(it.unit_price) || 0), 0) }
  },
  created () {
    this.isEdit = !!this.$route.params.id
    this.loadSources(); this.loadWarehouses(); this.loadUsers()
    if (this.isEdit) this.loadDetail(Number(this.$route.params.id))
  },
  methods: {
    today () {
      const d = new Date()
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    },
    async loadSources () {
      try {
        const r = await getReadyReceiveList()
        this.sourceOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
        this.sourceOptions.forEach(p => { this.sourceMap[p.id] = p })
      } catch (e) { this.sourceOptions = [] }
    },
    async loadWarehouses () {
      try {
        const r = await getWarehouseList({ page: 1, pageSize: 100, status: 1 })
        this.warehouseOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.warehouseOptions = [] }
    },
    async loadLocations () {
      if (!this.form.warehouse_id) { this.locationOptions = []; return }
      try {
        const r = await getLocationList({ warehouse_id: this.form.warehouse_id, page: 1, pageSize: 100 })
        this.locationOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.locationOptions = [] }
    },
    async loadUsers () {
      try {
        const r = await getUserList({ page: 1, limit: 200 })
        this.userOptions = (r.data && r.data.list) || []
        if (!this.isEdit && this.userOptions.length) {
          const cur = this.userOptions.find(u => u.id === (this.$store.state.user.userInfo && this.$store.state.user.userInfo.id))
          this.form.in_user_id = cur ? cur.id : this.userOptions[0].id
        }
      } catch (e) { this.userOptions = [] }
    },
    async loadDetail (id) {
      try {
        const r = await getProductInDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            id: d.id, in_no: d.in_no, source_type: d.source_type, source_id: d.source_id,
            warehouse_id: d.warehouse_id, warehouse_name: d.warehouse_name || '',
            in_user_id: d.in_user_id, in_date: d.in_date, remark: d.remark || ''
          }
          this.items = (d.items || []).map(it => ({
            source_item_id: it.source_item_id, product_id: it.product_id, product_code: it.product_code,
            product_name: it.product_name, specification: it.specification, unit: it.unit,
            quantity: Number(it.quantity) || 0, unit_price: Number(it.unit_price) || 0,
            serial_number: it.serial_number || '', location_id: it.location_id || 0, remark: it.remark || '', remaining_quantity: 999999
          }))
          this.loadLocations()
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    handleWarehouseChange () {
      this.form.warehouse_name = (this.warehouseOptions.find(w => w.id === this.form.warehouse_id) || {}).warehouse_name || ''
      this.loadLocations()
    },
    handleSourceChange (sid) {
      const s = this.sourceMap[sid]
      if (!s) return
      if (!this.form.warehouse_id && s.warehouse_name) {
        const w = this.warehouseOptions.find(x => x.warehouse_name === s.warehouse_name)
        if (w) { this.form.warehouse_id = w.id; this.loadLocations() }
      }
      this.importItems(s)
    },
    importFromSource () {
      const s = this.sourceMap[this.form.source_id]
      if (!s) return
      if (this.items.length) {
        this.$confirm('导入将覆盖当前明细列表，是否继续？', '提示', { type: 'warning' }).then(() => this.importItems(s)).catch(() => {})
      } else this.importItems(s)
    },
    importItems (s) {
      this.items = (s.items || []).filter(it => it.remaining_quantity > 0).map(it => ({
        source_item_id: it.receive_item_id, product_id: it.product_id, product_code: it.product_code,
        product_name: it.product_name, specification: it.spec, unit: it.unit,
        quantity: it.remaining_quantity, unit_price: 0, serial_number: it.device_no || '',
        location_id: 0, remark: it.remark || '', remaining_quantity: it.remaining_quantity
      }))
    },
    handleBack () {
      if (this.items.length) {
        this.$confirm('当前有未保存的内容，确认离开吗？', '提示', { type: 'warning' }).then(() => {
          this.$router.push({ path: '/warehouse/product/in/list' })
        }).catch(() => {})
        return
      }
      this.$router.push({ path: '/warehouse/product/in/list' })
    },
    handleSave () {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (this.form.source_type === 1 && !this.form.source_id) { this.$message.warning('请选择来源产品接收单'); return }
        if (!this.items.length) { this.$message.warning('请至少添加一条入库明细'); return }
        const invalid = this.items.find(it => !it.quantity || it.quantity <= 0 || !it.unit_price || it.unit_price <= 0 || !it.serial_number || !it.location_id)
        if (invalid) { this.$message.warning('请完善明细：数量/单价大于 0、设备编号与货位必填'); return }
        this.saving = true
        try {
          const r = await saveProductIn({ ...this.form, items: this.items })
          if (r.code === 0) {
            this.$message.success(r.msg || '保存成功')
            this.$router.push({ path: '/warehouse/product/in/list' })
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
.logs-card { margin-bottom: 16px; }
.logs-header { display: flex; justify-content: space-between; align-items: center; }
.danger { color: #F56C6C; }
</style>
