<template>
  <div class="hazard-page">
    <!-- 面包屑 -->
    <el-breadcrumb separator="/" class="crumb">
      <el-breadcrumb-item>安全管理</el-breadcrumb-item>
      <el-breadcrumb-item>隐患管理</el-breadcrumb-item>
      <el-breadcrumb-item>隐患列表</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <el-row :gutter="12" class="stat-row">
      <el-col :span="5" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :class="{ active: quickStatus === card.key }" @click="quickFilter(card.key)">
          <div class="stat-icon" :style="{ background: card.color }"><i :class="card.icon"></i></div>
          <div class="stat-info"><div class="stat-num">{{ statValue(card.key) }}</div><div class="stat-label">{{ card.label }}</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <div class="panel">
      <el-form :inline="true" :model="filter" size="small" class="filter-form">
        <el-form-item>
          <el-input v-model="filter.keyword" placeholder="请输入隐患名称、编号或位置" clearable style="width:220px" @keyup.enter.native="onSearch" />
        </el-form-item>
        <el-form-item label="类型">
          <el-select v-model="filter.hazard_type" multiple clearable placeholder="全部类型" style="width:130px">
            <el-option v-for="t in dicts.type" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="等级">
          <el-select v-model="filter.hazard_level" multiple clearable placeholder="全部等级" style="width:120px">
            <el-option v-for="t in dicts.level" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filter.status" multiple clearable placeholder="全部状态" style="width:120px">
            <el-option v-for="t in dicts.status" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="showMore" label="来源">
          <el-select v-model="filter.source_type" clearable placeholder="全部来源" style="width:120px">
            <el-option v-for="t in dicts.source" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="showMore" label="发现日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:220px" />
        </el-form-item>
        <el-form-item v-if="showMore" label="整改人">
          <el-select v-model="filter.handler_id" clearable filterable placeholder="整改人" style="width:120px">
            <el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="showMore" label="发现人">
          <el-select v-model="filter.discovered_by" clearable filterable placeholder="发现人" style="width:120px">
            <el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="onReset">重置</el-button>
          <el-button type="text" @click="showMore = !showMore">{{ showMore ? '收起' : '展开' }}<i :class="showMore ? 'el-icon-arrow-up' : 'el-icon-arrow-down'" /></el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 工具栏 -->
    <div class="panel">
      <div class="toolbar">
        <div class="toolbar-left">
          <span v-if="selection.length" class="sel-tip">已选 {{ selection.length }} 项</span>
          <el-button v-if="hasPerm('safety:hazard:delete')" :disabled="!selection.length" size="small" type="danger" icon="el-icon-delete" @click="batchDelete">批量删除</el-button>
          <el-button v-if="hasPerm('safety:hazard:export')" size="small" icon="el-icon-download" @click="doExport">导出</el-button>
          <el-button v-if="hasPerm('safety:hazard:add')" size="small" type="success" icon="el-icon-plus" @click="$router.push('/safety/hazard/create')">新增隐患</el-button>
        </div>
        <div class="toolbar-right"><el-button size="small" icon="el-icon-refresh" @click="loadList; loadStats">刷新</el-button></div>
      </div>

      <!-- 手机端卡片 -->
      <div v-if="isMobile" class="mobile-list">
        <div v-for="h in list" :key="h.id" class="mobile-card">
          <div class="mc-top">
            <span class="mc-name">{{ h.hazard_name }}</span>
            <el-tag :type="statusType(h.status)" size="mini">{{ statusLabel(h.status) }}</el-tag>
          </div>
          <div class="mc-line">编号：{{ h.hazard_code }} · 等级：{{ levelLabel(h.hazard_level) }}</div>
          <div class="mc-line">发现人：{{ h.discovered_by_name }} · {{ h.discovered_at }}</div>
          <div class="mc-actions">
            <el-button size="mini" type="text" @click="openDetail(h.id)">详情</el-button>
            <el-button v-if="['pending','processing','rejected'].includes(h.status)" size="mini" type="text" @click="$router.push('/safety/hazard/handle?id=' + h.id)">整改</el-button>
            <el-button v-if="h.status === 'resolved'" size="mini" type="text" @click="openVerify(h)">验证</el-button>
            <el-button v-if="['pending','rejected'].includes(h.status)" size="mini" type="text" style="color:#F56C6C" @click="delOne(h)">删除</el-button>
          </div>
        </div>
        <el-empty v-if="!list.length" description="暂无隐患数据" />
      </div>

      <!-- 桌面表格 -->
      <el-table v-else :data="list" size="small" border stripe style="width:100%" @selection-change="sel => (selection = sel)" highlight-current-row>
        <el-table-column type="selection" width="44" align="center" />
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="隐患编号" width="150">
          <template slot-scope="{ row }"><el-link type="primary" @click="openDetail(row.id)">{{ row.hazard_code }}</el-link></template>
        </el-table-column>
        <el-table-column prop="hazard_name" label="隐患名称" min-width="200" show-overflow-tooltip />
        <el-table-column label="隐患类型" width="100" align="center">
          <template slot-scope="{ row }"><el-tag :type="typeStyle(row.hazard_type)" size="small" effect="plain">{{ typeLabel(row.hazard_type) }}</el-tag></template>
        </el-table-column>
        <el-table-column label="等级" width="80" align="center">
          <template slot-scope="{ row }"><el-tag :type="levelType(row.hazard_level)" size="mini">{{ levelLabel(row.hazard_level) }}</el-tag></template>
        </el-table-column>
        <el-table-column label="来源" width="100" align="center">
          <template slot-scope="{ row }"><span style="font-size:12px">{{ sourceLabel(row.source_type) }}</span></template>
        </el-table-column>
        <el-table-column prop="discovered_by_name" label="发现人" width="80" />
        <el-table-column prop="discovered_at" label="发现时间" width="160" />
        <el-table-column prop="handler_name" label="整改人" width="80" />
        <el-table-column label="整改期限" width="110">
          <template slot-scope="{ row }"><span :style="{ color: isOverdue(row) ? '#F56C6C' : '' }">{{ row.handler_deadline || '-' }}</span></template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }"><el-tag :type="statusType(row.status)" size="mini">{{ statusLabel(row.status) }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right" align="center">
          <template slot-scope="{ row }">
            <el-button size="mini" type="text" @click="openDetail(row.id)">详情</el-button>
            <el-button v-if="(['pending','processing','rejected'].includes(row.status)) && hasPerm('safety:hazard:edit')"  size="mini" type="text" @click="$router.push('/safety/hazard/handle?id=' + row.id)">整改</el-button>
            <el-button v-if="(row.status === 'resolved') && hasPerm('safety:hazard:status')"  size="mini" type="text" @click="openVerify(row)">验证</el-button>
            <el-button v-if="(['pending','rejected'].includes(row.status)) && hasPerm('safety:hazard:delete')"  size="mini" type="text" style="color:#F56C6C" @click="delOne(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination v-if="!isMobile" class="pager" background layout="total, sizes, prev, pager, next, jumper"
                     :total="total" :current-page="page" :page-size="limit" :page-sizes="[10,20,50,100]"
                     @current-change="p => (page = p, loadList())" @size-change="s => (limit = s, page = 1, loadList())" />
    </div>

    <!-- 详情弹窗 -->
    <hazard-detail-dialog :visible.sync="detailVisible" :hazard-id="detailId" />
    <!-- 验证对话框 -->
    <el-dialog title="隐患验证" :visible.sync="verifyVisible" width="500px">
      <el-form label-width="100px" size="small">
        <el-form-item label="验证结果">
          <el-radio-group v-model="verifyForm.result">
            <el-radio label="passed">通过</el-radio>
            <el-radio label="rejected">驳回</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="验证意见"><el-input v-model="verifyForm.opinion" type="textarea" :rows="3" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="verifyVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="doVerify">确认</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getHazardList, getHazardDetail, exportHazards, getHazardStatistics, batchDeleteHazards, changeHazardStatus, deleteHazard } from '@/api/safetyHazard'
