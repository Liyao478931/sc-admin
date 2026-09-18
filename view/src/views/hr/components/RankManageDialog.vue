<template>
  <el-dialog title="职级管理" :visible="visible" @update:visible="$emit('update:visible', $event)" width="700px" top="8vh" @open="loadList">
    <div class="rank-toolbar">
      <el-button type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增职级</el-button>
      <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
      <span class="rank-tip">职级用于员工档案记录与展示（不涉及工资计算）</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" stripe>
      <el-table-column prop="rank_name" label="职级名称" min-width="120" />
      <el-table-column prop="rank_code" label="编码" width="90" align="center" />
      <el-table-column prop="sort" label="排序" width="70" align="center" />
      <el-table-column label="状态" width="80" align="center">
        <template slot-scope="{ row }">
          <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180" align="center">
        <template slot-scope="{ row }">
          <el-button type="text" size="mini" @click="openForm(row)">编辑</el-button>
          <el-button type="text" size="mini" @click="toggle(row)">{{ row.status === 1 ? '停用' : '启用' }}</el-button>
          <el-button type="text" size="mini" style="color:#F56C6C" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, prev, pager, next" :total="total"
      :current-page="page" :page-size="limit"
      @current-change="p => { page = p; loadList() }" />

    <!-- 新增/编辑表单 -->
    <el-dialog :title="form.id ? '编辑职级' : '新增职级'" :visible.sync="formVisible" width="420px" append-to-body>
      <el-form :model="form" label-width="90px" size="small">
        <el-form-item label="职级名称"><el-input v-model="form.rank_name" placeholder="如：一级科员" maxlength="50" /></el-form-item>
        <el-form-item label="职级编码"><el-input v-model="form.rank_code" placeholder="如：G1 / W1" maxlength="20" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="状态"><el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="submit">保存</el-button>
      </span>
    </el-dialog>
  </el-dialog>
</template>

<script>
import { getRankList, addRank, editRank, deleteRank, toggleRank } from '@/api/profile'

export default {
  name: 'RankManageDialog',
  props: { visible: { type: Boolean, default: false } },
  data () {
    return {
      list: [], total: 0, page: 1, limit: 10, loading: false,
      formVisible: false, saving: false,
      form: { id: 0, rank_name: '', rank_code: '', sort: 0, status: 1 }
    }
  },
  created () {
    // 组件被 v-if 创建时立即加载数据（避免依赖 el-dialog @open 事件在首开时不触发）
    this.loadList()
  },
  watch: {
    visible (val) {
      if (val) this.loadList()
    }
  },
  methods: {
    async loadList () {
      this.loading = true
      try {
        const r = await getRankList({ page: this.page, limit: this.limit })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    openForm (row) {
      this.form = row ? { id: row.id, rank_name: row.rank_name, rank_code: row.rank_code, sort: row.sort || 0, status: row.status } : { id: 0, rank_name: '', rank_code: '', sort: 0, status: 1 }
      this.formVisible = true
    },
    async submit () {
      if (!this.form.rank_name) { this.$message.warning('请输入职级名称'); return }
      if (!this.form.rank_code) { this.$message.warning('请输入职级编码'); return }
      this.saving = true
      try {
        const d = { rank_name: this.form.rank_name, rank_code: this.form.rank_code, sort: this.form.sort, status: this.form.status }
        const r = this.form.id ? await editRank(this.form.id, d) : await addRank(d)
        if (r.code === 0) {
          this.$message.success('保存成功')
          this.formVisible = false
          this.loadList()
          this.$emit('saved')
        }
      } catch (e) {} finally { this.saving = false }
    },
    async toggle (row) {
      const target = row.status === 1 ? 0 : 1
      try {
        const r = await toggleRank(row.id, target)
        if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.loadList() }
      } catch (e) {}
    },
    remove (row) {
      this.$confirm(`确定删除职级「${row.rank_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteRank(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadList(); this.$emit('saved') }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.rank-toolbar { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; }
.rank-tip { font-size: 12px; color: #909399; margin-left: 8px; }
.pager { margin-top: 12px; text-align: right; }
</style>
