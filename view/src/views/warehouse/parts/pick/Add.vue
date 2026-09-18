<!--
  文件：admin/src/views/warehouse/parts/pick/Add.vue
  功能：新增/编辑领料单（工单带明细/库存校验）
  权限：warehouse:pick:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>配件领用</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑领料单' : '新增领料单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑领料单 - ' + form.pick_no : '新增领料单' }}</span>
      <div>
        <el-button type="primary" size="small" :loading="saving" @click="handleSave">保存</el-button>
        <el-button size="small" @click="handleCancel">取消</el-button>
      </div>
    </div>

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>领料单信息</span></div>
      <el-form :model="form" label-width="120px" size="small" class="pick-form">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="领料类型" required>
              <el-select v-model="form.pick_type" style="width:100%" @change="onTypeChange">
                <el-option v-for="(t, v) in PICK_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item v-if="form.pick_type === 1" label="生产工单" required>
              <el-select v-model="form.production_order_id" filterable remote :remote-method="kw => searchOrders(kw)" :loading="woLoading" clearable placeholder="搜索生产工单" style="width:100%" @change="onOrderChange">
                <el-option v-for="o in workOrders" :key="o.id" :label="o.label" :value="o.id" />
              </el-select>
            </el-form-item>
            <el-form-item v-if="form.pick_type === 2" label="维修工单" required>
              <el-select v-model="form.repair_order_id" filterable remote :remote-method="kw => searchOrders(kw)" :loading="woLoading" clearable placeholder="搜索维修工单" style="width:100%" @change="onOrderChange">
                <el-option v-for="o in workOrders" :key="o.id" :label="o.label" :value="o.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="领料部门" required>
              <el-select v-model="form.department_id" filterable style="width:100%">
                <el-option v-for="d in deptOptions" :key="d.id" :label="d.label" :value="d.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="领料人" required>
              <el-select v-model="form.picker_id" filterable style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="领料日期" required>
              <el-date-picker v-model="form.pick_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="用途说明" required>
              <el-input v-model="form.purpose" type="textarea" :rows="2" placeholder="请描述领料用途" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head">
        <span>领料明细</span>
        <el-button v-if="form.production_order_id || form.repair_order_id" size="mini" type="primary" plain icon="el-icon-download" @click="importFromOrder">从工单导入明细</el-button>
        <el-button size="mini" icon="el-icon-plus" @click="pickVisible = true">添加物料</el-button>
      </div>
      <el-table :data="items" size="small" border empty-text="请选择工单导入或手动添加物料">
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="material_code" label="物料编码" width="110" />
        <el-table-column prop="material_name" label="物料名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="spec" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="55" align="center" />
        <el-table-column label="当前库存" width="90" align="right"><template slot-scope="s">{{ Number(s.row.current_stock || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="申请数量" width="120" align="right">
          <template slot-scope="s"><el-input-number v-model="s.row.apply_quantity" :min="1" size="small" style="width:100%" /></template>
        </el-table-column>
        <el-table-column label="实际领料数量" width="130" align="right">
          <template slot-scope="s"><el-input-number v-model="s.row.actual_quantity" :min="0" :max="Number(s.row.apply_quantity)" size="small" style="width:100%" /></template>
        </el-table-column>
        <el-table-column label="备注" width="110"><template slot-scope="s"><el-input v-model="s.row.remark" size="small" /></template></el-table-column>
        <el-table-column label="操作" width="55" align="center" fixed="right">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="items.splice(s.$index, 1)">删除</el-button></template>
        </el-table-column>
      </el-table>
      <div class="summary" v-if="items.length">申请总数量 <b>{{ totalQty }}</b>，物料种类 <b>{{ items.length }}</b> 种</div>
    </el-card>

    <el-card shadow="never" class="info-card">
      <el-form label-width="120px" size="small">
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" placeholder="整体备注（可选）" /></el-form-item>
      </el-form>
    </el-card>

    <!-- 选择物料 -->
    <el-dialog title="选择物料" :visible="pickVisible" @update:visible="v => pickVisible = v" width="620px" top="6vh">
      <el-select v-model="pickMaterialId" filterable placeholder="搜索物料" style="width:100%" @change="onPickMaterial">
        <el-option v-for="m in materialOptions" :key="m.id" :label="m.material_code + ' ' + m.material_name + '（库存 ' + Number(m.current_stock || 0) + '）'" :value="m.id" />
      </el-select>
      <div v-if="pickedMaterial" class="pick-qty">
        申请数量：<el-input-number v-model="pickQty" :min="1" style="width:140px" />
      </div>
      <span slot="footer">
        <el-button size="small" @click="pickVisible = false">取消</el-button>
        <el-button size="small" type="primary" :disabled="!pickedMaterial || pickQty <= 0" @click="addPicked">添加</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getPickDetail, savePick, getPickWorkOrders, getMaterialList } from '../../../../api/warehouse'
import { getDepartmentTree, getUserList } from '../../../../api/user'

const PICK_TYPES = { 1: '生产领料', 2: '维修领料', 3: '研发领料', 4: '其他领料' }

export default {
  name: 'WarehousePickAdd',
  data () {
    return {
      PICK_TYPES,
      id: Number(this.$route.params.id) || 0,
      isEdit: false, saving: false, woLoading: false, workOrders: [],
      deptOptions: [], userOptions: [], materialOptions: [],
      form: { pick_no: '', pick_type: 1, production_order_id: null, production_order_no: '', repair_order_id: null, repair_order_no: '', department_id: null, picker_id: 0, pick_date: this.today(), purpose: '', remark: '' },
      items: [],
      pickVisible: false, pickMaterialId: null, pickedMaterial: null, pickQty: 1
    }
  },
  computed: {
    totalQty () { return this.items.reduce((s, it) => s + Number(it.apply_quantity || 0), 0) }
  },
  created () {
    this.isEdit = this.id > 0
    this.loadBase()
    if (this.isEdit) this.loadDetail()
  },
  methods: {
    today () { const d = new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0') },
    async loadBase () {
      try {
        const [d, u] = await Promise.all([getDepartmentTree(), getUserList({ page: 1, limit: 200 })])
        const flat = []
        const walk = nodes => nodes.forEach(n => { flat.push({ id: n.id, label: n.name }); if (n.children) walk(n.children) })
        if (d.code === 0 && d.data) walk(Array.isArray(d.data) ? d.data : [])
        this.deptOptions = flat
        this.userOptions = (u.data && u.data.list) || []
        const me = this.$store && this.$store.state && this.$store.state.user
        if (me && me.id) this.form.picker_id = me.id
        const r = await getMaterialList({ page: 1, pageSize: 100 })
        this.materialOptions = (r.code === 0 && r.data) ? (r.data.list || []) : []
      } catch (e) {}
    },
    async loadDetail () {
      try {
        const r = await getPickDetail(this.id)
        if (r.code === 0 && r.data) {
          const d = r.data.pick || {}
          this.form = { pick_no: d.pick_no, pick_type: d.pick_type, production_order_id: d.production_order_id || null, production_order_no: d.production_order_no || '', repair_order_id: d.repair_order_id || null, repair_order_no: d.repair_order_no || '', department_id: d.department_id, picker_id: d.picker_id, pick_date: d.pick_date || this.today(), purpose: d.purpose || '', remark: d.remark || '' }
          this.items = (r.data.items || []).map(it => ({ ...it, actual_quantity: Number(it.actual_quantity) || Number(it.apply_quantity) }))
          // 回显工单选项（使下拉正确显示已关联工单）
          const woId = this.form.pick_type === 1 ? this.form.production_order_id : this.form.repair_order_id
          if (woId) this.searchOrders('')
        }
      } catch (e) {}
    },
    onTypeChange () { this.form.production_order_id = null; this.form.repair_order_id = null; this.workOrders = []; this.items = [] },
    async searchOrders (kw) {
      this.woLoading = true
      try {
        const r = await getPickWorkOrders(this.form.pick_type, kw)
        this.workOrders = (r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.workOrders = [] } finally { this.woLoading = false }
    },
    onOrderChange (oid) {
      const o = this.workOrders.find(x => x.id === oid)
      if (!o) return
      if (this.form.pick_type === 1) this.form.production_order_no = o.order_no
      else this.form.repair_order_no = o.order_no
      if (o.items && o.items.length) this.items = o.items.map(it => ({ ...it, actual_quantity: Number(it.apply_quantity) }))
    },
    importFromOrder () {
      if (this.items.length) {
        this.$confirm('导入将覆盖当前明细列表，是否继续？', '提示').then(() => { const o = this.workOrders.find(x => x.id === (this.form.pick_type === 1 ? this.form.production_order_id : this.form.repair_order_id)); if (o && o.items) this.items = o.items.map(it => ({ ...it, actual_quantity: Number(it.apply_quantity) })) }).catch(() => {})
      } else {
        const o = this.workOrders.find(x => x.id === (this.form.pick_type === 1 ? this.form.production_order_id : this.form.repair_order_id))
        if (o && o.items) this.items = o.items.map(it => ({ ...it, actual_quantity: Number(it.apply_quantity) }))
      }
    },
    onPickMaterial (mid) { this.pickedMaterial = this.materialOptions.find(m => m.id === mid) || null; this.pickQty = 1 },
    addPicked () {
      if (!this.pickedMaterial) return
      if (Number(this.pickQty) > Number(this.pickedMaterial.current_stock || 0)) { this.$message.warning('库存不足'); return }
      this.items.push({
        material_id: this.pickedMaterial.id, material_code: this.pickedMaterial.material_code,
        material_name: this.pickedMaterial.material_name, spec: this.pickedMaterial.specification || '',
        unit: this.pickedMaterial.unit, current_stock: Number(this.pickedMaterial.current_stock || 0),
        apply_quantity: this.pickQty, actual_quantity: this.pickQty, production_item_id: 0, repair_item_id: 0, remark: ''
      })
      this.pickVisible = false
      this.pickedMaterial = null
      this.pickMaterialId = null
    },
    handleSave () {
      if (!this.form.pick_type) { this.$message.warning('请选择领料类型'); return }
      if (this.form.pick_type === 1 && !this.form.production_order_id) { this.$message.warning('请选择生产工单'); return }
      if (this.form.pick_type === 2 && !this.form.repair_order_id) { this.$message.warning('请选择维修工单'); return }
      if (!this.form.department_id) { this.$message.warning('请选择领料部门'); return }
      if (!this.form.picker_id) { this.$message.warning('请选择领料人'); return }
      if (!this.form.pick_date) { this.$message.warning('请选择领料日期'); return }
      if (!this.form.purpose.trim()) { this.$message.warning('请填写用途说明'); return }
      if (!this.items.length) { this.$message.warning('请至少添加一条领料明细'); return }
      for (const it of this.items) {
        if (Number(it.apply_quantity) <= 0) { this.$message.warning('申请数量必须大于0'); return }
        if (Number(it.apply_quantity) > Number(it.current_stock || 0)) { this.$message.warning(`物料 [${it.material_name}] 库存不足，当前库存为 ${it.current_stock}，申请数量为 ${it.apply_quantity}`); return }
      }
      this.saving = true
      try {
        savePick({
          id: this.id || null, pick_type: this.form.pick_type,
          production_order_id: this.form.pick_type === 1 ? this.form.production_order_id : 0,
          repair_order_id: this.form.pick_type === 2 ? this.form.repair_order_id : 0,
          department_id: this.form.department_id, picker_id: this.form.picker_id,
          pick_date: this.form.pick_date, purpose: this.form.purpose, remark: this.form.remark,
          items: this.items.map(it => ({
            production_item_id: it.production_item_id || 0, repair_item_id: it.repair_item_id || 0,
            material_id: it.material_id, material_code: it.material_code, material_name: it.material_name,
            spec: it.spec, unit: it.unit, apply_quantity: it.apply_quantity, actual_quantity: it.actual_quantity || it.apply_quantity,
            location_id: it.location_id || 0, remark: it.remark || ''
          }))
        }).then(r => {
          if (r.code === 0) { this.$message.success('保存成功'); this.$router.push('/warehouse/parts/pick/list') } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      } catch (e) { this.saving = false }
    },
    handleCancel () {
      if (this.items.length || this.form.purpose) {
        this.$confirm('确认离开吗？未保存的内容将丢失', '提示', { type: 'warning' }).then(() => this.$router.push('/warehouse/parts/pick/list')).catch(() => {})
      } else {
        this.$router.push('/warehouse/parts/pick/list')
      }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.info-card { margin-bottom: 14px; }
.card-head { font-size: 15px; font-weight: 600; display: flex; align-items: center; gap: 10px; }
.pick-form { max-width: 900px; }
.summary { margin-top: 10px; font-size: 13px; color: #606266; }
.pick-qty { margin-top: 12px; }
.danger { color: #F56C6C; }
</style>
