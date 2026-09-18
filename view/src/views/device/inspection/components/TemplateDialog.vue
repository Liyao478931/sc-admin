<template>
  <el-dialog :title="mode === 'add' ? '新增巡检模板' : '编辑巡检模板'" :visible.sync="dialogVisible" width="800px" @open="handleOpen" @closed="resetForm">
    <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small">
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="模板名称" prop="template_name"><el-input v-model="form.template_name" maxlength="100" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="适用分类">
            <el-select v-model="form.category_id" clearable filterable style="width:100%">
              <el-option v-for="c in categoryOptions" :key="c.id" :label="c.name" :value="c.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="状态">
            <el-select v-model="form.status" style="width:100%">
              <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="模板描述"><el-input v-model="form.description" maxlength="255" /></el-form-item>
        </el-col>
      </el-row>

      <el-divider content-position="left">检查项列表（{{ items.length }} 项）</el-divider>
      <div v-for="(item, idx) in items" :key="idx" class="item-row">
        <el-row :gutter="8">
          <el-col :span="4"><el-input v-model="item.name" placeholder="检查项名称" size="small" /></el-col>
          <el-col :span="5"><el-input v-model="item.standard" placeholder="检查标准" size="small" /></el-col>
          <el-col :span="4">
            <el-select v-model="item.check_method" size="small" placeholder="检查方式" style="width:100%">
              <el-option label="目视" value="目视" /><el-option label="测量" value="测量" /><el-option label="功能测试" value="功能测试" />
            </el-select>
          </el-col>
          <el-col :span="5"><el-input v-model="item.normal_range" placeholder="正常值范围" size="small" /></el-col>
          <el-col :span="3">
            <el-switch v-model="item.required" :active-value="1" :inactive-value="0" active-text="必填" />
          </el-col>
          <el-col :span="3" style="text-align:right">
            <el-button type="text" size="small" icon="el-icon-delete" @click="items.splice(idx, 1)" />
          </el-col>
        </el-row>
      </div>
      <el-button size="small" type="primary" plain icon="el-icon-plus" @click="items.push({ name: '', standard: '', check_method: '目视', normal_range: '', required: 1 })">新增检查项</el-button>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" @click="submit">确认提交</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addTemplate, editTemplate, getTemplateDetail } from '@/api/deviceInspection'
import { getCategoryTree } from '@/api/deviceCategory'

export default {
  name: 'InspectionTemplateDialog',
  props: {
    visible: Boolean,
    mode: { type: String, default: 'add' },
    templateId: { type: Number, default: 0 }
  },
  data() {
    return {
      dialogVisible: this.visible,
      submitting: false,
      categoryOptions: [],
      statusOptions: [],
      items: [],
      form: { template_name: '', category_id: null, description: '', status: 'active' },
      rules: { template_name: [{ required: true, message: '请输入模板名称', trigger: 'blur' }] }
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val; if (val) this.loadDicts() }
  },
  methods: {
    // 状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('plan_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
    },
    async handleOpen() {
      this.form = { template_name: '', category_id: null, description: '', status: 'active' }
      this.items = []
      try {
        const cat = await getCategoryTree({ all: 1 })
        this.categoryOptions = this.flattenCat((cat.data && cat.data.list) || [])
      } catch (e) {}
      if (this.mode === 'edit' && this.templateId) await this.loadDetail(this.templateId)
    },
    flattenCat(nodes, arr = []) {
      (nodes || []).forEach(n => { arr.push({ id: n.id, name: n.name }); if (n.children && n.children.length) this.flattenCat(n.children, arr) })
      return arr
    },
    resetForm() { this.$refs.form && this.$refs.form.clearValidate() },
    async loadDetail(id) {
      try {
        const res = await getTemplateDetail(id)
        if (res.code !== 0) return
        const d = res.data
        this.form = { template_name: d.template_name, category_id: d.category_id, description: d.description || '', status: d.status }
        this.items = (d.items || []).map(x => ({ ...x }))
      } catch (e) {}
    },
    submit() {
      this.$refs.form.validate(async (valid) => {
        if (!valid) return
        const validItems = this.items.filter(x => x.name && String(x.name).trim())
        if (!validItems.length) { this.$message.warning('请至少填写一个检查项名称'); return }
        this.submitting = true
        try {
          const payload = { ...this.form, items: validItems }
          if (this.mode === 'add') { await addTemplate(payload); this.$message.success('创建成功') }
          else { await editTemplate(this.templateId, payload); this.$message.success('更新成功') }
          this.$emit('saved')
          this.dialogVisible = false
        } catch (e) { /* 拦截器已提示 */ }
        this.submitting = false
      })
    }
  }
}
</script>

<style scoped>
.item-row { background: #f8f9fb; border-radius: 4px; padding: 6px; margin-bottom: 6px; }
</style>
