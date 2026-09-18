<template>
  <el-dialog :title="isEdit ? '编辑题目' : '新增题目'" :visible="visible" width="750px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="120px" size="small">
      <!-- 题型：编辑时置灰不可修改 -->
      <el-form-item label="题型" prop="question_type">
        <el-select v-model="form.question_type" :disabled="isEdit" placeholder="请选择题型" style="width:220px" @change="onTypeChange">
          <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="题目内容" prop="question_text">
        <el-input v-model="form.question_text" type="textarea" :rows="3" placeholder="请输入题目内容" maxlength="1000" show-word-limit />
      </el-form-item>

      <!-- 选项设置 -->
      <el-form-item label="选项设置" v-if="form.question_type !== 'judge'">
        <div v-for="(opt, i) in form.options" :key="i" style="display:flex;gap:8px;margin-bottom:8px;align-items:center;">
          <el-tag size="mini" style="width:34px;text-align:center;">{{ opt.label }}</el-tag>
          <el-input v-model="opt.text" :placeholder="'请输入' + opt.label + '选项内容'" />
          <el-button v-if="form.options.length > 2" type="text" style="color:#F56C6C" @click="form.options.splice(i,1)">删除</el-button>
        </div>
        <el-button size="small" type="text" icon="el-icon-plus"
          :disabled="form.options.length >= maxOptions(form.question_type)" @click="addOption">添加选项</el-button>
        <div style="color:#909399;font-size:12px;line-height:1.6;">至少保留 2 个选项（单选题最多 4 个，多选题最多 5 个）</div>
      </el-form-item>
      <el-form-item label="选项设置" v-else>
        <div style="display:flex;gap:20px;color:#606266;font-size:13px;">
          <span><el-tag size="mini">对</el-tag> 正确</span>
          <span><el-tag size="mini">错</el-tag> 错误</span>
        </div>
      </el-form-item>

      <!-- 正确答案 -->
      <el-form-item label="正确答案" prop="answer">
        <el-radio-group v-if="form.question_type === 'single'" v-model="form.answer">
          <el-radio v-for="o in form.options" :key="o.label" :label="o.label">{{ o.label }}.{{ o.text }}</el-radio>
        </el-radio-group>
        <el-checkbox-group v-else-if="form.question_type === 'multiple'" v-model="multiAnswer">
          <el-checkbox v-for="o in form.options" :key="o.label" :label="o.label">{{ o.label }}.{{ o.text }}</el-checkbox>
        </el-checkbox-group>
        <el-radio-group v-else v-model="form.answer">
          <el-radio label="正确">正确</el-radio>
          <el-radio label="错误">错误</el-radio>
        </el-radio-group>
      </el-form-item>

      <el-form-item label="题目解析">
        <el-input v-model="form.analysis" type="textarea" :rows="2" placeholder="请输入题目解析（选填）" />
      </el-form-item>
      <el-form-item label="难度等级" prop="difficulty">
        <el-select v-model="form.difficulty" style="width:220px">
          <el-option v-for="d in diffOptions" :key="d.value" :label="d.label" :value="d.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="分类" prop="category_id">
        <el-select v-model="form.category_id" placeholder="请选择培训类型" style="width:220px">
          <el-option v-for="c in categoryOptions" :key="c.id" :label="c.name" :value="c.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="状态">
        <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="handleSave">提交</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addQuestion, editQuestion } from '@/api/trainingExam'

