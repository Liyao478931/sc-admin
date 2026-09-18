<template>
  <div class="pd-page">
    <el-breadcrumb separator="/" class="pd-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产详情</el-breadcrumb-item>
      <el-breadcrumb-item>部门资产</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="pd-banner">
      <i class="el-icon-info pd-banner-icon"></i>
      <span class="pd-banner-text">部门资产：本部门所有员工名下的物资汇总。负责人可查看本部门全部资产分布情况。</span>
      <i class="el-icon-close pd-banner-close" @click="closeBanner"></i>
    </div>

    <!-- 部门切换（管理员） -->
    <div v-if="departmentOptions.length > 1" class="pd-dept-switch">
      <span class="pd-dept-label">当前部门：</span>
      <el-select v-model="query.department_id" size="small" style="width:220px" @change="handleDeptChange">
        <el-option v-for="d in departmentOptions" :key="d.id" :label="d.name" :value="d.id" />
      </el-select>
    </div>

    <!-- 统计卡片 -->
    <div class="pd-stats">
      <div class="pd-stat-card">
        <div class="pd-stat-info">
          <div class="pd-stat-num">{{ stats.total_quantity }}</div>
          <div class="pd-stat-label">总数量</div>
        </div>
        <div class="pd-stat-icon" style="background:#ecf5ff"><i class="el-icon-box" style="color:#409EFF"></i></div>
      </div>
      <div class="pd-stat-card">
        <div class="pd-stat-info">
          <div class="pd-stat-num">{{ stats.total_types }}</div>
          <div class="pd-stat-label">总种类</div>
        </div>
        <div class="pd-stat-icon" style="background:#f0f9eb"><i class="el-icon-document" style="color:#67C23A"></i></div>
      </div>
      <div class="pd-stat-card">
        <div class="pd-stat-info">
          <div class="pd-stat-num">{{ stats.total_people }}</div>
          <div class="pd-stat-label">总人数</div>
        </div>
        <div class="pd-stat-icon" style="background:#fdf6ec"><i class="el-icon-user" style="color:#E6A23C"></i></div>
      </div>
      <div class="pd-stat-card">
        <div class="pd-stat-info">
          <div class="pd-stat-num">{{ stats.avg_quantity }}</div>
          <div class="pd-stat-label">人均数量</div>
        </div>
        <div class="pd-stat-icon" style="background:#f5f0fa"><i class="el-icon-data-line" style="color:#9B59B6"></i></div>
      </div>
    </div>

    <!-- 员工筛选 -->
    <div class="pd-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="员工姓名">
          <el-input v-model="query.employee_keyword" placeholder="请输入员工姓名" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="资产名称">
          <el-input v-model="query.keyword" placeholder="请输入资产名称" clearable style="width:170px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="资产类型">
          <el-select v-model="query.asset_type" clearable placeholder="全部类型" style="width:130px" @change="handleSearch">
            <el-option label="物料/配件" :value="1" />
            <el-option label="固定资产" :value="2" />
            <el-option label="工具" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="资产状态">
          <el-select v-model="query.asset_status" clearable placeholder="全部状态" style="width:130px" @change="handleSearch">
            <el-option label="正常" :value="1" />
            <el-option label="维修中" :value="2" />
            <el-option label="闲置" :value="3" />
            <el-option label="待报废" :value="4" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作栏 -->
    <div class="pd-toolbar">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
      <span class="pd-total">共 {{ totalEmployees }} 名员工，{{ stats.total_quantity }} 项资产</span>
    </div>

    <!-- 员工分组列表 -->
    <div v-loading="loading" class="pd-group-list">
      <template v-if="list.length">
        <div v-for="group in list" :key="group.user_id" class="pd-group">
          <!-- 分组标题 -->
          <div class="pd-group-head" @click="toggleGroup(group.user_id)">
            <div class="pd-avatar" :style="{ background: avatarColor(group.employee_name) }">{{ (group.employee_name || '员').substring(0, 1) }}</div>
            <div class="pd-group-info">
              <span class="pd-emp-name">{{ group.employee_name }}</span>
              <span class="pd-emp-no">{{ group.employee_no || '-' }}</span>
            </div>
            <span class="pd-emp-stats">共 {{ group.assets.length }} 项资产，合计 {{ group.total_quantity }} 件</span>
            <i class="el-icon-arrow-down pd-group-arrow" :class="{ collapsed: !expandedMap[group.user_id] }"></i>
          </div>
          <!-- 资产卡片 -->
          <div v-show="expandedMap[group.user_id]" class="pd-assets">
            <div v-for="(a, idx) in visibleAssets(group)" :key="a.id" class="pd-asset-card">
              <div class="pd-asset-left">
                <div class="pd-asset-name-row">
                  <span class="pd-type-tag" :class="'type-' + a.asset_type">{{ a.asset_type_label }}</span>
                  <span class="pd-asset-name">{{ a.asset_name }}</span>
                  <span v-if="a.specification" class="pd-asset-spec">{{ a.specification }}</span>
                </div>
