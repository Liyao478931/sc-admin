<template>
  <div class="hazard-detail-page" v-loading="loading">
    <!-- 顶部标题 + 操作按钮 -->
    <div class="head-bar">
      <div class="head-left">
        <h2 class="page-title">隐患详情</h2>
        <el-tag :type="statusType" size="medium">{{ statusLabel }}</el-tag>
      </div>
      <div class="head-actions">
        <el-button v-if="(['pending','rejected'].includes(d.status)) && hasPerm('safety:hazard:edit')"  size="small" type="primary" icon="el-icon-edit" @click="$router.push('/safety/hazard/create?edit=' + d.id)">编辑</el-button>
        <el-button v-if="(['pending','processing','rejected'].includes(d.status)) && hasPerm('safety:hazard:handle:complete')"  size="small" type="success" icon="el-icon-s-tools" @click="$router.push('/safety/hazard/handle?id=' + d.id)">整改处理</el-button>
        <el-button v-if="(d.status === 'resolved') && (hasPerm('safety:hazard:verify:pass') || hasPerm('safety:hazard:verify:reject'))" size="small" type="primary" icon="el-icon-finished" @click="verifyVisible = true">验证操作</el-button>
        <el-button v-if="(d.status === 'closed') && hasPerm('safety:hazard:reopen')"  size="small" type="warning" icon="el-icon-refresh-left" @click="reopen">重新打开</el-button>
        <el-button v-if="(['pending','rejected'].includes(d.status)) && hasPerm('safety:hazard:delete')"  size="small" type="danger" icon="el-icon-delete" @click="del">删除</el-button>
        <el-button size="small" icon="el-icon-printer" @click="print">打印</el-button>
      </div>
    </div>

    <!-- 概要信息卡片 -->
    <el-card shadow="always" class="summary-card">
      <el-row :gutter="16">
        <el-col :span="5"><div class="sum-label">隐患编号</div><div class="sum-value">{{ d.hazard_code || '-' }}</div></el-col>
        <el-col :span="5"><div class="sum-label">隐患名称</div><div class="sum-value">{{ d.hazard_name || '-' }}</div></el-col>
        <el-col :span="4"><div class="sum-label">隐患类型</div><div class="sum-value"><el-tag size="mini">{{ typeLabel }}</el-tag></div></el-col>
        <el-col :span="4"><div class="sum-label">隐患等级</div><div class="sum-value"><el-tag :type="levelType" size="mini">{{ levelLabel }}</el-tag></div></el-col>
        <el-col :span="6"><div class="sum-label">状态</div><div class="sum-value"><el-tag :type="statusType" size="mini">{{ statusLabel }}</el-tag></div></el-col>
      </el-row>
      <el-row :gutter="16" class="sum-row2">
        <el-col :span="6"><div class="sum-label">发现人</div><div class="sum-value">{{ d.discovered_by_name || '-' }}</div></el-col>
        <el-col :span="6"><div class="sum-label">发现时间</div><div class="sum-value">{{ d.discovered_at || '-' }}</div></el-col>
        <el-col :span="6"><div class="sum-label">整改人</div><div class="sum-value">{{ d.handler_name || '-' }}</div></el-col>
        <el-col :span="6"><div class="sum-label">整改期限</div><div class="sum-value">{{ d.handler_deadline || '-' }}</div></el-col>
      </el-row>
    </el-card>

    <!-- Tab 信息区 -->
    <el-card shadow="never" class="tabs-card">
      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="base">
          <el-descriptions :column="3" border size="small">
            <template slot="title"><b>隐患信息</b></template>
            <el-descriptions-item label="隐患编号">{{ d.hazard_code || '-' }}</el-descriptions-item>
            <el-descriptions-item label="隐患名称">{{ d.hazard_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="隐患类型">{{ typeLabel }}</el-descriptions-item>
            <el-descriptions-item label="隐患等级"><el-tag :type="levelType" size="mini">{{ levelLabel }}</el-tag></el-descriptions-item>
            <el-descriptions-item label="来源类型">{{ sourceLabel }}</el-descriptions-item>
            <el-descriptions-item label="来源编号">
              <el-link v-if="needSource && d.source_id" type="primary" @click="goSource">{{ d.source_id }}</el-link>
              <span v-else>-</span>
            </el-descriptions-item>
            <el-descriptions-item label="状态"><el-tag :type="statusType" size="mini">{{ statusLabel }}</el-tag></el-descriptions-item>
            <el-descriptions-item label="发现位置">{{ d.location || '-' }}</el-descriptions-item>
            <el-descriptions-item label="备注">{{ d.remark || '-' }}</el-descriptions-item>
          </el-descriptions>
          <el-divider content-position="left">发现信息</el-divider>
          <el-descriptions :column="3" border size="small">
            <el-descriptions-item label="发现人">{{ d.discovered_by_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发现时间">{{ d.discovered_at || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发现位置">{{ d.location || '-' }}</el-descriptions-item>
            <el-descriptions-item label="隐患描述" :span="3">{{ d.hazard_desc || '-' }}</el-descriptions-item>
            <el-descriptions-item label="隐患图片" :span="3">
              <el-image v-for="(img, i) in hazardImages" :key="i" :src="img" style="width:80px;height:80px;margin-right:8px" fit="cover" :preview-src-list="hazardImages" />
              <span v-if="!hazardImages.length">-</span>
            </el-descriptions-item>
          </el-descriptions>
          <el-divider content-position="left">整改信息</el-divider>
          <el-descriptions :column="3" border size="small">
            <el-descriptions-item label="整改人">{{ d.handler_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="整改期限">{{ d.handler_deadline || '-' }}</el-descriptions-item>
            <el-descriptions-item label="整改完成">{{ d.handle_completed_at || '-' }}</el-descriptions-item>
            <el-descriptions-item label="整改措施" :span="3">{{ d.handle_measure || '-' }}</el-descriptions-item>
            <el-descriptions-item label="整改附件" :span="3">
              <el-image v-for="(a, i) in handleAttachments" :key="i" :src="a" style="width:80px;height:80px;margin-right:8px" fit="cover" :preview-src-list="handleAttachments" />
              <span v-if="!handleAttachments.length">-</span>
            </el-descriptions-item>
          </el-descriptions>
          <el-divider content-position="left">验证信息</el-divider>
          <el-descriptions :column="3" border size="small">
            <el-descriptions-item label="验证人">{{ d.verifier_name || d.verified_by_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="验证时间">{{ d.verified_at || '-' }}</el-descriptions-item>
            <el-descriptions-item label="验证结果">{{ verifyLabel }}</el-descriptions-item>
            <el-descriptions-item label="验证意见" :span="3">{{ d.verify_opinion || '-' }}</el-descriptions-item>
            <el-descriptions-item label="验证附件" :span="2">
              <el-image v-for="(a, i) in verifyAttachments" :key="i" :src="a" style="width:60px;height:60px;margin-right:6px" fit="cover" :preview-src-list="verifyAttachments" />
              <span v-if="!verifyAttachments.length">-</span>
            </el-descriptions-item>
            <el-descriptions-item label="驳回次数">{{ d.reject_count || 0 }}<span v-if="d.reject_reason" style="margin-left:8px;color:#F56C6C">原因：{{ d.reject_reason }}</span></el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <!-- 整改历史 -->
        <el-tab-pane label="整改历史" name="handle">
          <el-timeline v-if="handleHistory.length">
            <el-timeline-item v-for="(h, i) in handleHistory" :key="i" :timestamp="h.time" placement="top">
              <div>整改：{{ h.content }}</div><div style="color:#909399;font-size:12px">处理人：{{ h.by }}</div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无整改记录" :image-size="60" />
        </el-tab-pane>

        <!-- 验证历史 -->
        <el-tab-pane label="验证历史" name="verify">
          <el-timeline v-if="verifyHistory.length">
            <el-timeline-item v-for="(v, i) in verifyHistory" :key="i" :timestamp="v.time" placement="top">
              <div :style="{ color: v.type === 'reject' ? '#F56C6C' : '' }">{{ v.type === 'reject' ? '驳回' : (v.result === 'passed' ? '验证通过' : '验证') }}：{{ v.opinion }}</div>
              <div style="color:#909399;font-size:12px">{{ v.by }}</div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无验证记录" :image-size="60" />
        </el-tab-pane>

        <!-- 操作记录 -->
        <el-tab-pane label="操作记录" name="logs">
          <el-timeline v-if="(d.operation_logs || []).length">
            <el-timeline-item v-for="l in d.operation_logs" :key="l.id" :timestamp="l.created_at" placement="top">
              <div>{{ l.action }}：{{ l.detail }}</div><div style="color:#909399;font-size:12px">{{ l.real_name }}</div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无操作记录" :image-size="60" />
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 底部返回栏 -->
    <div class="bottom-bar"><el-button size="small" @click="$router.back()">返回</el-button></div>

    <!-- 验证操作对话框 -->
    <hazard-verify-dialog :visible.sync="verifyVisible" :hazard-id="d.id" @pass="doPass" @reject="doReject" />
  </div>
</template>

<script>
import { getHazardDetail, deleteHazard, reopenHazard, verifyPass, verifyReject } from '@/api/safetyHazard'
import { getDictionaryBatch } from '@/utils/dict'
import HazardVerifyDialog from './components/VerifyDialog.vue'

export default {
  name: 'HazardDetail',
  components: { HazardVerifyDialog },
  data() {
    return {
      id: 0, d: {}, loading: false, activeTab: 'base', verifyVisible: false,
      dicts: { type: [], level: [], source: [], status: [], verify: [] }
    }
  },
  computed: {
    hazardImages() { return this.decArr(this.d.hazard_images) },
    handleAttachments() { return this.decArr(this.d.handle_attachments) },
    verifyAttachments() { return this.decArr(this.d.verify_attachments) },
    needSource() { return ['inspection', 'safety_check', 'repair'].includes(this.d.source_type) },
    typeLabel() { const t = this.dicts.type.find(x => x.value === this.d.hazard_type); return t ? t.label : (this.d.hazard_type || '-') },
    levelLabel() { const t = this.dicts.level.find(x => x.value === this.d.hazard_level); return t ? t.label : (this.d.hazard_level || '-') },
    levelType() { const t = this.dicts.level.find(x => x.value === this.d.hazard_level); return (t && t.style) || 'info' },
    sourceLabel() { const t = this.dicts.source.find(x => x.value === this.d.source_type); return t ? t.label : (this.d.source_type || '-') },
    statusLabel() { const t = this.dicts.status.find(x => x.value === this.d.status); return t ? t.label : (this.d.status || '-') },
    statusType() { const t = this.dicts.status.find(x => x.value === this.d.status); return (t && t.style) || 'info' },
    verifyLabel() { const t = this.dicts.verify.find(x => x.value === this.d.verify_result); return t ? t.label : (this.d.verify_result || '-') },
    handleHistory() {
      const list = []
      if (this.d.handler_name && this.d.handle_measure) list.push({ by: this.d.handler_name, time: this.d.handle_completed_at || '-', content: this.d.handle_measure })
      return list
    },
    verifyHistory() {
      const list = []
      if (this.d.verifier_name && this.d.verified_at) list.push({ by: this.d.verifier_name, time: this.d.verified_at, result: this.d.verify_result, opinion: this.d.verify_opinion, type: 'verify' })
      ;(this.d.reject_history || []).forEach(r => list.push({ by: r.by || '', time: r.time || '', opinion: r.reason || '', type: 'reject' }))
      return list.sort((a, b) => String(a.time).localeCompare(String(b.time)))
    }
  },
  async created() {
    this.id = Number(this.$route.query.id || 0)
    const dict = await getDictionaryBatch(['safety_hazard_type', 'safety_hazard_level', 'safety_hazard_source', 'safety_hazard_status', 'verify_result'])
    this.dicts = { type: dict['safety_hazard_type'] || [], level: dict['safety_hazard_level'] || [], source: dict['safety_hazard_source'] || [], status: dict['safety_hazard_status'] || [], verify: dict['verify_result'] || [] }
    if (this.id) this.loadData()
    else this.$message.error('缺少隐患ID')
    if (!this.$store.state.user || !this.$store.state.user.permissions || !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions').catch(() => {})
    }
  },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    decArr(v) { return Array.isArray(v) ? v : (typeof v === 'string' && v ? (JSON.parse(v) || []) : []) },
    async loadData() {
      this.loading = true
      try { const res = await getHazardDetail(this.id); if (res.code === 0) this.d = res.data } catch (e) {}
      this.loading = false
    },
    async doPass({ id, opinion, images }) {
      if (!opinion || opinion.length < 10) { this.$message.warning('请填写至少10字的验证意见'); return }
      try { await verifyPass(id, { verify_opinion: opinion, verify_attachments: images }); this.$message.success('验证通过，隐患已关闭'); this.verifyVisible = false; this.loadData() } catch (e) {}
    },
    async doReject({ id, reason }) {
      if (!reason || reason.length < 10) { this.$message.warning('请填写至少10字的驳回原因'); return }
      this.$confirm('确定驳回该隐患吗？驳回后需重新整改。', '提示', { type: 'warning' }).then(async () => {
        try { await verifyReject(id, { reject_reason: reason }); this.$message.success('已驳回'); this.verifyVisible = false; this.loadData() } catch (e) {}
      }).catch(() => {})
    },
    del() {
      this.$confirm('确定删除该隐患吗？仅待处理和已驳回状态可删除。', '提示', { type: 'warning' })
        .then(() => deleteHazard(this.id).then(() => { this.$message.success('已删除'); this.$router.push('/safety/hazard') })).catch(() => {})
    },
    reopen() {
      this.$confirm('确定重新打开该已关闭的隐患吗？状态将变为待处理。', '提示', { type: 'warning' })
        .then(() => reopenHazard(this.id).then(() => { this.$message.success('已重新打开'); this.loadData() })).catch(() => {})
    },
    goSource() {
      // 来源关联跳转（对应模块详情页）
      const routes = { inspection: '/device/inspection', safety_check: '/safety/inspection', repair: '/safety/hazard' }
      const p = routes[this.d.source_type]
      if (p) this.$router.push({ path: p, query: { id: this.d.source_id } })
    },
    print() { window.print() }
  }
}
</script>

<style scoped>
.hazard-detail-page { padding: 16px; }
.head-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; flex-wrap: wrap; gap: 10px; }
.head-left { display: flex; align-items: center; gap: 10px; }
.page-title { font-size: 20px; margin: 0; }
.head-actions { display: flex; gap: 8px; flex-wrap: wrap; }
.summary-card { margin-bottom: 16px; }
.sum-label { color: #909399; font-size: 12px; margin-bottom: 4px; }
.sum-value { font-size: 14px; font-weight: 500; }
.sum-row2 { margin-top: 12px; border-top: 1px solid #f0f0f0; padding-top: 12px; }
.tabs-card { min-height: 400px; }
.bottom-bar { position: fixed; bottom: 0; left: 50%; transform: translateX(-50%); width: 100%; max-width: 1200px; background: #fff; padding: 10px 20px; border-top: 1px solid #ebeef5; z-index: 10; }
@media print { .head-actions, .bottom-bar { display: none !important; } }
</style>
