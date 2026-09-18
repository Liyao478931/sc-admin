<template>
  <el-dialog :title="form.id ? '编辑测试用例' : '新增测试用例'" :visible.sync="visible" width="560px" append-to-body @closed="resetForm">
    <el-form :model="form" label-width="100px" size="small">
      <el-form-item label="用例名称" required>
        <el-input v-model="form.case_name" maxlength="50" placeholder="如：查询设备保养计划" />
      </el-form-item>
      <el-form-item label="输入内容" required>
        <el-input v-model="form.input" type="textarea" :rows="3" placeholder="输入测试问题" />
      </el-form-item>
      <el-form-item label="期望输出">
        <el-input v-model="form.expected_output" type="textarea" :rows="3" placeholder="选填，期望的AI回答" />
      </el-form-item>
      <el-form-item label="期望工具">
        <el-select v-model="form.expected_tools" multiple filterable placeholder="选填，期望调用的工具" style="width: 100%;">
          <el-option v-for="t in toolOptions" :key="t.id" :label="t.tool_display_name || t.tool_name" :value="t.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="标签">
        <el-tag v-for="(tag, i) in form.tags" :key="i" size="small" closable @close="removeTag(i)">{{ tag }}</el-tag>
        <el-input
          v-if="tagInputVisible"
          v-model="tagInput"
          size="small"
          style="width: 120px;"
          @keyup.enter.native="addTag"
          @blur="addTag"
        />
        <el-button v-else size="small" icon="el-icon-plus" @click="tagInputVisible = true">添加标签</el-button>
      </el-form-item>
      <el-form-item label="状态">
        <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确定</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addEvalCase, editEvalCase } from '../../../../api/aiEval'
import { getAiToolOptions } from '../../../../api/aiTool'

export default {
  name: 'EvalCaseDialog',
  data() {
    return {
      visible: false,
      saving: false,
      toolOptions: [],
      tagInputVisible: false,
      tagInput: '',
      form: {
        id: null, case_name: '', input: '', expected_output: '',
        expected_tools: [], tags: [], status: 1
      }
    }
  },
  methods: {
    async loadTools() {
      try { this.toolOptions = (await getAiToolOptions()).data || [] } catch (e) {}
    },
    open(row, prefillInput) {
      this.loadTools()
      if (row) {
        this.form = {
          id: row.id, case_name: row.case_name, input: row.input,
          expected_output: row.expected_output || '',
          expected_tools: (row.expected_tools || []).map(Number),
          tags: row.tags || [], status: Number(row.status)
        }
      } else {
        this.form = {
          id: null, case_name: '', input: prefillInput || '', expected_output: '',
          expected_tools: [], tags: [], status: 1
        }
      }
      this.visible = true
    },
    resetForm() {
      this.form = { id: null, case_name: '', input: '', expected_output: '', expected_tools: [], tags: [], status: 1 }
      this.tagInputVisible = false
      this.tagInput = ''
    },
    addTag() {
      const t = this.tagInput.trim()
      if (t && !this.form.tags.includes(t)) this.form.tags.push(t)
      this.tagInput = ''
      this.tagInputVisible = false
    },
    removeTag(i) {
      this.form.tags.splice(i, 1)
    },
    async submit() {
      if (!this.form.case_name) return this.$message.warning('请输入用例名称')
      if (!this.form.input) return this.$message.warning('请输入输入内容')
      this.saving = true
      try {
        const payload = {
          case_name: this.form.case_name, input: this.form.input,
          expected_output: this.form.expected_output,
          expected_tools: this.form.expected_tools, tags: this.form.tags,
          status: this.form.status
        }
        if (this.form.id) await editEvalCase(this.form.id, payload)
        else await addEvalCase(payload)
        this.$message.success('保存成功')
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
