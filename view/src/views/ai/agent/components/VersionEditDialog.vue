<template>
  <el-dialog title="编辑版本" :visible.sync="visible" width="520px" append-to-body>
    <el-form :model="form" label-width="110px" size="small">
      <el-form-item label="版本号">
        <el-input :value="form.version_number" disabled />
      </el-form-item>
      <el-form-item label="发布类型">
        <el-radio-group v-model="form.publish_type">
          <el-radio v-for="opt in publishTypeOptions" :key="opt.value" :label="opt.value">{{ opt.label }}</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-form-item v-if="form.publish_type === 'gray'" label="灰度比例">
        <el-input-number v-model="form.gray_ratio" :min="1" :max="100" /> <span class="unit">%</span>
      </el-form-item>
      <el-form-item label="版本名称">
        <el-input v-model="form.version_name" maxlength="100" />
      </el-form-item>
      <el-form-item label="版本描述">
        <el-input v-model="form.version_desc" type="textarea" :rows="3" maxlength="500" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">保存</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { editPublishVersion } from '../../../../api/aiPublish'

export default {
  name: 'VersionEditDialog',
  data() {
    return {
      visible: false,
      saving: false,
      publishTypeOptions: [],
      form: { id: null, version_number: '', version_name: '', version_desc: '', publish_type: 'full', gray_ratio: 10 }
    }
  },
  methods: {
    // 发布类型从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('agent_publish_type'); this.publishTypeOptions = r.data || [] } catch (e) { this.publishTypeOptions = [] }
    },
    open(row) {
      this.loadDicts()
      this.form = {
        id: row.id, version_number: row.version_number, version_name: row.version_name || '',
        version_desc: row.version_desc || '', publish_type: row.publish_type || 'full',
        gray_ratio: Number(row.gray_ratio) || 10
      }
      this.visible = true
    },
    async submit() {
      this.saving = true
      try {
        const res = await editPublishVersion(this.form.id, {
          version_name: this.form.version_name, version_desc: this.form.version_desc,
          publish_type: this.form.publish_type, gray_ratio: this.form.gray_ratio
        })
        this.$message.success(res.msg || '已保存')
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>

<style scoped>
.unit { color: #909399; margin-left: 6px; font-size: 12px; }
</style>
