<!--
  文件：admin/src/views/hr/recruit/Apply.vue
  功能：招聘投递 H5（公开访问，无需登录）— 品牌区 / 职位列表 / 职位详情 / 投递表单 / 投递成功
  访问：/admin/#/hr/recruit/apply（meta.noAuth）
-->
<template>
  <div class="apply-page">
    <!-- 顶部品牌区 -->
    <div class="brand" :style="brandBg">
      <div class="brand-inner">
        <div v-if="brand.logo" class="brand-logo"><img :src="brand.logo" alt="logo" /></div>
        <div v-else class="brand-logo brand-logo-default">{{ brand.company_name.charAt(0) }}</div>
        <div class="brand-text">
          <div class="brand-name">{{ brand.company_name }}</div>
          <div class="brand-slogan">{{ brand.slogan }}</div>
        </div>
      </div>
    </div>

    <!-- 职位列表区 -->
    <div class="container" v-if="!submitted">
      <div class="section-header">
        <span class="section-title">热招职位</span>
        <span class="count-text">共 {{ filteredPositions.length }} 个职位</span>
      </div>

      <div class="search-box">
        <el-input v-model="keyword" placeholder="搜索职位名称..." prefix-icon="el-icon-search" clearable size="medium" />
      </div>

      <div class="category-tabs">
        <span v-for="c in categories" :key="c.value" class="cat-tab" :class="{ active: category === c.value }" @click="category = c.value">{{ c.label }}</span>
      </div>

      <template v-if="filteredPositions.length">
        <div v-for="p in filteredPositions" :key="p.id" class="job-card" @click="openDetail(p)">
          <div class="job-head">
            <span class="job-name">{{ p.position_name }}</span>
            <el-tag v-if="p.recruit_count - p.hired_count > 0" type="danger" size="mini" effect="plain">急聘</el-tag>
            <el-tag v-else type="info" size="mini" effect="plain">招聘中</el-tag>
          </div>
          <div class="job-salary">{{ money(p.salary_range_min) }}-{{ money(p.salary_range_max) }}元/月</div>
          <div class="job-meta">
            <span>{{ p.department_name }}</span>
            <span>招聘 {{ p.recruit_count }} 人</span>
            <span v-if="p.work_location">📍 {{ p.work_location }}</span>
          </div>
          <div class="job-foot">
            <span class="job-cat">{{ p.position_category_label }}</span>
            <el-button type="primary" size="mini" round @click.stop="applyNow(p)">立即投递</el-button>
          </div>
        </div>
      </template>
      <div v-else class="empty-box">
        <i class="el-icon-s-custom empty-icon"></i>
        <p>暂无招聘职位，敬请期待</p>
        <el-button size="small" round @click="$message({ message: '可关注我司公众号获取最新招聘信息', type: 'info' })">关注我们</el-button>
      </div>
    </div>

    <!-- 投递表单区 -->
    <div class="container" v-if="!submitted" ref="formArea">
      <div class="section-header">
        <span class="section-title">在线投递简历</span>
      </div>
      <p class="form-sub">请填写以下信息，我们将在3个工作日内与您联系</p>

      <el-form ref="form" :model="form" :rules="rules" label-position="top" size="medium">
        <el-form-item label="应聘职位" prop="position_id">
          <el-input :value="selectedPositionName" placeholder="从职位列表选择带入" readonly>
            <el-button slot="append" size="small" @click="scrollToJobs">选择职位</el-button>
          </el-input>
        </el-form-item>
        <el-form-item label="姓名" prop="candidate_name">
          <el-input v-model="form.candidate_name" placeholder="请输入您的姓名" maxlength="20" />
        </el-form-item>
        <el-form-item label="手机号" prop="candidate_phone">
          <el-input v-model="form.candidate_phone" type="tel" placeholder="请输入您的手机号" maxlength="11" />
        </el-form-item>
        <el-form-item label="邮箱" prop="candidate_email">
          <el-input v-model="form.candidate_email" placeholder="请输入您的邮箱（选填）" />
        </el-form-item>
        <el-form-item label="性别" prop="candidate_gender">
          <el-radio-group v-model="form.candidate_gender">
            <el-radio :label="1">男</el-radio>
            <el-radio :label="2">女</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="学历" prop="education">
          <el-select v-model="form.education" placeholder="请选择您的学历" style="width:100%">
            <el-option v-for="(t, v) in EDUCATION_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="工作年限" prop="work_experience">
          <el-select v-model="form.work_experience" placeholder="请选择您的工作年限" style="width:100%">
            <el-option v-for="w in WORK_EXP" :key="w" :label="w" :value="w" />
          </el-select>
        </el-form-item>
        <el-form-item label="期望薪资" prop="expected_salary">
          <el-select v-model="form.expected_salary" placeholder="请选择您的期望薪资（选填）" clearable style="width:100%">
            <el-option v-for="s in EXPECTED_SALARY" :key="s" :label="s" :value="s" />
          </el-select>
        </el-form-item>
        <el-form-item label="简历附件">
          <el-upload :action="''" :auto-upload="false" :on-change="onFileChange" :file-list="uploadList" :limit="1" :on-remove="onFileRemove" accept=".pdf,.doc,.docx" list-type="text">
            <el-button size="small" icon="el-icon-upload2">点击上传简历附件（建议PDF格式，选填）</el-button>
            <div slot="tip" class="upload-tip">支持 pdf/doc/docx，单个不超过 5MB</div>
          </el-upload>
        </el-form-item>
        <el-form-item label="备注/自荐语" prop="self_introduction">
          <el-input v-model="form.self_introduction" type="textarea" :rows="4" maxlength="500" show-word-limit placeholder="请简要介绍您的优势或补充说明（选填）" />
        </el-form-item>
        <el-button class="submit-btn" type="primary" size="medium" :loading="submitting" @click="handleSubmit">提交简历</el-button>
      </el-form>
    </div>

    <!-- 投递成功反馈区 -->
    <div class="container success-box" v-else>
      <div class="success-icon"><i class="el-icon-check"></i></div>
      <div class="success-title">投递成功！</div>
      <div class="success-sub">您的简历已成功投递，我们将在3个工作日内与您联系</div>
      <div class="success-summary">
        <p>应聘职位：{{ selectedPositionName }}</p>
        <p>姓名：{{ form.candidate_name }}</p>
        <p>手机号：{{ form.candidate_phone }}</p>
      </div>
      <el-button type="primary" size="small" round @click="backToJobs">返回职位列表</el-button>
    </div>

    <!-- 职位详情弹窗 -->
    <el-dialog :title="detail ? detail.position_name : ''" :visible.sync="detailVisible" width="90%" custom-class="job-dialog">
      <div v-if="detail">
        <div class="dlg-salary">{{ money(detail.salary_range_min) }}-{{ money(detail.salary_range_max) }}元/月</div>
        <div class="dlg-meta">
          <span>{{ detail.department_name }}</span>
          <span>招聘 {{ detail.recruit_count }} 人</span>
          <span v-if="detail.work_location">📍 {{ detail.work_location }}</span>
        </div>
        <h4 class="dlg-section">职位描述</h4>
        <p class="dlg-text">{{ detail.job_description || '暂无描述' }}</p>
        <h4 class="dlg-section">任职要求</h4>
        <p class="dlg-text">{{ detail.requirements || '暂无要求' }}</p>
      </div>
      <span slot="footer">
        <el-button size="small" round @click="detailVisible = false">关闭</el-button>
        <el-button type="primary" size="small" round @click="applyFromDetail">立即投递</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getPublicPositionList, submitPublicResume, uploadPublicResumeFile } from '@/api/recruit'

