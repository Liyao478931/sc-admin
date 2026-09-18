<template>
  <el-dialog title="创建版本" :visible.sync="visible" width="520px" append-to-body @closed="resetForm">
    <el-form :model="form" label-width="110px" size="small">
      <el-form-item label="版本类型">
        <el-radio-group v-model="form.version_type">
          <el-radio label="major">主版本 (+1.0.0)</el-radio>
          <el-radio label="minor">次版本 (+0.1.0)</el-radio>
          <el-radio label="patch">修订 (+0.0.1)</el-radio>
        </el-radio-group>
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
        <el-input v-model="form.version_name" maxlength="100" placeholder="如：v1.0 正式版" />
      </el-form-item>
      <el-form-item label="版本描述">
        <el-input v-model="form.version_desc" type="textarea" :rows="3" maxlength="500" placeholder="描述本次版本变更内容" />
      </el-form-item>
      <el-alert title="将自动保存当前智能体完整配置作为版本快照，并自动生成版本号" type="info" :closable="false" show-icon />
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">创建</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { createPublishVersion } from '../../../../api/aiPublish'

export default {
  name: 'VersionCreateDialog',
  props: {
    agentId: { type: String, default: '' }
  },
  data() {
    return {
      visible: false,
      saving: false,
      publishTypeOptions: [],
      form: { version_type: 'patch', publish_type: 'full', gray_ratio: 10, version_name: '', version_desc: '' }
    }
  },
  methods: {
    // 发布类型从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('agent_publish_type'); this.publishTypeOptions = r.data || [] } catch (e) { this.publishTypeOptions = [] }
    },
    open() {
      this.visible = true
      this.loadDicts()
    },
    resetForm() {
      this.form = { version_type: 'patch', publish_type: 'full', gray_ratio: 10, version_name: '', version_desc: '' }
    },
    async submit() {
      if (!this.agentId) return this.$message.warning('缺少智能体')
      this.saving = true
      try {
        const res = await createPublishVersion({
          agent_id: this.agentId,
          version_type: this.form.version_type,
          publish_type: this.form.publish_type,
          gray_ratio: this.form.gray_ratio,
          version_name: this.form.version_name,
          version_desc: this.form.version_desc
        })
        this.$message.success(res.msg || '版本已创建')
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
