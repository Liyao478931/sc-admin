<template>
  <div class="face-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="8" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :style="{ borderTopColor: card.color }">
          <div class="stat-icon" :style="{ background: card.color + '1a', color: card.color }"><i :class="card.icon"></i></div>
          <div class="stat-body">
            <div class="stat-value" :style="{ color: card.color }">{{ card.value }}</div>
            <div class="stat-label">{{ card.label }}</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入员工姓名/工号" clearable style="width:180px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.face_status" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option label="已录入" value="registered" />
            <el-option label="未录入" value="unregistered" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.department_id" clearable filterable placeholder="全部部门" style="width:140px" @change="onSearch">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never" class="list-card">
      <div class="toolbar">
        <span class="stat-text">
          共 <b>{{ total }}</b> 人 · 已录入 <b style="color:#67C23A">{{ registeredCount }}</b> 人 · 未录入 <b style="color:#E6A23C">{{ unregisteredCount }}</b> 人
        </span>
        <div>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="employee_no" label="工号" width="120" show-overflow-tooltip />
        <el-table-column prop="name" label="姓名" width="100" />
        <el-table-column prop="department_name" label="部门" width="130" show-overflow-tooltip />
        <el-table-column prop="position" label="岗位" width="100" show-overflow-tooltip />
        <el-table-column label="人脸状态" width="120" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.face_status === 1 ? 'success' : 'info'">{{ row.face_status_label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="录入时间" width="160" />
        <el-table-column label="操作" width="250" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="row.face_status === 0 && hasPerm('face:register')" type="text" size="mini" icon="el-icon-plus" @click="openRegister(row)">录入</el-button>
            <el-button v-if="row.face_status === 1 && hasPerm('face:register')" type="text" size="mini" icon="el-icon-refresh" @click="openReRegister(row)">重新录入</el-button>
            <el-button v-if="row.face_status === 1 && hasPerm('face:view')" type="text" size="mini" icon="el-icon-view" @click="openPreview(row)">查看照片</el-button>
            <el-button v-if="row.face_status === 1 && hasPerm('face:register')" type="text" size="mini" icon="el-icon-delete" style="color:#F56C6C" @click="removeFace(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 录入/重新录入弹窗 -->
    <register-dialog v-if="registerVisible" :visible.sync="registerVisible" :emp="currentEmp" :is-re-register="isReRegister" @saved="loadAll" />
    <!-- 查看照片弹窗 -->
    <photo-preview v-if="previewVisible" :visible.sync="previewVisible" :emp="currentEmp" />
  </div>
</template>

<script>
import { getFaceList, deleteFace } from '@/api/face'
import { getDeptTree } from '@/api/organization'
import RegisterDialog from './components/RegisterDialog.vue'
import PhotoPreview from './components/PhotoPreview.vue'

function flattenDept (nodes) {
  let r = []
  for (const n of nodes || []) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

export default {
  name: 'FaceRegister',
  components: { RegisterDialog, PhotoPreview },
  data () {
    return {
      list: [], total: 0, page: 1, limit: 10, loading: false,
      registeredCount: 0, unregisteredCount: 0,
      filters: { keyword: '', face_status: '', department_id: '' },
      deptOptions: [],
      registerVisible: false, previewVisible: false, isReRegister: false,
      currentEmp: {}
    }
  },
  computed: {
    statCards () {
      return [
        { key: 'total', label: '总人数', icon: 'el-icon-user', color: '#409EFF', value: this.total },
        { key: 'registered', label: '已录入', icon: 'el-icon-camera', color: '#67C23A', value: this.registeredCount },
        { key: 'unregistered', label: '未录入', icon: 'el-icon-warning', color: '#E6A23C', value: this.unregisteredCount }
      ]
    }
  },
  created () {
    this.loadDepts()
    this.loadAll()
  },
  methods: {
    hasPerm (code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadDepts () {
      try {
        const r = await getDeptTree()
        if (r.code === 0) this.deptOptions = flattenDept(r.data || []).map(d => ({ id: d.id, name: d.name }))
      } catch (e) {}
    },
    async loadAll () {
      this.loading = true
      try { await this.loadList() } catch (e) {} finally { this.loading = false }
    },
    async loadList () {
      const params = { page: this.page, limit: this.limit }
      if (this.filters.keyword) params.keyword = this.filters.keyword
      if (this.filters.face_status) params.face_status = this.filters.face_status
      if (this.filters.department_id) params.department_id = this.filters.department_id
      const r = await getFaceList(params)
      if (r.code === 0) {
        this.list = r.data.list || []
        this.total = r.data.total || 0
        this.registeredCount = r.data.registered_count || 0
        this.unregisteredCount = r.data.unregistered_count || 0
      }
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () { this.filters = { keyword: '', face_status: '', department_id: '' }; this.page = 1; this.loadAll() },
    openRegister (row) { this.currentEmp = row; this.isReRegister = false; this.registerVisible = true },
    openReRegister (row) { this.currentEmp = row; this.isReRegister = true; this.registerVisible = true },
    openPreview (row) { this.currentEmp = row; this.previewVisible = true },
    removeFace (row) {
      this.$confirm(`确认删除员工「${row.name}」的人脸数据吗？删除后该员工将无法使用刷脸打卡。`, '提示', {
        type: 'warning', confirmButtonText: '确认删除', cancelButtonText: '取消'
      }).then(async () => {
        try {
          const r = await deleteFace(row.user_id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() }
          else this.$message.error(r.msg || '删除失败')
        } catch (e) { this.$message.error('请求失败') }
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.face-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; border-top: 3px solid #409EFF; padding: 14px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.04); }
.stat-icon { width: 44px; height: 44px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 22px; margin-right: 12px; }
.stat-value { font-size: 24px; font-weight: 700; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.filter-card { margin-bottom: 16px; }
.list-card .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; font-size: 13px; color: #606266; }
.pager { margin-top: 14px; text-align: right; }
</style>
