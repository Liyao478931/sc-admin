<!--
  文件：admin/src/views/production/quality/reject/Index.vue
  功能：不合格品处理（列表/处理对话框/关闭）
  权限：quality:reject:view / handle
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>质量管理</el-breadcrumb-item>
      <el-breadcrumb-item>不合格品处理</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="90px" @submit.native.prevent>
        <el-form-item label="处理单编号"><el-input v-model="query.reject_no" placeholder="请输入处理单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工单编号"><el-input v-model="query.work_order_no" placeholder="请输入工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="产品名称"><el-input v-model="query.product_name" placeholder="请输入产品名称" clearable style="width:140px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="不合格类型">
          <el-select v-model="query.reject_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="(t, v) in typeOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="严重程度">
          <el-select v-model="query.severity" clearable placeholder="全部" style="width:100px">
            <el-option v-for="(t, v) in severityOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="处理状态">
          <el-select v-model="query.handle_status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无不合格品处理记录">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="处理单编号" width="150"><template slot-scope="s"><span class="link-blue">{{ s.row.reject_no }}</span></template></el-table-column>
      <el-table-column label="关联工单" width="140"><template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/plan/order/detail/${s.row.work_order_id}`)">{{ s.row.work_order_no }}</span></template></el-table-column>
      <el-table-column prop="product_name" label="产品名称" min-width="120" show-overflow-tooltip />
      <el-table-column label="不合格类型" width="100" align="center"><template slot-scope="s"><el-tag :type="s.row.reject_type_tag" size="mini">{{ s.row.reject_type_label }}</el-tag></template></el-table-column>
      <el-table-column label="严重程度" width="90" align="center"><template slot-scope="s"><el-tag :type="s.row.severity_tag" size="mini">{{ s.row.severity_label }}</el-tag></template></el-table-column>
      <el-table-column label="处理方式" width="100" align="center"><template slot-scope="s"><el-tag :type="s.row.handle_method_tag" size="mini">{{ s.row.handle_method_label || '-' }}</el-tag></template></el-table-column>
      <el-table-column label="处理状态" width="90" align="center"><template slot-scope="s"><el-tag :type="s.row.handle_status_tag" size="mini">{{ s.row.handle_status_label }}</el-tag></template></el-table-column>
      <el-table-column label="操作" width="150" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row)">详情</el-button>
          <el-button v-if="s.row.handle_status === 0 || s.row.handle_status === 1" v-permission="'quality:reject:handle'" type="text" size="mini" @click="openHandle(s.row)">处理</el-button>
          <el-button v-if="s.row.handle_status === 2" v-permission="'quality:reject:handle'" type="text" size="mini" @click="handleClose(s.row)">关闭</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 详情对话框 -->
    <el-dialog title="不合格品详情" :visible.sync="detailVisible" width="560px" append-to-body>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="处理单编号">{{ currentRow.reject_no }}</el-descriptions-item>
        <el-descriptions-item label="关联工单">{{ currentRow.work_order_no }}</el-descriptions-item>
        <el-descriptions-item label="产品名称">{{ currentRow.product_name }}</el-descriptions-item>
        <el-descriptions-item label="严重程度">{{ currentRow.severity_label }}</el-descriptions-item>
        <el-descriptions-item label="处理状态">{{ currentRow.handle_status_label }}</el-descriptions-item>
        <el-descriptions-item label="处理人">{{ currentRow.handler_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="处理结果" :span="2">{{ currentRow.handle_result || '-' }}</el-descriptions-item>
      </el-descriptions>
      <div class="sub-title">不合格项目</div>
      <el-table :data="currentRow.reject_items || []" size="mini" border>
        <el-table-column prop="item_name" label="项目" min-width="120" />
        <el-table-column prop="measured_value" label="实测值" width="140" />
      </el-table>
    </el-dialog>

    <!-- 处理对话框 -->
    <el-dialog title="处理不合格品" :visible.sync="handleVisible" width="600px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="处理单信息">
          <div class="audit-summary">{{ currentRow.reject_no }} ｜ {{ currentRow.work_order_no }} ｜ {{ currentRow.product_name }}</div>
        </el-form-item>
        <el-form-item label="不合格项目">
          <el-table :data="currentRow.reject_items || []" size="mini" border>
            <el-table-column prop="item_name" label="项目" min-width="120" />
            <el-table-column prop="measured_value" label="实测值" width="140" />
          </el-table>
        </el-form-item>
        <el-form-item label="处理方式">
          <el-select v-model="handleForm.handle_method" style="width:100%">
            <el-option v-for="(t, v) in methodOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="handleForm.handle_method === 1" label="返修说明">
          <el-input v-model="handleForm.rework_note" type="textarea" :rows="3" placeholder="请描述返修要求和期限" />
        </el-form-item>
        <el-form-item label="处理结果">
          <el-input v-model="handleForm.handle_result" type="textarea" :rows="3" placeholder="请描述处理结果" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="handleVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="handling" @click="confirmHandle">确认处理</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getQualityRejectList, handleQualityReject, closeQualityReject } from '@/api/production'

export default {
  name: 'QualityReject',
  data () {
    return {
      typeOptions: { 1: '外观缺陷', 2: '尺寸超差', 3: '性能不达标', 4: '材质问题', 5: '其他' },
      severityOptions: { 1: '轻微', 2: '一般', 3: '严重' },
      methodOptions: { 1: '返修', 2: '报废', 3: '退货', 4: '让步接收' },
      statusOptions: { 0: '待处理', 1: '处理中', 2: '已处理', 3: '已关闭' },
      query: { reject_no: '', work_order_no: '', product_name: '', reject_type: '', severity: '', handle_status: '' },
      list: [], total: 0, page: 1, pageSize: 10, loading: false, handling: false,
      detailVisible: false, handleVisible: false, currentRow: {}, handleForm: {}
    }
  },
  created () { this.loadData() },
  methods: {
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.reject_no) p.reject_no = this.query.reject_no
      if (this.query.work_order_no) p.work_order_no = this.query.work_order_no
      if (this.query.product_name) p.product_name = this.query.product_name
      if (this.query.reject_type !== '' && this.query.reject_type !== null) p.reject_type = this.query.reject_type
      if (this.query.severity !== '' && this.query.severity !== null) p.severity = this.query.severity
      if (this.query.handle_status !== '' && this.query.handle_status !== null) p.handle_status = this.query.handle_status
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getQualityRejectList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { reject_no: '', work_order_no: '', product_name: '', reject_type: '', severity: '', handle_status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    openDetail (row) { this.currentRow = row; this.detailVisible = true },
    openHandle (row) {
      this.currentRow = row
      this.handleForm = { handle_method: 1, rework_note: '', handle_result: '' }
      this.handleVisible = true
    },
    async confirmHandle () {
      if (!this.handleForm.handle_method) { this.$message.warning('请选择处理方式'); return }
      if (this.handleForm.handle_method === 1 && !this.handleForm.rework_note) { this.$message.warning('返修请填写返修说明'); return }
      if (!this.handleForm.handle_result) { this.$message.warning('请填写处理结果'); return }
      this.handling = true
      try {
        const r = await handleQualityReject(this.currentRow.id, this.handleForm)
        if (r.code === 0) { this.$message.success('处理完成'); this.handleVisible = false; this.loadData() } else this.$message.error(r.msg || '处理失败')
      } catch (e) {} finally { this.handling = false }
    },
    handleClose (row) {
      this.$confirm('确认关闭该处理单吗？', '关闭处理单', { type: 'warning' }).then(async () => {
        try { const r = await closeQualityReject(row.id); if (r.code === 0) { this.$message.success('已关闭'); this.loadData() } else this.$message.error(r.msg) } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.sub-title { font-size: 14px; font-weight: 600; margin: 14px 0 8px; color: #303133; }
.audit-summary { font-size: 13px; color: #606266; background: #f8f9fb; padding: 8px 12px; border-radius: 4px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
