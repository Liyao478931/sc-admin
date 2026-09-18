<!--
  文件：admin/src/views/settings/code-rule/material/CodeRule.vue
  功能：物料编码自动生成规则配置（预览 + 保存）
  权限：warehouse:setting:material:view / add / edit
-->
<template>
  <div class="rule-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>系统设置</el-breadcrumb-item>
      <el-breadcrumb-item>系统参数</el-breadcrumb-item>
      <el-breadcrumb-item>物料编码规则</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" class="rule-card">
      <div slot="header"><span style="font-weight:600">物料编码自动生成规则</span></div>
      <el-form :model="form" label-width="140px" size="small" style="max-width:560px">
        <el-form-item label="编码前缀" required>
          <el-input v-model="form.prefix" placeholder="如 M" style="width:200px" />
          <span class="tip">编码统一前缀（开启类型前缀后作为兜底前缀）</span>
        </el-form-item>
        <el-form-item label="按类型首字母前缀">
          <el-switch v-model="form.type_prefix" :active-value="1" :inactive-value="0" active-text="开启" inactive-text="关闭" @change="preview" />
          <span class="tip">原材料Y / 半成品B / 成品C / 备件J / 辅料F</span>
        </el-form-item>
        <el-form-item label="包含分类编码">
          <el-switch v-model="form.include_category" :active-value="1" :inactive-value="0" active-text="开启" inactive-text="关闭" @change="preview" />
        </el-form-item>
        <el-form-item v-if="form.include_category === 1" label="分类编码位置">
          <el-select v-model="form.category_position" style="width:200px" @change="preview">
            <el-option label="前缀后" value="after" /><el-option label="后缀" value="suffix" />
          </el-select>
        </el-form-item>
        <el-form-item label="日期格式">
          <el-select v-model="form.date_format" style="width:200px" @change="preview">
            <el-option label="不包含日期" value="" /><el-option label="YYYYMMDD" value="YYYYMMDD" /><el-option label="YYYYMM" value="YYYYMM" /><el-option label="YYMMDD" value="YYMMDD" />
          </el-select>
        </el-form-item>
        <el-form-item label="流水号位数">
          <el-input-number v-model="form.seq_digits" :min="1" :max="8" style="width:200px" @change="preview" />
          <span class="tip">固定位数，不足补零</span>
        </el-form-item>
        <el-form-item label="流水号递增方式">
          <el-radio-group v-model="form.seq_mode" @change="preview">
            <el-radio label="category">按分类</el-radio>
            <el-radio label="day">按日</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="编码示例预览">
          <div class="preview-box">
            <div><span class="preview-label">无分类：</span><code>{{ previewNoCat || '-' }}</code></div>
            <div><span class="preview-label">示例分类（密封件 MF）：</span><code>{{ previewCat || '-' }}</code></div>
          </div>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="saving" @click="handleSave">保存</el-button>
          <el-button @click="load">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { getCodeRule, saveCodeRule, getNextMaterialCode, getMaterialCategoryList, rebuildMaterialCodes } from '../../../../api/warehouse'

export default {
  name: 'MaterialCodeRule',
  data () {
    return {
      form: { prefix: 'M', type_prefix: 0, include_category: 1, category_position: 'after', date_format: 'YYYYMMDD', seq_digits: 4, seq_mode: 'category' },
      saving: false, rebuilding: false, previewNoCat: '', previewCat: '', demoCatId: 0
    }
  },
  created () { this.load() },
  methods: {
    async load () {
      try {
        const r = await getCodeRule()
        if (r.code === 0 && r.data) this.form = Object.assign(this.form, r.data)
      } catch (e) {}
      // 找一个示例分类用于预览
      try {
        const c = await getMaterialCategoryList({ page: 1, pageSize: 1, status: 1 })
        if (c.code === 0 && c.data && c.data.list && c.data.list.length) this.demoCatId = c.data.list[0].id
      } catch (e) {}
      this.preview()
    },
    async preview () {
      try {
        const [r1, r2] = await Promise.all([
          getNextMaterialCode(0, 1), // 无分类 + 原材料类型
          this.demoCatId ? getNextMaterialCode(this.demoCatId, 1) : Promise.resolve(null)
        ])
        if (r1.code === 0 && r1.data) this.previewNoCat = r1.data.code
        if (r2 && r2.code === 0 && r2.data) this.previewCat = r2.data.code
      } catch (e) {}
    },
    async handleSave () {
      if (!this.form.prefix.trim()) { this.$message.warning('请填写编码前缀'); return }
      this.saving = true
      try {
        const r = await saveCodeRule(this.form)
        if (r.code === 0) {
          this.$message.success('保存成功')
          this.preview()
          // 规则已保存：询问是否立即按新规则重建现有物料与产品编码
          this.$confirm('编码规则已保存。是否立即按新规则重建现有物料与产品编码？（产品编码同步更新，产品同步物料随之更新）', '重建编码', { type: 'warning', confirmButtonText: '立即重建', cancelButtonText: '暂不' }).then(async () => {
            this.rebuilding = true
            try {
              const rr = await rebuildMaterialCodes()
              if (rr.code === 0) {
                this.$message.success(`重建完成：物料修改 ${rr.data.material_changed} 条、产品修改 ${rr.data.product_changed} 条` + (rr.data.material_failed ? `，失败 ${rr.data.material_failed} 条` : ''))
              } else this.$message.error(rr.msg || '重建失败')
            } catch (e) {} finally { this.rebuilding = false }
          }).catch(() => {})
        } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.rule-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.rule-card { max-width: 720px; }
.tip { color: #909399; font-size: 12px; margin-left: 8px; }
.preview-box { background: #f5f7fa; border-radius: 6px; padding: 12px 16px; width: 100%; }
.preview-label { color: #606266; font-size: 13px; }
.preview-box code { background: #fff; border: 1px solid #dcdfe6; border-radius: 4px; padding: 2px 8px; margin-left: 6px; font-size: 13px; color: #409EFF; }
</style>
