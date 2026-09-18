<template>
  <div class="device-category-page">
    <!-- 面包屑 -->
    <el-breadcrumb separator="/" class="crumb">
      <el-breadcrumb-item>设备管理</el-breadcrumb-item>
      <el-breadcrumb-item>设备分类</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="body-layout">
      <!-- ================= 左侧：分类树 70% ================= -->
      <div class="left-panel" v-loading="treeLoading">
        <div class="toolbar">
          <el-input v-model="searchKeyword" size="small" placeholder="请输入分类名称或编码搜索"
                    prefix-icon="el-icon-search" clearable style="width:220px"
                    @keyup.enter.native="onSearch" @clear="onSearch" />
          <el-button size="small" type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button size="small" icon="el-icon-sort" @click="expandAll">展开全部</el-button>
          <el-button size="small" icon="el-icon-s-fold" @click="collapseAll">收起全部</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadTree">刷新</el-button>
          <el-button v-if="hasPerm('device:category:add')" size="small" type="success" icon="el-icon-plus" title="新增顶级设备类型" @click="showAddRoot">新增设备类型</el-button>
        </div>

        <div class="tree-area">
          <el-empty v-if="!treeLoading && treeData.length === 0" description="暂无分类数据，点击新增分类开始创建" />
          <el-tree
            ref="treeRef"
            v-else
            :data="treeData"
            node-key="id"
            :props="{ children: 'children', label: 'name' }"
            highlight-current
            @node-click="handleNodeClick">
            <span class="custom-tree-node" slot-scope="{ data }">
              <span class="tree-label">
                <i v-if="data.icon" :class="data.icon" class="tree-icon"></i>
                <span class="tree-name">{{ data.name }}</span>
                <span class="tree-code">{{ data.code }}</span>
                <el-tag v-if="levelDict[data.level]" size="mini" type="info" effect="plain" class="tree-tag">{{ levelDict[data.level] }}</el-tag>
                <el-tag v-if="data.status === 1" size="mini" type="success" class="tree-tag">启用</el-tag>
                <el-tag v-else size="mini" type="info" class="tree-tag">停用</el-tag>
              </span>
              <span class="tree-actions">
                <el-button v-if="hasPerm('device:category:add') && data.status === 1" type="text" size="mini" icon="el-icon-plus" title="新增子分类" @click.stop="showAddChild(data)" />
                <el-button v-if="hasPerm('device:category:edit')" type="text" size="mini" icon="el-icon-edit" :title="data.level === 1 ? '编辑设备类型' : '编辑分类'" @click.stop="showEdit(data)" />
                <el-button v-if="hasPerm('device:category:edit')" size="mini"
                           :icon="data.status === 1 ? 'el-icon-video-pause' : 'el-icon-video-play'"
                           :title="data.status === 1 ? '停用' : '启用'" @click.stop="toggleStatus(data)" />
                <el-button v-if="hasPerm('device:category:delete')" type="text" size="mini" icon="el-icon-delete" style="color:#F56C6C" title="删除" @click.stop="confirmDelete(data)" />
              </span>
            </span>
          </el-tree>
        </div>
      </div>

      <!-- ================= 右侧：分类详情表单 30% ================= -->
      <div class="right-panel">
        <div class="form-header">
          <h3>{{ formTitle }}</h3>
        </div>

        <el-form ref="categoryForm" :model="form" :rules="rules" label-width="100px" label-position="right" size="small">
          <el-form-item label="父级分类" prop="parentIds">
            <el-cascader v-model="form.parentIds" :options="treeOptions"
                         :props="cascaderProps" placeholder="选择顶级分类或子分类" clearable filterable
                         :disabled="formMode === 'edit'" style="width:100%">
              <template slot-scope="{ data }"><i v-if="data.icon" :class="data.icon" class="icon-inline"></i>{{ data.name }}</template>
            </el-cascader>
            <div class="field-tip" v-if="formMode === 'edit'">编辑模式下父级分类不可修改</div>
          </el-form-item>

          <el-form-item label="分类名称" prop="name">
            <el-input v-model="form.name" maxlength="50" placeholder="请输入分类名称" />
            <div class="field-tip">必填，最多 50 个字符</div>
          </el-form-item>

          <el-form-item label="分类编码" prop="code">
            <div class="code-wrap">
              <el-input v-model="form.code" maxlength="30" placeholder="请输入分类编码" style="flex:1" />
              <el-button size="mini" type="text" icon="el-icon-magic-stick" :loading="codeLoading" @click="onAutoCode">自动生成</el-button>
            </div>
            <div class="field-tip">格式：{{ codeRegexText }}（{{ codeRegex }}）</div>
          </el-form-item>

          <el-form-item label="图标">
            <div class="icon-field">
              <span class="icon-preview"><i v-if="form.icon" :class="form.icon"></i><span v-else style="color:#C0C4CC">无</span></span>
              <el-input v-model="form.icon" maxlength="100" placeholder="图标类名或选择" style="flex:1" />
              <el-popover placement="bottom" width="330" trigger="click">
                <div class="icon-grid">
                  <span v-for="item in iconDict" :key="item.value" class="icon-cell" :title="item.label"
                        :class="{ active: form.icon === item.value }" @click="onSelectIcon(item.value)">
                    <i :class="item.value"></i>
                  </span>
                  <div v-if="iconDict.length === 0" style="color:#C0C4CC;font-size:12px">暂无图标字典</div>
                </div>
                <el-button slot="reference" size="mini" icon="el-icon-arrow-down" />
              </el-popover>
            </div>
          </el-form-item>

          <el-form-item label="排序权重" prop="sort">
            <el-input-number v-model="form.sort" :min="0" :max="9999" controls-position="right" style="width:160px" />
            <div class="field-tip">数值越大排序越靠前</div>
          </el-form-item>

          <el-form-item label="状态" prop="status">
            <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
          </el-form-item>
        </el-form>

        <div class="form-footer">
          <el-button type="primary" :loading="submitting" @click="submitForm">提交</el-button>
          <el-button @click="resetForm">重置</el-button>
        </div>

        <!-- 分类信息卡片（统计预留） -->
        <div class="info-card" v-if="currentCategory">
          <div class="info-title">分类信息</div>
          <div class="info-row"><span>所属路径</span><b style="font-weight:400">{{ getCategoryPath(currentCategory) }}</b></div>
          <div class="info-row"><span>子分类数量</span><b>{{ currentCategory.children_count || 0 }}</b></div>
          <div class="info-row"><span>设备数量</span><b title="设备台账开发后自动填充">--</b></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getCategoryTree, getCategoryDetail, addCategory, editCategory, deleteCategory, changeCategoryStatus, suggestCategoryCode } from '@/api/deviceCategory'
