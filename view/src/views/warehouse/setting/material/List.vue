<!--
  文件：admin/src/views/warehouse/setting/material/List.vue
  功能：物料管理（列表/新增/编辑/删除/导出/分类级联/货位级联/图片上传）
  权限：warehouse:setting:material:view/add/edit/delete/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>物料管理</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="物料名称"><el-input v-model="query.material_name" placeholder="请输入物料名称" clearable style="width:200px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物料编码"><el-input v-model="query.material_code" placeholder="请输入物料编码" clearable style="width:180px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物料分类">
          <el-cascader v-model="query.category_path" :options="categoryTree" placeholder="请选择分类" clearable style="width:180px" @change="onCategoryQueryChange" />
        </el-form-item>
        <el-form-item label="物料类型">
          <el-select v-model="query.material_type" clearable placeholder="全部" style="width:120px" @keyup.enter.native="handleSearch">
            <el-option v-for="(t, v) in MATERIAL_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px" @keyup.enter.native="handleSearch">
            <el-option label="启用" :value="1" /><el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="存放仓库">
          <el-select v-model="query.warehouse_id" clearable filterable placeholder="请选择仓库" style="width:160px" @keyup.enter.native="handleSearch">
            <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'warehouse:setting:material:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增物料</el-button>
        <el-button v-permission="'warehouse:setting:material:import'" size="small" icon="el-icon-upload2" @click="handleOpenImport">导入物料</el-button>
        <el-button v-permission="'warehouse:setting:material:add'" size="small" icon="el-icon-refresh" :loading="syncing" @click="handleSyncProducts">同步产品</el-button>
        <el-button v-permission="'warehouse:setting:material:edit'" size="small" icon="el-icon-sort" :loading="rebuilding" @click="handleRebuildCodes">重建编码</el-button>
        <el-dropdown :disabled="!selectedIds.length" @command="handleBatchCommand">
          <el-button size="small" :disabled="!selectedIds.length">批量操作<i class="el-icon-arrow-down el-icon--right"></i></el-button>
          <el-dropdown-menu slot="dropdown">
            <el-dropdown-item v-permission="'warehouse:setting:material:batch:enable'" command="enable">批量启用</el-dropdown-item>
            <el-dropdown-item v-permission="'warehouse:setting:material:batch:disable'" command="disable">批量停用</el-dropdown-item>
            <el-dropdown-item v-permission="'warehouse:setting:material:batch:category'" command="category">批量修改分类</el-dropdown-item>
            <el-dropdown-item v-permission="'warehouse:setting:material:batch:delete'" command="delete" divided>批量删除</el-dropdown-item>
          </el-dropdown-menu>
        </el-dropdown>
        <el-button size="small" icon="el-icon-full-screen" :disabled="!selectedIds.length" @click="openBatch('generate')">批量生成二维码</el-button>
        <el-button size="small" icon="el-icon-printer" :disabled="!selectedIds.length" @click="openBatch('print')">打印标签</el-button>
        <el-button size="small" icon="el-icon-setting" @click="$router.push('/settings/code-rule/material')">编码规则</el-button>
        <el-button v-permission="'warehouse:setting:material:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 个</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无数据" @selection-change="onSelectionChange">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="material_code" label="物料编码" width="130" />
      <el-table-column prop="material_name" label="物料名称" min-width="150" show-overflow-tooltip />
      <el-table-column label="规格型号" width="140" show-overflow-tooltip><template slot-scope="s">{{ s.row.specification || '-' }}</template></el-table-column>
      <el-table-column prop="unit" label="单位" width="80" />
      <el-table-column label="物料类型" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.material_type_tag" effect="plain" size="mini">{{ s.row.material_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="category_name" label="物料分类" width="120" show-overflow-tooltip />
      <el-table-column label="安全库存量" width="120">
        <template slot-scope="s">{{ Number(s.row.safety_stock) > 0 ? Number(s.row.safety_stock).toLocaleString() + ' ' + (s.row.unit || '') : '-' }}</template>
      </el-table-column>
      <el-table-column label="当前库存" width="120">
        <template slot-scope="s">
          <span>{{ Number(s.row.current_stock || 0).toLocaleString() + ' ' + (s.row.unit || '') }}</span>
          <span v-if="s.row.stock_warning" class="stock-warning">库存预警</span>
        </template>
      </el-table-column>
      <el-table-column label="参考采购单价" width="140" align="right"><template slot-scope="s">¥ {{ Number(s.row.reference_price || 0).toFixed(2) }}</template></el-table-column>
      <el-table-column label="参考成本单价" width="140" align="right"><template slot-scope="s">¥ {{ Number(s.row.reference_cost || 0).toFixed(2) }}</template></el-table-column>
      <el-table-column label="存放货位" width="130" show-overflow-tooltip><template slot-scope="s">{{ s.row.location_name || '-' }}</template></el-table-column>
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status === 1 ? 'success' : 'info'" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" icon="el-icon-full-screen" @click="handleOpenQrcode(s.row)">二维码</el-button>
          <el-button v-permission="'warehouse:setting:material:edit'" type="text" size="mini" @click="handleEdit(s.row)">编辑</el-button>
          <el-button v-permission="'warehouse:setting:material:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-button type="text" size="mini" @click="handleViewFlow(s.row)">库存流水</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 物料二维码弹窗 -->
    <MaterialQrcodeDialog :visible.sync="qrcodeVisible" :row="qrcodeRow" @saved="getList" />
    <!-- 物料二维码批量管理弹窗 -->
    <MaterialQrcodeBatchDialog :visible.sync="qrcodeBatchVisible" :active-tab.sync="qrcodeBatchTab" :selected="selectedRows" @saved="getList" />

    <!-- 分页 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="formData.id ? '编辑物料' : '新增物料'" :visible="dialogVisible"
      @update:visible="v => dialogVisible = v" width="800px" top="5vh"
      :close-on-click-modal="false" :close-on-press-escape="false">
      <el-form ref="form" :model="formData" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="物料编码" prop="material_code"><el-input v-model="formData.material_code" disabled placeholder="自动生成，选择分类后重新生成" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="物料名称" prop="material_name"><el-input v-model="formData.material_name" placeholder="请输入物料名称，如 O型密封圈 Φ50×3.5" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="物料分类">
              <el-cascader v-model="formData.category_path" :options="categoryTree" :props="categoryProps" clearable placeholder="请选择物料分类" style="width:100%" @change="onCategoryFormChange" />
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="规格型号"><el-input v-model="formData.specification" placeholder="请输入规格型号" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="单位" prop="unit">
              <el-select v-model="formData.unit" filterable allow-create default-first-option placeholder="请选择单位" style="width:100%">
                <el-option v-for="u in UNITS" :key="u" :label="u" :value="u" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="物料类型" prop="material_type">
              <el-select v-model="formData.material_type" placeholder="请选择物料类型" style="width:100%" @change="onMaterialTypeChange">
                <el-option v-for="(t, v) in MATERIAL_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="安全库存量"><el-input-number v-model="formData.safety_stock" :min="0" :step="1" style="width:100%" placeholder="请输入安全库存量" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="采购周期(天)"><el-input-number v-model="formData.purchase_cycle" :min="0" :step="1" style="width:100%" placeholder="请输入采购周期天数" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="参考采购单价(元)"><el-input-number v-model="formData.reference_price" :min="0" :precision="4" style="width:100%" placeholder="请输入参考采购单价" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="参考成本单价(元)"><el-input-number v-model="formData.reference_cost" :min="0" :precision="4" style="width:100%" placeholder="请输入参考成本单价" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="计价方式" prop="costing_method">
              <el-select v-model="formData.costing_method" style="width:100%" @change="onCostingChange">
                <el-option label="移动加权平均" :value="1" /><el-option label="先进先出" :value="2" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="默认供应商">
              <el-select v-model="formData.default_supplier_id" clearable filterable placeholder="请选择供应商" style="width:100%">
                <el-option v-for="s in supplierOptions" :key="s.id" :label="s.supplier_name" :value="s.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="存放货位">
              <el-cascader v-model="formData.location_path" :options="locationTree" placeholder="请选择存放货位" clearable style="width:100%" @change="onLocationChange" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="状态">
              <el-switch v-model="formData.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="物料图片">
              <ImageUpload v-model="formData.images" :limit="5" />
            </el-form-item>
          </el-col>
          <el-col :span="24"><el-form-item label="备注"><el-input v-model="formData.remark" type="textarea" :rows="3" placeholder="请输入备注信息" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" :disabled="codeExists" @click="handleSave">保存</el-button>
      </span>
    </el-dialog>

    <!-- 导入物料对话框 -->
    <el-dialog title="导入物料" :visible="importVisible" @update:visible="v => importVisible = v" width="700px" top="6vh"
      :close-on-click-modal="false" :close-on-press-escape="false">
      <el-alert type="info" :closable="false" show-icon
        title="支持导入 Excel 文件（.xlsx, .xls）；文件大小不超过 5MB；必填字段：物料编码、物料名称、单位、物料类型。导入前请先下载模板，按模板格式填写数据；导入时检测到重复编码可选择覆盖或跳过。" />
      <div class="import-row">
        <el-button size="small" icon="el-icon-download" @click="handleDownloadTemplate">下载导入模板</el-button>
      </div>
      <el-upload drag :auto-upload="false" :limit="1" accept=".xlsx,.xls"
        :on-change="onImportFileChange" :on-remove="handleImportRemove" :file-list="importFileList">
        <i class="el-icon-upload"></i>
        <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
        <div class="el-upload__tip" slot="tip">仅支持 .xlsx / .xls，大小不超过 5MB</div>
      </el-upload>
      <div class="import-row">
        <span style="margin-right:12px">重复处理策略：</span>
        <el-radio-group v-model="importStrategy">
          <el-radio label="overwrite">覆盖更新（以导入文件为准）</el-radio>
          <el-radio label="skip">跳过（保留原数据）</el-radio>
        </el-radio-group>
      </div>
      <div v-if="importResult" class="import-result">
        <el-alert :type="importResult.fail > 0 ? 'warning' : 'success'" :closable="false" show-icon
          :title="'导入完成：总行数 ' + importResult.total + '，成功 ' + importResult.success + ' 条，失败 ' + importResult.fail + ' 条'" />
        <el-table v-if="importResult.errors && importResult.errors.length" :data="importResult.errors" size="mini" border class="import-errors">
          <el-table-column prop="row" label="行号" width="70" align="center" />
          <el-table-column prop="code" label="物料编码" width="130" />
          <el-table-column prop="reason" label="错误原因" />
        </el-table>
      </div>
      <span slot="footer">
        <el-button size="small" @click="importVisible = false">关闭</el-button>
        <el-button size="small" type="primary" :loading="importing" :disabled="!importFile" @click="handleImport">开始导入</el-button>
      </span>
    </el-dialog>

    <!-- 批量修改分类对话框 -->
    <el-dialog title="批量修改分类" :visible="batchCatVisible" @update:visible="v => batchCatVisible = v" width="420px" top="8vh">
      <el-cascader v-model="batchCatPath" :options="categoryTree" :props="categoryProps" clearable placeholder="请选择目标分类" style="width:100%" @change="v => batchCatId = v && v.length ? v[v.length - 1] : 0" />
      <span slot="footer">
        <el-button size="small" @click="batchCatVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="handleBatchCategorySave">确定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getMaterialList, saveMaterial, deleteMaterial, checkMaterialCode, getMaterialCategoryTree, getLocationTree, exportMaterial, getWarehouseList, getMaterialTemplate, importMaterial, getNextMaterialCode, batchEnableMaterial, batchDisableMaterial, batchCategoryMaterial, batchDeleteMaterial, syncProductsToMaterial, rebuildMaterialCodes } from '../../../../api/warehouse'
