<!-- 文件：admin/src/views/ai/knowledge/components/DocumentList.vue -->
<!-- 已上传文档列表：搜索/类型筛选/状态筛选/批量删除/批量重试/分页 -->
<template>
  <div class="doc-list">
    <div class="dl-toolbar">
      <el-input v-model="filters.keyword" placeholder="搜索文档名称" clearable size="small" style="width:200px"
        @keyup.enter.native="doSearch" @clear="doSearch" />
      <el-select v-model="filters.doc_type" placeholder="全部类型" clearable size="small" style="width:110px" @change="doSearch">
        <el-option label="PDF" value="pdf" />
        <el-option label="Word" value="word" />
        <el-option label="Excel" value="excel" />
        <el-option label="PPT" value="ppt" />
        <el-option label="TXT" value="txt" />
        <el-option label="MD" value="md" />
        <el-option label="HTML" value="html" />
      </el-select>
      <el-select v-model="filters.status" placeholder="全部状态" clearable size="small" style="width:110px" @change="doSearch">
        <el-option label="待处理" value="pending" />
        <el-option label="处理中" value="processing" />
        <el-option label="已完成" value="completed" />
        <el-option label="失败" value="failed" />
      </el-select>
      <el-button size="small" type="primary" icon="el-icon-search" @click="doSearch">搜索</el-button>
      <div class="dl-right">
        <el-button size="small" type="danger" icon="el-icon-delete" :disabled="!selection.length" @click="batchDelete">批量删除</el-button>
        <el-button size="small" icon="el-icon-refresh" :disabled="!selection.length" @click="batchRetry">批量重试</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="$emit('refresh')">刷新</el-button>
      </div>
    </div>

    <el-table :data="list" size="small" stripe v-loading="loading" @selection-change="s => selection = s">
      <el-table-column type="selection" width="40" />
      <el-table-column label="文档名称" min-width="220" show-overflow-tooltip>
        <template slot-scope="s">
          <el-link type="primary" :underline="false" @click="openDetail(s.row)">{{ s.row.doc_name }}</el-link>
        </template>
      </el-table-column>
      <el-table-column label="类型" width="80" align="center">
        <template slot-scope="s">
          <el-tag size="mini" type="info">{{ typeText(s.row.doc_type) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="大小" width="100" align="center">
        <template slot-scope="s">{{ formatSize(s.row.doc_size) }}</template>
      </el-table-column>
      <el-table-column prop="uploaded_by_name" label="上传人" width="100" align="center" />
      <el-table-column prop="upload_time" label="上传时间" width="160" />
      <el-table-column label="向量化状态" width="140" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="statusType(s.row.status)">{{ statusText(s.row.status) }}</el-tag>
          <div v-if="s.row.status === 'failed' && s.row.error_message" class="dl-err" :title="s.row.error_message">
            <i class="el-icon-warning"></i>{{ truncate(s.row.error_message, 12) }}
          </div>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="130" align="center">
        <template slot-scope="s">
          <el-button size="mini" type="text" icon="el-icon-refresh" :disabled="s.row.status === 'processing'"
            @click="$emit('retry', s.row)">重试</el-button>
          <el-button size="mini" type="text" icon="el-icon-delete" @click="$emit('delete', s.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pager">
      <el-pagination background layout="total, prev, pager, next" :total="total"
        :page-size="limit" :current-page="page" small
        @current-change="p => { page = p; $emit('page-change', p) }" />
    </div>

    <!-- 文档详情弹窗 -->
    <el-dialog title="文档详情" :visible.sync="detailVisible" width="560px" top="12vh">
      <el-descriptions v-if="detail" :column="2" size="small" border>
        <el-descriptions-item label="文档名称" :span="2">{{ detail.doc_name }}</el-descriptions-item>
        <el-descriptions-item label="文档类型">{{ typeText(detail.doc_type) }}</el-descriptions-item>
        <el-descriptions-item label="文档大小">{{ formatSize(detail.doc_size) }}</el-descriptions-item>
        <el-descriptions-item label="切片数量">{{ detail.chunk_count || 0 }}</el-descriptions-item>
        <el-descriptions-item label="处理进度">{{ detail.progress || 0 }}%</el-descriptions-item>
        <el-descriptions-item label="上传人">{{ detail.uploaded_by_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="上传时间">{{ detail.upload_time }}</el-descriptions-item>
        <el-descriptions-item label="处理时间">{{ detail.process_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="向量化状态">
          <el-tag size="mini" :type="statusType(detail.status)">{{ statusText(detail.status) }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="文档ID">{{ detail.doc_id }}</el-descriptions-item>
        <el-descriptions-item v-if="detail.error_message" label="错误信息" :span="2">
          <span class="dl-detail-err">{{ detail.error_message }}</span>
        </el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'KbDocumentList',
  props: {
    list: { type: Array, default: () => [] },
    total: { type: Number, default: 0 },
    page: { type: Number, default: 1 },
    limit: { type: Number, default: 10 },
    loading: { type: Boolean, default: false }
  },
  data () {
    return {
      filters: { keyword: '', doc_type: '', status: '' },
      selection: [],
      detailVisible: false,
      detail: null
    }
  },
  methods: {
    typeText (t) {
      return { pdf: 'PDF', word: 'Word', excel: 'Excel', ppt: 'PPT', txt: 'TXT', md: 'MD', html: 'HTML' }[t] || t || '-'
    },
    statusText (s) {
      return { pending: '待处理', processing: '处理中', completed: '已完成', failed: '失败' }[s] || s || '-'
    },
    statusType (s) {
      return { pending: 'info', processing: 'primary', completed: 'success', failed: 'danger' }[s] || 'info'
    },
    formatSize (bytes) {
      const b = parseInt(bytes, 10)
      if (isNaN(b) || b <= 0) return '0 B'
      if (b < 1024) return b + ' B'
      if (b < 1048576) return (b / 1024).toFixed(1) + ' KB'
      return (b / 1048576).toFixed(2) + ' MB'
    },
    truncate (s, n) {
      if (!s) return ''
      return s.length > n ? s.slice(0, n) + '...' : s
    },
    doSearch () { this.$emit('search', this.filters) },
    openDetail (row) {
      this.detail = row
      this.detailVisible = true
    },
    batchDelete () {
      if (!this.selection.length) return
      this.$emit('batch-delete', this.selection.map(s => s.doc_id))
    },
    batchRetry () {
      const ids = this.selection.filter(s => s.status === 'failed').map(s => s.doc_id)
      if (!ids.length) { this.$emit('toast', '仅失败的文档可重新处理'); return }
      this.$emit('batch-retry', ids)
    }
  }
}
</script>

<style scoped>
.doc-list { }
.dl-toolbar { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; flex-wrap: wrap; }
.dl-right { margin-left: auto; display: flex; gap: 8px; }
.dl-err { font-size: 12px; color: #F56C6C; cursor: pointer; margin-top: 2px; }
.dl-detail-err { color: #F56C6C; }
.pager { margin-top: 12px; text-align: right; }
</style>
