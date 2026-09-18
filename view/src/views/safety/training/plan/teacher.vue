<template>
  <div class="training-teacher-page">
    <!-- 筛选 + 工具栏 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item><el-input v-model="filters.keyword" placeholder="按讲师姓名搜索" clearable style="width:160px" @keyup.enter.native="onSearch" /></el-form-item>
        <el-form-item>
          <el-input v-model="filters.department" placeholder="按部门筛选" clearable style="width:140px" @keyup.enter.native="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option label="启用" value="1" /><el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <el-button v-if="hasPerm('safety:training:plan:add')" size="small" type="primary" icon="el-icon-plus" @click="openAdd">新增讲师</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="teacher_code" label="讲师编号" width="170" />
        <el-table-column label="讲师姓名" min-width="110">
          <template slot-scope="{ row }">
            <div style="display:flex;align-items:center;gap:6px">
              <el-avatar v-if="row.avatar" :src="row.avatar" :size="26" />
              <el-avatar v-else :size="26" icon="el-icon-user" />
              <span>{{ row.teacher_name }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="department" label="所属部门" min-width="110" />
        <el-table-column prop="expertise" label="擅长领域" min-width="160" show-overflow-tooltip />
        <el-table-column prop="phone" label="联系电话" width="120" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:training:plan:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('safety:training:plan:delete')" size="mini" type="text" style="color:#F56C6C" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑讲师' : '新增讲师'" :visible.sync="dialogVisible" width="550px" append-to-body>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px" size="small">
        <el-form-item label="讲师编号">
          <el-input :value="form.teacher_code || '自动生成'" disabled />
        </el-form-item>
        <el-form-item label="讲师姓名" prop="teacher_name"><el-input v-model="form.teacher_name" /></el-form-item>
        <el-form-item label="头像">
          <el-upload class="avatar-uploader" action="/api/upload" :headers="uploadHeaders" :show-file-list="false" accept="image/jpeg,image/png,image/gif,image/webp" :before-upload="beforeAvatarUpload" :on-success="onAvatarSuccess">
            <img v-if="form.avatar" :src="form.avatar" class="avatar-img" />
            <i v-else class="el-icon-plus avatar-uploader-icon"></i>
          </el-upload>
          <div style="color:#909399;font-size:12px">支持 jpg/png/gif/webp，不超过 2MB</div>
        </el-form-item>
        <el-form-item label="所属部门"><el-input v-model="form.department" /></el-form-item>
        <el-form-item label="擅长领域"><el-input v-model="form.expertise" /></el-form-item>
        <el-form-item label="联系电话"><el-input v-model="form.phone" maxlength="20" /></el-form-item>
        <el-form-item label="讲师简介"><el-input v-model="form.intro" type="textarea" :rows="3" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="状态"><el-switch v-model="form.status" :active-value="1" :inactive-value="0" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getTeacherList, addTeacher, editTeacher, deleteTeacher } from '@/api/safetyTraining'
import { getToken } from '@/utils/auth'

export default {
  name: 'SafetyTrainingTeacher',
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', department: '', status: '' },
      dialogVisible: false, saving: false,
      form: { id: 0, teacher_code: '', teacher_name: '', department: '', expertise: '', phone: '', intro: '', avatar: '', sort: 0, status: 1 },
      rules: { teacher_name: [{ required: true, message: '请输入讲师姓名', trigger: 'blur' }] }
    }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } }
  },
  created() {
    // 权限为空时刷新（避免新加权限未及时拉取导致按钮不显示）
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadList()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getTeacherList({
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || '',
          department: this.filters.department || '',
          status: this.filters.status || ''
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() { this.filters = { keyword: '', department: '', status: '' }; this.page = 1; this.loadList() },
    openAdd() { this.form = { id: 0, teacher_code: '', teacher_name: '', department: '', expertise: '', phone: '', intro: '', avatar: '', sort: 0, status: 1 }; this.dialogVisible = true },
    openEdit(row) { this.form = { ...row }; this.dialogVisible = true },
    beforeAvatarUpload(file) {
      const okExt = /\.(jpg|jpeg|png|gif|webp)$/i.test(file.name)
      const okSize = file.size <= 2 * 1024 * 1024
      if (!okExt) this.$message.error('仅支持 jpg/png/gif/webp 格式')
      if (!okSize) this.$message.error('图片不能超过 2MB')
      return okExt && okSize
    },
    onAvatarSuccess(res) {
      if (res.code === 0 && res.data && res.data.url) this.form.avatar = res.data.url
      else this.$message.error('头像上传失败')
    },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const r = this.form.id ? await editTeacher(this.form.id, this.form) : await addTeacher(this.form)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadList() }
        } catch (e) {}
        this.saving = false
      })
    },
    handleDelete(row) {
      this.$confirm(`确认删除讲师「${row.teacher_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteTeacher(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.avatar-uploader { border: 1px dashed #d9d9d9; border-radius: 6px; cursor: pointer; width: 80px; height: 80px; display: flex; align-items: center; justify-content: center; overflow: hidden; }
.avatar-uploader-icon { font-size: 24px; color: #8c939d; }
.avatar-img { width: 100%; height: 100%; object-fit: cover; }
</style>
