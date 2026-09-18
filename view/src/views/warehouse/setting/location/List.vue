<!--
  文件：admin/src/views/warehouse/setting/location/List.vue
  功能：货位管理（列表/新增/编辑/删除/编码唯一校验/仓库联动）
  权限：warehouse:setting:location:view/add/edit/delete
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>货位管理</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="货位名称"><el-input v-model="query.location_name" placeholder="请输入货位名称" clearable style="width:200px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="货位编码"><el-input v-model="query.location_code" placeholder="请输入货位编码" clearable style="width:200px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="所属仓库">
          <el-select v-model="query.warehouse_id" clearable filterable placeholder="请选择仓库" style="width:180px" @keyup.enter.native="handleSearch">
            <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="货位类型">
          <el-select v-model="query.location_type" clearable placeholder="全部" style="width:130px" @keyup.enter.native="handleSearch">
            <el-option v-for="(t, v) in LOCATION_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="占用状态">
          <el-select v-model="query.occupancy_status" clearable placeholder="全部" style="width:120px" @keyup.enter.native="handleSearch">
            <el-option v-for="(t, v) in OCCUPANCY_TYPES" :key="v" :label="t" :value="Number(v)" />
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
        <el-button v-permission="'warehouse:setting:location:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增货位</el-button>
        <el-button v-permission="'warehouse:setting:location:batch:add'" size="small" icon="el-icon-plus" @click="openBatch">批量创建货位</el-button>
        <el-button size="small" icon="el-icon-setting" @click="$router.push('/settings/code-rule/location')">编码规则</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 个</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="location_code" label="货位编码" width="150" />
      <el-table-column prop="location_name" label="货位名称" width="150" show-overflow-tooltip />
      <el-table-column label="所属仓库" width="140">
        <template slot-scope="s">
          {{ s.row.warehouse_name || '-' }}
          <el-tag v-if="s.row.warehouse_disabled" type="info" size="mini">已停用</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="货位类型" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.location_type_tag" effect="plain" size="mini">{{ s.row.location_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="area" label="区域" width="100" />
      <el-table-column label="承载能力(kg)" width="110">
        <template slot-scope="s">{{ s.row.capacity !== null && s.row.capacity !== '' ? Number(s.row.capacity).toLocaleString() + ' kg' : '-' }}</template>
      </el-table-column>
      <el-table-column label="占用状态" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.occupancy_status_tag" size="mini">{{ s.row.occupancy_status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="230" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'warehouse:setting:location:edit'" type="text" size="mini" @click="handleEdit(s.row)">编辑</el-button>
          <el-button v-permission="'warehouse:setting:location:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-button v-permission="'warehouse:setting:location:qrcode:generate'" type="text" size="mini" @click="showQrcode(s.row)">二维码</el-button>
          <el-button type="text" size="mini" @click="handleViewMaterial">查看物料</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="formData.id ? '编辑货位' : '新增货位'" :visible="dialogVisible"
      @update:visible="v => dialogVisible = v" width="600px" top="6vh"
      :close-on-click-modal="false" :close-on-press-escape="false">
      <el-form ref="form" :model="formData" :rules="rules" label-width="100px" size="small">
        <el-form-item label="所属仓库" prop="warehouse_id">
          <el-select v-model="formData.warehouse_id" :disabled="!!formData.id || !!formData.lockedWarehouse" filterable placeholder="请选择仓库" style="width:100%" @change="onWarehouseChange">
            <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="货位编码" prop="location_code">
          <el-input v-model="formData.location_code" disabled placeholder="自动生成，选择仓库后重新生成" />
        </el-form-item>
        <el-form-item label="货位名称" prop="location_name"><el-input v-model="formData.location_name" placeholder="请输入货位名称" /></el-form-item>
        <el-form-item label="货位类型" prop="location_type">
          <el-select v-model="formData.location_type" placeholder="请选择货位类型" style="width:100%">
            <el-option v-for="(t, v) in LOCATION_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="区域"><el-input v-model="formData.area" placeholder="请输入区域，如 A区" /></el-form-item>
        <el-form-item label="承载能力(kg)">
          <el-input-number v-model="formData.capacity" :min="0" :step="100" style="width:200px" /> <span style="color:#909399">kg</span>
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="formData.remark" type="textarea" :rows="3" placeholder="请输入备注信息" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" :disabled="codeExists" @click="handleSave">保存</el-button>
      </span>
    </el-dialog>

    <!-- 批量创建货位对话框 -->
    <el-dialog title="批量创建货位" :visible="batchVisible" @update:visible="v => batchVisible = v" width="760px" top="5vh"
      :close-on-click-modal="false" :close-on-press-escape="false">
      <el-form :model="batchForm" label-width="110px" size="small">
        <el-row :gutter="12">
          <el-col :span="12"><el-form-item label="所属仓库" required>
            <el-select v-model="batchForm.warehouse_id" filterable style="width:100%"><el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" /></el-select>
          </el-form-item></el-col>
          <el-col :span="12"><el-form-item label="货位前缀编码" required><el-input v-model="batchForm.prefix" placeholder="如 WH001-A-" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="货位名称前缀" required><el-input v-model="batchForm.name_prefix" placeholder="如 A区货架" /></el-form-item></el-col>
          <el-col :span="6"><el-form-item label="起始序号" required><el-input-number v-model="batchForm.start_seq" :min="1" style="width:100%" /></el-form-item></el-col>
          <el-col :span="6"><el-form-item label="结束序号" required><el-input-number v-model="batchForm.end_seq" :min="1" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="序号位数" required>
            <el-select v-model="batchForm.seq_digits" style="width:100%"><el-option label="2位" :value="2" /><el-option label="3位" :value="3" /><el-option label="4位" :value="4" /></el-select>
          </el-form-item></el-col>
          <el-col :span="12"><el-form-item label="货位类型" required>
            <el-select v-model="batchForm.location_type" style="width:100%"><el-option v-for="(t, v) in LOCATION_TYPES" :key="v" :label="t" :value="Number(v)" /></el-select>
          </el-form-item></el-col>
          <el-col :span="6"><el-form-item label="区域"><el-input v-model="batchForm.area" placeholder="如 A区" /></el-form-item></el-col>
          <el-col :span="6"><el-form-item label="承载能力(kg)"><el-input-number v-model="batchForm.capacity" :min="0" :step="100" style="width:100%" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <div class="batch-actions">
        <el-button size="small" type="primary" plain @click="buildPreview">预览清单</el-button>
        <span v-if="batchPreview.length" class="batch-count">将创建 {{ batchPreview.length }} 个货位</span>
      </div>
      <el-table v-if="batchPreview.length" :data="batchPreview" size="mini" border max-height="220">
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="code" label="货位编码" width="200" />
        <el-table-column prop="name" label="货位名称" />
        <el-table-column label="货位类型" width="100"><template slot-scope="s">{{ LOCATION_TYPES[batchForm.location_type] }}</template></el-table-column>
        <el-table-column prop="area" label="区域" width="100" />
      </el-table>
      <div v-if="batchResult" class="batch-result">
        <el-alert :type="batchResult.fail > 0 ? 'warning' : 'success'" :closable="false" show-icon :title="'创建完成：成功 ' + batchResult.success + ' 个，失败 ' + batchResult.fail + ' 个'" />
        <el-table v-if="batchResult.errors && batchResult.errors.length" :data="batchResult.errors" size="mini" border class="batch-errors">
          <el-table-column prop="code" label="货位编码" width="200" /><el-table-column prop="reason" label="失败原因" />
        </el-table>
      </div>
      <span slot="footer">
        <el-button size="small" @click="batchVisible = false">关闭</el-button>
        <el-button size="small" type="primary" :loading="batchSaving" @click="handleBatchAdd">确认创建</el-button>
      </span>
    </el-dialog>

    <!-- 二维码弹窗 -->
    <el-dialog title="货位二维码" :visible="qrcodeVisible" @update:visible="v => qrcodeVisible = v" width="420px" top="8vh">
      <div v-loading="qrcodeLoading" class="qrcode-box">
        <template v-if="qrcodeUrl">
          <img :src="qrcodeUrl" class="qrcode-img" alt="货位二维码" />
          <div class="qrcode-info">
            <div>{{ qrcodeLoc ? qrcodeLoc.location_code + ' ' + qrcodeLoc.location_name : '' }}</div>
            <div style="color:#909399;font-size:12px">扫码可查看货位信息</div>
          </div>
        </template>
      </div>
      <span slot="footer">
        <el-button size="small" @click="qrcodeVisible = false">关闭</el-button>
        <el-button size="small" type="primary" :disabled="!qrcodeUrl" @click="downloadQrcode">下载 PNG</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getLocationList, saveLocation, deleteLocation, checkLocationCode, getWarehouseList, batchAddLocation, getLocationQrcode, getNextLocationCode } from '../../../../api/warehouse'

