<!--
  文件：admin/src/views/settings/code-rule/purchase-in/PurchaseInRule.vue
  功能：入库单编号自动生成规则配置（预览 + 保存）
  权限：warehouse:purchase:in:view / add / edit
-->
<template>
  <div class="rule-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>系统设置</el-breadcrumb-item>
      <el-breadcrumb-item>系统参数</el-breadcrumb-item>
      <el-breadcrumb-item>入库单编号规则</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" class="rule-card">
      <div slot="header"><span style="font-weight:600">入库单编号自动生成规则</span></div>
      <el-form :model="form" label-width="140px" size="small" style="max-width:520px">
        <el-form-item label="编号前缀" required>
          <el-input v-model="form.prefix" placeholder="如 IN" style="width:200px" />
        </el-form-item>
        <el-form-item label="日期格式">
          <el-select v-model="form.date_format" style="width:200px" @change="preview">
            <el-option label="YYYYMMDD" value="YYYYMMDD" /><el-option label="YYMMDD" value="YYMMDD" /><el-option label="无日期" value="" />
          </el-select>
        </el-form-item>
        <el-form-item label="流水号位数">
          <el-select v-model="form.seq_digits" style="width:200px" @change="preview">
            <el-option label="3位" :value="3" /><el-option label="4位" :value="4" /><el-option label="5位" :value="5" />
          </el-select>
        </el-form-item>
        <el-form-item label="流水号重置">
          <el-radio-group v-model="form.seq_reset">
            <el-radio label="day">每日重置</el-radio>
            <el-radio label="continuous">持续递增</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="编号示例预览">
          <code class="preview-code">{{ previewCode || '-' }}</code>
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
import { getPurchaseInCodeRule, savePurchaseInCodeRule, getPurchaseInNextCode } from '../../../../api/warehouse'

export default {
  name: 'PurchaseInCodeRule',
  data () {
    return {
      form: { prefix: 'IN', date_format: 'YYYYMMDD', seq_digits: 4, seq_reset: 'day' },
      saving: false, previewCode: ''
    }
  },
  created () { this.load() },
  methods: {
    async load () {
      try {
        const r = await getPurchaseInCodeRule()
        if (r.code === 0 && r.data) this.form = Object.assign(this.form, r.data)
      } catch (e) {}
      this.preview()
    },
    async preview () {
      try {
        const r = await getPurchaseInNextCode()
        if (r.code === 0 && r.data) this.previewCode = r.data.code
      } catch (e) {}
    },
    async handleSave () {
      if (!this.form.prefix.trim()) { this.$message.warning('请填写编号前缀'); return }
      this.saving = true
      try {
        const r = await savePurchaseInCodeRule(this.form)
        if (r.code === 0) { this.$message.success('保存成功'); this.preview() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.rule-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.rule-card { max-width: 680px; }
.preview-code { background: #f5f7fa; border: 1px solid #dcdfe6; border-radius: 4px; padding: 4px 10px; font-size: 14px; color: #409EFF; }
</style>
