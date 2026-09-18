<!--
  文件：admin/src/views/production/report/Audit.vue
  功能：报工审核（统计卡片/筛选/审核通过·驳回）
  权限：production:report:audit:view / audit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产执行</el-breadcrumb-item>
      <el-breadcrumb-item>报工审核</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="8">
        <div class="stat-card stat-orange" @click="quickFilter(1)">
          <div class="stat-icon"><i class="el-icon-time" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#E6A23C">{{ stats.pending }}</div><div class="stat-label">待审核（点击筛选）</div></div>
        </div>
      </el-col>
      <el-col :span="8">
        <div class="stat-card stat-blue" @click="quickFilter(1)">
          <div class="stat-icon"><i class="el-icon-today" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#409EFF">{{ stats.today_pending }}</div><div class="stat-label">今日待审（点击筛选）</div></div>
        </div>
      </el-col>
      <el-col :span="8">
        <div class="stat-card stat-green" @click="quickFilter(2)">
          <div class="stat-icon"><i class="el-icon-document-checked" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#67C23A">{{ stats.audited }}</div><div class="stat-label">审核总数（点击筛选）</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 搜索与筛选区域 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="报工单编号"><el-input v-model="query.report_no" placeholder="请输入报工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工单编号"><el-input v-model="query.work_order_no" placeholder="请输入工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="报工人"><el-input v-model="query.reporter_name" placeholder="请输入报工人姓名" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="关联工序">
          <el-select v-model="query.process_id" clearable filterable placeholder="全部" style="width:130px">
            <el-option v-for="p in processOptions" :key="p.id" :label="p.process_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="关联工位">
          <el-select v-model="query.workstation_id" clearable filterable placeholder="全部" style="width:130px">
            <el-option v-for="w in workstationOptions" :key="w.id" :label="w.workstation_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="关联设备">
          <el-select v-model="query.device_id" clearable filterable placeholder="全部" style="width:150px">
            <el-option v-for="d in deviceOptions" :key="d.id" :label="`${d.name}（${d.device_code}）`" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="审核状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option label="待审核" :value="1" />
            <el-option label="已通过" :value="2" />
            <el-option label="已驳回" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="报工日期">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无报工记录">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="报工单编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/report/detail/${s.row.id}`)">{{ s.row.report_no }}</span></template>
      </el-table-column>
      <el-table-column label="关联工单" width="140">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/plan/order/detail/${s.row.work_order_id}`)">{{ s.row.work_order_no }}</span></template>
      </el-table-column>
      <el-table-column prop="reporter_name" label="报工人" width="90" />
      <el-table-column prop="process_name" label="关联工序" width="110" show-overflow-tooltip />
      <el-table-column prop="workstation_name" label="关联工位" width="110" show-overflow-tooltip />
      <el-table-column prop="device_name" label="关联设备" width="130" show-overflow-tooltip />
      <el-table-column label="完成数量" width="80" align="center"><template slot-scope="s">{{ s.row.quantity || 1 }}</template></el-table-column>
      <el-table-column label="设备工时" width="80" align="right"><template slot-scope="s">{{ Number(s.row.duration || 0) }} h</template></el-table-column>
      <el-table-column label="工分" width="80" align="right"><template slot-scope="s">{{ Number(s.row.calculated_score || 0) }}</template></el-table-column>
      <el-table-column prop="report_date" label="报工日期" width="120" align="center" />
      <el-table-column label="审核状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-if="s.row.status === 1" v-permission="'production:report:audit'" type="text" size="mini" @click="openApprove(s.row)">审核通过</el-button>
          <el-button v-if="s.row.status === 1" v-permission="'production:report:audit'" type="text" size="mini" class="danger-text" @click="openReject(s.row)">审核驳回</el-button>
          <el-button type="text" size="mini" @click="$router.push(`/production/report/detail/${s.row.id}`)">查看详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页组件 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 审核通过对话框 -->
    <el-dialog title="审核通过" :visible.sync="approveVisible" width="750px" append-to-body>
      <div v-if="approveDetail.id">
        <div class="audit-section">报工基本信息</div>
        <el-descriptions :column="3" size="small" border style="margin-bottom:12px">
          <el-descriptions-item label="报工单编号">{{ approveDetail.report_no }}</el-descriptions-item>
          <el-descriptions-item label="报工人">{{ approveDetail.reporter_name }}</el-descriptions-item>
          <el-descriptions-item label="关联工单">{{ approveDetail.work_order_no }}</el-descriptions-item>
          <el-descriptions-item label="关联工序">{{ approveDetail.process_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="关联工位">{{ approveDetail.workstation_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="关联设备">{{ approveDetail.device_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="报工日期">{{ approveDetail.report_date }}</el-descriptions-item>
          <el-descriptions-item label="完成数量">{{ approveDetail.quantity || 1 }} 件</el-descriptions-item>
          <el-descriptions-item label="设备使用时长">{{ Number(approveDetail.duration || 0) }} 小时</el-descriptions-item>
        </el-descriptions>

        <div class="audit-section">工分计算与调整</div>
        <div class="score-formula">{{ scoreFormula || '-' }}</div>
        <el-form label-width="90px" size="small">
          <el-form-item label="最终工分">
            <el-input-number v-model="approveForm.total_score" :min="0.01" :precision="2" style="width:200px" />
            <span v-if="scoreAdjusted" class="balance-warn">{{ scoreAdjusted }}</span>
          </el-form-item>
        </el-form>

        <template v-if="approveDetail.materials && approveDetail.materials.length">
          <div class="audit-section">使用材料配件</div>
          <el-table :data="approveDetail.materials" size="mini" border style="margin-bottom:12px">
            <el-table-column prop="material_code" label="物料编码" width="120" />
            <el-table-column prop="material_name" label="物料名称" min-width="130" />
            <el-table-column prop="specification" label="规格型号" width="120" show-overflow-tooltip />
            <el-table-column prop="unit" label="单位" width="60" align="center" />
            <el-table-column label="使用数量" width="90" align="right"><template slot-scope="s">{{ s.row.quantity }}</template></el-table-column>
          </el-table>
        </template>

        <template v-if="approveDetail.photos && approveDetail.photos.length">
          <div class="audit-section">作业照片</div>
          <div class="photo-grid">
            <el-image v-for="(u, idx) in approveDetail.photos" :key="idx" :src="u" fit="cover" class="photo-img" :preview-src-list="approveDetail.photos" :initial-index="idx" />
          </div>
        </template>

        <el-form label-width="90px" size="small">
          <el-form-item label="审核备注"><el-input v-model="approveForm.audit_remark" type="textarea" :rows="3" placeholder="请输入审核备注（可选）" /></el-form-item>
        </el-form>
      </div>
      <div slot="footer">
        <el-button size="small" @click="approveVisible = false">取消</el-button>
        <el-button size="small" type="success" :loading="acting" @click="confirmApprove">确认通过</el-button>
      </div>
    </el-dialog>

    <!-- 审核驳回对话框 -->
    <el-dialog title="审核驳回" :visible.sync="rejectVisible" width="650px" append-to-body>
      <div v-if="rejectDetail.id">
        <div class="audit-section">报工基本信息</div>
        <el-descriptions :column="3" size="small" border style="margin-bottom:12px">
          <el-descriptions-item label="报工单编号">{{ rejectDetail.report_no }}</el-descriptions-item>
          <el-descriptions-item label="报工人">{{ rejectDetail.reporter_name }}</el-descriptions-item>
          <el-descriptions-item label="关联工单">{{ rejectDetail.work_order_no }}</el-descriptions-item>
          <el-descriptions-item label="关联工序">{{ rejectDetail.process_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="关联工位">{{ rejectDetail.workstation_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="关联设备">{{ rejectDetail.device_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="完成数量">{{ rejectDetail.quantity || 1 }} 件</el-descriptions-item>
          <el-descriptions-item label="设备使用时长">{{ Number(rejectDetail.duration || 0) }} 小时</el-descriptions-item>
        </el-descriptions>

        <template v-if="rejectDetail.photos && rejectDetail.photos.length">
          <div class="audit-section">作业照片</div>
          <div class="photo-grid">
            <el-image v-for="(u, idx) in rejectDetail.photos" :key="idx" :src="u" fit="cover" class="photo-img" :preview-src-list="rejectDetail.photos" :initial-index="idx" />
          </div>
        </template>

        <el-form label-width="90px" size="small">
          <el-form-item label="驳回原因"><el-input v-model="rejectForm.reason" type="textarea" :rows="4" placeholder="请详细填写驳回原因，以便报工人了解问题并重新报工" /></el-form-item>
        </el-form>
      </div>
      <div slot="footer">
        <el-button size="small" @click="rejectVisible = false">取消</el-button>
        <el-button size="small" type="danger" :loading="acting" @click="confirmReject">确认驳回</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getAuditList, getReportDetail, approveReport, rejectReport, getProcessList, getWorkstationList, getWsDeviceOptions } from '@/api/production'

export default {
  name: 'ProductionReportAudit',
  data () {
    return {
      stats: { pending: 0, today_pending: 0, audited: 0 },
      query: { report_no: '', work_order_no: '', reporter_name: '', status: '', process_id: '', workstation_id: '', device_id: '', dateRange: [] },
      list: [], total: 0, page: 1, pageSize: 10, loading: false, acting: false,
      processOptions: [], workstationOptions: [], deviceOptions: [],
      approveVisible: false, approveForm: { total_score: 0, audit_remark: '' }, approveDetail: {},
      rejectVisible: false, rejectForm: { reason: '' }, rejectDetail: {},
      currentRow: {}
    }
  },
  computed: {
    scoreFormula () {
      const d = this.approveDetail
      if (!d || !d.process_id) return ''
      const p = this.processOptions.find(x => x.id === d.process_id)
      if (!p) return ''
      return `${Number(p.standard_score)} 分 × ${Number(d.quantity || 1)} 件 = ${Number(d.calculated_score || 0)} 分`
    },
    scoreAdjusted () {
      const d = this.approveDetail
      if (!d) return ''
      if (Math.abs(Number(this.approveForm.total_score) - Number(d.calculated_score || 0)) > 0.001) {
        return `工分已从 ${Number(d.calculated_score || 0)} 分调整为 ${Number(this.approveForm.total_score)} 分`
      }
      return ''
    }
  },
  created () { this.loadProcesses(); this.loadWorkstations(); this.loadDevices(); this.loadData() },
  methods: {
    async loadProcesses () { try { const r = await getProcessList({ page: 1, pageSize: 200, status: 1 }); if (r.code === 0) this.processOptions = r.data.list || [] } catch (e) { this.processOptions = [] } },
    async loadWorkstations () { try { const r = await getWorkstationList({ page: 1, pageSize: 200, status: 1 }); if (r.code === 0) this.workstationOptions = r.data.list || [] } catch (e) { this.workstationOptions = [] } },
    async loadDevices () { try { const r = await getWsDeviceOptions(); if (r.code === 0) this.deviceOptions = r.data.list || [] } catch (e) { this.deviceOptions = [] } },
    tagType (t) { return t === 'purple' ? 'info' : t },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.report_no) p.report_no = this.query.report_no
      if (this.query.work_order_no) p.work_order_no = this.query.work_order_no
      if (this.query.reporter_name) p.reporter_name = this.query.reporter_name
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      if (this.query.process_id !== '' && this.query.process_id !== null) p.process_id = this.query.process_id
      if (this.query.workstation_id !== '' && this.query.workstation_id !== null) p.workstation_id = this.query.workstation_id
      if (this.query.device_id !== '' && this.query.device_id !== null) p.device_id = this.query.device_id
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getAuditList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.stats = r.data.stats || { pending: 0, today_pending: 0, audited: 0 }
          this.list = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { report_no: '', work_order_no: '', reporter_name: '', status: '', process_id: '', workstation_id: '', device_id: '', dateRange: [] }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    quickFilter (status) { this.query.status = status; this.handleSearch() },
    async openApprove (row) {
      this.currentRow = row
      this.approveVisible = true
      this.approveDetail = {}
      this.approveForm = { total_score: Number(row.calculated_score || row.total_score) || 0, audit_remark: '' }
      try {
        const r = await getReportDetail(row.id)
        if (r.code === 0 && r.data) {
          this.approveDetail = r.data
          this.approveForm.total_score = Number(r.data.calculated_score || r.data.total_score) || 0
        }
      } catch (e) {}
    },
    async openReject (row) {
      this.currentRow = row
      this.rejectDetail = {}
      this.rejectForm = { reason: '' }
      this.rejectVisible = true
      try {
        const r = await getReportDetail(row.id)
        if (r.code === 0 && r.data) this.rejectDetail = r.data
      } catch (e) {}
    },
    async confirmApprove () {
      this.acting = true
      try {
        const data = { total_score: this.approveForm.total_score, audit_remark: this.approveForm.audit_remark }
        const r = await approveReport(this.currentRow.id, data)
        if (r.code === 0) { this.$message.success(r.msg || '审核通过'); this.approveVisible = false; this.loadData() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    },
    async confirmReject () {
      if (!this.rejectForm.reason) { this.$message.warning('请填写驳回原因'); return }
      this.acting = true
      try {
        const r = await rejectReport(this.currentRow.id, { reason: this.rejectForm.reason })
        if (r.code === 0) { this.$message.success('已驳回并通知报工人'); this.rejectVisible = false; this.loadData() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.stat-row { margin-bottom: 16px; }
.stat-card { display: flex; align-items: center; padding: 16px 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: transform .2s; }
.stat-card:hover { transform: translateY(-3px); }
.stat-orange { background: linear-gradient(135deg, #fdf6ec, #fae8cd); }
.stat-blue { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-green { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-icon { font-size: 30px; margin-right: 14px; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-num { font-size: 24px; font-weight: bold; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.danger-text { color: #F56C6C; }
.task-desc { display: inline-block; max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.tag-purple { background: #f5ecfb; color: #9B59B6; border-color: #ecd9f7; }
.audit-section { font-size: 14px; font-weight: 600; margin: 14px 0 8px; color: #303133; }
.score-formula { font-size: 14px; color: #409EFF; background: #ecf5ff; padding: 8px 12px; border-radius: 4px; margin-bottom: 10px; }
.photo-grid { display: flex; flex-wrap: wrap; gap: 10px; margin: 4px 0 12px; }
.photo-img { width: 100px; height: 100px; border-radius: 4px; border: 1px solid #ebeef5; }
.qty-tip { font-size: 12px; color: #909399; line-height: 20px; margin-top: 6px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
