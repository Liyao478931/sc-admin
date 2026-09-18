<!--
  文件：admin/src/views/business/purchase/arrival/List.vue
  功能：采购到货列表（搜索/分页/状态标签/质检摘要/到货通知）
  权限：business:purchase:arrival:view/add/edit/delete/notice/quality/warehouse
-->
<template>
  <div class="ar-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购到货</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="到货单号">
          <el-input v-model="q.arrival_no" placeholder="请输入到货单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="采购订单">
          <el-input v-model="q.order_no" placeholder="请输入采购订单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="供应商">
          <el-input v-model="q.supplier" placeholder="请输入供应商名称" clearable style="width:140px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="到货状态">
          <el-select v-model="q.status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option v-for="(t, v) in STATUS_OPTIONS" :key="v" :label="t" :value="v" />
          </el-select>
        </el-form-item>
        <el-form-item label="到货日期">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:purchase:arrival:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push('/business/purchase/arrival/add')">新增到货登记</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border empty-text="暂无到货数据">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="到货单编号" width="150">
          <template slot-scope="s"><span class="link" @click="goDetail(s.row.id)">{{ s.row.arrival_no }}</span></template>
        </el-table-column>
        <el-table-column label="关联采购订单" width="140">
          <template slot-scope="s"><span class="link" @click="$router.push('/business/purchase/order/detail/' + s.row.order_id)">{{ s.row.order_no }}</span></template>
        </el-table-column>
        <el-table-column prop="supplier_name" label="供应商" width="130" show-overflow-tooltip />
        <el-table-column prop="arrival_date" label="到货日期" width="110" />
        <el-table-column label="到货状态" width="100" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="statusTag(s.row.status)">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="quality_summary" label="质检结果摘要" min-width="120" show-overflow-tooltip />
        <el-table-column label="物流信息" width="140" show-overflow-tooltip>
          <template slot-scope="s"><span>{{ s.row.logistics_company || '' }} {{ s.row.track_no || '' }}</span></template>
        </el-table-column>
        <el-table-column prop="receiver" label="收货人" width="90" align="center" />
        <el-table-column label="操作" width="240" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="goDetail(s.row.id)">查看详情</el-button>
            <el-button v-permission="'business:purchase:arrival:notice'" type="text" size="mini" @click="openNotice(s.row)">到货通知</el-button>
            <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
              <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1" v-permission="'business:purchase:arrival:edit'" command="edit">编辑</el-dropdown-item>
                <el-dropdown-item v-if="s.row.status === 0" v-permission="'business:purchase:arrival:delete'" command="del">删除</el-dropdown-item>
                <el-dropdown-item v-if="s.row.status === 2" v-permission="'business:purchase:arrival:warehouse'" command="warehouse">生成入库单</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper" :total="total" :page-sizes="[10, 20, 50, 100]" :page-size="q.pageSize" :current-page="q.page" @current-change="p => { q.page = p; getList() }" @size-change="s => { q.pageSize = s; q.page = 1; getList() }" />
    </el-card>

    <!-- 到货通知对话框 -->
    <el-dialog title="发送到货通知" :visible="noticeVisible" @update:visible="v => noticeVisible = v" width="560px" top="6vh">
      <el-form label-width="90px" size="small">
        <el-form-item label="通知对象">
          <div v-if="noticeOwner.id" class="notice-target"><el-checkbox :checked="true" disabled>{{ noticeOwner.name }}（采购专员）</el-checkbox></div>
          <div v-if="noticeDemander.id" class="notice-target"><el-checkbox v-model="noticeDemander.checked">{{ noticeDemander.name }}（需求人）</el-checkbox></div>
          <el-select v-model="noticeInspector" filterable clearable placeholder="选择质检员（可选）" style="width:100%;margin-top:6px;">
            <el-option v-for="u in userOptions" :key="u.id" :label="(u.real_name || u.username) + '（' + u.username + '）'" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="通知方式">
          <el-checkbox-group v-model="noticeChannels">
            <el-checkbox label="inbox">站内信</el-checkbox>
            <el-checkbox label="email">邮件</el-checkbox>
            <el-checkbox label="sms">短信</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="通知内容">
          <el-input v-model="noticeContent" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="noticeVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="noticeSending" @click="submitNotice">发送</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getArrivalList, deleteArrival, warehouseArrival, sendArrivalNotice, getArrivalDetail
} from '../../../../api/purchase'
import { getUserList } from '../../../../api/user'