const EDUCATION_TEXT = { 1: '初中及以下', 2: '高中/中专', 3: '大专', 4: '本科', 5: '硕士及以上' }
const WORK_EXP = ['0', '1-3', '3-5', '5-10', '10+']
const EXPECTED_SALARY = ['3000-5000元', '5000-8000元', '8000-12000元', '12000-20000元', '20000元以上']
const CATEGORIES = [
  { label: '全部', value: 0 },
  { label: '工人', value: 1 },
  { label: '技术员', value: 2 },
  { label: '业务员', value: 3 },
  { label: '管理人员', value: 4 },
  { label: '其他', value: 5 }
]

export default {
  name: 'RecruitApply',
  data () {
    return {
      EDUCATION_TEXT,
      positions: [], brand: { company_name: '数智管控平台 招聘', slogan: '期待您的加入', logo: '' },
      keyword: '', category: 0, CATEGORIES,
      detailVisible: false, detail: null,
      submitted: false, submitting: false, uploadList: [],
      form: {
        position_id: 0, candidate_name: '', candidate_phone: '', candidate_email: '',
        candidate_gender: 1, education: 3, work_experience: '', expected_salary: '',
        self_introduction: '', resume_file: ''
      },
      rules: {
        position_id: [{ required: true, message: '请选择应聘职位', trigger: 'change' }],
        candidate_name: [{ required: true, message: '请输入姓名', trigger: 'blur' }, { min: 2, max: 20, message: '姓名长度2-20个字符', trigger: 'blur' }],
        candidate_phone: [{ required: true, message: '请输入手机号', trigger: 'blur' }, { pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }],
        candidate_email: [{ type: 'email', message: '邮箱格式不正确', trigger: 'blur' }],
        candidate_gender: [{ required: true, message: '请选择性别', trigger: 'change' }],
        education: [{ required: true, message: '请选择学历', trigger: 'change' }],
        work_experience: [{ required: true, message: '请选择工作年限', trigger: 'change' }]
      }
    }
  },
  computed: {
    filteredPositions () {
      const kw = this.keyword.trim()
      return this.positions.filter(p => {
        const okKw = !kw || p.position_name.indexOf(kw) > -1
        const okCat = this.category === 0 || p.position_category === this.category
        return okKw && okCat
      })
    },
    selectedPositionName () {
      const p = this.positions.find(x => x.id === this.form.position_id)
      return p ? p.position_name : ''
    },
    brandBg () {
      return { background: 'linear-gradient(135deg, #409EFF 0%, #2b7fe0 100%)' }
    }
  },
  created () {
    this.loadData()
  },
  methods: {
    async loadData () {
      try {
        const r = await getPublicPositionList()
        if (r.code === 0 && r.data) {
          this.positions = r.data.list || []
          if (r.data.brand) this.brand = { ...this.brand, ...r.data.brand }
        }
      } catch (e) {}
    },
    money (v) { const n = Number(v) || 0; return n.toLocaleString('zh-CN') },
    openDetail (p) { this.detail = p; this.detailVisible = true },
    applyFromDetail () {
      this.detailVisible = false
      this.choosePosition(this.detail)
    },
    applyNow (p) { this.choosePosition(p) },
    choosePosition (p) {
      this.form.position_id = p.id
      this.$nextTick(() => {
        if (this.$refs.formArea) this.$refs.formArea.scrollIntoView({ behavior: 'smooth', block: 'start' })
      })
    },
    scrollToJobs () {
      window.scrollTo({ top: 0, behavior: 'smooth' })
    },
    onFileChange (file) {
      if (file.status === 'ready' && file.raw) {
        const fd = new FormData()
        fd.append('file', file.raw)
        uploadPublicResumeFile(fd).then(r => {
          if (r.code === 0 && r.data) {
            this.form.resume_file = r.data.url
            this.$message.success('简历附件上传成功')
          } else {
            this.$message.error(r.msg || '上传失败')
            this.uploadList = []
          }
        }).catch(() => {
          this.$message.error('上传失败，请重试')
          this.uploadList = []
        })
      }
    },
    onFileRemove () { this.form.resume_file = '' },
    handleSubmit () {
      this.$refs.form.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.submitting = true
        submitPublicResume(this.form).then(r => {
          if (r.code === 0) {
            this.submitted = true
            window.scrollTo({ top: 0 })
            setTimeout(() => { this.backToJobs() }, 3000)
          } else this.$message.error(r.msg || '投递失败')
        }).catch(() => {
          this.$message.error('网络连接超时，请稍后重试')
        }).finally(() => { this.submitting = false })
      })
    },
    backToJobs () {
      this.submitted = false
      this.form = {
        position_id: 0, candidate_name: '', candidate_phone: '', candidate_email: '',
        candidate_gender: 1, education: 3, work_experience: '', expected_salary: '',
        self_introduction: '', resume_file: ''
      }
      this.uploadList = []
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }
}
</script>

