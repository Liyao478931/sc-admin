<template>
  <div class="tp-page">
    <el-breadcrumb separator="/" class="tp-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产调拨</el-breadcrumb-item>
      <el-breadcrumb-item>待确认调拨</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- Tab切换 -->
    <div class="tp-tabs">
      <el-tabs v-model="activeTab" @tab-click="handleTabChange">
        <el-tab-pane :label="'待确认 (' + (stats.pending || 0) + ')'" name="0" />
        <el-tab-pane :label="'已确认 (' + (stats.confirmed || 0) + ')'" name="1" />
        <el-tab-pane :label="'已拒绝 (' + (stats.rejected || 0) + ')'" name="2" />
      </el-tabs>
    </div>

    <!-- 操作栏 -->
    <div class="tp-toolbar">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <span class="tp-total">共 {{ total }} 条</span>
    </div>

    <!-- 列表 -->
    <div v-loading="loading" class="tp-list">
      <template v-if="list.length">
        <div v-for="t in list" :key="t.id" class="tp-item">
          <div class="tp-item-head">
            <span class="tp-no">{{ t.transfer_no }}</span>
            <span class="tp-date">{{ String(t.created_at).slice(0, 16) }}</span>
          </div>
          <div class="tp-item-body">
            <div class="tp-line"><span class="tp-lb">申请人</span>{{ t.initiator_id === t.from_user_id ? t.from_name : t.to_name }}</div>
            <div class="tp-line"><span class="tp-lb">资产</span>{{ t.asset_name }}（{{ t.specification || '-' }}）{{ t.transfer_quantity }} {{ t.unit }}</div>
            <div class="tp-line"><span class="tp-lb">方向</span>{{ t.from_name }} → {{ t.to_name }}</div>
            <div v-if="t.purpose" class="tp-line"><span class="tp-lb">用途</span>{{ t.purpose }}</div>
            <div v-if="t.reject_reason" class="tp-line" style="color:#F56C6C"><span class="tp-lb">拒绝原因</span>{{ t.reject_reason }}</div>
            <div class="tp-line"><span class="tp-lb">状态</span><el-tag :type="statusType(Number(t.status))" size="mini">{{ statusLabel(Number(t.status)) }}</el-tag></div>
          </div>
          <div class="tp-item-actions">
            <el-button v-if="Number(t.status) === 0" type="text" size="mini" style="color:#67C23A" @click="handleConfirm(t)">确认</el-button>
            <el-button v-if="Number(t.status) === 0" type="text" size="mini" style="color:#F56C6C" @click="handleReject(t)">拒绝</el-button>
            <el-button type="text" size="mini" @click="openDetail(t)">查看详情</el-button>
          </div>
        </div>
      </template>
      <div v-else class="tp-empty">
        <i class="el-icon-message tp-empty-icon"></i>
        <div class="tp-empty-title">暂无{{ statusLabel(Number(activeTab)) }}调拨记录</div>
      </div>
    </div>

    <!-- 分页 -->
    <div class="tp-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 拒绝弹窗 -->
    <el-dialog title="拒绝调拨" :visible.sync="rejectVisible" width="440px">
      <el-form label-width="80px" size="small">
        <el-form-item label="拒绝原因">
          <el-input v-model="rejectReason" type="textarea" :rows="2" placeholder="请填写拒绝原因（选填）" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="rejectVisible = false">取消</el-button>
        <el-button size="small" type="danger" :loading="submitting" @click="submitReject">确认拒绝</el-button>
      </div>
    </el-dialog>

    <!-- 详情弹窗 -->
    <el-dialog :title="'调拨详情 - ' + (detail.transfer_no || '')" :visible.sync="detailVisible" width="600px">
      <div class="tp-detail-body">
        <template v-if="detail.id">
          <div class="tp-detail-sec">
            <div class="tp-detail-title">调拨信息</div>
            <div class="tp-detail-grid">
              <div class="tp-detail-item"><span class="tp-detail-lb">调拨单号</span>{{ detail.transfer_no }}</div>
              <div class="tp-detail-item"><span class="tp-detail-lb">状态</span><el-tag :type="statusType(Number(detail.status))" size="mini">{{ statusLabel(Number(detail.status)) }}</el-tag></div>
              <div class="tp-detail-item"><span class="tp-detail-lb">申请时间</span>{{ detail.created_at }}</div>
              <div class="tp-detail-item"><span class="tp-detail-lb">确认时间</span>{{ detail.confirm_time || '-' }}</div>
            </div>
          </div>
          <div class="tp-detail-sec">
            <div class="tp-detail-title">资产信息</div>
            <div class="tp-detail-grid">
              <div class="tp-detail-item"><span class="tp-detail-lb">资产名称</span>{{ detail.asset_name }}</div>
              <div class="tp-detail-item"><span class="tp-detail-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="tp-detail-item"><span class="tp-detail-lb">资产编码</span>{{ detail.asset_code || '-' }}</div>
              <div class="tp-detail-item"><span class="tp-detail-lb">调拨数量</span>{{ detail.transfer_quantity }} {{ detail.unit }}</div>
            </div>
          </div>
          <div class="tp-detail-sec">
            <div class="tp-detail-title">人员信息</div>
            <div class="tp-detail-grid">
              <div class="tp-detail-item"><span class="tp-detail-lb">调出人</span>{{ detail.from_name }}</div>
              <div class="tp-detail-item"><span class="tp-detail-lb">接收人</span>{{ detail.to_name }}</div>
            </div>
          </div>
          <div v-if="detail.purpose" class="tp-detail-sec">
            <div class="tp-detail-title">用途说明</div>
            <div class="tp-detail-remark">{{ detail.purpose }}</div>
          </div>
        </template>
      </div>
      <div slot="footer"><el-button size="small" @click="detailVisible = false">关闭</el-button></div>
    </el-dialog>
  </div>
