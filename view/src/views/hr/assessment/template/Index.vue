<!--
  文件：admin/src/views/hr/assessment/template/Index.vue
  功能：考核模板管理主页面（左侧模板列表 + 右侧编辑区：基本信息/指标配置/预览）
  视觉：对齐《考核模板管理 · 油缸组月度考核表》参考模板（主色 #1e6fff）
-->
<template>
  <div class="wh-page assessment-page">
    <!-- 顶部 header -->
    <div class="page-header">
      <div class="header-left">
        <el-breadcrumb separator="/" class="breadcrumb">
          <el-breadcrumb-item>人事管理</el-breadcrumb-item>
          <el-breadcrumb-item>绩效考核</el-breadcrumb-item>
          <el-breadcrumb-item>考核模板管理</el-breadcrumb-item>
        </el-breadcrumb>
        <span class="badge-module">📋 考核模板管理</span>
      </div>
      <div class="header-actions" v-if="editing && !isNew">
        <el-button size="small" icon="el-icon-download" v-permission="'assessment:template:export'" @click="quickExport">导出预览</el-button>
        <el-button size="small" icon="el-icon-printer" @click="quickPrint">打印</el-button>
        <el-button type="primary" size="small" icon="el-icon-check" @click="quickSave">保存模板</el-button>
      </div>
    </div>

    <div class="assessment-layout">
      <!-- 左：模板列表 -->
      <div class="left-panel">
        <template-list
          :list="list" :loading="listLoading" :selected-id="selectedId"
          @select="onSelect" @create="onCreate" @search="onSearch"
          @toggle="onToggle" @duplicate="onDuplicate" @delete="onDelete"
        />
      </div>

      <!-- 右：编辑区 -->
      <div class="right-panel">
        <template v-if="editing">
          <div class="editor-header">
            <div class="editor-title">
              <span class="title-text">{{ currentTemplate.name || (isNew ? '新建考核模板' : '考核模板') }}</span>
              <el-tag v-if="!isNew" size="small" :type="currentTemplate.status === 1 ? 'success' : 'info'">{{ currentTemplate.status === 1 ? '启用' : '停用' }}</el-tag>
              <el-tag v-if="!isNew" size="small" type="warning">V{{ currentTemplate.version }}</el-tag>
            </div>
            <div class="editor-actions">
              <el-button size="small" icon="el-icon-back" @click="cancelEdit">返回列表</el-button>
            </div>
          </div>

          <el-tabs v-model="activeTab" type="border-card" class="editor-tabs">
            <el-tab-pane label="📋 基本信息" name="basic">
              <basic-info-tab ref="basicTab" :form="basicForm" :saving="basicSaving" @save="saveBasic" @cancel="cancelEdit" />
            </el-tab-pane>
            <el-tab-pane label="⚙️ 指标配置" name="indicators">
              <indicator-tab
                :template-id="templateId" :can-edit="canEdit"
                @tree-change="onTreeChange"
              />
            </el-tab-pane>
            <el-tab-pane label="👁️ 预览" name="preview">
              <preview-tab ref="previewTab" :template="currentTemplate" :tree="previewTree" :total-score="previewScore" />
            </el-tab-pane>
          </el-tabs>
        </template>

        <div v-else class="empty-state">
          <i class="el-icon-document-checked"></i>
          <p>从左侧选择一个模板进行编辑，或点击「新建」创建考核模板</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import store from '@/store'
import TemplateList from './components/TemplateList.vue'
import BasicInfoTab from './components/BasicInfoTab.vue'
import IndicatorTab from './components/IndicatorTab.vue'
import PreviewTab from './components/PreviewTab.vue'
import {
  getTemplateList, getTemplateDetail, createTemplate, updateTemplate,
  deleteTemplate, toggleTemplateStatus, duplicateTemplate
} from '@/api/assessment'