export default {
  name: 'QuestionFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null }, // 编辑时的行数据
    typeOptions: { type: Array, default: () => [] },
    diffOptions: { type: Array, default: () => [] },
    categoryOptions: { type: Array, default: () => [] },
  },
  computed: {
    isEdit() { return !!(this.row && this.row.id) },
  },
  data() {
    return {
      saving: false,
      form: { id: 0, question_type: 'single', question_text: '', options: [], answer: '', analysis: '', difficulty: 'normal', category_id: null, status: 1 },
      multiAnswer: [],
      rules: {
        question_type: [{ required: true, message: '请选择题型', trigger: 'change' }],
        question_text: [
          { required: true, message: '请输入题目内容', trigger: 'blur' },
          { min: 10, max: 1000, message: '题目内容长度为10-1000字符', trigger: 'blur' },
        ],
        answer: [{ required: true, message: '请设置正确答案', trigger: 'change' }],
        difficulty: [{ required: true, message: '请选择难度', trigger: 'change' }],
        category_id: [{ required: true, message: '请选择分类', trigger: 'change' }],
      },
    }
  },
  watch: {
    visible(val) {
      if (val) this.init()
    },
  },
  methods: {
    // 关闭弹窗时把事件转发给父组件，保证父组件 formVisible 同步为 false（避免再次打开无反应）
    handleVisibleChange(val) {
      this.$emit('update:visible', val)
    },
    maxOptions(type) { return type === 'single' ? 4 : 5 },
    defaultOptions(type) {
      if (type === 'judge') return []
      if (type === 'multiple') return ['A', 'B', 'C', 'D', 'E'].map(l => ({ label: l, text: '' }))
      return ['A', 'B', 'C', 'D'].map(l => ({ label: l, text: '' }))
    },
    onTypeChange() {
      this.form.answer = ''
      this.multiAnswer = []
      if (this.form.question_type === 'judge') {
        this.form.options = []
      } else {
        this.form.options = this.defaultOptions(this.form.question_type)
      }
    },
    addOption() {
      const max = this.maxOptions(this.form.question_type)
      if (this.form.options.length >= max) return
      const nextLabel = String.fromCharCode(65 + this.form.options.length)
      this.form.options.push({ label: nextLabel, text: '' })
    },
    async init() {
      this.form = { id: 0, question_type: 'single', question_text: '', options: this.defaultOptions('single'), answer: '', analysis: '', difficulty: 'normal', category_id: null, status: 1 }
      this.multiAnswer = []
      if (this.isEdit) {
        try {
          // 行数据已含完整字段（列表接口返回 options 数组）
          const d = { ...this.row }
          d.options = Array.isArray(d.options) ? d.options.map(o => ({ ...o })) : []
          if (d.question_type === 'judge') d.options = []
          if (d.question_type === 'multiple') this.multiAnswer = (d.answer || '').split(',').filter(Boolean)
          this.form = d
        } catch (e) {}
      }
      this.$nextTick(() => { if (this.$refs.formRef) this.$refs.formRef.clearValidate() })
    },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        // 前端补充校验：选项内容非空
        if (this.form.question_type !== 'judge') {
          const filled = this.form.options.filter(o => (o.text || '').trim() !== '')
          if (filled.length < 2) { this.$message.error('选项至少2个且内容不能为空'); return }
          for (const o of this.form.options) {
            if ((o.text || '').trim() === '') { this.$message.error(`选项${o.label}内容不能为空`); return }
          }
        }
        if (this.form.question_type === 'multiple') {
          if (!this.multiAnswer.length) { this.$message.error('请至少选择一个正确答案'); return }
          this.form.answer = this.multiAnswer.join(',')
        } else if (this.form.question_type === 'single') {
          if (!this.form.answer) { this.$message.error('请选择正确答案'); return }
        } else {
          if (!this.form.answer) { this.$message.error('请选择正确答案'); return }
          this.form.options = []
        }
        this.saving = true
        try {
          const payload = {
            question_text: this.form.question_text,
            options: this.form.options,
            answer: this.form.answer,
            analysis: this.form.analysis || '',
            difficulty: this.form.difficulty,
            category_id: this.form.category_id,
            status: this.form.status,
          }
          const r = this.isEdit
            ? await editQuestion(this.form.id, payload)
            : await addQuestion({ ...payload, question_type: this.form.question_type })
          if (r.code === 0) {
            this.$message.success(this.isEdit ? '保存成功' : '新增成功')
            this.handleVisibleChange(false)
            this.$emit('saved')
          }
        } catch (e) {}
        this.saving = false
      })
    },
  },
}
</script>
