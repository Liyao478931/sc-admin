<!--
  文件：admin/src/views/production/execute/dispatch/Add.vue
  功能：新增/编辑派工（关联工单 + 工序任务分配：指定工位/设备/工人或班组）
  权限：production:dispatch:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产执行</el-breadcrumb-item>
      <el-breadcrumb-item>工单派工</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑派工' : '新增派工' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑派工' : '新增派工' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/production/execute/dispatch/list')">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="关联工单" prop="work_order_id">
              <el-select v-model="form.work_order_id" filterable placeholder="请选择待派工的工单" style="width:100%" @change="onOrderChange" :disabled="isEdit">
                <el-option v-for="o in orderOptions" :key="o.id" :label="`${o.order_no} - ${o.product_name}（${o.product_spec || ''}）`" :value="o.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="派工类型" prop="dispatch_type">
              <el-select v-model="form.dispatch_type" style="width:100%" @change="onTypeChange">
                <el-option :value="1" label="个人派工" />
                <el-option :value="2" label="班组派工" />
              </el-select>
            </el-form-item>
            <el-form-item label="派工人" prop="dispatcher_id">
              <el-select v-model="form.dispatcher_id" filterable placeholder="请选择派工人" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="派工日期" prop="dispatch_date">
              <el-date-picker v-model="form.dispatch_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
            </el-form-item>
            <el-form-item label="计划开始日期" prop="planned_start_date">
              <el-date-picker v-model="form.planned_start_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
            </el-form-item>
            <el-form-item label="计划完成日期" prop="planned_end_date">
              <el-date-picker v-model="form.planned_end_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 工序任务分配 -->
        <div class="sub-title">工序任务分配</div>
        <el-table :data="form.tasks" size="small" border empty-text="请先选择关联工单，再添加工序任务">
          <el-table-column type="index" label="#" width="45" align="center" />
          <el-table-column prop="process_name" label="工序名称" min-width="100" show-overflow-tooltip />
          <el-table-column prop="process_group" label="工序组" width="90" show-overflow-tooltip />
          <el-table-column label="计划数量" width="90" align="right"><template slot-scope="s">{{ Number(s.row.planned_quantity) }}</template></el-table-column>
          <el-table-column label="指定工位" width="150">
            <template slot-scope="s">
              <el-select v-model="s.row.workstation_id" size="mini" filterable placeholder="选择空闲工位" style="width:100%" @change="onWsChange(s.row)">
                <el-option v-for="w in wsOptions" :key="w.id" :label="w.workstation_name" :value="w.id" />
              </el-select>
            </template>
          </el-table-column>
          <el-table-column label="指定设备" width="150">
            <template slot-scope="s">
              <el-select v-model="s.row.device_id" size="mini" filterable placeholder="选择设备" style="width:100%" :disabled="!s.row.workstation_id">
                <el-option v-for="d in s.row.deviceOptions" :key="d.device_id" :label="`${d.device_name}（${d.device_code}）`" :value="d.device_id" />
              </el-select>
            </template>
          </el-table-column>
          <el-table-column :label="form.dispatch_type === 1 ? '被派工人' : '被派班组'" width="150">
            <template slot-scope="s">
              <el-select v-if="form.dispatch_type === 1" v-model="s.row.worker_id" size="mini" filterable placeholder="选择工人" style="width:100%" :disabled="!s.row.workstation_id">
                <el-option v-for="u in s.row.staffOptions" :key="u.user_id" :label="u.user_name" :value="u.user_id" />
              </el-select>
              <el-select v-else v-model="s.row.team_id" size="mini" filterable placeholder="选择班组" style="width:100%">
                <el-option v-for="t in teamOptions" :key="t.id" :label="t.name" :value="t.id" />
              </el-select>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="60" align="center">
            <template slot-scope="s"><el-button type="text" size="mini" class="danger-text" @click="removeTask(s.$index)">删除</el-button></template>
          </el-table-column>
        </el-table>
        <el-button size="small" icon="el-icon-plus" style="margin-top:10px" :disabled="!form.work_order_id" @click="taskDialogVisible = true">添加工序任务</el-button>
      </el-form>
    </el-card>

    <!-- 工序选择对话框 -->
    <el-dialog title="选择工序任务" :visible.sync="taskDialogVisible" width="600px" append-to-body>
      <el-select v-model="selectedTaskIds" multiple filterable placeholder="选择工序（可多选）" style="width:100%">
        <el-option v-for="t in availableTasks" :key="t.process_id" :label="`${t.process_name}（${t.process_group || '未分组'}）计划${Number(t.planned_quantity)}`" :value="t.process_id" />
      </el-select>
      <div slot="footer">
        <el-button size="small" @click="taskDialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="addTasks">添加</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  getDispatchableOrders, getOrderTasks, getDispatchWsOptions, getDispatchDevices, getDispatchStaff,
  getDispatchTeams, getDispatchDetail, saveDispatch, getOrderUsers
} from '@/api/production'

