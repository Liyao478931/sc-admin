<!--
  文件：admin/src/views/hr/salary/payroll/Config.vue
  功能：工资配置（基本工资/工分单价/津贴/扣款，按全局/岗位/职级/部门维度）
  权限：hr:salary:payroll:config:view/add/edit/delete
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
      <el-breadcrumb-item>工资核算</el-breadcrumb-item>
      <el-breadcrumb-item>工资配置</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="配置名称"><el-input v-model="query.config_name" placeholder="请输入配置名称" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="配置类型">
          <el-select v-model="query.config_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="(t, v) in CONFIG_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="维度类型">
          <el-select v-model="query.dimension_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="(t, v) in DIMENSIONS" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'hr:salary:payroll:config:add'" type="primary" size="small" icon="el-icon-plus" @click="openDialog()">新增配置</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
        <el-button size="small" icon="el-icon-back" @click="$router.push({ path: '/hr/salary/calculate/payroll' })">返回工资计算</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无工资配置">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="config_name" label="配置名称" width="180" show-overflow-tooltip />
      <el-table-column label="配置类型" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.config_type_tag" size="mini">{{ s.row.config_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="dimension_label" label="维度" width="120" />
      <el-table-column label="值" width="120" align="right"><template slot-scope="s">{{ Number(s.row.value).toFixed(2) }} {{ s.row.unit }}</template></el-table-column>
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.is_active === 1 ? 'success' : 'info'" size="mini">{{ s.row.is_active === 1 ? '启用' : '停用' }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="sort" label="排序" width="70" align="center" />
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'hr:salary:payroll:config:edit'" type="text" size="mini" @click="openDialog(s.row)">编辑</el-button>
          <el-button v-permission="'hr:salary:payroll:config:edit'" type="text" size="mini" @click="handleToggle(s.row)">{{ s.row.is_active === 1 ? '停用' : '启用' }}</el-button>
          <el-button v-permission="'hr:salary:payroll:config:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 新增/编辑配置对话框 -->
    <el-dialog :title="formData.id ? '编辑工资配置' : '新增工资配置'" :visible.sync="dialogVisible" width="650px" :close-on-click-modal="false">
      <el-form :model="formData" label-width="110px" size="small">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="配置类型" required>
              <el-select v-model="formData.config_type" style="width:100%">
                <el-option v-for="(t, v) in CONFIG_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="配置名称" required><el-input v-model="formData.config_name" placeholder="如：高级技师基本工资" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="配置键" required><el-input v-model="formData.config_key" placeholder="如：base_salary_master" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="维度类型" required>
              <el-select v-model="formData.dimension_type" style="width:100%" @change="formData.dimension_value = ''">
                <el-option v-for="(t, v) in DIMENSIONS" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col v-if="formData.dimension_type === 2" :span="12">
            <el-form-item label="岗位" required>
              <el-input v-model="formData.dimension_value" placeholder="岗位名称或ID" />
            </el-form-item>
          </el-col>
          <el-col v-if="formData.dimension_type === 3" :span="12">
            <el-form-item label="职级" required>
              <el-select v-model="formData.dimension_value" filterable style="width:100%">
                <el-option v-for="r in rankOptions" :key="r.id" :label="r.rank_name" :value="String(r.id)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col v-if="formData.dimension_type === 4" :span="12">
            <el-form-item label="部门" required>
              <el-select v-model="formData.dimension_value" filterable style="width:100%">
                <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="String(d.id)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="值类型">
              <el-select v-model="formData.value_type" style="width:100%">
                <el-option label="固定金额" :value="1" /><el-option label="百分比" :value="2" /><el-option label="公式" :value="3" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="配置值" required><el-input-number v-model="formData.value" :min="0" :precision="4" style="width:100%" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="单位"><el-input v-model="formData.unit" placeholder="元/分/%" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="排序"><el-input-number v-model="formData.sort" :min="0" style="width:100%" /></el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="状态">
              <el-switch v-model="formData.is_active" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注"><el-input v-model="formData.remark" type="textarea" :rows="2" /></el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getSalaryConfigList, saveSalaryConfig, deleteSalaryConfig, toggleSalaryConfig } from '@/api/salaryPayroll'
import { getDepartmentOptions } from '@/api/attendanceStatistics'
import request from '@/api/request'

const CONFIG_TYPES = { 1: '基本工资', 2: '工分单价', 3: '津贴', 4: '扣款', 5: '其他' }
const DIMENSIONS = { 1: '全局', 2: '按岗位', 3: '按职级', 4: '按部门' }

export default {
  name: 'HrSalaryConfig',
  data () {
    return {
      CONFIG_TYPES, DIMENSIONS,
      list: [], total: 0, loading: false, saving: false,
      query: { config_name: '', config_type: '', dimension_type: '' },
      dialogVisible: false, formData: this.emptyForm(),
      rankOptions: [], deptOptions: []
    }
  },
  created () {
    this.loadData()
    this.loadRanks()
    this.loadDepts()
  },
  methods: {
    emptyForm () {
      return { id: 0, config_type: 1, config_name: '', config_key: '', dimension_type: 1, dimension_value: '', value_type: 1, value: 0, unit: '元', sort: 0, is_active: 1, remark: '' }
    },
    async loadRanks () {
      try {
        const r = await request({ url: '/hr/rank/list', method: 'get' })
        if (r.code === 0 && r.data) this.rankOptions = r.data.list || r.data
      } catch (e) { this.rankOptions = [] }
    },
    async loadDepts () {
      try {
        const r = await getDepartmentOptions()
        const out = []; const walk = (nodes) => { (nodes || []).forEach(n => { out.push({ id: n.id, name: n.name }); walk(n.children) }) }
        walk(r.data); this.deptOptions = out
      } catch (e) { this.deptOptions = [] }
    },
    buildParams () {
      const p = {}
      if (this.query.config_name) p.config_name = this.query.config_name
      if (this.query.config_type !== '' && this.query.config_type !== null) p.config_type = this.query.config_type
      if (this.query.dimension_type !== '' && this.query.dimension_type !== null) p.dimension_type = this.query.dimension_type
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getSalaryConfigList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.loadData() },
    handleReset () { this.query = { config_name: '', config_type: '', dimension_type: '' }; this.handleSearch() },
    openDialog (row) {
      this.formData = row ? { ...row } : this.emptyForm()
      this.dialogVisible = true
    },
    async handleSave () {
      if (!this.formData.config_name.trim()) { this.$message.warning('请填写配置名称'); return }
      if (!this.formData.config_key.trim()) { this.$message.warning('请填写配置键'); return }
      this.saving = true
      try {
        const r = await saveSalaryConfig(this.formData)
        if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadData() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    },
    handleToggle (row) {
      this.$confirm(`确认${row.is_active === 1 ? '停用' : '启用'}配置「${row.config_name}」吗？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await toggleSalaryConfig(row.id)
          if (r.code === 0) { this.$message.success('操作成功'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleDelete (row) {
      this.$confirm(`确认删除配置「${row.config_name}」吗？删除后不可恢复`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteSalaryConfig(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadData() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.danger { color: #F56C6C; }
</style>