const LOCATION_TYPES = { 1: '普通货位', 2: '货架', 3: '堆场', 4: '托盘位' }
const OCCUPANCY_TYPES = { 0: '空闲', 1: '部分占用', 2: '已满' }

export default {
  name: 'WarehouseSettingLocationList',
  data () {
    return {
      LOCATION_TYPES, OCCUPANCY_TYPES,
      list: [], total: 0, page: 1, pageSize: 10, loading: false,
      warehouseOptions: [],
      query: { location_name: '', location_code: '', warehouse_id: '', location_type: '', occupancy_status: '' },
      dialogVisible: false, saving: false, codeExists: false,
      batchVisible: false, batchSaving: false, batchPreview: [], batchResult: null,
      qrcodeVisible: false, qrcodeLoading: false, qrcodeUrl: '', qrcodeLoc: null,
      batchForm: { warehouse_id: null, prefix: '', name_prefix: '', start_seq: 1, end_seq: 20, seq_digits: 2, location_type: 1, area: '', capacity: 0 },
      formData: { id: 0, warehouse_id: null, location_code: '', location_name: '', location_type: 1, area: '', capacity: 0, remark: '', lockedWarehouse: false },
      rules: {
        warehouse_id: [{ required: true, message: '请选择所属仓库', trigger: 'change' }],
        location_code: [{ required: true, message: '请输入货位编码', trigger: 'blur' }],
        location_name: [{ required: true, message: '请输入货位名称', trigger: 'blur' }],
        location_type: [{ required: true, message: '请选择货位类型', trigger: 'change' }]
      }
    }
  },
  created () {
    this.loadWarehouses()
    const wid = this.$route.query.warehouse_id
    if (wid) { this.query.warehouse_id = Number(wid); this.searchFromWarehouse = true }
    this.getList()
  },
  methods: {
    async loadWarehouses () {
      try {
        const r = await getWarehouseList({ page: 1, pageSize: 100, status: 1 })
        this.warehouseOptions = (r.code === 0 && r.data) ? (r.data.list || []) : []
      } catch (e) { this.warehouseOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.query).forEach(k => { if (this.query[k] !== '' && this.query[k] !== null) p[k] = this.query[k] })
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getLocationList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { location_name: '', location_code: '', warehouse_id: '', location_type: '', occupancy_status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    handleAdd () {
      const wid = this.query.warehouse_id ? Number(this.query.warehouse_id) : null
      this.formData = { id: 0, warehouse_id: wid, location_code: '', location_name: '', location_type: 1, area: '', capacity: 0, remark: '', lockedWarehouse: !!wid }
      this.codeExists = false
      this.dialogVisible = true
      this.$nextTick(() => {
        if (this.$refs.form) this.$refs.form.clearValidate()
        this.generateCode(wid)
      })
    },
    onWarehouseChange (wid) {
      if (!this.formData.id) this.generateCode(wid)
    },
    async generateCode (warehouseId) {
      if (this.formData.id) return
      try {
        const r = await getNextLocationCode(warehouseId || 0)
        if (r.code === 0 && r.data) this.formData.location_code = r.data.code
      } catch (e) {}
    },
    handleEdit (row) {
      this.formData = { ...row, lockedWarehouse: true }
      this.codeExists = false
      this.dialogVisible = true
      this.$nextTick(() => { if (this.$refs.form) this.$refs.form.clearValidate() })
    },
    async validateCode () {
      if (this.formData.id) return
      const wid = this.formData.warehouse_id
      const code = (this.formData.location_code || '').trim()
      if (!wid || !code) { this.codeExists = false; return }
      try {
        const r = await checkLocationCode(wid, code, 0)
        this.codeExists = !!(r.code === 0 && r.data && r.data.exists)
        if (this.codeExists) this.$message.error('该货位编码已存在，请重新输入')
      } catch (e) { this.codeExists = false }
    },
    handleSave () {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.saving = true
        try {
          const r = await saveLocation(this.formData)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
        } catch (e) {} finally { this.saving = false }
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该货位吗？删除后不可恢复', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteLocation(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleViewMaterial () { this.$message.info('物料管理功能开发中，敬请期待') },
    openBatch () {
      this.batchVisible = true
      this.batchForm = { warehouse_id: this.query.warehouse_id || null, prefix: '', name_prefix: '', start_seq: 1, end_seq: 20, seq_digits: 2, location_type: 1, area: '', capacity: 0 }
      this.batchPreview = []
      this.batchResult = null
    },
    buildPreview () {
      const f = this.batchForm
      if (!f.prefix.trim() || !f.name_prefix.trim()) { this.$message.warning('请填写前缀'); return }
      if (f.start_seq > f.end_seq || f.end_seq - f.start_seq > 500) { this.$message.warning('序号范围无效（单次最多 500 个）'); return }
      const list = []
      for (let i = f.start_seq; i <= f.end_seq; i++) {
        list.push({ code: f.prefix + String(i).padStart(f.seq_digits, '0'), name: f.name_prefix + i, area: f.area || '' })
      }
      this.batchPreview = list
      this.batchResult = null
    },
    async handleBatchAdd () {
      const f = this.batchForm
      if (!f.warehouse_id) { this.$message.warning('请选择所属仓库'); return }
      if (!f.prefix.trim() || !f.name_prefix.trim()) { this.$message.warning('请填写前缀'); return }
      this.batchSaving = true
      try {
        const r = await batchAddLocation(f)
        if (r.code === 0 && r.data) { this.batchResult = r.data; this.$message.success('批量创建完成'); this.getList() } else this.$message.error(r.msg || '创建失败')
      } catch (e) {} finally { this.batchSaving = false }
    },
    async showQrcode (row) {
      this.qrcodeVisible = true
      this.qrcodeLoading = true
      this.qrcodeUrl = ''
      this.qrcodeLoc = row
      try {
        const r = await getLocationQrcode(row.id)
        if (r.code === 0 && r.data) this.qrcodeUrl = r.data.qrcode_url
        else this.$message.error(r.msg || '二维码生成失败')
      } catch (e) {} finally { this.qrcodeLoading = false }
    },
    downloadQrcode () {
      if (!this.qrcodeUrl) return
      const a = document.createElement('a')
      a.href = this.qrcodeUrl
      a.download = (this.qrcodeLoc ? this.qrcodeLoc.location_code : 'location') + '_qrcode.png'
      a.click()
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
.batch-actions { margin: 10px 0; display: flex; align-items: center; gap: 12px; }
.batch-count { color: #909399; font-size: 13px; }
.batch-result { margin-top: 10px; }
.batch-errors { margin-top: 8px; }
.qrcode-box { display: flex; flex-direction: column; align-items: center; padding: 12px 0; min-height: 120px; }
.qrcode-img { width: 240px; height: 240px; }
.qrcode-info { margin-top: 10px; font-size: 14px; color: #303133; }
</style>
