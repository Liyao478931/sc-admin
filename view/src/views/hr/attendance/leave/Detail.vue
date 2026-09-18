<!--
  文件：admin/src/views/hr/attendance/leave/Detail.vue
  功能：假勤申请详情（信息/审批记录/附件/操作）
  权限：hr:attendance:leave:view
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>考勤管理</el-breadcrumb-item>
      <el-breadcrumb-item>假勤申请</el-breadcrumb-item>
      <el-breadcrumb-item>申请详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">假勤申请详情 - {{ detail.request_no || '' }}</span>
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push({ path: '/hr/attendance/leave' })">返回列表</el-button>
        <el-button v-if="detail.status === 0 || detail.status === 3" v-permission="'hr:attendance:leave:edit'" size="small" type="primary" @click="goEdit">编辑</el-button>
        <el-button v-if="detail.status === 0" size="small" @click="handleSubmit">提交审批</el-button>
        <el-button v-if="detail.status === 1 && isApprover" v-permission="'hr:attendance:leave:approve'" size="small" type="success" @click="handleApprove">审批通过</el-button>
        <el-button v-if="detail.status === 1 && isApprover" v-permission="'hr:attendance:leave:approve'" size="small" type="danger" @click="handleReject">审批驳回</el-button>
        <el-button v-if="detail.status === 0 || detail.status === 1" size="small" @click="handleCancel">撤销</el-button>
        <el-button v-if="detail.status === 1" size="small" type="warning" @click="handleUrge">催办</el-button>
        <el-button size="small" icon="el-icon-printer" @click="window.print()">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-header">
        <span>申请信息</span>
        <el-tag :type="detail.status_tag" size="small">{{ detail.status_label }}</el-tag>
      </div>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="申请编号">{{ detail.request_no }}</el-descriptions-item>
        <el-descriptions-item label="假勤类型">{{ detail.leave_type_label }}</el-descriptions-item>
        <el-descriptions-item label="申请人">{{ detail.applicant_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="部门">{{ detail.department_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="申请日期范围">{{ detail.date_range || '-' }}</el-descriptions-item>
        <el-descriptions-item label="总天数">{{ Number(detail.total_days) }} 天</el-descriptions-item>
        <el-descriptions-item label="开始时间">{{ detail.start_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="结束时间">{{ detail.end_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="申请事由" :span="2">{{ detail.reason || '-' }}</el-descriptions-item>
        <el-descriptions-item label="申请状态">{{ detail.status_label }}</el-descriptions-item>
        <el-descriptions-item label="审批人">{{ detail.approver_name || detail.approver_id || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审批时间">{{ detail.approve_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审批备注" :span="2">{{ detail.approve_remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ detail.creator_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detail.created_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ detail.updated_at || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card shadow="never" class="logs-card">
      <div slot="header" class="card-header">
        <span>审批记录</span>
        <span class="log-count">共 {{ (detail.logs || []).length }} 条记录</span>
      </div>
      <el-timeline v-if="detail.logs && detail.logs.length">
        <el-timeline-item v-for="lg in detail.logs" :key="lg.id" :timestamp="lg.created_at || ''" placement="top">
          <div>
            <el-tag size="mini" :type="lg.action === 3 ? 'danger' : (lg.action === 2 ? 'success' : 'primary')">{{ lg.action_label }}</el-tag>
            <span class="log-operator">{{ lg.operator_name }}</span>
            <span v-if="lg.from_status_text || lg.to_status_text" class="log-status">{{ lg.from_status_text }} → {{ lg.to_status_text }}</span>
            <div v-if="lg.remark" class="log-remark">{{ lg.remark }}</div>
          </div>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-else description="暂无审批记录" />
    </el-card>

    <el-card shadow="never" class="logs-card">
      <div slot="header" class="card-header"><span>附件</span></div>
      <div v-if="detail.attachments && detail.attachments.length" class="att-list">
        <div v-for="a in detail.attachments" :key="a.id" class="att-item">
          <i class="el-icon-paperclip" />
          <span class="att-name">{{ a.file_name }}</span>
          <span class="att-size">{{ a.file_size ? (a.file_size / 1024).toFixed(1) + ' KB' : '' }}</span>
          <a :href="a.file_path" target="_blank" class="att-download"><el-button type="text" size="mini" icon="el-icon-download">下载</el-button></a>
        </div>
      </div>
      <el-empty v-else description="暂无附件" />
    </el-card>
  </div>
</template>

<script>
import { getLeaveDetail, submitLeave, approveLeave, rejectLeave, cancelLeave, urgeLeave } from '@/api/attendanceLeave'

export default {
  name: 'HrLeaveDetail',
  data () {
    return { id: 0, loading: false, detail: {} }
  },
  computed: {
    isApprover () {
      const uid = this.$store.state.user.userInfo && this.$store.state.user.userInfo.id
      return this.detail.approver_id === uid
    }
  },
  created () {
    this.id = Number(this.$route.params.id)
    this.loadDetail()
  },
  methods: {
    async loadDetail () {
      this.loading = true
      try {
        const r = await getLeaveDetail(this.id)
        if (r.code === 0 && r.data) this.detail = r.data
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {} finally { this.loading = false }
    },
    goEdit () { this.$router.push({ path: `/hr/attendance/leave/edit/${this.id}` }) },
    handleSubmit () {
      this.$confirm(`确认提交申请 ${this.detail.request_no} 审批吗？提交后不可再编辑。`, '提交审批', { type: 'warning' }).then(async () => {
        try {
          const r = await submitLeave(this.id)
          if (r.code === 0) { this.$message.success('已提交审批'); this.loadDetail() } else this.$message.error(r.msg || '提交失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleApprove () {
      this.$prompt('请输入审批备注（可选）', '审批通过', { inputPlaceholder: '审批备注', inputValue: '' }).then(async ({ value }) => {
        try {
          const r = await approveLeave(this.id, value || '')
          if (r.code === 0) { this.$message.success('审批已通过'); this.loadDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleReject () {
      this.$prompt('请输入驳回原因（必填）', '审批驳回', { inputPlaceholder: '驳回原因' }).then(async ({ value }) => {
        if (!value || !value.trim()) { this.$message.warning('驳回原因必填'); return }
        try {
          const r = await rejectLeave(this.id, value.trim())
          if (r.code === 0) { this.$message.success('已驳回'); this.loadDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleCancel () {
      this.$confirm(`确认撤销申请 ${this.detail.request_no} 吗？`, '撤销申请', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelLeave(this.id)
          if (r.code === 0) { this.$message.success('已撤销'); this.loadDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleUrge () {
      this.$confirm('确认催办该申请吗？将通知审批人尽快处理。', '催办', { type: 'warning' }).then(async () => {
        try {
          const r = await urgeLeave(this.id)
          if (r.code === 0) { this.$message.success('已催办'); this.loadDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-title { font-size: 18px; font-weight: bold; }
.info-card { margin-bottom: 16px; }
.logs-card { margin-bottom: 16px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.log-count { color: #909399; font-size: 12px; }
.log-operator { margin-left: 8px; color: #606266; font-size: 13px; }
.log-status { margin-left: 8px; color: #909399; font-size: 12px; }
.log-remark { color: #606266; font-size: 13px; margin-top: 4px; }
.att-item { display: flex; align-items: center; gap: 8px; padding: 8px 0; border-bottom: 1px dashed #ebeef5; }
.att-name { color: #606266; }
.att-size { color: #909399; font-size: 12px; }
.att-download { margin-left: auto; }
</style>
