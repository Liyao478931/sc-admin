<template>
  <el-dialog :title="'分类下的工具列表' + (categoryName ? '：' + categoryName : '')" :visible.sync="visible" width="700px" append-to-body>
    <el-table :data="toolList" size="small" stripe v-loading="loading">
      <el-table-column prop="tool_name" label="工具名称" min-width="130" show-overflow-tooltip />
      <el-table-column prop="tool_display_name" label="显示名称" min-width="130" show-overflow-tooltip />
      <el-table-column prop="method" label="请求方法" width="90" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="methodType(s.row.method)">{{ s.row.method }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="api_path" label="API路径" min-width="180" show-overflow-tooltip />
      <el-table-column label="状态" width="80" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
        </template>
      </el-table-column>
    </el-table>
    <el-empty v-if="!loading && !toolList.length" description="该分类下暂无启用工具" :image-size="60" />
    <el-pagination v-if="total > pageSize" class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" @current-change="p => { page = p; loadTools() }" />
    <div slot="footer">
      <el-button size="small" type="primary" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getToolCategoryTools } from '../../../../api/aiToolCategory'

export default {
  name: 'CategoryToolsDialog',
  data() {
    return {
      visible: false,
      loading: false,
      categoryKey: '',
      categoryName: '',
      toolList: [],
      total: 0,
      page: 1,
      pageSize: 20
    }
  },
  methods: {
    methodType(m) { return { GET: 'primary', POST: 'success', PUT: 'warning', DELETE: 'danger' }[m] || 'info' },
    open(categoryKey, categoryName) {
      this.categoryKey = categoryKey
      this.categoryName = categoryName || ''
      this.page = 1
      this.visible = true
      this.loadTools()
    },
    async loadTools() {
      this.loading = true
      try {
        const res = await getToolCategoryTools({ category_key: this.categoryKey, page: this.page, limit: this.pageSize })
        this.toolList = res.data.list || []
        this.total = res.data.total || 0
      } catch (e) {}
      this.loading = false
    }
  }
}
</script>

<style scoped>
.pager { margin-top: 10px; text-align: right; }
</style>
