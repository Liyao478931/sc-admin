<template>
  <div class="pa3-page">
    <el-breadcrumb separator="/" class="pa3-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产详情</el-breadcrumb-item>
      <el-breadcrumb-item>全部资产</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="pa3-banner">
      <i class="el-icon-info pa3-banner-icon"></i>
      <span class="pa3-banner-text">全部资产：公司全部资产总览，包含总仓库库存（在库资产）和个人名下资产（在册资产）。仅管理员可见。</span>
      <i class="el-icon-close pa3-banner-close" @click="closeBanner"></i>
    </div>

    <!-- 统计卡片 (动态变化) -->
    <div class="pa3-stats">
      <template v-if="activeTab === 'all'">
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#409EFF">{{ stats.total_quantity }}</div><div class="pa3-stat-label">总资产</div></div><div class="pa3-stat-icon" style="background:#ecf5ff"><i class="el-icon-box" style="color:#409EFF"></i></div></div>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#E6A23C">{{ stats.warehouse_quantity }}</div><div class="pa3-stat-label">在库资产</div></div><div class="pa3-stat-icon" style="background:#fdf6ec"><i class="el-icon-house" style="color:#E6A23C"></i></div></div>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#67C23A">{{ stats.personal_quantity }}</div><div class="pa3-stat-label">在册资产</div></div><div class="pa3-stat-icon" style="background:#f0f9eb"><i class="el-icon-user" style="color:#67C23A"></i></div></div>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#9B59B6">{{ stats.total_types }}</div><div class="pa3-stat-label">资产种类</div></div><div class="pa3-stat-icon" style="background:#f5f0fa"><i class="el-icon-document" style="color:#9B59B6"></i></div></div>
      </template>
      <template v-else-if="activeTab === 'warehouse'">
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#409EFF">{{ stats.total_quantity }}</div><div class="pa3-stat-label">在库总数量</div></div><div class="pa3-stat-icon" style="background:#ecf5ff"><i class="el-icon-box" style="color:#409EFF"></i></div></div>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#67C23A">{{ stats.total_types }}</div><div class="pa3-stat-label">在库种类</div></div><div class="pa3-stat-icon" style="background:#f0f9eb"><i class="el-icon-document" style="color:#67C23A"></i></div></div>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#E6A23C">{{ stats.part_count }}</div><div class="pa3-stat-label">配件数量</div></div><div class="pa3-stat-icon" style="background:#fdf6ec"><i class="el-icon-setting" style="color:#E6A23C"></i></div></div>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#9B59B6">{{ stats.asset_count }}</div><div class="pa3-stat-label">固定资产</div></div><div class="pa3-stat-icon" style="background:#f5f0fa"><i class="el-icon-monitor" style="color:#9B59B6"></i></div></div>
      </template>
      <template v-else>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#409EFF">{{ stats.total_quantity }}</div><div class="pa3-stat-label">在册总数量</div></div><div class="pa3-stat-icon" style="background:#ecf5ff"><i class="el-icon-box" style="color:#409EFF"></i></div></div>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#67C23A">{{ stats.total_types }}</div><div class="pa3-stat-label">在册种类</div></div><div class="pa3-stat-icon" style="background:#f0f9eb"><i class="el-icon-document" style="color:#67C23A"></i></div></div>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#E6A23C">{{ stats.part_count }}</div><div class="pa3-stat-label">配件数量</div></div><div class="pa3-stat-icon" style="background:#fdf6ec"><i class="el-icon-setting" style="color:#E6A23C"></i></div></div>
        <div class="pa3-stat-card"><div class="pa3-stat-info"><div class="pa3-stat-num" style="color:#9B59B6">{{ stats.asset_count }}</div><div class="pa3-stat-label">固定资产</div></div><div class="pa3-stat-icon" style="background:#f5f0fa"><i class="el-icon-monitor" style="color:#9B59B6"></i></div></div>
      </template>
    </div>

    <!-- Tab切换 -->
    <div class="pa3-tabs">
      <el-tabs v-model="activeTab" @tab-click="handleTabChange">
        <el-tab-pane label="📦 全部资产" name="all" />
        <el-tab-pane label="🏚️ 在库资产（总仓库）" name="warehouse" />
        <el-tab-pane label="👤 在册资产（个人名下）" name="personal" />
      </el-tabs>
    </div>

    <!-- 筛选区 (动态) -->
    <div class="pa3-filter">
      <el-form inline size="small" @submit.native.prevent>
        <template v-if="activeTab === 'personal'">
          <el-form-item label="所属部门">
            <el-cascader v-model="query.department_path" :options="deptTree" :props="cascaderProps" clearable placeholder="全部部门" style="width:200px" @change="handleSearch" />
          </el-form-item>
          <el-form-item label="员工姓名">
            <el-input v-model="query.employee_keyword" placeholder="请输入员工姓名" clearable style="width:130px" @keyup.enter.native="handleSearch" />
          </el-form-item>
        </template>
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
        <el-form-item v-if="activeTab === 'personal'" label="资产状态">
          <el-select v-model="query.asset_status" clearable placeholder="全部状态" style="width:120px" @change="handleSearch">
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
    <div class="pa3-toolbar">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
      <span class="pa3-total">共 {{ total }} 条</span>
    </div>

    <!-- ======== 全部 / 在库 Tab：平铺表格 ======== -->
    <div v-if="activeTab !== 'personal'" v-loading="loading" class="pa3-table-wrap">
      <el-table :data="flatList" size="small" border stripe empty-text="暂无资产数据">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="asset_name" label="资产名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="120" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="70" align="center" />
        <el-table-column label="数量" width="90" align="center">
          <template slot-scope="s">{{ s.row.quantity }}</template>
        </el-table-column>
        <el-table-column label="资产类型" width="100" align="center">
          <template slot-scope="s"><span class="pa3-type-tag" :class="'type-' + s.row.asset_type">{{ s.row.asset_type_label }}</span></template>
        </el-table-column>
        <el-table-column label="资产状态" width="100" align="center">
          <template slot-scope="s"><el-tag :type="s.row.asset_status === '在库' ? 'info' : 'primary'" size="mini">{{ s.row.asset_status }}</el-tag></template>
        </el-table-column>
        <el-table-column label="存放位置" width="140">
          <template slot-scope="s"><i class="el-icon-location-outline" style="color:#909399;margin-right:2px;font-size:12px"></i>{{ s.row.location || '—' }}</template>
        </el-table-column>
        <el-table-column prop="keeper_name" label="保管人" width="120" />
        <el-table-column prop="department_name" label="所属部门" width="120" />
        <el-table-column label="采购信息" width="180" show-overflow-tooltip>
          <template slot-scope="s">{{ s.row.supplier_name || '' }}{{ s.row.supplier_name && s.row.purchase_order_no ? ' / ' : '' }}{{ s.row.purchase_order_no || '' }}{{ s.row.warranty_end_date ? ' 保修至' + s.row.warranty_end_date : '' }}</template>
        </el-table-column>
        <el-table-column label="入库时间" width="160">
          <template slot-scope="s">{{ s.row.created_at || '-' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center" fixed="right">
          <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button></template>
        </el-table-column>
      </el-table>
    </div>

    <!-- ======== 在册 Tab：部门→员工二级分组 ======== -->
    <div v-else v-loading="loading" class="pa3-group-list">
      <template v-if="groupList.length">
        <div v-for="dept in groupList" :key="dept.department_id" class="pa3-dept">
          <div class="pa3-dept-head" @click="toggleDept(dept.department_id)">
            <span class="pa3-dept-icon">🏢</span>
            <span class="pa3-dept-name">{{ dept.department_name }}</span>
            <span class="pa3-dept-stats">共 {{ dept.employee_count }} 名员工，{{ dept.employees.length }} 组，合计 {{ dept.total_quantity }} 件</span>
            <i class="el-icon-arrow-down pa3-dept-arrow" :class="{ collapsed: !deptExpanded[dept.department_id] }"></i>
          </div>
          <div v-show="deptExpanded[dept.department_id]" class="pa3-emp-list">
            <div v-for="emp in dept.employees" :key="emp.user_id" class="pa3-emp">
              <div class="pa3-emp-head" @click="toggleEmp(emp.user_id)">
                <div class="pa3-avatar" :style="{ background: avatarColor(emp.employee_name) }">{{ (emp.employee_name || '员').substring(0, 1) }}</div>
                <span class="pa3-emp-name">{{ emp.employee_name }}</span>
                <span class="pa3-emp-no">{{ emp.employee_no || '-' }}</span>
                <span class="pa3-emp-stats">共 {{ emp.assets.length }} 项资产，合计 {{ emp.total_quantity }} 件</span>
                <i class="el-icon-arrow-down pa3-emp-arrow" :class="{ collapsed: !empExpanded[emp.user_id] }"></i>
              </div>
              <div v-show="empExpanded[emp.user_id]" class="pa3-assets">
                <div v-for="a in emp.assets" :key="a.id" class="pa3-asset-card">
                  <div class="pa3-asset-left">
                    <div class="pa3-asset-name-row">
                      <span class="pa3-type-tag" :class="'type-' + a.asset_type">{{ a.asset_type_label }}</span>
                      <span class="pa3-asset-name">{{ a.asset_name }}</span>
                      <span v-if="a.specification" class="pa3-asset-spec">{{ a.specification }}</span>
                    </div>
                    <div class="pa3-asset-code">编码：{{ a.asset_code || '-' }}</div>
                    <div class="pa3-asset-qty"><span class="pa3-qty-num">{{ a.quantity }}</span> {{ a.unit }}</div>
                    <div class="pa3-asset-location"><i class="el-icon-location-outline" style="color:#909399;margin-right:2px;font-size:12px"></i>{{ a.location || '未设置位置' }}</div>
                    <div class="pa3-asset-source">来源：{{ a.source_type_label }} / {{ a.source_no || '-' }}</div>
                    <div v-if="a.supplier_name || a.purchase_order_no" class="pa3-asset-purchase">采购信息：{{ a.supplier_name || '' }}{{ a.supplier_name && a.purchase_order_no ? ' / ' : '' }}{{ a.purchase_order_no || '' }}</div>
                  </div>
                  <div class="pa3-asset-right">
                    <span class="pa3-status-tag" :class="'status-' + a.asset_status">{{ a.asset_status_label }}</span>
                    <el-button type="text" size="mini" @click="openDetail(a)">查看详情</el-button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>
      <div v-else class="pa3-empty">
        <i class="el-icon-box pa3-empty-icon"></i>
        <div class="pa3-empty-title">{{ isFiltered ? '未找到匹配资产' : '暂无在册资产数据' }}</div>
        <el-button v-if="isFiltered" type="primary" @click="handleReset">重置筛选</el-button>
      </div>
    </div>

    <!-- 分页 -->
    <div class="pa3-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 资产详情弹窗 -->
    <el-dialog :title="'资产详情 - ' + (detail.asset_name || '')" :visible.sync="detailVisible" width="560px">
      <div v-loading="detailLoading" class="pa3-detail-body">
        <template v-if="detail.id || detail.source_type">
          <div class="pa3-detail-section">
            <div class="pa3-detail-title">基本信息</div>
            <div class="pa3-detail-grid">
              <div class="pa3-detail-item"><span class="pa3-detail-lb">资产名称</span>{{ detail.asset_name || '-' }}</div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">类型</span><span class="pa3-type-tag" :class="'type-' + detail.asset_type">{{ detail.asset_type_label }}</span></div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">状态</span>
                <el-tag v-if="detail.asset_status === '在库'" type="info" size="mini">在库</el-tag>
                <span v-else class="pa3-status-tag" :class="'status-' + detail.asset_status">{{ detail.asset_status_label }}</span>
              </div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">数量</span>{{ detail.quantity }} {{ detail.unit }}</div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">单位</span>{{ detail.unit || '-' }}</div>
            </div>
          </div>
          <div class="pa3-detail-section">
            <div class="pa3-detail-title">保管信息</div>
            <div class="pa3-detail-grid">
              <div class="pa3-detail-item"><span class="pa3-detail-lb">保管人</span>{{ detail.keeper_name || '-' }}</div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">所属部门</span>{{ detail.department_name || '-' }}</div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">入库时间</span>{{ formatDate(detail.created_at) }}</div>
            </div>
          </div>
          <div v-if="detail.source_type === 'personal' && detail._raw" class="pa3-detail-section">
            <div class="pa3-detail-title">来源信息</div>
            <div class="pa3-detail-grid">
              <div class="pa3-detail-item"><span class="pa3-detail-lb">来源类型</span>{{ detail._raw.source_type_label || '-' }}</div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">来源单号</span>{{ detail._raw.source_no || '-' }}</div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">资产编码</span>{{ detail._raw.asset_code || '-' }}</div>
              <div class="pa3-detail-item"><span class="pa3-detail-lb">原值</span>{{ detail._raw.original_value ? '¥' + Number(detail._raw.original_value).toFixed(2) : '-' }}</div>
            </div>
          </div>
          <div v-if="detail._raw && detail._raw.remark" class="pa3-detail-section">
            <div class="pa3-detail-title">备注</div>
            <div class="pa3-detail-remark">{{ detail._raw.remark }}</div>
          </div>
        </template>
      </div>
      <div slot="footer"><el-button size="small" @click="detailVisible = false">关闭</el-button></div>
    </el-dialog>
  </div>
</template>

<script>
import { getAllAssetList, getAllAssetStatistics, getWarehouseAssetList, getInServiceAssetList, getAllAssetDepartments, getMyAssetDetail, exportAllAsset } from '../../api/personalAssets'

export default {
  name: 'PersonalAssetsAllList',
  data () {
    return {
      showBanner: localStorage.getItem('pa3_banner_closed') !== '1',
      activeTab: 'all',
      stats: { total_quantity: 0, warehouse_quantity: 0, personal_quantity: 0, total_types: 0, part_count: 0, asset_count: 0 },
      // 平铺列表（all/warehouse tab）
      flatList: [], total: 0, page: 1, limit: 20, loading: false, exporting: false,
      // 分组列表（personal tab）
      groupList: [], totalDepartments: 0,
      deptTree: [], cascaderProps: { value: 'id', label: 'name', children: 'children', checkStrictly: true },
      deptExpanded: {}, empExpanded: {},
      query: { department_path: [], department_id: 0, employee_keyword: '', keyword: '', asset_type: '', asset_status: '' },
      detailVisible: false, detailLoading: false, detail: {},
      isFiltered: false,
      avatarColors: ['#6e8efb', '#fb8a6e', '#34c796', '#8a7aa8', '#fbaa50', '#50c8ff']
    }
  },
  created () {
    this.loadDeptTree().then(() => this.loadData())
  },
  methods: {
    closeBanner () {
      this.showBanner = false
      localStorage.setItem('pa3_banner_closed', '1')
    },
    avatarColor (name) {
      let sum = 0
      for (const c of String(name || '员')) sum += c.charCodeAt(0)
      return this.avatarColors[sum % this.avatarColors.length]
    },
    formatDate (t) { return t ? String(t).slice(0, 10) : '-' },
    async loadDeptTree () {
      try {
        const r = await getAllAssetDepartments()
        if (r.code === 0) this.deptTree = r.data || []
      } catch (e) {}
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit, tab: this.activeTab }
      if (this.activeTab === 'personal') {
        if (this.query.department_path && this.query.department_path.length) {
          p.department_id = this.query.department_path[this.query.department_path.length - 1]
        }
        if (this.query.employee_keyword) p.employee_keyword = this.query.employee_keyword
        if (this.query.asset_status !== '' && this.query.asset_status != null) p.asset_status = this.query.asset_status
      }
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.query.asset_type !== '' && this.query.asset_type != null) p.asset_type = this.query.asset_type
      return p
    },
    async loadStatistics () {
      try {
        const r = await getAllAssetStatistics({ tab: this.activeTab })
        if (r.code === 0 && r.data.statistics) this.stats = r.data.statistics
      } catch (e) {}
    },
    async loadData () {
      this.loading = true
      try {
        // 加载统计
        await this.loadStatistics()
        // 加载列表
        if (this.activeTab === 'all') {
          const r = await getAllAssetList(this.buildParams())
          if (r.code === 0) {
            this.flatList = r.data.list || []
            this.total = r.data.total || 0
            if (r.data.statistics) this.stats = r.data.statistics
          }
        } else if (this.activeTab === 'warehouse') {
          const r = await getWarehouseAssetList(this.buildParams())
          if (r.code === 0) {
            this.flatList = r.data.list || []
            this.total = r.data.total || 0
          }
        } else {
          const r = await getAllAssetList(this.buildParams())
          if (r.code === 0) {
            this.groupList = r.data.list || []
            this.totalDepartments = r.data.total_departments || 0
            this.total = this.totalDepartments
            if (r.data.statistics) {
              this.stats = {
                total_quantity: r.data.statistics.total_quantity || 0,
                total_types: r.data.statistics.total_types || 0,
                part_count: 0,
                asset_count: 0
              }
            }
            // 默认展开前3个部门
            this.groupList.forEach((dept, idx) => {
              this.$set(this.deptExpanded, dept.department_id, idx < 3)
              dept.employees.forEach(emp => { this.$set(this.empExpanded, emp.user_id, idx < 3) })
            })
            this.isFiltered = !!(this.query.department_id || this.query.employee_keyword || this.query.keyword || this.query.asset_type || this.query.asset_status)
          }
        }
      } catch (e) {}
      this.loading = false
    },
    handleTabChange () {
      this.page = 1
      this.flatList = []
      this.groupList = []
      this.loadData()
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () {
      this.query = { department_path: [], department_id: 0, employee_keyword: '', keyword: '', asset_type: '', asset_status: '' }
      this.page = 1
      this.loadData()
    },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.loadData() },
    toggleDept (did) { this.$set(this.deptExpanded, did, !this.deptExpanded[did]) },
    toggleEmp (uid) { this.$set(this.empExpanded, uid, !this.empExpanded[uid]) },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams(), tab: this.activeTab }
        delete p.page
        delete p.limit
        const res = await exportAllAsset(p)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '全部资产_' + this.activeTab + '_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    },
    async openDetail (item) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      // 在册资产：调用detail接口获取完整信息；在库资产：直接使用列表数据
      if (item.source_type === 'personal' && item.id) {
        try {
          const r = await getMyAssetDetail(item.id)
          if (r.code === 0) {
            this.detail = { ...item, _raw: r.data }
          } else {
            this.detail = item
          }
        } catch (e) { this.detail = item }
      } else {
        this.detail = item
        // 补充detail模拟数据
        if (!this.detail._raw) this.detail._raw = { source_type_label: '总仓库', source_no: '-', asset_code: '-', original_value: 0, remark: '' }
      }
      this.detailLoading = false
    }
  }
}
</script>

