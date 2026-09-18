<!--
  文件：admin/src/views/business/receive/Add.vue
  功能：新增/编辑产品接收单（煤矿拉回主场景，动态表单+明细）
  权限：business:receive:add / edit
-->
<template>
  <div class="rc-add-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品接收管理</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑接收单' : '新增接收单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑接收单 - ' + form.receipt_no : '新增接收单' }}</span>
      <div class="header-actions">
        <el-button type="primary" size="small" :loading="saving" @click="handleSave">保存</el-button>
        <el-button size="small" @click="handleCancel">取消</el-button>
      </div>
    </div>

    <el-card shadow="never">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="接收类型" prop="receipt_type">
              <el-select v-model="form.receipt_type" style="width:100%" @change="onTypeChange">
                <el-option v-for="(t, v) in RECEIPT_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
            <el-form-item v-if="form.receipt_type === 1 || form.receipt_type === 4 || form.receipt_type === 3" label="客户" prop="customer_id">
              <el-select v-model="form.customer_id" filterable placeholder="从客户列表选择" style="width:100%" @change="onCustomerChange">
                <el-option v-for="c in customerOptions" :key="c.id" :label="c.customer_name" :value="c.id" />
              </el-select>
            </el-form-item>
            <el-form-item v-if="form.receipt_type === 1 || form.receipt_type === 2" label="关联维修订单">
              <el-select v-model="form.work_order_id" filterable remote :remote-method="searchWorkOrders" :loading="woLoading" clearable placeholder="从订单列表搜索维修订单" style="width:100%" @change="onWorkOrderChange">
                <el-option v-for="w in workOrderOptions" :key="w.id" :label="w.label" :value="w.id" />
              </el-select>
            </el-form-item>
            <el-form-item v-if="form.receipt_type === 3" label="客户" prop="customer_id">
              <el-select v-model="form.customer_id" filterable placeholder="选择客户" style="width:100%" @change="onCustomerChange">
                <el-option v-for="c in customerOptions" :key="c.id" :label="c.customer_name" :value="c.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="接收日期" prop="receipt_date">
              <el-date-picker v-model="form.receipt_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <!-- 产品明细 -->
    <el-card shadow="never" style="margin-top:14px;">
      <div class="section-title">产品明细</div>
      <div class="toolbar">
        <el-button size="small" type="primary" icon="el-icon-plus" @click="openOrderProducts">从订单添加产品</el-button>
        <el-button v-if="form.work_order_id" size="small" icon="el-icon-download" @click="importFromWorkOrder">导入订单全部产品</el-button>
        <span class="tip">产品仅可从关联维修订单的产品明细中添加</span>
      </div>
      <el-table :data="items" size="small" border empty-text="请先关联维修订单，再从订单添加产品">
        <el-table-column type="index" label="序号" width="50" align="center" />
        <el-table-column label="产品" min-width="200">
          <template slot-scope="s"><span>{{ (s.row.product_code || '') + ' ' + (s.row.product_name || '') }}</span></template>
        </el-table-column>
        <el-table-column label="规格型号" width="100">
          <template slot-scope="s"><el-input v-model="s.row.product_spec" size="small" /></template>
        </el-table-column>
        <el-table-column label="单位" width="70">
          <template slot-scope="s"><el-input v-model="s.row.product_unit" size="small" /></template>
        </el-table-column>
        <el-table-column label="数量" width="130">
          <template slot-scope="s">
            <el-input-number v-model="s.row.quantity" :min="0" :precision="0" :max="s.row.max_qty || 0" size="small" style="width:100%" @change="v => onQtyChange(s.$index, v)" />
            <div v-if="Number(s.row.max_qty) <= 0" class="full-tip">已全部接收</div>
          </template>
        </el-table-column>
        <el-table-column label="产品状态" width="100">
          <template slot-scope="s">
            <el-select v-model="s.row.product_status" size="small" style="width:100%">
              <el-option v-for="(t, v) in PRODUCT_STATUSES" :key="v" :label="t" :value="Number(v)" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="设备编号" width="120">
          <template slot-scope="s"><el-input v-model="s.row.serial_no" placeholder="序列号" size="small" /></template>
        </el-table-column>
        <el-table-column label="备注" min-width="110">
          <template slot-scope="s"><el-input v-model="s.row.remark" size="small" /></template>
        </el-table-column>
        <el-table-column label="操作" width="60" align="center" fixed="right">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="removeItem(s.$index)">删除</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 从订单添加产品弹窗 -->
    <el-dialog title="从订单添加产品" :visible="orderProdVisible" @update:visible="v => orderProdVisible = v" width="560px" top="8vh">
      <el-alert v-if="!form.work_order_id" type="warning" :closable="false" show-icon title="请先关联维修订单" style="margin-bottom:12px" />
      <template v-else>
        <el-checkbox-group v-model="pickedIds">
          <el-checkbox v-for="p in orderProductOptions" :key="p.id" :label="p.id" :disabled="Number(p.remaining) <= 0" style="display:block;margin:6px 0;">
            {{ p.product_code }} {{ p.product_name }}（{{ p.product_spec || '-' }} 剩余 {{ Number(p.remaining) || 0 }}/{{ p.quantity }}）
            <span v-if="Number(p.remaining) <= 0" class="full-tip">已全部接收</span>
          </el-checkbox>
        </el-checkbox-group>
      </template>
      <span slot="footer">
        <el-button size="small" @click="orderProdVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="confirmOrderProducts">添加</el-button>
      </span>
    </el-dialog>

    <el-card shadow="never" style="margin-top:14px;">
      <el-form label-width="120px" size="small">
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="3" /></el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { saveReceive, getReceiveDetail, getReceiveWorkOrders, getReceiveCustomers } from '../../../api/purchase'
import { getUserList } from '../../../api/user'

