<template>
  <div class="hr-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="s in stats" :key="s.label">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-val" :style="{color:s.color}">{{ s.value }}</div>
          <div class="stat-lbl">{{ s.label }}</div>
        </el-card>
      </el-col>
    </el-row>
    <el-card shadow="never">
      <div slot="header">
        <span>员工档案</span>
        <div style="float:right;">
          <el-button v-if="hasPerm('employeeprofile:export')" size="small" @click="handleExport">导出</el-button>
          <el-button v-if="hasPerm('employeeprofile:syncAll')" size="small" @click="handleSync" :loading="syncing" icon="el-icon-refresh">同步用户信息</el-button>
          <el-button v-if="hasPerm('employeeprofile:store')" size="small" type="primary" @click="openForm()">新增员工</el-button>
        </div>
      </div>
      <el-form :inline="true" size="small">
        <el-form-item><el-select v-model="filters.status" placeholder="员工状态" clearable style="width:130px" @change="fetchList"><el-option v-for="s in dictEmpStatus" :key="s.value" :label="s.label" :value="s.value" /></el-select></el-form-item>
        <el-form-item><el-select v-model="filters.department_id" placeholder="所属部门" clearable style="width:150px" @change="fetchList"><el-option v-for="d in deptOptions" :key="d.id" :label="d.label" :value="d.id" /></el-select></el-form-item>
        <el-form-item><el-select v-model="filters.position_id" placeholder="岗位" clearable style="width:130px" @change="fetchList"><el-option v-for="p in posOptions" :key="p.id" :label="p.name" :value="p.id" /></el-select></el-form-item>
        <el-form-item><el-input v-model="filters.keyword" placeholder="搜索姓名、工号或手机号" clearable style="width:240px" @input="searchDelay" /></el-form-item>
      </el-form>
      <el-table :data="list" v-loading="loading" stripe border size="small">
        <el-table-column type="index" label="#" width="50" />
        <el-table-column prop="employee_id" label="工号" width="110" />
        <el-table-column prop="name" label="姓名" min-width="100">
          <template slot-scope="{row}"><el-button type="text" size="small" @click="openDetail(row)">{{ row.name }}</el-button></template>
        </el-table-column>
        <el-table-column label="部门" width="120"><template slot-scope="{row}">{{ row.department?.name||'-' }}</template></el-table-column>
        <el-table-column label="岗位" width="100"><template slot-scope="{row}">{{ row.position?.name||'-' }}</template></el-table-column>
        <el-table-column label="岗位等级" width="130"><template slot-scope="{row}">{{ row.position_level_name || '-' }}</template></el-table-column>
        <el-table-column prop="phone" label="手机号" width="120" />
        <el-table-column label="同步状态" width="90" align="center">
          <template slot-scope="{row}">
            <el-tag v-if="row.sync_status===0 || row.sync_status===undefined" type="success" size="mini">已同步</el-tag>
            <el-tag v-else-if="row.sync_status===1" type="warning" size="mini">待同步</el-tag>
            <el-tag v-else type="danger" size="mini">失败</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="hire_date" label="入职日期" width="110" />
        <el-table-column label="员工状态" width="100">
          <template slot-scope="{row}"><el-tag :type="statusType(row.employee_status)" size="mini">{{ statusLabel(row.employee_status) }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('employeeprofile:view')" type="text" size="small" @click="openDetail(row)">详情</el-button>
            <el-button v-if="hasPerm('employeeprofile:update')" type="text" size="small" @click="openForm(row)">编辑</el-button>
            <el-button v-if="hasPerm('employeeprofile:destroy')" type="text" size="small" style="color:#f56c6c" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination background :current-page="page" :page-size="limit" :total="total" layout="total,sizes,prev,pager,next" :page-sizes="[10,20,50,100]" @size-change="s=>{limit=s;fetchList()}" @current-change="p=>{page=p;fetchList()}" style="margin-top:16px;" />
    </el-card>

    <!-- 员工详情弹窗 -->
    <el-dialog :title="'员工详情 — '+detailData.name" :visible.sync="detailVisible" width="720px" top="5vh">
      <div v-if="detailData.id" class="detail-wrap">
        <div class="detail-section"><h4>基本信息</h4>
          <el-row :gutter="16"><el-col :span="8"><label>工号</label><p>{{ detailData.employee_id||'-' }}</p></el-col>
            <el-col :span="8"><label>姓名</label><p>{{ detailData.name }}</p></el-col>
            <el-col :span="8"><label>性别</label><p>{{ {1:'男',2:'女'}[detailData.gender]||'未知' }}</p></el-col>
            <el-col :span="8"><label>手机号</label><p>{{ detailData.phone }}</p></el-col>
            <el-col :span="8"><label>邮箱</label><p>{{ detailData.email||'-' }}</p></el-col>
            <el-col :span="8"><label>出生日期</label><p>{{ detailData.birthday||'-' }}</p></el-col>
            <el-col :span="8"><label>身份证号</label><p>{{ maskIdCard(detailData.id_card) }}</p></el-col>
            <el-col :span="8"><label>血型</label><p>{{ detailData.blood_type||'-' }}</p></el-col>
            <el-col :span="8"><label>政治面貌</label><p>{{ detailData.political_status||'-' }}</p></el-col>
            <el-col :span="8"><label>学历</label><p>{{ eduName(detailData.education_level) }}</p></el-col>
            <el-col :span="8"><label>职称</label><p>{{ titleName(detailData.title_level) }}</p></el-col>
            <el-col :span="12"><label>户籍地址</label><p>{{ detailData.domicile||'-' }}</p></el-col>
            <el-col :span="12"><label>现住地址</label><p>{{ detailData.address||'-' }}</p></el-col>
          </el-row>
        </div>
        <div class="detail-section"><h4>工作信息</h4>
          <el-row :gutter="16"><el-col :span="8"><label>部门</label><p>{{ detailData.department?.name||'-' }}</p></el-col>
            <el-col :span="8"><label>岗位</label><p>{{ detailData.position?.name||'-' }}</p></el-col>
            <el-col :span="8"><label>岗位等级</label><p>{{ detailData.position_level_name || '-' }}</p></el-col>
            <el-col :span="8"><label>直属上级</label><p>{{ detailData.leader?.real_name||detailData.leader?.username||'-' }}</p></el-col>
            <el-col :span="8"><label>入职日期</label><p>{{ detailData.hire_date||'-' }}</p></el-col>
            <el-col :span="8"><label>转正日期</label><p>{{ detailData.probation_end_date||'-' }}</p></el-col>
            <el-col :span="8"><label>员工状态</label><p><el-tag :type="statusType(detailData.employee_status)" size="mini">{{ statusLabel(detailData.employee_status) }}</el-tag></p></el-col>
          </el-row>
        </div>
        <div class="detail-section" v-if="detailData.contracts?.length"><h4>合同信息 <el-tag v-for="c in detailData.contracts" :key="c.id" size="mini" style="margin:0 4px 4px 0">{{ c.contract_no }} ({{ c.start_date }}~{{ c.end_date }})</el-tag></h4></div>
        <div class="detail-section" v-if="detailData.educations?.length"><h4>学历信息 <el-tag v-for="e in detailData.educations" :key="e.id" size="mini" style="margin:0 4px 4px 0">{{ e.education }} @ {{ e.school }} ({{ e.major }})</el-tag></h4></div>
        <div class="detail-section" v-if="detailData.emergency_contacts?.length"><h4>紧急联系人 <el-tag v-for="ec in detailData.emergency_contacts" :key="ec.id" size="mini" style="margin:0 4px 4px 0">{{ ec.name }}({{ ec.relationship }}) {{ ec.phone }}</el-tag></h4></div>
        <div class="detail-section" v-if="detailData.id"><h4>异动历史（最近 5 条）</h4>
          <el-table :data="transferList" size="mini" border empty-text="暂无异动记录">
            <el-table-column label="异动编号" width="150">
              <template slot-scope="s"><el-link type="primary" @click="$router.push({ path: `/hr/transfer/detail/${s.row.id}` })">{{ s.row.transfer_no }}</el-link></template>
            </el-table-column>
            <el-table-column label="异动类型" width="90" align="center"><template slot-scope="s">{{ s.row.transfer_type_label }}</template></el-table-column>
            <el-table-column label="变更信息" min-width="140" show-overflow-tooltip><template slot-scope="s">{{ s.row.change_summary }}</template></el-table-column>
            <el-table-column label="生效日期" width="100" align="center"><template slot-scope="s">{{ s.row.transfer_date }}</template></el-table-column>
            <el-table-column label="异动状态" width="90" align="center"><template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template></el-table-column>
          </el-table>
        </div>
      </div>
      <span slot="footer"><el-button @click="detailVisible=false">关闭</el-button><el-button type="primary" @click="detailVisible=false;openForm(detailData)">编辑</el-button></span>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="formId?'编辑员工 — '+(form.name||''):'新增员工'" :visible.sync="formVisible" width="800px" top="5vh">
      <el-form :model="form" label-width="120px" size="small">
        <h4>基本信息</h4>
        <el-row :gutter="16">
          <el-col :span="8"><el-form-item label="工号"><el-input v-model="form.employee_id" :disabled="true" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="姓名"><el-input v-model="form.name" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="性别"><el-select v-model="form.gender" style="width:100%"><el-option v-for="g in dictGender" :key="g.value" :label="g.label" :value="g.value" /></el-select></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="手机号"><el-input v-model="form.phone" maxlength="11" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="邮箱"><el-input v-model="form.email" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="出生日期"><el-date-picker v-model="form.birthday" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="身份证号"><el-input v-model="form.id_card" maxlength="18" :placeholder="formId&&detailData.id_card?'已加密，重新输入覆盖':''" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="血型"><el-select v-model="form.blood_type" clearable style="width:100%"><el-option v-for="b in dictBlood" :key="b.value" :label="b.label" :value="b.value" /></el-select></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="民族"><el-input v-model="form.nation" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="政治面貌"><el-select v-model="form.political_status" clearable style="width:100%"><el-option v-for="p in dictPolitical" :key="p.value" :label="p.label" :value="p.value" /></el-select></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="婚姻状况"><el-select v-model="form.marital_status" clearable style="width:100%"><el-option v-for="m in dictMarital" :key="m.value" :label="m.label" :value="m.value" /></el-select></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="户籍地址"><el-input v-model="form.domicile" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="现住地址"><el-input v-model="form.address" /></el-form-item></el-col>
        </el-row>
        <h4>工作信息</h4>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="所属部门"><el-select v-model="form.department_id" clearable style="width:100%" @change="onDeptChange"><el-option v-for="d in deptOptions" :key="d.id" :label="d.label" :value="d.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="岗位"><el-select v-model="form.position_id" clearable style="width:100%"><el-option v-for="p in posOptions" :key="p.id" :label="p.name" :value="p.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="岗位等级"><el-select v-model="form.position_level" placeholder="请选择岗位等级" clearable filterable style="width:100%"><el-option v-for="s in standardOptions" :key="s.position_code" :label="s.position_name + '（' + s.position_code + '）'" :value="s.position_code" /></el-select></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="直属上级"><el-select v-model="form.leader_id" filterable clearable style="width:100%"><el-option v-for="u in userOptions" :key="u.id" :label="u.real_name||u.username" :value="u.id" /></el-select></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="入职日期"><el-date-picker v-model="form.hire_date" value-format="yyyy-MM-dd" style="width:100%" @change="onHireDateChange" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="转正日期"><el-date-picker v-model="form.probation_end_date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="试用期月数"><el-input-number v-model="form.probation_months" :min="1" :max="12" style="width:100%" /></el-form-item></el-col>
        </el-row>
        <h4>合同信息</h4>
        <el-row :gutter="16">
          <el-col :span="8"><el-form-item label="合同编号"><el-input v-model="form.contract_no" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="合同类型"><el-select v-model="form.contract_type" clearable style="width:100%"><el-option v-for="c in dictContract" :key="c.value" :label="c.label" :value="c.value" /></el-select></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="合同开始日"><el-date-picker v-model="form.contract_start_date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="合同结束日"><el-date-picker v-model="form.contract_end_date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="签订日期"><el-date-picker v-model="form.contract_sign_date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
        </el-row>
        <h4>学历信息</h4>
        <el-row :gutter="16">
          <el-col :span="8"><el-form-item label="学历"><el-select v-model="form.education_level" clearable filterable style="width:100%"><el-option v-for="e in educationOptions" :key="e.code" :label="e.name" :value="e.code" /></el-select></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="职称"><el-select v-model="form.title_level" clearable filterable style="width:100%"><el-option v-for="t in titleOptions" :key="t.code" :label="t.name" :value="t.code" /></el-select></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="毕业院校"><el-input v-model="form.graduate_school" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="专业"><el-input v-model="form.major" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="毕业时间"><el-date-picker v-model="form.graduation_date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
        </el-row>
        <h4>紧急联系人</h4>
        <el-row :gutter="16">
          <el-col :span="8"><el-form-item label="联系人姓名"><el-input v-model="form.emergency_contact" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="联系人关系"><el-input v-model="form.emergency_relationship" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="联系人手机"><el-input v-model="form.emergency_phone" maxlength="11" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <span slot="footer"><el-button @click="formVisible=false">取消</el-button><el-button type="primary" :loading="saving" @click="handleSave">保存</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getProfileList, getProfileStatistics, getProfileDetail, createProfile, updateProfile, deleteProfile, exportProfiles, syncAllProfiles } from '@/api/profile'
