<template>
  <el-dialog :title="isEdit ? '编辑考试' : '创建考试'" :visible="visible" width="850px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <!-- 第一步：基本信息 -->
    <el-form ref="baseRef" :model="form" :rules="rules" label-width="120px" size="small" v-if="step === 1">
      <el-form-item label="考试名称" prop="exam_name">
        <el-input v-model="form.exam_name" placeholder="请输入考试名称（默认自动生成）" maxlength="100" />
      </el-form-item>
      <el-form-item label="考试类型" prop="exam_type">
        <el-radio-group v-model="form.exam_type">
          <el-radio v-for="opt in examTypeOptions" :key="opt.value" :label="opt.value">{{ opt.label }}</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-form-item label="选择试卷" prop="paper_id">
        <el-select v-model="form.paper_id" placeholder="仅显示已发布试卷" style="width:300px" @change="onPaperChange">
          <el-option v-for="p in paperOptions" :key="p.id" :label="`${p.paper_name}（${p.total_questions}题/${p.total_score}分）`" :value="p.id" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="form.exam_type === 'formal'" label="关联培训记录" prop="training_record_id">
        <el-select v-model="form.training_record_id" placeholder="请选择培训记录" style="width:300px">
          <el-option v-for="r in recordOptions" :key="r.id" :label="r.label" :value="r.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="开始时间" prop="start_time">
        <el-date-picker v-model="form.start_time" type="datetime" placeholder="选择开始时间" style="width:260px" />
      </el-form-item>
      <el-form-item label="结束时间" prop="end_time">
        <el-date-picker v-model="form.end_time" type="datetime" placeholder="选择结束时间" style="width:260px" />
      </el-form-item>
      <el-form-item label="考试时长" prop="duration_minutes">
        <el-input-number v-model="form.duration_minutes" :min="1" :max="600" /> <span style="color:#909399;">分钟</span>
      </el-form-item>
      <el-form-item label="补考规则">
        <el-input-number v-model="form.retake_limit" :min="0" :max="99" /> <span style="color:#909399;">次（0 = 不允许补考）</span>
        <div style="font-size:12px;color:#909399;line-height:1.6;">未通过考生可补考次数；通过后不可再考，补考次数用完后不可再考</div>
      </el-form-item>
      <el-form-item label="考试须知">
        <el-input v-model="form.exam_notice" type="textarea" :rows="2" placeholder="请输入考试须知（选填）" />
      </el-form-item>
    </el-form>

    <!-- 第二步：选择考生（仅新增） -->
    <div v-else-if="step === 2">
      <el-form label-width="120px" size="small">
        <el-form-item label="考生类型">
          <el-radio-group v-model="participantType">
            <el-radio label="department">按部门</el-radio>
            <el-radio label="position">按岗位</el-radio>
            <el-radio label="user">按人员</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="选择">
          <el-tree v-if="participantType === 'department'" ref="deptTree" :data="deptTree" show-checkbox node-key="id" :props="{ label: 'name', children: 'children' }" style="max-height:220px;overflow:auto;" />
          <el-select v-else-if="participantType === 'position'" v-model="positionIds" multiple placeholder="请选择岗位" style="width:320px">
            <el-option v-for="p in positionOptions" :key="p.id" :label="p.name" :value="p.id" />
          </el-select>
          <el-select v-else v-model="userIds" multiple filterable remote :remote-method="searchUsers" :loading="userLoading" placeholder="输入姓名/用户名搜索" style="width:320px">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="已选考生">
          <div v-if="selectedNames.length" style="max-height:160px;overflow:auto;">
            <el-tag v-for="(n, i) in selectedNames" :key="i" closable style="margin:2px 6px 2px 0;" @close="removeSelected(i)">{{ n }}</el-tag>
          </div>
          <span v-else style="color:#909399;">尚未选择考生（正式考试未选择时默认取培训记录参训人员）</span>
        </el-form-item>
      </el-form>
    </div>

    <!-- 第三步：确认信息（仅新增） -->
    <div v-else-if="step === 3">
      <el-descriptions :column="2" size="small" border>
        <el-descriptions-item label="考试名称">{{ form.exam_name }}</el-descriptions-item>
        <el-descriptions-item label="考试类型">{{ form.exam_type === 'formal' ? '正式考试' : '练习模式' }}</el-descriptions-item>
        <el-descriptions-item label="试卷">{{ paperName }}</el-descriptions-item>
        <el-descriptions-item label="培训记录">{{ recordName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="考试时间">{{ form.start_time }} ~ {{ form.end_time }}</el-descriptions-item>
        <el-descriptions-item label="考试时长">{{ form.duration_minutes }} 分钟</el-descriptions-item>
        <el-descriptions-item label="应考人数" :span="2">{{ selectedNames.length || (form.training_record_id ? '培训参训人员' : 0) }}</el-descriptions-item>
        <el-descriptions-item v-if="form.exam_notice" label="考试须知" :span="2">{{ form.exam_notice }}</el-descriptions-item>
      </el-descriptions>
    </div>

    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button v-if="step > 1 && !isEdit" size="small" @click="step--">上一步</el-button>
      <el-button v-if="step === 1 && !isEdit" size="small" type="primary" :loading="saving" @click="goStep2">下一步</el-button>
      <el-button v-if="step === 2" size="small" type="primary" @click="step = 3">下一步</el-button>
      <el-button v-if="(step === 3 || isEdit)" size="small" type="primary" :loading="saving" @click="submit">提交</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { createExam, editExam, getExamDetail, getAvailablePapers } from '@/api/trainingExam'
import { getRecordList } from '@/api/safetyTrainingRecord'
import { getUserList } from '@/api/user'
import { getDeptTree, getPositions } from '@/api/organization'

export default {
  name: 'ExamCreateDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
    paperOptions: { type: Array, default: () => [] },
  },
  computed: {
    isEdit() { return !!(this.row && this.row.id) },
    paperName() { const p = this.paperOptions.find(x => x.id === this.form.paper_id); return p ? p.paper_name : '' },
  },
  data() {
    return {
      step: 1, saving: false,
      form: { exam_name: '', exam_type: 'formal', paper_id: null, training_record_id: null, start_time: '', end_time: '', duration_minutes: 60, retake_limit: 0, exam_notice: '' },
      examTypeOptions: [],
      recordOptions: [], recordName: '',
      participantType: 'department', deptTree: [], positionOptions: [], positionIds: [],
      userIds: [], userOptions: [], userLoading: false, selectedNames: [],
      rules: {
        exam_name: [{ required: true, message: '请输入考试名称', trigger: 'blur' }],
        exam_type: [{ required: true, message: '请选择考试类型', trigger: 'change' }],
        paper_id: [{ required: true, message: '请选择试卷', trigger: 'change' }],
        training_record_id: [{ required: true, message: '正式考试必须关联培训记录', trigger: 'change' }],
        start_time: [{ required: true, message: '请选择开始时间', trigger: 'change' }],
        end_time: [{ required: true, message: '请选择结束时间', trigger: 'change' }],
        duration_minutes: [{ required: true, message: '请输入考试时长', trigger: 'blur' }],
      },
    }
  },
  watch: {
    visible(val) { if (val) this.init() },
    'form.exam_type'(v) {
      if (v === 'practice') this.form.training_record_id = null
    },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    // 考试类型从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../../api/dictionary')
      try { const r = await getDictByCode('exam_type'); this.examTypeOptions = r.data || [] } catch (e) { this.examTypeOptions = [] }
    },
    async init() {
      this.loadDicts()
      this.step = 1; this.saving = false
      this.selectedNames = []; this.positionIds = []; this.userIds = []; this.participantType = 'department'
      if (this.isEdit) {
        try {
          const r = await getExamDetail(this.row.id)
          if (r.code === 0) {
            const d = r.data
            this.form = {
              exam_name: d.exam_name, exam_type: d.exam_type, paper_id: d.paper_id,
              training_record_id: d.training_record_id || null,
              start_time: d.start_time, end_time: d.end_time,
              duration_minutes: d.duration_minutes, retake_limit: d.retake_limit || 0, exam_notice: d.exam_notice || '',
            }
          }
        } catch (e) {}
      } else {
        this.form = { exam_name: '', exam_type: 'formal', paper_id: null, training_record_id: null, start_time: '', end_time: '', duration_minutes: 60, retake_limit: 0, exam_notice: '' }
      }
      this.loadRecords(); this.loadDeptTree(); this.loadPositions()
      this.$nextTick(() => { if (this.$refs.baseRef) this.$refs.baseRef.clearValidate() })
    },
    async loadRecords() {
      try {
        const r = await getRecordList({ page: 1, limit: 50 })
        const list = r.data.list || r.data || []
        this.recordOptions = list.map(x => ({ id: x.id, label: x.plan_name ? `${x.record_code} ${x.plan_name}` : (x.record_code || `记录${x.id}`) }))
      } catch (e) {}
    },
    async loadDeptTree() {
      try { const r = await getDeptTree(); this.deptTree = r.data || [] } catch (e) {}
    },
    async loadPositions() {
      try { const r = await getPositions(); this.positionOptions = r.data || [] } catch (e) {}
    },
    async searchUsers(keyword) {
      if (!keyword) return
      this.userLoading = true
      try {
        const r = await getUserList({ keyword, page: 1, limit: 30 })
        this.userOptions = r.data.list || r.data || []
      } catch (e) {}
      this.userLoading = false
    },
    onPaperChange(id) {
      const p = this.paperOptions.find(x => x.id === id)
      if (p) this.form.duration_minutes = p.duration_minutes
    },
    goStep2() {
      this.$refs.baseRef.validate((valid) => {
        if (!valid) return
        if (this.form.exam_type === 'formal' && !this.form.training_record_id) { this.$message.error('正式考试必须关联培训记录'); return }
        if (new Date(this.form.end_time) <= new Date(this.form.start_time)) { this.$message.error('结束时间必须晚于开始时间'); return }
        this.selectedNames = []
        this.step = 2
      })
    },
    async collectParticipants() {
      if (this.participantType === 'department') {
        const checked = this.$refs.deptTree ? this.$refs.deptTree.getCheckedKeys() : []
        const half = this.$refs.deptTree ? this.$refs.deptTree.getHalfCheckedKeys() : []
        const ids = [...checked, ...half]
        this.selectedNames = ids.map(id => this.findDeptName(this.deptTree, id) || '部门#' + id)
        return { type: 'department', ids }
      }
      if (this.participantType === 'position') {
        this.selectedNames = this.positionOptions.filter(p => this.positionIds.includes(p.id)).map(p => p.name)
        return { type: 'position', ids: this.positionIds }
      }
      this.selectedNames = this.userOptions.filter(u => this.userIds.includes(u.id)).map(u => u.real_name || u.username)
      return { type: 'user', ids: this.userIds }
    },
    findDeptName(tree, id) {
      for (const n of tree || []) {
        if (n.id === id) return n.name
        if (n.children && n.children.length) {
          const r = this.findDeptName(n.children, id)
          if (r) return r
        }
      }
      return ''
    },
    removeSelected(i) { this.selectedNames.splice(i, 1) },
    async submit() {
      this.saving = true
      try {
        if (this.isEdit) {
          const r = await editExam(this.row.id, {
            exam_name: this.form.exam_name, start_time: this.form.start_time,
            end_time: this.form.end_time, duration_minutes: this.form.duration_minutes,
            retake_limit: this.form.retake_limit, exam_notice: this.form.exam_notice,
          })
          if (r.code === 0) { this.$message.success('保存成功'); this.handleVisibleChange(false); this.$emit('saved') }
        } else {
          const parts = await this.collectParticipants()
          const r = await createExam({
            exam_name: this.form.exam_name, paper_id: this.form.paper_id,
            training_record_id: this.form.training_record_id, exam_type: this.form.exam_type,
            start_time: this.form.start_time, end_time: this.form.end_time,
            duration_minutes: this.form.duration_minutes, retake_limit: this.form.retake_limit, exam_notice: this.form.exam_notice,
            participant_type: parts.type, participant_ids: parts.ids,
          })
          if (r.code === 0) { this.$message.success('考试创建成功'); this.handleVisibleChange(false); this.$emit('saved') }
        }
      } catch (e) {}
      this.saving = false
    },
  },
}
</script>