<div class="pd-asset-code">编码：{{ a.asset_code || '-' }}</div>
                  <div class="pd-asset-qty"><span class="pd-qty-num">{{ a.quantity }}</span> {{ a.unit }}</div>
                  <div class="pd-asset-location"><i class="el-icon-location-outline pd-loc-icon"></i>{{ a.location || '未设置位置' }}</div>
                <div class="pd-asset-source">来源：{{ a.source_type_label }} / {{ a.source_no || '-' }}</div>
                  <div v-if="a.supplier_name || a.purchase_order_no" class="pd-asset-purchase"><span class="pd-purchase-label">采购信息：</span>{{ a.supplier_name || '' }}{{ a.supplier_name && a.purchase_order_no ? ' / ' : '' }}{{ a.purchase_order_no || '' }}</div>
              </div>
              <div class="pd-asset-right">
                <span class="pd-status-tag" :class="'status-' + a.asset_status">{{ a.asset_status_label }}</span>
                <el-button type="text" size="mini" @click="openDetail(a)">查看详情</el-button>
              </div>
            </div>
            <div v-if="group.assets.length > COLLAPSE_THRESHOLD" class="pd-more">
              <el-button type="text" size="small" @click="toggleMore(group.user_id)">
                {{ moreMap[group.user_id] ? '收起' : '查看更多' }}
              </el-button>
            </div>
          </div>
        </div>
      </template>

      <!-- 空状态 -->
      <div v-else class="pd-empty">
        <i class="el-icon-box pd-empty-icon"></i>
        <div class="pd-empty-title">{{ isFiltered ? '未找到匹配资产' : '本部门暂无资产' }}</div>
        <div class="pd-empty-desc">{{ isFiltered ? '请调整搜索条件后重试。' : '本部门员工名下暂无资产，请鼓励员工从总仓领用或申请资产领用。' }}</div>
        <el-button v-if="isFiltered" type="primary" @click="handleReset">重置筛选</el-button>
      </div>
    </div>

    <!-- 分页 -->
    <div class="pd-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="totalEmployees" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 资产详情弹窗（只读） -->
    <el-dialog :title="'资产详情 - ' + (detail.asset_name || '')" :visible.sync="detailVisible" width="560px">
      <div v-loading="detailLoading" class="pd-detail-body">
        <template v-if="detail.id">
          <div class="pd-detail-section">
            <div class="pd-detail-title">基本信息</div>
            <div class="pd-detail-grid">
              <div class="pd-detail-item"><span class="pd-detail-lb">资产名称</span>{{ detail.asset_name || '-' }}</div>
              <div class="pd-detail-item"><span class="pd-detail-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="pd-detail-item"><span class="pd-detail-lb">资产编码</span>{{ detail.asset_code || '-' }}</div>
              <div class="pd-detail-item">
                <span class="pd-detail-lb">类型</span>
                <span class="pd-type-tag" :class="'type-' + detail.asset_type">{{ detail.asset_type_label }}</span>
              </div>
              <div class="pd-detail-item">
                <span class="pd-detail-lb">状态</span>
                <span class="pd-status-tag" :class="'status-' + detail.asset_status">{{ detail.asset_status_label }}</span>
              </div>
              <div class="pd-detail-item"><span class="pd-detail-lb">品牌</span>{{ detail.brand || '-' }}</div>
            </div>
          </div>
          <div class="pd-detail-section">
            <div class="pd-detail-title">数量信息</div>
            <div class="pd-detail-grid">
              <div class="pd-detail-item"><span class="pd-detail-lb">当前数量</span>{{ detail.quantity }} {{ detail.unit }}</div>
              <div class="pd-detail-item"><span class="pd-detail-lb">单位</span>{{ detail.unit || '-' }}</div>
              <div class="pd-detail-item"><span class="pd-detail-lb">初始数量</span>{{ detail.initial_quantity }}</div>
            </div>
          </div>
          <div class="pd-detail-section">
            <div class="pd-detail-title">来源信息</div>
            <div class="pd-detail-grid">
              <div class="pd-detail-item"><span class="pd-detail-lb">来源类型</span>{{ detail.source_type_label }}</div>
              <div class="pd-detail-item"><span class="pd-detail-lb">来源单号</span>{{ detail.source_no || '-' }}</div>
              <div class="pd-detail-item"><span class="pd-detail-lb">来源日期</span>{{ formatDate(detail.created_at) }}</div>
            </div>
          </div>
          <div v-if="detail.remark" class="pd-detail-section">
            <div class="pd-detail-title">备注</div>
            <div class="pd-detail-remark">{{ detail.remark }}</div>
          </div>
        </template>
      </div>
      <div slot="footer">
        <el-button size="small" @click="detailVisible = false">关闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getDeptAssetList, getAssetDepartments, getMyAssetDetail, exportDeptAsset } from '../../api/personalAssets'