import { getDeptTree, getPositions } from '@/api/organization'
import { getDictByCode } from '@/api/dictionary'
import { getDictLabel as getDictLabelUtil } from '@/utils/dict'
import { getUserOptions } from '@/api/user'
import { getSettingValue } from '@/api/settings'
import { getTransferList } from '@/api/hrTransfer'
import { getSalaryStandardOptions } from '@/api/salaryStandard'
import { getSubsidyOptions } from '@/api/salarySubsidy'

function flattenDept(nodes) {
  let r=[]; for(const n of nodes){r.push(n);if(n.children)r=r.concat(flattenDept(n.children))} return r
}
export default {
  name: 'Profiles',
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 20,
      filters: { keyword: '', status: '', department_id: '', position_id: '' },
      searchTimer: null, stats: [],
      detailVisible: false, detailData: {}, transferList: [],
      formVisible: false, formId: null, saving: false, syncing: false,
      form: {
        employee_id:'', name:'', gender:0, phone:'', email:'', birthday:'', id_card:'',
        blood_type:'', nation:'', political_status:'', marital_status:'', domicile:'', address:'',
        department_id:null, position_id:null, position_level:null, leader_id:null,
        hire_date:'', probation_end_date:'', probation_months:3,
        contract_no:'', contract_type:'', contract_start_date:'', contract_end_date:'', contract_sign_date:'',
        education:'', title_qualification:'', education_level:'', title_level:'', graduate_school:'', major:'', graduation_date:'',
        emergency_contact:'', emergency_relationship:'', emergency_phone:'',
      },
      deptOptions: [], posOptions: [], standardOptions: [], userOptions: [], educationOptions: [], titleOptions: [],
      dictStatus: [], dictGender: [], dictEducation: [], dictMarital: [],
      dictPolitical: [], dictContract: [], dictBlood: [], dictEmpStatus: [],
    }
  },
  computed: {
    statusLabel() { return (v) => getDictLabelUtil(this.dictEmpStatus, v) },
    statusType() { return (v) => ({1:'primary',2:'success',3:'warning',4:'info',5:'danger'}[v]||'info') },
  },
  created() {
    this.fetchList(); this.fetchStats(); this.loadDepts(); this.loadUsers(); this.loadPosOptions(); this.loadStandards(); this.loadSubsidyOptions()
    getDictByCode('gender').then(r=>{if(r.code===0)this.dictGender=r.data||[]})
    getDictByCode('education').then(r=>{if(r.code===0)this.dictEducation=r.data||[]})
    getDictByCode('marital_status').then(r=>{if(r.code===0)this.dictMarital=r.data||[]})
    getDictByCode('political_status').then(r=>{if(r.code===0)this.dictPolitical=r.data||[]})
    getDictByCode('contract_type').then(r=>{if(r.code===0)this.dictContract=r.data||[]})
    getDictByCode('blood_type').then(r=>{if(r.code===0)this.dictBlood=r.data||[]})
    getDictByCode('employee_status').then(r=>{if(r.code===0)this.dictEmpStatus=r.data||[]})
    getSettingValue('profile_list_default_pagesize').then(r=>{if(r.code===0)this.limit=parseInt(r.data?.value)||20})
  },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async fetchList() { this.loading=true; try{const r=await getProfileList({page:this.page,limit:this.limit,...this.filters});if(r.code===0){this.list=r.data.list;this.total=r.data.total}}catch(e){} this.loading=false },
    async fetchStats() { try{const r=await getProfileStatistics();if(r.code===0){const s=r.data;this.stats=[{label:'在职员工',value:s.total||0,color:'#409eff'},{label:'试用期',value:s.probation||0,color:'#e6a23c'},{label:'本月入职',value:s.hired_this_month||0,color:'#67c23a'},{label:'本月离职',value:s.resigned_this_month||0,color:'#f56c6c'}]}}catch(e){} },
    searchDelay() { clearTimeout(this.searchTimer); this.searchTimer = setTimeout(()=>{this.page=1;this.fetchList()},500) },
    async loadDepts() { try{const r=await getDeptTree();if(r.code===0){const flat=flattenDept(r.data||[]);this.deptOptions=flat.map(d=>({id:d.id,label:d.name}))}}catch(e){} },
    async loadPosOptions() { try{const r=await getPositions(0);if(r.code===0)this.posOptions=r.data||[]}catch(e){} },
    async loadStandards() { try{const r=await getSalaryStandardOptions();if(r.code===0)this.standardOptions=r.data||[]}catch(e){} },
    async loadSubsidyOptions() {
      try {
        const [ed, ti] = await Promise.all([getSubsidyOptions({ type: 'education' }), getSubsidyOptions({ type: 'title' })])
        if (ed.code === 0) this.educationOptions = ed.data || []
        if (ti.code === 0) this.titleOptions = ti.data || []
      } catch (e) {}
    },
    eduName(code) { const o = this.educationOptions.find(x => x.code === code); return o ? o.name : (code || '-') },
    titleName(code) { const o = this.titleOptions.find(x => x.code === code); return o ? o.name : (code || '-') },
    onDeptChange(val) { if(!val)return; getPositions(val).then(r=>{if(r.code===0)this.posOptions=r.data||[]}) },
    onHireDateChange(val) { if(val&&!this.formId){const d=new Date(val);d.setMonth(d.getMonth()+(this.form.probation_months||3));this.form.probation_end_date=d.toISOString().slice(0,10)} },
    async loadUsers() { try{const r=await getUserOptions();this.userOptions=(r.data||[]).map(o=>({id:o.value,real_name:o.label,username:o.label}))}catch(e){} },
    maskIdCard(v) { return v ? v.slice(0,6)+'********'+v.slice(-4) : '-' },
    async openDetail(row) {
      this.transferList = []
      try{const r=await getProfileDetail(row.id);if(r.code===0)this.detailData=r.data;this.detailVisible=true}catch(e){}
      try{const t=await getTransferList({employee_id: row.id, pageSize: 5});if(t.code===0)this.transferList=t.data.list||[]}catch(e){}
    },
    async openForm(row) {
      this.formId = row?.id || null
      if(row?.id) { try{const r=await getProfileDetail(row.id);if(r.code===0)row=r.data}catch(e){} }
      this.form = row ? {
        employee_id: row.employee_id||'', name: row.name||'', gender: row.gender??0, phone: row.phone||'',
        email: row.email||'', birthday: row.birthday||'', id_card: row.id_card||'',
        blood_type: row.blood_type||'', nation: row.nation||'', political_status: row.political_status||'',
        marital_status: row.marital_status||'', domicile: row.domicile||'', address: row.address||'',
        department_id: row.department_id||null, position_id: row.position_id||null, position_level: row.position_level||null, leader_id: row.leader_id||null,
        hire_date: row.hire_date||'', probation_end_date: row.probation_end_date||'', probation_months: row.probation_months||3,
        contract_no: (row.contracts?.[0]?.contract_no)||'', contract_type: (row.contracts?.[0]?.contract_type)||'',
        contract_start_date: (row.contracts?.[0]?.start_date)||'', contract_end_date: (row.contracts?.[0]?.end_date)||'',
        contract_sign_date: (row.contracts?.[0]?.sign_date)||'',
        education: row.educations?.[0]?.education||'', title_qualification: row.title_qualification||'', education_level: row.education_level||'', title_level: row.title_level||'', graduate_school: row.educations?.[0]?.school||'',
        major: row.educations?.[0]?.major||'', graduation_date: row.educations?.[0]?.graduation_date||'',
        emergency_contact: row.emergency_contacts?.[0]?.name||'', emergency_relationship: row.emergency_contacts?.[0]?.relationship||'',
        emergency_phone: row.emergency_contacts?.[0]?.phone||'',
      } : {
        employee_id:'', name:'', gender:0, phone:'', email:'', birthday:'', id_card:'',
        blood_type:'', nation:'', political_status:'', marital_status:'', domicile:'', address:'',
        department_id:null, position_id:null, position_level:null, leader_id:null,
        hire_date:'', probation_end_date:'', probation_months:3,
        contract_no:'', contract_type:'', contract_start_date:'', contract_end_date:'', contract_sign_date:'',
        education:'', title_qualification:'', education_level:'', title_level:'', graduate_school:'', major:'', graduation_date:'',
        emergency_contact:'', emergency_relationship:'', emergency_phone:'',
      }
      this.formVisible = true
    },
    async handleSave() {
      this.saving=true
      try {
        const data={...this.form}
        // 同步学历/职称编码（education_level/title_level 存的是补助标准编码）
        data.education_code = data.education_level || ''
        data.title_code = data.title_level || ''
        data.contracts = data.contract_no ? [{ contract_no: data.contract_no, contract_type: data.contract_type, start_date: data.contract_start_date, end_date: data.contract_end_date, sign_date: data.contract_sign_date }] : []
        data.educations = data.education ? [{ education: data.education, school: data.graduate_school, major: data.major, graduation_date: data.graduation_date }] : []
        data.emergency_contacts = data.emergency_contact ? [{ name: data.emergency_contact, relationship: data.emergency_relationship, phone: data.emergency_phone }] : []
        ;['contract_no','contract_type','contract_start_date','contract_end_date','contract_sign_date','education','graduate_school','major','graduation_date','emergency_contact','emergency_relationship','emergency_phone'].forEach(k=>delete data[k])
        if(this.formId) await updateProfile(this.formId, data); else await createProfile(data)
        this.$message.success('保存成功'); this.formVisible=false; this.fetchList(); this.fetchStats()
      } catch(e){ this.$message.error('保存失败') }
      this.saving=false
    },