<style scoped>
.apply-page { min-height: 100vh; background: #f5f7fa; padding-bottom: 40px; }
.brand { padding: 32px 16px; color: #fff; }
.brand-inner { max-width: 640px; margin: 0 auto; display: flex; align-items: center; gap: 14px; }
.brand-logo { width: 52px; height: 52px; border-radius: 12px; overflow: hidden; flex-shrink: 0; background: rgba(255,255,255,0.2); }
.brand-logo img { width: 100%; height: 100%; object-fit: cover; }
.brand-logo-default { display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: bold; }
.brand-name { font-size: 22px; font-weight: 600; }
.brand-slogan { font-size: 14px; opacity: 0.9; margin-top: 4px; }
.container { max-width: 640px; margin: 0 auto; padding: 0 16px; }
.section-header { display: flex; justify-content: space-between; align-items: center; margin: 20px 0 12px; }
.section-title { font-size: 18px; font-weight: 600; color: #303133; }
.count-text { font-size: 13px; color: #909399; }
.search-box { margin-bottom: 12px; }
.category-tabs { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 14px; }
.cat-tab { padding: 5px 14px; border-radius: 16px; background: #fff; border: 1px solid #e4e7ed; font-size: 13px; color: #606266; cursor: pointer; }
.cat-tab.active { background: #409EFF; border-color: #409EFF; color: #fff; }
.job-card { background: #fff; border: 1px solid #ebeef5; border-radius: 12px; padding: 16px; margin-bottom: 12px; box-shadow: 0 1px 4px rgba(0,0,0,0.04); cursor: pointer; transition: box-shadow 0.2s; }
.job-card:active { box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
.job-head { display: flex; align-items: center; gap: 8px; }
.job-name { font-size: 18px; font-weight: 600; color: #303133; flex: 1; }
.job-salary { font-size: 16px; color: #E6A23C; margin: 8px 0 6px; font-weight: 600; }
.job-meta { display: flex; flex-wrap: wrap; gap: 12px; font-size: 13px; color: #909399; margin-bottom: 10px; }
.job-foot { display: flex; justify-content: space-between; align-items: center; }
.job-cat { font-size: 12px; color: #909399; background: #f5f7fa; padding: 2px 10px; border-radius: 10px; }
.empty-box { text-align: center; padding: 60px 0; color: #909399; background: #fff; border-radius: 12px; }
.empty-icon { font-size: 56px; color: #dcdfe6; }
.empty-box p { margin: 12px 0 16px; }
.form-sub { color: #909399; font-size: 13px; margin: -4px 0 16px; }
.submit-btn { width: 100%; height: 46px; font-size: 16px; margin-top: 4px; }
.upload-tip { color: #909399; font-size: 12px; line-height: 1.6; }
.success-box { text-align: center; padding: 60px 16px; background: #fff; border-radius: 12px; margin-top: 20px; }
.success-icon { width: 64px; height: 64px; border-radius: 50%; background: #67C23A; color: #fff; font-size: 34px; display: flex; align-items: center; justify-content: center; margin: 0 auto 16px; }
.success-title { font-size: 24px; font-weight: 600; color: #303133; }
.success-sub { font-size: 16px; color: #606266; margin: 8px 0 20px; }
.success-summary { background: #f5f7fa; border-radius: 8px; padding: 12px 16px; font-size: 14px; color: #909399; text-align: left; margin-bottom: 20px; }
.success-summary p { margin: 4px 0; }
.dlg-salary { font-size: 18px; color: #E6A23C; font-weight: 600; margin-bottom: 8px; }
.dlg-meta { display: flex; flex-wrap: wrap; gap: 12px; font-size: 13px; color: #909399; margin-bottom: 8px; }
.dlg-section { margin: 12px 0 6px; color: #303133; }
.dlg-text { color: #606266; font-size: 14px; line-height: 1.8; white-space: pre-wrap; }
@media (max-width: 640px) {
  .job-dialog { margin: 8vh auto 0 !important; }
}
</style>
