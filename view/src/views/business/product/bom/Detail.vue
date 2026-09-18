<!--
  文件：admin/src/views/business/product/bom/Detail.vue
  功能：BOM详情（头信息卡片 + 结构树）
  权限：页面 business:product:bom:list；编辑按钮 business:product:bom:edit
-->
<template>
  <div class="bom-detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>BOM管理</el-breadcrumb-item>
      <el-breadcrumb-item>BOM详情</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 标题栏 -->
    <div class="page-header">
      <span class="page-title">BOM详情 - {{ bom.bom_code || '' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/business/product/bom')">返回列表</el-button>
        <el-button v-permission="'business:product:bom:edit'" type="primary" size="small" :disabled="bom.approval_status === 2" @click="$router.push(`/business/product/bom/edit/${id}`)">编辑</el-button>
        <el-button size="small" icon="el-icon-printer" @click="handlePrint">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" v-loading="loading">
      <template v-if="loadFailed">
        <el-empty description="加载失败，请刷新重试">
          <el-button size="small" @click="$router.push('/business/product/bom')">返回列表</el-button>
        </el-empty>
      </template>
      <template v-else-if="bom.id">
        <!-- 头信息 -->
        <div class="section-title">BOM头信息</div>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="BOM编号">{{ bom.bom_code }}</el-descriptions-item>
          <el-descriptions-item label="BOM名称">{{ bom.bom_name }}</el-descriptions-item>
          <el-descriptions-item label="产品名称">{{ bom.product_name }}</el-descriptions-item>
          <el-descriptions-item label="产品编码">{{ bom.product_code }}</el-descriptions-item>
          <el-descriptions-item label="版本号">{{ bom.version }}</el-descriptions-item>
          <el-descriptions-item label="父件数量">{{ bom.quantity }}</el-descriptions-item>
          <el-descriptions-item label="单位">{{ bom.unit || '-' }}</el-descriptions-item>
          <el-descriptions-item label="是否默认">
            <el-tag size="mini" :type="bom.is_default === 1 ? 'success' : 'info'">{{ bom.is_default === 1 ? '是' : '否' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="bom.status === 1 ? 'success' : 'info'">{{ bom.status === 1 ? '启用' : '停用' }}</el-tag>
            <el-tag v-if="bom.is_expired" size="mini" type="danger" style="margin-left:6px">已过期</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="审批状态">
            <el-tag size="mini" :type="approvalTag(bom.approval_status)">{{ bom.approval_status_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="生效日期">{{ bom.effective_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="失效日期">{{ bom.expiry_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ bom.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ bom.create_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ bom.update_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ bom.remark || '-' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 结构树 -->
        <div class="section-title tree-title">BOM结构</div>
        <BomTreeTable :items="treeItems" :loading="loading" />
      </template>
    </el-card>
  </div>
</template>

<script>
import { getBomDetail } from '../../../../api/product'
import BomTreeTable from './components/BomTreeTable.vue'

export default {
  name: 'BusinessProductBomDetail',
  components: { BomTreeTable },
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false,
      loadFailed: false,
      bom: {},
      treeItems: []
    }
  },
  created() {
    this.fetchDetail()
  },
  methods: {
    approvalTag(v) { return ['info', 'warning', 'success', 'danger'][v] || 'info' },
    async fetchDetail() {
      this.loading = true
      this.loadFailed = false
      try {
        const r = await getBomDetail(this.id)
        if (r.code === 0 && r.data) {
          this.bom = r.data.bom || {}
          this.treeItems = r.data.items || []
        } else {
          this.loadFailed = true
        }
      } catch (e) { this.loadFailed = true }
      this.loading = false
    },
    handlePrint() { window.print() }
  }
}
</script>

<style scoped>
.bom-detail-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.section-title { display: flex; align-items: center; font-size: 15px; font-weight: 600; margin: 18px 0 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; }
.tree-title { margin-top: 20px; }
</style>
