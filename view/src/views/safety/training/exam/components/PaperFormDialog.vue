<template>
  <el-dialog :title="isEdit ? '编辑试卷' : '新增试卷'" :visible="visible" width="800px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <!-- 第一步：基本信息 -->
    <el-form ref="baseRef" :model="form" :rules="rules" label-width="120px" size="small" v-if="step === 1">
      <el-form-item label="试卷名称" prop="paper_name">
        <el-input v-model="form.paper_name" placeholder="请输入试卷名称" maxlength="100" />
      </el-form-item>
      <el-form-item label="关联培训类型" prop="training_type_id">
        <el-select v-model="form.training_type_id" placeholder="请选择培训类型" style="width:260px">
          <el-option v-for="t in typeOptions" :key="t.id" :label="t.name" :value="t.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="总分" prop="total_score">
        <el-input-number v-model="form.total_score" :min="1" :max="1000" />
      </el-form-item>
      <el-form-item label="及格分数" prop="pass_score">
        <el-input-number v-model="form.pass_score" :min="1" :max="1000" />
      </el-form-item>
      <el-form-item label="考试时长" prop="duration_minutes">
        <el-input-number v-model="form.duration_minutes" :min="1" :max="600" /> <span style="color:#909399;">分钟</span>
      </el-form-item>
      <el-form-item label="组卷方式" prop="mode">
        <el-radio-group v-model="form.mode">
          <el-radio label="auto">自动组卷</el-radio>
          <el-radio label="manual">手动组卷</el-radio>
        </el-radio-group>
      </el-form-item>
    </el-form>

    <!-- 第二步：自动组卷 -->
    <div v-else-if="step === 2 && form.mode === 'auto'">
      <div style="color:#E6A23C;font-size:12px;margin-bottom:12px;line-height:1.6;">
        抽题范围：{{ typeName }} 分类下的启用题目。若提示"题库题目不足"，请更换培训类型，或先在该分类下补充题目。
      </div>
      <el-form label-width="120px" size="small">
        <el-form-item label="题型数量">
          <span style="margin-right:10px;">单选</span><el-input-number v-model="autoPlan.single" :min="0" :max="200" size="small" />
          <span style="margin:0 10px 0 20px;">多选</span><el-input-number v-model="autoPlan.multiple" :min="0" :max="200" size="small" />
          <span style="margin:0 10px 0 20px;">判断</span><el-input-number v-model="autoPlan.judge" :min="0" :max="200" size="small" />
        </el-form-item>
        <el-form-item label="难度比例(%)">
          <span style="margin-right:10px;">简单</span><el-input-number v-model="autoPlan.easy" :min="0" :max="100" size="small" />
          <span style="margin:0 10px 0 20px;">中等</span><el-input-number v-model="autoPlan.normal" :min="0" :max="100" size="small" />
          <span style="margin:0 10px 0 20px;">困难</span><el-input-number v-model="autoPlan.hard" :min="0" :max="100" size="small" />
          <div style="color:#909399;font-size:12px;margin-top:6px;">三项之和必须等于 100（当前：{{ autoPlan.easy + autoPlan.normal + autoPlan.hard }}）</div>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" size="small" :loading="generating" @click="doAutoGenerate">生成题目</el-button>
          <el-button size="small" :disabled="!generated" @click="doAutoGenerate">重新生成</el-button>
        </el-form-item>
      </el-form>
      <el-alert v-if="autoError" type="error" :title="autoError" style="margin-bottom:10px;" />
      <el-table v-if="generated" :data="autoQuestions" size="mini" border max-height="300">
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="type_text" label="题型" width="80" align="center" />
        <el-table-column prop="question_text" label="题目内容" show-overflow-tooltip />
      </el-table>
      <div v-if="generated" style="margin-top:8px;font-size:13px;color:#67C23A;">已生成 {{ autoQuestions.length }} 道题目</div>
    </div>

    <!-- 第二步：手动组卷 -->
    <div v-else-if="step === 2 && form.mode === 'manual'">
      <el-form :inline="true" size="small">
        <el-form-item>
          <el-select v-model="manualFilter.question_type" clearable placeholder="全部题型" style="width:110px">
            <el-option v-for="opt in questionTypeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="manualFilter.difficulty" clearable placeholder="全部难度" style="width:110px">
            <el-option v-for="opt in difficultyOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="manualFilter.category_id" clearable placeholder="全部分类" style="width:130px">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="manualFilter.keyword" placeholder="题目关键词" clearable style="width:160px" @keyup.enter.native="loadAvailable(1)" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" size="small" @click="loadAvailable(1)">查询</el-button>
        </el-form-item>
      </el-form>
      <el-table :data="availableList" size="mini" border max-height="240" @selection-change="onAvailableSelect">
        <el-table-column type="selection" width="40" />
        <el-table-column prop="type_text" label="题型" width="70" align="center" />
        <el-table-column prop="question_text" label="题目内容" show-overflow-tooltip />
        <el-table-column prop="difficulty_text" label="难度" width="60" align="center" />
      </el-table>
      <div style="margin-top:6px;display:flex;justify-content:space-between;align-items:center;">
        <el-pagination small background layout="total, prev, pager, next" :total="availableTotal" :current-page.sync="availablePage" :page-size="10" @current-change="loadAvailable(availablePage)" />
        <el-button size="mini" type="primary" :disabled="!selectedAvailable.length" @click="addSelected">加入试卷（{{ selectedAvailable.length }}）</el-button>
      </div>
      <el-divider content-position="left">已选题目（{{ selectedIds.length }} 道，总分 {{ form.total_score }} 分）</el-divider>
      <el-table :data="selectedQuestions" size="mini" border max-height="200">
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="type_text" label="题型" width="70" align="center" />
        <el-table-column prop="question_text" label="题目内容" show-overflow-tooltip />
        <el-table-column label="操作" width="70" align="center">
          <template slot-scope="{ row }">
            <el-button size="mini" type="text" style="color:#F56C6C" @click="removeSelected(row)">移除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button v-if="step === 2" size="small" @click="step = 1">上一步</el-button>
      <el-button v-if="step === 1" size="small" type="primary" :loading="savingBase" @click="goStep2">下一步</el-button>
      <el-button v-if="step === 2" size="small" type="primary" :loading="saving" @click="finish">完成</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addPaper, editPaper, autoGeneratePaper, addPaperQuestions, removePaperQuestion, getAvailableQuestions, getPaperDetail } from '@/api/trainingExam'

