<!--
  文件：admin/src/views/approval/Phrases.vue
  功能：常用语管理（统一审批管理）— 搜索 / 列表 / 新增编辑 / 删除 / 使用次数
  权限：approval:task:view
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>统一审批</el-breadcrumb-item>
      <el-breadcrumb-item>常用语管理</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="常用语"><el-input v-model="query.keyword" placeholder="请输入常用语关键词" clearable style="width:200px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="创建时间">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'approval:task:view'" type="primary" size="small" icon="el-icon-plus" @click="openAdd">新增常用语</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条常用语</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无常用语，请点击新增常用语添加">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="常用语内容" min-width="300" show-overflow-tooltip>
        <template slot-scope="s">{{ s.row.phrase_content || s.row.content }}</template>
      </el-table-column>
      <el-table-column label="使用次数" width="120" align="center">
        <template slot-scope="s">
          <span v-if="s.row.use_count > 0" class="count-num">{{ s.row.use_count }}</span>
          <span v-else class="count-zero">-</span>
        </template>
      </el-table-column>
      <el-table-column prop="sort_order" label="排序" width="100" align="center" />
      <el-table-column prop="created_at" label="创建时间" width="160" align="center" />
      <el-table-column label="操作" width="180" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-if="!s.row.is_default" v-permission="'approval:task:view'" type="text" size="mini" @click="openEdit(s.row)">编辑</el-button>
          <el-button v-if="!s.row.is_default" v-permission="'approval:task:view'" type="text" size="mini" class="danger-text" @click="handleDelete(s.row)">删除</el-button>
          <span v-if="s.row.is_default" class="default-tag">系统默认</span>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="form.id ? '编辑常用语' : '新增常用语'" :visible.sync="dialogVisible" width="550px" :close-on-click-modal="false" append-to-body>
      <el-form ref="form" :model="form" :rules="formRules" label-width="100px" size="small">
        <el-form-item label="常用语内容" prop="phrase_content">
          <el-input v-model="form.phrase_content" type="textarea" :rows="3" maxlength="200" show-word-limit placeholder="请输入常用审批意见，如：同意，已阅，请重新提交等" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort_order" :min="0" :max="999" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="200" placeholder="请输入备注信息" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取 消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保 存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getCommonPhrases, saveCommonPhrase, deleteCommonPhrase } from '@/api/approval'

export default {
  name: 'ApprovalPhrases',
  data () {
    return {
      query: { keyword: '', dateRange: [] },
      list: [], total: 0, page: 1, pageSize: 10, loading: false,
      dialogVisible: false, saving: false,
      form: { id: 0, phrase_content: '', sort_order: 0, remark: '' },
      formRules: {
        phrase_content: [{ required: true, message: '请输入常用语内容', trigger: 'blur' }, { max: 200, message: '不能超过 200 字', trigger: 'blur' }]
      }
    }
  },
  created () { this.loadData() },
  methods: {
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getCommonPhrases(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { keyword: '', dateRange: [] }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    openAdd () {
      this.form = { id: 0, phrase_content: '', sort_order: 0, remark: '' }
      this.dialogVisible = true
      this.$nextTick(() => this.$refs.form && this.$refs.form.clearValidate())
    },
    openEdit (row) {
      this.form = { id: row.id, phrase_content: row.phrase_content || row.content, sort_order: row.sort_order, remark: row.remark || '' }
      this.dialogVisible = true
      this.$nextTick(() => this.$refs.form && this.$refs.form.clearValidate())
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) return
        this.saving = true
        saveCommonPhrase(this.form).then(r => {
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadData() } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该常用语吗？删除后不可恢复', '删除常用语', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteCommonPhrase(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadData() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.danger-text { color: #F56C6C; }
.count-num { color: #409EFF; font-weight: 600; }
.count-zero { color: #c0c4cc; }
.default-tag { color: #909399; font-size: 12px; }
</style>
