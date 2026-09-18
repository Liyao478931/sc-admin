<!--
  文件：admin/src/views/hr/transfer/Detail.vue
  功能：员工异动详情（信息卡 / 变更对比 / 审批时间轴 / 附件 / 状态操作）
  权限：hr:transfer:view / add / edit / approve
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>员工异动</el-breadcrumb-item>
      <el-breadcrumb-item>异动详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">异动详情 - {{ d.transfer_no || '' }}</span>
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push({ path: '/hr/transfer/list' })">返回列表</el-button>
        <el-button v-if="d.status === 0" v-permission="'hr:transfer:edit'" size="small" icon="el-icon-edit" @click="goEdit">编辑</el-button>
        <el-button v-if="d.status === 0" size="small" type="primary" icon="el-icon-upload2" :loading="submitting" @click="handleSubmit">提交审批</el-button>
        <el-button v-if="d.approval_status === 1" size="small" icon="el-icon-refresh-left" :loading="revoking" @click="handleRevoke">撤销审批</el-button>
        <el-button v-if="d.approval_status === 2 && d.status === 1" v-permission="'hr:transfer:approve'" size="small" type="success" icon="el-icon-check" :loading="confirming" @click="handleConfirm">确认生效</el-button>
        <el-button size="small" icon="el-icon-printer" @click="handlePrint">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <div slot="header" class="card-header">
        <span>异动信息</span>
        <span class="card-tags">
          <el-tag :type="d.status_tag" size="small">{{ d.status_label }}</el-tag>
          <el-tag :type="d.approval_status_tag" size="small" style="margin-left:8px">{{ d.approval_status_label }}</el-tag>
        </span>
      </div>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="异动编号">{{ d.transfer_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="异动类型">
          <el-tag :type="d.transfer_type_tag" effect="plain" size="mini">{{ d.transfer_type_label }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="员工姓名">{{ d.employee_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="员工工号">{{ d.employee_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="异动原因" :span="2">{{ d.transfer_reason || '-' }}</el-descriptions-item>
        <el-descriptions-item label="异动生效日期">{{ d.transfer_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="申请日期">{{ d.apply_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审批时间">{{ d.approval_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审批人">{{ d.approver_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审批备注" :span="2">{{ d.approval_remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ d.creator_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ d.created_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ d.updated_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="实际生效时间">{{ d.effective_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ d.remark || '-' }}</el-descriptions-item>
        <template v-if="d.transfer_type === 5">
          <el-descriptions-item label="离职类型">{{ d.leave_type_label || '-' }}</el-descriptions-item>
          <el-descriptions-item label="最后工作日">{{ d.last_work_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="交接人">{{ d.handover_person_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="交接状态">{{ {0: '待交接', 1: '交接中', 2: '已完成'}[d.handover_status] || '-' }}</el-descriptions-item>
        </template>
      </el-descriptions>
    </el-card>

    <el-card shadow="never" class="form-card">
      <div slot="header"><span>{{ d.transfer_type === 5 ? '离职信息对比' : '变更对比' }}</span></div>
      <el-row :gutter="24">
        <el-col :span="12">
          <div class="compare-box" :class="{ highlight: hasChange('before', 'after') }">
            <h4 class="compare-title">{{ d.transfer_type === 5 ? '离职前信息' : '变更前' }}</h4>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="部门">{{ d.before_department_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="岗位">{{ d.before_position_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="职级">{{ d.before_rank_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="薪资">{{ money(d.before_salary) }}</el-descriptions-item>
            </el-descriptions>
          </div>
        </el-col>
        <el-col :span="12">
          <div class="compare-box" :class="{ highlight: hasChange('before', 'after') }">
            <h4 class="compare-title">{{ d.transfer_type === 5 ? '离职信息' : '变更后' }}</h4>
            <template v-if="d.transfer_type === 5">
              <el-descriptions :column="1" border size="small">
                <el-descriptions-item label="离职类型">{{ d.leave_type_label || '-' }}</el-descriptions-item>
                <el-descriptions-item label="最后工作日">{{ d.last_work_date || '-' }}</el-descriptions-item>
                <el-descriptions-item label="交接人">{{ d.handover_person_name || '-' }}</el-descriptions-item>
              </el-descriptions>
            </template>
            <template v-else>
              <el-descriptions :column="2" border size="small">
                <el-descriptions-item label="部门">{{ d.after_department_name || '-' }}</el-descriptions-item>
                <el-descriptions-item label="岗位">{{ d.after_position_name || '-' }}</el-descriptions-item>
                <el-descriptions-item label="职级">{{ d.after_rank_name || '-' }}</el-descriptions-item>
                <el-descriptions-item label="薪资">{{ money(d.after_salary) }}</el-descriptions-item>
              </el-descriptions>
            </template>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <el-card shadow="never" class="form-card">
      <div slot="header"><span>审批记录</span></div>
      <el-timeline v-if="d.approval_histories && d.approval_histories.length" style="padding-left:8px;">
        <el-timeline-item v-for="(h, i) in d.approval_histories" :key="i" :timestamp="h.created_at" :type="h.result === 'reject' ? 'danger' : (h.action === 'submit' ? 'primary' : 'success')" placement="top">
          <div class="history-item">
            <span class="history-action">{{ h.action_label }}：{{ h.result === 'pass' ? '通过' : (h.result === 'reject' ? '驳回' : '') }}</span>
            <span class="history-operator">{{ h.operator_name }}</span>
            <div v-if="h.comment" class="history-comment">审批意见：{{ h.comment }}</div>
          </div>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-else description="暂无审批记录" :image-size="60" />
    </el-card>

    <el-card shadow="never" class="form-card">
      <div slot="header"><span>附件</span></div>
      <el-table :data="d.attachments || []" size="small" border empty-text="暂无附件">
        <el-table-column prop="file_name" label="文件名" min-width="200" show-overflow-tooltip />
        <el-table-column label="附件类型" width="120" align="center">
          <template slot-scope="s">{{ s.row.attachment_type_label || '-' }}</template>
        </el-table-column>
        <el-table-column label="文件大小" width="110" align="right">
          <template slot-scope="s">{{ formatSize(s.row.file_size) }}</template>
        </el-table-column>
        <el-table-column label="上传人" width="100" align="center"><template slot-scope="s">{{ s.row.uploader_name || '-' }}</template></el-table-column>
        <el-table-column label="上传时间" width="160" align="center"><template slot-scope="s">{{ s.row.upload_time || '-' }}</template></el-table-column>
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" icon="el-icon-download" @click="downloadAtt(s.row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getTransferDetail, submitTransfer, revokeTransfer, confirmTransfer } from '@/api/hrTransfer'

export default {
  name: 'HrTransferDetail',
  data () {
    return { d: {}, submitting: false, revoking: false, confirming: false }
  },
  created () {
    this.loadDetail(Number(this.$route.params.id))
  },
  methods: {
    async loadDetail (id) {
      try {
        const r = await getTransferDetail(id)
        if (r.code === 0 && r.data) this.d = r.data
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    hasChange () {
      const b = [this.d.before_department_id, this.d.before_position_id, this.d.before_rank_id, Number(this.d.before_salary)]
      const a = [this.d.after_department_id, this.d.after_position_id, this.d.after_rank_id, Number(this.d.after_salary)]
      return JSON.stringify(b) !== JSON.stringify(a)
    },
    money (v) {
      const n = Number(v) || 0
      return '¥ ' + n.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    },
    formatSize (s) {
      const n = Number(s) || 0
      if (n >= 1048576) return (n / 1048576).toFixed(1) + ' MB'
      if (n >= 1024) return (n / 1024).toFixed(1) + ' KB'
      return n + ' B'
    },
    downloadAtt (row) {
      if (!row.file_path) return
      const a = document.createElement('a')
      a.href = row.file_path
      a.download = row.file_name || ''
      a.target = '_blank'
      a.click()
    },
    goEdit () { this.$router.push({ path: `/hr/transfer/edit/${this.d.id}` }) },
    handleSubmit () {
      this.$confirm(`确认提交异动 ${this.d.transfer_no} 审批吗？提交后不可再编辑。`, '提交审批', { type: 'warning' }).then(async () => {
        this.submitting = true
        try {
          const r = await submitTransfer(this.d.id)
          if (r.code === 0) { this.$message.success('已提交审批'); this.loadDetail(this.d.id) } else this.$message.error(r.msg || '提交失败')
        } catch (e) {} finally { this.submitting = false }
      }).catch(() => {})
    },
    handleRevoke () {
      this.$confirm(`确认撤销异动 ${this.d.transfer_no} 的审批吗？`, '撤销审批', { type: 'warning' }).then(async () => {
        this.revoking = true
        try {
          const r = await revokeTransfer(this.d.id)
          if (r.code === 0) { this.$message.success('已撤销'); this.loadDetail(this.d.id) } else this.$message.error(r.msg || '操作失败')
        } catch (e) {} finally { this.revoking = false }
      }).catch(() => {})
    },
    handleConfirm () {
      this.$confirm(`确认异动 ${this.d.transfer_no} 生效吗？生效后员工档案将自动更新且不可撤回。`, '确认生效', { type: 'warning' }).then(async () => {
        this.confirming = true
        try {
          const r = await confirmTransfer(this.d.id)
          if (r.code === 0) { this.$message.success('异动已生效'); this.loadDetail(this.d.id) } else this.$message.error(r.msg || '操作失败')
        } catch (e) {} finally { this.confirming = false }
      }).catch(() => {})
    },
    handlePrint () { window.print() }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-title { font-size: 18px; font-weight: bold; }
.form-card { margin-bottom: 16px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.card-tags { display: flex; align-items: center; }
.compare-box { border: 1px solid #ebeef5; border-radius: 6px; padding: 12px; }
.compare-box.highlight { border-color: #409EFF; background: #f5f9ff; }
.compare-title { margin: 0 0 10px; font-size: 14px; color: #606266; }
.history-item { line-height: 1.8; }
.history-action { font-weight: bold; margin-right: 10px; }
.history-operator { color: #909399; }
.history-comment { color: #606266; background: #f5f7fa; border-radius: 4px; padding: 4px 8px; margin-top: 4px; font-size: 12px; }
</style>
