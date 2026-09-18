<template>
  <div class="pkl-page">
    <el-breadcrumb separator="/" class="pkl-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产领用</el-breadcrumb-item>
      <el-breadcrumb-item>我的领用申请</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 筛选 -->
    <div class="pkl-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="申请状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:130px" @change="handleSearch">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="申请日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="开始" end-placeholder="结束" style="width:240px" />
        </el-form-item>
        <el-form-item label="配件名称">
          <el-input v-model="query.keyword" placeholder="模糊搜索" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作栏 -->
    <div class="pkl-toolbar">
      <el-button size="small" type="primary" icon="el-icon-plus" @click="goCreate">新增申请</el-button>
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <span class="pkl-total">共 {{ total }} 条</span>
    </div>

    <!-- 列表 -->
    <div class="pkl-table">
      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无领用申请，点击“新增申请”开始">
        <el-table-column label="申请单号" width="160">
          <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.apply_no }}</el-link></template>
        </el-table-column>
        <el-table-column prop="material_name" label="配件名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column label="申请数量" width="100">
          <template slot-scope="s">{{ s.row.apply_quantity }} {{ s.row.unit }}</template>
        </el-table-column>
        <el-table-column prop="purpose" label="用途说明" min-width="180" show-overflow-tooltip />
        <el-table-column label="申请日期" width="110">
          <template slot-scope="s">{{ String(s.row.created_at).slice(0, 10) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag :type="statusType(s.row.status)" size="mini">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="160" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openDetail(s.row)">查看</el-button>
            <el-button v-if="s.row.status === 1" type="text" size="mini" @click="goApproval(s.row)">审批进度</el-button>
            <el-button v-if="s.row.can_cancel" type="text" size="mini" style="color:#F56C6C" @click="handleCancel(s.row)">取消</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="pkl-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 详情弹窗 -->
    <el-dialog :title="'申请详情 - ' + (detail.apply_no || '')" :visible.sync="detailVisible" width="620px">
      <div v-loading="detailLoading" class="pkl-detail">
        <template v-if="detail.id">
          <div class="pkl-sec">
            <div class="pkl-sec-title">基本信息</div>
            <div class="pkl-grid">
              <div class="pkl-item"><span class="pkl-lb">申请单号</span>{{ detail.apply_no }}</div>
              <div class="pkl-item"><span class="pkl-lb">申请人</span>{{ detail.user_name }}</div>
              <div class="pkl-item"><span class="pkl-lb">部门</span>{{ detail.department_name || '-' }}</div>
              <div class="pkl-item"><span class="pkl-lb">申请日期</span>{{ String(detail.created_at).slice(0, 10) }}</div>
            </div>
          </div>
          <div class="pkl-sec">
            <div class="pkl-sec-title">配件信息</div>
            <div class="pkl-grid">
              <div class="pkl-item"><span class="pkl-lb">配件名称</span>{{ detail.material_name }}</div>
              <div class="pkl-item"><span class="pkl-lb">配件编码</span>{{ detail.material_code }}</div>
              <div class="pkl-item"><span class="pkl-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="pkl-item"><span class="pkl-lb">单位</span>{{ detail.unit }}</div>
              <div class="pkl-item"><span class="pkl-lb">申请数量</span>{{ detail.apply_quantity }}</div>
              <div class="pkl-item"><span class="pkl-lb">关联工单</span>{{ detail.work_order_no || '-' }}</div>
            </div>
          </div>
          <div class="pkl-sec">
            <div class="pkl-sec-title">审批信息</div>
            <div class="pkl-grid">
              <div class="pkl-item"><span class="pkl-lb">状态</span><el-tag :type="statusType(detail.status)" size="mini">{{ detail.status_label }}</el-tag></div>
              <div class="pkl-item"><span class="pkl-lb">审批人</span>{{ detail.approver_id ? 'ID:' + detail.approver_id : '-' }}</div>
              <div class="pkl-item"><span class="pkl-lb">审批时间</span>{{ detail.approve_time ? String(detail.approve_time).slice(0, 16) : '-' }}</div>
              <div class="pkl-item"><span class="pkl-lb">领料单</span>{{ detail.pick_order_id ? '已生成' : '-' }}</div>
            </div>
            <div v-if="detail.approve_remark" class="pkl-remark">审批备注：{{ detail.approve_remark }}</div>
            <div v-if="detail.reject_reason" class="pkl-remark" style="color:#F56C6C">驳回原因：{{ detail.reject_reason }}</div>
          </div>
          <div class="pkl-sec">
            <div class="pkl-sec-title">申请内容</div>
            <div class="pkl-remark">用途：{{ detail.purpose }}</div>
            <div v-if="detail.remark" class="pkl-remark">备注：{{ detail.remark }}</div>
          </div>
        </template>
      </div>
      <div slot="footer">
        <el-button v-if="detail.status === 0" size="small" type="primary" @click="goEdit(detail)">提交申请</el-button>
        <el-button v-if="detail.status === 3" size="small" type="primary" @click="goReapply(detail)">重新申请</el-button>
        <el-button size="small" @click="detailVisible = false">关闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getMyPickApplies, getPickApplyDetail, cancelPickApply } from '../../../api/pickApply'

const STATUS_TEXT = { 0: '草稿', 1: '审批中', 2: '已通过', 3: '已驳回', 4: '已取消' }

export default {
  name: 'PickApplyMyList',
  data () {
    return {
      STATUS_TEXT,
      list: [], total: 0, page: 1, limit: 20, loading: false,
      query: { status: '', keyword: '' }, dateRange: [],
      detailVisible: false, detailLoading: false, detail: {}
    }
  },
  created () { this.getList() },
  methods: {
    statusType (s) { return { 0: 'info', 1: 'warning', 2: 'success', 3: 'danger', 4: 'info' }[s] || 'info' },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.status !== '' && this.query.status != null) p.status = this.query.status
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getMyPickApplies(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { status: '', keyword: '' }; this.dateRange = []; this.page = 1; this.getList() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    goCreate () { this.$router.push('/personal-assets/pick-apply/create') },
    goApproval (row) {
      if (row.approval_instance_id) {
        this.$router.push('/approval/my-initiated/detail/' + row.approval_instance_id)
      } else {
        this.$message.info('审批实例尚未创建')
      }
    },
    async openDetail (row) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getPickApplyDetail(row.id)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.detailLoading = false
    },
    handleCancel (row) {
      this.$confirm('确认取消该申请吗？', '确认', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelPickApply(row.id)
          if (r.code === 0) { this.$message.success('申请已取消'); this.getList() }
        } catch (e) {}
      }).catch(() => {})
    },
    goEdit (detail) { this.$router.push('/personal-assets/pick-apply/create?material_id=' + detail.material_id) },
    goReapply (detail) {
      this.$router.push('/personal-assets/pick-apply/create?material_id=' + detail.material_id + '&specification=' + (detail.specification || '') + '&unit=' + detail.unit + '&quantity=' + detail.apply_quantity + '&purpose=' + encodeURIComponent(detail.purpose))
    }
  }
}
</script>

<style scoped>
.pkl-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.pkl-breadcrumb { margin-bottom: 12px; }
.pkl-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.pkl-filter .el-form-item { margin-bottom: 16px; }
.pkl-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.pkl-total { margin-left: 12px; color: #909399; font-size: 13px; }
.pkl-table { background: #fff; border-radius: 8px; padding: 12px; }
.pkl-pagination { display: flex; justify-content: flex-end; margin-top: 16px; }
.pkl-detail { min-height: 200px; }
.pkl-sec { margin-bottom: 16px; }
.pkl-sec-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.pkl-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.pkl-item { font-size: 13px; color: #303133; }
.pkl-lb { color: #909399; width: 70px; display: inline-block; }
.pkl-remark { font-size: 13px; color: #4b5a6c; margin-top: 6px; line-height: 1.7; }
</style>