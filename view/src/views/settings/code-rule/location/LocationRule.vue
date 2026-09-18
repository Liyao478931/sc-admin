<!--
  文件：admin/src/views/settings/code-rule/location/LocationRule.vue
  功能：货位编码自动生成规则配置（预览 + 保存）
  权限：warehouse:setting:location:view / add / edit
-->
<template>
  <div class="rule-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>系统设置</el-breadcrumb-item>
      <el-breadcrumb-item>系统参数</el-breadcrumb-item>
      <el-breadcrumb-item>货位编码规则</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" class="rule-card">
      <div slot="header"><span style="font-weight:600">货位编码自动生成规则</span></div>
      <el-form :model="form" label-width="150px" size="small" style="max-width:580px">
        <el-form-item label="编码前缀" required>
          <el-input v-model="form.prefix" placeholder="如 WH" style="width:200px" />
          <span class="tip">编码统一前缀</span>
        </el-form-item>
        <el-form-item label="包含仓库编码">
          <el-switch v-model="form.include_warehouse" :active-value="1" :inactive-value="0" active-text="开启" inactive-text="关闭" @change="preview" />
        </el-form-item>
        <el-form-item v-if="form.include_warehouse === 1" label="仓库编码位置">
          <el-select v-model="form.warehouse_position" style="width:200px" @change="preview">
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
            <el-radio label="warehouse">按仓库</el-radio>
            <el-radio label="day">按日</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="编码示例预览">
          <div class="preview-box">
            <div><span class="preview-label">无仓库：</span><code>{{ previewNoWh || '-' }}</code></div>
            <div v-if="demoWh"><span class="preview-label">示例仓库（{{ demoWh.warehouse_name }}）：</span><code>{{ previewWh || '-' }}</code></div>
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
import { getLocationCodeRule, saveLocationCodeRule, getNextLocationCode, getWarehouseList } from '../../../../api/warehouse'

export default {
  name: 'LocationCodeRule',
  data () {
    return {
      form: { prefix: 'WH', include_warehouse: 1, warehouse_position: 'after', date_format: 'YYYYMMDD', seq_digits: 2, seq_mode: 'warehouse' },
      saving: false, previewNoWh: '', previewWh: '', demoWh: null
    }
  },
  created () { this.load() },
  methods: {
    async load () {
      try {
        const r = await getLocationCodeRule()
        if (r.code === 0 && r.data) this.form = Object.assign(this.form, r.data)
      } catch (e) {}
      try {
        const w = await getWarehouseList({ page: 1, pageSize: 1, status: 1 })
        if (w.code === 0 && w.data && w.data.list && w.data.list.length) this.demoWh = w.data.list[0]
      } catch (e) {}
      this.preview()
    },
    async preview () {
      try {
        const r1 = await getNextLocationCode(0)
        if (r1.code === 0 && r1.data) this.previewNoWh = r1.data.code
        if (this.demoWh) {
          const r2 = await getNextLocationCode(this.demoWh.id)
          if (r2.code === 0 && r2.data) this.previewWh = r2.data.code
        }
      } catch (e) {}
    },
    async handleSave () {
      if (!this.form.prefix.trim()) { this.$message.warning('请填写编码前缀'); return }
      this.saving = true
      try {
        const r = await saveLocationCodeRule(this.form)
        if (r.code === 0) { this.$message.success('保存成功'); this.preview() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.rule-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.rule-card { max-width: 740px; }
.tip { color: #909399; font-size: 12px; margin-left: 8px; }
.preview-box { background: #f5f7fa; border-radius: 6px; padding: 12px 16px; width: 100%; }
.preview-label { color: #606266; font-size: 13px; }
.preview-box code { background: #fff; border: 1px solid #dcdfe6; border-radius: 4px; padding: 2px 8px; margin-left: 6px; font-size: 13px; color: #409EFF; }
</style>
