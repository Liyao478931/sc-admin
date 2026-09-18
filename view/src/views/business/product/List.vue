<!--
  文件：admin/src/views/business/product/List.vue
  功能：经营管理 → 产品管理 → 产品列表
    - 搜索筛选（产品名称/编码模糊、分类级联[父级递归由后端处理]、状态、创建时间范围）
    - 工具栏（新增/导出/刷新 + 总数）
    - 表格（编码/名称点击跳详情、状态标签、编辑/删除/更多[详情|复制|管理BOM]）
    - 分页（total, sizes, prev, pager, next, jumper）
  权限：页面 business:product:list；按钮 add/edit/delete/export（v-permission 指令已在 main.js 注册）
  备注：复制产品通过 query.copyFrom 携带业务字段（排除 id/product_code/created_at/updated_at/deleted_at）
-->
<template>
  <div class="product-page">
    <!-- ===== 面包屑导航 ===== -->
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品列表</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- ===== 搜索与筛选区 ===== -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="产品名称">
          <el-input v-model="queryParams.product_name" placeholder="请输入产品名称" clearable style="width:180px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="产品编码">
          <el-input v-model="queryParams.product_code" placeholder="请输入产品编码" clearable style="width:180px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="产品分类">
          <el-cascader
            v-model="categoryId"
            :options="categoryOptions"
            :props="{ value: 'value', label: 'label', children: 'children' }"
            :disabled="categoryLoadFailed"
            :placeholder="categoryLoadFailed ? '分类加载失败，请刷新重试' : '请选择分类'"
            clearable
            filterable
            style="width:200px"
            @change="handleSearch"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="启用" value="1" />
            <el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="创建时间">
          <el-date-picker
            v-model="timeRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="yyyy-MM-dd HH:mm:ss"
            style="width:340px"
            @change="handleSearch"
          />
        </el-form-item>

        <!-- 搜索/重置按钮：不包裹在 el-form-item，单独 flex 右对齐 -->
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <!-- ===== 操作按钮栏 + 表格 ===== -->
    <el-card shadow="never">
      <div class="toolbar">
        <!-- v-permission 指令已在 main.js 注册（从 store.permissions 校验，无权限直接移除 DOM） -->
        <el-button v-permission="'business:product:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增产品</el-button>
        <el-button v-permission="'business:product:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button v-permission="'business:product:qrcode'" size="small" icon="el-icon-full-screen" :disabled="!selection.length" @click="openBatch('generate')">批量生成二维码</el-button>
        <el-button v-permission="'business:product:qrcode'" size="small" icon="el-icon-printer" :disabled="!selection.length" @click="openBatch('print')">打印标签</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border @selection-change="v => (selection = v)">
        <el-table-column type="selection" width="45" />
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="product_code" label="产品编码" width="140" show-overflow-tooltip>
          <template slot-scope="s">
            <span class="link-text" @click="handleViewDetail(s.row.id)">{{ s.row.product_code }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="product_name" label="产品名称" min-width="150" show-overflow-tooltip>
          <template slot-scope="s">
            <span class="link-text" @click="handleViewDetail(s.row.id)">{{ s.row.product_name }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="category_name" label="产品分类" width="130" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="140" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="70" align="center" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="create_time" label="创建时间" width="160" align="center">
          <template slot-scope="s">{{ formatDateTime(s.row.create_time) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="200" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="handleViewDetail(s.row.id)">详情</el-button>
            <el-button v-permission="'business:product:edit'" type="text" size="mini" @click="handleEdit(s.row.id)">编辑</el-button>
            <el-button v-permission="'business:product:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row.id)">删除</el-button>
            <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
              <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right"></i></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item command="copy">复制产品</el-dropdown-item>
                <el-dropdown-item v-permission="'business:product:drawing:list'" command="viewDrawing">查看图纸</el-dropdown-item>
                <el-dropdown-item v-permission="'business:product:qrcode'" command="qrcode">产品二维码</el-dropdown-item>
                <el-dropdown-item command="bom" disabled>管理BOM</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>

      <!-- ===== 分页 ===== -->
      <el-pagination
        class="pager"
        background
        layout="total, sizes, prev, pager, next, jumper"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        :page-size="queryParams.pageSize"
        :current-page="queryParams.page"
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
    </el-card>

    <!-- 产品二维码弹窗 -->
    <ProductQrcodeDialog :visible.sync="qrcodeVisible" :row="qrcodeRow" @saved="getList" />

    <!-- 产品二维码批量弹窗（批量生成/打印标签） -->
    <ProductQrcodeBatchDialog :visible.sync="qrcodeBatchVisible" :active-tab.sync="qrcodeBatchTab" :selected="selection" @saved="getList" />
  </div>
</template>

<script>
import ProductQrcodeDialog from './components/ProductQrcodeDialog.vue'
import ProductQrcodeBatchDialog from './components/ProductQrcodeBatchDialog.vue'
import {
  getProductList,
  getProductParams,
  deleteProduct,
  exportProduct,
  getProductCategoryTree
} from '../../../api/product'

export default {
  name: 'BusinessProductList',
  components: { ProductQrcodeDialog, ProductQrcodeBatchDialog },
  data() {
    return {
      loading: false,
      exporting: false,
      qrcodeVisible: false,
      qrcodeRow: {},
      qrcodeBatchVisible: false,
      qrcodeBatchTab: 'generate',
      selection: [],
      list: [],
      total: 0,
      categoryOptions: [],
      categoryLoadFailed: false,
      // 级联选择器绑定值（数组，选中末级/父级时仅取最后一级 ID 传给后端，父级递归由后端实现）
      categoryId: [],
      // 搜索时间范围（datetimerange），请求前转换为 start_time/end_time
      timeRange: [],
      queryParams: {
        page: 1,
        pageSize: 10,
        product_name: '',
        product_code: '',
        category_id: '',
        status: '',
        start_time: '',
        end_time: ''
      }
    }
  },
  created() {
    this.loadCategoryTree()
    this.getList()
  },
  methods: {
    /** 组装请求参数：级联末级分类 → category_id；时间范围 → start_time/end_time */
    buildParams() {
      const params = { ...this.queryParams }
      params.category_id = this.categoryId.length ? this.categoryId[this.categoryId.length - 1] : ''
      if (this.timeRange && this.timeRange.length === 2) {
        params.start_time = this.timeRange[0]
        params.end_time = this.timeRange[1]
      } else {
        params.start_time = ''
        params.end_time = ''
      }
      return params
    },
    /** 加载分类树；失败静默降级：置空 options + 禁用级联，不阻塞列表加载 */
    async loadCategoryTree() {
      try {
        const r = await getProductCategoryTree()
        this.categoryOptions = (r && r.code === 0 && r.data) ? r.data : []
        this.categoryLoadFailed = false
      } catch (e) {
        this.categoryOptions = []
        this.categoryLoadFailed = true
      }
    },
    async getList() {
      this.loading = true
      try {
        const r = await getProductList(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {}
      this.loading = false
    },
    /** 搜索：重置页码为 1 后加载 */
    handleSearch() {
      this.queryParams.page = 1
      this.getList()
    },
    /** 重置：清空全部筛选条件并刷新 */
    handleReset() {
      this.queryParams = {
        page: 1,
        pageSize: this.queryParams.pageSize,
        product_name: '',
        product_code: '',
        category_id: '',
        status: '',
        start_time: '',
        end_time: ''
      }
      this.categoryId = []
      this.timeRange = []
      this.handleSearch()
    },
    handlePageChange(p) {
      this.queryParams.page = p
      this.getList()
    },
    handleSizeChange(size) {
      this.queryParams.pageSize = size
      this.queryParams.page = 1
      this.getList()
    },
    handleAdd() {
      this.$router.push('/business/product/add')
    },
    handleEdit(id) {
      this.$router.push(`/business/product/edit/${id}`)
    },
    handleViewDetail(id) {
      this.$router.push(`/business/product/detail/${id}`)
    },
    /** 删除：确认后调用接口，成功后刷新并做页码回退（避免空页） */
    handleDelete(id) {
      this.$confirm('确认删除该产品吗', '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteProduct(id)
          if (r.code === 0) {
            this.$message.success('删除成功')
            await this.getList()
            // 页码回退：当前页已空且非第一页，则减一页重新加载
            if (!this.list.length && this.queryParams.page > 1) {
              this.queryParams.page -= 1
              await this.getList()
            }
          }
        } catch (e) {}
      }).catch(() => {})
    },
    /** 导出：blob 下载，文件名优先取 content-disposition，扩展名按 Content-Type 判断 */
    async handleExport() {
      this.exporting = true
      try {
        const res = await exportProduct(this.buildParams())
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const filename = this.resolveExportFilename(res.headers) || this.defaultExportName()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = filename
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
      this.exporting = false
    },
    /** 解析响应头 content-disposition 中的文件名 */
    resolveExportFilename(headers) {
      if (!headers) return null
      const disposition = headers['content-disposition'] || ''
      if (!disposition) return null
      const star = disposition.match(/filename\*=(?:UTF-8'')?([^;]+)/i)
      if (star) return decodeURIComponent(star[1].replace(/^"|"$/g, ''))
      const plain = disposition.match(/filename="?([^";]+)"?/i)
      if (plain) return plain[1]
      return null
    },
    /** 默认导出文件名：产品列表_YYYYMMDD_HHmmss.xlsx */
    defaultExportName() {
      const now = new Date()
      const pad = n => String(n).padStart(2, '0')
      const stamp = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`
      return `产品列表_${stamp}.xlsx`
    },
    /** 复制产品：排除系统字段（id/编码/时间戳/创建人），异步携带产品参数值，query.copyFrom 传递 */
    async handleCopy(row) {
      const excluded = ['id', 'product_code', 'created_at', 'updated_at', 'deleted_at', 'create_time', 'update_time', 'delete_time', 'created_by', 'created_by_name']
      const copy = {}
      Object.keys(row || {}).forEach(k => {
        if (excluded.indexOf(k) === -1) copy[k] = row[k]
      })
      try {
        const r = await getProductParams(row.id)
        copy.params = (r.code === 0 && r.data && r.data.params) ? r.data.params : []
      } catch (e) {
        copy.params = []
      }
      this.$router.push({ path: '/business/product/add', query: { copyFrom: JSON.stringify(copy) } })
    },
    /** 更多下拉菜单 */
    handleMore(cmd, row) {
      if (cmd === 'copy') this.handleCopy(row)
      else if (cmd === 'viewDrawing') this.$router.push({ path: '/business/product/drawing/list', query: { product_name: row.product_name } })
      else if (cmd === 'qrcode') this.openQrcode(row)
      else if (cmd === 'bom') this.$message.info('功能开发中，敬请期待')
    },
    /** 打开产品二维码弹窗 */
    openQrcode(row) {
      this.qrcodeRow = row
      this.qrcodeVisible = true
    },
    /** 打开批量二维码弹窗（generate 批量生成 / print 打印标签） */
    openBatch(tab) {
      this.qrcodeBatchTab = tab
      this.qrcodeBatchVisible = true
    },
    /** 创建时间格式化：兼容时间戳（秒/毫秒）与 'YYYY-MM-DD HH:mm:ss' 字符串 */
    formatDateTime(val) {
      if (val === null || val === undefined || val === '') return '-'
      let d
      const pad = n => String(n).padStart(2, '0')
      if (typeof val === 'number') {
        d = new Date(val < 1e12 ? val * 1000 : val)
      } else if (typeof val === 'string' && /^\d+$/.test(val)) {
        d = new Date(Number(val) < 1e12 ? Number(val) * 1000 : Number(val))
      } else if (typeof val === 'string') {
        const m = val.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})/)
        if (m) return `${m[1]}-${m[2]}-${m[3]} ${m[4]}:${m[5]}:${m[6]}`
        d = new Date(val)
      } else {
        return '-'
      }
      if (isNaN(d.getTime())) return '-'
      return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
    }
  }
}
</script>

<style scoped>
.product-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.filter-card { margin-bottom: 14px; }
.filter-btns { display: flex; align-items: center; margin-left: 8px; }
.filter-btns .el-button + .el-button { margin-left: 10px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.toolbar .el-button + .el-button { margin-left: 10px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link-text { color: #409eff; cursor: pointer; }
.pager { margin: 20px 0; text-align: right; background-color: #fff; }
.danger { color: #f56c6c; }
</style>
