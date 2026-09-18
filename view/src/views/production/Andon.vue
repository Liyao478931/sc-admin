<template>
  <div class="page-container">
    <el-row :gutter="14" class="stat-row">
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num orange">{{ stats.waiting || 0 }}</div><div class="stat-label">等待处理</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ stats.processing || 0 }}</div><div class="stat-label">处理中</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num green">{{ stats.closed || 0 }}</div><div class="stat-label">已关闭</div></el-card></el-col>
    </el-row>

    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词"><el-input v-model="filter.keyword" placeholder="呼叫单号/设备/工位" clearable style="width:180px" @keyup.enter.native="load" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filter.status" placeholder="全部" clearable style="width:120px">
            <el-option label="待处理" :value="0" /><el-option label="处理中" :value="1" /><el-option label="已关闭" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item><el-button type="primary" icon="el-icon-search" @click="load">查询</el-button></el-form-item>
      </el-form>
    </el-card>
    <div class="toolbar">
      <el-button v-permission="'production:andon:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">发起呼叫</el-button>
    </div>
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column prop="andon_no" label="呼叫单号" min-width="140" />
        <el-table-column prop="device_name" label="设备" min-width="120" />
        <el-table-column prop="station" label="工位" min-width="100" />
        <el-table-column prop="type" label="类型" width="90" />
        <el-table-column prop="description" label="描述" min-width="160" show-overflow-tooltip />
        <el-table-column prop="caller" label="发起人" width="90" />
        <el-table-column prop="responder" label="响应人" width="90" />
        <el-table-column prop="status" label="状态" width="90">
          <template #default="{row}">
            <el-tag :type="row.status === 0 ? 'danger' : (row.status === 1 ? 'warning' : 'success')" size="mini">{{ row.status === 0 ? '待处理' : (row.status === 1 ? '处理中' : '已关闭') }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="190" fixed="right">
          <template #default="{row}">
            <el-button v-if="row.status === 0" v-permission="'production:andon:add'" type="text" size="small" @click="respond(row)">响应</el-button>
            <el-button v-if="row.status !== 2" v-permission="'production:andon:add'" type="text" size="small" class="success" @click="close(row)">关闭</el-button>
            <el-button type="text" size="small" @click="openForm(row)">编辑</el-button>
            <el-button type="text" size="small" class="danger" @click="del(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next, sizes" :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10,20,50,100]" @current-change="p => { page = p; load() }" @size-change="s => { pageSize = s; page = 1; load() }" />
    </el-card>
    <el-dialog :title="form.id ? '编辑呼叫' : '发起异常呼叫'" :visible.sync="formVisible" width="560px">
      <el-form :model="form" label-width="90px" size="small">
        <el-row :gutter="12">
          <el-col :span="12"><el-form-item label="设备名称" required><el-input v-model="form.device_name" placeholder="如 数控车床-01" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="工位"><el-input v-model="form.station" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="异常类型"><el-select v-model="form.type" style="width:100%"><el-option label="设备故障" value="设备故障" /><el-option label="物料短缺" value="物料短缺" /><el-option label="质量异常" value="质量异常" /><el-option label="其他" value="其他" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="发起人"><el-input v-model="form.caller" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="异常描述"><el-input v-model="form.description" type="textarea" :rows="3" /></el-form-item></el-col>
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
  name: 'ProductionAndon',
  data() {
    return {
      loading: false, saving: false, list: [], total: 0, page: 1, pageSize: 20,
      stats: {}, filter: { keyword: '', status: '' },
      formVisible: false,
      form: { id: 0, andon_no: '', device_name: '', station: '', type: '设备故障', description: '', status: 0, caller: '' }
    }
  },
  created() { this.load(); this.loadStats() },
  methods: {
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/andon/list', method: 'get', params: { page: this.page, pageSize: this.pageSize, keyword: this.filter.keyword, status: this.filter.status } })
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    async loadStats() {
      try {
        const res = await request({ url: '/andon/stats', method: 'get' })
        if (res.code === 0) this.stats = res.data || {}
      } catch (e) {}
    },
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, andon_no: 'AN' + this.dateStr() + '-', device_name: '', station: '', type: '设备故障', description: '', status: 0, caller: '' }
      this.formVisible = true
    },
    dateStr() { const d = new Date(); return d.getFullYear() + String(d.getMonth() + 1).padStart(2, '0') + String(d.getDate()).padStart(2, '0') },
    async save() {
      if (!this.form.device_name) return this.$message.warning('设备名称不能为空')
      this.saving = true
      try {
        const res = await request({ url: '/andon/save', method: 'post', data: this.form })
        if (res.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.load(); this.loadStats() }
        else this.$message.error(res.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') }
      this.saving = false
    },
    async respond(row) {
      const res = await request({ url: '/andon/respond', method: 'post', data: { id: row.id } })
      if (res.code === 0) { this.$message.success('已响应'); this.load(); this.loadStats() }
    },
    async close(row) {
      const res = await request({ url: '/andon/close', method: 'post', data: { id: row.id } })
      if (res.code === 0) { this.$message.success('已关闭'); this.load(); this.loadStats() }
    },
    del(row) {
      this.$confirm('确认删除呼叫 ' + row.andon_no + '？', '提示', { type: 'warning' }).then(async () => {
        const res = await request({ url: '/andon/delete', method: 'post', data: { id: row.id } })
        if (res.code === 0) { this.$message.success('已删除'); this.load(); this.loadStats() }
      }).catch(() => {})
    }
  }
}
</script>
<style scoped>
.page-container { padding: 4px; }
.stat-row { margin-bottom: 10px; }
.stat-card { text-align: center; }
.stat-num { font-size: 24px; font-weight: 700; color: #333; }
.stat-num.blue { color: #409EFF; } .stat-num.orange { color: #E6A23C; } .stat-num.green { color: #67C23A; }
.stat-label { color: #909399; font-size: 13px; margin-top: 4px; }
.filter-card { margin-bottom: 10px; }
.toolbar { margin-bottom: 10px; }
.pager { margin-top: 12px; text-align: right; }
.success { color: #67C23A; }
</style>