const STATUS_OPTIONS = { 0: '待质检', 1: '质检中', 2: '质检合格', 3: '质检不合格', 4: '待入库', 5: '已入库' }

export default {
  name: 'PurchaseArrivalList',
  data () {
    return {
      STATUS_OPTIONS,
      q: { page: 1, pageSize: 10, arrival_no: '', order_no: '', supplier: '', status: '' },
      dateRange: null,
      list: [], total: 0, loading: false,
      noticeVisible: false, noticeSending: false,
      currentArrival: null, noticeOwner: {}, noticeDemander: { checked: true }, noticeInspector: null,
      noticeChannels: ['inbox'], noticeContent: '', userOptions: []
    }
  },
  created () { this.getList() },
  methods: {
    async getList () {
      this.loading = true
      try {
        const params = { page: this.q.page, pageSize: this.q.pageSize, ...this.q }
        if (this.dateRange && this.dateRange.length === 2) { params.start_date = this.dateRange[0]; params.end_date = this.dateRange[1] }
        const r = await getArrivalList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.q.page = 1; this.getList() },
    handleReset () {
      this.q = { page: 1, pageSize: this.q.pageSize, arrival_no: '', order_no: '', supplier: '', status: '' }
      this.dateRange = null
      this.getList()
    },
    statusTag (v) { return { 0: 'info', 1: 'primary', 2: 'success', 3: 'danger', 4: 'warning', 5: 'success' }[v] || 'info' },
    goDetail (id) { this.$router.push('/business/purchase/arrival/detail/' + id) },
    handleMore (cmd, row) {
      if (cmd === 'edit') this.$router.push('/business/purchase/arrival/add?id=' + row.id)
      if (cmd === 'del') {
        this.$confirm('确认删除到货单 ' + row.arrival_no + '？', '删除确认', { type: 'warning' }).then(async () => {
          try { const r = await deleteArrival(row.id); if (r.code === 0) { this.$message.success('已删除'); this.getList() } } catch (e) {}
        }).catch(() => {})
      }
      if (cmd === 'warehouse') {
        this.$confirm('确认生成入库单？到货单将变为"待入库"。', '生成入库单', { type: 'info' }).then(async () => {
          try {
            const r = await warehouseArrival(row.id)
            if (r.code === 0) { this.$message.success(r.msg || '已生成入库单'); this.getList() } else this.$message.error(r.msg || '操作失败')
          } catch (e) {}
        }).catch(() => {})
      }
    },
    async openNotice (row) {
      this.currentArrival = row
      this.noticeOwner = {}; this.noticeDemander = { checked: true }; this.noticeInspector = null
      this.noticeChannels = ['inbox']
      this.noticeContent = `您负责的订单 ${row.order_no} 已到货，请及时安排质检。`
      this.noticeVisible = true
      try {
        const r = await getArrivalDetail(row.id)
        if (r.code === 0) {
          this.noticeOwner = r.data.purchase_owner || {}
          this.noticeDemander = { ...(r.data.demander || {}), checked: true }
        }
      } catch (e) {}
      try {
        const u = await getUserList({ page: 1, limit: 200 })
        this.userOptions = (u.data && u.data.list) || []
      } catch (e) { this.userOptions = [] }
    },
    async submitNotice () {
      if (!this.noticeChannels.length) { this.$message.warning('请选择通知方式'); return }
      const targets = []
      if (this.noticeOwner.id) targets.push({ user_id: this.noticeOwner.id })
      if (this.noticeDemander.id && this.noticeDemander.checked) targets.push({ user_id: this.noticeDemander.id })
      if (this.noticeInspector) targets.push({ user_id: this.noticeInspector })
      if (!targets.length) { this.$message.warning('请选择通知对象'); return }
      this.noticeSending = true
      try {
        const r = await sendArrivalNotice(this.currentArrival.id, {
          notice_type: 1, content: this.noticeContent, targets, channels: this.noticeChannels
        })
        if (r.code === 0) { this.$message.success(r.msg || '通知已发送'); this.noticeVisible = false }
        else this.$message.error(r.msg || '发送失败')
      } catch (e) {} finally { this.noticeSending = false }
    }
  }
}
</script>

<style scoped>
.ar-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.filter-card { margin-bottom: 12px; }
.filter-btns { display: inline-block; margin-left: 4px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link { color: #409EFF; cursor: pointer; }
.pager { margin-top: 12px; text-align: right; }
.notice-target { margin-bottom: 6px; }
</style>
