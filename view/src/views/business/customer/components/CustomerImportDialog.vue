<!--
  文件：admin/src/views/business/customer/components/CustomerImportDialog.vue
  功能：客户批量导入弹窗（Excel）
    - 支持 .xlsx / .xls
    - 返回导入结果：成功数 + 失败明细（行号/原因）
-->
<template>
  <el-dialog title="导入客户" :visible="visible" width="560px" :close-on-click-modal="false" @close="$emit('update:visible', false)">
    <div class="import-tip">
      <p>支持 .xlsx / .xls 格式，请按模板列顺序填写：</p>
      <p class="cols">客户名称 | 客户类型 | 客户简称 | 所属行业 | 所属区域 | 客户等级 | 联系人 | 联系电话 | 联系邮箱 | 地址</p>
      <p class="cols">客户类型取值：state_owned/private/individual/foreign/other；客户等级：A/B/C/D</p>
    </div>
    <el-upload
      drag
      action=""
      :show-file-list="false"
      :http-request="handleUpload"
      accept=".xlsx,.xls"
      :disabled="uploading"
    >
      <i class="el-icon-upload"></i>
      <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
      <div class="el-upload__tip" slot="tip">{{ uploading ? '正在导入…' : '单次最多 1000 条' }}</div>
    </el-upload>

    <div v-if="result" class="result-block">
      <el-alert
        :title="'导入完成：成功 ' + result.success + ' 条，失败 ' + (result.fail ? result.fail.length : 0) + ' 条'"
        :type="result.fail && result.fail.length ? 'warning' : 'success'"
        :closable="false"
        show-icon
      />
      <el-table v-if="result.fail && result.fail.length" :data="result.fail" size="mini" border max-height="220" style="margin-top:10px">
        <el-table-column prop="line" label="行号" width="70" />
        <el-table-column prop="reason" label="失败原因" />
      </el-table>
    </div>
  </el-dialog>
</template>

<script>
import { importCustomer } from '../../../../api/businessCustomer'

export default {
  name: 'CustomerImportDialog',
  props: {
    visible: { type: Boolean, default: false }
  },
  data() {
    return { uploading: false, result: null }
  },
  watch: {
    visible(val) {
      if (val) { this.result = null; this.uploading = false }
    }
  },
  methods: {
    async handleUpload({ file }) {
      const fd = new FormData()
      fd.append('file', file)
      this.uploading = true
      this.result = null
      try {
        const r = await importCustomer(fd)
        if (r.code === 0) this.result = r.data || { success: 0, fail: [] }
      } catch (e) {}
      this.uploading = false
    }
  }
}
</script>

<style scoped>
.import-tip { margin-bottom: 12px; }
.import-tip p { margin: 4px 0; font-size: 12px; color: #606266; }
.import-tip .cols { color: #909399; }
.result-block { margin-top: 14px; }
</style>