export default {
  name: 'PaperFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
    typeOptions: { type: Array, default: () => [] },
  },
computed: {
  isEdit() { return !!(this.row && this.row.id) },
  typeName() {
    const t = this.typeOptions.find(x => x.id === this.form.training_type_id)
    return t ? t.name : '当前'
  },
},
  data() {
    return {
      step: 1, savingBase: false, saving: false,
      form: { paper_name: '', training_type_id: null, total_score: 100, pass_score: 60, duration_minutes: 60, mode: 'auto' },
      autoPlan: { single: 5, multiple: 3, judge: 2, easy: 30, normal: 50, hard: 20 },
      autoQuestions: [], autoError: '', generating: false, generated: false,
      manualFilter: { question_type: '', difficulty: '', category_id: null, keyword: '' },
      questionTypeOptions: [], difficultyOptions: [],
      availableList: [], availableTotal: 0, availablePage: 1, selectedAvailable: [], selectedIds: [], selectedQuestions: [], paperId: 0,
      rules: {
        paper_name: [{ required: true, message: '请输入试卷名称', trigger: 'blur' }],
        training_type_id: [{ required: true, message: '请选择培训类型', trigger: 'change' }],
        total_score: [{ required: true, message: '请输入总分', trigger: 'blur' }],
        pass_score: [{ required: true, message: '请输入及格分数', trigger: 'blur' }],
        duration_minutes: [{ required: true, message: '请输入考试时长', trigger: 'blur' }],
      },
    }
  },
  watch: {
    visible(val) { if (val) this.init() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    // 题型/难度从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../../api/dictionary')
      try { const r = await getDictByCode('exam_question_type'); this.questionTypeOptions = r.data || [] } catch (e) { this.questionTypeOptions = [] }
      try { const r = await getDictByCode('exam_difficulty'); this.difficultyOptions = r.data || [] } catch (e) { this.difficultyOptions = [] }
    },
    async init() {
      this.loadDicts()
      this.step = 1; this.autoQuestions = []; this.autoError = ''; this.generated = false;
      this.manualFilter = { question_type: '', difficulty: '', category_id: null, keyword: '' };
      this.selectedAvailable = []; this.selectedIds = []; this.selectedQuestions = []; this.paperId = 0;
      if (this.isEdit) {
        this.form = {
          paper_name: this.row.paper_name, training_type_id: this.row.training_type_id,
          total_score: this.row.total_score, pass_score: this.row.pass_score,
          duration_minutes: this.row.duration_minutes, mode: 'manual',
        }
        this.paperId = this.row.id
        // 编辑：加载已有题目到已选列表
        try {
          const r = await getPaperDetail(this.row.id)
          if (r.code === 0) {
            this.selectedIds = (r.data.question_ids || []).map(Number)
            this.selectedQuestions = r.data.questions || []
            // 回填自动组卷配置（若原试卷为自动组卷生成），便于重新组卷
            const cfg = r.data.question_config
            if (cfg && cfg.mode === 'auto') {
              this.form.mode = 'auto'
              if (cfg.plan) this.autoPlan = { ...this.autoPlan, single: cfg.plan.single || 0, multiple: cfg.plan.multiple || 0, judge: cfg.plan.judge || 0 }
              if (cfg.ratios) this.autoPlan = { ...this.autoPlan, easy: cfg.ratios.easy || 0, normal: cfg.ratios.normal || 0, hard: cfg.ratios.hard || 0 }
              this.autoQuestions = r.data.questions || []
              this.generated = this.autoQuestions.length > 0
            }
          }
        } catch (e) {}
      } else {
        this.form = { paper_name: '', training_type_id: null, total_score: 100, pass_score: 60, duration_minutes: 60, mode: 'auto' }
      }
      this.$nextTick(() => { if (this.$refs.baseRef) this.$refs.baseRef.clearValidate() })
    },
    async goStep2() {
      this.$refs.baseRef.validate(async (valid) => {
        if (!valid) return
        if (this.form.pass_score > this.form.total_score) { this.$message.error('及格分数不能超过总分'); return }
        this.savingBase = true
        try {
          if (this.isEdit) {
            await editPaper(this.paperId, {
              paper_name: this.form.paper_name, training_type_id: this.form.training_type_id,
              total_score: this.form.total_score, pass_score: this.form.pass_score, duration_minutes: this.form.duration_minutes,
            })
          } else {
            const r = await addPaper({
              paper_name: this.form.paper_name, training_type_id: this.form.training_type_id,
              total_score: this.form.total_score, pass_score: this.form.pass_score, duration_minutes: this.form.duration_minutes,
            })
            this.paperId = r.data.id
          }
          if (this.form.mode === 'manual' && this.selectedQuestions.length) {
            await addPaperQuestions(this.paperId, this.selectedIds)
          }
          this.step = 2
          if (this.form.mode === 'manual') this.loadAvailable(1)
        } catch (e) {}
        this.savingBase = false
      })
    },
    async doAutoGenerate() {
      if (this.autoPlan.single + this.autoPlan.multiple + this.autoPlan.judge <= 0) { this.$message.error('请设置至少一个题型数量'); return }
      if (this.autoPlan.easy + this.autoPlan.normal + this.autoPlan.hard !== 100) { this.$message.error('难度比例之和必须等于100'); return }
      this.generating = true; this.autoError = ''
      try {
        const r = await autoGeneratePaper({
          paper_id: this.paperId,
          single_count: this.autoPlan.single, multiple_count: this.autoPlan.multiple, judge_count: this.autoPlan.judge,
          easy_ratio: this.autoPlan.easy, normal_ratio: this.autoPlan.normal, hard_ratio: this.autoPlan.hard,
        })
        if (r.code === 0) {
          this.autoQuestions = r.data.questions || []; this.generated = true
          this.$message.success(`已生成 ${r.data.count} 道题目`)
        }
      } catch (e) { /* request.js 已弹出 msg（含题库不足提示） */ }
      this.generating = false
    },
    async loadAvailable(page = 1) {
      this.availablePage = page
      try {
        const r = await getAvailableQuestions({
          page, limit: 10, paper_id: this.paperId,
          keyword: this.manualFilter.keyword || '',
          question_type: this.manualFilter.question_type || '',
          difficulty: this.manualFilter.difficulty || '',
          category_id: this.manualFilter.category_id || '',
        })
        if (r.code === 0) { this.availableList = r.data.list || []; this.availableTotal = r.data.total || 0 }
      } catch (e) {}
    },
    onAvailableSelect(rows) { this.selectedAvailable = rows.map(x => x.id) },
    async addSelected() {
      if (!this.selectedAvailable.length) return
      try {
        const r = await addPaperQuestions(this.paperId, this.selectedAvailable)
        if (r.code === 0) {
          this.selectedIds = (r.data.question_ids || []).map(Number)
          this.selectedAvailable = []
          this.loadAvailable(1)
          await this.refreshSelected()
        }
      } catch (e) {}
    },
    async removeSelected(row) {
      try {
        const r = await removePaperQuestion(this.paperId, row.id)
        if (r.code === 0) {
          this.selectedIds = (r.data.question_ids || []).map(Number)
          this.selectedQuestions = this.selectedQuestions.filter(q => q.id !== row.id)
          this.loadAvailable(1)
        }
      } catch (e) {}
    },
    async refreshSelected() {
      try {
        const r = await getPaperDetail(this.paperId)
        if (r.code === 0) this.selectedQuestions = r.data.questions || []
      } catch (e) {}
    },
    finish() {
      this.handleVisibleChange(false)
      this.$emit('saved')
    },
  },
}
</script>
