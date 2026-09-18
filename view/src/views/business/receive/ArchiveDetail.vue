<!--
  文件：admin/src/views/business/receive/ArchiveDetail.vue
  功能：产品档案详情（产品维修履历）：基本信息/维修履历时间轴/接收历史时间轴/状态变更日志
  权限：business:receive:archive:view
-->
<template>
  <div class="ad-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品接收管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品档案</el-breadcrumb-item>
      <el-breadcrumb-item>产品详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">产品档案详情 - {{ product.product_name || '' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/business/receive/archive')">返回列表</el-button>
        <el-button size="small" @click="window.print()">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" v-loading="loading">
      <template v-if="loadFailed">
        <el-empty :description="failMsg || '加载失败，请刷新重试'">
          <el-button size="small" @click="$router.push('/business/receive/archive')">返回列表</el-button>
        </el-empty>
      </template>
      <template v-else-if="product.id">
        <!-- 基本信息 -->
        <div class="section-title">
          <span>基本信息</span>
          <el-tag size="small" :type="pStatusTag(product.status)">{{ product.status_label }}</el-tag>
        </div>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="产品编码">{{ product.product_code }}</el-descriptions-item>
          <el-descriptions-item label="产品名称">{{ product.product_name }}</el-descriptions-item>
          <el-descriptions-item label="设备编号/序列号">{{ product.serial_number || '-' }}</el-descriptions-item>
          <el-descriptions-item label="规格型号">{{ product.specification || '-' }}</el-descriptions-item>
          <el-descriptions-item label="单位">{{ product.unit || '-' }}</el-descriptions-item>
          <el-descriptions-item label="产品分类">{{ product.category_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="生产厂家">{{ product.manufacturer || '-' }}</el-descriptions-item>
          <el-descriptions-item label="出厂日期">{{ product.manufacture_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="产品状态"><el-tag size="mini" :type="pStatusTag(product.status)">{{ product.status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="当前所在位置">{{ product.current_location || '-' }}</el-descriptions-item>
          <el-descriptions-item label="产品图片">
            <el-image v-if="product.product_image" :src="product.product_image" :preview-src-list="[product.product_image]" style="width:60px;height:60px;" fit="cover" />
            <span v-else>-</span>
          </el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ product.remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ product.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ product.create_time || '-' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 维修履历 -->
        <div class="section-title">维修履历<span class="count">共 {{ repairs.length }} 次维修记录</span></div>
        <el-timeline v-if="repairs.length">
          <el-timeline-item v-for="(rp, i) in repairs" :key="i" :timestamp="rp.complete_date">
            <div class="tl-head">
              <el-tag size="mini" :type="repairTypeTag(rp.repair_type)">{{ rp.repair_type_label }}</el-tag>
              <span v-if="rp.work_order_no" class="link" @click="$router.push('/business/order?category=repair')">{{ rp.work_order_no }}</span>
              <span class="tl-amount">维修费用：¥{{ Number(rp.cost || 0).toFixed(2) }}</span>
            </div>
            <div class="tl-content">{{ rp.content || '（无描述）' }}</div>
            <div class="tl-sub">负责人：{{ rp.repairer || '-' }}　结果：{{ rp.result || '-' }}</div>
            <div v-if="rp.parts_list && rp.parts_list.length" class="tl-parts">
              更换配件：
              <el-tag v-for="(p, pi) in rp.parts_list" :key="pi" size="mini" style="margin-right:6px;">
                {{ p.name || p.part_name || '-' }} x{{ p.quantity || p.qty || 1 }}
              </el-tag>
            </div>
          </el-timeline-item>
        </el-timeline>
        <el-empty v-else description="暂无维修记录" :image-size="60" />

        <!-- 接收历史 -->
        <div class="section-title">接收历史<span class="count">共 {{ history.length }} 次接收记录</span></div>
        <el-timeline v-if="history.length">
          <el-timeline-item v-for="(h, i) in history" :key="i" :timestamp="h.receipt_date">
            <div class="tl-head">
              <el-tag size="mini" :type="typeTag(h.receipt_type)">{{ h.receipt_type_label }}</el-tag>
              <span class="link" @click="$router.push('/business/receive/detail/' + h.receipt_id)">{{ h.receipt_no }}</span>
            </div>
            <div class="tl-sub">来源：{{ h.source_location || h.receipt_location || h.customer_name || '-' }}　数量：{{ h.quantity }}　接收时状态：{{ h.product_status_label }}</div>
            <div v-if="h.remark" class="tl-content">{{ h.remark }}</div>
          </el-timeline-item>
        </el-timeline>
        <el-empty v-else description="暂无接收记录" :image-size="60" />

        <!-- 状态变更日志 -->
        <div class="section-title">状态变更日志<span class="count">共 {{ statusLogs.length }} 次状态变更</span></div>
        <el-table :data="statusLogs" size="small" border empty-text="暂无状态变更">
          <el-table-column prop="create_time" label="变更时间" width="160" />
          <el-table-column label="变更前" width="90" align="center">
            <template slot-scope="s"><el-tag v-if="s.row.before_label" size="mini">{{ s.row.before_label }}</el-tag><span v-else>-</span></template>
          </el-table-column>
          <el-table-column label="变更后" width="90" align="center">
            <template slot-scope="s"><el-tag size="mini" :type="pStatusTag(s.row.after_status)">{{ s.row.after_label }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="reason" label="变更原因" min-width="160" show-overflow-tooltip />
          <el-table-column prop="ref_no" label="关联单据号" width="150" show-overflow-tooltip />
          <el-table-column prop="operator_name" label="操作人" width="100" align="center" />
        </el-table>
      </template>
    </el-card>
  </div>
</template>

<script>
import { getReceiveArchiveDetail } from '../../../api/purchase'

export default {
  name: 'ProductReceiveArchiveDetail',
  data () {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false, loadFailed: false, failMsg: '',
      product: {}, repairs: [], history: [], statusLogs: []
    }
  },
  created () { this.fetchDetail() },
  methods: {
    async fetchDetail () {
      this.loading = true
      this.loadFailed = false
      this.failMsg = ''
      try {
        const r = await getReceiveArchiveDetail(this.id)
        if (r.code === 0 && r.data) {
          this.product = r.data.product || {}
          this.repairs = r.data.repairs || []
          this.history = r.data.history || []
          this.statusLogs = r.data.status_logs || []
        } else {
          this.loadFailed = true
          this.failMsg = (r && r.msg) || '加载失败，请刷新重试'
        }
      } catch (e) {
        this.loadFailed = true
        this.failMsg = '请求异常：' + (e.message || '网络错误')
      } finally { this.loading = false }
    },
    pStatusTag (v) { return { 1: 'success', 2: 'warning', 3: 'primary', 4: 'danger', 5: 'info' }[v] || 'info' },
    repairTypeTag (v) { return { 1: 'danger', 2: 'warning', 3: 'primary', 4: 'success' }[v] || 'info' },
    typeTag (v) { return { 1: 'primary', 2: 'success', 3: 'warning', 4: 'primary', 5: 'info' }[v] || 'info' }
  }
}
</script>

<style scoped>
.ad-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.section-title { font-size: 15px; font-weight: 600; margin: 20px 0 12px; display: flex; align-items: center; gap: 10px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; display: inline-block; }
.count { font-size: 12px; color: #909399; font-weight: 400; }
.tl-head { display: flex; align-items: center; gap: 8px; }
.tl-amount { margin-left: auto; font-size: 12px; color: #E6A23C; }
.tl-content { font-size: 13px; color: #303133; margin: 4px 0; }
.tl-sub { font-size: 12px; color: #909399; }
.tl-parts { font-size: 12px; color: #606266; margin-top: 4px; }
.link { color: #409EFF; cursor: pointer; }
</style>