import { getSupplierOptions } from '../../../../api/businessSupplier'
import ImageUpload from '../../../settings/components/ImageUpload.vue'
import MaterialQrcodeDialog from './components/MaterialQrcodeDialog.vue'
import MaterialQrcodeBatchDialog from './components/MaterialQrcodeBatchDialog.vue'

const MATERIAL_TYPES = { 1: '原材料', 2: '半成品', 3: '成品', 4: '备件', 5: '辅料' }
const UNITS = ['个', '件', '台', '套', '公斤', '千克', '克', '吨', '米', '厘米', '毫米', '升', '毫升', '箱', '包', '卷', '根', '条', '块', '片', '只', '支', '桶', '袋', '盒', '瓶', '罐', '组', '副', '双', '对', '打', '令', '张', '份', '册', '托', '盘', '批', '节', '把', '付', '本']

export default {
  name: 'WarehouseSettingMaterialList',
  components: { ImageUpload, MaterialQrcodeDialog, MaterialQrcodeBatchDialog },
  data () {
    return {
      MATERIAL_TYPES, UNITS,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, syncing: false, rebuilding: false,
      importVisible: false, importFile: null, importFileList: [], importStrategy: 'overwrite', importResult: null, importing: false,
      selectedIds: [], batchCatVisible: false, batchCatPath: [], batchCatId: 0,
      categoryTree: [], locationTree: [], warehouseOptions: [], supplierOptions: [],
      query: { material_name: '', material_code: '', category_path: [], category_id: 0, material_type: '', status: '', warehouse_id: '' },
      dialogVisible: false, saving: false, codeExists: false,
      qrcodeVisible: false, qrcodeRow: {},
      qrcodeBatchVisible: false, qrcodeBatchTab: 'generate', selectedRows: [],
      formData: this.emptyForm(),
      categoryProps: { value: 'value', label: 'label', children: 'children', checkStrictly: true },
      rules: {
        material_code: [{ required: true, message: '请输入物料编码', trigger: 'blur' }],
        material_name: [{ required: true, message: '请输入物料名称', trigger: 'blur' }],
        unit: [{ required: true, message: '请选择单位', trigger: 'change' }],
        material_type: [{ required: true, message: '请选择物料类型', trigger: 'change' }]
      }
    }
  },
  created () {
    this.loadBaseData()
    this.getList()
  },
  methods: {
    emptyForm () {
      return { id: 0, material_code: '', material_name: '', category_id: 0, category_path: [], specification: '', unit: '', material_type: 1, safety_stock: 0, purchase_cycle: 0, reference_price: 0, reference_cost: 0, costing_method: 1, default_supplier_id: 0, location_id: 0, location_path: [], status: 1, images: [], remark: '' }
    },
    async loadBaseData () {
      try {
        const [catR, locR, whR, supR] = await Promise.all([
          getMaterialCategoryTree(), getLocationTree(), getWarehouseList({ page: 1, pageSize: 100, status: 1 }), getSupplierOptions()
        ])
        this.categoryTree = (catR.code === 0 && catR.data) ? catR.data : []
        this.locationTree = (locR.code === 0 && locR.data) ? locR.data : []
        this.warehouseOptions = (whR.code === 0 && whR.data) ? (whR.data.list || []) : []
        this.supplierOptions = (supR.code === 0 && supR.data) ? supR.data : []
      } catch (e) {}
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.material_name) p.material_name = this.query.material_name
      if (this.query.material_code) p.material_code = this.query.material_code
      if (this.query.category_path && this.query.category_path.length) p.category_id = this.query.category_path[this.query.category_path.length - 1]
      if (this.query.material_type !== '') p.material_type = this.query.material_type
      if (this.query.status !== '') p.status = this.query.status
      if (this.query.warehouse_id) p.warehouse_id = this.query.warehouse_id
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getMaterialList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { material_name: '', material_code: '', category_path: [], category_id: 0, material_type: '', status: '', warehouse_id: '' }; this.handleSearch() },
    onCategoryQueryChange (v) { this.query.category_id = v && v.length ? v[v.length - 1] : 0 },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    handleAdd () {
      this.formData = this.emptyForm()
      this.codeExists = false
      this.dialogVisible = true
      this.$nextTick(() => {
        if (this.$refs.form) this.$refs.form.clearValidate()
        this.generateCode(0)
      })
    },
    onCategoryFormChange (v) {
      this.formData.category_id = v && v.length ? v[v.length - 1] : 0
      if (!this.formData.id) this.generateCode(this.formData.category_id)
    },
    onCostingChange () {
      if (this.formData.id) this.$message.info('修改计价方式将影响库存成本核算，请谨慎操作')
    },
    async generateCode (categoryId) {
      if (this.formData.id) return
      try {
        const r = await getNextMaterialCode(categoryId || 0, this.formData.material_type || 0)
        if (r.code === 0 && r.data) this.formData.material_code = r.data.code
      } catch (e) {}
    },
    onMaterialTypeChange () {
      // 新增时按物料类型刷新编码预览（类型首字母前缀）
      if (!this.formData.id) this.generateCode(this.formData.category_id)
    },
    handleEdit (row) {
      this.formData = { ...this.emptyForm(), ...row, category_path: row.category_id ? [row.category_id] : [], location_path: [], images: Array.isArray(row.images) ? row.images : [] }
      this.findLocationPath()
      this.codeExists = false
      this.dialogVisible = true
      this.$nextTick(() => { if (this.$refs.form) this.$refs.form.clearValidate() })
    },
    findLocationPath () {
      if (!this.formData.location_id || !this.locationTree.length) return
      for (const wh of this.locationTree) {
        if (wh.disabled) continue
        const found = (wh.children || []).find(l => l.value === this.formData.location_id)
        if (found) { this.formData.location_path = [wh.value, found.value]; return }
      }
    },
    onLocationChange (v) { this.formData.location_id = v && v.length ? v[v.length - 1] : 0 },
    async validateCode () {
      if (this.formData.id) return
      const code = (this.formData.material_code || '').trim()
      if (!code) { this.codeExists = false; return }
      try {
        const r = await checkMaterialCode(code, 0)
        this.codeExists = !!(r.code === 0 && r.data && r.data.exists)
        if (this.codeExists) this.$message.error('该物料编码已存在，请重新输入')
      } catch (e) { this.codeExists = false }
    },
    handleSave () {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.saving = true
        try {
          const r = await saveMaterial(this.formData)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
        } catch (e) {} finally { this.saving = false }
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该物料吗？删除后不可恢复', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteMaterial(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
        handleSyncProducts () {
      this.$confirm('将产品列表中的启用产品同步为物料（已存在的按编码更新，软删的自动恢复），是否继续？', '同步产品到物料', { type: 'warning' }).then(async () => {
        this.syncing = true
        try {
          const r = await syncProductsToMaterial()
          if (r.code === 0) {
            this.$message.success(`同步完成：新增 ${r.data.inserted} 条，更新 ${r.data.updated} 条`)
            this.getList()
          } else this.$message.error(r.msg || '同步失败')
        } catch (e) {} finally { this.syncing = false }
      }).catch(() => {})
    },
    handleRebuildCodes () {
      this.$confirm('将按当前编码规则重新生成物料与产品编码（产品同步物料编码随产品更新）。此操作会修改物料与产品编码，是否继续？', '重建编码', { type: 'warning' }).then(async () => {
        this.rebuilding = true
        try {
          const r = await rebuildMaterialCodes()
          if (r.code === 0) {
            this.$message.success(`重建完成：物料修改 ${r.data.material_changed} 条、产品修改 ${r.data.product_changed} 条` + (r.data.material_failed ? `，失败 ${r.data.material_failed} 条` : ''))
            this.getList()
          } else this.$message.error(r.msg || '重建失败')
        } catch (e) {} finally { this.rebuilding = false }
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const resp = await exportMaterial(this.buildParams())
        const url = window.URL.createObjectURL(new Blob([resp.data]))
        const a = document.createElement('a')
        a.href = url; a.download = '物料列表_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        a.click(); window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    },
    handleViewFlow (row) { this.$router.push({ path: '/warehouse/setting/material/detail/' + row.id }) },
    handleOpenQrcode (row) {
      this.qrcodeRow = row
      this.qrcodeVisible = true
    },
    onSelectionChange (rows) {
      this.selectedRows = rows
      this.selectedIds = rows.map(r => r.id)
    },
    openBatch (tab) {
      this.qrcodeBatchTab = tab
      this.qrcodeBatchVisible = true
    },
    handleOpenImport () {
      this.importVisible = true
      this.importFile = null
      this.importFileList = []
      this.importStrategy = 'overwrite'
      this.importResult = null
    },
    async handleDownloadTemplate () {
      try {
        const resp = await getMaterialTemplate()
        const url = window.URL.createObjectURL(new Blob([resp.data]))
        const a = document.createElement('a')
        a.href = url; a.download = '物料导入模板.xlsx'
        a.click(); window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('模板下载失败') }
    },
    onImportFileChange (file, fileList) {
      if (file.size > 5 * 1024 * 1024) {
        this.$message.error('文件大小不能超过 5MB')
        this.importFile = null
        this.importFileList = []
        return
      }
      this.importFile = file.raw
      this.importFileList = fileList.slice(-1)
      this.importResult = null
    },
    handleImportRemove () { this.importFile = null; this.importFileList = [] },
    async handleImport () {
      if (!this.importFile) { this.$message.warning('请先选择文件'); return }
      this.importing = true
      try {
        const fd = new FormData()
        fd.append('file', this.importFile)
        fd.append('duplicate_strategy', this.importStrategy)
        const r = await importMaterial(fd)
        if (r.code === 0 && r.data) {
          this.importResult = r.data
          this.$message.success('导入完成')
          this.getList()
        } else this.$message.error(r.msg || '导入失败')
      } catch (e) {} finally { this.importing = false }
    },
    handleBatchCommand (cmd) {
      const ids = this.selectedIds
      if (!ids.length) { this.$message.warning('请先选择物料'); return }
      if (cmd === 'enable') {
        this.$confirm(`将操作 ${ids.length} 个物料，确认继续吗？`, '提示').then(() => this.doBatch(batchEnableMaterial, '已启用')).catch(() => {})
      } else if (cmd === 'disable') {
        this.$confirm(`将操作 ${ids.length} 个物料，确认继续吗？`, '提示').then(() => this.doBatch(batchDisableMaterial, '已停用')).catch(() => {})
      } else if (cmd === 'category') {
        this.batchCatPath = []
        this.batchCatId = 0
        this.batchCatVisible = true
      } else if (cmd === 'delete') {
        this.$confirm(`确认删除选中的 ${ids.length} 个物料吗？删除后不可恢复`, '提示', { type: 'warning' }).then(() => this.doBatch(batchDeleteMaterial, '已删除')).catch(() => {})
      }
    },
    async doBatch (fn, successText) {
      const ids = this.selectedIds
      try {
        const r = await fn(ids)
        if (r.code === 0) {
          this.$message.success((successText || '操作') + (r.data && r.data.count ? ' ' + r.data.count + ' 个' : ''))
          this.selectedIds = []
          this.getList()
        } else this.$message.error(r.msg || '操作失败')
      } catch (e) {}
    },
    async handleBatchCategorySave () {
      if (!this.batchCatId) { this.$message.warning('请选择分类'); return }
      try {
        const r = await batchCategoryMaterial(this.selectedIds, this.batchCatId)
        if (r.code === 0) {
          this.$message.success('已修改分类')
          this.batchCatVisible = false
          this.selectedIds = []
          this.getList()
        } else this.$message.error(r.msg || '操作失败')
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 0; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.danger { color: #F56C6C; }
.stock-warning { color: #F56C6C; font-size: 12px; margin-left: 4px; }
.import-row { margin: 14px 0; }
.import-result { margin-top: 14px; }
.import-errors { margin-top: 10px; }
</style>
