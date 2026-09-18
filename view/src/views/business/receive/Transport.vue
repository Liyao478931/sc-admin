<template>
  <!-- 产品接收 - 运输管理 -->
  <div class="transport-page">
    <el-card shadow="never">
      <div class="toolbar">
        <el-button size="small" type="primary" icon="el-icon-plus" @click="openDialog()">新增运输单</el-button>
        <el-input v-model="keyword" size="small" placeholder="运输单号/车牌/司机/物流公司/接收单号" style="width:220px" clearable @keyup.enter="loadList" />
        <el-select v-model="status" size="small" clearable placeholder="全部状态" style="width:120px" @change="loadList">
          <el-option label="待发车" :value="0" />
          <el-option label="运输中" :value="1" />
          <el-option label="已到达" :value="2" />
          <el-option label="已签收" :value="3" />
        </el-select>
        <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
      </div>

      <el-table :data="list" v-loading="loading" size="small" border stripe>
        <el-table-column prop="transport_no" label="运输单号" width="140" />
        <el-table-column prop="receipt_no" label="接收单号" width="140" />
        <el-table-column prop="customer_name" label="客户" width="140" show-overflow-tooltip />
        <el-table-column label="运输方式" width="100">
          <template slot-scope="{ row }">{{ typeLabel(row.transport_type) }}</template>
        </el-table-column>
        <el-table-column prop="plate_no" label="车牌号" width="110">
          <template slot-scope="{ row }">{{ row.plate_no || '-' }}</template>
        </el-table-column>
        <el-table-column prop="driver_name" label="司机" width="90">
          <template slot-scope="{ row }">{{ row.driver_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="driver_phone" label="联系电话" width="120">
          <template slot-scope="{ row }">{{ row.driver_phone || '-' }}</template>
        </el-table-column>
        <el-table-column prop="logistics_company" label="物流公司" width="120" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.logistics_company || '-' }}</template>
        </el-table-column>
        <el-table-column prop="track_no" label="运单号" width="120">
          <template slot-scope="{ row }">{{ row.track_no || '-' }}</template>
        </el-table-column>
        <el-table-column label="运费" width="100">
          <template slot-scope="{ row }">¥{{ Number(row.freight_amount).toLocaleString() }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template slot-scope="{ row }">
            <el-tag :type="statusTag(row.transport_status)" size="mini">{{ statusLabel(row.transport_status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="row.transport_status < 3" type="success" size="mini" @click="nextStatus(row)">{{ statusNextLabel(row.transport_status) }}</el-button>
            <el-button type="text" size="mini" @click="openDialog(row)">编辑</el-button>
            <el-button type="text" size="mini" style="color:#F56C6C" @click="delRow(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        class="pager"
        background
        layout="total, prev, pager, next, sizes"
        :total="total"
        :page-size="limit"
        :current-page="page"
        :page-sizes="[10, 15, 30, 50]"
        @current-change="p => { page = p; loadList() }"
        @size-change="s => { limit = s; page = 1; loadList() }"
      />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑运输单' : '新增运输单'" :visible.sync="dialog" width="560px" @closed="resetForm">
      <el-form label-width="100px" size="small">
        <el-form-item label="关联接收单" required>
          <el-select v-model="form.receipt_id" style="width:100%" :disabled="!!form.id" filterable placeholder="选择未关联运输的接收单">
            <el-option v-for="r in receiptOptions" :key="r.id" :label="`${r.receipt_no}（${r.customer_name || r.source_location || '-'}）`" :value="r.id" />
          </el-select>
        </el-form-item>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="运输方式">
              <el-select v-model="form.transport_type" style="width:100%">
                <el-option label="公司派车" :value="1" />
                <el-option label="外包物流" :value="2" />
                <el-option label="客户自送" :value="3" />
                <el-option label="其他" :value="4" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="车牌号"><el-input v-model="form.plate_no" /></el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="司机"><el-input v-model="form.driver_name" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="联系电话"><el-input v-model="form.driver_phone" /></el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="物流公司"><el-input v-model="form.logistics_company" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="运单号"><el-input v-model="form.track_no" /></el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="发运地址"><el-input v-model="form.ship_address" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="收货地址"><el-input v-model="form.receive_address" /></el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="10">
          <el-col :span="8">
            <el-form-item label="发车日期"><el-date-picker v-model="form.depart_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="预计到达"><el-date-picker v-model="form.expected_arrive_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="实际到达"><el-date-picker v-model="form.actual_arrive_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="运费(元)"><el-input-number v-model="form.freight_amount" :min="0" :precision="2" style="width:100%" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="状态">
              <el-select v-model="form.transport_status" style="width:100%">
                <el-option label="待发车" :value="0" />
                <el-option label="运输中" :value="1" />
                <el-option label="已到达" :value="2" />
                <el-option label="已签收" :value="3" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="dialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import axios from 'axios'
import { getToken } from '@/utils/auth'

// 运输管理接口走主应用路由，独立实例（带 token）
const api = axios.create({ baseURL: '', timeout: 15000 })
api.interceptors.request.use(config => {
  const token = getToken()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

export default {
  name: 'ReceiveTransport',
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      page: 1,
      limit: 15,
      keyword: '',
      status: '',
      dialog: false,
      receiptOptions: [],
      form: { id: 0, receipt_id: null, transport_type: 1, plate_no: '', driver_name: '', driver_phone: '', logistics_company: '', track_no: '', depart_date: '', expected_arrive_date: '', actual_arrive_date: '', ship_address: '', receive_address: '', freight_amount: 0, transport_status: 0, remark: '' },
    }
  },
  created() { this.loadList(); this.loadOptions() },
  methods: {
    async req(url, method = 'get', data = {}) {
      try {
        const r = await api({ url: `/index.php/receive-transport/${url}`, method, params: method === 'get' ? data : undefined, data: method === 'get' ? undefined : data })
        const res = r.data
        if (res.code === 0) return res.data
        this.$message.error(res.msg || '请求失败')
        return null
      } catch (e) {
        this.$message.error('网络错误，请稍后重试')
        return null
      }
    },
    async loadList() {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.limit }
        if (this.keyword) params.keyword = this.keyword
        if (this.status !== '') params.status = this.status
        const data = await this.req('list', 'get', params)
        if (data) { this.list = data.list || []; this.total = data.total || 0 }
      } finally { this.loading = false }
    },
    async loadOptions() {
      const data = await this.req('options')
      if (data) this.receiptOptions = data
    },
    openDialog(row) {
      if (row) {
        this.form = { ...row, freight_amount: Number(row.freight_amount) }
      } else {
        this.resetForm()
      }
      this.dialog = true
    },
    resetForm() {
      this.form = { id: 0, receipt_id: null, transport_type: 1, plate_no: '', driver_name: '', driver_phone: '', logistics_company: '', track_no: '', depart_date: '', expected_arrive_date: '', actual_arrive_date: '', ship_address: '', receive_address: '', freight_amount: 0, transport_status: 0, remark: '' }
      this.loadOptions()
    },
    async save() {
      if (!this.form.receipt_id) { this.$message.warning('请选择关联接收单'); return }
      const data = await this.req('save', 'post', this.form)
      if (data) { this.$message.success(this.form.id ? '运输单已更新' : '运输单已创建'); this.dialog = false; this.loadList() }
    },
    async nextStatus(row) {
      const next = row.transport_status + 1
      const label = this.statusLabel(next)
      await this.$confirm(`确认将运输单 ${row.transport_no} 状态更新为「${label}」？`, '提示', { type: 'warning' })
      const data = await this.req('status', 'post', { id: row.id, status: next })
      if (data) { this.$message.success(`状态已更新为${label}`); this.loadList() }
    },
    async delRow(row) {
      await this.$confirm(`确认删除运输单 ${row.transport_no}？`, '提示', { type: 'warning' })
      const data = await this.req('delete', 'post', { id: row.id })
      if (data) { this.$message.success('已删除'); this.loadList() }
    },
    typeLabel(t) { return { 1: '公司派车', 2: '外包物流', 3: '客户自送', 4: '其他' }[t] || '-' },
    statusLabel(s) { return { 0: '待发车', 1: '运输中', 2: '已到达', 3: '已签收' }[s] || '-' },
    statusNextLabel(s) { return { 0: '发车', 1: '到达', 2: '签收' }[s] || '-' },
    statusTag(s) { return { 0: 'info', 1: 'warning', 2: 'success', 3: 'success' }[s] || 'info' },
  },
}
</script>

<style scoped>
.toolbar { display: flex; gap: 10px; margin-bottom: 14px; align-items: center; }
.pager { margin-top: 14px; text-align: right; }
</style>
