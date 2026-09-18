<!--
  文件：admin/src/views/hr/salary/standard/Index.vue
  功能：薪酬标准表（人事管理 -> 薪酬管理 -> 薪酬标准表）
  权限：salary:standard:view/create/edit/delete/import/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬标准表</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-head">
      <span class="page-title">薪酬标准表</span>
    </div>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'salary:standard:create'" type="primary" size="small" icon="el-icon-plus" @click="openDialog()">新增标准</el-button>
        <el-button v-permission="'salary:standard:import'" size="small" icon="el-icon-upload2" @click="importVisible = true">导入</el-button>
        <el-button v-permission="'salary:standard:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 个岗位</span>
    </div>

    <!-- 筛选区 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="70px" @submit.native.prevent>
        <el-form-item label="生效年份">
          <el-select v-model="query.year" clearable placeholder="全部年份" style="width:120px">
            <el-option v-for="y in years" :key="y" :label="y + '年'" :value="y" />
          </el-select>
        </el-form-item>
        <el-form-item label="岗位名称">
          <el-input v-model="query.keyword" placeholder="请输入岗位名称" clearable style="width:170px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="岗位类别">
          <el-select v-model="query.category" clearable placeholder="全部" style="width:100px">
            <el-option label="A" value="A" /><el-option label="B" value="B" />
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
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无薪酬标准数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="岗位编码" width="110">
        <template slot-scope="s"><el-tag size="mini" type="info">{{ s.row.position_code }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="position_name" label="岗位名称" min-width="130" show-overflow-tooltip />
      <el-table-column label="类别" width="80" align="center">
        <template slot-scope="s"><el-tag v-if="s.row.category" size="mini" :type="s.row.category === 'A' ? 'primary' : 'warning'">{{ s.row.category }}</el-tag><span v-else>-</span></template>
      </el-table-column>
      <el-table-column label="基本工资（元/月）" width="130" align="right"><template slot-scope="s">{{ fmtMoney(s.row.basic_wage) }}</template></el-table-column>
      <el-table-column label="岗位工资（元/月）" width="130" align="right"><template slot-scope="s">{{ fmtMoney(s.row.position_wage) }}</template></el-table-column>
      <el-table-column label="日常考核（元/月）" width="130" align="right"><template slot-scope="s">{{ fmtMoney(s.row.daily_assessment) }}</template></el-table-column>
      <el-table-column label="工分（分/元）" width="110" align="right"><template slot-scope="s">{{ fmtMoney(s.row.score_price) }}</template></el-table-column>
      <el-table-column label="生效年份" width="100" align="center"><template slot-scope="s">{{ s.row.effective_year }}年</template></el-table-column>
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status === 1 ? 'success' : 'info'" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="170" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'salary:standard:edit'" type="text" size="mini" @click="openDialog(s.row)">编辑</el-button>
          <el-button v-permission="'salary:standard:edit'" type="text" size="mini" @click="handleToggle(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
          <el-button v-permission="'salary:standard:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total,sizes,prev,pager,next,jumper" :total="total"
      :current-page="page" :page-size="limit" :page-sizes="[10,20,50,100]"
      @size-change="s => { limit = s; page = 1; loadList() }"
      @current-change="p => { page = p; loadList() }" />

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑薪酬标准 - ' + form.position_name : '新增薪酬标准'" :visible.sync="dialogVisible" width="550px" :close-on-click-modal="false">
      <el-form :model="form" label-width="130px" size="small">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="岗位编码" required><el-input v-model="form.position_code" placeholder="如 B-02" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="岗位名称" required><el-input v-model="form.position_name" placeholder="如 一类科长B" /></el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="类别">
              <el-select v-model="form.category" clearable placeholder="请选择" style="width:100%">
                <el-option label="A" value="A" /><el-option label="B" value="B" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="生效年份" required><el-input-number v-model="form.effective_year" :min="2000" :max="2100" style="width:100%" /></el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="基本工资（元/月）" required><el-input-number v-model="form.basic_wage" :min="0" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="岗位工资（元/月）" required><el-input-number v-model="form.position_wage" :min="0" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="日常考核（元/月）" required><el-input-number v-model="form.daily_assessment" :min="0" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="工分（分/元）"><el-input-number v-model="form.score_price" :min="0" :precision="2" style="width:100%" /></el-form-item>
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

    <!-- 导入弹窗 -->
    <el-dialog title="导入薪酬标准" :visible.sync="importVisible" width="450px" :close-on-click-modal="false">
      <div class="import-box">
        <el-upload drag action="#" :auto-upload="false" :on-change="onFileChange" :limit="1" accept=".xlsx,.xls">
          <i class="el-icon-upload"></i>
          <div class="el-upload__text">将 Excel 文件拖到此处，或<em>点击上传</em></div>
        </el-upload>
        <el-radio-group v-model="conflictStrategy" style="margin-top:14px;">
          <el-radio label="skip">跳过重复</el-radio>
          <el-radio label="overwrite">覆盖已有</el-radio>
        </el-radio-group>
        <div class="import-tip">导入模板字段：岗位编码、岗位名称、类别、基本工资（元/月）、岗位工资（元/月）、日常考核（元/月）、生效年份</div>
      </div>
      <div slot="footer">
        <el-button size="small" @click="importVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="importing" @click="doImport">确认导入</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  getSalaryStandardList, createSalaryStandard, updateSalaryStandard,
  toggleSalaryStandard, deleteSalaryStandard, exportSalaryStandard
} from '@/api/salaryStandard'
import request from '@/api/request'

