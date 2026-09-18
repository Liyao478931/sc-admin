<!--
  文件：admin/src/views/warehouse/inventory/Alert.vue
  功能：库存预警（预警列表/统计卡片/等级筛选/生成采购申请/调整安全库存/忽略/规则配置/导出）
  权限：warehouse:inventory:alert:view / handle / config / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存预警</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索与筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="物料名称"><el-input v-model="query.material_name" placeholder="请输入物料名称" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物料编码"><el-input v-model="query.material_code" placeholder="请输入物料编码" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="预警等级">
          <el-select v-model="query.alert_level" clearable placeholder="全部" style="width:130px">
            <el-option v-for="(t, v) in ALERT_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="物料分类">
          <el-cascader v-model="query.category" :options="categoryTree" :props="{ value: 'value', label: 'label', children: 'children' }" clearable placeholder="全部" style="width:180px" @change="handleCategoryChange" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6">
        <div class="stat-card stat-blue" @click="handleCardClick('all')">
          <div class="stat-icon"><i class="el-icon-bell" /></div>
          <div class="stat-info">
            <div class="stat-num">{{ stats.total_alerts }}</div>
            <div class="stat-label">预警总数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-red" @click="handleCardClick(1)">
          <div class="stat-icon"><i class="el-icon-warning-filled" /></div>
          <div class="stat-info">
            <div class="stat-num" style="color:#F56C6C">{{ stats.shortage_count }}</div>
            <div class="stat-label">短缺</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-orange" @click="handleCardClick(2)">
          <div class="stat-icon"><i class="el-icon-warning" /></div>
          <div class="stat-info">
            <div class="stat-num" style="color:#E6A23C">{{ stats.low_count }}</div>
            <div class="stat-label">偏低</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-purple" @click="handleCardClick(4)">
          <div class="stat-icon"><i class="el-icon-circle-plus" /></div>
          <div class="stat-info">
            <div class="stat-num" style="color:#9B59B6">{{ stats.overstock_count }}</div>
            <div class="stat-label">超储</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 规则提示条 -->
    <el-alert v-if="config.enabled === 0" type="warning" show-icon :closable="false" class="rule-alert" title="预警已禁用，可在「预警规则配置」中开启" />
    <el-alert v-else type="info" show-icon :closable="false" class="rule-alert" :title="`预警已开启｜低库存预警阈值：安全库存量的 ${config.threshold}%｜检查频率：${frequencyText}`" />

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新预警</el-button>
        <el-button v-permission="'warehouse:inventory:alert:config'" size="small" icon="el-icon-setting" @click="openConfigDialog">预警规则配置</el-button>
        <el-button v-permission="'warehouse:inventory:alert:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条预警</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无库存预警数据，所有物料库存正常">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="预警等级" width="100" align="center">
        <template slot-scope="s">
          <el-tag v-if="s.row.alert_level === 4" size="mini" class="purple-tag">{{ s.row.alert_level_label }}</el-tag>
          <el-tag v-else :type="s.row.alert_level_tag" size="mini">{{ s.row.alert_level_label }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="material_code" label="物料编码" width="130" />
      <el-table-column prop="material_name" label="物料名称" min-width="150" show-overflow-tooltip />
      <el-table-column label="规格型号" width="140" show-overflow-tooltip><template slot-scope="s">{{ s.row.specification || '-' }}</template></el-table-column>
      <el-table-column prop="unit" label="单位" width="80" align="center" />
      <el-table-column label="当前库存" width="130" align="right"><template slot-scope="s">{{ Number(s.row.current_stock).toFixed(4) }} {{ s.row.unit }}</template></el-table-column>
      <el-table-column label="安全库存量" width="120" align="right"><template slot-scope="s">{{ Number(s.row.safety_stock) > 0 ? Number(s.row.safety_stock).toFixed(4) : '-' }}</template></el-table-column>
      <el-table-column label="最高库存量" width="120" align="right"><template slot-scope="s">{{ Number(s.row.max_stock) > 0 ? Number(s.row.max_stock).toFixed(4) : '-' }}</template></el-table-column>
      <el-table-column label="存放位置" width="150" show-overflow-tooltip>
        <template slot-scope="s">{{ s.row.warehouse_name ? (s.row.warehouse_name + ' / ' + (s.row.location_name || '-')) : '-' }}</template>
      </el-table-column>
      <el-table-column label="预警天数" width="100" align="center"><template slot-scope="s">{{ s.row.alert_days || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="280" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-if="s.row.alert_level === 1 || s.row.alert_level === 2" v-permission="'warehouse:inventory:alert:handle'" type="text" size="mini" @click="goPurchase(s.row)">生成采购申请</el-button>
          <el-button v-permission="'warehouse:inventory:alert:config'" type="text" size="mini" @click="openAdjustDialog(s.row)">调整安全库存</el-button>
          <el-button type="text" size="mini" @click="goInventory(s.row)">查看库存</el-button>
          <el-button v-if="s.row.alert_level === 3 || s.row.alert_level === 4" v-permission="'warehouse:inventory:alert:handle'" type="text" size="mini" class="danger" @click="handleIgnore(s.row)">忽略预警</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 预警规则配置对话框 -->
    <el-dialog title="预警规则配置" :visible.sync="configVisible" width="700px" :close-on-click-modal="false">
      <el-form :model="config" label-width="140px" size="small">
        <el-divider content-position="left">全局规则</el-divider>
        <el-form-item label="启用库存预警">
          <el-switch v-model="config.enabled" :active-value="1" :inactive-value="0" />
        </el-form-item>
        <el-form-item label="预警检查频率">
          <el-select v-model="config.frequency" style="width:200px">
            <el-option label="实时" value="realtime" /><el-option label="每小时" value="hourly" /><el-option label="每天" value="daily" />
          </el-select>
        </el-form-item>
        <el-form-item label="低库存预警阈值比例">
          <el-input-number v-model="config.threshold" :min="10" :max="500" :precision="0" style="width:200px" />
          <span class="tip">%：库存低于安全库存量的该比例即触发偏低预警</span>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="configVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="configSaving" @click="handleSaveConfig">保存配置</el-button>
      </div>
    </el-dialog>

    <!-- 调整安全库存对话框 -->
    <el-dialog :title="`调整安全库存 - ${adjustRow.material_name || ''}`" :visible.sync="adjustVisible" width="500px" :close-on-click-modal="false">
      <el-descriptions v-if="adjustRow.material_id" :column="2" border size="small" style="margin-bottom:16px">
        <el-descriptions-item label="物料编码">{{ adjustRow.material_code }}</el-descriptions-item>
        <el-descriptions-item label="物料名称">{{ adjustRow.material_name }}</el-descriptions-item>
        <el-descriptions-item label="规格型号">{{ adjustRow.specification || '-' }}</el-descriptions-item>
        <el-descriptions-item label="单位">{{ adjustRow.unit || '-' }}</el-descriptions-item>
        <el-descriptions-item label="当前库存">{{ Number(adjustRow.current_stock).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="预警等级">{{ adjustRow.alert_level_label }}</el-descriptions-item>
      </el-descriptions>
      <el-form :model="adjustForm" label-width="140px" size="small">
        <el-form-item label="当前安全库存量"><span>{{ adjustRow.safety_stock != null ? Number(adjustRow.safety_stock).toFixed(4) : '-' }}</span></el-form-item>
        <el-form-item label="新安全库存量" required>
          <el-input-number v-model="adjustForm.safety_stock" :min="0" :precision="4" placeholder="请输入新的安全库存量" style="width:220px" />
        </el-form-item>
        <el-form-item label="当前最高库存量"><span>{{ adjustRow.max_stock != null ? Number(adjustRow.max_stock).toFixed(4) : '-' }}</span></el-form-item>
        <el-form-item label="新最高库存量">
          <el-input-number v-model="adjustForm.max_stock" :min="0" :precision="4" placeholder="请输入新的最高库存量" style="width:220px" />
        </el-form-item>
        <el-form-item label="调整原因">
          <el-input v-model="adjustForm.reason" type="textarea" :rows="3" placeholder="请填写调整原因" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="adjustVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="adjustSaving" @click="handleAdjust">确认调整</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getAlertList, adjustSafetyStock, ignoreAlert, getAlertConfig, saveAlertConfig, exportAlert, getMaterialCategoryTree } from '../../../api/warehouse'

const ALERT_TEXT = { 1: '短缺', 2: '偏低', 3: '充足', 4: '超储' }
const FREQ_TEXT = { realtime: '实时', hourly: '每小时', daily: '每天' }

export default {
  name: 'WarehouseInventoryAlert',
  data () {
    return {
      ALERT_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      query: { material_name: '', material_code: '', alert_level: '', category: [], category_id: 0 },
      stats: { total_alerts: 0, shortage_count: 0, low_count: 0, overstock_count: 0 },
      categoryTree: [],
      config: { enabled: 1, threshold: 100, frequency: 'hourly' },
      configVisible: false, configSaving: false,
      adjustVisible: false, adjustSaving: false, adjustRow: {}, adjustForm: { safety_stock: 0, max_stock: 0, reason: '' }
    }
  },
  computed: {
    frequencyText () { return FREQ_TEXT[this.config.frequency] || this.config.frequency }
  },
  created () {
    this.getList()
    this.loadCategoryTree()
    this.loadConfig()
  },
  methods: {
    async loadCategoryTree () {
      try {
        const r = await getMaterialCategoryTree()
        this.categoryTree = (r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.categoryTree = [] }
    },
    async loadConfig () {
      try {
        const r = await getAlertConfig()
        if (r.code === 0 && r.data) this.config = { ...this.config, ...r.data }
      } catch (e) {}
    },
    handleCategoryChange (val) {
      this.query.category_id = Array.isArray(val) && val.length ? Number(val[val.length - 1]) : 0
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.material_name) p.material_name = this.query.material_name
      if (this.query.material_code) p.material_code = this.query.material_code
      if (this.query.alert_level !== '' && this.query.alert_level !== null) p.alert_level = this.query.alert_level
      if (this.query.category_id) p.category_id = this.query.category_id
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getAlertList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = {
            total_alerts: r.data.total_alerts || 0,
            shortage_count: r.data.shortage_count || 0,
            low_count: r.data.low_count || 0,
            overstock_count: r.data.overstock_count || 0
          }
          if (r.data.config) this.config = { ...this.config, ...r.data.config }
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { material_name: '', material_code: '', alert_level: '', category: [], category_id: 0 }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    handleCardClick (level) {
      if (level === 'all') { this.query.alert_level = '' } else { this.query.alert_level = level }
      this.handleSearch()
    },
    goPurchase (row) {
      const suggest = Math.max(1, Math.ceil(Number(row.safety_stock) * 1.5 - Number(row.current_stock)))
      const copyFrom = JSON.stringify({
        request: { title: `[${row.material_name}]库存预警补货申请` },
        items: [{
          product_id: row.material_id, product_code: row.material_code, product_name: row.material_name,
          product_spec: row.specification || '', product_unit: row.unit || '',
          quantity: suggest, unit_price: 0, need_date: ''
        }]
      })
      this.$router.push({ path: '/business/purchase/request/add', query: { copyFrom: encodeURIComponent(copyFrom) } })
    },
    goInventory (row) { this.$router.push({ path: '/warehouse/inventory/query', query: { material_id: row.material_id } }) },
    openAdjustDialog (row) {
      this.adjustRow = row
      this.adjustForm = { safety_stock: Number(row.safety_stock) || 0, max_stock: Number(row.max_stock) || 0, reason: '' }
      this.adjustVisible = true
    },
    async handleAdjust () {
      if (this.adjustForm.safety_stock === undefined || this.adjustForm.safety_stock === null || this.adjustForm.safety_stock < 0) { this.$message.warning('请输入新的安全库存量'); return }
      this.adjustSaving = true
      try {
        const r = await adjustSafetyStock({
          material_id: this.adjustRow.material_id,
          safety_stock: this.adjustForm.safety_stock,
          max_stock: this.adjustForm.max_stock || 0,
          reason: this.adjustForm.reason || ''
        })
        if (r.code === 0) { this.$message.success('安全库存已更新'); this.adjustVisible = false; this.getList() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.adjustSaving = false }
    },
    handleIgnore (row) {
      this.$prompt('请输入忽略原因（可选）', `忽略预警 - ${row.material_name}`, { inputPlaceholder: '忽略原因（可选）', inputValue: '' }).then(async ({ value }) => {
        try {
          const r = await ignoreAlert(row.material_id, (value || '').trim())
          if (r.code === 0) { this.$message.success('已忽略该预警'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    openConfigDialog () { this.configVisible = true },
    async handleSaveConfig () {
      this.configSaving = true
      try {
        const r = await saveAlertConfig(this.config)
        if (r.code === 0) { this.$message.success('保存成功'); this.configVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.configSaving = false }
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportAlert(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `库存预警_${new Date().toLocaleDateString()}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.stat-row { margin-top: 16px; }
.stat-card { display: flex; align-items: center; padding: 16px 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: transform .2s; }
.stat-card:hover { transform: translateY(-3px); }
.stat-blue { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-red { background: linear-gradient(135deg, #fef0f0, #fde2e2); }
.stat-orange { background: linear-gradient(135deg, #fdf6ec, #fae8cd); }
.stat-purple { background: linear-gradient(135deg, #f5ecfb, #ecd9f7); }
.stat-icon { font-size: 30px; margin-right: 14px; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-red .stat-icon { color: #F56C6C; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-purple .stat-icon { color: #9B59B6; }
.stat-num { font-size: 24px; font-weight: bold; color: #303133; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.rule-alert { margin-top: 16px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; margin-top: 16px; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.tip { color: #909399; font-size: 12px; margin-left: 8px; }
.danger { color: #F56C6C; }
.purple-tag { background: #f5ecfb; color: #9B59B6; border-color: #e0c3f5; }
</style>