import { getDictionaryBatch } from '@/utils/dict'
import { getSettingsBatch } from '@/api/settings'

export default {
  name: 'DeviceCategory',
  data() {
    return {
      treeLoading: false,
      submitting: false,
      codeLoading: false,
      searchKeyword: '',
      treeData: [],
      treeOptions: [],
      currentCategory: null, // 当前选中分类（信息卡片）
      formMode: 'add', // add / edit
      // 字典缓存
      levelDict: {}, // level -> 一级/二级...
      iconDict: [], // 图标字典条目
      // 系统参数（前端仅展示校验规则，后端为最终校验）
      codeRegex: '^[A-Z][A-Z0-9_]*$',
      codeRegexText: '大写字母开头，可包含大写字母、数字、下划线',
      cascaderProps: { checkStrictly: true, emitPath: false, value: 'id', label: 'name', children: 'children' },
      // 表单
      form: {
        parentIds: [], // el-cascader 路径数组（顶级为 []）
        name: '',
        code: '',
        icon: '',
        sort: 0,
        status: 1
      },
      rules: {
        name: [
          { required: true, message: '请输入分类名称', trigger: 'blur' },
          { max: 50, message: '最多50个字符', trigger: 'blur' }
        ],
        code: [
          { required: true, message: '请输入分类编码', trigger: 'blur' },
          { max: 30, message: '最多30个字符', trigger: 'blur' },
          { validator: (rule, value, cb) => {
              try {
                const re = new RegExp(this.codeRegex)
                if (value && !re.test(value)) cb(new Error('编码格式不正确'))
                else cb()
              } catch (e) { cb() }
            }, trigger: 'blur' }
        ],
        sort: [
          { validator: (rule, value, cb) => { if (value < 0 || value > 9999) cb(new Error('范围0-9999')); else cb() }, trigger: 'change' }
        ]
      }
    }
  },
  computed: {
    // 表单标题：新增设备类型 / 新增分类 / 编辑设备类型 / 编辑分类
    formTitle() {
      if (this.formMode === 'add') return this.isTopLevelForm ? '新增设备类型' : '新增分类'
      return this.currentCategory && this.currentCategory.level === 1
        ? ('编辑设备类型：' + this.form.name)
        : ('编辑分类：' + this.form.name)
    },
    // 新增模式下父级为空即代表新增顶级设备类型
    isTopLevelForm() {
      if (this.formMode === 'edit') return false
      return (this.form.parentIds || []).length === 0
    },
    // 响应式权限判断（依赖 store.user.permissions，权限加载完成后自动更新按钮显示）
    hasPerm() {
      return (code) => {
        const perms = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
        return perms.indexOf(code) > -1
      }
    }
  },
  async created() {
    this.loadDicts()
    this.loadParams()
    this.loadTree()
    // 兜底：确保权限已加载（从其它页面导航进来时 permissions 可能为空，导致按钮灰色）
    if (!this.$store.state.user || !this.$store.state.user.permissions || !this.$store.state.user.permissions.length) {
      try {
        await this.$store.dispatch('user/loadPermissions')
      } catch (e) { /* 失败不阻塞 */ }
    }
  },
  methods: {
    // ---------- 数据加载 ----------
    async loadDicts() {
      try {
        const res = await getDictionaryBatch(['device_category_status', 'device_category_level', 'device_category_icon'])
        const levelMap = {}
        ;(res['device_category_level'] || []).forEach(i => { levelMap[i.value] = i.label })
        this.levelDict = levelMap
        this.iconDict = res['device_category_icon'] || []
      } catch (e) { /* 字典加载失败不阻塞 */ }
    },
    async loadParams() {
      try {
        const res = await getSettingsBatch(['device_category_code_regex'])
        const map = res.data || {}
        const regex = map['device_category_code_regex'] || map.device_category_code_regex
        if (regex) this.codeRegex = regex
      } catch (e) { /* 使用默认正则 */ }
    },
    async loadTree() {
      this.treeLoading = true
      try {
        // 管理端返回全部（含停用）分类，便于启停管理
        const params = { all: 1 }
        if (this.searchKeyword) params.keyword = this.searchKeyword
        const res = await getCategoryTree(params)
        this.treeData = (res.data && res.data.list) || []
        this.buildTreeOptions()
        // 数据加载完成后默认展开全部节点
        this.$nextTick(() => {
          const tree = this.$refs.treeRef
          if (tree && tree.store) tree.store._getAllNodes().forEach(node => { node.expanded = true })
        })
      } catch (e) {
        this.$message.error('网络异常，请稍后重试')
      } finally {
        this.treeLoading = false
      }
    },
    // 将树数据转为级联选择器 options
    buildTreeOptions() {
      const convert = (nodes) => (nodes || []).map(n => ({
        id: n.id,
        name: n.name,
        icon: n.icon,
        children: convert(n.children)
      }))
      this.treeOptions = convert(this.treeData)
    },

    // ---------- 树操作 ----------
    onSearch() { this.loadTree() },
    // Element UI el-tree 无内置展开全部/收起全部，通过 store._getAllNodes() 控制
    expandAll() {
      this.$nextTick(() => {
        const tree = this.$refs.treeRef
        if (!tree || !tree.store) return
        tree.store._getAllNodes().forEach(node => { node.expanded = true })
      })
    },
    collapseAll() {
      this.$nextTick(() => {
        const tree = this.$refs.treeRef
        if (!tree || !tree.store) return
        tree.store._getAllNodes().forEach(node => { node.expanded = false })
      })
    },
    handleNodeClick(data) { this.loadDetail(data.id) },

    async loadDetail(id) {
      try {
        const res = await getCategoryDetail(id)
        if (res.code !== 0) return
        const d = res.data
        this.currentCategory = d
        this.formMode = 'edit'
        this.form = {
          parentIds: this.findParentPath(this.treeData, d.id) || [],
          name: d.name,
          code: d.code,
          icon: d.icon || '',
          sort: d.sort || 0,
          status: d.status === 1 ? 1 : 0
        }
      } catch (e) { this.$message.error('网络异常，请稍后重试') }
    },

    // 在树中查找指定 id 的父级路径（返回路径上的 id 数组）
    findParentPath(nodes, id, path = []) {
      for (const n of nodes || []) {
        if (n.id === id) return path.concat(n.id)
        if (n.children && n.children.length) {
          const r = this.findParentPath(n.children, id, path.concat(n.id))
          if (r) return r
        }
      }
      return null
    },

    // ---------- 新增/编辑 ----------
    showAddRoot() {
      if (!this.hasPerm('device:category:add')) {
        this.$message.warning('无权限执行该操作')
        return
      }
      this.formMode = 'add'
      this.currentCategory = null
      this.resetForm()
    },
    showAddChild(data) {
      this.formMode = 'add'
      this.currentCategory = null
      this.resetForm()
      this.form.parentIds = this.findParentPath(this.treeData, data.id) || [data.id]
    },
    showEdit(data) { this.loadDetail(data.id) },

    async onAutoCode() {
      this.codeLoading = true
      try {
        const res = await suggestCategoryCode({ parent_id: this.getParentId(), name: this.form.name })
        if (res.code === 0 && res.data) this.form.code = res.data.code
      } catch (e) { this.$message.error('网络异常，请稍后重试') }
      finally { this.codeLoading = false }
    },
    onSelectIcon(value) { this.form.icon = value },

    // 从 cascader 数组中取最终父级 id
    getParentId() {
      const arr = this.form.parentIds || []
      return arr.length ? Number(arr[arr.length - 1]) : 0
    },

    // ---------- 提交 / 删除 ----------
    async submitForm() {
      this.$refs.categoryForm.validate(async (valid) => {
        if (!valid) return
        this.submitting = true
        try {
          const payload = {
            parent_id: this.getParentId(),
            name: this.form.name,
            code: this.form.code,
            icon: this.form.icon || '',
            sort: this.form.sort || 0,
            status: this.form.status
          }
          if (this.formMode === 'add') {
            await addCategory(payload)
            this.$message.success('创建成功')
          } else {
            await editCategory(this.currentCategory.id, payload)
            this.$message.success('更新成功')
          }
          await this.loadTree()
          this.resetForm()
        } catch (e) { /* request 拦截器已提示 */ }
        finally { this.submitting = false }
      })
    },

    confirmDelete(data) {
      this.$confirm(`确定要删除分类 [${data.name}] 吗？删除后不可恢复。`, '提示', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(async () => {
        try {
          await deleteCategory(data.id)
          this.$message.success('删除成功')
          await this.loadTree()
          this.currentCategory = null
          this.resetForm()
        } catch (e) { /* 拦截器已提示（如含子分类/含设备） */ }
      }).catch(() => {})
    },

    // 切换分类启用/停用（树节点快捷操作）
    async toggleStatus(data) {
      const next = data.status === 1 ? 0 : 1
      if (next === 0) {
        try {
          await this.$confirm(`确定要停用分类 [${data.name}] 吗？停用后该分类及其层级在树中仍可见但不可作为父级新建子分类。`, '提示', {
            confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
          })
        } catch (e) { return }
      }
      try {
        await changeCategoryStatus(data.id, next)
        this.$message.success(next === 1 ? '已启用' : '已停用')
        await this.loadTree()
      } catch (e) { /* 拦截器已提示（如有启用子分类） */ }
    },

    // 从树数据中拼接分类所属路径名称（如 普通设备 / 办公设备）
    getCategoryPath(data) {
      if (!data) return '-'
      const names = []
      this.collectPathNames(this.treeData, data.id, names)
      return names.length ? names.join(' / ') : data.name
    },
    collectPathNames(nodes, id, names) {
      for (const n of nodes || []) {
        if (n.id === id) { names.push(n.name); return true }
        if (n.children && n.children.length) {
          const sub = []
          if (this.collectPathNames(n.children, id, sub)) {
            names.push(n.name, ...sub)
            return true
          }
        }
      }
      return false
    },

    resetForm() {
      this.form = { parentIds: [], name: '', code: '', icon: '', sort: 0, status: 1 }
      if (this.$refs.categoryForm) this.$refs.categoryForm.clearValidate()
    }
  }
}
</script>

<style scoped>
.device-category-page { padding: 16px; }
.crumb { margin-bottom: 14px; }
.body-layout { display: flex; gap: 16px; align-items: flex-start; }

/* 左侧 70% */
.left-panel { flex: 0 0 70%; width: 70%; background: #fff; border-radius: 8px; padding: 14px; box-shadow: 0 2px 8px rgba(0,0,0,.04); min-height: 70vh; }
.toolbar { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px; align-items: center; }
.tree-area { max-height: 64vh; overflow: auto; }
.custom-tree-node { display: flex; align-items: center; justify-content: space-between; flex: 1; padding-right: 8px; font-size: 13px; }
.tree-label { display: inline-flex; align-items: center; gap: 6px; }
.tree-icon { color: #409EFF; }
.tree-name { font-weight: 600; }
.tree-code { color: #909399; font-size: 12px; font-family: Consolas, monospace; }
.tree-tag { margin-left: 2px; }
.tree-actions { display: none; gap: 2px; }
.custom-tree-node:hover .tree-actions { display: inline-flex; }

/* 右侧 30% */
.right-panel { flex: 0 0 30%; width: 30%; background: #fff; border-radius: 8px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,.04); }
.form-header { border-bottom: 1px solid #f0f0f0; margin-bottom: 16px; }
.form-header h3 { margin: 0 0 12px; font-size: 16px; }
.field-tip { color: #909399; font-size: 12px; line-height: 1.4; }
.code-wrap { display: flex; align-items: center; gap: 6px; }
.icon-field { display: flex; align-items: center; gap: 8px; }
.icon-preview { width: 34px; height: 34px; border: 1px dashed #dcdfe6; border-radius: 6px; display: flex; align-items: center; justify-content: center; color: #409EFF; font-size: 18px; }
.icon-inline { margin-right: 4px; color: #409EFF; }
.icon-grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: 8px; }
.icon-cell { height: 36px; border: 1px solid #ebeef5; border-radius: 6px; display: flex; align-items: center; justify-content: center; color: #606266; cursor: pointer; font-size: 18px; }
.icon-cell.active, .icon-cell:hover { border-color: #409EFF; color: #409EFF; background: #ecf5ff; }
.form-footer { margin-top: 12px; }
.info-card { margin-top: 18px; border-top: 1px solid #f0f0f0; padding-top: 12px; }
.info-title { font-weight: 600; margin-bottom: 8px; }
.info-row { display: flex; justify-content: space-between; color: #606266; font-size: 13px; padding: 4px 0; }
</style>
