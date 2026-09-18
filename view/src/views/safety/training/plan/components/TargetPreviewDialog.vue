<template>
  <el-dialog title="培训对象人员名单" :visible.sync="dialogVisible" width="700px" append-to-body @open="loadUsers">
    <div v-loading="loading">
      <div style="margin-bottom:12px;color:#909399;font-size:13px">共 <b style="color:#409EFF">{{ total }}</b> 人</div>
      <el-table :data="list" size="small" border stripe max-height="480">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="name" label="姓名" min-width="100" />
        <el-table-column prop="username" label="登录名" min-width="100" />
        <el-table-column prop="department_name" label="所属部门" min-width="140">
          <template slot-scope="{ row }">{{ row.department_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="position_name" label="岗位" min-width="140">
          <template slot-scope="{ row }">{{ row.position_name || '-' }}</template>
        </el-table-column>
      </el-table>
      <el-empty v-if="!loading && !list.length" description="暂无人员" />
    </div>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getTargetUsers } from '@/api/safetyTraining'

export default {
  name: 'TargetPreviewDialog',
  props: {
    visible: Boolean,
    targetType: { type: String, default: 'all' },
    targetIds: { type: Array, default: () => [] }
  },
  data() {
    return { dialogVisible: this.visible, loading: false, list: [], total: 0 }
  },
  watch: {
    visible(val) { this.dialogVisible = val },
    dialogVisible(val) { this.$emit('update:visible', val) }
  },
  methods: {
    async loadUsers() {
      this.loading = true
      try {
        const r = await getTargetUsers({ target_type: this.targetType, target_ids: (this.targetIds || []).join(',') })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    }
  }
}
</script>
