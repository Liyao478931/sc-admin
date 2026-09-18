<template>
  <div class="ann-admin">
    <div class="page-header">
      <div><h2>公告管理</h2><p class="page-subtitle">发布企业通知、紧急通告与活动公告 · 共 {{ total }} 条</p></div>
      <div style="display:flex;gap:8px">
        <el-select v-model="filterCategory" size="small" placeholder="类型" clearable style="width:110px" @change="reload">
          <el-option label="通知" value="notice" /><el-option label="紧急" value="urgent" /><el-option label="活动" value="activity" />
        </el-select>
        <el-select v-model="filterStatus" size="small" placeholder="状态" clearable style="width:110px" @change="reload">
          <el-option label="已发布" :value="1" /><el-option label="草稿" :value="0" />
        </el-select>
        <el-input v-model="keyword" size="small" placeholder="搜索公告标题" prefix-icon="el-icon-search" clearable style="width:220px" @keyup.enter.native="reload" @clear="reload" />
        <el-button v-if="hasPerm('announcement:add')" type="primary" size="small" icon="el-icon-plus" @click="openAdd">新增公告</el-button>
      </div>
    </div>

    <div class="ann-body" v-loading="loading">
      <el-table :data="list" stripe style="width:100%">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column label="标题" min-width="240">
          <template slot-scope="{ row }">
            <span class="top-badge" v-if="row.is_top == 1">置顶</span>
            <span>{{ row.title }}</span>
          </template>
        </el-table-column>
        <el-table-column label="类型" width="100">
          <template slot-scope="{ row }">
            <el-tag :type="row.category === 'urgent' ? 'danger' : (row.category === 'activity' ? 'warning' : 'primary')" size="mini">{{ row.category_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="置顶" width="90">
          <template slot-scope="{ row }">
            <el-switch :value="row.is_top == 1" @change="v => doToggle(row, 'is_top', v ? 1 : 0)" :disabled="!hasPerm('announcement:edit')" />
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template slot-scope="{ row }">
            <el-switch :value="row.status == 1" active-text="发布" inactive-text="草稿" @change="v => doToggle(row, 'status', v ? 1 : 0)" :disabled="!hasPerm('announcement:edit')" />
          </template>
        </el-table-column>
        <el-table-column prop="publisher_name" label="发布人" width="100">
          <template slot-scope="{ row }">{{ row.publisher_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="published_at" label="发布时间" width="160">
          <template slot-scope="{ row }">{{ row.published_at || '-' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('announcement:edit')" type="text" size="small" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('announcement:delete')" type="text" size="small" class="danger" @click="doDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="limit" :current-page.sync="page" @current-change="load" />
      </div>
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑公告' : '新增公告'" :visible.sync="showForm" width="640px" @closed="resetForm">
      <el-form :model="form" label-width="80px" size="small">
        <el-form-item label="标题" required>
          <el-input v-model="form.title" maxlength="200" placeholder="请输入公告标题" />
        </el-form-item>
        <el-form-item label="类型">
          <el-radio-group v-model="form.category">
            <el-radio label="notice">通知</el-radio>
            <el-radio label="urgent">紧急</el-radio>
            <el-radio label="activity">活动</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="内容">
          <el-input v-model="form.content" type="textarea" :rows="8" placeholder="支持 HTML 富文本（如 <p>段落</p><ul><li>条目</li></ul>）" />
        </el-form-item>
        <el-form-item label="置顶">
          <el-switch v-model="form.is_top" :active-value="1" :inactive-value="0" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :label="1">发布</el-radio>
            <el-radio :label="0">草稿</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="showForm = false">取消</el-button>
        <el-button type="primary" size="small" :loading="saving" @click="save">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getAnnouncementList, addAnnouncement, editAnnouncement, toggleAnnouncement, deleteAnnouncement } from '@/api/announcement'

export default {
  name: 'AnnouncementAdmin',
  data() {
    return {
      loading: false, saving: false,
      list: [], total: 0, page: 1, limit: 20,
      keyword: '', filterCategory: '', filterStatus: '',
      showForm: false, form: { id: 0, title: '', content: '', category: 'notice', is_top: 0, status: 1 },
    }
  },
  created() { this.load() },
  methods: {
    hasPerm(code) { const p = (this.$store.state.user && this.$store.state.user.permissions) || []; return p.indexOf(code) > -1 },
    async load() {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.limit }
        if (this.keyword) params.keyword = this.keyword
        if (this.filterCategory) params.category = this.filterCategory
        if (this.filterStatus !== '') params.status = this.filterStatus
        const r = await getAnnouncementList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
        else this.$message.error(r.msg || '加载失败')
      } catch (e) { this.$message.error('加载失败') } finally { this.loading = false }
    },
    reload() { this.page = 1; this.load() },
    openAdd() { this.form = { id: 0, title: '', content: '', category: 'notice', is_top: 0, status: 1 }; this.showForm = true },
    openEdit(row) { this.form = { id: row.id, title: row.title, content: row.content || '', category: row.category, is_top: row.is_top, status: row.status }; this.showForm = true },
    resetForm() { this.form = { id: 0, title: '', content: '', category: 'notice', is_top: 0, status: 1 } },
    async save() {
      if (!this.form.title.trim()) return this.$message.warning('请填写公告标题')
      this.saving = true
      try {
        const r = this.form.id ? await editAnnouncement(this.form) : await addAnnouncement(this.form)
        if (r.code === 0) { this.$message.success('保存成功'); this.showForm = false; this.load() }
        else this.$message.error(r.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') } finally { this.saving = false }
    },
    async doToggle(row, field, val) {
      try {
        const r = await toggleAnnouncement({ id: row.id, field, value: val })
        if (r.code === 0) { this.$message.success('操作成功'); this.load() }
        else this.$message.error(r.msg || '操作失败')
      } catch (e) { this.$message.error('操作失败') }
    },
    async doDelete(row) {
      try {
        await this.$confirm(`确定删除公告「${row.title}」？`, '提示', { type: 'warning' })
        const r = await deleteAnnouncement(row.id)
        if (r.code === 0) { this.$message.success('删除成功'); this.load() }
        else this.$message.error(r.msg || '删除失败')
      } catch (e) {}
    },
  },
}
</script>

<style scoped>
.ann-admin { padding: 20px; height: 100%; display: flex; flex-direction: column; background: #f0f2f5; gap: 16px; }
.page-header { display: flex; justify-content: space-between; align-items: flex-start; }
.page-header h2 { margin: 0; font-size: 20px; font-weight: 700; color: #303133; }
.page-subtitle { margin: 4px 0 0; font-size: 13px; color: #909399; }
.ann-body { flex: 1; background: #fff; border-radius: 8px; padding: 16px 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); overflow: auto; }
.top-badge { background: linear-gradient(135deg, #F56C6C, #E64340); color: #fff; font-size: 12px; padding: 1px 6px; border-radius: 4px; margin-right: 6px; }
.pager { display: flex; justify-content: flex-end; margin-top: 14px; }
.danger { color: #F56C6C; }
</style>
