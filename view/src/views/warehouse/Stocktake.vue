<template>
  <div class="stocktake-page">
    <el-tabs v-model="activeTab" @tab-click="onTab">
      <!-- 盘点计划 -->
      <el-tab-pane label="盘点计划" name="plan">
        <el-card shadow="never" class="box-card">
          <div class="search-row">
            <el-input v-model="planQuery.plan_name" placeholder="计划名称" clearable style="width: 160px" @keyup.enter.native="loadPlans(1)" />
            <el-input v-model="planQuery.plan_no" placeholder="计划编号" clearable style="width: 160px" @keyup.enter.native="loadPlans(1)" />
            <el-select v-model="planQuery.plan_type" placeholder="盘点类型" clearable style="width: 120px" @change="loadPlans(1)">
              <el-option label="全盘" value="1" />
              <el-option label="抽盘" value="2" />
              <el-option label="循环盘点" value="3" />
            </el-select>
            <el-select v-model="planQuery.status" placeholder="状态" clearable style="width: 120px" @change="loadPlans(1)">
              <el-option v-for="(t, v) in statusMap" :key="v" :label="t" :value="v" />
            </el-select>
            <el-button type="primary" icon="el-icon-search" @click="loadPlans(1)">查询</el-button>
            <el-button type="success" icon="el-icon-plus" @click="openPlanDialog()">新建盘点计划</el-button>
          </div>

          <el-table v-loading="planLoading" :data="planList" border stripe style="margin-top: 14px">
            <el-table-column type="index" label="#" width="50" align="center" />
            <el-table-column prop="plan_no" label="计划编号" width="130" />
            <el-table-column prop="plan_name" label="计划名称" min-width="160" show-overflow-tooltip />
            <el-table-column label="类型" width="100">
              <template slot-scope="{ row }">
                <el-tag :type="row.plan_type_tag" size="small">{{ row.plan_type_label }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="warehouse_name" label="盘点仓库" width="110" />
            <el-table-column label="范围/方式" width="150">
              <template slot-scope="{ row }">
                <div>{{ row.scope_type_label }}</div>
                <div class="sub-text">{{ row.inventory_method_label }}</div>
              </template>
            </el-table-column>
            <el-table-column prop="plan_date_range" label="计划日期" width="200" />
            <el-table-column prop="responsible_person_name" label="负责人" width="90" />
            <el-table-column label="状态" width="110">
              <template slot-scope="{ row }">
                <el-tag :type="row.status_tag" size="small">{{ row.status_label }}</el-tag>
                <div v-if="row.approval_status_label" class="sub-text">{{ row.approval_status_label }}</div>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="280" align="center" fixed="right">
              <template slot-scope="{ row }">
                <el-button type="primary" size="mini" icon="el-icon-view" @click="viewPlan(row)">详情</el-button>
                <template v-if="row.status === 0">
                  <el-button type="warning" size="mini" icon="el-icon-edit" @click="openPlanDialog(row)">编辑</el-button>
                  <el-button type="primary" size="mini" icon="el-icon-s-promotion" @click="submitPlan(row)">提交审批</el-button>
                  <el-button type="danger" size="mini" icon="el-icon-delete" @click="deletePlan(row)">删除</el-button>
                </template>
                <template v-if="row.status === 0 || row.status === 1 || row.status === 2">
                  <el-button type="info" size="mini" icon="el-icon-circle-close" @click="cancelPlan(row)">取消</el-button>
                </template>
                <el-button v-if="row.status === 2" type="success" size="mini" icon="el-icon-video-play" @click="startPlan(row)">开始</el-button>
                <el-button v-if="row.status === 3" type="success" size="mini" icon="el-icon-circle-check" @click="completePlan(row)">完成</el-button>
              </template>
            </el-table-column>
          </el-table>

          <div class="pager-row">
            <el-pagination background layout="total, prev, pager, next" :total="planTotal" :page-size="planQuery.limit"
              :current-page="planQuery.page" @current-change="loadPlans" />
          </div>
        </el-card>
      </el-tab-pane>

      <!-- 执行任务 -->
      <el-tab-pane label="执行任务" name="execute">
        <el-card shadow="never" class="box-card">
          <div class="search-row">
            <el-input v-model="taskQuery.keyword" placeholder="计划编号/任务名称" clearable style="width: 220px" @keyup.enter.native="loadTasks(1)" />
            <el-select v-model="taskQuery.status" placeholder="任务状态" clearable style="width: 130px" @change="loadTasks(1)">
              <el-option v-for="(t, v) in taskStatusMap" :key="v" :label="t" :value="v" />
            </el-select>
            <el-button type="primary" icon="el-icon-search" @click="loadTasks(1)">查询</el-button>
          </div>
          <el-table v-loading="taskLoading" :data="taskList" border stripe style="margin-top: 14px">
            <el-table-column type="index" label="#" width="50" align="center" />
            <el-table-column prop="task_no" label="任务编号" width="130" />
            <el-table-column prop="plan_no" label="计划编号" width="130" />
            <el-table-column prop="task_name" label="任务名称" min-width="160" />
            <el-table-column prop="location_name" label="盘点库位" width="110" />
            <el-table-column label="物料数" width="90" align="center">
              <template slot-scope="{ row }">{{ (row.material_ids || []).length }}</template>
            </el-table-column>
            <el-table-column prop="responsible_person_name" label="责任人" width="90" />
            <el-table-column label="状态" width="100">
              <template slot-scope="{ row }">
                <el-tag :type="row.status_tag" size="small">{{ row.status_label }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="actual_end_time" label="完成时间" width="160">
              <template slot-scope="{ row }">{{ row.actual_end_time || '-' }}</template>
            </el-table-column>
          </el-table>
          <div class="pager-row">
            <el-pagination background layout="total, prev, pager, next" :total="taskTotal" :page-size="taskQuery.limit"
              :current-page="taskQuery.page" @current-change="loadTasks" />
          </div>
        </el-card>
      </el-tab-pane>

      <!-- 盘点差异 -->
      <el-tab-pane label="盘点差异" name="diff">
        <el-card shadow="never" class="box-card">
          <div class="search-row">
            <el-input v-model="diffQuery.keyword" placeholder="物料编码/名称" clearable style="width: 220px" @keyup.enter.native="loadDiffs(1)" />
            <el-select v-model="diffQuery.status" placeholder="处理状态" clearable style="width: 130px" @change="loadDiffs(1)">
              <el-option label="待处理" value="0" />
              <el-option label="已处理" value="1" />
              <el-option label="已忽略" value="2" />
            </el-select>
            <el-button type="primary" icon="el-icon-search" @click="loadDiffs(1)">查询</el-button>
          </div>
          <el-table v-loading="diffLoading" :data="diffList" border stripe style="margin-top: 14px">
            <el-table-column type="index" label="#" width="50" align="center" />
            <el-table-column prop="plan_no" label="计划编号" width="130" />
            <el-table-column label="物料" min-width="170">
              <template slot-scope="{ row }">
                <div>{{ row.material_name }}</div>
                <div class="sub-text">{{ row.material_code }} {{ row.specification }}</div>
              </template>
            </el-table-column>
            <el-table-column label="账面/实盘" width="150">
              <template slot-scope="{ row }">
                <div>{{ fmtNum(row.book_quantity) }} → {{ fmtNum(row.actual_quantity) }}</div>
                <div class="sub-text">{{ row.unit }}</div>
              </template>
            </el-table-column>
            <el-table-column label="差异" width="110" align="right">
              <template slot-scope="{ row }">
                <span :class="row.difference_type === 1 ? 'diff-gain' : row.difference_type === 2 ? 'diff-loss' : 'sub-text'">
                  {{ row.difference_type === 1 ? '+' : row.difference_type === 2 ? '-' : '' }}{{ fmtNum(row.difference_quantity) }}
                </span>
              </template>
            </el-table-column>
            <el-table-column prop="location_name" label="库位" width="100" />
            <el-table-column prop="status_text" label="状态" width="100">
              <template slot-scope="{ row }">
                <el-tag :type="row.status === 0 ? 'warning' : row.status === 1 ? 'success' : 'info'" size="small">{{ row.status_text }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="created_at" label="登记时间" width="160" />
            <el-table-column label="操作" width="160" align="center" fixed="right">
              <template slot-scope="{ row }">
                <template v-if="row.status === 0">
                  <el-button type="success" size="mini" icon="el-icon-check" @click="processDiff(row)">处理</el-button>
                  <el-button type="info" size="mini" icon="el-icon-close" @click="ignoreDiff(row)">忽略</el-button>
                </template>
                <span v-else class="sub-text">-</span>
              </template>
            </el-table-column>
          </el-table>
          <div class="pager-row">
            <el-pagination background layout="total, prev, pager, next" :total="diffTotal" :page-size="diffQuery.limit"
              :current-page="diffQuery.page" @current-change="loadDiffs" />
          </div>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 计划新建/编辑弹窗 -->
    <el-dialog :title="planForm.id ? '编辑盘点计划' : '新建盘点计划'" :visible.sync="planDialog" width="560px" :close-on-click-modal="false">
      <el-form ref="planForm" :model="planForm" label-width="100px" size="small">
        <el-form-item label="计划名称" required>
          <el-input v-model="planForm.plan_name" placeholder="如：2026年9月季度全盘" maxlength="60" />
        </el-form-item>
        <el-form-item label="盘点类型" required>
          <el-radio-group v-model="planForm.plan_type">
            <el-radio :label="1">全盘</el-radio>
            <el-radio :label="2">抽盘</el-radio>
            <el-radio :label="3">循环盘点</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="盘点仓库" required>
          <el-select v-model="planForm.warehouse_id" filterable placeholder="选择仓库" style="width: 100%">
            <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="盘点范围" required>
          <el-radio-group v-model="planForm.scope_type">
            <el-radio :label="1">全仓</el-radio>
            <el-radio :label="2">按货位</el-radio>
            <el-radio :label="3">按物料分类</el-radio>
            <el-radio :label="4">按物料</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="盘点方式" required>
          <el-radio-group v-model="planForm.inventory_method">
            <el-radio :label="1">明盘</el-radio>
            <el-radio :label="2">暗盘</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="计划日期" required>
          <el-date-picker v-model="planDateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至"
            start-placeholder="开始日期" end-placeholder="结束日期" style="width: 100%" />
        </el-form-item>
        <el-form-item label="负责人" required>
          <el-select v-model="planForm.responsible_person_id" filterable placeholder="选择负责人" style="width: 100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="预计天数">
          <el-input-number v-model="planForm.expected_duration" :min="1" :max="60" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="planForm.remark" type="textarea" :rows="2" maxlength="200" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="planDialog = false">取消</el-button>
        <el-button type="primary" size="small" :loading="planSaving" @click="savePlan">保存</el-button>
      </div>
    </el-dialog>

    <!-- 计划详情弹窗 -->
    <el-dialog title="盘点计划详情" :visible.sync="detailDialog" width="720px">
      <template v-if="planDetail.plan">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="计划编号">{{ planDetail.plan.plan_no }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="planDetail.plan.status_tag" size="small">{{ planDetail.plan.status_label }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="计划名称">{{ planDetail.plan.plan_name }}</el-descriptions-item>
          <el-descriptions-item label="盘点仓库">{{ planDetail.plan.warehouse_name }}</el-descriptions-item>
          <el-descriptions-item label="盘点类型">{{ planDetail.plan.plan_type_label }} / {{ planDetail.plan.inventory_method_label }}</el-descriptions-item>
          <el-descriptions-item label="范围">{{ planDetail.plan.scope_type_label }}（{{ planDetail.scope ? planDetail.scope.count : 0 }} 项）</el-descriptions-item>
          <el-descriptions-item label="计划日期">{{ planDetail.plan.plan_date_range }}</el-descriptions-item>
          <el-descriptions-item label="负责人">{{ planDetail.plan.responsible_person_name }}</el-descriptions-item>
        </el-descriptions>
        <el-table :data="planDetail.tasks || []" border size="small" style="margin-top: 12px">
          <el-table-column type="index" label="#" width="50" align="center" />
          <el-table-column prop="task_no" label="任务编号" width="140" />
          <el-table-column prop="task_name" label="任务名称" min-width="140" />
          <el-table-column prop="location_name" label="库位" width="110" />
          <el-table-column label="物料数" width="80" align="center">
            <template slot-scope="{ row }">{{ (row.material_ids || []).length }}</template>
          </el-table-column>
          <el-table-column label="状态" width="90">
            <template slot-scope="{ row }">
              <el-tag :type="row.status_tag" size="small">{{ row.status_label }}</el-tag>
            </template>
          </el-table-column>
        </el-table>
        <div class="detail-summary" v-if="planDetail.summary">
          <el-tag type="success" size="small">盘盈 {{ planDetail.summary.gain }} 项 / +{{ fmtNum(planDetail.summary.gain_qty) }}</el-tag>
          <el-tag type="danger" size="small" style="margin-left: 8px">盘亏 {{ planDetail.summary.loss }} 项 / -{{ fmtNum(planDetail.summary.loss_qty) }}</el-tag>
          <el-tag type="info" size="small" style="margin-left: 8px">差异共 {{ planDetail.summary.total }} 项</el-tag>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import request from '@/api/request'

export default {
  name: 'WarehouseStocktake',
  data() {
    return {
      activeTab: 'plan',
      statusMap: { 0: '草稿', 1: '待审核', 2: '已审核', 3: '执行中', 4: '已完成', 5: '已取消' },
      taskStatusMap: { 0: '待执行', 1: '执行中', 2: '已完成', 3: '已逾期' },
      planQuery: { plan_no: '', plan_name: '', plan_type: '', status: '', page: 1, limit: 15 },
      planList: [],
      planTotal: 0,
      planLoading: false,
      taskQuery: { keyword: '', status: '', page: 1, limit: 15 },
      taskList: [],
      taskTotal: 0,
      taskLoading: false,
      diffQuery: { keyword: '', status: '', page: 1, limit: 15 },
      diffList: [],
      diffTotal: 0,
      diffLoading: false,
      warehouseOptions: [],
      userOptions: [],
      planDialog: false,
      planSaving: false,
      planDateRange: [],
      planForm: { id: 0, plan_name: '', plan_type: 1, warehouse_id: 0, scope_type: 1, inventory_method: 1, expected_duration: 1, responsible_person_id: 0, remark: '' },
      detailDialog: false,
      planDetail: {}
    }
  },
  mounted() {
    this.loadPlans(1)
    this.loadWarehouses()
    this.loadUsers()
  },
  methods: {
    fmtNum(v) {
      const n = Number(v || 0)
      return n % 1 === 0 ? n : n.toFixed(2)
    },
    onTab() {
      if (this.activeTab === 'execute' && !this.taskList.length) this.loadTasks(1)
      if (this.activeTab === 'diff' && !this.diffList.length) this.loadDiffs(1)
    },
    loadWarehouses() {
      request.get('/warehouse/setting/warehouse/list').then((res) => {
        const d = res.data || {}
        this.warehouseOptions = (d.list || []).map((w) => ({ id: w.id, warehouse_name: w.warehouse_name || w.name || w.location_name }))
      }).catch(() => {})
    },
    loadUsers() {
      request.get('/users/options').then((res) => {
        this.userOptions = (res.data || []).map((u) => ({ id: u.id, username: u.username, real_name: u.real_name }))
      }).catch(() => {})
    },
    loadPlans(page) {
      this.planQuery.page = page || 1
      this.planLoading = true
      const params = { page: this.planQuery.page, pageSize: this.planQuery.limit }
      if (this.planQuery.plan_no) params.plan_no = this.planQuery.plan_no
      if (this.planQuery.plan_name) params.plan_name = this.planQuery.plan_name
      if (this.planQuery.plan_type !== '') params.plan_type = this.planQuery.plan_type
      if (this.planQuery.status !== '') params.status = this.planQuery.status
      request.get('/warehouse/check/plan/list', { params }).then((res) => {
        const d = res.data || { list: [], total: 0 }
        this.planList = d.list || []
        this.planTotal = d.total || 0
      }).finally(() => { this.planLoading = false })
    },
    openPlanDialog(row) {
      if (row && row.id) {
        this.planForm = {
          id: row.id, plan_name: row.plan_name, plan_type: row.plan_type,
          warehouse_id: row.warehouse_id, scope_type: row.scope_type,
          inventory_method: row.inventory_method, expected_duration: row.expected_duration || 1,
          responsible_person_id: row.responsible_person_id, remark: row.remark
        }
        this.planDateRange = [row.plan_start_date, row.plan_end_date]
      } else {
        this.planForm = { id: 0, plan_name: '', plan_type: 1, warehouse_id: 0, scope_type: 1, inventory_method: 1, expected_duration: 1, responsible_person_id: 0, remark: '' }
        this.planDateRange = []
      }
      this.planDialog = true
    },
    savePlan() {
      if (!this.planForm.plan_name) return this.$message.warning('请填写计划名称')
      if (!this.planForm.warehouse_id) return this.$message.warning('请选择盘点仓库')
      if (!this.planDateRange || !this.planDateRange.length) return this.$message.warning('请选择计划日期')
      if (!this.planForm.responsible_person_id) return this.$message.warning('请选择负责人')
      this.planSaving = true
      const payload = {
        ...this.planForm,
        scope_value: '[]',
        participants: '[]',
        plan_start_date: this.planDateRange[0],
        plan_end_date: this.planDateRange[1]
      }
      request.post('/warehouse/check/plan/save', payload).then((res) => {
        this.$message.success(res.msg || '保存成功')
        this.planDialog = false
        this.loadPlans(this.planQuery.page)
      }).finally(() => { this.planSaving = false })
    },
    viewPlan(row) {
      request.get('/warehouse/check/plan/detail/' + row.id).then((res) => {
        this.planDetail = res.data || {}
        this.detailDialog = true
      })
    },
    submitPlan(row) {
      this.$confirm(`提交盘点计划 ${row.plan_no} 进入审批流？`, '提交审批', { type: 'warning' }).then(() => {
        request.post('/warehouse/check/plan/submit/' + row.id).then((res) => {
          this.$message.success(res.msg || '已提交')
          this.loadPlans(this.planQuery.page)
        })
      }).catch(() => {})
    },
    cancelPlan(row) {
      this.$confirm(`确定取消盘点计划 ${row.plan_no}？`, '取消计划', { type: 'info' }).then(() => {
        request.post('/warehouse/check/plan/cancel/' + row.id).then((res) => {
          this.$message.success(res.msg || '已取消')
          this.loadPlans(this.planQuery.page)
        })
      }).catch(() => {})
    },
    deletePlan(row) {
      this.$confirm(`确定删除盘点计划 ${row.plan_no}？`, '删除计划', { type: 'error' }).then(() => {
        request.post('/warehouse/check/plan/delete/' + row.id).then((res) => {
          this.$message.success(res.msg || '已删除')
          this.loadPlans(this.planQuery.page)
        })
      }).catch(() => {})
    },
    startPlan(row) {
      this.$confirm(`开始执行盘点计划 ${row.plan_no}？`, '开始执行', { type: 'warning' }).then(() => {
        request.post('/warehouse/check/plan/start/' + row.id).then((res) => {
          this.$message.success(res.msg || '已开始执行')
          this.loadPlans(this.planQuery.page)
        })
      }).catch(() => {})
    },
    completePlan(row) {
      this.$confirm(`确认完成盘点计划 ${row.plan_no}？`, '完成任务', { type: 'warning' }).then(() => {
        request.post('/warehouse/check/plan/complete/' + row.id).then((res) => {
          this.$message.success(res.msg || '已完成')
          this.loadPlans(this.planQuery.page)
        })
      }).catch(() => {})
    },
    loadTasks(page) {
      this.taskQuery.page = page || 1
      this.taskLoading = true
      const params = { page: this.taskQuery.page, pageSize: this.taskQuery.limit }
      if (this.taskQuery.keyword) params.keyword = this.taskQuery.keyword
      if (this.taskQuery.status !== '') params.status = this.taskQuery.status
      request.get('/warehouse/check/execute/tasks', { params }).then((res) => {
        const d = res.data || { list: [], total: 0 }
        this.taskList = d.list || []
        this.taskTotal = d.total || 0
      }).finally(() => { this.taskLoading = false })
    },
    loadDiffs(page) {
      this.diffQuery.page = page || 1
      this.diffLoading = true
      const params = { page: this.diffQuery.page, pageSize: this.diffQuery.limit }
      if (this.diffQuery.keyword) params.keyword = this.diffQuery.keyword
      if (this.diffQuery.status !== '') params.status = this.diffQuery.status
      request.get('/warehouse/check/diff/list', { params }).then((res) => {
        const d = res.data || { list: [], total: 0 }
        this.diffList = d.list || []
        this.diffTotal = d.total || 0
      }).finally(() => { this.diffLoading = false })
    },
    processDiff(row) {
      this.$confirm(`处理差异：${row.material_name} 盘盈/盘亏 ${this.fmtNum(row.difference_quantity)}？`, '处理差异', { type: 'warning' }).then(() => {
        request.post('/warehouse/check/diff/process/' + row.id).then((res) => {
          this.$message.success(res.msg || '已处理')
          this.loadDiffs(this.diffQuery.page)
        })
      }).catch(() => {})
    },
    ignoreDiff(row) {
      this.$confirm(`确定忽略差异：${row.material_name}？`, '忽略差异', { type: 'info' }).then(() => {
        request.post('/warehouse/check/diff/ignore/' + row.id).then((res) => {
          this.$message.success(res.msg || '已忽略')
          this.loadDiffs(this.diffQuery.page)
        })
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.search-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
}
.sub-text {
  font-size: 12px;
  color: #9CA3AF;
}
.pager-row {
  margin-top: 14px;
  display: flex;
  justify-content: flex-end;
}
.diff-gain {
  color: #52C41A;
  font-weight: 600;
}
.diff-loss {
  color: #EA6668;
  font-weight: 600;
}
.detail-summary {
  margin-top: 12px;
}
</style>
