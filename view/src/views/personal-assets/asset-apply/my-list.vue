<template>
  <div class="aal-page">
    <el-breadcrumb separator="/" class="aal-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产领用</el-breadcrumb-item>
      <el-breadcrumb-item>资产领用申请</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div class="aal-banner">
      <i class="el-icon-info aa-banner-icon"></i>
      <span>资产领用申请：申请领用公司固定资产到个人名下，需经审批后生效。</span>
    </div>

    <!-- 筛选 -->
    <div class="aal-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="申请状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:130px" @change="handleSearch">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="申请日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="开始" end-placeholder="结束" style="width:240px" />
        </el-form-item>
        <el-form-item label="资产名称">
          <el-input v-model="query.keyword" placeholder="模糊搜索" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作栏 -->
    <div class="aal-toolbar">
      <el-button size="small" type="primary" icon="el-icon-plus" @click="goCreate">新增申请</el-button>
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <span class="aal-total">共 {{ total }} 条</span>
    </div>

    <!-- 列表 -->
    <div class="aal-table">
      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无资产领用申请，点击“新增申请”开始">
        <el-table-column label="申请单号" width="160">
          <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.apply_no }}</el-link></template>
        </el-table-column>
        <el-table-column prop="asset_name" label="资产名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="asset_no" label="资产编号" width="120" />
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
        <el-table-column label="操作" width="200" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openDetail(s.row)">查看</el-button>
            <el-button v-if="s.row.status === 1" type="text" size="mini" @click="goApproval(s.row)">审批进度</el-button>
            <el-button v-if="s.row.status === 2 && s.row.personal_asset_id" type="text" size="mini" @click="goPersonalAsset(s.row)">个人资产</el-button>
            <el-button v-if="s.row.can_cancel" type="text" size="mini" style="color:#F56C6C" @click="handleCancel(s.row)">取消</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="aal-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 详情弹窗 -->
    <el-dialog :title="'申请详情 - ' + (detail.apply_no || '')" :visible.sync="detailVisible" width="620px">
      <div v-loading="detailLoading" class="aal-detail">
        <template v-if="detail.id">
          <div class="aal-sec">
            <div class="aal-sec-title">基本信息</div>
            <div class="aal-grid">
              <div class="aal-item"><span class="aal-lb">申请单号</span>{{ detail.apply_no }}</div>
              <div class="aal-item"><span class="aal-lb">申请人</span>{{ detail.user_name }}</div>
              <div class="aal-item"><span class="aal-lb">部门</span>{{ detail.department_id ? '部门ID:' + detail.department_id : '-' }}</div>
              <div class="aal-item"><span class="aal-lb">申请日期</span>{{ String(detail.created_at).slice(0, 10) }}</div>
            </div>
          </div>
          <div class="aal-sec">
            <div class="aal-sec-title">资产信息</div>
            <div class="aal-grid">
              <div class="aal-item"><span class="aal-lb">资产名称</span>{{ detail.asset_name }}</div>
              <div class="aal-item"><span class="aal-lb">资产编号</span>{{ detail.asset_no }}</div>
              <div class="aal-item"><span class="aal-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="aal-item"><span class="aal-lb">单位</span>{{ detail.unit }}</div>
              <div class="aal-item"><span class="aal-lb">申请数量</span>{{ detail.apply_quantity }}</div>
              <div class="aal-item"><span class="aal-lb">原值</span>{{ detail.original_value ? '¥' + Number(detail.original_value).toFixed(2) : '-' }}</div>
            </div>
          </div>
          <div class="aal-sec">
            <div class="aal-sec-title">审批信息</div>
            <div class="aal-grid">
              <div class="aal-item"><span class="aal-lb">状态</span><el-tag :type="statusType(detail.status)" size="mini">{{ detail.status_label }}</el-tag></div>
            </div>
            <div v-if="detail.reject_reason" class="aal-remark" style="color:#F56C6C">驳回原因：{{ detail.reject_reason }}</div>
          </div>
          <div class="aal-sec">
            <div class="aal-sec-title">申请内容</div>
            <div class="aal-remark">用途：{{ detail.purpose }}</div>
            <div v-if="detail.remark" class="aal-remark">备注：{{ detail.remark }}</div>
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
import { getMyAssetApplies, getAssetApplyDetail, cancelAssetApply } from '../../../api/assetApply'

const STATUS_TEXT = { 0: '草稿', 1: '审批中', 2: '已通过', 3: '已驳回', 4: '已取消' }

export default {
  name: 'AssetApplyMyList',
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
        const r = await getMyAssetApplies(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { status: '', keyword: '' }; this.dateRange = []; this.page = 1; this.getList() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    goCreate () { this.$router.push('/personal-assets/asset-apply/create') },
    goApproval (row) {
      if (row.approval_instance_id) {
        this.$router.push('/approval/my-initiated/detail/' + row.approval_instance_id)
      } else {
        this.$message.info('审批实例尚未创建')
      }
    },
    goPersonalAsset (row) {
      this.$router.push('/personal-assets/my-list')
    },
    async openDetail (row) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getAssetApplyDetail(row.id)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.detailLoading = false
    },
    handleCancel (row) {
      this.$confirm('确认取消该申请吗？', '确认', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelAssetApply(row.id)
          if (r.code === 0) { this.$message.success('申请已取消'); this.getList() }
        } catch (e) {}
      }).catch(() => {})
    },
    goEdit (detail) { this.$router.push('/personal-assets/asset-apply/create?asset_archive_id=' + detail.asset_archive_id) },
    goReapply (detail) {
      this.$router.push('/personal-assets/asset-apply/create?asset_archive_id=' + detail.asset_archive_id + '&asset_no=' + (detail.asset_no || '') + '&specification=' + (detail.specification || '') + '&unit=' + detail.unit + '&original_value=' + (detail.original_value || 0) + '&quantity=' + detail.apply_quantity + '&purpose=' + encodeURIComponent(detail.purpose))
    }
  }
}
</script>

<style scoped>
.aal-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.aal-breadcrumb { margin-bottom: 12px; }
.aal-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; font-size: 14px; color: #5a6b7f; }
.aal-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.aal-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.aal-filter .el-form-item { margin-bottom: 16px; }
.aal-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.aal-total { margin-left: 12px; color: #909399; font-size: 13px; }
.aal-table { background: #fff; border-radius: 8px; padding: 12px; }
.aal-pagination { display: flex; justify-content: flex-end; margin-top: 16px; }
.aal-detail { min-height: 200px; }
.aal-sec { margin-bottom: 16px; }
.aal-sec-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.aal-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.aal-item { font-size: 13px; color: #303133; }
.aal-lb { color: #909399; width: 70px; display: inline-block; }
.aal-remark { font-size: 13px; color: #4b5a6c; margin-top: 6px; line-height: 1.7; }
</style>