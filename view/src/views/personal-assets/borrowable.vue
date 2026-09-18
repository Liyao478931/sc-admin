<template>
  <div class="bb-page">
    <el-breadcrumb separator="/" class="bb-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产调拨</el-breadcrumb-item>
      <el-breadcrumb-item>可借用资产</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="bb-banner">
      <i class="el-icon-info bb-banner-icon"></i>
      <span class="bb-banner-text">可借用资产：同部门同事名下可调拨/借用的物资汇总。借用后需经保管人确认。</span>
      <i class="el-icon-close bb-banner-close" @click="closeBanner"></i>
    </div>

    <!-- 统计卡片 -->
    <div class="bb-stats">
      <div class="bb-stat-card">
        <div class="bb-stat-info">
          <div class="bb-stat-num" style="color:#409EFF">{{ stats.total_quantity }}</div>
          <div class="bb-stat-label">可借用总数量</div>
        </div>
        <div class="bb-stat-icon" style="background:#ecf5ff"><i class="el-icon-box" style="color:#409EFF"></i></div>
      </div>
      <div class="bb-stat-card">
        <div class="bb-stat-info">
          <div class="bb-stat-num" style="color:#67C23A">{{ stats.total_types }}</div>
          <div class="bb-stat-label">可借用种类</div>
        </div>
        <div class="bb-stat-icon" style="background:#f0f9eb"><i class="el-icon-document" style="color:#67C23A"></i></div>
      </div>
      <div class="bb-stat-card">
        <div class="bb-stat-info">
          <div class="bb-stat-num" style="color:#E6A23C">{{ stats.total_people }}</div>
          <div class="bb-stat-label">可借用人数</div>
        </div>
        <div class="bb-stat-icon" style="background:#fdf6ec"><i class="el-icon-user" style="color:#E6A23C"></i></div>
      </div>
    </div>

    <!-- 筛选区 -->
    <div class="bb-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="资产名称">
          <el-input v-model="query.keyword" placeholder="请输入资产名称" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="资产类型">
          <el-select v-model="query.asset_type" clearable placeholder="全部类型" style="width:120px" @change="handleSearch">
            <el-option label="物料/配件" :value="1" />
            <el-option label="固定资产" :value="2" />
            <el-option label="工具" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="资产状态">
          <el-select v-model="query.asset_status" clearable placeholder="全部状态" style="width:120px" @change="handleSearch">
            <el-option label="正常" :value="1" />
            <el-option label="维修中" :value="2" />
            <el-option label="闲置" :value="3" />
            <el-option label="待报废" :value="4" />
          </el-select>
        </el-form-item>
        <el-form-item label="保管人">
          <el-input v-model="query.keeper_name" placeholder="请输入保管人姓名" clearable style="width:130px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作栏 -->
    <div class="bb-toolbar">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <span class="bb-total">共 {{ total }} 项资产，涉及 {{ stats.total_people }} 位同事</span>
    </div>

    <!-- 资产卡片列表 -->
    <div v-loading="loading" class="bb-card-list">
      <template v-if="list.length">
        <div v-for="item in list" :key="item.id" class="bb-card" @click="openDetail(item)">
          <div class="bb-card-left">
            <div class="bb-card-name-row">
              <span class="bb-type-tag" :class="'type-' + item.asset_type">{{ item.asset_type_label }}</span>
              <span class="bb-card-name">{{ item.asset_name }}</span>
              <span v-if="item.specification" class="bb-card-spec">{{ item.specification }}</span>
            </div>
            <div class="bb-card-code">编码：{{ item.asset_code || '-' }}</div>
            <div class="bb-card-keeper">保管人：{{ item.keeper_name }}{{ item.keeper_no ? '（' + item.keeper_no + '）' : '' }}</div>
            <div class="bb-card-qty"><span class="bb-qty-num">{{ item.quantity }}</span> {{ item.unit }}</div>
          </div>
          <div class="bb-card-right">
            <span class="bb-status-tag" :class="'status-' + item.asset_status">{{ item.asset_status_label }}</span>
            <div class="bb-card-actions" @click.stop>
              <el-button type="text" size="mini" @click="handleApplyTransfer(item)">申请调拨</el-button>
              <el-button type="text" size="mini" @click="handleInitiateTransfer(item)">发起调拨</el-button>
            </div>
          </div>
        </div>
      </template>

      <!-- 空状态 -->
      <div v-else class="bb-empty">
        <i class="el-icon-message bb-empty-icon"></i>
        <div class="bb-empty-title">{{ isFiltered ? '未找到匹配资产' : '暂无可用资产' }}</div>
        <div class="bb-empty-desc">{{ isFiltered ? '请调整搜索条件后重试。' : '当前部门暂无同事名下有可借用资产。' }}</div>
        <el-button v-if="isFiltered" type="primary" @click="handleReset">重置筛选</el-button>
      </div>
    </div>

    <!-- 分页 -->
    <div class="bb-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 申请调拨弹窗 -->
    <el-dialog :title="'申请调拨 - ' + (transferAsset.asset_name || '')" :visible.sync="applyVisible" width="480px">
      <el-form label-width="90px" size="small">
        <el-form-item label="资产信息"><span>{{ transferAsset.asset_name }}（{{ transferAsset.specification || '-' }}）</span></el-form-item>
        <el-form-item label="保管人"><span>{{ transferAsset.keeper_name }}{{ transferAsset.keeper_no ? '（' + transferAsset.keeper_no + '）' : '' }}</span></el-form-item>
        <el-form-item label="当前数量"><span>{{ transferAsset.quantity }} {{ transferAsset.unit }}</span></el-form-item>
        <el-form-item label="调拨数量" required>
          <el-input-number v-model="transferForm.quantity" :min="1" :max="Number(transferAsset.quantity)" :precision="0" style="width:180px" />
        </el-form-item>
        <el-form-item label="用途说明" required>
          <el-input v-model="transferForm.purpose" type="textarea" :rows="2" placeholder="请说明调拨用途" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="transferForm.remark" type="textarea" :rows="2" placeholder="可选备注" />
        </el-form-item>
        <el-form-item>
          <div class="bb-tip">申请调拨：向保管人发起领用申请，待对方确认后资产自动转移。</div>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="applyVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="submitting" @click="submitTransfer('apply')">确认申请</el-button>
      </div>
    </el-dialog>

    <!-- 发起调拨弹窗 -->
    <el-dialog :title="'发起调拨 - ' + (transferAsset.asset_name || '')" :visible.sync="initiateVisible" width="480px">
      <el-form label-width="90px" size="small">
        <el-form-item label="资产信息"><span>{{ transferAsset.asset_name }}（{{ transferAsset.specification || '-' }}）</span></el-form-item>
        <el-form-item label="保管人"><span>{{ transferAsset.keeper_name }}{{ transferAsset.keeper_no ? '（' + transferAsset.keeper_no + '）' : '' }}</span></el-form-item>
        <el-form-item label="当前数量"><span>{{ transferAsset.quantity }} {{ transferAsset.unit }}</span></el-form-item>
        <el-form-item label="调拨数量" required>
          <el-input-number v-model="transferForm.quantity" :min="1" :max="Number(transferAsset.quantity)" :precision="0" style="width:180px" />
        </el-form-item>
        <el-form-item label="调拨说明" required>
          <el-input v-model="transferForm.purpose" type="textarea" :rows="2" placeholder="请说明调拨原因" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="transferForm.remark" type="textarea" :rows="2" placeholder="可选备注" />
        </el-form-item>
        <el-form-item>
          <div class="bb-tip">发起调拨：主动向保管人发起调拨，待对方确认后资产自动转移。</div>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="initiateVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="submitting" @click="submitTransfer('initiate')">确认发起</el-button>
      </div>
    </el-dialog>

    <!-- 资产详情弹窗（只读） -->
    <el-dialog :title="'资产详情 - ' + (detail.asset_name || '')" :visible.sync="detailVisible" width="560px">
      <div class="bb-detail-body">
        <template v-if="detail.id">
          <div class="bb-detail-section">
            <div class="bb-detail-title">基本信息</div>
            <div class="bb-detail-grid">
              <div class="bb-detail-item"><span class="bb-detail-lb">资产名称</span>{{ detail.asset_name || '-' }}</div>
              <div class="bb-detail-item"><span class="bb-detail-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="bb-detail-item"><span class="bb-detail-lb">资产编码</span>{{ detail.asset_code || '-' }}</div>
              <div class="bb-detail-item"><span class="bb-detail-lb">类型</span><span class="bb-type-tag" :class="'type-' + detail.asset_type">{{ detail.asset_type_label }}</span></div>
              <div class="bb-detail-item"><span class="bb-detail-lb">状态</span><span class="bb-status-tag" :class="'status-' + detail.asset_status">{{ detail.asset_status_label }}</span></div>
              <div class="bb-detail-item"><span class="bb-detail-lb">数量</span>{{ detail.quantity }} {{ detail.unit }}</div>
            </div>
          </div>
          <div class="bb-detail-section">
            <div class="bb-detail-title">保管信息</div>
            <div class="bb-detail-grid">
              <div class="bb-detail-item"><span class="bb-detail-lb">保管人</span>{{ detail.keeper_name || '-' }}</div>
              <div class="bb-detail-item"><span class="bb-detail-lb">工号</span>{{ detail.keeper_no || '-' }}</div>
              <div class="bb-detail-item"><span class="bb-detail-lb">部门</span>{{ detail.keeper_department || '-' }}</div>
            </div>
          </div>
        </template>
      </div>
      <div slot="footer"><el-button size="small" @click="detailVisible = false">关闭</el-button></div>
    </el-dialog>
  </div>
