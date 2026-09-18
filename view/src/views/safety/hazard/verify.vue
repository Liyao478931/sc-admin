<template>
  <div class="hazard-page">
    <el-breadcrumb separator="/" class="crumb">
      <el-breadcrumb-item>安全管理</el-breadcrumb-item>
      <el-breadcrumb-item>隐患管理</el-breadcrumb-item>
      <el-breadcrumb-item>验证任务</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <el-row :gutter="12" class="stat-row">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :class="{ active: quickKey === card.key }" @click="quickFilter(card.key)">
          <div class="stat-icon" :style="{ background: card.color }"><i :class="card.icon"></i></div>
          <div class="stat-info"><div class="stat-num">{{ statValue(card.key) }}</div><div class="stat-label">{{ card.label }}</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选 -->
    <div class="panel">
      <el-form :inline="true" size="small">
        <el-form-item><el-input v-model="filter.keyword" placeholder="请输入隐患名称、编号或位置" clearable style="width:200px" @keyup.enter.native="loadList" /></el-form-item>
        <el-form-item label="验证状态">
          <el-select v-model="filter.verify_status" clearable placeholder="全部状态" style="width:110px">
            <el-option label="待验证" value="pending" /><el-option label="已通过" value="passed" /><el-option label="已驳回" value="rejected" />
          </el-select>
        </el-form-item>
        <el-form-item label="等级">
          <el-select v-model="filter.hazard_level" clearable placeholder="全部等级" style="width:110px"><el-option v-for="t in dicts.level" :key="t.value" :label="t.label" :value="t.value" /></el-select>
        </el-form-item>
        <el-form-item label="类型">
          <el-select v-model="filter.hazard_type" clearable placeholder="全部类型" style="width:120px"><el-option v-for="t in dicts.type" :key="t.value" :label="t.label" :value="t.value" /></el-select>
        </el-form-item>
        <el-form-item label="整改人">
          <el-select v-model="filter.handler_id" clearable filterable placeholder="整改人" style="width:120px"><el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" /></el-select>
        </el-form-item>
        <el-form-item label="整改完成日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:220px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="loadList">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 工具栏 -->
    <div class="panel">
      <div class="toolbar">
        <div class="toolbar-left">验证任务列表 · 共 {{ total }} 条</div>
        <div class="toolbar-right"><el-button size="small" icon="el-icon-refresh" @click="loadList; loadStats">刷新</el-button></div>
      </div>

      <!-- 手机卡片 -->
      <div v-if="isMobile" class="mobile-list">
        <div v-for="h in list" :key="h.id" class="card">
          <div class="card-top"><span class="card-title">{{ h.hazard_name }}</span><el-tag :type="statusType(h.status)" size="mini">{{ statusLabel(h.status) }}</el-tag></div>
          <div class="card-line">{{ h.hazard_code }} · 等级：{{ levelLabel(h.hazard_level) }}</div>
          <div class="card-line">整改人：{{ h.handler_name || '-' }} · 完成：{{ h.handle_completed_at || '-' }}</div>
          <div class="card-actions">
            <el-button v-if="h.status === 'resolved'" size="mini" type="text" @click="openVerify(h)">验证</el-button>
            <el-button size="mini" type="text" @click="openDetail(h.id)">详情</el-button>
          </div>
        </div>
        <el-empty v-if="!list.length" description="暂无验证任务" />
      </div>

      <!-- 桌面表格 -->
      <el-table v-else :data="list" size="small" border stripe style="width:100%" highlight-current-row>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="隐患编号" width="150"><template slot-scope="{ row }"><el-link type="primary" @click="openDetail(row.id)">{{ row.hazard_code }}</el-link></template></el-table-column>
        <el-table-column prop="hazard_name" label="隐患名称" min-width="180" show-overflow-tooltip />
        <el-table-column label="隐患等级" width="80" align="center"><template slot-scope="{ row }"><el-tag :type="levelType(row.hazard_level)" size="mini">{{ levelLabel(row.hazard_level) }}</el-tag></template></el-table-column>
        <el-table-column label="隐患类型" width="100" align="center"><template slot-scope="{ row }"><span style="font-size:12px">{{ typeLabel(row.hazard_type) }}</span></template></el-table-column>
        <el-table-column prop="handler_name" label="整改人" width="80" />
        <el-table-column prop="handle_completed_at" label="整改完成时间" width="160" />
        <el-table-column label="验证状态" width="100" align="center"><template slot-scope="{ row }"><el-tag :type="statusType(row.status)" size="mini">{{ statusLabel(row.status) }}</el-tag></template></el-table-column>
        <el-table-column label="操作" width="180" fixed="right" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="(row.status === 'resolved') && (hasPerm('safety:hazard:verify:pass') || hasPerm('safety:hazard:verify:reject'))" size="mini" type="text" @click="openVerify(row)">验证</el-button>
            <el-button size="mini" type="text" @click="openDetail(row.id)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination v-if="!isMobile" class="pager" background layout="total, sizes, prev, pager, next" :total="total" :current-page="page" :page-size="limit" :page-sizes="[10,20,50,100]" @current-change="p => (page = p, loadList())" @size-change="s => (limit = s, page = 1, loadList())" />
    </div>

    <!-- 验证操作弹窗 -->
    <el-dialog title="隐患验证" :visible.sync="verifyVisible" width="700px" @open="openVerifyForm">
      <div v-loading="detailLoading">
        <el-descriptions :column="3" border size="small" title="隐患信息">
          <el-descriptions-item label="隐患编号">{{ vd.hazard_code || '-' }}</el-descriptions-item>
          <el-descriptions-item label="隐患名称">{{ vd.hazard_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="隐患等级"><el-tag :type="levelType(vd.hazard_level)" size="mini">{{ levelLabel(vd.hazard_level) }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="隐患类型">{{ typeLabel(vd.hazard_type) }}</el-descriptions-item>
          <el-descriptions-item label="发现位置">{{ vd.location || '-' }}</el-descriptions-item>
          <el-descriptions-item label="发现人">{{ vd.discovered_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="发现时间" :span="3">{{ vd.discovered_at || '-' }}</el-descriptions-item>
        </el-descriptions>
        <el-descriptions :column="3" border size="small" title="整改信息" style="margin-top:12px">
          <el-descriptions-item label="整改人">{{ vd.handler_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="整改完成">{{ vd.handle_completed_at || '-' }}</el-descriptions-item>
          <el-descriptions-item label="整改期限">{{ vd.handler_deadline || '-' }}</el-descriptions-item>
          <el-descriptions-item label="整改措施" :span="3">{{ vd.handle_measure || '-' }}</el-descriptions-item>
        </el-descriptions>

        <el-form label-width="100px" size="small" style="margin-top:16px">
          <el-form-item label="验证意见"><el-input v-model="verifyForm.opinion" type="textarea" :rows="3" maxlength="500" placeholder="请填写验证意见（至少10字）" /></el-form-item>
          <el-form-item label="验证照片">
            <el-upload action="/api/upload/image" :headers="uploadHeaders" list-type="picture-card" multiple :limit="9" :before-upload="beforeUpload" :on-success="onVerifyUpload" :on-remove="onVerifyRemove" :on-preview="onPreview"><i class="el-icon-plus"></i></el-upload>
          </el-form-item>
        </el-form>

        <!-- 验证历史 -->
        <el-collapse style="margin-top:8px">
          <el-collapse-item title="验证历史（{{ vd.verify_history ? vd.verify_history.length : 0 }}）">
            <el-timeline v-if="vd.verify_history && vd.verify_history.length">
              <el-timeline-item v-for="(h, i) in vd.verify_history" :key="i" :timestamp="h.time" placement="top">
                <div>{{ h.type === 'reject' ? '驳回' : (h.result === 'passed' ? '验证通过' : '验证') }}：{{ h.opinion }}</div>
                <div style="color:#909399;font-size:12px">{{ h.by }}</div>
              </el-timeline-item>
            </el-timeline>
            <el-empty v-else description="暂无验证历史" :image-size="50" />
          </el-collapse-item>
        </el-collapse>
      </div>
      <div slot="footer">
        <el-button type="success" :loading="submitting" @click="doPass">通过并关闭</el-button>
        <el-button type="danger" :loading="submitting" @click="doReject">驳回</el-button>
        <el-button @click="verifyVisible = false">取消</el-button>
      </div>
    </el-dialog>

    <hazard-detail-dialog :visible.sync="detailVisible" :hazard-id="detailId" />
  </div>
</template>

<script>
import { getVerifyList, getVerifyStatistics, getVerifyDetail, verifyPass, verifyReject } from '@/api/safetyHazard'
import { getDictionaryBatch } from '@/utils/dict'
import { getManagers } from '@/api/deviceAsset'
import { getToken } from '@/utils/auth'
import HazardDetailDialog from './components/DetailDialog.vue'

export default {
  name: 'HazardVerify',
  components: { HazardDetailDialog },
  data() {
    return {
      list: [], total: 0, page: 1, limit: 20, isMobile: false, quickKey: '',
      stats: {}, dicts: { type: [], level: [] }, managerList: [],
      filter: { keyword: '', verify_status: '', hazard_level: '', hazard_type: '', handler_id: '' }, dateRange: null,
      verifyVisible: false, vd: {}, detailLoading: false, verifyForm: { opinion: '', images: [] }, verifyImages: [],
      submitting: false, detailVisible: false, detailId: 0
    }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } },
    statCards() {
      return [
        { key: 'pending_total', label: '待验证总数', icon: 'el-icon-time', color: '#E6A23C' },
        { key: 'today_pending', label: '今日待验证', icon: 'el-icon-timer', color: '#409EFF' },
        { key: 'month_verified', label: '本月已验证', icon: 'el-icon-circle-check', color: '#67C23A' },
        { key: 'avg_hours', label: '平均验证时长', icon: 'el-icon-data-line', color: '#B57FEB' }
      ]
    }
  },
  async created() {
    this.isMobile = /Android|webOS|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent || '') || window.innerWidth < 768
    const dict = await getDictionaryBatch(['safety_hazard_type', 'safety_hazard_level', 'safety_hazard_status'])
    this.dicts = { type: dict['safety_hazard_type'] || [], level: dict['safety_hazard_level'] || [] }
    const m = await getManagers()
    this.managerList = m.data || []
    this.loadList(); this.loadStats()
    if (!this.$store.state.user || !this.$store.state.user.permissions || !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions').catch(() => {})
    }
  },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    statValue(key) { if (key === 'avg_hours') return this.stats.avg_hours ?? 0; return this.stats[key] || 0 },
    buildParams() {
      return { ...this.filter, page: this.page, limit: this.limit, start_date: this.dateRange ? this.dateRange[0] : '', end_date: this.dateRange ? this.dateRange[1] : '' }
    },
    async loadList() {
      try { const r = await getVerifyList(this.buildParams()); if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 } } catch (e) {}
    },
    async loadStats() { try { const r = await getVerifyStatistics(); if (r.code === 0) this.stats = r.data || {} } catch (e) {} },
    quickFilter(key) {
      if (this.quickKey === key) { this.quickKey = ''; this.filter.verify_status = '' }
      else {
        this.quickKey = key
        this.filter.verify_status = { pending_total: 'pending', today_pending: 'pending', month_verified: 'passed' }[key] || ''
      }
      this.page = 1
      this.loadList()
    },
    reset() { this.filter = { keyword: '', verify_status: '', hazard_level: '', hazard_type: '', handler_id: '' }; this.dateRange = null; this.quickKey = ''; this.page = 1; this.loadList() },
    typeLabel(v) { const t = this.dicts.type.find(x => x.value === v); return t ? t.label : v },
    levelLabel(v) { const t = this.dicts.level.find(x => x.value === v); return t ? t.label : v },
    levelType(v) { const t = this.dicts.level.find(x => x.value === v); return (t && t.style) || 'info' },
    statusLabel(v) { return { resolved: '待验证', closed: '已通过', rejected: '已驳回' }[v] || v },
    statusType(v) { return { resolved: 'warning', closed: 'success', rejected: 'danger' }[v] || 'info' },
    async openVerify(row) {
      this.verifyForm = { opinion: '', images: [] }; this.verifyImages = []; this.vd = { hazard_code: row.hazard_code, hazard_name: row.hazard_name, hazard_level: row.hazard_level, hazard_type: row.hazard_type }
      this.verifyVisible = true
      this.detailLoading = true
      try { const r = await getVerifyDetail(row.id); if (r.code === 0) this.vd = r.data } catch (e) {}
      this.detailLoading = false
    },
    openVerifyForm() {},
    beforeUpload(f) { if (f.size > 5 * 1024 * 1024) { this.$message.error('照片不能超过5MB'); return false } return true },
    onVerifyUpload(res, file) { if (res.code === 0 && res.data && res.data.url) this.verifyImages.push(res.data.url) },
    onVerifyRemove(file) { const url = file.url || (file.response && file.response.data && file.response.data.url); this.verifyImages = this.verifyImages.filter(x => x !== url) },
    onPreview(file) { if (file.url) window.open(file.url, '_blank') },
    openDetail(id) { this.detailId = id; this.detailVisible = true },
    async doPass() {
      if (!this.verifyForm.opinion || this.verifyForm.opinion.length < 10) { this.$message.warning('请填写至少10字的验证意见'); return }
      this.submitting = true
      try { await verifyPass(this.vd.id, { verify_opinion: this.verifyForm.opinion, verify_attachments: this.verifyImages }); this.$message.success('验证通过，隐患已关闭'); this.verifyVisible = false; this.loadList(); this.loadStats() } catch (e) {}
      this.submitting = false
    },
    async doReject() {
      if (!this.verifyForm.opinion || this.verifyForm.opinion.length < 10) { this.$message.warning('请填写至少10字的驳回原因'); return }
      this.$confirm('确定驳回该隐患吗？驳回后需重新整改。', '提示', { type: 'warning' }).then(async () => {
        this.submitting = true
        try { await verifyReject(this.vd.id, { reject_reason: this.verifyForm.opinion }); this.$message.success('已驳回'); this.verifyVisible = false; this.loadList(); this.loadStats() } catch (e) {}
        this.submitting = false
      }).catch(() => {})
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
.toolbar-left { color: #606266; font-size: 13px; }
.pager { margin-top: 12px; text-align: right; }
.mobile-list { display: flex; flex-direction: column; gap: 10px; }
.card { border: 1px solid #ebeef5; border-radius: 8px; padding: 10px; }
.card-top { display: flex; justify-content: space-between; align-items: center; }
.card-title { font-size: 14px; font-weight: 600; }
.card-line { color: #606266; font-size: 12px; margin: 3px 0; }
.card-actions { display: flex; gap: 2px; margin-top: 6px; }
</style>
