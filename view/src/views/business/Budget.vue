<template>
  <!-- 预算管理：预算编制 / 费用申请 / 预算看板 -->
  <div class="budget-page">
    <el-card shadow="never">
      <el-tabs v-model="tab">
        <!-- 预算编制 -->
        <el-tab-pane label="预算编制" name="plans">
          <div class="toolbar">
            <el-select v-model="planYear" size="small" style="width:110px" @change="loadPlans">
              <el-option v-for="y in years" :key="y" :label="y + '年'" :value="y" />
            </el-select>
            <el-select v-model="planMonth" size="small" style="width:110px" @change="loadPlans">
              <el-option label="全年" :value="0" />
              <el-option v-for="m in 12" :key="m" :label="m + '月'" :value="m" />
            </el-select>
            <el-button size="small" type="primary" icon="el-icon-plus" @click="openPlanDialog()">新增预算</el-button>
            <el-button size="small" icon="el-icon-refresh" @click="loadPlans">刷新</el-button>
          </div>
          <el-table :data="plans" v-loading="loading" size="small" border stripe>
            <el-table-column prop="department_name" label="部门" width="120" />
            <el-table-column prop="category" label="科目" width="100" />
            <el-table-column label="预算金额" width="120">
              <template slot-scope="{ row }">¥{{ row.amount.toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="已用" width="110">
              <template slot-scope="{ row }"><span :style="{ color: row.used_amount > row.amount ? '#F56C6C' : '' }">¥{{ row.used_amount.toLocaleString() }}</span></template>
            </el-table-column>
            <el-table-column label="剩余" width="110">
              <template slot-scope="{ row }">¥{{ row.remain_amount.toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="执行率" width="140">
              <template slot-scope="{ row }">
                <el-progress :percentage="row.rate" :color="row.rate >= 90 ? '#F56C6C' : row.rate >= 70 ? '#E6A23C' : '#67C23A'" :stroke-width="10" />
              </template>
            </el-table-column>
            <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
            <el-table-column label="操作" width="120" fixed="right">
              <template slot-scope="{ row }">
                <el-button type="text" size="mini" @click="openPlanDialog(row)">编辑</el-button>
                <el-button type="text" size="mini" style="color:#F56C6C" @click="deletePlan(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 费用申请 -->
        <el-tab-pane label="费用申请" name="expenses">
          <div class="toolbar">
            <el-button size="small" type="primary" icon="el-icon-plus" @click="openExpenseDialog()">新增申请</el-button>
            <el-select v-model="expenseStatus" size="small" clearable placeholder="全部状态" style="width:130px" @change="loadExpenses">
              <el-option label="草稿" :value="0" />
              <el-option label="待审批" :value="1" />
              <el-option label="已通过" :value="2" />
              <el-option label="已驳回" :value="3" />
            </el-select>
            <el-button size="small" icon="el-icon-refresh" @click="loadExpenses">刷新</el-button>
          </div>
          <el-table :data="expenses" v-loading="loading" size="small" border stripe>
            <el-table-column prop="department_name" label="部门" width="110" />
            <el-table-column prop="category" label="科目" width="90" />
            <el-table-column label="金额" width="110">
              <template slot-scope="{ row }">¥{{ row.amount.toLocaleString() }}</template>
            </el-table-column>
            <el-table-column prop="purpose" label="事由" min-width="160" show-overflow-tooltip />
            <el-table-column prop="applicant_name" label="申请人" width="90" />
            <el-table-column label="状态" width="90">
              <template slot-scope="{ row }">
                <el-tag :type="statusTag(row.status)" size="mini">{{ row.status_text }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="approver_name" label="审批人" width="90">
              <template slot-scope="{ row }">{{ row.approver_name || '-' }}</template>
            </el-table-column>
            <el-table-column prop="created_at" label="申请时间" width="160" />
            <el-table-column label="操作" width="160" fixed="right">
              <template slot-scope="{ row }">
                <el-button v-if="row.status === 1" type="success" size="mini" @click="approve(row, 'approve')">通过</el-button>
                <el-button v-if="row.status === 1" type="danger" size="mini" @click="approve(row, 'reject')">驳回</el-button>
                <el-button v-if="row.status === 0 || row.status === 3" type="text" size="mini" style="color:#F56C6C" @click="deleteExpense(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 预算看板 -->
        <el-tab-pane label="预算看板" name="overview">
          <div class="toolbar">
            <el-select v-model="planYear" size="small" style="width:110px" @change="loadOverview">
              <el-option v-for="y in years" :key="y" :label="y + '年'" :value="y" />
            </el-select>
            <el-select v-model="planMonth" size="small" style="width:110px" @change="loadOverview">
              <el-option label="全年" :value="0" />
              <el-option v-for="m in 12" :key="m" :label="m + '月'" :value="m" />
            </el-select>
          </div>
          <div class="ov-cards">
            <div class="ov-card"><div class="ov-num">¥{{ ov.total_budget.toLocaleString() }}</div><div class="ov-label">年度预算</div></div>
            <div class="ov-card"><div class="ov-num warn">¥{{ ov.total_used.toLocaleString() }}</div><div class="ov-label">已用</div></div>
            <div class="ov-card"><div class="ov-num ok">¥{{ ov.total_remain.toLocaleString() }}</div><div class="ov-label">剩余</div></div>
            <div class="ov-card"><div class="ov-num">{{ ov.total_rate }}%</div><div class="ov-label">执行率</div></div>
            <div class="ov-card"><div class="ov-num">{{ ov.pending }}</div><div class="ov-label">待审批</div></div>
          </div>
          <el-row :gutter="16">
            <el-col :span="12">
              <el-card shadow="never" class="sub-card">
                <div slot="header">部门预算执行</div>
                <el-table :data="ov.departments" size="small" border>
                  <el-table-column prop="department_name" label="部门" />
                  <el-table-column label="预算" width="100"><template slot-scope="{ row }">¥{{ row.budget.toLocaleString() }}</template></el-table-column>
                  <el-table-column label="已用" width="90"><template slot-scope="{ row }">¥{{ row.used.toLocaleString() }}</template></el-table-column>
                  <el-table-column label="执行率" width="120">
                    <template slot-scope="{ row }"><el-progress :percentage="row.rate" :stroke-width="10" /></template>
                  </el-table-column>
                </el-table>
              </el-card>
            </el-col>
            <el-col :span="12">
              <el-card shadow="never" class="sub-card">
                <div slot="header">科目预算执行</div>
                <el-table :data="ov.categories" size="small" border>
                  <el-table-column prop="category" label="科目" />
                  <el-table-column label="预算" width="100"><template slot-scope="{ row }">¥{{ row.budget.toLocaleString() }}</template></el-table-column>
                  <el-table-column label="已用" width="90"><template slot-scope="{ row }">¥{{ row.used.toLocaleString() }}</template></el-table-column>
                  <el-table-column label="执行率" width="120">
                    <template slot-scope="{ row }"><el-progress :percentage="row.rate" :stroke-width="10" /></template>
                  </el-table-column>
                </el-table>
              </el-card>
            </el-col>
          </el-row>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 预算计划弹窗 -->
    <el-dialog title="预算计划" :visible.sync="planDialog" width="480px">
      <el-form label-width="90px" size="small">
        <el-form-item label="部门"><el-select v-model="planForm.department_id" style="width:100%"><el-option v-for="d in departments" :key="d.id" :label="d.name" :value="d.id" /></el-select></el-form-item>
        <el-form-item label="年度"><el-select v-model="planForm.year" style="width:100%"><el-option v-for="y in years" :key="y" :label="y + '年'" :value="y" /></el-select></el-form-item>
        <el-form-item label="预算类型"><el-select v-model="planForm.month" style="width:100%"><el-option label="年度预算（全年）" :value="0" /><el-option v-for="m in 12" :key="m" :label="'' + m + '月（月度预算）'" :value="m" /></el-select></el-form-item>
        <el-form-item label="科目"><el-select v-model="planForm.category" style="width:100%"><el-option v-for="c in categories" :key="c" :label="c" :value="c" /></el-select></el-form-item>
        <el-form-item label="预算金额"><el-input-number v-model="planForm.amount" :min="0" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="planForm.remark" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="planDialog = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="savePlan">保存</el-button>
      </template>
    </el-dialog>

    <!-- 费用申请弹窗 -->
    <el-dialog title="费用申请" :visible.sync="expenseDialog" width="480px">
      <el-form label-width="90px" size="small">
        <el-form-item label="预算计划">
          <el-select v-model="expenseForm.plan_id" style="width:100%" placeholder="选择预算科目">
            <el-option v-for="p in plans" :key="p.id" :label="p.department_name + ' - ' + p.category + '（剩余¥' + p.remain_amount + '）'" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="申请金额"><el-input-number v-model="expenseForm.amount" :min="0.01" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="事由"><el-input v-model="expenseForm.purpose" type="textarea" :rows="3" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="expenseDialog = false">取消</el-button>
        <el-button size="small" @click="saveExpense(false)" :loading="saving">存草稿</el-button>
        <el-button size="small" type="primary" @click="saveExpense(true)" :loading="saving">提交审批</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import request from '@/api/request'

export default {
  name: 'Budget',
  data() {
    return {
      tab: 'plans',
      loading: false,
      saving: false,
      plans: [], expenses: [], ov: { total_budget: 0, total_used: 0, total_remain: 0, total_rate: 0, pending: 0, departments: [], categories: [] },
      departments: [], categories: [], years: [],
      planYear: new Date().getFullYear(),
      planMonth: new Date().getMonth() + 1,
      expenseStatus: '',
      planDialog: false, expenseDialog: false,
      planForm: { id: 0, department_id: 0, year: new Date().getFullYear(), month: new Date().getMonth() + 1, category: '', amount: 0, remark: '' },
      expenseForm: { id: 0, plan_id: 0, amount: 0, purpose: '' },
    }
  },
  created() { this.loadOptions() },
  methods: {
    async loadOptions() {
      try {
        const r = await request({ url: '/budget/options', method: 'get' })
        if (r.code === 0) {
          this.departments = r.data.departments || []
          this.categories = r.data.categories || []
          this.years = r.data.years || []
        }
      } catch (e) {}
      this.loadPlans(); this.loadExpenses(); this.loadOverview()
    },
    async loadPlans() {
      this.loading = true
      try {
        const r = await request({ url: '/budget/plans', method: 'get', params: { year: this.planYear, month: this.planMonth } })
        if (r.code === 0) this.plans = (r.data.list || []).map(p => ({ ...p, amount: Number(p.amount), used_amount: Number(p.used_amount), remain_amount: Number(p.remain_amount) }))
      } catch (e) {} finally { this.loading = false }
    },
    async loadExpenses() {
      try {
        const params = {}
        if (this.expenseStatus !== '') params.status = this.expenseStatus
        const r = await request({ url: '/budget/expenses', method: 'get', params })
        if (r.code === 0) this.expenses = (r.data.list || []).map(x => ({ ...x, amount: Number(x.amount) }))
      } catch (e) {}
    },
    async loadOverview() {
      try {
        const r = await request({ url: '/budget/overview', method: 'get', params: { year: this.planYear, month: this.planMonth } })
        if (r.code === 0) this.ov = r.data || this.ov
      } catch (e) {}
    },
    openPlanDialog(row) {
      this.planForm = row ? { id: row.id, department_id: row.department_id, year: row.year, month: row.month, category: row.category, amount: row.amount, remark: row.remark } : { id: 0, department_id: 0, year: this.planYear, month: this.planMonth, category: '', amount: 0, remark: '' }
      this.planDialog = true
    },
    async savePlan() {
      this.saving = true
      try {
        const r = await request({ url: '/budget/plan-save', method: 'post', data: this.planForm })
        if (r.code === 0) { this.$message.success('预算已保存'); this.planDialog = false; this.loadPlans(); this.loadOverview() }
      } catch (e) {} finally { this.saving = false }
    },
    async deletePlan(row) {
      await this.$confirm('确认删除该预算计划？', '提示', { type: 'warning' })
      const r = await request({ url: '/budget/plan-delete', method: 'post', data: { id: row.id } })
      if (r.code === 0) { this.$message.success('已删除'); this.loadPlans(); this.loadOverview() }
    },
    openExpenseDialog() {
      this.expenseForm = { id: 0, plan_id: this.plans.length ? this.plans[0].id : 0, amount: 0, purpose: '' }
      this.expenseDialog = true
    },
    async saveExpense(submit) {
      if (!this.expenseForm.plan_id || !this.expenseForm.purpose) { this.$message.warning('请选择预算科目并填写事由'); return }
      this.saving = true
      try {
        const r = await request({ url: '/budget/expense-save', method: 'post', data: { ...this.expenseForm, submit: submit ? 1 : 0 } })
        if (r.code === 0) { this.$message.success(submit ? '已提交审批' : '已保存草稿'); this.expenseDialog = false; this.loadExpenses(); this.loadPlans(); this.loadOverview() }
      } catch (e) {} finally { this.saving = false }
    },
    async approve(row, action) {
      const remark = action === 'reject' ? await this.$prompt('请输入驳回原因', '驳回', { inputType: 'textarea' }).then(r => r.value).catch(() => null) : ''
      if (action === 'reject' && remark === null) return
      const r = await request({ url: '/budget/expense-approve', method: 'post', data: { id: row.id, action, remark } })
      if (r.code === 0) { this.$message.success(action === 'approve' ? '已通过' : '已驳回'); this.loadExpenses(); this.loadPlans(); this.loadOverview() }
    },
    async deleteExpense(row) {
      await this.$confirm('确认删除该申请？', '提示', { type: 'warning' })
      const r = await request({ url: '/budget/expense-delete', method: 'post', data: { id: row.id } })
      if (r.code === 0) { this.$message.success('已删除'); this.loadExpenses() }
    },
    statusTag(s) { return { 0: 'info', 1: 'warning', 2: 'success', 3: 'danger' }[s] || 'info' },
  },
}
</script>

<style scoped>
.toolbar { display: flex; gap: 10px; margin-bottom: 14px; align-items: center; }
.ov-cards { display: flex; gap: 14px; margin-bottom: 16px; flex-wrap: wrap; }
.ov-card { flex: 1; min-width: 140px; background: #fff; border-radius: 8px; padding: 16px; text-align: center; box-shadow: 0 1px 4px rgba(0,0,0,.05); }
.ov-num { font-size: 22px; font-weight: 700; color: #409EFF; }
.ov-num.warn { color: #E6A23C; }
.ov-num.ok { color: #67C23A; }
.ov-label { color: #909399; font-size: 12px; margin-top: 4px; }
.sub-card { margin-bottom: 16px; }
</style>
