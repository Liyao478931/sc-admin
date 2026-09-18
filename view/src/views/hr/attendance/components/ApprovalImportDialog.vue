<template>
  <el-dialog title="导入审批记录" :visible="visible" @update:visible="$emit('update:visible', $event)" width="550px" top="8vh">
    <div class="import-tip">
      <el-button size="small" icon="el-icon-download" @click="downloadTemplate">下载导入模板</el-button>
      <span class="tip">模板列：员工姓名 / 审批类型(leave,outing,travel,car_apply) / 申请日期 / 开始时间 / 结束时间 / 审批状态</span>
    </div>
    <el-upload drag :show-file-list="false" :http-request="doImport" accept=".xlsx,.xls" style="margin-top:12px;">
      <i class="el-icon-upload"></i>
      <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em>（仅支持 .xlsx）</div>
    </el-upload>

    <div v-if="result" class="import-result">
      <div class="result-line">总条数：<b>{{ result.total }}</b>，成功：<b style="color:#67C23A;">{{ result.success }}</b>，失败：<b style="color:#F56C6C;">{{ result.fail }}</b></div>
      <div v-if="result.errors && result.errors.length" class="errors">
        <div v-for="(e, i) in result.errors" :key="i" class="err-item">{{ e }}</div>
      </div>
    </div>
  </el-dialog>
</template>

<script>
import { getApprovalTemplate, importApproval } from '@/api/attendanceApproval'

export default {
  name: 'ApprovalImportDialog',
  props: { visible: { type: Boolean, default: false } },
  data () { return { result: null } },
  methods: {
    async downloadTemplate () {
      try {
        const r = await getApprovalTemplate()
        if (r.code === 0 && r.data && r.data.url) window.open(r.data.url, '_blank')
      } catch (e) {}
    },
    async doImport ({ file }) {
      const fd = new FormData()
      fd.append('file', file)
      try {
        const r = await importApproval(fd)
        if (r.code === 0) {
          this.result = r.data || {}
          this.$message.success(r.msg || '导入完成')
          this.$emit('saved')
        }
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.import-tip { display: flex; align-items: center; gap: 12px; }
.tip { font-size: 12px; color: #909399; }
.import-result { margin-top: 14px; border: 1px solid #EBEEF5; border-radius: 6px; padding: 12px; }
.result-line { font-size: 13px; margin-bottom: 8px; }
.errors { max-height: 180px; overflow-y: auto; }
.err-item { font-size: 12px; color: #F56C6C; padding: 2px 0; }
</style>
