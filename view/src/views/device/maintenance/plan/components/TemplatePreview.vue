<template>
  <div class="template-preview">
    <el-table :data="items" size="small" border stripe>
      <el-table-column type="index" label="#" width="50" />
      <el-table-column prop="item_name" label="项目名称" min-width="140" />
      <el-table-column prop="operation_content" label="操作内容" min-width="160" show-overflow-tooltip />
      <el-table-column prop="check_standard" label="检查标准" min-width="140" show-overflow-tooltip />
      <el-table-column label="必做" width="60" align="center">
        <template slot-scope="{row}"><el-tag :type="row.is_required ? 'success' : 'info'" size="mini">{{ row.is_required ? '是' : '否' }}</el-tag></template>
      </el-table-column>
      <el-table-column label="严重异常" width="80" align="center">
        <template slot-scope="{row}"><el-tag :type="row.is_serious ? 'danger' : 'info'" size="mini">{{ row.is_serious ? '是' : '否' }}</el-tag></template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script>
export default {
  name: 'TemplatePreview',
  props: {
    items: { type: Array, default: () => [] }
  }
}
</script>

<style scoped>
.template-preview { margin-bottom: 12px; }
</style>
