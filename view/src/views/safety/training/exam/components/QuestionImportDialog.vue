<template>
  <el-dialog title="导入题目" :visible="visible" width="550px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div style="margin-bottom:12px;">
      <el-button size="small" icon="el-icon-download" @click="downloadTemplate">下载导入模板</el-button>
      <span style="margin-left:10px;font-size:12px;color:#909399;">仅支持 .xlsx 文件，按模板列导入</span>
    </div>
    <el-upload drag :auto-upload="false" accept=".xlsx" :limit="1" :on-change="onFileChange" :on-remove="onFileRemove" :file-list="fileList" style="margin-bottom:12px;">
      <i class="el-icon-upload" />
      <div class="el-upload__text">将文件拖到此处，或<em>点击选择文件</em></div>
      <div class="el-upload__tip" slot="tip">请使用下载的模板填写数据后上传</div>
    </el-upload>
    <div style="text-align:right;">
      <el-button size="small" type="primary" :loading="importing" :disabled="!file" @click="doImport">开始导入</el-button>
    </div>

    <!-- 导入结果 -->
    <div v-if="result" style="margin-top:16px;padding:12px;background:#f5f7fa;border-radius:6px;">
      <div style="margin-bottom:8px;">
        <el-tag size="small" type="info">总条数：{{ result.total }}</el-tag>
        <el-tag size="small" type="success" style="margin-left:8px;">成功：{{ result.success }}</el-tag>
        <el-tag size="small" type="danger" style="margin-left:8px;">失败：{{ result.failed.length }}</el-tag>
      </div>
      <el-table v-if="result.failed.length" :data="result.failed" size="mini" max-height="220" border>
        <el-table-column prop="row" label="行号" width="60" align="center" />
        <el-table-column prop="msg" label="失败原因" show-overflow-tooltip />
      </el-table>
    </div>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { importQuestionFile, getQuestionTemplate } from '@/api/trainingExam'

export default {
  name: 'QuestionImportDialog',
  props: { visible: { type: Boolean, default: false } },
  data() {
    return { file: null, fileList: [], importing: false, result: null }
  },
  watch: {
    visible(val) { if (val) this.reset() },
  },
  methods: {
    // 关闭弹窗时把事件转发给父组件，保证父组件 visible 同步（避免再次打开无反应）
    handleVisibleChange(val) {
      this.$emit('update:visible', val)
    },
    reset() { this.file = null; this.fileList = []; this.result = null; this.importing = false },
    onFileChange(file) { this.file = file.raw; this.fileList = [file] },
    onFileRemove() { this.file = null; this.fileList = [] },
    async downloadTemplate() {
      try {
        const r = await getQuestionTemplate()
        if (r.code === 0 && r.data.url) window.open(r.data.url, '_blank')
      } catch (e) {}
    },
    async doImport() {
      if (!this.file) { this.$message.warning('请先选择 Excel 文件'); return }
      this.importing = true
      try {
        const fd = new FormData()
        fd.append('file', this.file)
        const r = await importQuestionFile(fd)
        if (r.code === 0) {
          this.result = r.data
          this.$emit('imported')
        }
      } catch (e) {}
      this.importing = false
    },
  },
}
</script>
