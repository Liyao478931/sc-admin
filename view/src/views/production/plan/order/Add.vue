<!--
  文件：admin/src/views/production/plan/order/Add.vue
  功能：新建/编辑工单（来源订单 + BOM 明细自动带入 + 工序/工位配置 + 工位可用性校验）
  权限：production:order:create / edit
  规则：必须选来源订单；BOM 至少一条且每行工序/工位必选；工位校验（占用/无设备/设备不可用拦截）；计划数量≤订单数量
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产计划</el-breadcrumb-item>
      <el-breadcrumb-item>生产工单</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑工单' : '新建工单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑工单' : '新建工单' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="handleCancel">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <!-- 来源单据选择区域 -->
    <el-card v-if="!isEdit" shadow="never" class="source-card">
      <div slot="header" class="card-header">来源单据</div>
      <el-form inline size="small" label-width="90px">
        <el-form-item label="来源类型" required>
          <el-select v-model="sourceType" placeholder="请选择" style="width:140px" :disabled="isFromOrder" @change="onSourceTypeChange">
            <el-option :value="1" label="销售订单" />
            <el-option :value="2" label="维修订单" />
          </el-select>
        </el-form-item>
        <el-form-item label="选择来源单据" required>
          <el-select v-model="selectedSourceId" filterable placeholder="请选择订单" style="width:320px" :disabled="isFromOrder || !sourceType" :loading="loadingSource" @change="onSourceOrderChange">
            <el-option v-for="o in sourceOrders" :key="o.id" :label="`${o.order_no} - ${o.customer_name || ''} - ${o.product_name || o.device_name || ''}`" :value="o.id" />
          </el-select>
          <div v-if="sourceType && !loadingSource && !sourceOrders.length" class="empty-tip">暂无可用订单</div>
        </el-form-item>
      </el-form>
      <el-descriptions v-if="sourceSummary" :column="2" size="small" border class="source-summary">
        <el-descriptions-item label="客户名称">{{ sourceSummary.customer_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="下单日期">{{ sourceSummary.order_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="订单金额">¥{{ fmt(sourceSummary.order_amount) }}</el-descriptions-item>
        <el-descriptions-item label="交货日期">{{ sourceSummary.delivery_date || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 工单信息表单 -->
    <el-card shadow="never" class="form-card">
      <div slot="header" class="card-header">工单信息</div>
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="工单类型" prop="order_type">
              <el-input :value="form.order_type === 1 ? '生产工单' : '维修工单'" readonly />
            </el-form-item>
            <el-form-item label="来源单据编号">
              <span class="link-blue" @click="goOrderList">{{ form.source_no || '-' }}</span>
            </el-form-item>
            <el-form-item label="产品名称"><el-input :value="form.product_name || ''" readonly /></el-form-item>
            <el-form-item label="规格型号"><el-input :value="form.product_spec || ''" readonly /></el-form-item>
            <el-form-item label="计划数量" prop="plan_quantity">
              <el-input-number v-model="form.plan_quantity" :min="0.0001" :max="hasSource ? sourceQuantity : undefined" :precision="4" style="width:100%" />
              <div v-if="hasSource && sourceQuantity" class="qty-tip">最多 {{ sourceQuantity }}（订单数量）</div>
            </el-form-item>
            <el-form-item label="计划开始日期" prop="planned_start_date">
              <el-date-picker v-model="form.planned_start_date" type="date" value-format="yyyy-MM-dd" :picker-options="startDateOptions" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item v-if="hasSource" label="客户名称"><el-input :value="form.customer_name || ''" readonly /></el-form-item>
            <el-form-item label="计划完成日期" prop="planned_end_date">
              <el-date-picker v-model="form.planned_end_date" type="date" value-format="yyyy-MM-dd" :picker-options="endDateOptions" style="width:100%" />
            </el-form-item>
            <el-form-item label="优先级" prop="priority">
              <el-select v-model="form.priority" style="width:100%">
                <el-option :value="1" label="普通" />
                <el-option :value="2" label="紧急" />
                <el-option :value="3" label="特急" />
              </el-select>
            </el-form-item>
            <el-form-item label="负责人" prop="responsible_person_id">
              <el-select v-model="form.responsible_person_id" filterable clearable placeholder="请选择负责人" style="width:100%" @change="onPersonChange">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="负责部门" prop="department_id">
              <el-select v-model="form.department_id" filterable clearable placeholder="请选择部门" style="width:100%">
                <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="3" placeholder="请输入备注信息" /></el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <!-- 工序与工位配置（BOM 明细） -->
    <el-card shadow="never" class="form-card">
      <div slot="header" class="card-header">工序与工位配置</div>
      <div v-if="!bomFound && !isEdit" class="bom-empty">
        <span>{{ bomMsg || '请先选择来源单据以加载 BOM 明细' }}</span>
        <el-button v-if="bomMsg && bomMsg.indexOf('尚未配置') > -1" type="text" size="small" @click="goBomManage">跳转至 BOM 管理</el-button>
      </div>
      <el-table :data="form.items" size="small" border>
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="material_code" label="物料编码" width="120" show-overflow-tooltip />
        <el-table-column prop="material_name" label="物料名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="60" align="center" />
        <el-table-column label="计划用量" width="100" align="right"><template slot-scope="s"><el-input-number v-model="s.row.plan_quantity" :min="0" :precision="4" size="mini" style="width:100%" /></template></el-table-column>
        <el-table-column label="工序" width="140">
          <template slot-scope="s">
            <el-select v-model="s.row.process_id" filterable placeholder="选择工序" size="mini" style="width:100%" @change="(v) => onProcessChange(s.$index, v)">
              <el-option v-for="p in processOptions" :key="p.id" :label="p.process_name" :value="p.id" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="工位" width="150">
          <template slot-scope="s">
            <el-select v-model="s.row.workstation_id" filterable placeholder="选择工位" size="mini" style="width:100%" @change="(v) => onWorkstationChange(s.$index, v)">
              <el-option v-for="w in workstationOptions" :key="w.id" :label="w.workstation_name" :value="w.id" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="计划工时" width="100">
          <template slot-scope="s"><el-input-number v-model="s.row.work_duration" :min="0" :precision="2" size="mini" style="width:100%" /></template>
        </el-table-column>
        <el-table-column label="操作" width="70" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger-text" @click="removeItem(s.$index)">删除</el-button></template>
        </el-table-column>
      </el-table>
      <el-button v-if="isEdit || bomFound" size="small" icon="el-icon-plus" @click="addItem">添加明细</el-button>
      <div v-if="currentWorkstationStaff" class="ws-staff">工位关联员工：{{ currentWorkstationStaff }}</div>
    </el-card>
  </div>
</template>

<script>
import { getOrderProducts, createOrder, editOrder, getOrderDetail, getSourceData, getOrderUsers, getAvailableSalesOrders, getAvailableRepairOrders, getOrderBom, checkWorkstation, getProcessList, getWorkstationList, getWsStaff } from '@/api/production'
import { getDepartmentOptions } from '@/api/attendanceStatistics'

export default {
  name: 'ProductionOrderAdd',
  data () {
    return {
      isEdit: false, isFromOrder: false,
      sourceOrderNo: '', sourceQuantity: null,
      sourceType: null, selectedSourceId: null, sourceOrders: [], sourceSummary: null, loadingSource: false,
      bomFound: false, bomMsg: '', currentWorkstationStaff: '',
      processOptions: [], workstationOptions: [],
      userOptions: [], deptOptions: [],
      form: {
        order_type: 1, source_type: 0, source_id: 0, source_no: '', product_id: null, product_name: '', product_spec: '',
        customer_id: 0, customer_name: '', plan_quantity: 1, priority: 1,
        planned_start_date: this.today(), planned_end_date: '', responsible_person_id: null, responsible_person_name: '',
        department_id: null, department_name: '', remark: '', items: []
      },
      rules: {
        order_type: [{ required: true, message: '请选择工单类型' }],
        plan_quantity: [{ required: true, message: '请输入计划数量' }],
        planned_start_date: [{ required: true, message: '请选择计划开始日期' }],
        planned_end_date: [{ required: true, message: '请选择计划完成日期' }],
        priority: [{ required: true, message: '请选择优先级' }],
        responsible_person_id: [{ required: true, message: '请选择负责人' }],
        department_id: [{ required: true, message: '请选择负责部门' }]
      },
      saving: false, saved: false, initialSnapshot: ''
    }
  },
  computed: {
    hasSource () { return this.form.source_type === 1 || this.form.source_type === 2 },
    startDateOptions () { return { disabledDate: (t) => t.getTime() < Date.now() - 86400000 } },
    endDateOptions () {
      const start = this.form.planned_start_date ? new Date(this.form.planned_start_date).getTime() : 0
      return { disabledDate: (t) => t.getTime() < Date.now() - 86400000 || (start && t.getTime() < start) }
    }
  },
  beforeRouteLeave (to, from, next) {
    if (this.saved || !this.isDirty()) return next()
    this.$confirm('确认离开吗？未保存的内容将丢失', '提示', { type: 'warning' }).then(() => next()).catch(() => next(false))
  },
  created () {
    this.loadProcessOptions()
    this.loadWorkstationOptions()
    this.loadUsers()
    this.loadDepts()
    this.setDefaultDepartment()
    const id = this.$route.params.id
    if (id) { this.isEdit = true; this.loadDetail(id) }
    else {
      const st = this.$route.query.source_type
      const sid = this.$route.query.source_id
      if (st && sid) this.initFromOrder(st, sid)
    }
  },
  methods: {
    today () { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    fmt (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    isDirty () {
      if (this.saved) return false
      if (this.isEdit) return this.initialSnapshot !== '' && this.initialSnapshot !== JSON.stringify(this.form)
      return this.sourceType !== null || !!this.form.planned_end_date || !!this.form.remark || this.form.items.length > 0
    },
    async loadProcessOptions () {
      try { const r = await getProcessList({ page: 1, pageSize: 100, status: 1 }); if (r.code === 0) this.processOptions = r.data.list || [] } catch (e) { this.processOptions = [] }
    },
    async loadWorkstationOptions () {
      try { const r = await getWorkstationList({ page: 1, pageSize: 100, status: 1 }); if (r.code === 0) this.workstationOptions = r.data.list || [] } catch (e) { this.workstationOptions = [] }
    },
    async loadUsers () {
      try { const r = await getOrderUsers(); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) { this.userOptions = [] }
    },
    async loadDepts () {
      try {
        const r = await getDepartmentOptions()
        const out = []; const walk = (nodes) => { (nodes || []).forEach(n => { out.push({ id: n.id, name: n.name }); walk(n.children) }) }
        walk(r.data); this.deptOptions = out
      } catch (e) { this.deptOptions = [] }
    },
    setDefaultDepartment () {
      const me = this.$store.state.user.userInfo || {}
      if (me.department_id) { this.form.department_id = me.department_id; this.form.department_name = me.department_name || '' }
    },
    async initFromOrder (sourceType, sourceId) {
      this.isFromOrder = true
      this.sourceType = Number(sourceType)
      await this.loadSourceOrders()
      this.selectedSourceId = Number(sourceId)
      await this.fillFromOrder(Number(sourceType), Number(sourceId))
    },
    async loadSourceOrders () {
      if (!this.sourceType) { this.sourceOrders = []; return }
      this.loadingSource = true
      try {
        const r = this.sourceType === 1 ? await getAvailableSalesOrders() : await getAvailableRepairOrders()
        if (r.code === 0) this.sourceOrders = r.data.list || []
      } catch (e) { this.sourceOrders = [] } finally { this.loadingSource = false }
    },
    onSourceTypeChange () {
      this.selectedSourceId = null
      this.sourceSummary = null
      this.clearFromOrderFill()
      if (this.sourceType) this.loadSourceOrders()
    },
    clearFromOrderFill () {
      this.sourceQuantity = null
      this.bomFound = false
      this.bomMsg = ''
      this.form = { ...this.form, order_type: 1, source_type: 0, source_id: 0, source_no: '', product_id: null, product_name: '', product_spec: '', customer_id: 0, customer_name: '', plan_quantity: 1, planned_end_date: '', items: [] }
    },
    async onSourceOrderChange (id) {
      if (!id) { this.sourceSummary = null; this.clearFromOrderFill(); return }
      const o = this.sourceOrders.find(x => x.id === id)
      this.sourceSummary = o || null
      await this.fillFromOrder(this.sourceType, id)
    },
    async fillFromOrder (sourceType, sourceId) {
      try {
        const r = await getSourceData({ source_type: sourceType, source_id: sourceId })
        if (r.code === 0 && r.data) {
          const d = r.data
          const items = d.items || []
          const totalQty = items.reduce((s, it) => s + Number(it.quantity || 0), 0)
          const first = items[0] || {}
          this.sourceQuantity = totalQty || null
          this.form = {
            ...this.form,
            order_type: Number(sourceType) === 1 ? 1 : 2,
            source_type: Number(sourceType), source_id: Number(sourceId), source_no: d.order_no || '',
            product_id: first.product_id || null, product_name: first.product_name || '', product_spec: first.product_spec || first.product_model || '',
            customer_id: d.customer_id || 0, customer_name: d.customer_name || '',
            plan_quantity: totalQty || 1, planned_end_date: d.delivery_date || ''
          }
          await this.loadBom(first.product_id)
        } else this.$message.error(r.msg || '订单数据加载失败')
      } catch (e) {}
    },
    async loadBom (productId) {
      this.bomFound = false
      this.bomMsg = ''
      this.form.items = []
      if (!productId) { this.bomMsg = '订单无产品，无法加载 BOM'; return }
      try {
        const r = await getOrderBom(productId)
        if (r.code === 0 && r.data) {
          if (!r.data.found) { this.bomMsg = r.msg || '该产品尚未配置 BOM，请先在产品管理中为该产品创建 BOM'; return }
          this.bomFound = true
          this.form.items = (r.data.list || []).map(i => ({ ...i, work_duration: 0 }))
        } else this.bomMsg = r.msg || 'BOM 加载失败'
      } catch (e) { this.bomMsg = 'BOM 加载失败' }
    },
    async loadDetail (id) {
      try {
        const r = await getOrderDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            order_type: d.order_type, source_type: d.source_type, source_id: d.source_id || 0, source_no: d.source_no,
            product_id: d.product_id, product_name: d.product_name, product_spec: d.product_spec,
            customer_id: d.customer_id, customer_name: d.customer_name,
            plan_quantity: Number(d.plan_quantity), priority: d.priority,
            planned_start_date: d.planned_start_date || this.today(), planned_end_date: d.planned_end_date || '',
            responsible_person_id: d.responsible_person_id || null, responsible_person_name: d.responsible_person_name || '',
            department_id: d.department_id || null, department_name: d.department_name || '',
            remark: d.remark || '', items: (d.items || []).map(i => ({ ...i }))
          }
          if (this.form.source_type === 1 || this.form.source_type === 2) {
            try {
              const s = await getSourceData({ source_type: this.form.source_type, source_id: this.form.source_id })
              if (s.code === 0 && s.data) {
                const its = s.data.items || []
                this.sourceQuantity = its.reduce((sum, it) => sum + Number(it.quantity || 0), 0) || null
                this.sourceOrderNo = s.data.order_no || ''
              }
            } catch (e) {}
          }
          if (this.form.items.length) this.bomFound = true
          this.initialSnapshot = JSON.stringify(this.form)
        }
      } catch (e) {}
    },
    onPersonChange (id) {
      const u = this.userOptions.find(x => x.id === id)
      if (u) {
        this.form.responsible_person_name = u.real_name || u.username
        if (!this.form.department_id && u.department_id) {
          const d = this.deptOptions.find(x => x.id === u.department_id)
          this.form.department_id = u.department_id
          this.form.department_name = d ? d.name : ''
        }
      }
    },
    onProcessChange (idx, id) {
      const p = this.processOptions.find(x => x.id === id)
      if (p && this.form.items[idx]) { this.form.items[idx].process_name = p.process_name }
    },
    async onWorkstationChange (idx, id) {
      const row = this.form.items[idx]
      if (!row) return
      if (!id) { row.workstation_id = 0; row.workstation_name = ''; this.currentWorkstationStaff = ''; return }
      const ws = this.workstationOptions.find(x => x.id === id)
      if (ws) row.workstation_name = ws.workstation_name
      try {
        const r = await checkWorkstation(id)
        if (r.code === 0 && r.data) {
          if (!r.data.available) {
            this.$message.warning(r.data.message || '该工位不可用')
            row.workstation_id = 0
            row.workstation_name = ''
            this.currentWorkstationStaff = ''
            return
          }
          const sr = await getWsStaff(id)
          if (sr.code === 0 && sr.data && sr.data.list) {
            this.currentWorkstationStaff = sr.data.list.map(s => s.user_name).join('、') || '（无关联员工）'
          }
        } else this.$message.error(r.msg || '校验失败')
      } catch (e) {}
    },
    addItem () {
      this.form.items.push({ material_id: null, material_code: '', material_name: '', specification: '', unit: '', plan_quantity: 0, process_id: 0, process_name: '', workstation_id: 0, workstation_name: '', work_duration: 0, remark: '' })
    },
    removeItem (idx) { this.form.items.splice(idx, 1) },
    goOrderList () { this.$router.push('/business/order') },
    goBomManage () { this.$router.push('/business/product/bom') },
    handleCancel () {
      if (this.isDirty()) {
        this.$confirm('确认离开吗？未保存的内容将丢失', '提示', { type: 'warning' }).then(() => { this.saved = true; this.$router.push('/production/plan/order/list') }).catch(() => {})
      } else this.$router.push('/production/plan/order/list')
    },
    async handleSave () {
      if (!this.isEdit) {
        if (!this.sourceType) { this.$message.warning('请选择来源类型'); return }
        if (!this.selectedSourceId) { this.$message.warning('请选择来源单据'); return }
      }
      if (!this.form.items.length) { this.$message.warning('BOM 明细至少一条，请先选择来源单据加载 BOM'); return }
      for (const it of this.form.items) {
        if (!it.process_id) { this.$message.warning(`「${it.material_name || it.material_code}」请选择工序`); return }
        if (!it.workstation_id) { this.$message.warning(`「${it.material_name || it.material_code}」请选择工位`); return }
      }
      if (!this.form.plan_quantity || this.form.plan_quantity <= 0) { this.$message.warning('请输入计划数量'); return }
      if (this.hasSource && this.sourceQuantity && this.form.plan_quantity > this.sourceQuantity) { this.$message.warning(`计划数量不能超过订单数量（${this.sourceQuantity}）`); return }
      if (!this.form.planned_start_date) { this.$message.warning('请选择计划开始日期'); return }
      if (!this.form.planned_end_date) { this.$message.warning('请选择计划完成日期'); return }
      if (this.form.planned_end_date < this.form.planned_start_date) { this.$message.warning('计划完成日期不能早于计划开始日期'); return }
      if (!this.form.responsible_person_id) { this.$message.warning('请选择负责人'); return }
      if (!this.form.department_id) { this.$message.warning('请选择负责部门'); return }
      this.saving = true
      try {
        const data = {
          ...this.form,
          source_type: this.sourceType || this.form.source_type || 0,
          source_id: this.selectedSourceId || this.form.source_id || 0,
          items: this.form.items.filter(i => i.material_id || i.material_name)
        }
        let r
        if (this.isEdit) r = await editOrder(this.$route.params.id, data)
        else r = await createOrder(data)
        if (r.code === 0) { this.saved = true; this.$message.success('工单创建成功'); this.$router.replace('/production/plan/order/list') } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; background: #fff; padding: 14px 20px; border-radius: 8px 8px 0 0; border-bottom: 1px solid #ebeef5; }
.page-title { font-size: 18px; font-weight: 700; }
.header-actions { display: flex; gap: 10px; }
.source-card { margin-top: 12px; border-radius: 8px; }
.form-card { margin-top: 12px; border-radius: 8px; }
.card-header { font-weight: 600; }
.source-summary { margin-top: 8px; }
.empty-tip { color: #909399; font-size: 12px; line-height: 20px; }
.bom-empty { color: #E6A23C; font-size: 13px; padding: 8px 0; }
.link-blue { color: #409EFF; cursor: pointer; }
.qty-tip { font-size: 12px; color: #909399; line-height: 20px; }
.danger-text { color: #F56C6C; }
.ws-staff { margin-top: 10px; font-size: 13px; color: #909399; }
</style>
