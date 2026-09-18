<!--
  文件：admin/src/views/business/product/Detail.vue
  功能：产品详情
    - 标题栏（左侧标题 + 右侧返回/编辑）
    - 基础信息卡片（el-descriptions，含排序/创建/更新时间）
    - 产品参数卡片（独立加载，空态提示，互不影响）
  权限：页面 business:product:list；编辑按钮 business:product:edit
-->
<template>
  <div class="product-detail-page">
    <!-- ===== 面包屑 ===== -->
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品详情</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- ===== 标题栏 ===== -->
    <div class="page-header">
      <span class="page-title">产品详情</span>
      <div class="header-actions">
        <el-button size="small" @click="handleBack">返回列表</el-button>
        <el-button v-permission="'business:product:edit'" type="primary" size="small" @click="handleEdit">编辑</el-button>
      </div>
    </div>

    <!-- ===== 基础信息卡片 ===== -->
    <el-card shadow="never" class="info-card" v-loading="loading">
      <template v-if="loadFailed">
        <el-empty description="加载失败，请刷新重试">
          <el-button size="small" @click="handleBack">返回列表</el-button>
        </el-empty>
      </template>
      <template v-else-if="product.id">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="产品ID">{{ product.id }}</el-descriptions-item>
          <el-descriptions-item label="产品编码">{{ product.product_code }}</el-descriptions-item>
          <el-descriptions-item label="产品名称">{{ product.product_name }}</el-descriptions-item>
          <el-descriptions-item label="产品分类">{{ product.category_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="规格型号">{{ product.specification || '-' }}</el-descriptions-item>
          <el-descriptions-item label="单位">{{ product.unit || '-' }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="product.status === 1 ? 'success' : 'info'">{{ product.status === 1 ? '启用' : '停用' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="排序">{{ product.sort || 0 }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ formatDateTime(product.create_time) }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ formatDateTime(product.update_time) }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ product.remark || '-' }}</el-descriptions-item>
        </el-descriptions>
      </template>
    </el-card>

    <!-- ===== 产品参数卡片（独立加载） ===== -->
    <el-card shadow="never" class="param-card">
      <div slot="header" class="param-header">
        <span>产品参数</span>
        <span v-if="paramLoading" class="param-loading"><i class="el-icon-loading"></i> 加载中...</span>
      </div>
      <div v-loading="paramLoading">
        <template v-if="!paramLoading && paramList.length">
          <el-table :data="paramList" size="small" border>
            <el-table-column type="index" label="序号" width="55" align="center" />
            <el-table-column prop="param_name" label="参数名称" min-width="160" show-overflow-tooltip />
            <el-table-column prop="param_value" label="参数值" min-width="200" show-overflow-tooltip />
            <el-table-column prop="param_unit" label="单位" width="100" align="center">
              <template slot-scope="s">{{ s.row.param_unit || '-' }}</template>
            </el-table-column>
          </el-table>
        </template>
        <el-empty v-else-if="!paramLoading" description="该产品暂无参数配置" :image-size="80" />
      </div>
    </el-card>
  </div>
</template>

<script>
import { getProductDetail, getProductParams } from '../../../api/product'

export default {
  name: 'BusinessProductDetail',
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false,        // 基础信息加载状态
      paramLoading: false,   // 参数加载状态（独立）
      loadFailed: false,
      product: {
        id: '',
        product_code: '',
        product_name: '',
        category_id: '',
        category_name: '',
        specification: '',
        unit: '',
        status: 0,
        sort: 0,
        remark: '',
        create_time: '',
        update_time: ''
      },
      paramList: []
    }
  },
  created() {
    // 并行加载，互不影响：详情失败展示错误态，参数失败不影响基础信息
    this.fetchDetail()
    this.fetchParams()
  },
  methods: {
    async fetchDetail() {
      this.loading = true
      this.loadFailed = false
      try {
        const r = await getProductDetail(this.id)
        if (r.code === 0 && r.data) {
          this.product = Object.assign(this.product, r.data)
        } else {
          this.loadFailed = true
        }
      } catch (e) {
        this.loadFailed = true
      }
      this.loading = false
    },
    async fetchParams() {
      this.paramLoading = true
      try {
        const r = await getProductParams(this.id)
        if (r.code === 0 && r.data && r.data.params) {
          this.paramList = r.data.params
        } else {
          this.paramList = []
        }
      } catch (e) {
        this.paramList = []
      }
      this.paramLoading = false
    },
    handleBack() {
      this.$router.push('/business/product/list')
    },
    handleEdit() {
      this.$router.push(`/business/product/edit/${this.id}`)
    },
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
.product-detail-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.info-card { margin-bottom: 14px; }
.param-header { display: flex; align-items: center; justify-content: space-between; }
.param-loading { font-size: 12px; color: #909399; }
</style>
