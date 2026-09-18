<template>
  <div class="page-container">
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词"><el-input v-model="filter.keyword" placeholder="客户/联系人/电话" clearable style="width:190px" @keyup.enter.native="load" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filter.status" placeholder="全部" clearable style="width:120px">
            <el-option label="新建" :value="0" /><el-option label="跟进中" :value="1" /><el-option label="已转化" :value="2" /><el-option label="已失效" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item><el-button type="primary" icon="el-icon-search" @click="load">查询</el-button><el-button icon="el-icon-refresh-left" @click="reset">重置</el-button></el-form-item>
      </el-form>
    </el-card>
    <div class="toolbar">
      <el-button v-permission="'business:crm:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增线索</el-button>
    </div>
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column prop="lead_no" label="线索编号" min-width="140" />
        <el-table-column prop="customer_name" label="客户名称" min-width="140" />
        <el-table-column prop="contact" label="联系人" width="90" />
        <el-table-column prop="phone" label="联系电话" min-width="120" />
        <el-table-column prop="source" label="来源" width="90" />
        <el-table-column prop="owner" label="负责人" width="90" />
        <el-table-column prop="status" label="状态" width="90">
          <template #default="{row}">
            <el-tag :type="['info','warning','success','danger'][row.status] || 'info'" size="mini">{{ ['新建','跟进中','已转化','已失效'][row.status] || '未知' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="155" />
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{row}">
            <el-button type="text" size="small" @click="openForm(row)">编辑</el-button>
            <el-button type="text" size="small" class="danger" @click="del(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next, sizes" :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10,20,50,100]" @current-change="p => { page = p; load() }" @size-change="s => { pageSize = s; page = 1; load() }" />
    </el-card>
    <el-dialog :title="form.id ? '编辑线索' : '新增线索'" :visible.sync="formVisible" width="560px">
      <el-form :model="form" label-width="90px" size="small">
        <el-row :gutter="12">
          <el-col :span="12"><el-form-item label="客户名称" required><el-input v-model="form.customer_name" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="来源"><el-select v-model="form.source" style="width:100%"><el-option label="网络推广" value="网络推广" /><el-option label="老客户推荐" value="老客户推荐" /><el-option label="展会" value="展会" /><el-option label="电话营销" value="电话营销" /><el-option label="其他" value="其他" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="联系人"><el-input v-model="form.contact" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="联系电话"><el-input v-model="form.phone" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="负责人"><el-input v-model="form.owner" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="状态">
            <el-select v-model="form.status" style="width:100%"><el-option label="新建" :value="0" /><el-option label="跟进中" :value="1" /><el-option label="已转化" :value="2" /><el-option label="已失效" :value="3" /></el-select>
          </el-form-item></el-col>
          <el-col :span="24"><el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item></el-col>
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
  name: 'CrmLeads',
  data() {
    return {
      loading: false, saving: false, list: [], total: 0, page: 1, pageSize: 20,
      filter: { keyword: '', status: '' }, formVisible: false,
      form: { id: 0, customer_name: '', contact: '', phone: '', source: '网络推广', status: 0, owner: '', remark: '' }
    }
  },
  created() { this.load() },
  methods: {
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/crm/leads', method: 'get', params: { page: this.page, pageSize: this.pageSize, keyword: this.filter.keyword, status: this.filter.status } })
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    reset() { this.filter = { keyword: '', status: '' }; this.page = 1; this.load() },
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, customer_name: '', contact: '', phone: '', source: '网络推广', status: 0, owner: '', remark: '' }
      this.formVisible = true
    },
    async save() {
      if (!this.form.customer_name) return this.$message.warning('客户名称不能为空')
      this.saving = true
      try {
        const res = await request({ url: '/crm/lead-save', method: 'post', data: this.form })
        if (res.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.load() }
        else this.$message.error(res.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') }
      this.saving = false
    },
    del(row) {
      this.$confirm('确认删除线索 ' + row.customer_name + '？', '提示', { type: 'warning' }).then(async () => {
        const res = await request({ url: '/crm/lead-delete', method: 'post', data: { id: row.id } })
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
</style>
