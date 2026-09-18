<template>
  <div class="ixe-page">
    <el-breadcrumb separator="/" class="ixe-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>固定资产管理</el-breadcrumb-item>
      <el-breadcrumb-item>执行盘点</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="ixe-head">
      <div class="ixe-head-info">
        <div class="ixe-title">执行盘点 - {{ plan.plan_no }}</div>
        <div class="ixe-meta">{{ plan.plan_name }}　|　{{ plan.plan_type_label }}　|　{{ plan.scope_label }}　|　负责人：{{ plan.plan_by_name }}</div>
      </div>
      <div class="ixe-progress">
        <span>已盘 {{ checkedCount }}/{{ tasks.length }}</span>
        <el-progress :percentage="progress" :stroke-width="10" style="width:160px" />
      </div>
      <div class="ixe-actions">
        <el-button size="small" @click="$router.back()">返回</el-button>
        <el-button size="small" type="primary" :loading="submitting" @click="submitAll">提交盘点</el-button>
      </div>
    </div>

    <!-- 筛选 -->
    <div class="ixe-filter">
      <el-radio-group v-model="filterStatus" size="small" @change="applyFilter">
        <el-radio-button label="">全部</el-radio-button>
        <el-radio-button label="0">待盘</el-radio-button>
        <el-radio-button label="1">已盘</el-radio-button>
      </el-radio-group>
      <el-input v-model="filterKeyword" placeholder="搜索资产名称/编号" size="small" clearable style="width:200px;margin-left:12px" @input="applyFilter" />
    </div>

    <!-- 资产列表 -->
    <div class="ixe-table">
      <el-table :data="filteredTasks" v-loading="loading" size="small" border stripe>
        <el-table-column type="index" label="序号" width="50" align="center" />
        <el-table-column prop="asset_no" label="资产编号" width="120" />
        <el-table-column prop="asset_name" label="资产名称" min-width="110" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="55" align="center" />
        <el-table-column label="系统数量" width="80" align="right"><template slot-scope="s">{{ s.row.system_quantity }}</template></el-table-column>
        <el-table-column label="实际数量" width="110">
          <template slot-scope="s">
            <el-input-number v-model="s.row.actual_quantity" :min="0" :precision="0" size="mini" :disabled="s.row.check_status === 1" style="width:90px" />
          </template>
        </el-table-column>
        <el-table-column label="实际状态" width="110">
          <template slot-scope="s">
            <el-select v-model="s.row.actual_status" size="mini" :disabled="s.row.check_status === 1" style="width:90px">
              <el-option v-for="(t, v) in ASSET_STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="备注" min-width="120">
          <template slot-scope="s"><el-input v-model="s.row.remark" size="mini" :disabled="s.row.check_status === 1" placeholder="备注" /></template>
        </el-table-column>
        <el-table-column label="状态" width="70" align="center">
          <template slot-scope="s"><el-tag :type="s.row.check_status === 1 ? 'success' : 'info'" size="mini">{{ s.row.check_status === 1 ? '已盘' : '待盘' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="s">
            <el-button v-if="s.row.check_status === 0" type="text" size="mini" @click="saveOne(s.row)">保存</el-button>
            <span v-else>-</span>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div class="ixe-tip">💡 录入实际数量与实际状态后点击"保存"；全部盘完后点击"提交盘点"生成差异报告。</div>
  </div>
</template>

<script>
import { getInventoryTasks, checkInventory, submitInventory, getInventoryDetail } from '../../api/inventory'

const ASSET_STATUS_TEXT = { 1: '正常', 2: '维修中', 3: '闲置', 4: '待报废', 5: '已报废' }

export default {
  name: 'InventoryExecute',
  data () {
    return {
      ASSET_STATUS_TEXT,
      planId: 0, plan: {}, tasks: [], loading: false, submitting: false,
      filterStatus: '', filterKeyword: '', filteredTasks: []
    }
  },
  computed: {
    checkedCount () { return this.tasks.filter(t => t.check_status === 1).length },
    progress () { return this.tasks.length ? Math.round(this.checkedCount / this.tasks.length * 100) : 0 }
  },
  created () {
    this.planId = Number(this.$route.query.plan_id || 0)
    if (this.planId) this.loadData()
  },
  methods: {
    async loadData () {
      this.loading = true
      try {
        const [d, t] = await Promise.all([
          getInventoryDetail({ plan_id: this.planId }),
          getInventoryTasks({ plan_id: this.planId })
        ])
        if (d.code === 0) this.plan = d.data
        if (t.code === 0) {
          this.tasks = (t.data.list || []).map(x => ({ ...x, actual_quantity: x.actual_quantity != null ? Number(x.actual_quantity) : Number(x.system_quantity), actual_status: x.actual_status || 1, remark: x.remark || '' }))
          this.applyFilter()
        }
      } catch (e) {}
      this.loading = false
    },
    applyFilter () {
      let list = this.tasks
      if (this.filterStatus !== '') list = list.filter(t => t.check_status === Number(this.filterStatus))
      if (this.filterKeyword) {
        const kw = this.filterKeyword.toLowerCase()
        list = list.filter(t => (t.asset_name || '').toLowerCase().includes(kw) || (t.asset_no || '').toLowerCase().includes(kw))
      }
      this.filteredTasks = list
    },
    async saveOne (task) {
      try {
        const r = await checkInventory({ task_id: task.id, actual_quantity: task.actual_quantity, actual_status: task.actual_status, remark: task.remark })
        if (r.code === 0) { this.$message.success('已保存'); this.loadData() }
      } catch (e) {}
    },
    submitAll () {
      const unchecked = this.tasks.filter(t => t.check_status === 0)
      if (unchecked.length > 0) {
        this.$confirm('还有 ' + unchecked.length + ' 项资产未盘点，确认提交吗？', '提示', { type: 'warning' }).then(() => this.doSubmit()).catch(() => {})
      } else {
        this.doSubmit()
      }
    },
    async doSubmit () {
      this.submitting = true
      try {
        const r = await submitInventory({ plan_id: this.planId })
        if (r.code === 0) { this.$message.success(r.msg || '盘点已提交'); this.$router.push('/personal-assets/inventory') }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.ixe-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.ixe-breadcrumb { margin-bottom: 12px; }
.ixe-head { background: #fff; border-radius: 8px; padding: 16px 20px; margin-bottom: 12px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; }
.ixe-title { font-size: 16px; font-weight: 700; color: #1f2d3d; }
.ixe-meta { font-size: 13px; color: #909399; margin-top: 4px; }
.ixe-progress { display: flex; align-items: center; gap: 10px; font-size: 13px; color: #606266; }
.ixe-filter { background: #fff; border-radius: 8px; padding: 12px 16px; margin-bottom: 12px; display: flex; align-items: center; }
.ixe-table { background: #fff; border-radius: 8px; padding: 12px; }
.ixe-tip { font-size: 13px; color: #909399; margin-top: 12px; }
</style>