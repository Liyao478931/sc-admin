<template>
  <div class="page-container">
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词">
          <el-input v-model="filter.keyword" placeholder="批次号/物料名称" clearable style="width:180px" @keyup.enter.native="load" />
        </el-form-item>
        <el-form-item label="类型">
          <el-select v-model="filter.item_type" placeholder="全部" clearable style="width:110px">
            <el-option label="物料" value="material" /><el-option label="产品" value="product" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="load">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
    <div class="toolbar">
      <el-button v-permission="'batch:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增批次</el-button>
      <span class="flex-1"></span>
    </div>
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column prop="batch_no" label="批次号" min-width="140" />
        <el-table-column prop="item_name" label="物料/产品" min-width="120" />
        <el-table-column prop="item_type" label="类型" width="80"><template #default="{row}">{{ row.item_type === 'product' ? '产品' : '物料' }}</template></el-table-column>
        <el-table-column prop="quantity" label="数量" width="90" />
        <el-table-column prop="unit" label="单位" width="70" />
        <el-table-column prop="prod_date" label="生产日期" width="105" />
        <el-table-column prop="expire_date" label="到期日期" width="105" />
        <el-table-column prop="location" label="库位" min-width="90" />
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{row}"><el-tag :type="row.status === 1 ? 'success' : 'info'" size="mini">{{ row.status === 1 ? '启用' : '停用' }}</el-tag></template>
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
    <el-dialog :title="form.id ? '编辑批次' : '新增批次'" :visible.sync="formVisible" width="600px">
      <el-form :model="form" label-width="95px" size="small">
        <el-row :gutter="12">
          <el-col :span="12"><el-form-item label="批次号" required><el-input v-model="form.batch_no" placeholder="如 PC20260914-001" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="类型"><el-select v-model="form.item_type" style="width:100%"><el-option label="物料" value="material" /><el-option label="产品" value="product" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="物料/产品"><el-select v-model="form.item_id" filterable clearable style="width:100%" @change="onItemChange">
            <el-option v-for="o in itemOptions" :key="o.id" :label="o.name" :value="o.id" />
          </el-select></el-form-item></el-col>
          <el-col :span="6"><el-form-item label="数量"><el-input-number v-model="form.quantity" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="6"><el-form-item label="单位"><el-input v-model="form.unit" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="来源"><el-input v-model="form.source" placeholder="采购/生产/退货" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="来源单号"><el-input v-model="form.source_no" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="生产日期"><el-date-picker v-model="form.prod_date" type="date" value-format="YYYY-MM-DD" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="到期日期"><el-date-picker v-model="form.expire_date" type="date" value-format="YYYY-MM-DD" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="库位"><el-input v-model="form.location" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="状态"><el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" /></el-form-item></el-col>
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
  name: 'WarehouseBatch',
  data() {
    return {
      loading: false, saving: false, list: [], total: 0, page: 1, pageSize: 20,
      filter: { keyword: '', item_type: '' },
      itemOptions: [], formVisible: false,
      form: { id: 0, batch_no: '', item_type: 'material', item_id: 0, item_name: '', quantity: 0, unit: '', source: '', source_no: '', prod_date: null, expire_date: null, location: '', status: 1, remark: '' }
    }
  },
  created() { this.load(); this.loadOptions() },
  methods: {
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/batch/list', method: 'get', params: { page: this.page, pageSize: this.pageSize, keyword: this.filter.keyword, item_type: this.filter.item_type } })
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    async loadOptions() {
      try {
        const res = await request({ url: '/batch/options', method: 'get' })
        if (res.code === 0) this.itemOptions = res.data || []
      } catch (e) {}
    },
    onItemChange(id) {
      const o = this.itemOptions.find(x => x.id === id)
      if (o) { this.form.item_name = o.name; if (!this.form.unit) this.form.unit = o.unit || '' }
    },
    reset() { this.filter = { keyword: '', item_type: '' }; this.page = 1; this.load() },
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, batch_no: 'PC' + this.dateStr() + '-', item_type: 'material', item_id: 0, item_name: '', quantity: 0, unit: '', source: '', source_no: '', prod_date: null, expire_date: null, location: '', status: 1, remark: '' }
      this.formVisible = true
    },
    dateStr() { const d = new Date(); return d.getFullYear() + String(d.getMonth() + 1).padStart(2, '0') + String(d.getDate()).padStart(2, '0') },
    async save() {
      if (!this.form.batch_no) return this.$message.warning('批次号不能为空')
      this.saving = true
      try {
        const res = await request({ url: '/batch/save', method: 'post', data: this.form })
        if (res.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.load() }
        else this.$message.error(res.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') }
      this.saving = false
    },
    del(row) {
      this.$confirm('确认删除批次 ' + row.batch_no + '？', '提示', { type: 'warning' }).then(async () => {
        const res = await request({ url: '/batch/delete', method: 'post', data: { id: row.id } })
        if (res.code === 0) { this.$message.success('已删除'); this.load() }
      }).catch(() => {})
    }
  }
}
</script>
<style scoped>
.page-container { padding: 4px; }
.filter-card { margin-bottom: 10px; }
.toolbar { display: flex; align-items: center; margin-bottom: 10px; }
.flex-1 { flex: 1; }
.pager { margin-top: 12px; text-align: right; }
</style>