export default {
  name: 'ProductionDispatchAdd',
  data () {
    return {
      isEdit: false,
      orderOptions: [], userOptions: [], wsOptions: [], teamOptions: [],
      availableTasks: [], selectedTaskIds: [], taskDialogVisible: false,
      form: {
        work_order_id: null, dispatch_type: 1, dispatcher_id: null, dispatcher_name: '',
        dispatch_date: this.today(), planned_start_date: this.today(), planned_end_date: '', tasks: []
      },
      rules: {
        work_order_id: [{ required: true, message: '请选择关联工单' }],
        dispatch_type: [{ required: true, message: '请选择派工类型' }],
        dispatcher_id: [{ required: true, message: '请选择派工人' }],
        dispatch_date: [{ required: true, message: '请选择派工日期' }],
        planned_start_date: [{ required: true, message: '请选择计划开始日期' }],
        planned_end_date: [{ required: true, message: '请选择计划完成日期' }]
      },
      saving: false
    }
  },
  created () {
    this.loadOrders()
    this.loadUsers()
    this.loadWs()
    this.loadTeams()
    this.prefillDispatcher()
    const id = this.$route.params.id
    if (id) { this.isEdit = true; this.loadDetail(id) }
  },
  methods: {
    today () { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    prefillDispatcher () {
      const info = this.$store.state.user && this.$store.state.user.userInfo
      if (info && info.id) {
        this.form.dispatcher_id = info.id
        this.form.dispatcher_name = info.real_name || info.username || ''
      }
    },
    async loadOrders () { try { const r = await getDispatchableOrders(); if (r.code === 0) this.orderOptions = r.data.list || [] } catch (e) { this.orderOptions = [] } },
    async loadUsers () { try { const r = await getOrderUsers(); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) { this.userOptions = [] } },
    async loadWs () { try { const r = await getDispatchWsOptions(); if (r.code === 0) this.wsOptions = r.data.list || [] } catch (e) { this.wsOptions = [] } },
    async loadTeams () { try { const r = await getDispatchTeams(); if (r.code === 0) this.teamOptions = r.data.list || [] } catch (e) { this.teamOptions = [] } },
    onTypeChange () {
      this.form.tasks.forEach(t => { t.worker_id = null; t.team_id = null })
    },
    async onOrderChange (id) {
      this.form.tasks = []
      this.availableTasks = []
      this.selectedTaskIds = []
      if (!id) return
      try {
        const r = await getOrderTasks(id)
        if (r.code === 0) this.availableTasks = r.data.tasks || []
      } catch (e) { this.availableTasks = [] }
    },
    async onWsChange (row) {
      row.device_id = null
      row.worker_id = null
      row.deviceOptions = []
      row.staffOptions = []
      if (!row.workstation_id) return
      const [d, s] = await Promise.all([getDispatchDevices(row.workstation_id), getDispatchStaff(row.workstation_id)])
      if (d.code === 0) row.deviceOptions = d.data.list || []
      if (s.code === 0) row.staffOptions = s.data.list || []
    },
    addTasks () {
      if (!this.selectedTaskIds.length) { this.$message.warning('请选择工序任务'); return }
      const existing = this.form.tasks.map(t => t.process_id)
      let added = 0
      this.selectedTaskIds.forEach(pid => {
        if (existing.includes(pid)) return
        const t = this.availableTasks.find(x => x.process_id === pid)
        if (t) {
          this.form.tasks.push({
            work_order_item_id: t.work_order_item_id, process_id: t.process_id, process_name: t.process_name,
            process_group: t.process_group || '', planned_quantity: t.planned_quantity,
            workstation_id: null, workstation_name: '', device_id: null, device_name: '',
            worker_id: null, worker_name: '', team_id: null, team_name: '',
            deviceOptions: [], staffOptions: [], sort_order: this.form.tasks.length + 1
          })
          added++
        }
      })
      if (added) { this.$message.success(`已添加 ${added} 个工序任务`); this.taskDialogVisible = false; this.selectedTaskIds = [] }
      else this.$message.warning('所选工序已在列表中')
    },
    removeTask (idx) { this.form.tasks.splice(idx, 1) },
    async loadDetail (id) {
      try {
        const r = await getDispatchDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data.dispatch
          this.form = {
            work_order_id: d.work_order_id, dispatch_type: d.dispatch_type, dispatcher_id: d.dispatcher_id,
            dispatcher_name: d.dispatcher_name, dispatch_date: d.dispatch_date || this.today(),
            planned_start_date: d.planned_start_date || this.today(), planned_end_date: d.planned_end_date || '',
            tasks: []
          }
          for (const t of r.data.tasks || []) {
            const row = {
              work_order_item_id: t.work_order_item_id, process_id: t.process_id, process_name: t.process_name,
              process_group: '', planned_quantity: t.planned_quantity,
              workstation_id: t.workstation_id, workstation_name: t.workstation_name,
              device_id: t.device_id, device_name: t.device_name,
              worker_id: t.worker_id, worker_name: t.worker_name,
              team_id: t.team_id, team_name: t.team_name,
              deviceOptions: [], staffOptions: [], sort_order: t.sort_order
            }
            this.form.tasks.push(row)
            await this.onWsChange(row)
          }
        }
      } catch (e) {}
    },
    async handleSave () {
      if (!this.form.work_order_id) { this.$message.warning('请选择关联工单'); return }
      if (!this.form.dispatcher_id) { this.$message.warning('请选择派工人'); return }
      if (!this.form.dispatch_date || !this.form.planned_start_date || !this.form.planned_end_date) { this.$message.warning('请完善派工日期与计划日期'); return }
      if (this.form.planned_end_date < this.form.planned_start_date) { this.$message.warning('计划完成日期不能早于计划开始日期'); return }
      if (!this.form.tasks.length) { this.$message.warning('请至少添加一个工序任务'); return }
      for (let i = 0; i < this.form.tasks.length; i++) {
        const t = this.form.tasks[i]
        if (!t.workstation_id) { this.$message.warning(`第 ${i + 1} 个工序任务未指定工位`); return }
        if (!t.device_id) { this.$message.warning(`第 ${i + 1} 个工序任务未指定设备`); return }
        if (this.form.dispatch_type === 1 && !t.worker_id) { this.$message.warning(`第 ${i + 1} 个工序任务未指派工人`); return }
        if (this.form.dispatch_type === 2 && !t.team_id) { this.$message.warning(`第 ${i + 1} 个工序任务未选择班组`); return }
      }
      this.saving = true
      try {
        const data = {
          work_order_id: this.form.work_order_id, dispatch_type: this.form.dispatch_type,
          dispatcher_id: this.form.dispatcher_id, dispatcher_name: this.form.dispatcher_name,
          dispatch_date: this.form.dispatch_date,
          planned_start_date: this.form.planned_start_date, planned_end_date: this.form.planned_end_date,
          tasks: this.form.tasks.map((t, i) => ({
            work_order_item_id: t.work_order_item_id, process_id: t.process_id, process_name: t.process_name,
            workstation_id: t.workstation_id, workstation_name: t.workstation_name,
            device_id: t.device_id, device_name: t.device_name,
            worker_id: this.form.dispatch_type === 1 ? t.worker_id : 0, worker_name: t.worker_name,
            team_id: this.form.dispatch_type === 2 ? t.team_id : 0, team_name: t.team_name,
            planned_quantity: t.planned_quantity, sort_order: t.sort_order || (i + 1)
          }))
        }
        if (this.isEdit) data.id = this.$route.params.id
        const r = await saveDispatch(data)
        if (r.code === 0) { this.$message.success('保存成功'); this.$router.replace('/production/execute/dispatch/list') } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; background: #fff; padding: 14px 20px; border-radius: 8px 8px 0 0; border-bottom: 1px solid #ebeef5; }
.page-title { font-size: 18px; font-weight: 700; }
.header-actions { display: flex; gap: 10px; }
.form-card { margin-top: 12px; border-radius: 8px; }
.sub-title { font-size: 14px; font-weight: 600; margin: 8px 0 12px; }
.danger-text { color: #F56C6C; }
</style>