import { getDictionaryBatch } from '@/utils/dict'
import { getManagers } from '@/api/deviceAsset'
import HazardDetailDialog from './components/DetailDialog.vue'

export default {
  name: 'SafetyHazardList',
  components: { HazardDetailDialog },
  data() {
    return {
      list: [], total: 0, page: 1, limit: 20, selection: [], isMobile: false, showMore: false,
      quickStatus: '',
      dicts: { type: [], level: [], source: [], status: [], verify: [] },
      managerList: [], dateRange: null,
      filter: { keyword: '', hazard_type: [], hazard_level: [], status: [], source_type: '', handler_id: '', discovered_by: '' },
      stats: {},
      detailVisible: false, detailId: 0,
      verifyVisible: false, verifyForm: { id: 0, result: 'passed', opinion: '' }
    }
  },
  computed: {
    statCards() {
      return [
        { key: 'total', label: '全部隐患', icon: 'el-icon-s-data', color: '#409EFF' },
        { key: 'pending', label: '待处理', icon: 'el-icon-time', color: '#E6A23C' },
        { key: 'processing', label: '整改中', icon: 'el-icon-setting', color: '#B57FEB' },
        { key: 'resolved', label: '待验证', icon: 'el-icon-check', color: '#409EFF' },
        { key: 'closed', label: '已关闭', icon: 'el-icon-circle-check', color: '#67C23A' }
      ]
    }
  },
  async created() {
    this.isMobile = /Android|webOS|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent || '') || window.innerWidth < 768
    this.loadDicts()
    this.loadManagers()
    this.loadList()
    this.loadStats()
    if (!this.$store.state.user || !this.$store.state.user.permissions || !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions').catch(() => {})
    }
  },
  methods: {
    hasPerm(code) {
      const perms = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return perms.indexOf(code) > -1
    },
    async loadDicts() {
      try {
        const res = await getDictionaryBatch(['safety_hazard_type', 'safety_hazard_level', 'safety_hazard_source', 'safety_hazard_status', 'verify_result'])
        this.dicts = { type: res['safety_hazard_type'] || [], level: res['safety_hazard_level'] || [], source: res['safety_hazard_source'] || [], status: res['safety_hazard_status'] || [], verify: res['verify_result'] || [] }
      } catch (e) {}
    },
    async loadManagers() { try { const r = await getManagers(); this.managerList = r.data || [] } catch (e) {} },
    buildParams() {
      return {
        page: this.page, limit: this.limit,
        keyword: this.filter.keyword || '',
        hazard_type: this.filter.hazard_type && this.filter.hazard_type.length ? this.filter.hazard_type.join(',') : '',
        hazard_level: this.filter.hazard_level && this.filter.hazard_level.length ? this.filter.hazard_level.join(',') : '',
        status: this.filter.status && this.filter.status.length ? this.filter.status.join(',') : '',
        source_type: this.filter.source_type || '',
        handler_id: this.filter.handler_id || '',
        discovered_by: this.filter.discovered_by || '',
        start_date: this.dateRange ? this.dateRange[0] : '',
        end_date: this.dateRange ? this.dateRange[1] : ''
      }
    },
    async loadList() {
      try {
        const res = await getHazardList(this.buildParams())
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) {}
    },
    async loadStats() {
      try { const res = await getHazardStatistics(); this.stats = res.data || {} } catch (e) {}
    },
    statValue(key) {
      if (key === 'total') return this.stats.total || 0
      return (this.stats.by_status && this.stats.by_status[key]) || 0
    },
    quickFilter(key) {
      if (key === 'total') { this.filter.status = []; this.quickStatus = '' }
      else { this.filter.status = [key]; this.quickStatus = key }
      this.page = 1
      this.loadList()
    },
    onSearch() { this.page = 1; this.loadList() },
    onReset() {
      this.filter = { keyword: '', hazard_type: [], hazard_level: [], status: [], source_type: '', handler_id: '', discovered_by: '' }
      this.dateRange = null
      this.page = 1
      this.quickStatus = ''
      this.loadList()
    },
    typeLabel(v) { const t = this.dicts.type.find(x => x.value === v); return t ? t.label : (v || '-') },
    typeStyle(v) { return { equipment: 'primary', environment: 'success', behavior: 'warning', management: 'info' }[v] || 'info' },
    levelLabel(v) { const t = this.dicts.level.find(x => x.value === v); return t ? t.label : (v || '-') },
    levelType(v) { const t = this.dicts.level.find(x => x.value === v); return (t && t.style) || 'info' },
    sourceLabel(v) { const t = this.dicts.source.find(x => x.value === v); return t ? t.label : (v || '-') },
    statusLabel(v) { const t = this.dicts.status.find(x => x.value === v); return t ? t.label : (v || '-') },
    statusType(v) { const t = this.dicts.status.find(x => x.value === v); return (t && t.style) || 'info' },
    isOverdue(row) { return row.handler_deadline && row.status === 'processing' && row.handler_deadline < new Date().toISOString().slice(0, 10) },
    openDetail(id) { this.detailId = id; this.detailVisible = true },
    openVerify(row) { this.verifyForm = { id: row.id, result: 'passed', opinion: '' }; this.verifyVisible = true },
    doVerify() {
      changeHazardStatus(this.verifyForm.id, { status: this.verifyForm.result === 'passed' ? 'closed' : 'rejected', verify_opinion: this.verifyForm.opinion, reject_reason: this.verifyForm.result === 'rejected' ? this.verifyForm.opinion : '' })
        .then(() => { this.$message.success('验证完成'); this.verifyVisible = false; this.loadList(); this.loadStats() })
    },
    delOne(row) {
      this.$confirm(`确定删除隐患 [${row.hazard_name}] 吗？`, '提示', { type: 'warning' })
        .then(() => deleteHazard(row.id).then(() => { this.$message.success('已删除'); this.loadList(); this.loadStats() })).catch(() => {})
    },
    batchDelete() {
      if (!this.selection.length) { this.$message.warning('请选择要删除的隐患'); return }
      this.$confirm(`确定删除选中的 ${this.selection.length} 条隐患吗？仅待处理和已驳回状态可删除。`, '提示', { type: 'warning' })
        .then(() => batchDeleteHazards(this.selection.map(x => x.id)).then(res => { this.$message.success(res.msg || '删除完成'); this.loadList(); this.loadStats() })).catch(() => {})
    },
    doExport() {
      exportHazards(this.buildParams()).then(res => { if (res.code === 0 && res.data && res.data.url) window.open(res.data.url, '_blank') })
    }
  }
}
</script>

