<!--
  文件：admin/src/views/hr/salary/subsidy/Index.vue
  功能：补助标准配置（学历补助 / 职称补助）
  权限：salary:subsidy:view/create/edit/delete
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
      <el-breadcrumb-item>补助标准配置</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-head">
      <span class="page-title">补助标准配置</span>
    </div>

    <el-tabs v-model="activeType" @tab-click="switchType">
      <el-tab-pane label="学历补助" name="education" />
      <el-tab-pane label="职称补助" name="title" />
    </el-tabs>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'salary:subsidy:create'" type="primary" size="small" icon="el-icon-plus" @click="openDialog()">新增标准</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 项</span>
    </div>

    <!-- 筛选区 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="70px" @submit.native.prevent>
        <el-form-item label="生效年份">
          <el-select v-model="query.year" clearable placeholder="全部年份" style="width:120px">
            <el-option v-for="y in years" :key="y" :label="y + '年'" :value="y" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:100px">
            <el-option label="启用" :value="1" /><el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无补助标准数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="编码" width="180">
        <template slot-scope="s"><el-tag size="mini" type="info">{{ s.row[codeField] }}</el-tag></template>
      </el-table-column>
      <el-table-column :label="nameLabel" min-width="140"><template slot-scope="s">{{ s.row[nameField] }}</template></el-table-column>
      <el-table-column label="补助金额" width="140" align="right"><template slot-scope="s"><strong style="color:#409EFF">{{ fmtMoney(s.row[amountField]) }}</strong> 元/月</template></el-table-column>
      <el-table-column label="生效年份" width="110" align="center"><template slot-scope="s">{{ s.row.effective_year }}年</template></el-table-column>
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status === 1 ? 'success' : 'info'" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="140" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'salary:subsidy:edit'" type="text" size="mini" @click="openDialog(s.row)">编辑</el-button>
          <el-button v-permission="'salary:subsidy:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑补助标准' : '新增补助标准'" :visible.sync="dialogVisible" width="480px" :close-on-click-modal="false">
      <el-form :model="form" label-width="90px" size="small">
        <el-form-item label="补助类型">
          <el-radio-group v-model="form.type" :disabled="!!form.id">
            <el-radio label="education">学历补助</el-radio>
            <el-radio label="title">职称补助</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="编码" required><el-input v-model="form.code" :placeholder="form.type === 'education' ? '如 bachelor' : '如 engineer'" /></el-form-item>
        <el-form-item label="名称" required><el-input v-model="form.name" :placeholder="form.type === 'education' ? '如 本科' : '如 工程师'" /></el-form-item>
        <el-form-item label="补助金额" required><el-input-number v-model="form.amount" :min="0" :precision="2" style="width:200px" /> 元/月</el-form-item>
        <el-form-item label="生效年份"><el-input-number v-model="form.year" :min="2000" :max="2100" style="width:200px" /></el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" maxlength="200" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getSubsidyList, createSubsidy, updateSubsidy, deleteSubsidy } from '@/api/salarySubsidy'

export default {
  name: 'HrSalarySubsidy',
  data () {
    return {
      activeType: 'education', list: [], total: 0, loading: false, years: [],
      query: { year: '', status: '' },
      dialogVisible: false, saving: false, form: this.emptyForm()
    }
  },
  computed: {
    codeField () { return this.activeType === 'education' ? 'education_code' : 'title_code' },
    nameField () { return this.activeType === 'education' ? 'education_level' : 'title_level' },
    amountField () { return 'subsidy_amount' },
    nameLabel () { return this.activeType === 'education' ? '学历' : '职称' }
  },
  created () { this.loadList() },
  methods: {
    emptyForm () {
      return { id: 0, type: 'education', code: '', name: '', amount: 0, year: new Date().getFullYear(), status: 1, remark: '' }
    },
    fmtMoney (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    switchType () { this.query = { year: '', status: '' }; this.loadList() },
    buildParams () {
      const p = { type: this.activeType }
      if (this.query.year !== '' && this.query.year !== null) p.year = this.query.year
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      return p
    },
    async loadList () {
      this.loading = true
      try {
        const r = await getSubsidyList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          if (r.data.years) this.years = r.data.years
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.loadList() },
    handleReset () { this.query = { year: '', status: '' }; this.loadList() },
    openDialog (row) {
      if (row) {
        this.form = {
          id: row.id, type: this.activeType, code: row[this.codeField], name: row[this.nameField],
          amount: row.subsidy_amount, year: row.effective_year, status: row.status, remark: row.remark || ''
        }
      } else {
        this.form = { id: 0, type: this.activeType, code: '', name: '', amount: 0, year: new Date().getFullYear(), status: 1, remark: '' }
      }
      this.dialogVisible = true
    },
    async handleSave () {
      if (!this.form.code.trim()) { this.$message.warning('请填写编码'); return }
      if (!this.form.name.trim()) { this.$message.warning('请填写名称'); return }
      this.saving = true
      try {
        const data = {
          type: this.form.type, code: this.form.code, name: this.form.name,
          amount: this.form.amount, year: this.form.year, status: this.form.status, remark: this.form.remark
        }
        const r = this.form.id ? await updateSubsidy(this.form.id, data) : await createSubsidy(data)
        if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadList() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    },
    handleDelete (row) {
      const name = row[this.nameField]
      this.$confirm(`确认删除补助标准「${name}」吗？删除后不可恢复！`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteSubsidy(row.id, this.activeType)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-head { margin-bottom: 12px; }
.page-title { font-size: 20px; font-weight: 600; color: #0b1e33; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; }
.danger { color: #F56C6C; }
</style>
