<!--
  文件：admin/src/views/business/product/bom/List.vue
  功能：BOM管理列表（搜索/分页/新增/导出/详情/编辑/删除/设为默认/复制/启停/提交审批）
  权限：business:product:bom:list/add/edit/delete/export/approve/default
-->
<template>
  <div class="bom-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>BOM管理</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索区 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="BOM编号">
          <el-input v-model="queryParams.bom_code" placeholder="请输入BOM编号" clearable style="width:170px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="BOM名称">
          <el-input v-model="queryParams.bom_name" placeholder="请输入BOM名称" clearable style="width:170px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="产品名称">
          <el-input v-model="queryParams.product_name" placeholder="请输入产品名称" clearable style="width:160px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="全部" clearable style="width:100px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="启用" value="1" />
            <el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="审批状态">
          <el-select v-model="queryParams.approval_status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="草稿" value="0" />
            <el-option label="待审批" value="1" />
            <el-option label="已审批" value="2" />
            <el-option label="已驳回" value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="创建时间">
          <el-date-picker v-model="timeRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width:320px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:product:bom:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增BOM</el-button>
        <el-button v-permission="'business:product:bom:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="bom_code" label="BOM编号" width="150" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.bom_code }}</span></template>
        </el-table-column>
        <el-table-column prop="bom_name" label="BOM名称" width="150" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.bom_name }}</span></template>
        </el-table-column>
        <el-table-column prop="product_name" label="产品名称" width="130" show-overflow-tooltip />
        <el-table-column prop="product_code" label="产品编码" width="120" show-overflow-tooltip />
        <el-table-column prop="version" label="版本号" width="80" align="center" />
        <el-table-column prop="quantity" label="父件数量" width="100" align="right" />
        <el-table-column label="默认BOM" width="70" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="s.row.is_default === 1 ? 'success' : 'info'">{{ s.row.is_default === 1 ? '是' : '否' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="审批状态" width="100" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="approvalTag(s.row.approval_status)">{{ s.row.approval_status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="create_time" label="创建时间" width="160" align="center" />
        <el-table-column label="操作" width="220" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="viewDetail(s.row.id)">详情</el-button>
            <el-button v-permission="'business:product:bom:edit'" type="text" size="mini" :disabled="s.row.approval_status === 2" @click="handleEdit(s.row.id)">编辑</el-button>
            <el-button v-permission="'business:product:bom:delete'" type="text" size="mini" class="danger" :disabled="s.row.approval_status === 2" @click="handleDelete(s.row.id)">删除</el-button>
            <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
              <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right"></i></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item v-permission="'business:product:bom:default'" command="default">设为默认</el-dropdown-item>
                <el-dropdown-item v-permission="'business:product:bom:add'" command="copy">复制BOM</el-dropdown-item>
                <el-dropdown-item v-permission="'business:product:bom:edit'" command="toggle">{{ s.row.status === 1 ? '停用' : '启用' }}</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 0" v-permission="'business:product:bom:approve'" command="approve">提交审批</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>

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
  </div>
</template>

<script>
import {
  getBomList, deleteBom, copyBom, setDefaultBom, submitBomApproval, toggleBomStatus, exportBom
} from '../../../../api/product'

export default {
  name: 'BusinessProductBomList',
  data() {
    return {
      loading: false,
      exporting: false,
      list: [],
      total: 0,
      timeRange: [],
      queryParams: {
        page: 1,
        pageSize: 10,
        bom_code: '',
        bom_name: '',
        product_name: '',
        status: '',
        approval_status: '',
        start_time: '',
        end_time: ''
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    approvalTag(v) {
      return ['info', 'warning', 'success', 'danger'][v] || 'info'
    },
    buildParams() {
      const p = { ...this.queryParams }
      if (this.timeRange && this.timeRange.length === 2) {
        p.start_time = this.timeRange[0]
        p.end_time = this.timeRange[1]
      } else { p.start_time = ''; p.end_time = '' }
      return p
    },
    async getList() {
      this.loading = true
      try {
        const r = await getBomList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    handleSearch() { this.queryParams.page = 1; this.getList() },
    handleReset() {
      this.queryParams = { page: 1, pageSize: this.queryParams.pageSize, bom_code: '', bom_name: '', product_name: '', status: '', approval_status: '', start_time: '', end_time: '' }
      this.timeRange = []
      this.handleSearch()
    },
    handlePageChange(p) { this.queryParams.page = p; this.getList() },
    handleSizeChange(size) { this.queryParams.pageSize = size; this.queryParams.page = 1; this.getList() },
    handleAdd() { this.$router.push('/business/product/bom/add') },
    viewDetail(id) { this.$router.push(`/business/product/bom/detail/${id}`) },
    handleEdit(id) { this.$router.push(`/business/product/bom/edit/${id}`) },
    handleDelete(id) {
      this.$confirm('确认删除该BOM吗？删除后不可恢复', '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteBom(id)
          if (r.code === 0) {
            this.$message.success('删除成功')
            await this.getList()
            if (!this.list.length && this.queryParams.page > 1) {
              this.queryParams.page -= 1
              await this.getList()
            }
          }
        } catch (e) {}
      }).catch(() => {})
    },
    async handleMore(cmd, row) {
      if (cmd === 'default') {
        try {
          const r = await setDefaultBom(row.id)
          if (r.code === 0) { this.$message.success('已设为默认BOM'); this.getList() }
        } catch (e) {}
      } else if (cmd === 'copy') {
        try {
          const r = await copyBom(row.id)
          if (r.code === 0 && r.data && r.data.id) { this.$message.success('复制成功'); this.$router.push(`/business/product/bom/edit/${r.data.id}`) }
        } catch (e) {}
      } else if (cmd === 'toggle') {
        if (row.status === 1 && row.approval_status === 2) { this.$message.warning('已审批的BOM不能停用'); return }
        try {
          const r = await toggleBomStatus(row.id, row.status === 1 ? 0 : 1)
          if (r.code === 0) { this.$message.success(r.msg); this.getList() }
        } catch (e) {}
      } else if (cmd === 'approve') {
        try {
          const r = await submitBomApproval(row.id)
          if (r.code === 0) { this.$message.success('已提交审批'); this.getList() }
        } catch (e) {}
      }
    },
    async handleExport() {
      this.exporting = true
      try {
        const res = await exportBom(this.buildParams())
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const filename = this.resolveName(res.headers) || 'BOM列表_' + this.stamp() + '.xlsx'
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
    resolveName(headers) {
      if (!headers) return null
      const d = headers['content-disposition'] || ''
      if (!d) return null
      const star = d.match(/filename\*=(?:UTF-8'')?([^;]+)/i)
      if (star) return decodeURIComponent(star[1].replace(/^"|"$/g, ''))
      const plain = d.match(/filename="?([^";]+)"?/i)
      return plain ? plain[1] : null
    },
    stamp() {
      const n = new Date()
      const pad = x => String(x).padStart(2, '0')
      return `${n.getFullYear()}${pad(n.getMonth() + 1)}${pad(n.getDate())}_${pad(n.getHours())}${pad(n.getMinutes())}${pad(n.getSeconds())}`
    }
  }
}
</script>

<style scoped>
.bom-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.filter-card { margin-bottom: 14px; }
.filter-btns { display: flex; align-items: center; margin-left: 8px; }
.filter-btns .el-button + .el-button { margin-left: 10px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link-text { color: #409eff; cursor: pointer; }
.pager { margin: 20px 0; text-align: right; }
.danger { color: #f56c6c; }
</style>
