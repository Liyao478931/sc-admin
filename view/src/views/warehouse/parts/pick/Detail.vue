<!--
  文件：admin/src/views/warehouse/parts/pick/Detail.vue
  功能：领料单详情（信息/明细/流水/操作日志时间轴/状态操作）
  权限：warehouse:pick:view/edit/audit/confirm/version:view/version:restore
-->
<template>
  <div class="detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>配件领用</el-breadcrumb-item>
      <el-breadcrumb-item>领料单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="detail-header">
      <span class="detail-title">领料单详情 - {{ detail.pick_no || '...' }}</span>
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push('/warehouse/parts/pick/list')">返回列表</el-button>
        <el-button v-if="detail.status === 0 || detail.status === 4" v-permission="'warehouse:pick:edit'" size="small" type="primary" icon="el-icon-edit" @click="$router.push('/warehouse/parts/pick/edit/' + id)">编辑</el-button>
        <el-button v-if="detail.status === 0" size="small" icon="el-icon-check" @click="doAction(submitPick(id), '已提交审核')">提交审核</el-button>
        <el-button v-if="detail.status === 1" v-permission="'warehouse:pick:audit'" size="small" type="success" icon="el-icon-check" @click="auditVisible = true">审核通过</el-button>
        <el-button v-if="detail.status === 1" v-permission="'warehouse:pick:audit'" size="small" type="danger" plain icon="el-icon-close" @click="rejectVisible = true">审核驳回</el-button>
        <el-button v-if="detail.status === 2" v-permission="'warehouse:pick:confirm'" size="small" type="primary" icon="el-icon-sold-out" :loading="confirming" @click="doConfirm">确认发料</el-button>
        <el-button size="small" icon="el-icon-time" @click="openVersions">版本历史</el-button>
        <el-button size="small" icon="el-icon-printer" @click="handlePrint">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head">
        <span>领料单信息</span>
        <el-tag :type="detail.status_tag" size="mini" style="margin-left:8px">{{ detail.status_label }}</el-tag>
        <el-tag type="success" size="mini" style="margin-left:6px">{{ detail.version_no }}</el-tag>
      </div>
      <el-descriptions v-if="detail.pick_no" :column="2" border size="small">
        <el-descriptions-item label="领料单编号">{{ detail.pick_no }}</el-descriptions-item>
        <el-descriptions-item label="领料类型"><el-tag :type="detail.pick_type_tag" size="mini">{{ detail.pick_type_label }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="关联工单"><span class="link" @click="goWorkOrder">{{ detail.work_order_no || '-' }}</span></el-descriptions-item>
        <el-descriptions-item label="领料部门">{{ detail.department_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="领料人">{{ detail.picker_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="领料日期">{{ detail.pick_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="当前版本">{{ detail.version_no }}</el-descriptions-item>
        <el-descriptions-item label="审核人">{{ detail.auditor_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核时间">{{ detail.audit_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核备注">{{ detail.audit_remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="用途说明" :span="2">{{ detail.purpose || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ detail.created_by_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detail.create_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ detail.update_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>领料明细</span></div>
      <el-table :data="items" size="small" border empty-text="暂无明细">
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="material_code" label="物料编码" width="110" />
        <el-table-column prop="material_name" label="物料名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="spec" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="55" align="center" />
        <el-table-column label="当前库存" width="90" align="right"><template slot-scope="s">{{ Number(s.row.current_stock || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="申请数量" width="90" align="right"><template slot-scope="s">{{ Number(s.row.apply_quantity || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="实际领料" width="90" align="right"><template slot-scope="s">{{ Number(s.row.actual_quantity || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="已退库数量" width="100" align="right"><template slot-scope="s">{{ Number(s.row.returned_quantity || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="可退库数量" width="100" align="right"><template slot-scope="s"><span :class="{ 'returnable-zero': !(s.row.returnable_quantity > 0) }">{{ Number(s.row.returnable_quantity || 0).toLocaleString() }}</span></template></el-table-column>
        <el-table-column label="出库单价" width="100" align="right"><template slot-scope="s">{{ detail.status === 3 ? '¥ ' + Number(s.row.out_price || 0).toFixed(4) : '-' }}</template></el-table-column>
        <el-table-column label="出库总价" width="110" align="right"><template slot-scope="s">{{ detail.status === 3 ? '¥ ' + Number(s.row.out_total || 0).toFixed(2) : '-' }}</template></el-table-column>
        <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip />
      </el-table>
    </el-card>

    <!-- 退库进度 -->
    <el-card v-if="returnOrders && returnOrders.length" shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>退库进度</span></div>
      <div class="return-progress">
        <el-progress :percentage="returnProgress" :stroke-width="14" :color="returnProgress >= 100 ? '#67C23A' : '#409EFF'" />
        <div class="return-summary">已退库 {{ returnedTotal }} / 领料 {{ pickTotal }}</div>
      </div>
      <el-table :data="returnOrders" size="small" border>
        <el-table-column label="退库单编号" width="160">
          <template slot-scope="s"><el-link type="primary" @click="goReturnDetail(s.row)">{{ s.row.return_no }}</el-link></template>
        </el-table-column>
        <el-table-column label="退库类型" width="100" align="center"><template slot-scope="s">{{ returnTypeText(s.row.return_type) }}</template></el-table-column>
        <el-table-column prop="return_date" label="退库日期" width="110" align="center" />
        <el-table-column label="退库数量" width="100" align="right"><template slot-scope="s">{{ Number(s.row.total_quantity || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template slot-scope="s"><el-tag :type="s.row.status === 3 ? 'success' : (s.row.status === 4 ? 'danger' : (s.row.status === 1 ? 'warning' : 'info'))" size="mini">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card v-if="detail.status === 3" shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>库存流水</span></div>
      <el-table :data="flows" size="small" border empty-text="暂无流水">
        <el-table-column prop="material_name" label="物料名称" min-width="120" show-overflow-tooltip />
        <el-table-column label="变动类型" width="90"><template slot-scope="s">生产领料</template></el-table-column>
        <el-table-column label="变动数量" width="90" align="right"><template slot-scope="s">{{ Number(s.row.flow_quantity || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="成本单价" width="100" align="right"><template slot-scope="s">¥ {{ Number(s.row.cost_price || 0).toFixed(4) }}</template></el-table-column>
        <el-table-column label="成本总价" width="110" align="right"><template slot-scope="s">¥ {{ Number(s.row.cost_total || 0).toFixed(2) }}</template></el-table-column>
        <el-table-column label="变动前库存" width="100" align="right"><template slot-scope="s">{{ Number(s.row.before_stock || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="变动后库存" width="100" align="right"><template slot-scope="s">{{ Number(s.row.after_stock || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column prop="operator_name" label="操作人" width="90" />
        <el-table-column prop="flow_time" label="变动时间" width="160" />
      </el-table>
    </el-card>

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>操作日志</span><span class="log-count">共 {{ logs.length }} 条</span></div>
      <el-timeline>
        <el-timeline-item v-for="l in logs" :key="l.id" :timestamp="l.action_time" placement="top">
          <div class="log-item">
            <span class="log-op">{{ l.operator_name }}</span>
            <el-tag :type="actionTag(l.action_type)" size="mini">{{ l.action_label }}</el-tag>
            <span v-if="l.from_status !== null && l.from_status !== undefined" class="log-status">{{ statusText(l.from_status) }} → {{ statusText(l.to_status) }}</span>
            <div v-if="l.remark" class="log-remark">{{ l.remark }}</div>
          </div>
        </el-timeline-item>
      </el-timeline>
    </el-card>

    <el-dialog title="审核通过" :visible="auditVisible" @update:visible="v => auditVisible = v" width="460px" top="8vh">
      <el-input v-model="auditRemark" type="textarea" :rows="3" placeholder="审核备注（可选）" />
      <span slot="footer">
        <el-button size="small" @click="auditVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="acting" @click="doApprove">确认通过</el-button>
      </span>
    </el-dialog>
    <el-dialog title="审核驳回" :visible="rejectVisible" @update:visible="v => rejectVisible = v" width="460px" top="8vh">
      <el-input v-model="rejectReason" type="textarea" :rows="3" placeholder="请填写驳回原因（必填）" />
      <span slot="footer">
        <el-button size="small" @click="rejectVisible = false">取消</el-button>
        <el-button size="small" type="danger" :loading="acting" @click="doReject">确认驳回</el-button>
      </span>
    </el-dialog>

    <el-dialog :title="'版本历史 - ' + detail.pick_no" :visible="verVisible" @update:visible="v => verVisible = v" width="760px" top="6vh">
      <el-table :data="versions" size="small" border :row-class-name="rowCls">
        <el-table-column prop="version_no" label="版本号" width="110" align="center" />
        <el-table-column prop="change_summary" label="变更摘要" min-width="180" />
        <el-table-column prop="operator_name" label="操作人" width="100" />
        <el-table-column prop="create_time" label="修改时间" width="160" />
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="s">
            <el-button v-permission="'warehouse:pick:version:restore'" v-if="!s.row.is_current" type="text" size="mini" class="danger" @click="doRestore(s.row)">恢复</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>
  </div>
</template>

<script>
import { getPickDetail, submitPick, approvePick, rejectPick, confirmPick, getPickVersions, restorePickVersion } from '../../../../api/warehouse'

const ACTION_TAG = { 1: 'success', 2: 'primary', 3: 'warning', 4: 'success', 5: 'danger', 6: 'warning', 7: 'info', 8: 'danger', 9: 'warning' }
const STATUS_TEXT = { 0: '草稿', 1: '待审核', 2: '已审核', 3: '已领料', 4: '已驳回', 5: '已撤销' }

export default {
  name: 'WarehousePickDetail',
  data () {
    return {
      id: Number(this.$route.params.id) || 0,
      detail: {}, items: [], flows: [], logs: [], returnOrders: [],
      auditVisible: false, rejectVisible: false, auditRemark: '', rejectReason: '', acting: false, confirming: false,
      verVisible: false, versions: []
    }
  },
  computed: {
    returnedTotal () {
      return this.items.reduce((s, it) => s + (Number(it.returned_quantity) || 0), 0)
    },
    pickTotal () {
      return this.items.reduce((s, it) => s + (Number(it.apply_quantity) || 0), 0)
    },
    returnProgress () {
      return this.pickTotal > 0 ? Math.min(100, Math.round(this.returnedTotal / this.pickTotal * 100)) : 0
    }
  },
  created () { this.load() },
  methods: {
    async load () {
      try {
        const r = await getPickDetail(this.id)
        if (r.code === 0 && r.data) {
          this.detail = r.data.pick || {}
          this.items = r.data.items || []
          this.flows = r.data.flows || []
          this.logs = r.data.logs || []
          this.returnOrders = r.data.return_orders || []
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    statusText (s) { return STATUS_TEXT[s] || '未知' },
    actionTag (t) { return ACTION_TAG[t] || 'info' },
    goWorkOrder () {
      if (this.detail.production_order_id) this.$router.push('/business/order/detail/' + this.detail.production_order_id)
      else if (this.detail.repair_order_id) this.$router.push('/business/order/detail/' + this.detail.repair_order_id)
    },
    returnTypeText (t) {
      return { 1: '生产退库', 2: '维修退库', 3: '质量退库', 4: '其他退库' }[t] || '未知'
    },
    goReturnDetail (row) { this.$router.push({ path: `/warehouse/parts/return/detail/${row.id}` }) },
    async doAction (promise, msg) {
      this.acting = true
      try {
        const r = await promise
        if (r.code === 0) { this.$message.success(msg); this.load() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    },
    doApprove () {
      this.$confirm('确认审核通过该领料单吗？', '提示').then(() => this.doAction(approvePick(this.id, this.auditRemark), '审核通过')).catch(() => {})
        .finally(() => { this.auditVisible = false })
    },
    doReject () {
      if (!this.rejectReason.trim()) { this.$message.warning('请填写驳回原因'); return }
      this.$confirm('确认驳回该领料单吗？', '提示', { type: 'warning' }).then(() => this.doAction(rejectPick(this.id, this.rejectReason), '已驳回')).catch(() => {})
        .finally(() => { this.rejectVisible = false })
    },
    async doConfirm () {
      this.$confirm('确认发料将扣减库存并生成流水，确认继续吗？', '确认发料', { type: 'warning' }).then(async () => {
        this.$message({ message: '正在处理发料，请稍候...', type: 'info', duration: 0 })
        this.confirming = true
        try {
          const r = await confirmPick(this.id)
          this.$message.closeAll()
          if (r.code === 0) { this.$message.success(r.msg || '发料成功'); this.load() } else this.$message.error(r.msg || '发料失败')
        } catch (e) { this.$message.closeAll() } finally { this.confirming = false }
      }).catch(() => {})
    },
    async openVersions () {
      try {
        const r = await getPickVersions(this.id)
        if (r.code === 0 && r.data) { this.versions = r.data.list || []; this.verVisible = true } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    rowCls ({ row }) { return row.is_current ? 'current-version' : '' },
    doRestore (v) {
      this.$confirm(`确认恢复到 ${v.version_no} 吗？当前数据将被覆盖`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await restorePickVersion(this.id, v.version_no)
          if (r.code === 0) { this.$message.success(r.msg || '已恢复'); this.openVersions(); this.load() } else this.$message.error(r.msg || '恢复失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handlePrint () { window.print() }
  }
}
</script>

<style scoped>
.detail-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.detail-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.detail-title { font-size: 18px; font-weight: 700; color: #303133; }
.info-card { margin-bottom: 14px; }
.card-head { font-size: 15px; font-weight: 600; display: flex; align-items: center; }
.log-count { font-size: 12px; color: #909399; font-weight: 400; margin-left: 8px; }
.log-item { font-size: 13px; }
.log-op { font-weight: 600; margin-right: 8px; }
.log-status { margin-left: 8px; color: #606266; }
.log-remark { color: #909399; margin-top: 4px; }
.link { color: #409EFF; cursor: pointer; }
.return-progress { margin-bottom: 14px; }
.return-summary { color: #909399; font-size: 13px; margin-top: 6px; }
.returnable-zero { color: #c0c4cc; }
/deep/ .current-version { background: #f0f9eb; }
</style>
