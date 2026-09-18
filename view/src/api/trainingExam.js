/**
 * 培训考试 API 封装
 * 题库/试卷/考试/成绩：/safety/training/exam/*
 */
import request from './request'

// ===== 题库 =====
export const getQuestionList = (p) => request({ url: '/safety/training/exam/question/list', method: 'get', params: p })
export const getQuestionDetail = (id) => request({ url: `/safety/training/exam/question/detail/${id}`, method: 'get' })
export const addQuestion = (d) => request({ url: '/safety/training/exam/question/add', method: 'post', data: d })
export const editQuestion = (id, d) => request({ url: `/safety/training/exam/question/edit/${id}`, method: 'put', data: d })
export const deleteQuestion = (id) => request({ url: `/safety/training/exam/question/delete/${id}`, method: 'delete' })
export const importQuestions = (items) => request({ url: '/safety/training/exam/question/import', method: 'post', data: { items } })
export const exportQuestions = (p) => request({ url: '/safety/training/exam/question/export', method: 'get', params: p })
export const getQuestionStatistics = () => request({ url: '/safety/training/exam/question/statistics', method: 'get' })
export const batchDeleteQuestions = (ids) => request({ url: '/safety/training/exam/question/batch-delete', method: 'delete', data: { ids } })
export const changeQuestionStatus = (id, status) => request({ url: `/safety/training/exam/question/status/${id}`, method: 'put', data: { status } })
export const getQuestionTemplate = () => request({ url: '/safety/training/exam/question/template', method: 'get' })
export const importQuestionFile = (formData) => request({ url: '/safety/training/exam/question/import', method: 'post', data: formData })
export const getCategoryOptions = () => request({ url: '/safety/training/exam/question/category-options', method: 'get' })

// ===== 试卷 =====
export const getPaperList = (p) => request({ url: '/safety/training/exam/paper/list', method: 'get', params: p })
export const getPaperDetail = (id) => request({ url: `/safety/training/exam/paper/detail/${id}`, method: 'get' })
export const addPaper = (d) => request({ url: '/safety/training/exam/paper/add', method: 'post', data: d })
export const autoGeneratePaper = (d) => request({ url: '/safety/training/exam/paper/auto-generate', method: 'post', data: d })
export const editPaper = (id, d) => request({ url: `/safety/training/exam/paper/edit/${id}`, method: 'put', data: d })
export const deletePaper = (id) => request({ url: `/safety/training/exam/paper/delete/${id}`, method: 'delete' })
export const publishPaper = (id) => request({ url: `/safety/training/exam/paper/publish/${id}`, method: 'put' })
export const previewPaper = (id) => request({ url: `/safety/training/exam/paper/preview/${id}`, method: 'get' })
export const addPaperQuestions = (paperId, questionIds) => request({ url: '/safety/training/exam/paper/add-questions', method: 'post', data: { paper_id: paperId, question_ids: questionIds } })
export const removePaperQuestion = (paperId, questionId) => request({ url: '/safety/training/exam/paper/remove-question', method: 'delete', data: { paper_id: paperId, question_id: questionId } })
export const copyPaper = (id) => request({ url: `/safety/training/exam/paper/copy/${id}`, method: 'post' })
export const getAvailableQuestions = (p) => request({ url: '/safety/training/exam/paper/available-questions', method: 'get', params: p })

// ===== 考试 =====
export const getExamList = (p) => request({ url: '/safety/training/exam/record/list', method: 'get', params: p })
export const getExamDetail = (id) => request({ url: `/safety/training/exam/record/detail/${id}`, method: 'get' })
export const createExam = (d) => request({ url: '/safety/training/exam/record/create', method: 'post', data: d })
export const editExam = (id, d) => request({ url: `/safety/training/exam/record/edit/${id}`, method: 'put', data: d })
export const getExamMonitor = (id) => request({ url: `/safety/training/exam/record/monitor/${id}`, method: 'get' })
export const forceSubmitExam = (id, userId) => request({ url: `/safety/training/exam/record/force-submit/${id}`, method: 'put', data: { user_id: userId } })
export const extendExamTime = (id, userId, minutes) => request({ url: `/safety/training/exam/record/extend-time/${id}`, method: 'put', data: { user_id: userId, extend_minutes: minutes } })
export const deleteExam = (id) => request({ url: `/safety/training/exam/record/delete/${id}`, method: 'delete' })
export const getAvailablePapers = () => request({ url: '/safety/training/exam/record/available-papers', method: 'get' })
export const getExamScoreList = (id) => request({ url: `/safety/training/exam/record/score-list/${id}`, method: 'get' })
export const getExamScoreDetail = (examId, userId) => request({ url: `/safety/training/exam/record/score-detail/${examId}`, method: 'get', params: { user_id: userId } })
export const exportExamScore = (id) => request({ url: `/safety/training/exam/record/export-score/${id}`, method: 'get' })

// ===== 成绩管理（全局） =====
export const getScoreList = (p) => request({ url: '/safety/training/exam/score/list', method: 'get', params: p })
export const getScoreStatistics = () => request({ url: '/safety/training/exam/score/statistics', method: 'get' })
export const getScoreDetail = (examId, userId) => request({ url: '/safety/training/exam/score/detail', method: 'get', params: { exam_id: examId, user_id: userId } })
export const getScoreByExam = (examId, p) => request({ url: '/safety/training/exam/score/by-exam', method: 'get', params: { exam_id: examId, ...p } })
export const getScoreByUser = (userId, p) => request({ url: '/safety/training/exam/score/by-user', method: 'get', params: { user_id: userId, ...p } })
export const getScoreTrend = (months) => request({ url: '/safety/training/exam/score/trend', method: 'get', params: { months } })
export const exportScoreList = (p) => request({ url: '/safety/training/exam/score/export', method: 'get', params: p })

// ===== 关联数据 =====
export const getTypeOptions = () => request({ url: '/safety/training/plan/type/options', method: 'get' })
export const getTrainingRecordOptions = (p) => request({ url: '/safety/training/record/list', method: 'get', params: p })
