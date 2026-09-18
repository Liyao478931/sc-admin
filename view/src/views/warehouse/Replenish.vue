<template>
  <div class="replenish-page">
    <el-card shadow="never" class="box-card">
      <div class="stat-grid">
        <div class="stat-card">
          <div class="stat-num">{{ summary.pending }}</div>
          <div class="stat-label">待处理建议</div>
        </div>
        <div class="stat-card ok">
          <div class="stat-num">{{ summary.confirmed }}</div>
          <div class="stat-label">已确认建议</div>
        </div>
        <div class="stat-card warn">
          <div class="stat-num">{{ summary.total_qty }}</div>
          <div class="stat-label">待补货数量</div>
        </div>
        <div class="stat-card danger">
          <div class="stat-num">{{ summary.shortage }}</div>
          <div class="stat-label">短缺物料</div>
        </div>
      </div>
    </el-card>

    <el-card shadow="never" class="box-card">
      <div class="search-row">
        <el-select v-model="query.status" placeholder="状态" clearable style="width: 130px" @change="loadList(1)">
          <el-option label="待处理" value="0" />
          <el-option label="已确认" value="1" />
          <el-option label="已忽略" value="2" />
        </el-select>
        <el-input v-model="query.keyword" placeholder="建议编号/物料编码/物料名称" clearable style="width: 240px" @keyup.enter.native="loadList(1)" />
        <el-button type="primary" icon="el-icon-search" @click="loadList(1)">查询</el-button>
        <el-button type="success" icon="el-icon-refresh" :loading="genLoading" @click="handleGenerate">生成补货建议</el-button>
      </div>

      <el-table v-loading="loading" :data="list" border stripe style="margin-top: 14px">
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="suggest_no" label="建议编号" width="140" />
        <el-table-column label="物料" min-width="180">
          <template slot-scope="{ row }">
            <div>{{ row.material_name }}</div>
            <div class="sub-text">{{ row.material_code }} {{ row.specification }} / {{ row.unit }}</div>
          </template>
        </el-table-column>
        <el-table-column label="当前库存" width="100" align="right">
          <template slot-scope="{ row }">{{ fmtNum(row.current_stock) }}</template>
        </el-table-column>
        <el-table-column label="安全库存" width="100" align="right">
          <template slot-scope="{ row }">{{ fmtNum(row.safety_stock) }}</template>
        </el-table-column>
        <el-table-column label="建议补货" width="100" align="right">
          <template slot-scope="{ row }"><span class="suggest-qty">{{ fmtNum(row.suggest_qty) }}</span></template>
        </el-table-column>
        <el-table-column label="原因" width="120">
          <template slot-scope="{ row }">
            <el-tag :type="row.reason === 'shortage' ? 'danger' : 'warning'" size="small">{{ row.reason_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template slot-scope="{ row }">
            <el-tag :type="row.status === 0 ? 'warning' : row.status === 1 ? 'success' : 'info'" size="small">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="确认人/时间" min-width="150">
          <template slot-scope="{ row }">
            <div v-if="row.confirm_user_name">{{ row.confirm_user_name }}</div>
            <div class="sub-text" v-if="row.confirm_time">{{ row.confirm_time }}</div>
            <span v-else class="sub-text">-</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" align="center" fixed="right">
          <template slot-scope="{ row }">
            <template v-if="row.status === 0">
              <el-button type="success" size="mini" icon="el-icon-check" @click="handleConfirm(row)">确认</el-button>
              <el-button type="info" size="mini" icon="el-icon-close" @click="handleDismiss(row)">忽略</el-button>
            </template>
            <span v-else class="sub-text">-</span>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager-row">
        <el-pagination
          background
          layout="total, prev, pager, next"
          :total="total"
          :page-size="query.limit"
          :current-page="query.page"
          @current-change="loadList" />
      </div>
    </el-card>
  </div>
</template>

<script>
import request from '@/api/request'

export default {
  name: 'WarehouseReplenish',
  data() {
    return {
      loading: false,
      genLoading: false,
      summary: { pending: 0, confirmed: 0, total_qty: 0, shortage: 0 },
      query: { status: '', keyword: '', page: 1, limit: 20 },
      list: [],
      total: 0
    }
  },
  mounted() {
    this.loadSummary()
    this.loadList(1)
  },
  methods: {
    fmtNum(v) {
      const n = Number(v || 0)
      return n % 1 === 0 ? n : n.toFixed(2)
    },
    loadSummary() {
      request.get('/stock-replenish/summary').then((res) => {
        this.summary = res.data || { pending: 0, confirmed: 0, total_qty: 0, shortage: 0 }
      }).catch(() => {})
    },
    loadList(page) {
      this.query.page = page || 1
      this.loading = true
      const params = { page: this.query.page, limit: this.query.limit }
      if (this.query.status !== '') params.status = this.query.status
      if (this.query.keyword) params.keyword = this.query.keyword
      request.get('/stock-replenish/list', { params }).then((res) => {
        const d = res.data || { list: [], total: 0 }
        this.list = d.list || []
        this.total = d.total || 0
      }).finally(() => { this.loading = false })
    },
    handleGenerate() {
      this.$confirm('将根据当前库存与安全库存重新生成补货建议，确定执行？', '生成补货建议', { type: 'warning' }).then(() => {
        this.genLoading = true
        request.post('/stock-replenish/generate').then((res) => {
          this.$message.success(res.msg || '生成成功')
          this.loadSummary()
          this.loadList(1)
        }).finally(() => { this.genLoading = false })
      }).catch(() => {})
    },
    handleConfirm(row) {
      this.$confirm(`确认补货建议 ${row.suggest_no}？确认后将进入采购跟进。`, '确认建议', { type: 'warning' }).then(() => {
        request.post('/stock-replenish/confirm', { id: row.id }).then((res) => {
          this.$message.success(res.msg || '已确认')
          this.loadSummary()
          this.loadList(this.query.page)
        })
      }).catch(() => {})
    },
    handleDismiss(row) {
      this.$confirm(`确定忽略建议 ${row.suggest_no}？`, '忽略建议', { type: 'info' }).then(() => {
        request.post('/stock-replenish/dismiss', { id: row.id }).then((res) => {
          this.$message.success(res.msg || '已忽略')
          this.loadSummary()
          this.loadList(this.query.page)
        })
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.stat-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
}
.stat-card {
  flex: 1 1 160px;
  min-width: 0;
  padding: 16px;
  border-radius: 12px;
  background: linear-gradient(135deg, rgba(139, 200, 234, 0.15), rgba(139, 200, 234, 0.28));
  box-sizing: border-box;
}
.stat-card.ok { background: linear-gradient(135deg, rgba(82, 196, 26, 0.1), rgba(82, 196, 26, 0.2)); }
.stat-card.warn { background: linear-gradient(135deg, rgba(250, 173, 20, 0.1), rgba(250, 173, 20, 0.22)); }
.stat-card.danger { background: linear-gradient(135deg, rgba(234, 102, 104, 0.1), rgba(234, 102, 104, 0.2)); }
.stat-num {
  font-size: 26px;
  font-weight: 600;
  color: #1A1B1C;
}
.stat-label {
  margin-top: 6px;
  font-size: 13px;
  color: #6B7280;
}
.search-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
}
.sub-text {
  font-size: 12px;
  color: #9CA3AF;
}
.suggest-qty {
  color: #EA6668;
  font-weight: 600;
}
.pager-row {
  margin-top: 14px;
  display: flex;
  justify-content: flex-end;
}
</style>
