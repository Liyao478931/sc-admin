<!--
  文件：admin/src/views/production/routing/Detail.vue
  功能：工艺路线详情（头信息 + 工序序列）
  权限：production:routing:view
-->
<template>
  <div class="routing-detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>工艺路线</el-breadcrumb-item>
      <el-breadcrumb-item>路线详情</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" v-loading="loading">
      <template v-if="routing.id">
        <el-descriptions :column="3" border size="small" class="desc">
          <el-descriptions-item label="路线编号">{{ routing.routing_code }}</el-descriptions-item>
          <el-descriptions-item label="路线名称">{{ routing.routing_name }}</el-descriptions-item>
          <el-descriptions-item label="版本号">{{ routing.version }}</el-descriptions-item>
          <el-descriptions-item label="产品">{{ routing.product_name }}</el-descriptions-item>
          <el-descriptions-item label="产品编码">{{ routing.product_code }}</el-descriptions-item>
          <el-descriptions-item label="规格型号">{{ routing.product_spec || '-' }}</el-descriptions-item>
          <el-descriptions-item label="产品数量">{{ routing.quantity }}</el-descriptions-item>
          <el-descriptions-item label="单位">{{ routing.unit || '-' }}</el-descriptions-item>
          <el-descriptions-item label="默认路线">
            <el-tag size="mini" :type="routing.is_default === 1 ? 'success' : 'info'">{{ routing.is_default === 1 ? '是' : '否' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="routing.status === 1 ? 'success' : 'info'">{{ routing.status === 1 ? '启用' : '停用' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="审批状态">
            <el-tag size="mini" :type="approvalTag(routing.approval_status)">{{ routing.approval_status_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="工序数">{{ routing.process_count }}</el-descriptions-item>
          <el-descriptions-item label="总标准工时">{{ routing.total_hours }} 小时</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ routing.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="生效日期">{{ routing.effective_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="失效日期">{{ routing.expiry_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ routing.create_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="3">{{ routing.remark || '-' }}</el-descriptions-item>
        </el-descriptions>

        <div class="items-title">工序序列</div>
        <el-table :data="items" size="small" border stripe>
          <el-table-column type="index" label="序号" width="60" align="center" />
          <el-table-column prop="sort_order" label="顺序" width="70" align="center" />
          <el-table-column prop="process_code" label="工序编码" width="110" />
          <el-table-column prop="process_name" label="工序名称" width="140" />
          <el-table-column prop="process_group" label="工序组" width="120" />
          <el-table-column prop="standard_hours" label="标准工时(h)" width="110" align="center" />
          <el-table-column prop="standard_score" label="工分定额" width="100" align="center" />
          <el-table-column prop="workstation_name" label="工位" width="120">
            <template slot-scope="s">{{ s.row.workstation_name || '-' }}</template>
          </el-table-column>
          <el-table-column label="关键工序" width="90" align="center">
            <template slot-scope="s">
              <el-tag size="mini" :type="s.row.is_key === 1 ? 'danger' : 'info'">{{ s.row.is_key === 1 ? '关键' : '普通' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="remark" label="备注" min-width="140">
            <template slot-scope="s">{{ s.row.remark || '-' }}</template>
          </el-table-column>
        </el-table>

        <div class="footer-btns">
          <el-button v-if="routing.approval_status !== 2" v-permission="'production:routing:edit'" type="primary" size="small" @click="$router.push(`/production/routing/edit/${routing.id}`)">编辑</el-button>
          <el-button size="small" @click="$router.push('/production/routing')">返回列表</el-button>
        </div>
      </template>
    </el-card>
  </div>
</template>

<script>
import { getRoutingDetail } from '../../../api/production'

export default {
  name: 'ProductionRoutingDetail',
  data() {
    return {
      loading: false,
      routing: {},
      items: []
    }
  },
  created() {
    this.load()
  },
  methods: {
    approvalTag(v) {
      return ['info', 'warning', 'success', 'danger'][v] || 'info'
    },
    async load() {
      const id = this.$route.params.id
      if (!id) return
      this.loading = true
      try {
        const r = await getRoutingDetail(id)
        if (r.code === 0 && r.data) {
          this.routing = r.data.routing || {}
          this.items = r.data.items || []
        }
      } catch (e) {}
      this.loading = false
    }
  }
}
</script>

<style scoped>
.routing-detail-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.desc { margin-bottom: 8px; }
.items-title { font-size: 15px; font-weight: 600; margin: 16px 0 10px; }
.footer-btns { margin-top: 18px; }
</style>
