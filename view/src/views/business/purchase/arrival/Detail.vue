<!--
  文件：admin/src/views/business/purchase/arrival/Detail.vue
  功能：到货单详情（信息/明细/质检操作/通知历史）
  权限：business:purchase:arrival:view/quality/notice/warehouse/edit
-->
<template>
  <div class="ar-detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购到货</el-breadcrumb-item>
      <el-breadcrumb-item>到货单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">到货单详情 - {{ arrival.arrival_no || '' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/business/purchase/arrival/list')">返回列表</el-button>
        <el-button v-if="arrival.status === 0 || arrival.status === 1" v-permission="'business:purchase:arrival:edit'" size="small" @click="$router.push('/business/purchase/arrival/add?id=' + id)">编辑</el-button>
        <el-button v-permission="'business:purchase:arrival:notice'" size="small" @click="openNotice">到货通知</el-button>
        <el-button v-if="arrival.status === 2 || arrival.status === 4" v-permission="'business:purchase:arrival:warehouse'" type="primary" size="small" @click="$router.push('/warehouse/parts/purchase-in/add?arrival_id=' + id)">生成入库单</el-button>
        <el-button size="small" @click="$print ? '' : windowPrint()">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" v-loading="loading">
      <template v-if="loadFailed">
        <el-empty description="加载失败，请刷新重试">
          <el-button size="small" @click="$router.push('/business/purchase/arrival/list')">返回列表</el-button>
        </el-empty>
      </template>
      <template v-else-if="arrival.id">
        <!-- 到货单信息 -->
        <div class="section-title">到货单信息</div>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="到货单编号">{{ arrival.arrival_no }}</el-descriptions-item>
          <el-descriptions-item label="到货状态"><el-tag size="mini" :type="statusTag(arrival.status)">{{ arrival.status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="关联采购订单">
            <span class="link" @click="$router.push('/business/purchase/order/detail/' + arrival.order_id)">{{ arrival.order_no }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="供应商">{{ arrival.supplier_name }}</el-descriptions-item>
          <el-descriptions-item label="到货日期">{{ arrival.arrival_date }}</el-descriptions-item>
          <el-descriptions-item label="收货人">{{ arrival.receiver }}</el-descriptions-item>
          <el-descriptions-item label="物流公司">{{ arrival.logistics_company || '-' }}</el-descriptions-item>
          <el-descriptions-item label="物流单号">{{ arrival.track_no || '-' }}</el-descriptions-item>
          <el-descriptions-item label="质检结果备注" :span="2">{{ arrival.quality_remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ arrival.remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ arrival.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ arrival.create_time || '-' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 入库进度 -->
        <div class="section-title">入库进度</div>
        <div class="in-progress-box">
          <el-progress :percentage="Number(arrival.in_progress || 0)" :stroke-width="16" :text-inside="true" />
          <div class="in-progress-text">已入库 {{ Number(arrival.received_quantity || 0) }} / 到货总数 {{ Number(arrival.arrival_total_quantity || 0) }}（{{ arrival.in_status_text || '-' }}）</div>
        </div>
        <el-table :data="relatedIns" size="small" border empty-text="暂无关联入库单">
          <el-table-column label="入库单编号" width="170">
            <template slot-scope="s"><span class="link" @click="$router.push('/warehouse/parts/purchase-in/detail/' + s.row.id)">{{ s.row.in_no }}</span></template>
          </el-table-column>
          <el-table-column prop="in_date" label="入库日期" width="120" />
          <el-table-column label="入库数量" width="110" align="right"><template slot-scope="s">{{ Number(s.row.in_quantity || 0).toLocaleString() }}</template></el-table-column>
          <el-table-column prop="receiver_name" label="入库人" width="110" />
          <el-table-column label="状态" width="90"><template slot-scope="s"><el-tag size="mini">{{ s.row.status_label }}</el-tag></template></el-table-column>
        </el-table>

        <!-- 到货物料明细 -->
        <div class="section-title">到货物料明细</div>
        <el-table :data="items" size="small" border>
          <el-table-column type="index" label="序号" width="55" align="center" />
          <el-table-column prop="product_code" label="产品编码" width="120" show-overflow-tooltip />
          <el-table-column prop="product_name" label="产品名称" min-width="130" show-overflow-tooltip />
          <el-table-column prop="product_spec" label="规格型号" width="100" show-overflow-tooltip />
          <el-table-column prop="product_unit" label="单位" width="55" align="center" />
          <el-table-column prop="order_quantity" label="订单数量" width="85" align="right" />
          <el-table-column prop="arrival_quantity" label="到货数量" width="85" align="right" />
          <el-table-column prop="qualified_quantity" label="合格数量" width="85" align="right" />
          <el-table-column prop="unqualified_quantity" label="不合格数量" width="90" align="right" />
          <el-table-column label="质检状态" width="90" align="center">
            <template slot-scope="s"><el-tag size="mini" :type="qualityTag(s.row.quality_status)">{{ qualityLabel(s.row.quality_status) }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="unqualified_reason" label="不合格原因" min-width="120" show-overflow-tooltip />
        </el-table>

        <!-- 质检操作 -->
        <template v-if="arrival.status === 0 || arrival.status === 1">
          <div class="section-title">质检操作</div>
          <el-table :data="items" size="small" border>
            <el-table-column type="index" label="序号" width="55" align="center" />
            <el-table-column prop="product_name" label="产品" min-width="150" show-overflow-tooltip />
            <el-table-column prop="arrival_quantity" label="到货数量" width="90" align="right" />
            <el-table-column label="合格数量" width="110">
              <template slot-scope="s">
                <el-input-number v-model="s.row.qualified_quantity" :min="0" :precision="0" :max="s.row.arrival_quantity" size="small" style="width:100%" @change="v => onQualifiedChange(s.$index, v)" />
              </template>
            </el-table-column>
            <el-table-column label="不合格数量" width="90" align="right">
              <template slot-scope="s">{{ Number(s.row.arrival_quantity) - Number(s.row.qualified_quantity) }}</template>
            </el-table-column>
            <el-table-column label="不合格原因" min-width="160">
              <template slot-scope="s">
                <el-input v-model="s.row.unqualified_reason" size="small" placeholder="不合格时填写原因" />
              </template>
            </el-table-column>
          </el-table>
          <div class="quality-btns">
            <el-button type="success" size="small" :loading="qualitySaving" @click="submitQuality('pass')">质检通过（全部合格）</el-button>
            <el-button type="danger" size="small" :loading="qualitySaving" @click="submitQuality('fail')">质检不通过</el-button>
          </div>
        </template>

        <!-- 通知历史 -->
        <div class="section-title">通知历史</div>
        <el-table :data="notices" size="small" border empty-text="暂无通知记录">
          <el-table-column prop="notice_type_label" label="通知类型" width="110" align="center" />
          <el-table-column prop="target_user_name" label="通知对象" width="120" />
          <el-table-column prop="notice_way_label" label="通知方式" width="100" align="center" />
          <el-table-column label="发送状态" width="90" align="center">
            <template slot-scope="s"><el-tag size="mini" :type="s.row.send_status === 1 ? 'success' : (s.row.send_status === 2 ? 'danger' : 'info')">{{ s.row.send_status_label }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="content" label="内容" min-width="180" show-overflow-tooltip />
          <el-table-column prop="send_time" label="发送时间" width="160" />
        </el-table>
      </template>
    </el-card>

    <!-- 到货通知对话框 -->
    <el-dialog title="发送到货通知" :visible="noticeVisible" @update:visible="v => noticeVisible = v" width="560px" top="6vh">
      <el-form label-width="90px" size="small">
        <el-form-item label="通知对象">
          <div v-if="noticeOwner.id" class="notice-target"><el-checkbox :checked="true" disabled>{{ noticeOwner.name }}（采购专员）</el-checkbox></div>
          <div v-if="noticeDemander.id" class="notice-target"><el-checkbox v-model="noticeDemander.checked">{{ noticeDemander.name }}（需求人）</el-checkbox></div>
          <el-select v-model="noticeInspector" filterable clearable placeholder="选择质检员（可选）" style="width:100%;margin-top:6px;">
            <el-option v-for="u in userOptions" :key="u.id" :label="(u.real_name || u.username) + '（' + u.username + '）'" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="通知方式">
          <el-checkbox-group v-model="noticeChannels">
            <el-checkbox label="inbox">站内信</el-checkbox>
            <el-checkbox label="email">邮件</el-checkbox>
            <el-checkbox label="sms">短信</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="通知内容">
          <el-input v-model="noticeContent" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="noticeVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="noticeSending" @click="submitNotice">发送</el-button>
      </span>
    </el-dialog>

    <!-- 质检不通过 - 退货处理 -->
    <el-dialog title="质检不通过处理" :visible="rejectVisible" @update:visible="v => rejectVisible = v" width="460px" top="8vh">
      <el-alert type="warning" :closable="false" show-icon title="存在质检不合格项，请选择处理方式" style="margin-bottom:12px" />
      <div class="reject-opts">
        <el-button type="danger" size="small" @click="handleRejectReturn">生成退货单</el-button>
        <el-button size="small" @click="handleRejectRecord">仅记录不合格</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  getArrivalDetail, qualityArrival, warehouseArrival, sendArrivalNotice
} from '../../../../api/purchase'
import { getUserList } from '../../../../api/user'

export default {
  name: 'PurchaseArrivalDetail',
  data () {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false, loadFailed: false,
      arrival: {}, items: [], notices: [], relatedIns: [], qualitySaving: false,
      rejectVisible: false,
      noticeVisible: false, noticeSending: false, noticeOwner: {}, noticeDemander: { checked: true }, noticeInspector: null,
      noticeChannels: ['inbox'], noticeContent: '', userOptions: []
    }
  },
  created () { this.fetchDetail() },
  methods: {
    async fetchDetail () {
      this.loading = true
      this.loadFailed = false
      try {
        const r = await getArrivalDetail(this.id)
        if (r.code === 0 && r.data) {
          this.arrival = r.data.arrival || {}
          this.items = (r.data.items || []).map(it => ({ ...it, qualified_quantity: Number(it.qualified_quantity) || Number(it.arrival_quantity) || 0, unqualified_reason: it.unqualified_reason || '' }))
          this.relatedIns = r.data.related_ins || []
          this.notices = r.data.notices || []
        } else {
          this.loadFailed = true
        }
      } catch (e) { this.loadFailed = true } finally { this.loading = false }
    },
    statusTag (v) { return { 0: 'info', 1: 'primary', 2: 'success', 3: 'danger', 4: 'warning', 5: 'success' }[v] || 'info' },
    qualityTag (v) { return { 0: 'info', 1: 'success', 2: 'danger' }[v] || 'info' },
    qualityLabel (v) { return { 0: '待检', 1: '合格', 2: '不合格' }[v] || '未知' },
    onQualifiedChange (idx, v) {
      const it = this.items[idx]
      if (it && Number(v) > Number(it.arrival_quantity)) {
        it.qualified_quantity = Number(it.arrival_quantity)
        this.$message.warning('合格数量不能超过到货数量')
      }
    },
    windowPrint () { window.print() },
    async submitQuality (type) {
      if (type === 'fail') {
        const hasUnqualified = this.items.some(it => Number(it.arrival_quantity) - Number(it.qualified_quantity) > 0)
        if (!hasUnqualified) { this.$message.warning('没有不合格项，请调整合格数量或选择"质检通过"'); return }
      }
      this.qualitySaving = true
      try {
        const payload = {
          type,
          quality_remark: type === 'pass' ? '质检通过' : '质检不通过',
          items: this.items.map(it => ({
            item_id: it.id,
            unqualified_quantity: Number(it.arrival_quantity) - Number(it.qualified_quantity),
            reason: it.unqualified_reason || ''
          }))
        }
        const r = await qualityArrival(this.id, payload)
        if (r.code === 0) {
          this.$message.success(r.msg || '操作成功')
          if (type === 'fail') { this.rejectVisible = true } else { this.fetchDetail() }
        } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.qualitySaving = false }
    },
    handleRejectReturn () {
      this.rejectVisible = false
      this.fetchDetail()
      this.$message.info('退货单模块待接入，不合格项已记录，状态为质检不合格')
    },
    handleRejectRecord () {
      this.rejectVisible = false
      this.fetchDetail()
      this.$message.success('已记录不合格，状态为质检不合格')
    },
    handleWarehouse () {
      this.$confirm('确认生成入库单？到货单将变为"待入库"。', '生成入库单', { type: 'info' }).then(async () => {
        try {
          const r = await warehouseArrival(this.id)
          if (r.code === 0) { this.$message.success(r.msg || '已生成入库单'); this.fetchDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async openNotice () {
      this.noticeOwner = {}; this.noticeDemander = { checked: true }; this.noticeInspector = null
      this.noticeChannels = ['inbox']
      this.noticeContent = `您负责的订单 ${this.arrival.order_no} 已到货，请及时安排质检。`
      this.noticeVisible = true
      try {
        const r = await getArrivalDetail(this.id)
        if (r.code === 0) {
          this.noticeOwner = r.data.purchase_owner || {}
          this.noticeDemander = { ...(r.data.demander || {}), checked: true }
        }
      } catch (e) {}
      try {
        const u = await getUserList({ page: 1, limit: 200 })
        this.userOptions = (u.data && u.data.list) || []
      } catch (e) { this.userOptions = [] }
    },
    async submitNotice () {
      if (!this.noticeChannels.length) { this.$message.warning('请选择通知方式'); return }
      const targets = []
      if (this.noticeOwner.id) targets.push({ user_id: this.noticeOwner.id })
      if (this.noticeDemander.id && this.noticeDemander.checked) targets.push({ user_id: this.noticeDemander.id })
      if (this.noticeInspector) targets.push({ user_id: this.noticeInspector })
      if (!targets.length) { this.$message.warning('请选择通知对象'); return }
      this.noticeSending = true
      try {
        const r = await sendArrivalNotice(this.id, { notice_type: 1, content: this.noticeContent, targets, channels: this.noticeChannels })
        if (r.code === 0) { this.$message.success(r.msg || '通知已发送'); this.noticeVisible = false; this.fetchDetail() }
        else this.$message.error(r.msg || '发送失败')
      } catch (e) {} finally { this.noticeSending = false }
    }
  }
}
</script>

<style scoped>
.ar-detail-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.section-title { font-size: 15px; font-weight: 600; margin: 16px 0 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; display: inline-block; vertical-align: middle; }
.in-progress-box { max-width: 420px; margin-bottom: 10px; }
.in-progress-text { font-size: 13px; color: #606266; margin-top: 6px; }
.link { color: #409EFF; cursor: pointer; }
.quality-btns { margin-top: 12px; }
.notice-target { margin-bottom: 6px; }
.reject-opts { text-align: right; }
</style>
