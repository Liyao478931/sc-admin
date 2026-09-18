<!-- 文件：admin/src/views/ai/agents/order.vue（v1.67.0 订单处理智能体） -->
<template>
  <div class="od-page">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>业务智能体</span><i class="el-icon-arrow-right"></i><span class="cur">订单处理智能体</span></div>

    <div class="toolbar">
      <el-button size="small" icon="el-icon-refresh" @click="load">刷新</el-button>
      <el-button size="small" type="primary" icon="el-icon-video-play" @click="load">触发自动处理</el-button>
    </div>

    <div class="panel">
      <div class="panel-head">订单处理任务（共 {{ total }} 条）</div>
      <el-table :data="list" v-loading="loading" size="small" border stripe>
        <el-table-column prop="order_no" label="订单号" width="150" />
        <el-table-column prop="customer_name" label="客户" min-width="120" />
        <el-table-column label="金额" width="110" align="right">
          <template slot-scope="s">{{ fmtMoney(s.row.order_amount) }}</template>
        </el-table-column>
        <el-table-column prop="order_status_text" label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="{ '已审核': 'success', '待审核': 'warning' }[s.row.order_status_text] || 'info'">{{ s.row.order_status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="处理步骤" min-width="200">
          <template slot-scope="s">
            <span v-for="(st, i) in s.row.steps" :key="i" class="step-tag">
              {{ stepText(st.step) }}<i :class="st.status === 'pass' ? 'ok' : 'no'">{{ st.status === 'pass' ? '✓' : '✗' }}</i>
            </span>
            <span v-if="!s.row.steps || !s.row.steps.length" class="none">未处理</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openDetail(s.row)">查看</el-button>
            <el-button v-if="s.row.order_status === 'pending'" type="text" size="mini" @click="manual(s.row, 'approve')">通过</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager"><span>共 {{ total }} 条</span></div>
    </div>

    <!-- 规则配置 -->
    <div class="panel">
      <div class="panel-head">处理规则配置</div>
      <el-form :inline="true" size="small">
        <el-form-item label="信用审核阈值">
          <el-input-number v-model="rules.credit_threshold" :min="0.1" :max="1" :step="0.1" style="width:100px" />
        </el-form-item>
        <el-form-item label="自动信用审核"><el-switch v-model="rules.auto_credit" /></el-form-item>
        <el-form-item label="自动库存检查"><el-switch v-model="rules.auto_inventory" /></el-form-item>
        <el-form-item label="自动生成发货通知"><el-switch v-model="rules.auto_notice" /></el-form-item>
        <el-form-item><el-button type="primary" @click="saveRules">保存配置</el-button></el-form-item>
      </el-form>
    </div>

    <!-- 详情弹窗 -->
    <el-dialog title="订单处理详情" :visible.sync="detailVisible" width="560px">
      <div v-if="detail.order" class="d-body">
        <div class="p-line">订单：{{ detail.order.order_no }}｜客户：{{ detail.order.customer_name }}｜金额：{{ fmtMoney(detail.order.order_amount) }}</div>
        <div class="d-title">处理日志</div>
        <div v-for="l in detail.logs" :key="l.id" class="d-log">
          {{ l.processed_at }}｜{{ l.step_text }}｜<el-tag :type="l.status === 'pass' ? 'success' : 'danger'" size="mini">{{ l.status_text }}</el-tag>
          <div class="d-detail">{{ fmtDetail(l.detail) }}</div>
        </div>
        <div v-if="!detail.logs || !detail.logs.length" class="none">暂无处理日志</div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getOrderTasks, getOrderDetail, manualOrder, getOrderRules, saveOrderRules } from '@/api/aiAgentBiz'

export default {
  name: 'AiAgentOrder',
  data () {
    return { list: [], total: 0, loading: false, rules: {}, detail: {}, detailVisible: false }
  },
  mounted () { this.load(); this.loadRules() },
  methods: {
    fmtMoney (v) { v = Number(v) || 0; return v >= 10000 ? (v / 10000).toFixed(1) + '万' : v.toFixed(0) },
    stepText (s) { return { credit_check: '信用', inventory_check: '库存', create_notice: '发货' }[s] || s },
    async load () {
      this.loading = true
      try { const r = await getOrderTasks({ page: 1, limit: 20 }); if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 } } catch (e) {} finally { this.loading = false }
    },
    async loadRules () { try { const r = await getOrderRules(); if (r.code === 0) this.rules = r.data || {} } catch (e) {} },
    async saveRules () { try { const r = await saveOrderRules(this.rules); if (r.code === 0) this.$message.success('规则已保存') } catch (e) { this.$message.error('保存失败') } },
    async openDetail (row) { try { const r = await getOrderDetail(row.id); if (r.code === 0) { this.detail = r.data; this.detailVisible = true } } catch (e) {} },
    async manual (row, action) {
      try { const r = await manualOrder(row.id, action); if (r.code === 0) { this.$message.success('已处理'); this.load() } else this.$message.error(r.msg || '失败') } catch (e) { this.$message.error('处理失败') }
    },
    fmtDetail (d) { return d && typeof d === 'object' ? JSON.stringify(d) : (d || '') }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.toolbar { display: flex; align-items: center; padding: 12px 16px; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; margin: 0 16px 16px; padding: 12px 16px; }
.panel-head { font-weight: 600; margin-bottom: 8px; }
.pager { display: flex; align-items: center; justify-content: space-between; padding-top: 10px; }
.step-tag { display: inline-flex; align-items: center; gap: 2px; background: #f5f7fa; border-radius: 3px; padding: 1px 6px; font-size: 12px; margin-right: 6px; }
.step-tag .ok { color: #67c23a; }
.step-tag .no { color: #f56c6c; }
.none { color: #909399; font-size: 12px; }
.p-line { font-size: 13px; color: #606266; margin-bottom: 6px; }
.d-title { font-weight: 600; margin: 10px 0 6px; }
.d-log { background: #f5f7fa; border-radius: 4px; padding: 6px 8px; margin-bottom: 6px; font-size: 12px; }
.d-detail { color: #909399; margin-top: 4px; word-break: break-all; }
</style>