const COLLAPSE_THRESHOLD = 10
const INITIAL_SHOW = 5

export default {
  name: 'PersonalAssetsDeptList',
  data () {
    return {
      showBanner: localStorage.getItem('pa_banner_closed') !== '1',
      COLLAPSE_THRESHOLD,
      stats: { total_quantity: 0, total_types: 0, total_people: 0, avg_quantity: 0 },
      list: [], totalEmployees: 0, page: 1, limit: 20, loading: false, exporting: false,
      departmentOptions: [], expandedMap: {}, moreMap: {},
      query: { department_id: '', employee_keyword: '', keyword: '', asset_type: '', asset_status: '' },
      detailVisible: false, detailLoading: false, detail: {},
      isFiltered: false,
      avatarColors: ['#6e8efb', '#fb8a6e', '#34c796', '#8a7aa8', '#fbaa50', '#50c8ff']
    }
  },
  created () {
    this.loadDepartments().then(() => this.getList())
  },
  methods: {
    closeBanner () {
      this.showBanner = false
      localStorage.setItem('pa_banner_closed', '1')
    },
    avatarColor (name) {
      let sum = 0
      for (const c of String(name || '员')) sum += c.charCodeAt(0)
      return this.avatarColors[sum % this.avatarColors.length]
    },
    formatDate (t) { return t ? String(t).slice(0, 10) : '-' },
    async loadDepartments () {
      try {
        const r = await getAssetDepartments()
        if (r.code === 0 && Array.isArray(r.data)) {
          this.departmentOptions = r.data
          if (!this.query.department_id && r.data.length) {
            // 默认选择第一个部门
            this.query.department_id = r.data[0].id
          }
        }
      } catch (e) {}
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.department_id) p.department_id = this.query.department_id
      if (this.query.employee_keyword) p.employee_keyword = this.query.employee_keyword
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.query.asset_type !== '' && this.query.asset_type != null) p.asset_type = this.query.asset_type
      if (this.query.asset_status !== '' && this.query.asset_status != null) p.asset_status = this.query.asset_status
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getDeptAssetList(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.totalEmployees = r.data.total_employees || 0
          this.stats = r.data.statistics || { total_quantity: 0, total_types: 0, total_people: 0, avg_quantity: 0 }
          // 默认展开所有分组
          this.list.forEach(g => {
            this.$set(this.expandedMap, g.user_id, true)
            this.$set(this.moreMap, g.user_id, false)
          })
          this.isFiltered = !!(this.query.employee_keyword || this.query.keyword || this.query.asset_type || this.query.asset_status)
        }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { department_id: this.query.department_id, employee_keyword: '', keyword: '', asset_type: '', asset_status: '' }
      this.page = 1
      this.getList()
    },
    handleDeptChange () { this.page = 1; this.getList() },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page
        delete p.limit
        const res = await exportDeptAsset(p)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '部门资产_' + this.statsLabel() + '_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    },
    statsLabel () {
      const d = this.departmentOptions.find(x => x.id === this.query.department_id)
      return d ? d.name : '全部'
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    toggleGroup (uid) { this.$set(this.expandedMap, uid, !this.expandedMap[uid]) },
    toggleMore (uid) { this.$set(this.moreMap, uid, !this.moreMap[uid]) },
    visibleAssets (group) {
      if (group.assets.length > COLLAPSE_THRESHOLD && !this.moreMap[group.user_id]) {
        return group.assets.slice(0, INITIAL_SHOW)
      }
      return group.assets
    },
    async openDetail (item) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getMyAssetDetail(item.id)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.detailLoading = false
    }
  }
}
</script>

<style scoped>
.pd-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.pd-breadcrumb { margin-bottom: 12px; }

