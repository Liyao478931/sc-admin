<!-- 文件：admin/src/views/ai/knowledge/components/FileList.vue -->
<!-- 上传队列文件列表：文件名/类型/大小/状态/进度/删除 -->
<template>
  <div class="file-list">
    <el-table :data="files" size="small" stripe>
      <el-table-column prop="name" label="文件名" min-width="220" show-overflow-tooltip />
      <el-table-column label="类型" width="90" align="center">
        <template slot-scope="s">
          <el-tag size="mini" type="info">{{ typeText(s.row.type) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="大小" width="100" align="center">
        <template slot-scope="s">{{ formatSize(s.row.size) }}</template>
      </el-table-column>
      <el-table-column label="状态" width="100" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="statusType(s.row.status)">{{ statusText(s.row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="进度" min-width="160">
        <template slot-scope="s">
          <el-progress :percentage="s.row.progress" :status="s.row.status === 'error' ? 'exception' : ''" :stroke-width="6" />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="70" align="center">
        <template slot-scope="s">
          <el-button size="mini" type="text" icon="el-icon-close" :disabled="s.row.status === 'uploading'"
            @click="$emit('remove', s.row)">移除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div v-if="files.length" class="fl-summary">
      <span>共 {{ files.length }} 个文件 · 已上传 {{ doneCount }}/{{ files.length }}</span>
      <el-progress :percentage="overallProgress" :stroke-width="8" style="width:200px;margin-left:12px;" />
    </div>
  </div>
</template>

<script>
export default {
  name: 'KbFileList',
  props: {
    files: { type: Array, default: () => [] }
  },
  computed: {
    doneCount () {
      return this.files.filter(f => f.status === 'done').length
    },
    overallProgress () {
      if (!this.files.length) return 0
      const sum = this.files.reduce((a, f) => a + (f.progress || 0), 0)
      return Math.round(sum / this.files.length)
    }
  },
  methods: {
    typeText (t) {
      return { pdf: 'PDF', word: 'Word', excel: 'Excel', ppt: 'PPT', txt: 'TXT', md: 'MD', html: 'HTML' }[t] || t || '-'
    },
    statusText (s) {
      return { waiting: '等待上传', uploading: '上传中', done: '上传完成', error: '失败' }[s] || s
    },
    statusType (s) {
      return { waiting: 'info', uploading: 'primary', done: 'success', error: 'danger' }[s] || 'info'
    },
    formatSize (bytes) {
      const b = parseInt(bytes, 10)
      if (isNaN(b) || b <= 0) return '0 B'
      if (b < 1024) return b + ' B'
      if (b < 1048576) return (b / 1024).toFixed(1) + ' KB'
      return (b / 1048576).toFixed(2) + ' MB'
    }
  }
}
</script>

<style scoped>
.file-list { }
.fl-summary { display: flex; align-items: center; margin-top: 10px; font-size: 13px; color: #909399; }
</style>
