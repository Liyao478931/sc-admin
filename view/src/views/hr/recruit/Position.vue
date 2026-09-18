<!--
  文件：admin/src/views/hr/recruit/Position.vue
  功能：招聘职位（搜索/新增/编辑/删除/发布/下架/关闭/导出/详情）
  权限：hr:recruit:view/add/edit/delete/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>招聘管理</el-breadcrumb-item>
      <el-breadcrumb-item>职位管理</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="职位编号"><el-input v-model="query.position_no" placeholder="请输入职位编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="职位名称"><el-input v-model="query.position_name" placeholder="请输入职位名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="所属部门">
          <el-select v-model="query.department_id" clearable placeholder="全部" style="width:150px">
            <el-option v-for="d in departmentOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="发布状态">
          <el-select v-model="query.publish_status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in PUBLISH_TEXT" :key="v" :label="t" :value="Number(v)" />
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
        <el-button v-permission="'hr:recruit:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增职位</el-button>
        <el-button v-permission="'hr:recruit:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无招聘职位数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="职位编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.position_no }}</el-link></template>
      </el-table-column>
      <el-table-column prop="position_name" label="职位名称" min-width="120" show-overflow-tooltip />
      <el-table-column prop="department_name" label="所属部门" width="150" show-overflow-tooltip />
      <el-table-column prop="recruit_count" label="招聘人数" width="90" align="center"><template slot-scope="s">{{ s.row.recruit_count }} 人</template></el-table-column>
      <el-table-column prop="hired_count" label="已录用" width="90" align="center"><template slot-scope="s">{{ s.row.hired_count }} 人</template></el-table-column>
      <el-table-column label="发布状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.publish_status_tag" size="mini">{{ s.row.publish_status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="创建时间" width="160" align="center"><template slot-scope="s">{{ s.row.created_at || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="240" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button>
          <el-button v-permission="'hr:recruit:edit'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
          <el-button v-if="s.row.publish_status === 0" v-permission="'hr:recruit:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.publish_status === 0" command="publish" icon="el-icon-position">发布职位</el-dropdown-item>
              <el-dropdown-item v-if="s.row.publish_status === 1" command="offline" icon="el-icon-download">下架职位</el-dropdown-item>
              <el-dropdown-item v-if="s.row.publish_status === 1 || s.row.publish_status === 2" command="close" icon="el-icon-circle-close">关闭职位</el-dropdown-item>
              <el-dropdown-item v-if="!(s.row.publish_status === 0 || s.row.publish_status === 1 || s.row.publish_status === 2)" disabled>当前状态无可执行操作</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="formId ? '编辑招聘职位' : '新增招聘职位'" :visible.sync="formVisible" width="640px" top="6vh">
      <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="职位名称" prop="position_name"><el-input v-model="form.position_name" placeholder="请输入职位名称" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="所属部门" prop="department_id"><el-select v-model="form.department_id" placeholder="请选择部门" style="width:100%"><el-option v-for="d in departmentOptions" :key="d.id" :label="d.name" :value="d.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="岗位类别" prop="position_category"><el-select v-model="form.position_category" style="width:100%"><el-option v-for="(t, v) in CATEGORY_TEXT" :key="v" :label="t" :value="Number(v)" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="招聘人数" prop="recruit_count"><el-input-number v-model="form.recruit_count" :min="1" :max="999" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="工作地点"><el-input v-model="form.work_location" placeholder="如：厂区/车间" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="发布渠道"><el-input v-model="form.channel" placeholder="如：Boss直聘、内部推荐" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="薪资范围-最低"><el-input-number v-model="form.salary_range_min" :min="0" :precision="2" :controls="false" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="薪资范围-最高"><el-input-number v-model="form.salary_range_max" :min="0" :precision="2" :controls="false" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="过期时间"><el-date-picker v-model="form.expire_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" placeholder="选填" style="width:100%" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="职位描述"><el-input v-model="form.job_description" type="textarea" :rows="3" placeholder="职位描述（选填）" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="任职要求"><el-input v-model="form.requirements" type="textarea" :rows="3" placeholder="任职要求（选填）" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" placeholder="备注信息（选填）" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <span slot="footer"><el-button size="small" @click="formVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button></span>
    </el-dialog>

    <!-- 详情抽屉 -->
    <el-drawer :title="'招聘职位详情 - ' + (detail.position_no || '')" :visible.sync="detailVisible" size="560px">
      <div class="drawer-body" v-if="detail.id">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="职位编号">{{ detail.position_no }}</el-descriptions-item>
          <el-descriptions-item label="发布状态"><el-tag :type="detail.publish_status_tag" size="mini">{{ detail.publish_status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="职位名称">{{ detail.position_name }}</el-descriptions-item>
          <el-descriptions-item label="所属部门">{{ detail.department_name }}</el-descriptions-item>
          <el-descriptions-item label="岗位类别">{{ detail.position_category_label }}</el-descriptions-item>
          <el-descriptions-item label="招聘/已录用">{{ detail.recruit_count }} / {{ detail.hired_count }}</el-descriptions-item>
          <el-descriptions-item label="工作地点">{{ detail.work_location || '-' }}</el-descriptions-item>
          <el-descriptions-item label="发布渠道">{{ detail.channel || '-' }}</el-descriptions-item>
          <el-descriptions-item label="薪资范围">{{ money(detail.salary_range_min) }} ~ {{ money(detail.salary_range_max) }}</el-descriptions-item>
          <el-descriptions-item label="过期时间">{{ detail.expire_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="发布时间">{{ detail.publish_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.creator_name }}</el-descriptions-item>
          <el-descriptions-item label="职位描述" :span="2">{{ detail.job_description || '-' }}</el-descriptions-item>
          <el-descriptions-item label="任职要求" :span="2">{{ detail.requirements || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import { getPositionList, savePosition, deletePosition, publishPosition, offlinePosition, closePosition, exportPosition } from '@/api/recruit'
import { getRecruitOptions } from '@/api/recruit'

const CATEGORY_TEXT = { 1: '工人', 2: '技术员', 3: '业务员', 4: '管理人员', 5: '其他' }
const PUBLISH_TEXT = { 0: '未发布', 1: '已发布', 2: '已下架', 3: '已关闭' }

export default {
  name: 'RecruitPosition',
  data () {
    return {
      CATEGORY_TEXT, PUBLISH_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, saving: false,
      departmentOptions: [],
      query: { position_no: '', position_name: '', department_id: '', publish_status: '' },
      formVisible: false, formId: null, form: {},
      detailVisible: false, detail: {},
      rules: {
        position_name: [{ required: true, message: '请填写职位名称', trigger: 'blur' }],
        department_id: [{ required: true, message: '请选择所属部门', trigger: 'change' }],
        position_category: [{ required: true, message: '请选择岗位类别', trigger: 'change' }],
        recruit_count: [{ required: true, message: '请填写招聘人数', trigger: 'change' }]
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
        if (r.code === 0 && r.data) this.departmentOptions = r.data.departments || []
      } catch (e) { this.departmentOptions = [] }
    },
    money (v) { const n = Number(v) || 0; return n ? '¥ ' + n.toLocaleString('zh-CN') : '-' },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.query).forEach(k => { if (this.query[k] !== '' && this.query[k] !== null) p[k] = this.query[k] })
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getPositionList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { position_no: '', position_name: '', department_id: '', publish_status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    openForm (row) {
      this.formId = row ? row.id : null
      this.form = row ? {
        id: row.id, position_name: row.position_name, department_id: row.department_id,
        position_category: row.position_category, recruit_count: row.recruit_count,
        work_location: row.work_location || '', channel: row.channel || '',
        salary_range_min: Number(row.salary_range_min) || 0, salary_range_max: Number(row.salary_range_max) || 0,
        expire_time: row.expire_time || '', job_description: row.job_description || '', requirements: row.requirements || '', remark: row.remark || ''
      } : {
        id: 0, position_name: '', department_id: 0, position_category: 1, recruit_count: 1,
        work_location: '', channel: '', salary_range_min: 0, salary_range_max: 0,
        expire_time: '', job_description: '', requirements: '', remark: ''
      }
      this.formVisible = true
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (Number(this.form.salary_range_max) > 0 && Number(this.form.salary_range_min) > Number(this.form.salary_range_max)) {
          this.$message.warning('薪资最低值不能大于最高值'); return
        }
        this.saving = true
        savePosition(this.form).then(r => {
          if (r.code === 0) { this.$message.success(r.msg || '保存成功'); this.formVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该招聘职位吗？删除后不可恢复', '提示', { type: 'warning' }).then(() => {
        deletePosition(row.id).then(r => { if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败') })
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'publish') this.confirmAction('发布职位', `确认发布职位 ${row.position_no} 吗？`, publishPosition, row)
      else if (cmd === 'offline') this.confirmAction('下架职位', `确认下架职位 ${row.position_no} 吗？`, offlinePosition, row)
      else if (cmd === 'close') this.confirmAction('关闭职位', `确认关闭职位 ${row.position_no} 吗？`, closePosition, row)
    },
    confirmAction (title, text, fn, row) {
      this.$confirm(text, title, { type: 'warning' }).then(() => {
        fn(row.id).then(r => { if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    async openDetail (row) {
      try {
        const r = await getPositionDetail(row.id)
        if (r.code === 0 && r.data) this.detail = r.data
      } catch (e) {}
      this.detailVisible = true
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportPosition(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `招聘职位_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
</style>