const RECEIPT_TYPES = { 1: '煤矿拉回', 2: '维修完成移交', 3: '客户退货', 4: '内部调拨', 5: '其他' }
const PRODUCT_STATUSES = { 1: '完好', 2: '待维修', 3: '待保养', 4: '报废', 5: '待检验' }

export default {
  name: 'ProductReceiveAdd',
  data () {
    return {
      RECEIPT_TYPES, PRODUCT_STATUSES,
      id: Number(this.$route.params.id) || 0,
      isEdit: false, saving: false,
      form: { receipt_type: 1, work_order_id: null, work_order_no: '', source_location: '', customer_id: null, customer_name: '', receipt_date: this.today(), receiver_id: 0, receiver_name: '', remark: '' },
      items: [],
      orderProdVisible: false, orderProductOptions: [], pickedIds: [],
      workOrderOptions: [], woLoading: false, customerOptions: [], userOptions: [],
      rules: {
        receipt_type: [{ required: true, message: '请选择接收类型', trigger: 'change' }],
        receipt_date: [{ required: true, message: '请选择接收日期', trigger: 'change' }]
      }
    }
  },
  created () {
    this.isEdit = this.id > 0
    this.loadUsers()
    this.loadCustomers()
    if (this.isEdit) this.loadDetail()
  },
  methods: {
    today () { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    async loadUsers () {
      try { const u = await getUserList({ page: 1, limit: 200 }); this.userOptions = (u.data && u.data.list) || [] } catch (e) { this.userOptions = [] }
      const me = this.$store && this.$store.state && this.$store.state.user
      if (me) {
        const found = this.userOptions.find(x => (x.real_name || x.username) === (me.real_name || me.username))
        if (found) this.form.receiver_id = found.id
      }
    },
    async loadCustomers () {
      try { const r = await getReceiveCustomers(); this.customerOptions = (r.code === 0 && r.data) ? r.data : [] } catch (e) { this.customerOptions = [] }
    },
    async loadDetail () {
      try {
        const r = await getReceiveDetail(this.id)
        if (r.code === 0 && r.data) {
          const d = r.data.receipt || {}
          this.form = { receipt_type: d.receipt_type, work_order_id: d.work_order_id || null, work_order_no: d.work_order_no || '', source_location: d.source_location || '', customer_id: d.customer_id || null, customer_name: d.customer_name || '', receipt_date: d.receipt_date || this.today(), receiver_id: d.receiver_id || 0, receiver_name: d.receiver_name || '', remark: d.remark || '' }
          this.items = (r.data.items || []).map(it => ({ ...it, product_status: it.product_status || 5, max_qty: (it.max_qty !== undefined ? Number(it.max_qty) : Number(it.quantity)) || 0 }))
          // 编辑回显：加载工单选项使已关联工单正确显示
          if (d.work_order_id) this.searchWorkOrders('')
        }
      } catch (e) {}
    },
    onTypeChange () {
      this.form.source_location = ''
      this.form.customer_id = null
      this.form.work_order_id = null
      this.form.work_order_no = ''
      this.$nextTick(() => { if (this.$refs.form) this.$refs.form.clearValidate() })
    },
    async searchWorkOrders (kw) {
      this.woLoading = true
      try { const r = await getReceiveWorkOrders(kw); this.workOrderOptions = (r.code === 0 && r.data) ? r.data : [] } catch (e) { this.workOrderOptions = [] } finally { this.woLoading = false }
    },
    onWorkOrderChange (id) {
      const w = this.workOrderOptions.find(x => x.id === id)
      this.form.work_order_no = w ? w.no : ''
      // 关联维修订单后自动获取客户（订单客户名称）
      if (w && w.customer_name) {
        const c = this.customerOptions.find(x => x.customer_name === w.customer_name)
        this.form.customer_id = c ? c.id : 0
        this.form.customer_name = w.customer_name
        this.items.forEach(it => { it.source_location = w.customer_name })
      }
      if (w && w.items && w.items.length && !this.items.length) {
        this.items = w.items.map(it => ({
          work_order_item_id: it.work_order_item_id || 0, product_id: it.product_id, product_code: it.product_code, product_name: it.product_name, product_spec: it.product_spec || '',
          product_unit: it.product_unit || '', quantity: Number(it.remaining) || 0, max_qty: Number(it.remaining) || 0, product_status: 5,
          serial_no: '', source_location: this.form.customer_name, manufacturer: '', manufacture_date: '', remark: ''
        }))
      }
    },
    onCustomerChange (id) {
      const c = this.customerOptions.find(x => x.id === id)
      this.form.customer_name = c ? c.customer_name : ''
      // 明细"客户"列统一显示主表客户名
      this.items.forEach(it => { it.source_location = this.form.customer_name })
    },
    importFromWorkOrder () {
      if (!this.form.work_order_id) return
      const w = this.workOrderOptions.find(x => x.id === this.form.work_order_id)
      if (w && w.items && w.items.length) {
        w.items.forEach(it => {
          if (Number(it.remaining) <= 0) return
          this.items.push({
            work_order_item_id: it.work_order_item_id || 0, product_id: it.product_id, product_code: it.product_code, product_name: it.product_name, product_spec: it.product_spec || '',
            product_unit: it.product_unit || '', quantity: Number(it.remaining) || 0, max_qty: Number(it.remaining) || 0, product_status: 5,
            serial_no: '', source_location: this.form.customer_name, manufacturer: '', manufacture_date: '', remark: ''
          })
        })
        this.$message.success('已从维修订单导入 ' + w.items.length + ' 项')
      } else {
        this.$message.info('该维修订单无产品明细')
      }
    },
    addItem () {
      this.items.push({ work_order_item_id: 0, product_id: 0, product_code: '', product_name: '', product_spec: '', product_unit: '', quantity: 1, product_status: 5, serial_no: '', source_location: this.form.customer_name, manufacturer: '', manufacture_date: '', remark: '' })
    },
    openOrderProducts () {
      if (!this.form.work_order_id) { this.$message.warning('请先关联维修订单'); return }
      const w = this.workOrderOptions.find(x => x.id === this.form.work_order_id)
      this.orderProductOptions = (w && w.items) ? w.items : []
      this.pickedIds = []
      this.orderProdVisible = true
    },
    confirmOrderProducts () {
      const w = this.workOrderOptions.find(x => x.id === this.form.work_order_id)
      const all = (w && w.items) ? w.items : []
      const picked = all.filter(p => this.pickedIds.includes(p.id))
      if (!picked.length) { this.$message.warning('请选择产品'); return }
      picked.forEach(p => {
        if (Number(p.remaining) <= 0) return
        this.items.push({
          work_order_item_id: p.work_order_item_id || 0, product_id: p.product_id, product_code: p.product_code, product_name: p.product_name, product_spec: p.product_spec || '',
          product_unit: p.product_unit || '', quantity: Number(p.remaining) || 0, max_qty: Number(p.remaining) || 0, product_status: 5,
          serial_no: '', source_location: this.form.customer_name, manufacturer: '', manufacture_date: '', remark: ''
        })
      })
      this.orderProdVisible = false
      this.$message.success('已添加 ' + picked.length + ' 项')
    },
    removeItem (idx) { this.items.splice(idx, 1) },
    onQtyChange (idx, v) {
      const it = this.items[idx]
      if (it && it.max_qty !== undefined && Number(v) > Number(it.max_qty)) {
        it.quantity = Number(it.max_qty)
        this.$message.warning('数量不能超过剩余可接收量（' + it.max_qty + '）')
      }
    },
    handleCancel () {
      if (this.form.source_location || this.form.work_order_id || this.items.length) {
        this.$confirm('确认离开吗？未保存的内容将丢失', '提示', { type: 'warning' }).then(() => this.$router.push('/business/receive/list')).catch(() => {})
      } else {
        this.$router.push('/business/receive/list')
      }
    },
    async handleSave () {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) { this.$message.warning('请完善必填项'); return }
      if ([1, 3, 4].includes(this.form.receipt_type) && !this.form.customer_id) { this.$message.warning('请选择客户'); return }
      if (!this.items.length) { this.$message.warning('请至少添加一条产品明细'); return }
      if (!this.items.some(it => Number(it.quantity) > 0)) { this.$message.warning('订单产品已全部接收，无可接收数量'); return }
      if (this.items.some(it => !it.product_name)) { this.$message.warning('产品名称必填'); return }
      this.saving = true
      try {
        // 接收人 = 当前操作用户（哪个用户添加，接收人即哪个用户）
        const me = this.$store && this.$store.state && this.$store.state.user
        const receiverId = (me && me.id) ? me.id : 0
        const r = await saveReceive({
          id: this.id || null,
          receipt_type: this.form.receipt_type, work_order_id: this.form.work_order_id || 0, work_order_no: this.form.work_order_no,
          source_location: this.form.source_location || this.form.customer_name, customer_id: this.form.customer_id || 0, customer_name: this.form.customer_name,
          receipt_date: this.form.receipt_date, receiver_id: receiverId, remark: this.form.remark,
            items: this.items.map(it => ({
              work_order_item_id: it.work_order_item_id || 0,
              product_id: it.product_id, product_code: it.product_code, product_name: it.product_name, product_spec: it.product_spec,
            product_unit: it.product_unit, quantity: it.quantity, product_status: it.product_status, serial_no: it.serial_no,
            source_location: it.source_location || this.form.customer_name, manufacturer: it.manufacturer, manufacture_date: it.manufacture_date, remark: it.remark
          }))
        })
        if (r.code === 0) { this.$message.success('保存成功'); this.$router.push('/business/receive/list') }
        else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.rc-add-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.section-title { font-size: 15px; font-weight: 600; margin-bottom: 12px; }
.toolbar { margin-bottom: 12px; }
.tip { font-size: 12px; color: #909399; margin-left: 8px; }
.full-tip { color: #F56C6C; font-size: 12px; margin-left: 6px; }
.danger { color: #F56C6C; }
</style>
