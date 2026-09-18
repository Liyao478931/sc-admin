<template>
  <div class="page-container">
    <el-row :gutter="14" class="stat-row">
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ stats.total || 0 }}</div><div class="stat-label">项目总数</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ stats.doing || 0 }}</div><div class="stat-label">进行中</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num green">{{ stats.done || 0 }}</div><div class="stat-label">已完成</div></el-card></el-col>
    </el-row>

    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词"><el-input v-model="filter.keyword" placeholder="项目编号/名称/客户" clearable style="width:200px" @keyup.enter.native="load" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filter.status" placeholder="全部" clearable style="width:120px">
            <el-option label="未开始" :value="0" /><el-option label="进行中" :value="1" /><el-option label="已暂停" :value="2" /><el-option label="已完成" :value="3" /><el-option label="已取消" :value="4" />
          </el-select>
        </el-form-item>
        <el-form-item><el-button type="primary" icon="el-icon-search" @click="load">查询</el-button><el-button icon="el-icon-refresh-left" @click="reset">重置</el-button></el-form-item>
      </el-form>
    </el-card>
    <div class="toolbar">
      <el-button v-permission="'business:project:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新建项目</el-button>
    </div>
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column prop="project_no" label="项目编号" min-width="130" />
        <el-table-column prop="name" label="项目名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="customer_name" label="客户" min-width="110" />
        <el-table-column prop="manager" label="负责人" width="90" />
        <el-table-column prop="start_date" label="开始日期" width="100" />
        <el-table-column prop="end_date" label="结束日期" width="100" />
        <el-table-column prop="budget" label="预算(¥)" width="105"><template #default="{row}">{{ Number(row.budget || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="进度" width="160">
          <template #default="{row}">
            <el-progress :percentage="row.progress || 0" :stroke-width="8" />
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="90">
          <template #default="{row}">
            <el-tag :type="['info','primary','warning','success','danger'][row.status] || 'info'" size="mini">{{ ['未开始','进行中','已暂停','已完成','已取消'][row.status] || '未知' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{row}">
            <el-button type="text" size="small" @click="openForm(row)">编辑</el-button>
            <el-button type="text" size="small" class="danger" @click="del(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next, sizes" :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10,20,50,100]" @current-change="p => { page = p; load() }" @size-change="s => { pageSize = s; page = 1; load() }" />
    </el-card>
    <el-dialog :title="form.id ? '编辑项目' : '新建项目'" :visible.sync="formVisible" width="640px">
      <el-form :model="form" label-width="95px" size="small">
        <el-row :gutter="12">
          <el-col :span="24"><el-form-item label="项目名称" required><el-input v-model="form.name" placeholder="如 支架维修自动化改造项目" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="客户"><el-input v-model="form.customer_name" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="负责人"><el-input v-model="form.manager" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="成员"><el-input v-model="form.members" placeholder="多人用逗号分隔" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="优先级"><el-select v-model="form.priority" style="width:100%"><el-option label="高" value="高" /><el-option label="中" value="中" /><el-option label="低" value="低" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="开始日期"><el-date-picker v-model="form.start_date" type="date" value-format="YYYY-MM-DD" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="结束日期"><el-date-picker v-model="form.end_date" type="date" value-format="YYYY-MM-DD" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="预算(¥)"><el-input-number v-model="form.budget" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="进度%"><el-input-number v-model="form.progress" :min="0" :max="100" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="状态">
            <el-select v-model="form.status" style="width:100%"><el-option label="未开始" :value="0" /><el-option label="进行中" :value="1" /><el-option label="已暂停" :value="2" /><el-option label="已完成" :value="3" /><el-option label="已取消" :value="4" /></el-select>
          </el-form-item></el-col>
          <el-col :span="24"><el-form-item label="项目描述"><el-input v-model="form.description" type="textarea" :rows="2" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>
<script>
import request from '@/api/request'
export default {
  name: 'BusinessProject',
  data() {
    return {
      loading: false, saving: false, list: [], total: 0, page: 1, pageSize: 20,
      stats: {}, filter: { keyword: '', status: '' }, formVisible: false,
      form: { id: 0, project_no: 'PRJ' + this.dateStr() + '-', name: '', customer_name: '', manager: '', members: '', start_date: '', end_date: '', budget: 0, progress: 0, status: 0, priority: '中', description: '' }
    }
  },
  created() { this.load(); this.loadStats() },
  methods: {
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/project/list', method: 'get', params: { page: this.page, pageSize: this.pageSize, keyword: this.filter.keyword, status: this.filter.status } })
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    async loadStats() {
      try {
        const res = await request({ url: '/project/stats', method: 'get' })
        if (res.code === 0) this.stats = res.data || {}
      } catch (e) {}
    },
    reset() { this.filter = { keyword: '', status: '' }; this.page = 1; this.load() },
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, project_no: 'PRJ' + this.dateStr() + '-', name: '', customer_name: '', manager: '', members: '', start_date: '', end_date: '', budget: 0, progress: 0, status: 0, priority: '中', description: '' }
      this.formVisible = true
    },
    dateStr() { const d = new Date(); return d.getFullYear() + String(d.getMonth() + 1).padStart(2, '0') + String(d.getDate()).padStart(2, '0') },
    async save() {
      if (!this.form.name) return this.$message.warning('项目名称不能为空')
      this.saving = true
      try {
        const res = await request({ url: '/project/save', method: 'post', data: this.form })
        if (res.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.load(); this.loadStats() }
        else this.$message.error(res.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') }
      this.saving = false
    },
    del(row) {
      this.$confirm('确认删除项目 ' + row.name + '？', '提示', { type: 'warning' }).then(async () => {
        const res = await request({ url: '/project/delete', method: 'post', data: { id: row.id } })
        if (res.code === 0) { this.$message.success('已删除'); this.load(); this.loadStats() }
      }).catch(() => {})
    }
  }
}
</script>
<style scoped>
.page-container { padding: 4px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 24px; font-weight: 700; color: #333; }
.stat-num.blue { color: #409EFF; } .stat-num.green { color: #67C23A; }
.stat-label { color: #909399; font-size: 13px; margin-top: 4px; }
.filter-card { margin-bottom: 10px; }
.toolbar { margin-bottom: 10px; }
.pager { margin-top: 12px; text-align: right; }
</style>