</template>

<script>
import { getBorrowableAssets, applyTransfer } from '../../api/personalAssets'

export default {
  name: 'BorrowableAssets',
  data () {
    return {
      showBanner: localStorage.getItem('bb_banner_closed') !== '1',
      stats: { total_quantity: 0, total_types: 0, total_people: 0 },
      list: [], total: 0, page: 1, limit: 20, loading: false,
      query: { keyword: '', asset_type: '', asset_status: '', keeper_name: '' },
      isFiltered: false,
      // 调拨弹窗
      applyVisible: false, initiateVisible: false, submitting: false,
      transferAsset: {}, transferForm: { quantity: 1, purpose: '', remark: '' },
      // 详情
      detailVisible: false, detail: {}
    }
  },
  created () { this.getList() },
  methods: {
    closeBanner () {
      this.showBanner = false
      localStorage.setItem('bb_banner_closed', '1')
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.query.asset_type !== '' && this.query.asset_type != null) p.asset_type = this.query.asset_type
      if (this.query.asset_status !== '' && this.query.asset_status != null) p.asset_status = this.query.asset_status
      if (this.query.keeper_name) p.keeper_name = this.query.keeper_name
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getBorrowableAssets(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.statistics || { total_quantity: 0, total_types: 0, total_people: 0 }
          this.isFiltered = !!(this.query.keyword || this.query.asset_type || this.query.asset_status || this.query.keeper_name)
        }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { keyword: '', asset_type: '', asset_status: '', keeper_name: '' }
      this.page = 1
      this.getList()
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    openDetail (item) {
      this.detail = item
      this.detailVisible = true
    },
    handleApplyTransfer (item) {
      this.transferAsset = item
      this.transferForm = { quantity: 1, purpose: '', remark: '' }
      this.applyVisible = true
    },
    handleInitiateTransfer (item) {
      this.transferAsset = item
      this.transferForm = { quantity: 1, purpose: '', remark: '' }
      this.initiateVisible = true
    },
    async submitTransfer (type) {
      if (!this.transferForm.quantity || this.transferForm.quantity <= 0) { this.$message.warning('请输入调拨数量'); return }
      if (this.transferForm.quantity > Number(this.transferAsset.quantity)) { this.$message.warning('调拨数量不能超过可用数量'); return }
      if (!this.transferForm.purpose) { this.$message.warning('请填写用途说明'); return }
      this.submitting = true
      try {
        const r = await applyTransfer({
          asset_id: this.transferAsset.id,
          target_user_id: this.transferAsset.keeper_id,
          quantity: this.transferForm.quantity,
          purpose: this.transferForm.purpose,
          remark: this.transferForm.remark
        })
        if (r.code === 0) {
          this.$message.success(type === 'apply' ? '申请已发送，请等待保管人确认' : '调拨已发起，请等待保管人确认')
          this.applyVisible = false
          this.initiateVisible = false
          this.getList()
        }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.bb-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.bb-breadcrumb { margin-bottom: 12px; }
.bb-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.bb-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.bb-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.bb-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.bb-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 16px; }
.bb-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.bb-stat-num { font-size: 22px; font-weight: 700; }
.bb-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.bb-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.bb-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.bb-filter .el-form-item { margin-bottom: 16px; margin-right: 16px; }
.bb-filter .el-form-item__label { color: #606266; font-size: 13px; width: 70px; }
.bb-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.bb-total { margin-left: 12px; color: #909399; font-size: 13px; }
.bb-card-list { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; min-height: 120px; }
.bb-card { background: #fff; border-radius: 12px; padding: 16px 18px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; justify-content: space-between; cursor: pointer; transition: box-shadow .2s; }
.bb-card:hover { box-shadow: 0 6px 20px rgba(31,45,61,.1); }
.bb-card-left { flex: 0 0 65%; min-width: 0; }
.bb-card-right { flex: 0 0 35%; display: flex; flex-direction: column; align-items: flex-end; justify-content: space-between; }
.bb-card-name-row { display: flex; align-items: center; gap: 8px; }
.bb-card-name { font-size: 16px; font-weight: 700; color: #1f2d3d; }
.bb-card-spec { font-size: 13px; color: #909399; }
.bb-type-tag { display: inline-flex; align-items: center; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; flex-shrink: 0; }
.bb-type-tag.type-1 { background: #FFF3E0; color: #E65100; }
.bb-type-tag.type-2 { background: #E3F2FD; color: #0D47A1; }
.bb-type-tag.type-3 { background: #F3E5F5; color: #6A1B9A; }
.bb-status-tag { display: inline-flex; align-items: center; padding: 2px 10px; border-radius: 999px; font-size: 11px; font-weight: 600; }
.bb-status-tag.status-1 { background: #E8F5E9; color: #2E7D32; }
.bb-status-tag.status-2 { background: #FFF3E0; color: #E65100; }
.bb-status-tag.status-3 { background: #F3E5F5; color: #6A1B9A; }
.bb-status-tag.status-4 { background: #FFEBEE; color: #C62828; }
.bb-card-code { font-size: 13px; color: #909399; margin-top: 6px; }
.bb-card-keeper { font-size: 13px; color: #909399; margin-top: 4px; }
.bb-card-qty { font-size: 14px; margin-top: 6px; }
.bb-qty-num { font-size: 16px; font-weight: 700; color: #409EFF; }
.bb-card-actions { display: flex; flex-direction: column; align-items: flex-end; gap: 2px; }
.bb-empty { grid-column: 1 / -1; text-align: center; padding: 60px 0; }
.bb-empty-icon { font-size: 48px; color: #dcdfe6; }
.bb-empty-title { font-size: 16px; color: #606266; font-weight: 600; margin-top: 12px; }
.bb-empty-desc { font-size: 13px; color: #909399; margin: 8px 0 16px; }
.bb-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }
.bb-tip { font-size: 12px; color: #909399; line-height: 1.6; }
.bb-detail-body { min-height: 150px; }
.bb-detail-section { margin-bottom: 16px; }
.bb-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.bb-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.bb-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.bb-detail-lb { color: #909399; width: 70px; flex-shrink: 0; }
@media (max-width: 768px) {
  .bb-stats { grid-template-columns: repeat(2, 1fr); }
  .bb-card-list { grid-template-columns: 1fr; }
  .bb-card { flex-direction: column; }
  .bb-card-right { flex: none; flex-direction: row; align-items: center; margin-top: 10px; }
  .bb-card-actions { flex-direction: row; }
}
</style>