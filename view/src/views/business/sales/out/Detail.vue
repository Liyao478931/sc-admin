<!--
  文件：admin/src/views/business/sales/out/Detail.vue
  功能：出库单详情（出库单信息卡 / 出库明细 / 操作日志时间轴 / 物流信息 / 状态操作 / 打印）
  权限：sales:out:list:view / add / edit / confirm / ship
  说明：审核走统一审批（提交后由统一审批待办处理，本页不提供审核通过/驳回按钮）
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>出库单列表</el-breadcrumb-item>
      <el-breadcrumb-item>出库单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">出库单详情 - {{ d.out_no || '' }}</span>
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push({ path: '/business/sales/out/list' })">返回列表</el-button>
        <el-button v-if="d.status === 0 || d.status === 4" v-permission="'sales:out:edit'" size="small" icon="el-icon-edit" @click="goEdit">编辑</el-button>
        <el-button v-if="d.status === 0 || d.status === 4" size="small" type="primary" icon="el-icon-upload2" :loading="submitting" @click="handleSubmit">提交审核</el-button>
        <el-button v-if="d.status === 2" v-permission="'sales:out:confirm'" size="small" type="success" icon="el-icon-check" :loading="confirming" @click="handleConfirm">确认出库</el-button>
        <el-button v-if="d.status === 3" v-permission="'sales:ship:add'" size="small" type="primary" icon="el-icon-ship" @click="handleGenShip">生成发货单</el-button>
        <el-button v-if="d.status === 3 && !d.ship_date" v-permission="'sales:out:ship'" size="small" type="warning" icon="el-icon-truck" @click="shipVisible = true">登记发货</el-button>
        <el-button size="small" icon="el-icon-printer" @click="handlePrint">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <div slot="header" class="card-header">
        <span>出库单信息</span>
        <el-tag :type="d.status_tag" size="small">{{ d.status_label }}</el-tag>
      </div>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="出库单编号">{{ d.out_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="销售订单">{{ d.source_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="客户名称">{{ d.customer_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="出库类型">{{ d.out_type_label || '-' }}</el-descriptions-item>
        <el-descriptions-item label="出库仓库">{{ d.warehouse_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="出库日期">{{ d.out_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="出库人">{{ d.out_user_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="出库总数量">{{ d.total_quantity || 0 }}</el-descriptions-item>
        <el-descriptions-item label="出库总金额">{{ money(d.total_amount) }}</el-descriptions-item>
        <el-descriptions-item label="审核人">{{ d.auditor_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核时间">{{ d.audit_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核备注">{{ d.audit_remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ d.creator_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ d.created_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ d.updated_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ d.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card shadow="never" class="form-card">
      <div slot="header"><span>出库明细</span></div>
      <el-table :data="d.items || []" size="small" border empty-text="暂无明细">
        <el-table-column prop="product_code" label="产品编码" width="110" />
        <el-table-column prop="product_name" label="产品名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="55" align="center" />
        <el-table-column prop="quantity" label="出库数量" width="90" align="right" />
        <el-table-column prop="unit_price" label="出库单价" width="100" align="right" />
        <el-table-column prop="total_price" label="出库总价" width="100" align="right" />
        <el-table-column prop="location_name" label="存放货位" width="120" show-overflow-tooltip><template slot-scope="s">{{ s.row.location_name || '-' }}</template></el-table-column>
        <el-table-column prop="serial_number" label="序列号" width="120" show-overflow-tooltip><template slot-scope="s">{{ s.row.serial_number || '-' }}</template></el-table-column>
        <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip><template slot-scope="s">{{ s.row.remark || '-' }}</template></el-table-column>
      </el-table>
    </el-card>

    <el-card v-if="d.ship_date" shadow="never" class="form-card">
      <div slot="header"><span>物流信息</span></div>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="发货方式">{{ d.ship_method_label || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发货日期">{{ d.ship_date }}</el-descriptions-item>
        <el-descriptions-item v-if="d.ship_company" label="物流公司" :span="2">{{ d.ship_company }}</el-descriptions-item>
        <el-descriptions-item v-if="d.ship_no" label="物流单号" :span="2">{{ d.ship_no }}</el-descriptions-item>
        <el-descriptions-item v-if="d.consignee" label="收货人" :span="2">{{ d.consignee }}（{{ d.consignee_phone || '-' }}）</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card shadow="never" class="form-card">
      <div slot="header"><span>操作日志</span></div>
      <el-timeline v-if="logs.length" style="padding-left:8px;">
        <el-timeline-item v-for="(lg, i) in logs" :key="i" :timestamp="lg.operator_time" placement="top">
          <div>{{ lg.action_label }} <span style="color:#909399">({{ lg.operator_name }})</span></div>
          <div v-if="lg.from_status_text || lg.to_status_text" style="color:#606266;font-size:12px;">{{ lg.from_status_text }} → {{ lg.to_status_text }}</div>
          <div v-if="lg.remark" style="color:#606266;font-size:12px;">{{ lg.remark }}</div>
        </el-timeline-item>
        <el-timeline-item v-for="(h, i) in d.approval_histories || []" :key="'h' + i" :timestamp="h.created_at" :type="h.result === 'reject' ? 'danger' : (h.action === 'submit' ? 'primary' : 'success')" placement="top">
          <div>【统一审批】{{ h.action_label }}：{{ h.result === 'pass' ? '通过' : (h.result === 'reject' ? '驳回' : '') }} <span style="color:#909399">({{ h.operator_name }})</span></div>
          <div v-if="h.comment" style="color:#606266;font-size:12px;">意见：{{ h.comment }}</div>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-else description="暂无操作日志" :image-size="50" />
    </el-card>

    <!-- 登记发货弹窗 -->
    <el-dialog title="登记发货" :visible.sync="shipVisible" width="480px">
      <el-form ref="shipForm" :model="shipForm" :rules="shipRules" label-width="90px" size="small">
        <el-form-item label="发货方式" prop="ship_method">
          <el-radio-group v-model="shipForm.ship_method">
            <el-radio :label="1">物流</el-radio>
            <el-radio :label="2">自提</el-radio>
            <el-radio :label="3">快递</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="shipForm.ship_method === 1" label="物流公司" prop="ship_company"><el-input v-model="shipForm.ship_company" placeholder="如：顺丰速运" /></el-form-item>
        <el-form-item v-if="shipForm.ship_method === 1" label="物流单号" prop="ship_no"><el-input v-model="shipForm.ship_no" placeholder="请输入物流单号" /></el-form-item>
        <el-form-item label="发货日期" prop="ship_date"><el-date-picker v-model="shipForm.ship_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择发货日期" style="width:100%" /></el-form-item>
        <el-form-item label="收货人"><el-input v-model="shipForm.consignee" placeholder="选填" /></el-form-item>
        <el-form-item label="收货电话"><el-input v-model="shipForm.consignee_phone" placeholder="选填" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button size="small" @click="shipVisible=false">取消</el-button><el-button size="small" type="primary" :loading="shipping" @click="handleShip">确认登记</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getSalesOutDetail, submitSalesOut, confirmSalesOut, shipSalesOut } from '@/api/sales'
import { generateShip } from '@/api/sales'

export default {
  name: 'SalesOutDetail',
  data () {
    return {
      d: {}, submitting: false, confirming: false, shipping: false,
      shipVisible: false, shipForm: {},
      shipRules: {
        ship_method: [{ required: true, message: '请选择发货方式', trigger: 'change' }],
        ship_date: [{ required: true, message: '请选择发货日期', trigger: 'change' }],
        ship_company: [{ required: true, message: '请填写物流公司', trigger: 'blur' }],
        ship_no: [{ required: true, message: '请填写物流单号', trigger: 'blur' }]
      }
    }
  },
  computed: {
    logs () { return this.d.logs || [] }
  },
  created () {
    this.loadDetail(Number(this.$route.params.id))
    if (this.$route.query.print) setTimeout(() => { window.print() }, 600)
  },
  methods: {
    money (v) { const n = Number(v) || 0; return n ? '¥ ' + n.toLocaleString('zh-CN', { minimumFractionDigits: 2 }) : '-' },
    async loadDetail (id) {
      try {
        const r = await getSalesOutDetail(id)
        if (r.code === 0 && r.data) this.d = r.data
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    goEdit () { this.$router.push({ path: `/business/sales/out/edit/${this.d.id}` }) },
    handleSubmit () {
      this.$confirm(`确认提交出库单 ${this.d.out_no} 审核吗？提交后将由统一审批流程处理。`, '提交审核', { type: 'warning' }).then(async () => {
        this.submitting = true
        try {
          const r = await submitSalesOut(this.d.id)
          if (r.code === 0) { this.$message.success('已提交审核'); this.loadDetail(this.d.id) } else this.$message.error(r.msg || '提交失败')
        } catch (e) {} finally { this.submitting = false }
      }).catch(() => {})
    },
    handleConfirm () {
      this.$confirm(`确认出库单 ${this.d.out_no} 出库吗？系统将扣减产品库存、生成库存流水并回写销售订单，且不可撤回。`, '确认出库', { type: 'warning' }).then(async () => {
        this.confirming = true
        try {
          const r = await confirmSalesOut(this.d.id)
          if (r.code === 0) { this.$message.success(r.msg || '出库成功'); this.loadDetail(this.d.id) } else this.$message.error(r.msg || '操作失败')
        } catch (e) {} finally { this.confirming = false }
      }).catch(() => {})
    },
    handleGenShip () {
      this.$confirm(`确认由出库单 ${this.d.out_no} 生成发货单吗？系统将自动生成草稿发货单（带入客户/明细/收货/物流信息）。`, '生成发货单', { type: 'warning' }).then(async () => {
        try {
          const r = await generateShip(this.d.id)
          if (r.code === 0) {
            this.$message.success(r.msg || '发货单已生成')
            if (r.data && r.data.id) this.$router.push({ path: `/business/sales/ship/detail/${r.data.id}` })
          } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleShip () {
      this.$refs.shipForm.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.shipping = true
        shipSalesOut(this.d.id, this.shipForm).then(r => {
          if (r.code === 0) { this.$message.success('发货已登记'); this.shipVisible = false; this.loadDetail(this.d.id) } else this.$message.error(r.msg || '操作失败')
        }).catch(() => {}).finally(() => { this.shipping = false })
      })
    },
    handlePrint () { window.print() }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-title { font-size: 18px; font-weight: bold; }
.form-card { margin-bottom: 16px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
