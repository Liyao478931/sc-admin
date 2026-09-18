<template>
  <div class="maintenance-template-page">
    <!-- 左侧模板列表 30% -->
    <div class="left-panel">
      <el-card shadow="never" class="left-card">
        <div slot="header" class="card-header">
          <span>项目模板</span>
          <div style="float:right;">
            <el-button v-if="hasPerm('device:maintenance:template:add')" size="small" type="primary" icon="el-icon-plus" @click="openForm()">新增模板</el-button>
          </div>
        </div>
        <el-input v-model="keyword" size="small" placeholder="搜索模板名称/编号" prefix-icon="el-icon-search" clearable style="margin-bottom:8px" @input="loadList" />
        <el-select v-model="levelFilter" size="small" clearable placeholder="按等级筛选" style="width:100%;margin-bottom:8px" @change="loadList">
          <el-option v-for="l in levelOptions" :key="l.id" :label="l.level_name" :value="l.id" />
        </el-select>
        <div v-loading="loading" class="template-list">
          <div v-for="t in list" :key="t.id" class="template-item" :class="{active: activeId === t.id}" @click="selectTemplate(t)">
            <div class="tpl-name">{{ t.template_name }} <el-tag :type="t.status === 'active' ? 'success' : 'info'" size="mini">{{ t.status === 'active' ? '启用' : '停用' }}</el-tag></div>
            <div class="tpl-meta">{{ t.device_type_name }} · {{ t.level_name }} · {{ t.item_count }}项</div>
          </div>
          <el-empty v-if="!list.length && !loading" description="暂无模板" :image-size="60" />
        </div>
      </el-card>
    </div>

    <!-- 右侧模板详情 70% -->
    <div class="right-panel">
      <el-card v-if="detail" shadow="never">
        <div slot="header" class="card-header">
          <span>模板详情：{{ detail.template_name }}</span>
          <div style="float:right;">
            <el-button v-if="hasPerm('device:maintenance:template:add')" size="small" icon="el-icon-copy-document" @click="handleCopy">复制</el-button>
            <el-button v-if="hasPerm('device:maintenance:template:edit')" size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
            <el-button v-if="hasPerm('device:maintenance:template:delete')" size="small" type="danger" @click="handleDelete">删除</el-button>
          </div>
        </div>

        <!-- 基本信息区 -->
        <el-form :model="detail" label-width="110px" size="small" style="margin-bottom:16px">
          <el-row :gutter="16">
            <el-col :span="8">
              <el-form-item label="模板名称"><el-input v-model="detail.template_name" maxlength="100" /></el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="保养等级">
                <el-select v-model="detail.level_id" disabled style="width:100%">
                  <el-option v-for="l in levelOptions" :key="l.id" :label="l.level_name" :value="l.id" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="标准工时"><el-input-number v-model="detail.standard_hours" :min="0" :precision="2" style="width:100%" /> 小时</el-form-item>
            </el-col>
          </el-row>
          <el-row>
            <el-col :span="8">
              <el-form-item label="适用设备类型">
                <el-select v-model="detail.device_type_id" clearable filterable style="width:100%" placeholder="留空=通用">
                  <el-option v-for="c in categoryOptions" :key="c.id" :label="c.name" :value="c.id" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="状态">
                <el-switch v-model="detail.status" active-value="active" inactive-value="inactive" active-text="启用" inactive-text="停用" />
              </el-form-item>
            </el-col>
          </el-row>
        </el-form>

        <!-- 项目列表区 -->
        <div class="item-section">
          <div class="item-header">
            <span>保养项目（{{ detail.items ? detail.items.length : 0 }}项）</span>
            <el-button v-if="!referenced" size="small" type="success" icon="el-icon-plus" @click="openItemForm()">新增项目</el-button>
            <el-tag v-else size="mini" type="warning">已关联计划，项目不可修改</el-tag>
          </div>
          <el-table :data="detail.items || []" size="small" border stripe>
            <el-table-column type="index" label="#" width="50" />
            <el-table-column prop="item_name" label="项目名称" min-width="140" />
            <el-table-column prop="operation_content" label="操作内容" min-width="160" show-overflow-tooltip />
            <el-table-column prop="check_standard" label="检查标准" min-width="140" show-overflow-tooltip />
            <el-table-column prop="required_tools" label="所需工具" width="120" show-overflow-tooltip />
            <el-table-column label="必做" width="60" align="center">
              <template slot-scope="{row}"><el-tag :type="row.is_required ? 'success' : 'info'" size="mini">{{ row.is_required ? '是' : '否' }}</el-tag></template>
            </el-table-column>
            <el-table-column label="严重异常" width="80" align="center">
              <template slot-scope="{row}"><el-tag :type="row.is_serious ? 'danger' : 'info'" size="mini">{{ row.is_serious ? '是' : '否' }}</el-tag></template>
            </el-table-column>
            <el-table-column prop="sort" label="排序" width="60" />
            <el-table-column label="操作" width="120" fixed="right" v-if="!referenced">
              <template slot-scope="{row, $index}">
                <el-button size="mini" type="text" icon="el-icon-edit" @click="openItemForm(row)">编辑</el-button>
                <el-button size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="removeItem($index)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-card>
      <el-card v-else shadow="never"><el-empty description="请选择左侧模板查看详情" /></el-card>
    </div>

    <!-- 新增/编辑项目弹窗 -->
    <el-dialog :title="itemForm.id ? '编辑项目' : '新增项目'" :visible.sync="itemFormVisible" width="520px" :close-on-click-modal="false">
      <el-form :model="itemForm" :rules="itemRules" ref="itemForm" label-width="100px" size="small">
        <el-form-item label="项目名称" prop="item_name"><el-input v-model="itemForm.item_name" maxlength="100" /></el-form-item>
        <el-form-item label="操作内容"><el-input v-model="itemForm.operation_content" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="检查标准"><el-input v-model="itemForm.check_standard" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="所需工具"><el-input v-model="itemForm.required_tools" /></el-form-item>
        <el-form-item label="是否必做"><el-switch v-model="itemForm.is_required" /></el-form-item>
        <el-form-item label="严重异常项"><el-switch v-model="itemForm.is_serious" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="itemForm.sort" :min="0" style="width:100%" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="itemFormVisible = false">取消</el-button>
        <el-button type="primary" @click="saveItem">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getTemplateList, getTemplateDetail, getLevelOptions, addTemplate, editTemplate, deleteTemplate, copyTemplate } from '@/api/maintenance'
