<template>
  <div class="paths-page">
    <!-- 顶部标题行 -->
    <div class="page-header">
      <div>
        <h2>路径管理</h2>
        <span class="sub-title">管理所有移动端页面路径 · 共 {{ total }} 条</span>
      </div>
      <el-button v-if="hasPerm('app:path:create')" type="primary" size="medium" icon="el-icon-plus" @click="openForm()">新增路径</el-button>
    </div>

    <!-- 搜索筛选栏 -->
    <div class="filter-bar">
      <div class="filter-left">
        <el-select v-model="filter.platform" placeholder="全部平台" size="small" clearable @change="loadList" style="width:140px">
          <el-option label="全部" :value="null" />
          <el-option v-for="item in platformOptions" :key="item.value" :label="item.label" :value="Number(item.value)" />
        </el-select>
      </div>
      <div class="filter-right">
        <el-input v-model="filter.keyword" size="small" placeholder="搜索路径名称或地址" prefix-icon="el-icon-search" clearable style="width:240px" @input="onSearchInput" />
      </div>
    </div>

    <!-- 数据表格 -->
    <div class="table-container">
      <el-table :data="list" size="small" border stripe style="width:100%" :row-style="{height:'44px'}" @sort-change="onSortChange" highlight-current-row>
        <el-table-column type="index" label="#" width="60" align="center" />
        <el-table-column prop="name" label="路径名称" width="150" sortable="custom">
          <template slot-scope="{row}"><strong>{{ row.name }}</strong></template>
        </el-table-column>
        <el-table-column prop="path" label="路径地址" min-width="240" sortable="custom">
          <template slot-scope="{row}">
            <span style="font-family:Consolas,monospace;color:#909399;font-size:12px">{{ row.path }}</span>
            <el-button type="text" size="mini" icon="el-icon-document-copy" style="margin-left:4px" @click="copyPath(row.path)" />
          </template>
        </el-table-column>
        <el-table-column label="平台" width="100" align="center">
          <template slot-scope="{row}">
            <el-tag :type="platformTagType(row.platform)" size="small" effect="plain">{{ row.platform_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="页面类型" width="100" align="center">
          <template slot-scope="{row}">
            <el-tag :type="row.page_type === 2 ? 'primary' : 'info'" size="small" effect="plain">{{ row.page_type_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="需要登录" width="90" align="center">
          <template slot-scope="{row}">
            <el-tag :type="row.require_auth ? 'primary' : 'info'" size="mini">{{ row.require_auth ? '是' : '否' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="关联页面" width="100" align="center">
          <template slot-scope="{row}">
            <el-tag v-if="getDiyPageKey(row)" type="success" size="mini" @click="editDiyPage(row)" style="cursor:pointer">可编辑</el-tag>
            <el-tag v-else type="info" size="mini">无</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{row}">
            <el-switch :value="!!row.status" @change="v => toggleStatus(row, v)" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('app:path:edit')" size="mini" type="text" icon="el-icon-edit" @click="openForm(row)">编辑</el-button>
            <el-button v-if="getDiyPageKey(row) && hasPerm('app:page:edit')" size="mini" type="text" icon="el-icon-document" style="color:#67C23A" @click="editDiyPage(row)">编辑页面</el-button>
            <el-button v-if="hasPerm('app:path:delete')" size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="confirmDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="pagination-wrap">
      <el-pagination
        :current-page="page"
        :page-sizes="[10,20,50,100]"
        :page-size="limit"
        :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="s => { limit = s; loadList() }"
        @current-change="p => { page = p; loadList() }"
      />
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑路径' : '新增路径'" :visible.sync="showForm" width="520px" :close-on-click-modal="true" @closed="resetForm">
      <el-form ref="form" :model="form" label-width="100px" label-position="right" size="small" :rules="rules">
        <el-form-item label="路径名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入路径名称" maxlength="50" />
        </el-form-item>
        <el-form-item label="路径地址" prop="path">
          <el-input v-model="form.path" placeholder="请输入路径地址，如 /pages/xxx/index" maxlength="255" />
        </el-form-item>
        <el-form-item label="平台" prop="platform">
          <el-select v-model="form.platform" style="width:100%">
            <el-option v-for="item in platformOptions" :key="item.value" :label="item.label" :value="Number(item.value)" />
          </el-select>
        </el-form-item>
        <el-form-item label="页面类型" prop="page_type">
          <el-select v-model="form.page_type" style="width:100%">
            <el-option v-for="item in pageTypeOptions" :key="item.value" :label="item.label" :value="Number(item.value)" />
          </el-select>
        </el-form-item>
        <el-form-item label="绑定页面">
          <el-select v-model="form.page_key" style="width:100%" clearable filterable placeholder="选择绑定的DIY页面（可选）">
            <el-option v-for="p in diyPageOptions" :key="p.page_key" :label="p.name" :value="p.page_key" />
            <div v-if="diyPageOptions.length === 0" style="padding:8px;text-align:center;color:#999;font-size:12px">暂无DIY页面</div>
          </el-select>
          <span style="font-size:11px;color:#909399;margin-top:2px;display:block">绑定后可在路径列表直接编辑该页面内容</span>
        </el-form-item>
        <el-form-item label="需要登录">
          <el-switch v-model="form.require_auth" :active-value="1" :inactive-value="0" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="showForm = false" size="small">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveForm" size="small">确定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getPathList, createPath, updatePath, deletePath, togglePathStatus } from '@/api/app'
import { getDictByCode } from '@/api/dictionary'

export default {
  name: 'PathManage',
  data() {
    return {
      list: [],
      total: 0,
      page: 1,
      limit: 20,
      filter: { platform: null, keyword: '' },
      searchTimer: null,
      sortProp: '',
      sortOrder: '',
      showForm: false,
      creating: false,
      form: { id: 0, name: '', path: '', platform: 0, page_type: 1, page_key: '', require_auth: 1, status: 1 },
      pageTypeOptions: [],
      diyPageOptions: [],
      rules: {
        name: [
          { required: true, message: '请输入路径名称', trigger: 'blur' },
          { max: 50, message: '长度不能超过50个字符', trigger: 'blur' },
        ],
        path: [
          { required: true, message: '请输入路径地址', trigger: 'blur' },
          { pattern: /^\//, message: '路径地址必须以 / 开头', trigger: 'blur' },
          { max: 255, message: '长度不能超过255个字符', trigger: 'blur' },
        ],
        platform: [{ required: true, message: '请选择平台', trigger: 'change' }],
        page_type: [{ required: true, message: '请选择页面类型', trigger: 'change' }],
      }
    }
  },
  async created() {
    await this.loadDict()
    this.loadList()
  },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async loadDict() {
      try {
        const [platRes, pageRes] = await Promise.all([
          getDictByCode('app_platform'),
          getDictByCode('app_page_type'),
        ])
        this.platformOptions = platRes.data || []
        this.pageTypeOptions = pageRes.data || []
      } catch (e) {
        this.platformOptions = [
          { label: '全部', value: '0' }, { label: '小程序', value: '1' },
          { label: 'H5', value: '2' }, { label: '公众号', value: '3' },
        ]
        this.pageTypeOptions = [
          { label: '普通页面', value: '1' }, { label: 'Tab页面', value: '2' },
        ]
      }
      this.loadDiyPages()
    },
    /** 加载DIY页面列表 */
    async loadDiyPages() {
      try {
        const { diyLst } = await import('@/api/diy')
        const res = await diyLst({ page: 1, limit: 100 })
        if (res.code === 0 && res.data?.list) {
          this.diyPageOptions = res.data.list.map(p => ({ page_key: String(p.id), name: p.name }))
        }
      } catch(e) {}
    },
    async loadList() {
      try {
        const res = await getPathList({
          page: this.page,
          limit: this.limit,
          platform: this.filter.platform,
          keyword: this.filter.keyword,
          sort_prop: this.sortProp,
          sort_order: this.sortOrder,
        })
        this.list = res.data.list
        this.total = res.data.total
      } catch (e) {}
    },
    onSearchInput() {
      clearTimeout(this.searchTimer)
      this.searchTimer = setTimeout(() => {
        this.page = 1
        this.loadList()
      }, 300)
    },
    onSortChange({ prop, order }) {
      this.sortProp = prop || ''
      this.sortOrder = order || ''
      this.loadList()
    },
    platformTagType(platform) {
      return { 0: 'info', 1: 'primary', 2: 'success', 3: 'warning' }[platform] || 'info'
    },
    openForm(row) {
      if (row) {
        this.form = { ...row }
      } else {
        this.form = { name: '', path: '', platform: 0, page_type: 1, page_key: '', require_auth: 1, status: 1 }
      }
      this.showForm = true
    },
    resetForm() {
      this.$refs.form?.clearValidate()
    },
    async saveForm() {
      try {
        await this.$refs.form.validate()
      } catch (e) {
        return
      }
      this.saving = true
      try {
        if (this.form.id) {
          await updatePath(this.form.id, this.form)
          this.$message.success('编辑成功')
        } else {
          await createPath(this.form)
          this.$message.success('新增成功')
        }
        this.showForm = false
        this.loadList()
      } catch (e) {}
      this.saving = false
    },
    async toggleStatus(row, val) {
      const oldStatus = row.status
      row.status = val ? 1 : 0
      try {
        await togglePathStatus(row.id, row.status)
        this.$message.success('状态已更新')
      } catch (e) {
        row.status = oldStatus
      }
    },
    confirmDelete(row) {
      this.$confirm(`确定删除路径「${row.name}」吗？`, '删除确认', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(async () => {
        try {
          await deletePath(row.id)
          this.$message.success('删除成功')
          this.loadList()
        } catch (e) {}
      }).catch(() => {})
    },
    copyPath(path) {
      const textarea = document.createElement('textarea')
      textarea.value = path
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
      this.$message.success('已复制')
    },
    /** 获取绑定页面标识（优先使用绑定的page_key，其次从路径推导） */
    getDiyPageKey(row) {
      if (row.page_key) return row.page_key
      const p = row.path || ''
      const match = p.match(/[?&]type=([^&]+)/)
      if (match) return match[1]
      const parts = p.split('/')
      if (parts.length >= 2) return parts[parts.length - 2]
      return ''
    },
    /** 跳转到 DIY 编辑器编辑该路径绑定的页面（新 DIY 体系按页面名称匹配） */
    async editDiyPage(row) {
      const key = row.page_key || this.getDiyPageKey(row)
      if (!key) { this.$message.warning('请先在编辑中绑定一个DIY页面'); return }
      // 新 DIY 体系：进入页面装修列表，按名称找到对应页面编辑
      this.$router.push('/diy/list')
    },
  }
}
</script>

<style scoped>
.paths-page {
  padding: 0;
  background: #f5f7fa;
  min-height: 100%;
}
.page-header {
  height: 56px;
  background: #fff;
  border-bottom: 1px solid #EBEEF5;
  padding: 0 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.page-header h2 {
  font-size: 20px;
  font-weight: bold;
  color: #303133;
  margin: 0;
  display: inline;
}
.sub-title {
  font-size: 13px;
  color: #909399;
  margin-left: 12px;
}
.filter-bar {
  height: 48px;
  background: #fff;
  border-radius: 8px;
  margin: 12px 24px 0;
  padding: 0 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.filter-left {
  display: flex;
  align-items: center;
  gap: 12px;
}
.table-container {
  background: #fff;
  margin: 0 24px;
  padding: 0;
}
.table-container .el-table {
  border-radius: 0;
}
.table-container .el-table::before {
  display: none;
}
.pagination-wrap {
  display: flex;
  justify-content: flex-end;
  padding: 16px 24px;
  background: #fff;
  margin: 0 24px 24px;
  border-top: 1px solid #EBEEF5;
}
</style>
