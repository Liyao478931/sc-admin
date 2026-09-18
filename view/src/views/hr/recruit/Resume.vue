<!--
  文件：admin/src/views/hr/recruit/Resume.vue
  功能：简历管理（搜索/新增/编辑/删除/筛选/淘汰/导入/导出/安排面试/面试评价/详情）
  权限：hr:recruit:view/add/edit/delete/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>招聘管理</el-breadcrumb-item>
      <el-breadcrumb-item>简历管理</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="姓名"><el-input v-model="query.candidate_name" placeholder="请输入姓名" clearable style="width:130px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="手机号"><el-input v-model="query.candidate_phone" placeholder="请输入手机号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="应聘职位">
          <el-select v-model="query.position_id" clearable placeholder="全部" style="width:150px">
            <el-option v-for="p in positionOptions" :key="p.id" :label="p.position_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="简历来源">
          <el-select v-model="query.source" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in SOURCE_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="简历状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in RESUME_STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'hr:recruit:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增简历</el-button>
        <el-button v-permission="'hr:recruit:add'" size="small" icon="el-icon-upload2" @click="importVisible = true">导入简历</el-button>
        <el-button v-permission="'hr:recruit:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无简历数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="简历编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.resume_no }}</el-link>
</template>
      </el-table-column>
      <el-table-column prop="candidate_name" label="应聘者" width="90" align="center" />
      <el-table-column prop="position_name" label="应聘职位" min-width="120" show-overflow-tooltip />
      <el-table-column prop="education_label" label="学历" width="110" align="center" />
      <el-table-column label="工作年限" width="90" align="center"><template slot-scope="s">{{ s.row.work_experience }} 年</template></el-table-column>
      <el-table-column label="简历来源" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.source_tag" effect="plain" size="mini">{{ s.row.source_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="简历状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="创建时间" width="160" align="center"><template slot-scope="s">{{ s.row.created_at || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="240" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'hr:recruit:edit'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4 || s.row.status === 5" v-permission="'hr:recruit:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" command="screen" icon="el-icon-check">筛选通过</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1 || s.row.status === 2" command="interview" icon="el-icon-calendar">安排面试</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1 || s.row.status === 2" command="eliminate" icon="el-icon-close">淘汰</el-dropdown-item>
              <el-dropdown-item v-if="!(s.row.status === 0 || s.row.status === 1 || s.row.status === 2)" disabled>当前状态无可执行操作</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑简历弹窗 -->
    <el-dialog :title="formId ? '编辑简历' : '新增简历'" :visible.sync="formVisible" width="760px" top="5vh">
      <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="应聘职位" prop="position_id"><el-select v-model="form.position_id" filterable placeholder="请选择应聘职位" style="width:100%"><el-option v-for="p in positionOptions" :key="p.id" :label="`${p.position_name}（${p.department_name || '-'}）`" :value="p.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="应聘者姓名" prop="candidate_name"><el-input v-model="form.candidate_name" placeholder="请输入姓名" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="联系电话" prop="candidate_phone"><el-input v-model="form.candidate_phone" maxlength="20" placeholder="请输入手机号" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="电子邮箱"><el-input v-model="form.candidate_email" placeholder="选填" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="性别" prop="candidate_gender"><el-select v-model="form.candidate_gender" style="width:100%"><el-option :value="1" label="男" /><el-option :value="2" label="女" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="年龄"><el-input-number v-model="form.candidate_age" :min="16" :max="80" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="学历" prop="education"><el-select v-model="form.education" style="width:100%"><el-option v-for="(t, v) in EDUCATION_TEXT" :key="v" :label="t" :value="Number(v)" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="工作年限" prop="work_experience"><el-input-number v-model="form.work_experience" :min="0" :max="60" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="毕业院校"><el-input v-model="form.school" placeholder="选填" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="专业"><el-input v-model="form.major" placeholder="选填" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="毕业年份"><el-input-number v-model="form.graduation_year" :min="1980" :max="2100" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="上一份工作"><el-input v-model="form.last_company" placeholder="单位（选填）" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="上一份岗位"><el-input v-model="form.last_position" placeholder="岗位（选填）" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="简历来源" prop="source"><el-select v-model="form.source" style="width:100%"><el-option v-for="(t, v) in SOURCE_TEXT" :key="v" :label="t" :value="Number(v)" /></el-select></el-form-item></el-col>
          <el-col v-if="form.source === 2" :span="12"><el-form-item label="推荐人" prop="recommender"><el-input v-model="form.recommender" placeholder="内部推荐人姓名" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="技能特长"><el-input v-model="form.skills" type="textarea" :rows="2" placeholder="技能特长（选填）" /></el-form-item></el-col>
          <el-col :span="24">
            <el-form-item label="简历附件">
              <el-upload :action="''" :auto-upload="false" :on-change="onFileChange" :file-list="uploadList" :limit="1" list-type="text">
                <el-button size="small" icon="el-icon-upload2">选择文件</el-button>
                <div slot="tip" class="upload-tip">支持 jpg/png/pdf/doc/docx，单个不超过 10MB</div>
              </el-upload>
              <div style="margin-top:6px">
                <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
              </div>
                <drive-file-picker :visible="driveVisible" mode="file" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
            </el-form-item>
          </el-col>
          <el-col :span="24"><el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" placeholder="备注信息（选填）" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <span slot="footer"><el-button size="small" @click="formVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button></span>
    </el-dialog>

    <!-- 导入简历弹窗 -->
    <el-dialog title="导入简历" :visible.sync="importVisible" width="480px">
      <div class="import-tip">
        <p>支持 xlsx/xls 文件，列顺序：应聘职位、姓名、电话、邮箱、性别（男/女）、年龄、学历（初中/高中/中专/大专/本科/硕士/博士）、毕业院校、专业、毕业年份、工作年限、上一份单位、上一份岗位、来源（招聘网站/内部推荐/校园招聘/人才市场/自主投递/其他）、推荐人。</p>
      </div>
      <el-upload :action="''" :auto-upload="false" :limit="1" :on-change="onImportFile" accept=".xlsx,.xls">
        <el-button size="small" type="primary" icon="el-icon-upload2">选择 Excel 文件</el-button>
      </el-upload>
      <div v-if="importResult" class="import-result" :class="{ ok: importResult.fail === 0 }">
        <p>导入结果：成功 {{ importResult.success }} 条，失败 {{ importResult.fail }} 条</p>
        <ul v-if="importResult.errors && importResult.errors.length"><li v-for="(e, i) in importResult.errors" :key="i">{{ e }}</li></ul>
      </div>
      <span slot="footer"><el-button size="small" @click="importVisible=false">关闭</el-button></span>
    </el-dialog>

    <!-- 详情抽屉 -->
    <el-drawer :title="'简历详情 - ' + (detail.resume_no || '')" :visible.sync="detailVisible" size="620px">
      <div class="drawer-body" v-if="detail.id">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="简历编号">{{ detail.resume_no }}</el-descriptions-item>
          <el-descriptions-item label="简历状态"><el-tag :type="detail.status_tag" size="mini">{{ detail.status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="应聘者">{{ detail.candidate_name }}</el-descriptions-item>
          <el-descriptions-item label="性别">{{ detail.gender_label || '-' }}</el-descriptions-item>
          <el-descriptions-item label="联系电话">{{ detail.candidate_phone }}</el-descriptions-item>
          <el-descriptions-item label="电子邮箱">{{ detail.candidate_email || '-' }}</el-descriptions-item>
          <el-descriptions-item label="应聘职位">{{ detail.position_name }}</el-descriptions-item>
          <el-descriptions-item label="年龄">{{ detail.candidate_age || '-' }}</el-descriptions-item>
          <el-descriptions-item label="学历">{{ detail.education_label }}</el-descriptions-item>
          <el-descriptions-item label="工作年限">{{ detail.work_experience }} 年</el-descriptions-item>
          <el-descriptions-item label="毕业院校">{{ detail.school || '-' }}</el-descriptions-item>
          <el-descriptions-item label="专业">{{ detail.major || '-' }}</el-descriptions-item>
          <el-descriptions-item label="毕业年份">{{ detail.graduation_year || '-' }}</el-descriptions-item>
          <el-descriptions-item label="上一份工作">{{ detail.last_company ? detail.last_company + ' / ' + (detail.last_position || '') : '-' }}</el-descriptions-item>
          <el-descriptions-item label="简历来源"><el-tag :type="detail.source_tag" effect="plain" size="mini">{{ detail.source_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="推荐人">{{ detail.recommender || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.creator_name }}</el-descriptions-item>
          <el-descriptions-item label="技能特长" :span="2">{{ detail.skills || '-' }}</el-descriptions-item>
          <el-descriptions-item label="筛选备注" :span="2">{{ detail.screening_remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
        </el-descriptions>

        <h4 class="section-title">
          面试记录
          <el-button v-if="[0, 1, 2].includes(detail.status)" size="mini" type="primary" style="float:right" @click="openInterview(detail)">安排面试</el-button>
        </h4>
        <el-table :data="detail.interviews || []" size="mini" border empty-text="暂无面试记录">
          <el-table-column label="轮次" width="70" align="center"><template slot-scope="s">{{ s.row.interview_round_label }}</template></el-table-column>
          <el-table-column label="类型" width="90" align="center"><template slot-scope="s">{{ s.row.interview_type_label }}</template></el-table-column>
          <el-table-column prop="interview_time" label="面试时间" width="140" />
          <el-table-column prop="interviewer_name" label="面试官" width="90" align="center" />
          <el-table-column label="结果" width="80" align="center"><template slot-scope="s"><el-tag :type="s.row.result_tag" size="mini">{{ s.row.result_label }}</el-tag></template></el-table-column>
          <el-table-column label="操作" width="110" align="center">
            <template slot-scope="s">
              <el-button v-if="s.row.status === 0" type="text" size="mini" @click="openEvaluate(s.row)">填写评价</el-button>
              <el-button v-if="s.row.status === 0" type="text" size="mini" class="danger" @click="handleCancelInterview(s.row)">取消</el-button>
              <span v-else>-</span>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-drawer>

    <!-- 安排面试弹窗 -->
    <el-dialog title="安排面试" :visible.sync="interviewVisible" width="520px">
      <el-form ref="ivForm" :model="ivForm" :rules="ivRules" label-width="100px" size="small">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="面试轮次" prop="interview_round"><el-select v-model="ivForm.interview_round" style="width:100%"><el-option v-for="(t, v) in ROUND_TEXT" :key="v" :label="t" :value="Number(v)" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="面试类型" prop="interview_type"><el-select v-model="ivForm.interview_type" style="width:100%"><el-option v-for="(t, v) in INTERVIEW_TYPE_TEXT" :key="v" :label="t" :value="Number(v)" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="面试时间" prop="interview_time"><el-date-picker v-model="ivForm.interview_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" placeholder="请选择面试时间" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="面试时长"><el-input-number v-model="ivForm.interview_duration" :min="10" :step="10" style="width:100%" /><span style="margin-left:6px;color:#909399;">分钟</span></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="面试官" prop="interviewer_id"><el-select v-model="ivForm.interviewer_id" filterable placeholder="请选择面试官" style="width:100%"><el-option v-for="u in interviewerOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="面试地点"><el-input v-model="ivForm.interview_location" placeholder="选填" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="面试备注"><el-input v-model="ivForm.interview_remark" type="textarea" :rows="2" placeholder="选填" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <span slot="footer"><el-button size="small" @click="interviewVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleSchedule">确认安排</el-button></span>
    </el-dialog>

    <!-- 面试评价弹窗 -->
    <el-dialog title="填写面试评价" :visible.sync="evaluateVisible" width="520px">
      <el-form ref="evForm" :model="evForm" :rules="evRules" label-width="100px" size="small">
        <el-form-item label="面试结果" prop="result"><el-radio-group v-model="evForm.result"><el-radio :label="1">通过</el-radio><el-radio :label="2">不通过</el-radio><el-radio :label="3">待定</el-radio></el-radio-group></el-form-item>
        <el-form-item label="评分"><el-input-number v-model="evForm.score" :min="1" :max="5" :step="0.5" :precision="1" style="width:200px" /><span style="margin-left:8px;color:#909399;">1-5 分</span></el-form-item>
        <el-form-item label="面试评价" prop="evaluation"><el-input v-model="evForm.evaluation" type="textarea" :rows="3" placeholder="请填写面试评价" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button size="small" @click="evaluateVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleEvaluate">保存</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getResumeList, saveResume, deleteResume, screenResume, eliminateResume, importResume, exportResume, getResumeDetail, scheduleInterview, evaluateInterview, cancelInterview, uploadRecruitFile } from '@/api/recruit'
import { getRecruitOptions } from '@/api/recruit'

const EDUCATION_TEXT = { 1: '初中及以下', 2: '高中/中专', 3: '大专', 4: '本科', 5: '硕士及以上' }
const SOURCE_TEXT = { 1: '招聘网站', 2: '内部推荐', 3: '校园招聘', 4: '人才市场', 5: '自主投递', 6: '其他' }
const RESUME_STATUS_TEXT = { 0: '待筛选', 1: '待面试', 2: '待复试', 3: '已录用', 4: '淘汰', 5: '已放弃' }
const ROUND_TEXT = { 1: '初试', 2: '复试', 3: '终试' }
const INTERVIEW_TYPE_TEXT = { 1: '现场面试', 2: '电话面试', 3: '视频面试' }

export default {
  name: 'RecruitResume',
  data () {
    return {
      driveVisible: false,
      EDUCATION_TEXT, SOURCE_TEXT, RESUME_STATUS_TEXT, ROUND_TEXT, INTERVIEW_TYPE_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, saving: false,
      positionOptions: [], interviewerOptions: [],
      query: { candidate_name: '', candidate_phone: '', position_id: '', source: '', status: '' },
      formVisible: false, formId: null, form: {}, uploadList: [],
      detailVisible: false, detail: {},
      importVisible: false, importResult: null,
      interviewVisible: false, ivForm: {}, currentResume: null,
      evaluateVisible: false, evForm: {}, currentInterview: null,
      rules: {
        position_id: [{ required: true, message: '请选择应聘职位', trigger: 'change' }],
        candidate_name: [{ required: true, message: '请填写姓名', trigger: 'blur' }],
        candidate_phone: [{ required: true, message: '请填写联系电话', trigger: 'blur' }],
        candidate_gender: [{ required: true, message: '请选择性别', trigger: 'change' }],
        education: [{ required: true, message: '请选择学历', trigger: 'change' }],
        work_experience: [{ required: true, message: '请填写工作年限', trigger: 'change' }],
        source: [{ required: true, message: '请选择简历来源', trigger: 'change' }],
        recommender: [{ required: true, message: '内部推荐请填写推荐人', trigger: 'blur' }]
      },
      ivRules: {
        interview_round: [{ required: true, message: '请选择面试轮次', trigger: 'change' }],
        interview_type: [{ required: true, message: '请选择面试类型', trigger: 'change' }],
        interview_time: [{ required: true, message: '请选择面试时间', trigger: 'change' }],
        interviewer_id: [{ required: true, message: '请选择面试官', trigger: 'change' }]
      },
      evRules: {
        result: [{ required: true, message: '请选择面试结果', trigger: 'change' }],
        evaluation: [{ required: true, message: '请填写面试评价', trigger: 'blur' }]
      }
    }
  },
  created () {
    this.getList()
    this.loadOptions()
  },
  methods: {
    async loadOptions () {
      try {
        const r = await getRecruitOptions()
        if (r.code === 0 && r.data) {
          this.positionOptions = r.data.positions || []
          this.interviewerOptions = r.data.interviewers || []
        }
      } catch (e) {}
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.query).forEach(k => { if (this.query[k] !== '' && this.query[k] !== null) p[k] = this.query[k] })
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getResumeList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { candidate_name: '', candidate_phone: '', position_id: '', source: '', status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    openForm (row) {
      this.formId = row ? row.id : null
      this.form = row ? {
        id: row.id, position_id: row.position_id, candidate_name: row.candidate_name, candidate_phone: row.candidate_phone,
        candidate_email: row.candidate_email || '', candidate_gender: row.candidate_gender, candidate_age: row.candidate_age || 18,
        education: row.education, school: row.school || '', major: row.major || '', graduation_year: row.graduation_year || 0,
        work_experience: row.work_experience || 0, last_company: row.last_company || '', last_position: row.last_position || '',
        skills: row.skills || '', resume_file: row.resume_file || '', source: row.source, recommender: row.recommender || '', remark: row.remark || ''
      } : {
        id: 0, position_id: 0, candidate_name: '', candidate_phone: '', candidate_email: '', candidate_gender: 1,
        candidate_age: 18, education: 3, school: '', major: '', graduation_year: 0, work_experience: 0,
        last_company: '', last_position: '', skills: '', resume_file: '', source: 1, recommender: '', remark: ''
      }
      this.uploadList = row && row.resume_file ? [{ name: row.resume_file.split('/').pop(), url: row.resume_file }] : []
      this.formVisible = true
    },
    onDrivePick(list) {
      const f = list[0]
      if (!f) return
      fetch(f.url).then(res => res.blob()).then(blob => {
        const raw = new File([blob], f.name, { type: blob.type || 'application/octet-stream' })
        this.onFileChange({ status: 'ready', raw, name: f.name, size: raw.size })
      }).catch(() => this.$message.error('读取网盘文件失败'))
    },
    onFileChange (file) {
      if (file.status === 'ready' && file.raw) {
        const fd = new FormData()
        fd.append('file', file.raw)
        uploadRecruitFile(fd).then(r => {
          if (r.code === 0 && r.data) {
            this.form.resume_file = r.data.url
            this.$message.success('上传成功')
          } else this.$message.error(r.msg || '上传失败')
        })
      }
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.saving = true
        saveResume(this.form).then(r => {
          if (r.code === 0) { this.$message.success(r.msg || '保存成功'); this.formVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该简历吗？删除后不可恢复', '提示', { type: 'warning' }).then(() => {
        deleteResume(row.id).then(r => { if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败') })
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'screen') this.handleScreen(row)
      else if (cmd === 'interview') this.openInterview(row)
      else if (cmd === 'eliminate') this.handleEliminate(row)
    },
    handleScreen (row) {
      this.$prompt('请输入筛选备注（可选）', '筛选通过', { inputPlaceholder: '筛选备注', inputValue: '' }).then(({ value }) => {
        screenResume(row.id, value || '').then(r => { if (r.code === 0) { this.$message.success('筛选已通过'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    handleEliminate (row) {
      this.$confirm(`确认淘汰应聘者 ${row.candidate_name} 吗？`, '淘汰', { type: 'warning' }).then(() => {
        eliminateResume(row.id).then(r => { if (r.code === 0) { this.$message.success('已淘汰'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    async openDetail (row) {
      this.detail = {}
      try {
        const r = await getResumeDetail(row.id)
        if (r.code === 0 && r.data) this.detail = r.data
      } catch (e) {}
      this.detailVisible = true
    },
    openInterview (row) {
      this.currentResume = row.id || row.id
      this.ivForm = { resume_id: row.id, interview_round: 1, interview_type: 1, interview_time: '', interview_duration: 60, interviewer_id: 0, interview_location: '', interview_remark: '' }
      this.interviewVisible = true
    },
    handleSchedule () {
      this.$refs.ivForm.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.saving = true
        scheduleInterview(this.ivForm).then(r => {
          if (r.code === 0) { this.$message.success('面试已安排'); this.interviewVisible = false; this.getList(); if (this.detailVisible) this.openDetail({ id: this.ivForm.resume_id }) } else this.$message.error(r.msg || '操作失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    openEvaluate (iv) {
      this.currentInterview = iv
      this.evForm = { result: 1, score: 4, evaluation: '' }
      this.evaluateVisible = true
    },
    handleEvaluate () {
      this.$refs.evForm.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.saving = true
        evaluateInterview(this.currentInterview.id, this.evForm).then(r => {
          if (r.code === 0) { this.$message.success('评价已保存'); this.evaluateVisible = false; this.getList(); this.openDetail({ id: this.currentInterview.resume_id }) } else this.$message.error(r.msg || '操作失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    handleCancelInterview (iv) {
      this.$confirm('确认取消该面试安排吗？', '取消面试', { type: 'warning' }).then(() => {
        cancelInterview(iv.id).then(r => { if (r.code === 0) { this.$message.success('已取消'); this.openDetail({ id: iv.resume_id }) } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    onImportFile (file) {
      if (file.status === 'ready' && file.raw) {
        const fd = new FormData()
        fd.append('file', file.raw)
        importResume(fd).then(r => {
          if (r.code === 0) { this.importResult = r.data || { success: 0, fail: 0 }; this.getList() } else { this.importResult = { success: 0, fail: 0, errors: [r.msg || '导入失败'] } }
        })
      }
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportResume(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `简历管理_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.danger { color: #F56C6C; }
.drawer-body { padding: 0 20px 20px; }
.section-title { margin: 20px 0 10px; color: #606266; border-bottom: 1px solid #f0f0f0; padding-bottom: 6px; }
.upload-tip { color: #909399; font-size: 12px; line-height: 1.6; }
.import-tip { color: #606266; font-size: 12px; line-height: 1.8; margin-bottom: 12px; background: #f5f7fa; border-radius: 4px; padding: 10px 12px; }
.import-result { margin-top: 12px; padding: 10px 12px; border-radius: 4px; background: #fef0f0; color: #f56c6c; font-size: 12px; }
.import-result.ok { background: #f0f9eb; color: #67c23a; }
.import-result ul { margin: 6px 0 0; padding-left: 18px; max-height: 120px; overflow-y: auto; }
</style>
