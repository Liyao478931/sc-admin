<template>
  <div class="points-page">
    <!-- 操作按钮栏 -->
    <el-card shadow="never" class="toolbar-card">
      <div class="toolbar">
        <div>
          <el-button v-if="hasPerm('attendance:points:manage')" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增打卡点</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
        <span class="stat-text">共 <b>{{ total }}</b> 个打卡点</span>
      </div>
    </el-card>

    <!-- 筛选 -->
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="搜索打卡点名称/地址" clearable style="width:220px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:120px" @change="onSearch">
            <el-option label="启用" value="enabled" />
            <el-option label="停用" value="disabled" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 列表 -->
    <el-card shadow="never" class="list-card">
      <el-table :data="list" v-loading="loading" size="small" stripe>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="point_name" label="打卡点名称" width="140" show-overflow-tooltip />
        <el-table-column prop="address" label="地址" width="200" show-overflow-tooltip />
        <el-table-column label="经纬度" width="170">
          <template slot-scope="{ row }">{{ row.latitude }}, {{ row.longitude }}</template>
        </el-table-column>
        <el-table-column label="半径" width="90" align="center">
          <template slot-scope="{ row }">{{ row.radius }}米</template>
        </el-table-column>
        <el-table-column label="打卡时间" width="130" align="center">
          <template slot-scope="{ row }">{{ row.start_time_hm || '--:--' }} - {{ row.end_time_hm || '--:--' }}</template>
        </el-table-column>
        <el-table-column prop="weekdays_label" label="有效星期" width="200" show-overflow-tooltip />
        <el-table-column prop="department_names" label="关联部门" width="140" show-overflow-tooltip />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status_label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('attendance:points:manage')" type="text" size="mini" icon="el-icon-edit" @click="openForm(row.id)">编辑</el-button>
            <el-button v-if="hasPerm('attendance:points:manage')" type="text" size="mini" icon="el-icon-switch-button" @click="toggle(row)">{{ row.status === 1 ? '停用' : '启用' }}</el-button>
            <el-button v-if="hasPerm('attendance:points:manage')" type="text" size="mini" icon="el-icon-delete" style="color:#F56C6C" @click="removeOne(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <points-form v-if="formVisible" :visible.sync="formVisible" :point-id="currentId" @saved="loadAll" />
  </div>
</template>

<script>
import { getPointsList, deletePoint, togglePoint } from '@/api/attendancePoints'
import PointsForm from './components/PointsForm.vue'

export default {
  name: 'AttendancePoints',
  components: { PointsForm },
  data () {
    return {
      list: [], total: 0, page: 1, limit: 10, loading: false,
      filters: { keyword: '', status: '' },
      formVisible: false, currentId: 0
    }
  },
  created () { this.loadAll() },
  methods: {
    hasPerm (code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadAll () {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.limit }
        if (this.filters.keyword) params.keyword = this.filters.keyword
        if (this.filters.status) params.status = this.filters.status
        const r = await getPointsList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () { this.filters = { keyword: '', status: '' }; this.page = 1; this.loadAll() },
    openForm (id) { this.currentId = id || 0; this.formVisible = true },
    async toggle (row) {
      try {
        const r = await togglePoint(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.loadAll() }
      } catch (e) {}
    },
    removeOne (row) {
      this.$confirm(`确认删除打卡点「${row.point_name}」吗？删除后该打卡点将不可用。`, '提示', {
        type: 'warning', confirmButtonText: '确认删除', cancelButtonText: '取消'
      }).then(async () => {
        try {
          const r = await deletePoint(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.points-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.toolbar-card { margin-bottom: 16px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; }
.stat-text { font-size: 13px; color: #606266; }
.filter-card { margin-bottom: 16px; }
.pager { margin-top: 14px; text-align: right; }
</style>