export default {
  name: 'AssessmentTemplateIndex',
  components: { TemplateList, BasicInfoTab, IndicatorTab, PreviewTab },
  data () {
    return {
      // 列表
      list: [], listLoading: false,
      // 编辑
      editing: false, isNew: false, templateId: 0, selectedId: 0, activeTab: 'basic',
      currentTemplate: {}, basicForm: this.emptyBasic(), basicSaving: false,
      previewTree: [], previewScore: 0
    }
  },
  computed: {
    canEdit () { return this.hasPerm('assessment:template:edit') }
  },
  created () {
    this.loadList()
  },
  methods: {
    hasPerm (code) {
      const u = store.state.user
      const perms = u?.permissions || []
      const info = u?.userInfo || {}
      if (!!info.is_super_admin || perms.includes('super_admin')) return true
      return perms.includes(code)
    },
    emptyBasic () {
      return { id: 0, name: '', code: '', category: '', period_type: 1, is_default: 0, status: 1, description: '' }
    },
    // ===== 列表 =====
    async loadList (params) {
      this.listLoading = true
      try {
        const p = Object.assign({ page: 1, limit: 100 }, params || {})
        const r = await getTemplateList(p)
        if (r.code === 0 && r.data) this.list = r.data.list || []
      } catch (e) {} finally { this.listLoading = false }
    },
    onSearch (params) {
      this.loadList(params)
    },
    // ===== 选择/新建 =====
    async onSelect (id) {
      this.selectedId = id
      this.templateId = id
      this.isNew = false
      this.activeTab = 'basic'
      this.editing = true
      await this.loadDetail(id)
    },
    onCreate () {
      this.editing = true
      this.isNew = true
      this.templateId = 0
      this.selectedId = 0
      this.activeTab = 'basic'
      this.currentTemplate = {}
      this.basicForm = this.emptyBasic()
      this.previewTree = []
      this.previewScore = 0
    },
    async loadDetail (id) {
      try {
        const r = await getTemplateDetail(id)
        if (r.code === 0 && r.data) {
          const t = r.data.template || {}
          this.currentTemplate = t
          this.basicForm = {
            id: t.id || 0, name: t.name || '', code: t.code || '', category: t.category || '',
            period_type: t.period_type || 1, is_default: t.is_default || 0,
            status: t.status === 1 ? 1 : 0, description: t.description || ''
          }
          this.previewTree = r.data.indicators || []
          this.previewScore = Number(r.data.total_score || 0)
        }
      } catch (e) {}
    },
    cancelEdit () {
      this.editing = false
      this.selectedId = 0
      this.loadList()
    },
    // ===== 基本信息保存 =====
    async saveBasic (form) {
      this.basicSaving = true
      try {
        const payload = {
          name: form.name, code: form.code, category: form.category,
          period_type: form.period_type, is_default: form.is_default,
          status: form.status, description: form.description
        }
        let r
        if (form.id) {
          r = await updateTemplate(form.id, payload)
        } else {
          r = await createTemplate(payload)
        }
        if (r.code === 0) {
          this.$message.success('模板已保存')
          await this.loadList()
          if (!form.id) {
            this.isNew = false
            this.templateId = r.data.id
            this.selectedId = r.data.id
            await this.loadDetail(r.data.id)
          } else {
            await this.loadDetail(form.id)
          }
        }
      } catch (e) {} finally { this.basicSaving = false }
    },
    // ===== 列表操作 =====
    async onToggle (item, val) {
      try {
        const r = await toggleTemplateStatus(item.id)
        if (r.code === 0) {
          this.$message.success('操作成功')
          await this.loadList()
          if (this.templateId === item.id && this.editing) await this.loadDetail(item.id)
        } else this.$message.error(r.msg || '操作失败')
      } catch (e) {}
    },
    async onDuplicate (item) {
      this.$confirm(`确认复制模板「${item.name}」吗？`, '提示', { type: 'warning' })
        .then(async () => {
          try {
            const r = await duplicateTemplate(item.id)
            if (r.code === 0) { this.$message.success('复制成功'); await this.loadList() } else this.$message.error(r.msg || '复制失败')
          } catch (e) {}
        }).catch(() => {})
    },
    async onDelete (item) {
      this.$confirm(`确认删除模板「${item.name}」吗？删除后不可恢复！`, '提示', { type: 'warning' })
        .then(async () => {
          try {
            const r = await deleteTemplate(item.id)
            if (r.code === 0) {
              this.$message.success('删除成功')
              if (this.templateId === item.id) this.cancelEdit()
              else await this.loadList()
            } else this.$message.error(r.msg || '删除失败')
          } catch (e) {}
        }).catch(() => {})
    },
    onTreeChange ({ tree, totalScore }) {
      this.previewTree = tree
      this.previewScore = totalScore
    },
    // ===== header 快捷操作 =====
    quickSave () {
      if (this.$refs.basicTab) this.$refs.basicTab.doSave()
    },
    quickExport () {
      if (this.$refs.previewTab) this.$refs.previewTab.doExport()
    },
    quickPrint () {
      if (this.$refs.previewTab) this.$refs.previewTab.doPrint()
    }
  }
}
</script>

