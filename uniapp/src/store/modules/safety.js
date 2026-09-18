// 安全检查执行/培训考试状态管理
// 文件路径：src/store/modules/safety.js
import { defineStore } from 'pinia'

const DRAFT_KEY = 'safety_task_draft'

export const useSafetyStore = defineStore('safety', {
  state: () => ({
    currentTask: null,        // 当前任务信息
    templateItems: [],        // 检查项目列表（含结果、问题）
    summary: '',              // 检查总结
    stats: { qualified: 0, unqualified: 0, na: 0 }, // 统计
    draftData: null,          // 暂存数据
    certificates: [],         // 我的证书列表
    certDetail: null,         // 当前证书详情
    examList: [],             // 我的考试列表
    currentExam: null,        // 当前考试信息
    examQuestions: [],        // 题目列表（不含答案）
    examAnswers: {},          // 答案映射 { questionId: selected }
    examMarked: {},           // 标记映射 { questionId: true }
    currentIndex: 0,          // 当前题目索引
    examResult: null,         // 成绩结果
    accidentList: [],         // 我的上报列表
    accidentDetail: null,     // 上报详情
    accidentDraft: null,      // 本地暂存草稿
  }),

  actions: {
    /** 设置任务信息 */
    setTask(task) {
      this.currentTask = task
    },

    /** 初始化检查项目列表，支持回显暂存/已有结果 */
    initItems(templateItems, savedResult = []) {
      const savedMap = {}
      ;(savedResult || []).forEach((s, idx) => {
        savedMap[idx] = s
      })
      this.templateItems = (templateItems || []).map((t, idx) => {
        const saved = savedMap[idx] || {}
        return {
          item_name: t.item_name,
          check_standard: t.check_standard || '',
          check_method: t.check_method || '',
          is_required: !!t.is_required,
          result: saved.result || '',
          remark: saved.remark || '',
          issue_description: '',
          suggest: '',
          severity: 'minor',
          create_hazard: true,
        }
      })
      this.calcStats()
    },

    /** 设置单个项目结果 */
    setResult(idx, result) {
      const item = this.templateItems[idx]
      if (!item) return
      item.result = result
      if (result !== 'unqualified') {
        item.issue_description = ''
        item.suggest = ''
      }
      this.calcStats()
    },

    /** 统计合格/不合格/不适用数量 */
    calcStats() {
      this.stats = { qualified: 0, unqualified: 0, na: 0 }
      this.templateItems.forEach((it) => {
        if (it.result === 'qualified') this.stats.qualified++
        else if (it.result === 'unqualified') this.stats.unqualified++
        else if (it.result === 'na') this.stats.na++
      })
    },

    /** 组装提交用的项目结果数组 */
    buildItems() {
      return this.templateItems.map((it) => ({
        item_name: it.item_name,
        result: it.result || 'na',
        remark: it.result === 'unqualified' ? (it.issue_description || '') : '',
      }))
    },

    /** 组装问题列表（不合格项目都生成问题记录，是否转隐患由开关决定） */
    buildIssues() {
      return this.templateItems
        .filter((it) => it.result === 'unqualified')
        .map((it) => ({
          item_name: it.item_name,
          issue_description: it.issue_description || '',
          suggest: it.suggest || '',
          severity: it.severity || 'minor',
          create_hazard: !!it.create_hazard,
        }))
    },

    /** 暂存到本地 */
    saveDraft(taskId) {
      this.draftData = {
        taskId,
        items: this.templateItems.map((it) => ({ ...it })),
        summary: this.summary,
      }
      try {
        uni.setStorageSync(DRAFT_KEY + '_' + taskId, JSON.stringify(this.draftData))
      } catch (e) {}
    },

    /** 读取本地暂存 */
    loadDraft(taskId) {
      try {
        const raw = uni.getStorageSync(DRAFT_KEY + '_' + taskId)
        if (raw) this.draftData = JSON.parse(raw)
      } catch (e) { this.draftData = null }
      return this.draftData
    },

    /** 清空本地暂存 */
    clearDraft(taskId) {
      this.draftData = null
      try { uni.removeStorageSync(DRAFT_KEY + '_' + taskId) } catch (e) {}
    },

    /** 重置全部状态 */
    reset() {
      this.currentTask = null
      this.templateItems = []
      this.summary = ''
      this.stats = { qualified: 0, unqualified: 0, na: 0 }
      this.draftData = null
    },

    /** ===== 证书状态 ===== */
    setCertificates(list) {
      this.certificates = list
    },
    setCertDetail(detail) {
      this.certDetail = detail
    },

    /** ===== 在线考试状态 ===== */
    setExamList(list) { this.examList = list },
    setCurrentExam(exam) { this.currentExam = exam },
    /** 初始化答题数据 */
    initExam(questions, savedAnswers = {}) {
      this.examQuestions = questions || []
      this.examAnswers = {}
      this.examMarked = {}
      this.currentIndex = 0
      Object.keys(savedAnswers || {}).forEach((qid) => { this.examAnswers[qid] = savedAnswers[qid] })
    },
    /** 设置单题答案 */
    setExamAnswer(questionId, selected) { this.examAnswers[questionId] = selected },
    /** 切换标记 */
    toggleExamMark(questionId) {
      this.examMarked[questionId] = !this.examMarked[questionId]
    },
    /** 切换题目 */
    goExamQuestion(index) {
      const n = this.examQuestions.length
      if (n <= 0) return
      if (index < 0) index = 0
      if (index >= n) index = n - 1
      this.currentIndex = index
    },
    /** 已答题数 */
    answeredCount() {
      return Object.keys(this.examAnswers).filter((k) => (this.examAnswers[k] || '') !== '').length
    },
    setExamResult(result) { this.examResult = result },
    /** 重置考试状态 */
    resetExam() {
      this.currentExam = null
      this.examQuestions = []
      this.examAnswers = {}
      this.examMarked = {}
      this.currentIndex = 0
      this.examResult = null
    },

    /** ===== 事故上报状态 ===== */
    setAccidentList(list) { this.accidentList = list },
    setAccidentDetail(d) { this.accidentDetail = d },
    saveAccidentDraft(d) { this.accidentDraft = d; try { uni.setStorageSync('accident_draft', JSON.stringify(d)) } catch (e) {} },
    loadAccidentDraft() {
      try { const raw = uni.getStorageSync('accident_draft'); if (raw) this.accidentDraft = JSON.parse(raw) } catch (e) { this.accidentDraft = null }
      return this.accidentDraft
    },
    clearAccidentDraft() { this.accidentDraft = null; try { uni.removeStorageSync('accident_draft') } catch (e) {} },
  },
})