<style scoped>
.hazard-page { padding: 16px; }
.crumb { margin-bottom: 14px; }
.stat-row { margin-bottom: 12px; }
.stat-card { display: flex; align-items: center; gap: 10px; background: #fff; border-radius: 8px; padding: 12px; box-shadow: 0 2px 8px rgba(0,0,0,.04); cursor: pointer; border: 2px solid transparent; transition: transform .2s; }
.stat-card:hover { transform: translateY(-2px); }
.stat-card.active { border-color: #409EFF; }
.stat-icon { width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 20px; }
.stat-num { font-size: 20px; font-weight: 700; }
.stat-label { color: #909399; font-size: 12px; }
.panel { background: #fff; border-radius: 8px; padding: 12px; margin-bottom: 12px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.toolbar-left { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.sel-tip { color: #409EFF; font-size: 13px; }
.pager { margin-top: 12px; text-align: right; }
.mobile-list { display: flex; flex-direction: column; gap: 10px; }
.mobile-card { border: 1px solid #ebeef5; border-radius: 8px; padding: 10px; }
.mc-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.mc-name { font-size: 14px; font-weight: 600; }
.mc-line { color: #606266; font-size: 12px; margin: 3px 0; }
.mc-actions { display: flex; gap: 2px; flex-wrap: wrap; margin-top: 6px; }
</style>
