<template>
  <div class="page-container">
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词"><el-input v-model="filter.keyword" placeholder="商机/客户名称" clearable style="width:190px" @keyup.enter.native="load" /></el-form-item>
        <el-form-item label="阶段">
          <el-select v-model="filter.stage" placeholder="全部" clearable style="width:130px">
            <el-option v-for="(v, k) in stageMap" :key="k" :label="v" :value="Number(k)" />
          </el-select>
        </el-form-item>
        <el-form-item><el-button type="primary" icon="el-icon-search" @click="load">查询</el-button><el-button icon="el-icon-refresh-left" @click="reset">重置</el-button></el-form-item>
      </el-form>
    </el-card>
    <div class="toolbar">
      <el-button v-permission="'business:crm:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增商机</el-button>
    </div>
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column prop="opp_no" label="商机编号" min-width="140" />
        <el-table-column prop="name" label="商机名称" min-width="150" />
        <el-table-column prop="customer_name" label="客户" min-width="120" />
        <el-table-column prop="amount" label="金额(¥)" width="110"><template #default="{row}">{{ Number(row.amount || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column prop="stage" label="阶段" width="110">
          <template #default="{row}"><el-tag :type="stageTag(row.stage)" size="mini">{{ stageMap[row.stage] || row.stage }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="expect_date" label="预计成交" width="105" />
        <el-table-column prop="owner" label="负责人" width="90" />
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{row}">
            <el-button type="text" size="small" @click="openForm(row)">编辑</el-button>
            <el-button type="text" size="small" class="danger" @click="del(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next, sizes" :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10,20,50,100]" @current-change="p => { page = p; load() }" @size-change="s => { pageSize = s; page = 1; load() }" />
    </el-card>
    <el-dialog :title="form.id ? '编辑商机' : '新增商机'" :visible.sync="formVisible" width="580px">
      <el-form :model="form" label-width="95px" size="small">
        <el-row :gutter="12">
          <el-col :span="24"><el-form-item label="商机名称" required><el-input v-model="form.name" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="客户名称"><el-input v-model="form.customer_name" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="金额(¥)"><el-input-number v-model="form.amount" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="联系人"><el-input v-model="form.contact" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="联系电话"><el-input v-model="form.phone" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="阶段">
            <el-select v-model="form.stage" style="width:100%"><el-option v-for="(v, k) in stageMap" :key="k" :label="v" :value="Number(k)" /></el-select>
          </el-form-item></el-col>
          <el-col :span="12"><el-form-item label="预计成交"><el-date-picker v-model="form.expect_date" type="date" value-format="YYYY-MM-DD" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="负责人"><el-input v-model="form.owner" /></el-form-item></el-col>
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
  name: 'CrmOpportunities',
  data() {
    return {
      loading: false, saving: false, list: [], total: 0, page: 1, pageSize: 20,
      filter: { keyword: '', stage: '' }, formVisible: false,
      stageMap: { 1: '初步接触', 2: '需求确认', 3: '方案报价', 4: '商务谈判', 5: '赢单', 6: '输单' },
      form: { id: 0, name: '', customer_name: '', contact: '', phone: '', amount: 0, stage: 1, expect_date: '', owner: '', remark: '' }
    }
  },
  created() { this.load() },
  methods: {
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/crm/opportunities', method: 'get', params: { page: this.page, pageSize: this.pageSize, keyword: this.filter.keyword, stage: this.filter.stage } })
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    stageTag(s) { return ['', 'info', 'primary', 'warning', 'warning', 'success', 'danger'][Number(s)] || 'info' },
    reset() { this.filter = { keyword: '', stage: '' }; this.page = 1; this.load() },
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, name: '', customer_name: '', contact: '', phone: '', amount: 0, stage: 1, expect_date: '', owner: '', remark: '' }
      this.formVisible = true
    },
    async save() {
      if (!this.form.name) return this.$message.warning('商机名称不能为空')
      this.saving = true
      try {
        const res = await request({ url: '/crm/opp-save', method: 'post', data: this.form })
        if (res.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.load() }
        else this.$message.error(res.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') }
      this.saving = false
    },
    del(row) {
      this.$confirm('确认删除商机 ' + row.name + '？', '提示', { type: 'warning' }).then(async () => {
        const res = await request({ url: '/crm/opp-delete', method: 'post', data: { id: row.id } })
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