</template>

<script>
import { getPendingTransfers, confirmTransfer, rejectTransfer } from '../../api/personalAssets'

export default {
  name: 'TransferPending',
  data () {
    return {
      activeTab: '0',
      stats: { pending: 0, confirmed: 0, rejected: 0 },
      list: [], total: 0, page: 1, limit: 20, loading: false,
      rejectVisible: false, rejectReason: '', submitting: false, currentTransfer: {},
      detailVisible: false, detail: {}
    }
  },
  created () { this.getList() },
  methods: {
    statusLabel (s) { return { 0: '待确认', 1: '已确认', 2: '已拒绝' }[s] || '未知' },
    statusType (s) { return { 0: 'warning', 1: 'success', 2: 'danger' }[s] || 'info' },
    handleTabChange () { this.page = 1; this.getList() },
    async getList () {
      this.loading = true
      try {
        const r = await getPendingTransfers({ status: this.activeTab, page: this.page, limit: this.limit })
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.statistics || { pending: 0, confirmed: 0, rejected: 0 }
        }
      } catch (e) {}
      this.loading = false
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    handleConfirm (t) {
      this.$confirm('确认接收该调拨申请吗？确认后资产将自动转移。', '确认', { type: 'warning' }).then(async () => {
        try {
          const r = await confirmTransfer({ transfer_id: t.id })
          if (r.code === 0) { this.$message.success('调拨确认成功，资产已转移'); this.getList() }
        } catch (e) {}
      }).catch(() => {})
    },
    handleReject (t) {
      this.currentTransfer = t
      this.rejectReason = ''
      this.rejectVisible = true
    },
    async submitReject () {
      this.submitting = true
      try {
        const r = await rejectTransfer({ transfer_id: this.currentTransfer.id, reason: this.rejectReason })
        if (r.code === 0) { this.$message.success('已拒绝该调拨申请'); this.rejectVisible = false; this.getList() }
      } catch (e) {}
      this.submitting = false
    },
    openDetail (t) {
      this.detail = t
      this.detailVisible = true
    }
  }
}
</script>

<style scoped>
.tp-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.tp-breadcrumb { margin-bottom: 12px; }
.tp-tabs { background: #fff; border-radius: 8px; padding: 0 16px; margin-bottom: 12px; }
.tp-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.tp-total { margin-left: 12px; color: #909399; font-size: 13px; }
.tp-list { display: flex; flex-direction: column; gap: 12px; }
.tp-item { background: #fff; border-radius: 10px; border: 1px solid #ebeef5; padding: 14px 16px; }
.tp-item-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.tp-no { font-size: 15px; font-weight: 700; color: #409EFF; }
.tp-date { font-size: 12px; color: #909399; }
.tp-item-body { display: flex; flex-direction: column; gap: 4px; }
.tp-line { font-size: 13px; color: #303133; }
.tp-lb { color: #909399; width: 60px; display: inline-block; }
.tp-item-actions { display: flex; justify-content: flex-end; margin-top: 8px; gap: 4px; }
.tp-empty { text-align: center; padding: 60px 0; background: #fff; border-radius: 10px; }
.tp-empty-icon { font-size: 48px; color: #dcdfe6; }
.tp-empty-title { font-size: 16px; color: #606266; font-weight: 600; margin-top: 12px; }
.tp-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }
.tp-detail-body { min-height: 150px; }
.tp-detail-sec { margin-bottom: 16px; }
.tp-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.tp-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.tp-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.tp-detail-lb { color: #909399; width: 70px; flex-shrink: 0; }
.tp-detail-remark { font-size: 13px; color: #4b5a6c; line-height: 1.7; }
</style>