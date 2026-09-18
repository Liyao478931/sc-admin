<template>
  <el-dialog :title="form.id ? '编辑敏感词' : '新增敏感词'" :visible.sync="visible" width="460px" append-to-body @closed="resetForm">
    <el-form :model="form" label-width="90px" size="small">
      <el-form-item label="敏感词" required>
        <el-input v-model="form.word" maxlength="100" placeholder="请输入敏感词" />
      </el-form-item>
      <el-form-item label="分类">
        <el-select v-model="form.category" style="width: 100%;">
          <el-option v-for="(v, k) in categoryMap" :key="k" :label="v" :value="k" />
        </el-select>
      </el-form-item>
      <el-form-item label="严重程度">
        <el-select v-model="form.severity" style="width: 100%;">
          <el-option v-for="(v, k) in severityMap" :key="k" :label="v" :value="k" />
        </el-select>
      </el-form-item>
      <el-form-item label="替换词">
        <el-input v-model="form.replace_with" maxlength="100" placeholder="留空则替换为 ***" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确定</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addSensitiveWord, editSensitiveWord } from '../../../../api/securityPolicy'

export default {
  name: 'SensitiveWordDialog',
  data() {
    return {
      visible: false,
      saving: false,
      categoryMap: { political: '政治', porn: '色情', violence: '暴力', ad: '广告', other: '其他' },
      severityMap: { low: '低', medium: '中', high: '高', critical: '严重' },
      form: { id: null, word: '', category: 'other', severity: 'medium', replace_with: '' }
    }
  },
  methods: {
    open(row) {
      if (row) {
        this.form = { id: row.id, word: row.word, category: row.category || 'other', severity: row.severity || 'medium', replace_with: row.replace_with || '' }
      }
      this.visible = true
    },
    resetForm() {
      this.form = { id: null, word: '', category: 'other', severity: 'medium', replace_with: '' }
    },
    async submit() {
      if (!this.form.word) return this.$message.warning('请输入敏感词')
      this.saving = true
      try {
        const payload = { word: this.form.word, category: this.form.category, severity: this.form.severity, replace_with: this.form.replace_with }
        if (this.form.id) await editSensitiveWord(this.form.id, payload)
        else await addSensitiveWord(payload)
        this.$message.success('保存成功')
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