async handleExport() {
  try{
    const r=await exportProfiles(this.filters)
    if(r.code===0){
      const rows=r.data.rows; const headers=r.data.headers
      let csv="\uFEFF"+headers.join(",")+"\n"
      for(const row of rows){ csv+=headers.map(h=>`"${(row[h]||'').replace(/"/g,'""')}"`).join(",")+"\n" }
      const blob=new Blob([csv],{type:'text/csv;charset=utf-8'})
      const url=URL.createObjectURL(blob); const a=document.createElement('a')
      a.href=url; a.download=`员工档案_${new Date().toISOString().slice(0,10)}.csv`; a.click()
      URL.revokeObjectURL(url); this.$message.success('导出成功')
    } else this.$message.error(r.msg||'导出失败')
  }catch(e){this.$message.error('导出失败')}
},
    async handleSync() {
      this.$confirm('将同步所有用户信息到员工档案（姓名、手机号、部门、岗位），确定执行？', '同步确认', { type: 'warning' }).then(async () => {
        this.syncing = true
        try {
          const res = await syncAllProfiles()
          this.$message.success(res.msg || '同步完成')
          this.fetchList()
        } catch (e) {} finally { this.syncing = false }
      }).catch(() => {})
    },
    async handleDelete(row) {
      await this.$confirm(`确认删除「${row.name}」？`,'提示',{type:'warning'})
      try{await deleteProfile(row.id);this.$message.success('已删除');this.fetchList();this.fetchStats()}catch(e){}
    },
  }
}
</script>
<style scoped>
.hr-page { padding:0; }
.stat-card { text-align:center; }
.stat-val { font-size:28px; font-weight:bold; }
.stat-lbl { font-size:13px; color:#999; margin-top:4px; }
h4 { margin:12px 0; color:#666; border-bottom:1px solid #f0f0f0; padding-bottom:6px; }
.detail-wrap { max-height:65vh; overflow-y:auto; }
.detail-section { margin-bottom:16px; }
.detail-section h4 { margin-bottom:8px; }
.detail-section label { color:#909399; font-size:12px; }
.detail-section p { margin:2px 0 8px; font-size:14px; color:#303133; }
</style>
