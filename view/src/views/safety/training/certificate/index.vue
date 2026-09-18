<template>
  <div class="certificate-page">
    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item><el-input v-model="filters.keyword" placeholder="员工姓名/证书名称/编号" clearable style="width:200px" @keyup.enter.native="onSearch" /></el-form-item>
        <el-form-item>
          <el-select v-model="filters.user_id" clearable filterable placeholder="全部员工" style="width:140px" @change="onSearch">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option v-for="opt in statusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.training_type_id" clearable placeholder="全部类型" style="width:130px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span style="color:#909399">共 <b style="color:#409EFF">{{ total }}</b> 张证书</span>
        <div>
          <el-button v-if="hasPerm('safety:training:certificate:export')" size="small" icon="el-icon-files" @click="doBatchExport">批量导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="55" />
        <el-table-column prop="certificate_code" label="证书编号" width="180" show-overflow-tooltip />
        <el-table-column prop="user_name" label="员工姓名" width="100" />
        <el-table-column prop="certificate_name" label="证书名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="training_name" label="培训名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="issue_date" label="颁发日期" width="110" align="center" />
        <el-table-column prop="expire_date" label="有效期截止" width="110" align="center">
          <template slot-scope="{ row }">{{ row.expire_date || '长期' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 'valid' ? 'success' : 'danger'">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:training:certificate:query')" size="mini" type="text" @click="openPreview(row)">预览</el-button>
            <el-button v-if="hasPerm('safety:training:certificate:export')" size="mini" type="text" @click="doExport(row)">导出</el-button>
            <el-button v-if="hasPerm('safety:training:certificate:config')" size="mini" type="text" style="color:#F56C6C" @click="doDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty v-if="!loading && !list.length" description="暂无培训证书" />
      <el-pagination v-if="total > 0" style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 证书预览弹窗 -->
    <certificate-preview-dialog :visible.sync="previewVisible" :cert-id="certId" />
  </div>
</template>

<script>
import { getCertificateList, exportCertificate, batchExportCertificate, deleteCertificate, getTypeOptions } from '@/api/safetyTrainingArchive'
import { getUserList } from '@/api/user'
import CertificatePreviewDialog from './components/CertificatePreviewDialog.vue'

export default {
  name: 'SafetyTrainingCertificate',
  components: { CertificatePreviewDialog },
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', user_id: null, status: '', training_type_id: null },
      statusOptions: [],
      userOptions: [], typeOptions: [],
      previewVisible: false, certId: 0
    }
  },
  created() {
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadList(); this.loadUsers(); this.loadTypes(); this.loadDicts()
  },
  methods: {
    // 证书状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('certificate_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
    },
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getCertificateList({
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || '',
          user_id: this.filters.user_id || '',
          status: this.filters.status || '',
          training_type_id: this.filters.training_type_id || ''
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadUsers() {
      try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {}
    },
    async loadTypes() {
      try { const r = await getTypeOptions(); if (r.code === 0) this.typeOptions = r.data || [] } catch (e) {}
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() { this.filters = { keyword: '', user_id: null, status: '', training_type_id: null }; this.page = 1; this.loadList() },
    openPreview(row) { this.certId = row.id; this.previewVisible = true },
    doExport(row) {
      this.$confirm('确认导出该证书？将打开证书页面可打印/另存为 PDF。', '导出确认', { type: 'info' }).then(async () => {
        try {
          const r = await exportCertificate(row.id)
          if (r.code === 0 && r.data && r.data.html) { this.openHtml(r.data.html); this.$message.success('已生成证书页面') }
        } catch (e) {}
      }).catch(() => {})
    },
    openHtml(html) {
      const w = window.open('', '_blank')
      w.document.write(html)
      w.document.close()
    },
    doBatchExport() {
      this.$confirm('确认批量导出当前筛选的证书？将打包为 ZIP。', '批量导出', { type: 'info' }).then(async () => {
        try {
          const r = await batchExportCertificate({
            user_ids: this.filters.user_id ? [this.filters.user_id] : [],
            training_type_id: this.filters.training_type_id || 0
          })
          if (r.code === 0 && r.data && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
        } catch (e) {}
      }).catch(() => {})
    },
    doDelete(row) {
      this.$confirm(`确认删除证书「${row.certificate_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteCertificate(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
