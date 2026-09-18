<!--
  文件：admin/src/views/production/routing/List.vue
  功能：工艺路线管理列表（搜索/分页/新增/导出/详情/编辑/删除/设为默认/复制/启停/提交审批）
  权限：production:routing:view/add/edit/delete/export/approve/default
-->
<template>
  <div class="routing-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>工艺路线</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索区 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="路线编号">
          <el-input v-model="queryParams.routing_code" placeholder="请输入路线编号" clearable style="width:170px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="路线名称">
          <el-input v-model="queryParams.routing_name" placeholder="请输入路线名称" clearable style="width:170px" @keyup.enter.native="handleSearch" />
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
        <el-button v-permission="'production:routing:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增工艺路线</el-button>
        <el-button v-permission="'production:routing:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="routing_code" label="路线编号" width="150" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.routing_code }}</span></template>
        </el-table-column>
        <el-table-column prop="routing_name" label="路线名称" width="160" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.routing_name }}</span></template>
        </el-table-column>
        <el-table-column prop="product_name" label="产品名称" width="130" show-overflow-tooltip />
        <el-table-column prop="product_code" label="产品编码" width="110" show-overflow-tooltip />
        <el-table-column prop="version" label="版本号" width="80" align="center" />
        <el-table-column prop="process_count" label="工序数" width="70" align="center" />
        <el-table-column prop="total_hours" label="总工时(h)" width="90" align="right" />
        <el-table-column label="默认路线" width="80" align="center">
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
        <el-table-column label="操作" width="230" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="viewDetail(s.row.id)">详情</el-button>
            <el-button v-permission="'production:routing:edit'" type="text" size="mini" :disabled="s.row.approval_status === 2" @click="handleEdit(s.row.id)">编辑</el-button>
            <el-button v-permission="'production:routing:delete'" type="text" size="mini" class="danger" :disabled="s.row.approval_status === 2" @click="handleDelete(s.row.id)">删除</el-button>
            <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
              <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right"></i></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item v-permission="'production:routing:default'" command="default">设为默认</el-dropdown-item>
                <el-dropdown-item v-permission="'production:routing:add'" command="copy">复制路线</el-dropdown-item>
                <el-dropdown-item v-permission="'production:routing:edit'" command="toggle">{{ s.row.status === 1 ? '停用' : '启用' }}</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 0" v-permission="'production:routing:approve'" command="approve">提交审批</el-dropdown-item>
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
  getRoutingList, deleteRouting, copyRouting, setDefaultRouting, submitRoutingApproval, toggleRoutingStatus, exportRouting
} from '../../../api/production'

export default {
  name: 'ProductionRoutingList',
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
        routing_code: '',
        routing_name: '',
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
        const r = await getRoutingList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    handleSearch() { this.queryParams.page = 1; this.getList() },
    handleReset() {
      this.queryParams = { page: 1, pageSize: this.queryParams.pageSize, routing_code: '', routing_name: '', product_name: '', status: '', approval_status: '', start_time: '', end_time: '' }
      this.timeRange = []
      this.handleSearch()
    },
    handlePageChange(p) { this.queryParams.page = p; this.getList() },
    handleSizeChange(size) { this.queryParams.pageSize = size; this.queryParams.page = 1; this.getList() },
    handleAdd() { this.$router.push('/production/routing/add') },
    viewDetail(id) { this.$router.push(`/production/routing/detail/${id}`) },
    handleEdit(id) { this.$router.push(`/production/routing/edit/${id}`) },
    handleDelete(id) {
      this.$confirm('确认删除该工艺路线吗？删除后不可恢复', '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteRouting(id)
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
          const r = await setDefaultRouting(row.id)
          if (r.code === 0) { this.$message.success('已设为默认工艺路线'); this.getList() }
        } catch (e) {}
      } else if (cmd === 'copy') {
        try {
          const r = await copyRouting(row.id)
          if (r.code === 0 && r.data && r.data.id) { this.$message.success('复制成功'); this.$router.push(`/production/routing/edit/${r.data.id}`) }
        } catch (e) {}
      } else if (cmd === 'toggle') {
        if (row.status === 1 && row.approval_status === 2) { this.$message.warning('已审批的路线不能停用'); return }
        try {
          const r = await toggleRoutingStatus(row.id, row.status === 1 ? 0 : 1)
          if (r.code === 0) { this.$message.success(r.msg); this.getList() }
        } catch (e) {}
      } else if (cmd === 'approve') {
        try {
          const r = await submitRoutingApproval(row.id)
          if (r.code === 0) { this.$message.success('已提交审批'); this.getList() }
        } catch (e) {}
      }
    },
    async handleExport() {
      this.exporting = true
      try {
        const res = await exportRouting(this.buildParams())
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const filename = this.resolveName(res.headers) || '工艺路线_' + this.stamp() + '.xlsx'
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
.routing-page { padding: 4px 16px; }
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
