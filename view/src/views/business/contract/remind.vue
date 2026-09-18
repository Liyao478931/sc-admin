<!--
  文件：admin/src/views/business/contract/remind.vue
  功能：合同到期提醒（即将到期 30 天内 + 已过期）
    - 统计卡片（即将到期/已过期）
    - 列表（按到期日期升序，即将到期优先）
    - 点击合同跳转详情
-->
<template>
  <div class="remind-page">
    <!-- 统计卡片 -->
    <el-row :gutter="14" class="stat-row">
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num orange">{{ stats.soon || 0 }}</div><div class="stat-label">即将到期（{{ stats.remind_days || 30 }}天内）</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num red">{{ stats.expired || 0 }}</div><div class="stat-label">已过期</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ (stats.soon || 0) + (stats.expired || 0) }}</div><div class="stat-label">需要关注</div></el-card></el-col>
    </el-row>

    <el-card shadow="never">
      <div class="toolbar">
        <el-radio-group v-model="remindType" size="small" @change="p => { page = 1; loadList() }">
          <el-radio-button label="all">全部</el-radio-button>
          <el-radio-button label="soon">即将到期</el-radio-button>
          <el-radio-button label="expired">已过期</el-radio-button>
        </el-radio-group>
        <span class="flex-1"></span>
        <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column prop="contract_no" label="合同编号" width="160" />
        <el-table-column prop="contract_name" label="合同名称" min-width="160" show-overflow-tooltip />
        <el-table-column label="合同类型" width="110" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="typeTag(s.row.contract_type)">{{ s.row.contract_type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="party_name" label="客户/供应商" min-width="130" show-overflow-tooltip />
        <el-table-column label="合同金额" width="110">
          <template slot-scope="s">¥{{ Number(s.row.contract_amount || 0).toLocaleString() }}</template>
        </el-table-column>
        <el-table-column label="到期日期" width="120">
          <template slot-scope="s">
            <span :style="{ color: s.row.remind_type === 'expired' ? '#f56c6c' : '#e6a23c', fontWeight: 600 }">{{ s.row.expiry_date }}</span>
          </template>
        </el-table-column>
        <el-table-column label="提醒状态" width="100" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.remind_type === 'expired' ? 'danger' : 'warning'">{{ s.row.remind_type === 'expired' ? '已过期' : '即将到期' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="responsible_person_name" label="负责人" width="90" />
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row.id)">详情</el-button></template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="20" :current-page="page" @current-change="p => { page = p; loadList() }" />
    </el-card>
  </div>
</template>

<script>
import { getContractRemindList, getContractRemindStatistics } from '../../../api/businessContract'

export default {
  name: 'BusinessContractRemind',
  data() {
    return {
      loading: false,
      list: [], total: 0, page: 1,
      stats: {},
      remindType: 'all'
    }
  },
  created() { this.loadStats(); this.loadList() },
  methods: {
    typeTag(t) { return { sales: 'primary', purchase: 'success', repair_service: 'warning' }[t] || 'info' },
    async loadStats() {
      try { const r = await getContractRemindStatistics(); if (r.code === 0) this.stats = r.data || {} } catch (e) {}
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getContractRemindList({ remind_type: this.remindType, page: this.page, limit: 20 })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    openDetail(id) { this.$router.push({ path: '/business/contract', query: { detail: id } }) }
  }
}
</script>

<style scoped>
.remind-page { padding: 4px 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 26px; font-weight: 700; color: #303133; }
.stat-num.orange { color: #e6a23c; }
.stat-num.red { color: #f56c6c; }
.stat-num.blue { color: #409eff; }
.stat-label { font-size: 12px; color: #909399; margin-top: 4px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.pager { margin-top: 12px; text-align: right; }
</style>
