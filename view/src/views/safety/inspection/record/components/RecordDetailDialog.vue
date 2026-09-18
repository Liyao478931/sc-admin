<template>
  <el-dialog title="检查记录详情" :visible.sync="dialogVisible" width="950px" top="5vh" append-to-body @open="loadDetail">
    <div v-loading="loading">
      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="base">
          <el-descriptions :column="3" size="small" border>
            <el-descriptions-item label="记录编号">{{ detail.task_code }}</el-descriptions-item>
            <el-descriptions-item label="任务编号">{{ detail.task_code }}</el-descriptions-item>
            <el-descriptions-item label="计划名称">{{ detail.plan_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="检查类型">{{ detail.inspection_type_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="检查区域">{{ detail.area || '-' }}</el-descriptions-item>
            <el-descriptions-item label="执行人">{{ detail.executor_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="计划执行日期">{{ detail.plan_execute_date }}</el-descriptions-item>
            <el-descriptions-item label="实际执行日期">{{ detail.actual_execute_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="执行耗时">{{ detail.execute_duration != null ? detail.execute_duration + ' 分钟' : '-' }}</el-descriptions-item>
            <el-descriptions-item label="项目总数">{{ detail.stats ? detail.stats.total : 0 }}</el-descriptions-item>
            <el-descriptions-item label="合格数"><span style="color:#67C23A">{{ detail.stats ? detail.stats.qualified : 0 }}</span></el-descriptions-item>
            <el-descriptions-item label="不合格数"><span :style="{ color: detail.stats && detail.stats.unqualified ? '#F56C6C' : '' }">{{ detail.stats ? detail.stats.unqualified : 0 }}</span></el-descriptions-item>
            <el-descriptions-item label="不适用数"><span style="color:#909399">{{ detail.stats ? detail.stats.na : 0 }}</span></el-descriptions-item>
            <el-descriptions-item label="问题总数">{{ detail.issue_count || 0 }}</el-descriptions-item>
            <el-descriptions-item label="检查总结" :span="3">{{ detail.summary || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <!-- 检查项目 -->
        <el-tab-pane label="检查项目" name="items">
          <el-table v-if="(detail.result || []).length" :data="detail.result" size="small" border stripe>
            <el-table-column type="index" label="序号" width="60" />
            <el-table-column prop="item_name" label="项目名称" min-width="140" />
            <el-table-column prop="check_standard" label="检查标准" min-width="160" show-overflow-tooltip />
            <el-table-column prop="check_method" label="检查方法" min-width="140" show-overflow-tooltip />
            <el-table-column label="结果状态" width="100" align="center">
              <template slot-scope="{ row }">
                <el-tag size="mini" :type="resultTagType(row.result)">{{ resultText(row.result) }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
          <!-- 不合格项明细 -->
          <div v-for="(item, idx) in unqualifiedItems" :key="idx" class="unq-item">
            <div class="unq-name">{{ item.item_name }}</div>
            <div class="unq-line" v-if="item.remark">问题描述：{{ item.remark }}</div>
            <div class="unq-line" v-if="issueSuggest(item.item_name)">整改建议：{{ issueSuggest(item.item_name) }}</div>
          </div>
          <el-empty v-if="!(detail.result || []).length" description="暂无检查项目" :image-size="60" />
        </el-tab-pane>

        <!-- 问题清单 -->
        <el-tab-pane label="问题清单" name="issues">
          <el-table v-if="(detail.issues || []).length" :data="detail.issues" size="small" border stripe>
            <el-table-column type="index" label="序号" width="60" />
            <el-table-column prop="item_name" label="检查项目" min-width="130" />
            <el-table-column prop="issue_description" label="问题描述" min-width="200" show-overflow-tooltip />
            <el-table-column label="严重程度" width="100" align="center">
              <template slot-scope="{ row }">
                <el-tag size="mini" :type="severityTagType(row.severity)">{{ row.severity_text }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="状态" width="90" align="center">
              <template slot-scope="{ row }">
                <el-tag size="mini" :type="row.status === 'resolved' ? 'success' : 'warning'">{{ row.status_text }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="suggest" label="整改建议" min-width="160" show-overflow-tooltip />
          </el-table>
          <el-empty v-if="!(detail.issues || []).length" description="暂无问题记录" :image-size="60" />
        </el-tab-pane>

        <!-- 检查总结 -->
        <el-tab-pane label="检查总结" name="summary">
          <div class="summary-box">{{ detail.summary || '暂无检查总结' }}</div>
        </el-tab-pane>
      </el-tabs>
    </div>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getRecordDetail } from '@/api/safetyInspectionRecord'

export default {
  name: 'RecordDetailDialog',
  props: {
    visible: Boolean,
    recordId: { type: Number, default: 0 },
  },
  data() {
    return { dialogVisible: this.visible, loading: false, activeTab: 'base', detail: {} }
  },
  computed: {
    unqualifiedItems() {
      return (this.detail.result || []).filter((it) => it.result === 'unqualified')
    },
  },
  watch: {
    visible(val) { this.dialogVisible = val },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    resultText(v) {
      return { qualified: '合格', unqualified: '不合格', na: '不适用' }[v] || v || '-'
    },
    resultTagType(v) {
      return { qualified: 'success', unqualified: 'danger', na: 'info' }[v] || 'info'
    },
    severityTagType(v) {
      return { minor: 'primary', major: 'warning', critical: 'danger' }[v] || 'info'
    },
    issueSuggest(itemName) {
      const issue = (this.detail.issues || []).find((x) => x.item_name === itemName)
      return issue && issue.suggest ? issue.suggest : ''
    },
    async loadDetail() {
      if (!this.recordId) return
      this.loading = true
      try {
        const r = await getRecordDetail(this.recordId)
        if (r.code === 0) this.detail = r.data || {}
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
      this.loading = false
    },
  },
}
</script>

<style scoped>
.unq-item { background: #fdf6ec; border-radius: 6px; padding: 10px 14px; margin-top: 12px; }
.unq-name { font-size: 13px; font-weight: 600; color: #F56C6C; margin-bottom: 4px; }
.unq-line { font-size: 12px; color: #606266; line-height: 1.7; padding-left: 12px; }
.summary-box { background: #f8f9fb; border-radius: 6px; padding: 16px; font-size: 14px; line-height: 1.8; color: #303133; }
</style>