import { getCategoryTree } from '@/api/deviceCategory'

export default {
  name: 'MaintenanceTemplate',
  data() {
    return {
      list: [], loading: false, saving: false,
      keyword: '', levelFilter: null,
      levelOptions: [], categoryOptions: [],
      activeId: 0, detail: null, referenced: false,
      itemFormVisible: false,
      itemForm: { id: '', item_name: '', operation_content: '', check_standard: '', required_tools: '', is_required: true, is_serious: false, sort: 0 },
      itemRules: { item_name: [{ required: true, message: '请输入项目名称', trigger: 'blur' }] }
    }
  },
  created() { this.loadLevelOptions(); this.loadCategoryOptions(); this.loadList() },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async loadLevelOptions() { try { const r = await getLevelOptions(); if (r.code === 0) this.levelOptions = r.data || [] } catch (e) {} },
    async loadCategoryOptions() {
      const flatten = (nodes) => {
        let arr = []
        nodes.forEach(n => { arr.push({ id: n.id, name: n.name }); if (n.children) arr = arr.concat(flatten(n.children)) })
        return arr
      }
      try { const r = await getCategoryTree({ all: 1 }); if (r.code === 0) this.categoryOptions = flatten(r.data || []) } catch (e) {}
    },
    async loadList() {
      this.loading = true
      try {
        const p = { keyword: this.keyword || undefined, level_id: this.levelFilter || undefined }
        const r = await getTemplateList(p)
        if (r.code === 0) {
          this.list = r.data.list || []
          if (this.activeId && !this.list.find(t => t.id === this.activeId)) this.activeId = 0
          if (!this.activeId && this.list.length) this.selectTemplate(this.list[0])
        }
      } catch (e) {}
      this.loading = false
    },
    async selectTemplate(t) {
      this.activeId = t.id
      try { const r = await getTemplateDetail(t.id); if (r.code === 0) this.detail = r.data } catch (e) {}
    },
    openForm() {
      // 新增：选择等级后创建空模板
      this.detail = { id: 0, template_name: '', level_id: this.levelFilter || this.levelOptions[0]?.id || null, device_type_id: null, items: [], standard_hours: 0, status: 'active' }
      this.activeId = 0
      this.$message.info('请填写基本信息并添加保养项目后保存')
    },
    async handleSave() {
      if (!this.detail.template_name) return this.$message.warning('请填写模板名称')
      if (!this.detail.level_id) return this.$message.warning('请选择保养等级')
      if (!this.detail.items || !this.detail.items.length) return this.$message.warning('请至少添加一个保养项目')
      this.saving = true
      try {
        const d = { ...this.detail }
        if (d.id) { const r = await editTemplate(d.id, d); if (r.code === 0) { this.$message.success('更新成功'); this.loadList() } }
        else { const r = await addTemplate(d); if (r.code === 0) { this.$message.success('创建成功'); this.loadList() } }
      } catch (e) {}
      this.saving = false
    },
    async handleCopy() {
      try { const r = await copyTemplate(this.detail.id); if (r.code === 0) { this.$message.success('复制成功'); this.loadList() } } catch (e) {}
    },
    async handleDelete() {
      try {
        await this.$confirm(`确认删除模板「${this.detail.template_name}」？`, '提示', { type: 'warning' })
        const r = await deleteTemplate(this.detail.id)
        if (r.code === 0) { this.$message.success('已删除'); this.detail = null; this.loadList() }
      } catch (e) {}
    },
    openItemForm(row) {
      this.itemForm = row ? { ...row } : { id: 'item_' + String(Date.now()).slice(-6), item_name: '', operation_content: '', check_standard: '', required_tools: '', is_required: true, is_serious: false, sort: (this.detail.items ? this.detail.items.length : 0) + 1 }
      this.itemFormVisible = true
    },
    async saveItem() {
      const valid = await this.$refs.itemForm.validate().catch(() => false)
      if (!valid) return
      const items = this.detail.items || []
      const idx = items.findIndex(x => x.id === this.itemForm.id)
      if (idx > -1) {
        items[idx] = { ...this.itemForm }
      } else {
        items.push({ ...this.itemForm })
      }
      this.detail.items = [...items]
      this.itemFormVisible = false
    },
    removeItem(index) { this.detail.items.splice(index, 1); this.detail.items = [...this.detail.items] }
  }
}
</script>

<style scoped>
.maintenance-template-page { display: flex; gap: 12px; padding: 0; }
.left-panel { width: 30%; min-width: 260px; }
.left-card { min-height: 600px; }
.template-list { max-height: 520px; overflow-y: auto; }
.template-item { padding: 10px 12px; border: 1px solid #ebeef5; border-radius: 6px; margin-bottom: 8px; cursor: pointer; transition: all .2s; }
.template-item:hover { border-color: #409EFF; }
.template-item.active { border-color: #409EFF; background: #ecf5ff; }
.tpl-name { font-weight: 600; font-size: 13px; display: flex; align-items: center; gap: 6px; }
.tpl-meta { color: #909399; font-size: 12px; margin-top: 4px; }
.right-panel { flex: 1; }
.item-section { border-top: 1px solid #ebeef5; padding-top: 12px; }
.item-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; font-weight: 600; }
</style>