export default {
  name: 'HrSalaryStandard',
  data () {
    return {
      list: [], total: 0, page: 1, limit: 20, loading: false, years: [],
      query: { year: '', keyword: '', category: '', status: '' },
      dialogVisible: false, saving: false, form: this.emptyForm(),
      importVisible: false, importing: false, fileList: [], conflictStrategy: 'skip', exporting: false
    }
  },
  created () { this.loadList() },
  methods: {
    emptyForm () {
      return { id: 0, position_code: '', position_name: '', category: '', basic_wage: 0, position_wage: 0, daily_assessment: 0, score_price: 0, effective_year: new Date().getFullYear(), status: 1, remark: '' }
    },
    fmtMoney (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.year !== '' && this.query.year !== null) p.year = this.query.year
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.query.category) p.category = this.query.category
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      return p
    },
    async loadList () {
      this.loading = true
      try {
        const r = await getSalaryStandardList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          if (r.data.years) this.years = r.data.years
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadList() },
    handleReset () { this.query = { year: '', keyword: '', category: '', status: '' }; this.handleSearch() },
    openDialog (row) {
      this.form = row ? { ...row } : this.emptyForm()
      this.dialogVisible = true
    },
    async handleSave () {
      if (!this.form.position_code.trim()) { this.$message.warning('请填写岗位编码'); return }
      if (!this.form.position_name.trim()) { this.$message.warning('请填写岗位名称'); return }
      if (!this.form.effective_year) { this.$message.warning('请填写生效年份'); return }
      this.saving = true
      try {
        const r = this.form.id ? await updateSalaryStandard(this.form.id, this.form) : await createSalaryStandard(this.form)
        if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadList() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    },
    handleToggle (row) {
      this.$confirm(`确认${row.status === 1 ? '停用' : '启用'}「${row.position_name}」吗？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await toggleSalaryStandard(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.loadList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleDelete (row) {
      this.$confirm(`确认删除薪酬标准「${row.position_name}」吗？删除后不可恢复！`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteSalaryStandard(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    onFileChange (file) { this.fileList = [file.raw] },
    async doImport () {
      if (!this.fileList.length) { this.$message.warning('请选择 Excel 文件'); return }
      this.importing = true
      try {
        const fd = new FormData()
        fd.append('file', this.fileList[0])
        fd.append('conflict_strategy', this.conflictStrategy)
        const r = await request({ url: '/salary/standard/import', method: 'post', data: fd })
        if (r.code === 0) { this.$message.success(r.msg || '导入成功'); this.importVisible = false; this.fileList = []; this.loadList() } else this.$message.error(r.msg || '导入失败')
      } catch (e) { this.$message.error('导入失败') } finally { this.importing = false }
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = {}
        if (this.query.year !== '' && this.query.year !== null) params.year = this.query.year
        if (this.query.keyword) params.keyword = this.query.keyword
        if (this.query.category) params.category = this.query.category
        if (this.query.status !== '' && this.query.status !== null) params.status = this.query.status
        const r = await exportSalaryStandard(params)
        const blob = new Blob([r.data], { type: 'text/csv;charset=utf-8' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `薪酬标准表_${new Date().toISOString().slice(0, 10)}.csv`
        a.click()
        URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
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
.pager { margin-top: 16px; text-align: right; }
.danger { color: #F56C6C; }
.import-box { text-align: center; }
.import-tip { font-size: 12px; color: #909399; margin-top: 12px; line-height: 1.7; text-align: left; }
</style>
