<template>
  <div class="page-container">
    <el-row :gutter="14" class="stat-row">
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ stats.today_in || 0 }}</div><div class="stat-label">今日入库量</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num orange">{{ stats.today_out || 0 }}</div><div class="stat-label">今日出库量</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num green">{{ stats.today_count || 0 }}</div><div class="stat-label">今日扫码次数</div></el-card></el-col>
    </el-row>

    <el-card shadow="never" class="scan-card">
      <div class="scan-head">
        <div class="scan-title">扫码出入库</div>
        <el-radio-group v-model="scanForm.io_type" size="small">
          <el-radio-button label="in">入库</el-radio-button>
          <el-radio-button label="out">出库</el-radio-button>
        </el-radio-group>
      </div>
      <el-form inline size="small" class="scan-form" @submit.native.prevent>
        <el-form-item label="条码">
          <el-input v-model="scanForm.scan_code" placeholder="扫描或输入条码/物料ID" style="width:200px" @keyup.enter.native="doScan" />
        </el-form-item>
        <el-form-item label="数量"><el-input-number v-model="scanForm.quantity" :min="0" :precision="2" style="width:110px" /></el-form-item>
        <el-form-item label="批次号"><el-input v-model="scanForm.batch_no" style="width:140px" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="scanForm.remark" style="width:140px" /></el-form-item>
        <el-form-item>
          <el-button v-permission="'warehouse:scan:add'" type="primary" icon="el-icon-scan" size="small" @click="doScan">确认扫码</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词"><el-input v-model="filter.keyword" placeholder="条码/物料名称" clearable style="width:180px" @keyup.enter.native="load" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="filter.io_type" placeholder="全部" clearable style="width:110px">
            <el-option label="入库" value="in" /><el-option label="出库" value="out" />
          </el-select>
        </el-form-item>
        <el-form-item><el-button type="primary" icon="el-icon-search" @click="load">查询</el-button></el-form-item>
      </el-form>
    </el-card>
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column prop="scan_code" label="条码" min-width="130" />
        <el-table-column prop="item_name" label="物料名称" min-width="120" />
        <el-table-column prop="io_type" label="类型" width="80"><template #default="{row}"><el-tag :type="row.io_type === 'in' ? 'success' : 'warning'" size="mini">{{ row.io_type === 'in' ? '入库' : '出库' }}</el-tag></template></el-table-column>
        <el-table-column prop="quantity" label="数量" width="90" />
        <el-table-column prop="batch_no" label="批次号" width="140" />
        <el-table-column prop="operator" label="操作人" width="100" />
        <el-table-column prop="created_at" label="时间" width="155" />
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next, sizes" :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10,20,50,100]" @current-change="p => { page = p; load() }" @size-change="s => { pageSize = s; page = 1; load() }" />
    </el-card>
  </div>
</template>
<script>
import request from '@/api/request'
export default {
  name: 'WarehouseScanIo',
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, pageSize: 20,
      stats: {}, filter: { keyword: '', io_type: '' },
      scanForm: { scan_code: '', io_type: 'in', quantity: 1, batch_no: '', remark: '' }
    }
  },
  created() { this.load(); this.loadStats() },
  methods: {
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/scan-io/list', method: 'get', params: { page: this.page, pageSize: this.pageSize, keyword: this.filter.keyword, io_type: this.filter.io_type } })
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    async loadStats() {
      try {
        const res = await request({ url: '/scan-io/stats', method: 'get' })
        if (res.code === 0) this.stats = res.data || {}
      } catch (e) {}
    },
    async doScan() {
      if (!this.scanForm.scan_code) return this.$message.warning('请输入条码')
      try {
        const res = await request({ url: '/scan-io/scan', method: 'post', data: this.scanForm })
        if (res.code === 0) { this.$message.success(res.msg || '成功'); this.load(); this.loadStats(); this.scanForm.scan_code = ''; this.scanForm.quantity = 1; this.scanForm.batch_no = ''; this.scanForm.remark = '' }
        else this.$message.error(res.msg || '失败')
      } catch (e) { this.$message.error('操作失败') }
    }
  }
}
</script>
<style scoped>
.page-container { padding: 4px; }
.stat-row { margin-bottom: 10px; }
.stat-card { text-align: center; }
.stat-num { font-size: 24px; font-weight: 700; color: #333; }
.stat-num.blue { color: #409EFF; } .stat-num.orange { color: #E6A23C; } .stat-num.green { color: #67C23A; }
.stat-label { color: #909399; font-size: 13px; margin-top: 4px; }
.scan-card { margin-bottom: 10px; }
.scan-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
.scan-title { font-weight: 600; font-size: 15px; }
.filter-card { margin-bottom: 10px; }
.pager { margin-top: 12px; text-align: right; }
</style>
