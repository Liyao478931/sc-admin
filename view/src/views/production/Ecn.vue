<template>
  <div class="page-container">
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词"><el-input v-model="filter.keyword" placeholder="变更单号/标题/对象" clearable style="width:200px" @keyup.enter.native="load" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filter.status" placeholder="全部" clearable style="width:120px">
            <el-option label="草稿" :value="0" /><el-option label="待审批" :value="1" /><el-option label="已批准" :value="2" /><el-option label="已驳回" :value="3" /><el-option label="已生效" :value="4" />
          </el-select>
        </el-form-item>
        <el-form-item><el-button type="primary" icon="el-icon-search" @click="load">查询</el-button><el-button icon="el-icon-refresh-left" @click="reset">重置</el-button></el-form-item>
      </el-form>
    </el-card>
    <div class="toolbar">
      <el-button v-permission="'production:ecn:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新建变更单</el-button>
    </div>
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column prop="ecn_no" label="变更单号" min-width="140" />
        <el-table-column prop="title" label="变更标题" min-width="170" show-overflow-tooltip />
        <el-table-column prop="type" label="变更类型" width="100" />
        <el-table-column prop="object_name" label="变更对象" min-width="120" />
        <el-table-column prop="applicant" label="申请人" width="90" />
        <el-table-column prop="status" label="状态" width="90">
          <template #default="{row}">
            <el-tag :type="['info','warning','success','danger','primary'][row.status] || 'info'" size="mini">{{ ['草稿','待审批','已批准','已驳回','已生效'][row.status] || '未知' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="effective_date" label="生效日期" width="105" />
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{row}">
            <el-button v-if="row.status === 1" v-permission="'production:ecn:add'" type="text" size="small" @click="approve(row, 'approve')">批准</el-button>
            <el-button v-if="row.status === 1" v-permission="'production:ecn:add'" type="text" size="small" class="danger" @click="approve(row, 'reject')">驳回</el-button>
            <el-button v-if="row.status === 2" v-permission="'production:ecn:add'" type="text" size="small" class="success" @click="effect(row)">生效</el-button>
            <el-button type="text" size="small" @click="openForm(row)">编辑</el-button>
            <el-button type="text" size="small" class="danger" @click="del(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next, sizes" :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10,20,50,100]" @current-change="p => { page = p; load() }" @size-change="s => { pageSize = s; page = 1; load() }" />
    </el-card>
    <el-dialog :title="form.id ? '编辑变更单' : '新建变更单'" :visible.sync="formVisible" width="640px">
      <el-form :model="form" label-width="95px" size="small">
        <el-row :gutter="12">
          <el-col :span="24"><el-form-item label="变更标题" required><el-input v-model="form.title" placeholder="如 液压支架密封圈规格变更" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="变更类型"><el-select v-model="form.type" style="width:100%"><el-option label="设计变更" value="设计变更" /><el-option label="工艺变更" value="工艺变更" /><el-option label="材料变更" value="材料变更" /><el-option label="文档变更" value="文档变更" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="对象类型"><el-select v-model="form.object_type" style="width:100%"><el-option label="产品" value="产品" /><el-option label="物料" value="物料" /><el-option label="工艺路线" value="工艺路线" /><el-option label="图纸" value="图纸" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="变更对象"><el-input v-model="form.object_name" placeholder="对象名称/编号" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="计划生效日期"><el-date-picker v-model="form.effective_date" type="date" value-format="YYYY-MM-DD" style="width:100%" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="变更原因"><el-input v-model="form.reason" type="textarea" :rows="2" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="变更内容"><el-input v-model="form.content" type="textarea" :rows="3" /></el-form-item></el-col>
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
  name: 'ProductionEcn',
  data() {
    return {
      loading: false, saving: false, list: [], total: 0, page: 1, pageSize: 20,
      filter: { keyword: '', status: '' }, formVisible: false,
      form: { id: 0, ecn_no: 'ECN' + this.dateStr() + '-', title: '', type: '设计变更', object_type: '产品', object_name: '', reason: '', content: '', status: 0, effective_date: null }
    }
  },
  created() { this.load() },
  methods: {
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/ecn/list', method: 'get', params: { page: this.page, pageSize: this.pageSize, keyword: this.filter.keyword, status: this.filter.status } })
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    reset() { this.filter = { keyword: '', status: '' }; this.page = 1; this.load() },
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, ecn_no: 'ECN' + this.dateStr() + '-', title: '', type: '设计变更', object_type: '产品', object_name: '', reason: '', content: '', status: 0, effective_date: null }
      this.formVisible = true
    },
    dateStr() { const d = new Date(); return d.getFullYear() + String(d.getMonth() + 1).padStart(2, '0') + String(d.getDate()).padStart(2, '0') },
    async save() {
      if (!this.form.title) return this.$message.warning('变更标题不能为空')
      this.saving = true
      try {
        const res = await request({ url: '/ecn/save', method: 'post', data: this.form })
        if (res.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.load() }
        else this.$message.error(res.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') }
      this.saving = false
    },
    async approve(row, action) {
      const res = await request({ url: '/ecn/approve', method: 'post', data: { id: row.id, action } })
      if (res.code === 0) { this.$message.success(action === 'approve' ? '已批准' : '已驳回'); this.load() }
    },
    async effect(row) {
      const res = await request({ url: '/ecn/effect', method: 'post', data: { id: row.id } })
      if (res.code === 0) { this.$message.success('已生效'); this.load() }
    },
    del(row) {
      this.$confirm('确认删除变更单 ' + row.ecn_no + '？', '提示', { type: 'warning' }).then(async () => {
        const res = await request({ url: '/ecn/delete', method: 'post', data: { id: row.id } })
        if (res.code === 0) { this.$message.success('已删除'); this.load() }
      }).catch(() => {})
    }
  }
}
</script>
<style scoped>
.page-container { padding: 4px; }
.filter-card { margin-bottom: 10px; }
.toolbar { margin-bottom: 10px; }
.pager { margin-top: 12px; text-align: right; }
.success { color: #67C23A; }
</style>