<style scoped>
.assessment-page { padding: 16px; }
.page-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; padding: 12px 18px; background: #fafbfc; border: 1px solid #e8ecf1; border-bottom: none; border-radius: 12px 12px 0 0; }
.header-left { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.header-left .breadcrumb { font-size: 14px; color: #8c8f9c; }
.header-left .breadcrumb >>> .el-breadcrumb__inner { color: #8c8f9c; }
.header-left .breadcrumb >>> .el-breadcrumb__item:last-child .el-breadcrumb__inner { color: #1d2129; font-weight: 500; }
.badge-module { background: #e8f3ff; color: #1e6fff; font-size: 12px; padding: 2px 12px; border-radius: 12px; font-weight: 500; }
.header-actions { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.assessment-layout { display: flex; gap: 0; height: calc(100vh - 170px); min-height: 540px; border: 1px solid #e8ecf1; border-radius: 0 0 12px 12px; overflow: hidden; }
.left-panel { width: 300px; flex-shrink: 0; background: #f7f9fc; border-right: 1px solid #e8ecf1; overflow: hidden; }
.right-panel { flex: 1; min-width: 0; background: #ffffff; display: flex; flex-direction: column; overflow: hidden; }
.editor-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 20px; border-bottom: 1px solid #f0f2f4; }
.editor-title { display: flex; align-items: center; gap: 10px; }
.title-text { font-size: 17px; font-weight: 600; color: #1d2129; }
.editor-actions { display: flex; gap: 8px; }
.editor-tabs { flex: 1; margin: 0 16px 16px; overflow: hidden; }
.editor-tabs >>> .el-tabs__content { overflow: auto; height: calc(100% - 44px); }
.empty-state { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; color: #c0c4cc; }
.empty-state i { font-size: 48px; margin-bottom: 12px; }
.empty-state p { font-size: 14px; }
@media (max-width: 992px) {
  .assessment-layout { flex-direction: column; height: auto; }
  .left-panel { width: 100%; max-height: 260px; border-right: none; border-bottom: 1px solid #e8ecf1; }
}
</style>

<!-- 模块级主题覆盖（对齐参考模板主色 #1e6fff，仅作用于本模块） -->
<style>
.assessment-page .el-button--primary { background-color: #1e6fff; border-color: #1e6fff; }
.assessment-page .el-button--primary:hover, .assessment-page .el-button--primary:focus { background-color: #4d8bff; border-color: #4d8bff; }
.assessment-page .el-button--primary.is-plain { color: #1e6fff; background: #ffffff; border-color: #1e6fff; }
.assessment-page .el-button--primary.is-plain:hover, .assessment-page .el-button--primary.is-plain:focus { color: #ffffff; background: #1e6fff; border-color: #1e6fff; }
.assessment-page .el-tabs__item.is-active { color: #1e6fff; }
.assessment-page .el-tabs__active-bar { background-color: #1e6fff; }
.assessment-page .el-switch.is-checked .el-switch__core { border-color: #1e6fff; background-color: #1e6fff; }
.assessment-page .el-radio__input.is-checked .el-radio__inner { border-color: #1e6fff; background: #1e6fff; }
.assessment-page .el-radio__input.is-checked + .el-radio__label { color: #1e6fff; }
.assessment-page .el-input__inner:focus, .assessment-page .el-textarea__inner:focus { border-color: #1e6fff; }
.assessment-page .el-select .el-input.is-focus .el-input__inner { border-color: #1e6fff; }
.assessment-page .el-checkbox__input.is-checked .el-checkbox__inner { background-color: #1e6fff; border-color: #1e6fff; }
.assessment-page .el-checkbox__input.is-checked + .el-checkbox__label { color: #1e6fff; }
.assessment-page .el-radio-button__orig-radio:checked + .el-radio-button__inner { background-color: #1e6fff; border-color: #1e6fff; box-shadow: -1px 0 0 0 #1e6fff; }
.assessment-page .el-radio-button__orig-radio:checked + .el-radio-button__inner:hover { color: #ffffff; }
</style>
