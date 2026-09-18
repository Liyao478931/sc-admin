<template>
  <div class="aa2-page">
    <el-breadcrumb separator="/" class="aa2-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>固定资产管理</el-breadcrumb-item>
      <el-breadcrumb-item>资产档案</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 操作栏 -->
    <div class="aa2-toolbar">
      <el-button size="small" type="primary" icon="el-icon-plus" @click="openCreate">新增资产</el-button>
      <el-button size="small" icon="el-icon-upload2" @click="importVisible = true">导入</el-button>
      <el-button size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <span class="aa2-total">共 {{ total }} 条</span>
    </div>

    <!-- 筛选区 -->
    <div class="aa2-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="资产名称">
          <el-input v-model="query.keyword" placeholder="请输入资产名称" clearable style="width:140px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="资产编号">
          <el-input v-model="query.asset_no" placeholder="请输入资产编号" clearable style="width:130px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="资产分类">
          <el-select v-model="query.category_id" clearable placeholder="全部分类" style="width:130px" @change="handleSearch">
            <el-option v-for="c in categoryOptions" :key="c.id" :label="c.name" :value="c.id" />
          </el-select>
          <el-button type="text" size="mini" @click="categoryVisible = true">管理分类</el-button>
        </el-form-item>
        <el-form-item label="资产状态">
          <el-select v-model="query.asset_status" clearable placeholder="全部状态" style="width:110px" @change="handleSearch">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="使用部门">
          <el-select v-model="query.department_id" clearable placeholder="全部部门" style="width:130px" @change="handleSearch">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 列表 -->
    <div class="aa2-table">
      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无资产档案，点击“新增资产”创建第一条资产档案。">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="资产编号" width="140"><template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.asset_no }}</el-link></template></el-table-column>
        <el-table-column prop="asset_name" label="资产名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="category_name" label="分类" width="100" />
        <el-table-column prop="specification" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="brand" label="品牌" width="80" />
        <el-table-column prop="serial_no" label="序列号" width="110" show-overflow-tooltip />
        <el-table-column label="原值" width="110" align="right"><template slot-scope="s">¥{{ Number(s.row.total_value).toLocaleString() }}</template></el-table-column>
        <el-table-column label="购入日期" width="105" align="center"><template slot-scope="s">{{ s.row.purchase_date || '-' }}</template></el-table-column>
        <el-table-column prop="current_user" label="保管人" width="80" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag :type="statusType(s.row.asset_status)" size="mini" :class="{ 'is-scrapped': s.row.asset_status === 5 }">{{ s.row.asset_status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="170" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openEdit(s.row)">编辑</el-button>
            <el-button type="text" size="mini" @click="openDetail(s.row)">查看</el-button>
            <el-button type="text" size="mini" style="color:#F56C6C" @click="handleDelete(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="aa2-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="(form.id ? '编辑资产 - ' + form.asset_name : '新增资产')" :visible.sync="editVisible" width="750px" append-to-body>
      <el-form ref="form" :model="form" :rules="rules" label-width="90px" size="small">
        <el-divider content-position="left">基础信息</el-divider>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="资产编号" prop="asset_no">
              <el-input v-model="form.asset_no" placeholder="可自动生成或手动输入">
                <el-button v-if="!form.id" slot="append" @click="genNo">自动生成</el-button>
              </el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="资产名称" prop="asset_name"><el-input v-model="form.asset_name" placeholder="请输入资产名称" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="资产分类" prop="category_id">
              <el-select v-model="form.category_id" placeholder="请选择分类" style="width:100%">
                <el-option v-for="c in categoryOptions" :key="c.id" :label="c.name" :value="c.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="规格型号"><el-input v-model="form.specification" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="品牌"><el-input v-model="form.brand" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="序列号"><el-input v-model="form.serial_no" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="单位"><el-input v-model="form.unit" placeholder="默认台" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="数量"><el-input-number v-model="form.quantity" :min="1" :precision="0" style="width:100%" /></el-form-item></el-col>
        </el-row>
        <el-divider content-position="left">财务信息</el-divider>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="单价"><el-input-number v-model="form.unit_price" :min="0" :precision="2" style="width:100%" @change="calcTotal" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="总价值"><el-input-number v-model="form.total_value" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="购入日期"><el-date-picker v-model="form.purchase_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
        </el-row>
        <el-divider content-position="left">折旧信息</el-divider>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="折旧方法">
              <el-select v-model="form.depreciation_method" style="width:100%">
                <el-option :value="1" label="直线法" />
                <el-option :value="2" label="加速法" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="年折旧率%"><el-input-number v-model="form.depreciation_rate" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="折旧月数"><el-input-number v-model="form.depreciation_months" :min="0" :precision="0" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="残值"><el-input-number v-model="form.residual_value" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
        </el-row>
        <el-divider content-position="left">使用信息</el-divider>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="使用部门">
              <el-select v-model="form.department_id" clearable placeholder="选择部门" style="width:100%" @change="onDeptChange">
                <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="使用人">
              <el-select v-model="form.current_user_id" clearable filterable placeholder="选择员工" style="width:100%">
                <el-option v-for="e in empOptions" :key="e.user_id" :label="e.name + (e.employee_id ? '（' + e.employee_id + '）' : '')" :value="e.user_id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="资产状态">
              <el-select v-model="form.asset_status" style="width:100%">
                <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="保修到期日"><el-date-picker v-model="form.warranty_expire" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
        </el-row>
        <el-divider content-position="left">其他</el-divider>
        <el-form-item label="采购单号"><el-input v-model="form.purchase_order_no" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="editVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="submitForm">保存</el-button>
      </div>
    </el-dialog>

    <!-- 详情弹窗 -->
    <el-dialog :title="'资产详情 - ' + (detail.asset_name || '')" :visible.sync="detailVisible" width="700px">
      <div v-loading="detailLoading" class="aa2-detail-body">
        <template v-if="detail.id">
          <div class="aa2-sec">
            <div class="aa2-sec-title">基本信息</div>
            <div class="aa2-grid">
              <div class="aa2-item"><span class="aa2-lb">资产编号</span>{{ detail.asset_no }}</div>
              <div class="aa2-item"><span class="aa2-lb">资产名称</span>{{ detail.asset_name }}</div>
              <div class="aa2-item"><span class="aa2-lb">分类</span>{{ detail.category_name || '-' }}</div>
              <div class="aa2-item"><span class="aa2-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="aa2-item"><span class="aa2-lb">品牌</span>{{ detail.brand || '-' }}</div>
              <div class="aa2-item"><span class="aa2-lb">序列号</span>{{ detail.serial_no || '-' }}</div>
              <div class="aa2-item"><span class="aa2-lb">单位</span>{{ detail.unit }}</div>
              <div class="aa2-item"><span class="aa2-lb">数量</span>{{ detail.quantity }}</div>
            </div>
          </div>
          <div class="aa2-sec">
            <div class="aa2-sec-title">财务信息</div>
            <div class="aa2-grid">
              <div class="aa2-item"><span class="aa2-lb">单价</span>¥{{ Number(detail.unit_price).toLocaleString() }}</div>
              <div class="aa2-item"><span class="aa2-lb">总价值</span>¥{{ Number(detail.total_value).toLocaleString() }}</div>
              <div class="aa2-item"><span class="aa2-lb">购入日期</span>{{ detail.purchase_date || '-' }}</div>
              <div class="aa2-item"><span class="aa2-lb">采购单号</span>{{ detail.purchase_order_no || '-' }}</div>
            </div>
          </div>
          <div class="aa2-sec">
            <div class="aa2-sec-title">折旧信息</div>
            <div class="aa2-grid">
              <div class="aa2-item"><span class="aa2-lb">折旧方法</span>{{ detail.depreciation_method === 2 ? '加速法' : '直线法' }}</div>
              <div class="aa2-item"><span class="aa2-lb">年折旧率</span>{{ detail.depreciation_rate }}%</div>
              <div class="aa2-item"><span class="aa2-lb">折旧月数</span>{{ detail.depreciation_months || 0 }}</div>
              <div class="aa2-item"><span class="aa2-lb">残值</span>¥{{ Number(detail.residual_value).toLocaleString() }}</div>
            </div>
          </div>
          <div class="aa2-sec">
            <div class="aa2-sec-title">使用信息</div>
            <div class="aa2-grid">
              <div class="aa2-item"><span class="aa2-lb">资产状态</span><el-tag :type="statusType(detail.asset_status)" size="mini">{{ detail.asset_status_label }}</el-tag></div>
              <div class="aa2-item"><span class="aa2-lb">保修到期</span>{{ detail.warranty_expire || '-' }}</div>
            </div>
          </div>
          <div class="aa2-sec">
            <div class="aa2-sec-title">关联个人资产</div>
            <el-table :data="detail.personal_assets" size="small" border empty-text="暂无关联个人资产">
              <el-table-column prop="asset_name" label="资产名称" min-width="110" />
              <el-table-column prop="user_name" label="保管人" width="90" />
              <el-table-column label="数量" width="80" align="right"><template slot-scope="s">{{ s.row.quantity }} {{ s.row.unit }}</template></el-table-column>
              <el-table-column label="状态" width="80" align="center"><template slot-scope="s">{{ s.row.status === 1 ? '有效' : '已出库' }}</template></el-table-column>
            </el-table>
          </div>
        </template>
      </div>
      <div slot="footer"><el-button size="small" @click="detailVisible = false">关闭</el-button></div>
    </el-dialog>

    <!-- 分类管理弹窗 -->
    <el-dialog title="资产分类管理" :visible.sync="categoryVisible" width="500px" append-to-body>
      <div class="aa2-cat-head">
        <el-input v-model="catForm.name" placeholder="分类名称" size="small" style="width:180px" />
        <el-button size="small" type="primary" @click="saveCategory">新增</el-button>
      </div>
      <el-table :data="categoryFlat" size="small" border>
        <el-table-column prop="name" label="分类名称" min-width="150" />
        <el-table-column label="排序" width="60"><template slot-scope="s">{{ s.row.sort }}</template></el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" style="color:#F56C6C" @click="removeCategory(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- 导入弹窗 -->
    <el-dialog title="导入资产档案" :visible.sync="importVisible" width="520px" append-to-body>
      <div class="aa2-import-tip">
        <p>1. 点击下方按钮下载导入模板，按模板格式填写数据</p>
        <p>2. 分类名称、使用部门需与系统中已有的分类/部门名称一致</p>
        <p>3. 状态可选：正常 / 维修中 / 闲置 / 待报废 / 已报废</p>
        <p>4. 资产编号留空将自动生成，重复编号将跳过</p>
        <el-button size="small" icon="el-icon-download" @click="downloadTemplate">下载导入模板</el-button>
      </div>
      <el-upload :show-file-list="false" :http-request="handleImport" accept=".xlsx" :disabled="importing">
        <el-button size="small" type="primary" :loading="importing">选择Excel文件上传</el-button>
      </el-upload>
      <div v-if="importResult" class="aa2-import-result">
        <el-alert :title="importResult.msg" :type="importResult.fail > 0 ? 'warning' : 'success'" show-icon :closable="false" />
        <div v-if="importResult.errors && importResult.errors.length" class="aa2-import-errors">
          <div v-for="(e, i) in importResult.errors" :key="i" class="aa2-import-error">{{ e }}</div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getAssetArchiveList, createAssetArchive, updateAssetArchive, deleteAssetArchive, getAssetArchiveDetail, exportAssetArchive, generateAssetNo, getAssetCategoryList, createAssetCategory, deleteAssetCategory, getAssetImportTemplate, importAssetArchive } from '../../api/assetArchive'
import { getAssetDepartments, getAssetEmployeeOptions } from '../../api/personalAssets'

const STATUS_TEXT = { 1: '正常', 2: '维修中', 3: '闲置', 4: '待报废', 5: '已报废' }

export default {
  name: 'AssetArchiveList',
  data () {
    return {
      STATUS_TEXT,
      list: [], total: 0, page: 1, limit: 20, loading: false, exporting: false,
      query: { keyword: '', asset_no: '', category_id: '', asset_status: '', department_id: '' },
      categoryOptions: [], categoryFlat: [], deptOptions: [], empOptions: [],
      editVisible: false, saving: false, form: this.emptyForm(),
      detailVisible: false, detailLoading: false, detail: {},
      categoryVisible: false, catForm: { name: '' },
      importVisible: false, importing: false, importResult: null,
      rules: {
        asset_no: [{ required: true, message: '请输入或自动生成资产编号', trigger: 'blur' }],
        asset_name: [{ required: true, message: '请输入资产名称', trigger: 'blur' }],
        category_id: [{ required: true, message: '请选择资产分类', trigger: 'change' }]
      }
    }
  },
  created () {
    this.loadCategories()
    this.loadDepartments()
    this.getList()
  },
  methods: {
    emptyForm () {
      return { id: 0, asset_no: '', asset_name: '', category_id: '', specification: '', brand: '', serial_no: '', unit: '台', quantity: 1, unit_price: 0, total_value: 0, purchase_date: '', depreciation_method: 1, depreciation_rate: 0, depreciation_months: 0, residual_value: 0, department_id: '', current_user_id: '', asset_status: 1, warranty_expire: '', purchase_order_no: '', remark: '' }
    },
    statusType (s) { return { 1: 'success', 2: 'warning', 3: 'info', 4: 'danger', 5: 'info' }[s] || 'info' },
    async loadCategories () {
      try {
        const r = await getAssetCategoryList()
        if (r.code === 0) {
          this.categoryOptions = r.data.flat ? Object.values(r.data.flat).map(c => ({ id: c.id, name: c.name })) : []
          this.categoryFlat = Object.values(r.data.flat || {}).filter(c => !c.parent_id || c.parent_id === 0)
        }
      } catch (e) {}
    },
    async loadDepartments () {
      try {
        const r = await getAssetDepartments()
        if (r.code === 0) this.deptOptions = r.data || []
      } catch (e) {}
    },
    async loadEmployees (deptId) {
      this.empOptions = []
      try {
        const r = await getAssetEmployeeOptions('')
        if (r.code === 0) this.empOptions = r.data || []
      } catch (e) {}
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.query.asset_no) p.asset_no = this.query.asset_no
      if (this.query.category_id !== '' && this.query.category_id != null) p.category_id = this.query.category_id
      if (this.query.asset_status !== '' && this.query.asset_status != null) p.asset_status = this.query.asset_status
      if (this.query.department_id !== '' && this.query.department_id != null) p.department_id = this.query.department_id
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getAssetArchiveList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { keyword: '', asset_no: '', category_id: '', asset_status: '', department_id: '' }
      this.page = 1
      this.getList()
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    calcTotal () { this.form.total_value = Number((Number(this.form.unit_price || 0) * Number(this.form.quantity || 1)).toFixed(2)) },
    async genNo () {
      try { const r = await generateAssetNo(); if (r.code === 0) this.form.asset_no = r.data.asset_no } catch (e) {}
    },
    openCreate () {
      this.form = this.emptyForm()
      this.editVisible = true
      this.loadEmployees()
    },
    openEdit (row) {
      this.form = { ...this.emptyForm(), ...row }
      this.form.category_id = row.category_id || ''
      this.form.department_id = row.department_id || ''
      this.form.current_user_id = row.current_user_id || ''
      this.editVisible = true
      this.loadEmployees()
    },
    onDeptChange () { this.loadEmployees() },
    submitForm () {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.saving = true
        try {
          if (this.form.id) {
            const r = await updateAssetArchive(this.form.id, this.form)
            if (r.code === 0) { this.$message.success('资产更新成功'); this.editVisible = false; this.getList() }
          } else {
            const r = await createAssetArchive(this.form)
            if (r.code === 0) { this.$message.success('资产创建成功'); this.editVisible = false; this.getList() }
          }
        } catch (e) {}
        this.saving = false
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除资产 ' + row.asset_name + ' 吗？', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteAssetArchive(row.id)
          if (r.code === 0) { this.$message.success('资产已删除'); this.getList() }
        } catch (e) {}
      }).catch(() => {})
    },
    async openDetail (row) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getAssetArchiveDetail(row.id)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.detailLoading = false
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page
        delete p.limit
        const res = await exportAssetArchive(p)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '资产档案_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    },
    async downloadTemplate () {
      try {
        const res = await getAssetImportTemplate()
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('模板下载失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '资产档案导入模板.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('模板下载失败') }
    },
    async handleImport (options) {
      this.importResult = null
      const file = options.file
      const fd = new FormData()
      fd.append('file', file)
      this.importing = true
      try {
        const r = await importAssetArchive(fd)
        if (r.code === 0) {
          this.importResult = { msg: r.msg, fail: r.data.fail || 0, errors: r.data.errors || [] }
          this.getList()
        } else {
          this.importResult = { msg: r.msg || '导入失败', fail: 1, errors: [] }
        }
      } catch (e) {
        this.importResult = { msg: '导入失败', fail: 1, errors: [] }
      }
      this.importing = false
      options.onSuccess && options.onSuccess()
    },
    async saveCategory () {
      if (!this.catForm.name) { this.$message.warning('请输入分类名称'); return }
      try {
        const r = await createAssetCategory({ name: this.catForm.name })
        if (r.code === 0) { this.$message.success('分类创建成功'); this.catForm.name = ''; this.loadCategories() }
      } catch (e) {}
    },
    async removeCategory (row) {
      this.$confirm('确认删除分类 ' + row.name + ' 吗？', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteAssetCategory(row.id)
          if (r.code === 0) { this.$message.success('分类已删除'); this.loadCategories() }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.aa2-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.aa2-breadcrumb { margin-bottom: 12px; }
.aa2-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.aa2-total { margin-left: 12px; color: #909399; font-size: 13px; }
.aa2-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.aa2-filter .el-form-item { margin-bottom: 16px; margin-right: 16px; }
.aa2-filter .el-form-item__label { color: #606266; font-size: 13px; width: 70px; }
.aa2-table { background: #fff; border-radius: 8px; padding: 12px; }
.aa2-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }
.aa2-detail-body { min-height: 150px; }
.aa2-sec { margin-bottom: 16px; }
.aa2-sec-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.aa2-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.aa2-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.aa2-lb { color: #909399; width: 70px; flex-shrink: 0; }
.aa2-cat-head { display: flex; gap: 8px; margin-bottom: 12px; }
.aa2-import-tip { font-size: 13px; color: #606266; line-height: 1.8; margin-bottom: 16px; }
.aa2-import-tip p { margin: 0 0 4px; }
.aa2-import-result { margin-top: 16px; }
.aa2-import-errors { margin-top: 8px; max-height: 150px; overflow-y: auto; }
.aa2-import-error { font-size: 12px; color: #F56C6C; line-height: 1.6; }
</style>