/* 提示横幅 */
.pd-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 12px; }
.pd-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.pd-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.pd-banner-close { color: #909399; cursor: pointer; font-size: 14px; }

/* 部门切换 */
.pd-dept-switch { margin-bottom: 12px; }
.pd-dept-label { font-size: 14px; color: #606266; margin-right: 4px; }

/* 统计卡片 */
.pd-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.pd-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.pd-stat-num { font-size: 22px; font-weight: 700; color: #1f2d3d; }
.pd-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.pd-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }

/* 筛选 */
.pd-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.pd-filter .el-form-item { margin-bottom: 16px; margin-right: 16px; }
.pd-filter .el-form-item__label { color: #606266; font-size: 13px; width: 70px; }

/* 操作栏 */
.pd-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.pd-total { margin-left: 12px; color: #909399; font-size: 13px; }

/* 分组列表 */
.pd-group { background: #fff; border-radius: 10px; margin-bottom: 12px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); overflow: hidden; }
.pd-group-head { display: flex; align-items: center; padding: 12px 16px; cursor: pointer; }
.pd-avatar { width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 14px; font-weight: 600; flex-shrink: 0; }
.pd-group-info { display: flex; align-items: baseline; gap: 8px; margin-left: 10px; }
.pd-emp-name { font-size: 16px; font-weight: 700; color: #1f2d3d; }
.pd-emp-no { font-size: 13px; color: #909399; }
.pd-emp-stats { flex: 1; text-align: right; font-size: 13px; color: #909399; margin-right: 8px; }
.pd-group-arrow { color: #909399; transition: transform .25s; }
.pd-group-arrow.collapsed { transform: rotate(-90deg); }

.pd-assets { padding: 0 16px 12px; }
.pd-asset-card { display: flex; justify-content: space-between; background: #fafbfc; border-radius: 8px; padding: 14px 16px; margin-bottom: 8px; border: 1px solid #f0f2f5; }
.pd-asset-left { flex: 1; min-width: 0; }
.pd-asset-right { flex-shrink: 0; display: flex; flex-direction: column; align-items: flex-end; justify-content: space-between; }

.pd-asset-name-row { display: flex; align-items: center; gap: 8px; }
.pd-asset-name { font-size: 15px; font-weight: 700; color: #1f2d3d; }
.pd-asset-spec { font-size: 13px; color: #909399; }

.pd-type-tag { display: inline-flex; align-items: center; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; flex-shrink: 0; }
.pd-type-tag.type-1 { background: #FFF3E0; color: #E65100; }
.pd-type-tag.type-2 { background: #E3F2FD; color: #0D47A1; }
.pd-type-tag.type-3 { background: #F3E5F5; color: #6A1B9A; }

.pd-status-tag { display: inline-flex; align-items: center; padding: 2px 10px; border-radius: 999px; font-size: 11px; font-weight: 600; }
.pd-status-tag.status-1 { background: #E8F5E9; color: #2E7D32; }
.pd-status-tag.status-2 { background: #FFF3E0; color: #E65100; }
.pd-status-tag.status-3 { background: #F3E5F5; color: #6A1B9A; }
.pd-status-tag.status-4 { background: #FFEBEE; color: #C62828; }

.pd-asset-code { font-size: 13px; color: #909399; margin-top: 4px; }
.pd-asset-qty { font-size: 14px; margin-top: 4px; }
.pd-asset-location { font-size: 12px; color: #909399; margin-top: 4px; }
.pd-loc-icon { margin-right: 2px; font-size: 12px; }
.pd-qty-num { font-size: 15px; font-weight: 700; color: #409EFF; }
.pd-asset-purchase { font-size: 12px; color: #909399; margin-top: 4px; }
.pd-purchase-label { color: #909399; }
.pd-asset-source { font-size: 12px; color: #909399; margin-top: 4px; }

.pd-more { text-align: center; padding: 4px 0; }

/* 空状态 */
.pd-empty { text-align: center; padding: 60px 0; background: #fff; border-radius: 10px; }
.pd-empty-icon { font-size: 48px; color: #dcdfe6; }
.pd-empty-title { font-size: 16px; color: #606266; font-weight: 600; margin-top: 12px; }
.pd-empty-desc { font-size: 13px; color: #909399; margin: 8px 0 16px; }

/* 分页 */
.pd-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }

/* 详情 */
.pd-detail-body { min-height: 200px; }
.pd-detail-section { margin-bottom: 16px; }
.pd-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.pd-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.pd-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.pd-detail-lb { color: #909399; width: 70px; flex-shrink: 0; }
.pd-detail-remark { font-size: 13px; color: #4b5a6c; line-height: 1.7; }

@media (max-width: 768px) {
  .pd-stats { grid-template-columns: repeat(2, 1fr); }
  .pd-group-head { flex-wrap: wrap; }
  .pd-emp-stats { flex: none; width: 100%; text-align: left; margin-top: 6px; margin-left: 42px; }
}
</style>