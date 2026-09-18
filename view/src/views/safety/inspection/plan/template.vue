<template>
  <div class="template-page" style="display:flex;gap:16px;">
    <!-- 左侧：模板列表 -->
    <el-card shadow="never" style="width:30%;flex-shrink:0;">
      <div slot="header" class="card-header">
        <b>检查标准模板</b>
        <el-button v-if="hasPerm('safety:inspection:plan:add')" size="small" type="primary" icon="el-icon-plus" @click="openAdd">新增模板</el-button>
      </div>
      <el-input v-model="searchKeyword" placeholder="搜索模板名称" size="small" clearable style="margin-bottom:8px" @keyup.enter.native="loadTemplates" />
      <el-select v-model="searchTypeId" placeholder="全部类型" size="small" clearable style="width:100%;margin-bottom:8px" @change="loadTemplates">
        <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
      </el-select>
      <div class="tpl-list" v-loading="tplLoading">
        <div v-for="t in templateList" :key="t.id" class="tpl-card" :class="{active: currentId === t.id}" @click="selectTemplate(t)">
          <div class="tpl-name">{{ t.template_name }}</div>
          <div class="tpl-meta">{{ t.type_name || '未分类' }} · {{ t.item_count }}项</div>
          <el-tag size="mini" :type="t.status === 'active' ? 'success' : 'info'">{{ t.status_text }}</el-tag>
        </div>
        <el-empty v-if="!templateList.length" description="暂无模板" :image-size="60" />
      </div>
    </el-card>

    <!-- 右侧：模板详情 -->
    <el-card shadow="never" style="flex:1;">
      <div slot="header" class="card-header">
        <b>{{ currentId ? '模板详情' : '请选择左侧模板' }}</b>
        <div v-if="currentId">
          <el-button v-if="hasPerm('safety:inspection:plan:add')" size="small" icon="el-icon-document-copy" @click="handleCopy">复制</el-button>
          <el-button v-if="hasPerm('safety:inspection:plan:edit')" size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
          <el-button v-if="hasPerm('safety:inspection:plan:delete')" size="small" type="danger" plain @click="handleDelete">删除</el-button>
        </div>
      </div>

      <template v-if="currentId">
        <!-- 基本信息 -->
        <el-form :inline="true" size="small">
          <el-form-item label="模板名称"><el-input v-model="form.template_name" style="width:200px" /></el-form-item>
          <el-form-item label="适用类型">
            <el-select v-model="form.inspection_type_id" style="width:140px">
              <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="状态">
            <el-switch v-model="form.status" active-value="active" inactive-value="inactive" active-text="启用" inactive-text="停用" />
          </el-form-item>
        </el-form>

        <!-- 项目列表 -->
        <div class="section-title">
          <span>检查项目列表（{{ form.items.length }}项）</span>
          <el-button size="mini" type="primary" icon="el-icon-plus" @click="openItemAdd">新增项目</el-button>
        </div>
        <el-table :data="form.items" border stripe size="small" row-key="__key">
          <el-table-column type="index" label="序号" width="55" />
          <el-table-column prop="item_name" label="项目名称" min-width="140" />
          <el-table-column prop="check_standard" label="检查标准" min-width="140" show-overflow-tooltip />
          <el-table-column prop="check_method" label="检查方法" min-width="100" />
          <el-table-column label="必查" width="70" align="center">
            <template slot-scope="{row}"><el-tag size="mini" :type="row.is_required ? 'success' : 'info'">{{ row.is_required ? '必查' : '选查' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="deduct_score" label="扣分" width="70" align="center" />
          <el-table-column prop="sort" label="排序" width="70" align="center" />
          <el-table-column label="操作" width="100" align="center">
            <template slot-scope="{row}">
              <el-button size="mini" type="text" @click="openItemEdit(row)">编辑</el-button>
              <el-button size="mini" type="text" style="color:#F56C6C" @click="removeItem(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </template>
      <el-empty v-else description="点击左侧模板查看详情" :image-size="80" />
    </el-card>

    <!-- 项目新增编辑弹窗 -->
    <el-dialog title="检查项目" :visible.sync="itemDialog" width="550px" append-to-body>
      <el-form :model="itemForm" :rules="itemRules" ref="itemRef" label-width="100px" size="small">
        <el-form-item label="项目名称" prop="item_name"><el-input v-model="itemForm.item_name" /></el-form-item>
        <el-form-item label="检查标准"><el-input v-model="itemForm.check_standard" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="检查方法">
          <el-select v-model="itemForm.check_method" style="width:100%">
            <el-option v-for="m in methodOptions" :key="m" :label="m" :value="m" />
          </el-select>
        </el-form-item>
        <el-form-item label="是否必查"><el-switch v-model="itemForm.is_required" :active-value="1" :inactive-value="0" /></el-form-item>
        <el-form-item label="扣分标准"><el-input-number v-model="itemForm.deduct_score" :min="0" :max="100" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="itemForm.sort" :min="0" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="itemDialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="saveItem">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getTemplateList, getTemplateDetail, addTemplate, editTemplate, deleteTemplate, copyTemplate, getTypeOptions } from '@/api/safetyInspectionPlan'

export default {
  name: 'SafetyInspectionTemplate',
  data() {
    return {
      tplLoading: false, templateList: [], typeOptions: [], searchKeyword: '', searchTypeId: null,
      currentId: 0, saving: false, form: { template_name: '', inspection_type_id: 0, status: 'active', items: [] },
      itemDialog: false, itemForm: {}, itemIndex: -1,
      itemRules: { item_name: [{ required: true, message: '项目名称必填', trigger: 'blur' }] },
      methodOptions: ['现场检查', '查阅资料', '询问核实', '仪器检测'],
    }
  },
  created() { this.loadTemplates(); this.loadTypes() },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadTypes() {
      try { const r = await getTypeOptions(); if (r.code === 0) this.typeOptions = r.data || [] } catch (e) {}
    },
    async loadTemplates() {
      this.tplLoading = true
      try {
        const r = await getTemplateList({ keyword: this.searchKeyword, inspection_type_id: this.searchTypeId })
        if (r.code === 0) this.templateList = r.data || []
      } catch (e) {}
      this.tplLoading = false
    },
    async selectTemplate(t) {
      this.currentId = t.id
      try {
        const r = await getTemplateDetail(t.id)
        if (r.code === 0) {
          const d = r.data
          this.form = { template_name: d.template_name, inspection_type_id: d.inspection_type_id, status: d.status, items: (d.items || []).map(i => ({ ...i, __key: 'k' + Math.random().toString(36).slice(2) })) }
        }
      } catch (e) {}
    },
    openAdd() {
      this.currentId = 0
      this.form = { template_name: '', inspection_type_id: this.typeOptions[0]?.id || 0, status: 'active', items: [] }
    },
    async handleSave() {
      if (!this.form.template_name) { this.$message.warning('模板名称必填'); return }
      if (!this.form.inspection_type_id) { this.$message.warning('适用检查类型必选'); return }
      if (!this.form.items.length) { this.$message.warning('至少添加一项检查项目'); return }
      this.saving = true
      try {
        const items = this.form.items.map(({ __key, ...it }) => it)
        const d = { ...this.form, items }
        const r = this.currentId ? await editTemplate(this.currentId, d) : await addTemplate(d)
        if (r.code === 0) { this.$message.success('保存成功'); this.loadTemplates(); if (!this.currentId) { this.currentId = r.data?.id || 0 } }
      } catch (e) {}
      this.saving = false
    },
    handleCopy() {
      this.$confirm('确认复制该模板？', '复制确认', { type: 'warning' }).then(async () => {
        const r = await copyTemplate(this.currentId)
        if (r.code === 0) { this.$message.success('复制成功'); this.loadTemplates() }
      }).catch(() => {})
    },
    handleDelete() {
      this.$confirm('确认删除该模板？', '删除确认', { type: 'warning' }).then(async () => {
        const r = await deleteTemplate(this.currentId)
        if (r.code === 0) { this.$message.success('删除成功'); this.currentId = 0; this.loadTemplates() }
      }).catch(() => {})
    },
    openItemAdd() { this.itemForm = { item_name: '', check_standard: '', check_method: '现场检查', is_required: 1, deduct_score: 0, sort: this.form.items.length + 1 }; this.itemIndex = -1; this.itemDialog = true },
    openItemEdit(row) { this.itemForm = { ...row }; this.itemIndex = this.form.items.indexOf(row); this.itemDialog = true },
    saveItem() {
      this.$refs.itemRef.validate((valid) => {
        if (!valid) return
        if (this.itemIndex >= 0) this.form.items.splice(this.itemIndex, 1, { ...this.itemForm })
        else this.form.items.push({ ...this.itemForm, __key: 'k' + Math.random().toString(36).slice(2) })
        this.itemDialog = false
      })
    },
    removeItem(row) {
      const idx = this.form.items.indexOf(row)
      if (idx >= 0) this.form.items.splice(idx, 1)
    },
  },
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.tpl-list { max-height: 600px; overflow-y: auto; }
.tpl-card { padding: 12px; border: 1px solid #E8ECF1; border-radius: 8px; margin-bottom: 8px; cursor: pointer; transition: all .2s; }
.tpl-card:hover { border-color: #409EFF; }
.tpl-card.active { border-color: #409EFF; background: #f0f7ff; }
.tpl-name { font-size: 14px; font-weight: 600; color: #303133; }
.tpl-meta { font-size: 12px; color: #909399; margin: 4px 0; }
.section-title { display: flex; justify-content: space-between; align-items: center; font-weight: 600; margin: 12px 0 8px; }
</style>