<style scoped>
.pa3-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.pa3-breadcrumb { margin-bottom: 12px; }

/* 提示横幅 */
.pa3-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 12px; }
.pa3-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.pa3-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.pa3-banner-close { color: #909399; cursor: pointer; font-size: 14px; }

/* 统计卡片 */
.pa3-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 12px; }
.pa3-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.pa3-stat-num { font-size: 22px; font-weight: 700; }
.pa3-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.pa3-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }

/* Tab */
.pa3-tabs { background: #fff; border-radius: 8px; padding: 0 16px; margin-bottom: 12px; }

/* 筛选 */
.pa3-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.pa3-filter .el-form-item { margin-bottom: 16px; margin-right: 16px; }
.pa3-filter .el-form-item__label { color: #606266; font-size: 13px; width: 70px; }

/* 操作栏 */
.pa3-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.pa3-total { margin-left: 12px; color: #909399; font-size: 13px; }

/* 表格 */
.pa3-table-wrap { background: #fff; border-radius: 8px; padding: 12px; }
.pa3-table-wrap .el-table { width: 100%; }

/* 分组列表（在册） */
.pa3-group-list { display: flex; flex-direction: column; gap: 12px; }
.pa3-dept { background: #fff; border-radius: 10px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); overflow: hidden; }
.pa3-dept-head { display: flex; align-items: center; padding: 14px 16px; cursor: pointer; background: #fafbfc; }
.pa3-dept-icon { font-size: 18px; margin-right: 8px; }
.pa3-dept-name { font-size: 18px; font-weight: 700; color: #1f2d3d; }
.pa3-dept-stats { flex: 1; text-align: right; font-size: 14px; color: #909399; margin-right: 8px; }
.pa3-dept-arrow { color: #909399; transition: transform .25s; }
.pa3-dept-arrow.collapsed { transform: rotate(-90deg); }
.pa3-emp-list { padding: 8px 16px 12px; }
.pa3-emp { margin-bottom: 8px; }
.pa3-emp-head { display: flex; align-items: center; padding: 8px 10px; cursor: pointer; border-radius: 8px; }
.pa3-emp-head:hover { background: #f5f7fa; }
.pa3-avatar { width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 12px; font-weight: 600; flex-shrink: 0; margin-right: 8px; }
.pa3-emp-name { font-size: 14px; font-weight: 700; color: #1f2d3d; }
.pa3-emp-no { font-size: 12px; color: #909399; margin-left: 8px; }
.pa3-emp-stats { flex: 1; text-align: right; font-size: 12px; color: #909399; margin-right: 8px; }
.pa3-emp-arrow { color: #909399; transition: transform .25s; }
.pa3-emp-arrow.collapsed { transform: rotate(-90deg); }
.pa3-assets { padding-left: 20px; }
.pa3-asset-card { display: flex; justify-content: space-between; background: #fafbfc; border-radius: 8px; padding: 12px 16px; margin-bottom: 6px; border: 1px solid #f0f2f5; }
.pa3-asset-left { flex: 1; min-width: 0; }
.pa3-asset-right { flex-shrink: 0; display: flex; flex-direction: column; align-items: flex-end; justify-content: space-between; }
.pa3-asset-name-row { display: flex; align-items: center; gap: 8px; }
.pa3-asset-name { font-size: 14px; font-weight: 700; color: #1f2d3d; }
.pa3-asset-spec { font-size: 12px; color: #909399; }

.pa3-type-tag { display: inline-flex; align-items: center; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; flex-shrink: 0; }
.pa3-type-tag.type-1 { background: #FFF3E0; color: #E65100; }
.pa3-type-tag.type-2 { background: #E3F2FD; color: #0D47A1; }
.pa3-type-tag.type-3 { background: #F3E5F5; color: #6A1B9A; }

.pa3-status-tag { display: inline-flex; align-items: center; padding: 2px 10px; border-radius: 999px; font-size: 11px; font-weight: 600; }
.pa3-status-tag.status-1 { background: #E8F5E9; color: #2E7D32; }
.pa3-status-tag.status-2 { background: #FFF3E0; color: #E65100; }
.pa3-status-tag.status-3 { background: #F3E5F5; color: #6A1B9A; }
.pa3-status-tag.status-4 { background: #FFEBEE; color: #C62828; }

.pa3-asset-code { font-size: 12px; color: #909399; margin-top: 4px; }
.pa3-asset-qty { font-size: 13px; margin-top: 4px; }
.pa3-asset-location { font-size: 12px; color: #909399; margin-top: 4px; }
.pa3-qty-num { font-size: 14px; font-weight: 700; color: #409EFF; }
.pa3-asset-purchase { font-size: 12px; color: #909399; margin-top: 4px; }
.pa3-asset-source { font-size: 12px; color: #909399; margin-top: 4px; }

/* 空状态 */
.pa3-empty { text-align: center; padding: 60px 0; background: #fff; border-radius: 10px; }
.pa3-empty-icon { font-size: 48px; color: #dcdfe6; }
.pa3-empty-title { font-size: 16px; color: #606266; font-weight: 600; margin-top: 12px; }

/* 分页 */
.pa3-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }

/* 详情 */
.pa3-detail-body { min-height: 200px; }
.pa3-detail-section { margin-bottom: 16px; }
.pa3-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.pa3-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.pa3-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.pa3-detail-lb { color: #909399; width: 70px; flex-shrink: 0; }
.pa3-detail-remark { font-size: 13px; color: #4b5a6c; line-height: 1.7; }

@media (max-width: 768px) {
  .pa3-stats { grid-template-columns: repeat(2, 1fr); }
}
</style>