<template>
  <div class="crmeb-diy-list">
    <div class="page-header">
      <div><h2>页面装修</h2><span class="sub-title">管理移动端 DIY 装修页面</span></div>
      <el-button type="primary" size="medium" icon="el-icon-plus" @click="handleCreate">新建页面</el-button>
    </div>

    <div class="filter-bar">
      <el-input v-model="searchKeyword" size="small" placeholder="搜索页面名称" clearable style="width:240px" @keyup.enter.native="loadList" />
      <el-button size="small" type="info" @click="loadList">搜索</el-button>
    </div>

    <div class="table-container">
      <el-table :data="list" size="small" border stripe v-loading="loading" style="width:100%">
        <el-table-column prop="id" label="ID" width="60" align="center" />
        <el-table-column prop="name" label="页面名称" width="150" show-overflow-tooltip />
        <el-table-column prop="title" label="标题" min-width="150" show-overflow-tooltip />
        <el-table-column label="状态" width="100" align="center">
          <template slot-scope="{row}">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">{{ row.status === 1 ? '已启用' : '未启用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="默认" width="80" align="center">
          <template slot-scope="{row}">
            <el-tag v-if="row.is_default === 1" type="warning" size="small">默认</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="update_time" label="更新时间" width="160" />
        <el-table-column label="操作" width="280" align="center" fixed="right">
          <template slot-scope="{row}">
            <el-button size="mini" type="text" @click="editPage(row)">编辑</el-button>
            <el-button v-if="row.status !== 1" size="mini" type="text" style="color:#67c23a" @click="enablePage(row)">启用</el-button>
            <el-button size="mini" type="text" @click="copyPage(row)">复制</el-button>
            <el-button v-if="row.is_default !== 1" size="mini" type="text" style="color:#f56c6c" @click="delPage(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div class="pagination-wrap">
      <el-pagination
        :current-page="page" :page-sizes="[10,20,50]" :page-size="limit" :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="s => { limit = s; loadList() }"
        @current-change="p => { page = p; loadList() }"
      />
    </div>

    <!-- 新建页面对话框 -->
    <el-dialog title="新建页面" :visible.sync="showCreate" width="420px">
      <el-form label-width="80px" size="small">
        <el-form-item label="页面名称">
          <el-input v-model="createForm.name" placeholder="请输入页面名称" maxlength="15" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="showCreate = false">取消</el-button>
        <el-button size="small" type="primary" :loading="creating" @click="handleCreateSubmit">确定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { diyLst, diySave, diyDel, diyStatus, diyCopy } from '@/api/diy'

export default {
  name: 'CrmebDiyList',
  data() {
    return {
      list: [], total: 0, page: 1, limit: 10,
      searchKeyword: '', loading: false,
      showCreate: false, creating: false,
      createForm: { name: '' },
    }
  },
  created() { this.loadList() },
  methods: {
    async loadList() {
      this.loading = true
      try {
        const res = await diyLst({ page: this.page, limit: this.limit, name: this.searchKeyword })
        if (res.code === 0) {
          this.list = res.data.list || []
          this.total = res.data.total || 0
        }
      } catch (e) {}
      this.loading = false
    },
    editPage(row) {
      this.$router.push(`/diy/editor/${row.id}`)
    },
    async enablePage(row) {
      try {
        await diyStatus(row.id)
        this.$message.success('启用成功')
        this.loadList()
      } catch (e) { this.$message.error(e.message || '操作失败') }
    },
    async copyPage(row) {
      try {
        await diyCopy(row.id)
        this.$message.success('复制成功')
        this.loadList()
      } catch (e) { this.$message.error(e.message || '复制失败') }
    },
    delPage(row) {
      this.$confirm(`确定删除页面「${row.name}」吗？`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          await diyDel(row.id)
          this.$message.success('删除成功')
          this.loadList()
        } catch (e) { this.$message.error(e.message || '删除失败') }
      }).catch(() => {})
    },
    handleCreate() {
      this.createForm.name = ''
      this.showCreate = true
    },
    async handleCreateSubmit() {
      if (!this.createForm.name) { this.$message.warning('请输入页面名称'); return }
      this.creating = true
      try {
        const res = await diySave(0, { name: this.createForm.name, title: this.createForm.name, value: {} })
        if (res.code === 0) {
          this.$message.success('创建成功')
          this.showCreate = false
          this.loadList()
          this.$router.push(`/diy/editor/${res.data.id}`)
        }
      } catch (e) { this.$message.error(e.message || '创建失败') }
      this.creating = false
    },
  },
}
</script>

<style scoped>
.crmeb-diy-list { padding: 0; background: #f5f7fa; min-height: 100%; }
.page-header { height: 56px; background: #fff; border-bottom: 1px solid #EBEEF5; padding: 0 24px; display: flex; align-items: center; justify-content: space-between; }
.page-header h2 { font-size: 20px; font-weight: bold; color: #303133; margin: 0; display: inline; }
.sub-title { font-size: 13px; color: #909399; margin-left: 12px; }
.filter-bar { height: 48px; background: #fff; border-radius: 8px; margin: 12px 24px 0; padding: 0 24px; display: flex; align-items: center; gap: 8px; }
.table-container { background: #fff; margin: 0 24px; padding: 0; }
.pagination-wrap { display: flex; justify-content: flex-end; padding: 16px 24px; background: #fff; margin: 0 24px 24px; border-top: 1px solid #EBEEF5; }
</style>
