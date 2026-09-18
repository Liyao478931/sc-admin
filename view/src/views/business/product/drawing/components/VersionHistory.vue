<!--
  文件：admin/src/views/business/product/drawing/components/VersionHistory.vue
  功能：图纸版本历史列表（按上传时间倒序，最新在前）
  props：versions（数组）、highlight（是否高亮最新，默认 true）
  emits：download（下载历史版本，参数为版本记录）
-->
<template>
  <div class="version-history">
    <el-table :data="versions" size="small" :row-class-name="rowClass">
      <el-table-column label="版本号" width="100" align="center">
        <template slot-scope="s">
          {{ s.row.version }}
          <el-tag v-if="isFirst(s.$index)" size="mini" type="success" style="margin-left:4px">最新</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="文件大小" width="110" align="right">
        <template slot-scope="s">{{ formatSize(s.row.file_size) }}</template>
      </el-table-column>
      <el-table-column prop="uploader_name" label="上传人" width="110" />
      <el-table-column prop="uploaded_at" label="上传时间" width="160" align="center" />
      <el-table-column prop="change_description" label="变更说明" min-width="160" show-overflow-tooltip>
        <template slot-scope="s">{{ s.row.change_description || '-' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="90" align="center">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$emit('download', s.row)">下载</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-empty v-if="!versions.length" description="暂无历史版本" :image-size="70" />
  </div>
</template>

<script>
export default {
  name: 'VersionHistory',
  props: {
    versions: { type: Array, default: () => [] }
  },
  methods: {
    isFirst(idx) { return idx === 0 && this.versions.length > 0 },
    rowClass({ row }) {
      return this.versions.length && row.id === this.versions[0].id ? 'row-newest' : ''
    },
    formatSize(bytes) {
      if (bytes === null || bytes === undefined) return '-'
      const b = Number(bytes)
      if (b < 1024 * 1024) return (b / 1024).toFixed(1) + 'KB'
      return (b / (1024 * 1024)).toFixed(1) + 'MB'
    }
  }
}
</script>

<style scoped>
::v-deep .el-table .row-newest td { background-color: #f0f9eb; }
</style>
