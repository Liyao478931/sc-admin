<template>
  <div class="trace-page">
    <el-breadcrumb separator="/">
      <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
      <el-breadcrumb-item>质量管理</el-breadcrumb-item>
      <el-breadcrumb-item>质量追溯</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索区 -->
    <el-card class="box-card" shadow="never">
      <div class="search-row">
        <el-input
          v-model="keyword"
          placeholder="输入工单号 / 产品名称 / 规格 / 客户搜索"
          clearable
          style="width: 360px"
          @keyup.enter.native="doSearch"
        ></el-input>
        <el-button type="primary" icon="el-icon-search" @click="doSearch">搜索工单</el-button>
        <el-button type="success" icon="el-icon-download" :disabled="!current" @click="doExport">导出追溯报告</el-button>
      </div>
      <!-- 搜索结果 -->
      <el-table
        v-if="searchList.length > 0"
        :data="searchList"
        highlight-current-row
        style="margin-top: 12px"
        @current-change="selectOrder"
      >
        <el-table-column type="index" label="#" width="50"></el-table-column>
        <el-table-column prop="order_no" label="工单号" width="180"></el-table-column>
        <el-table-column prop="type_text" label="类型" width="100"></el-table-column>
        <el-table-column prop="product_name" label="产品" min-width="140"></el-table-column>
        <el-table-column prop="product_spec" label="规格" width="110"></el-table-column>
        <el-table-column prop="customer_name" label="客户" min-width="120"></el-table-column>
        <el-table-column prop="plan_quantity" label="计划数量" width="100"></el-table-column>
        <el-table-column prop="progress" label="进度" width="80">
          <template slot-scope="{ row }">{{ row.progress }}%</template>
        </el-table-column>
        <el-table-column prop="status_text" label="状态" width="90">
          <template slot-scope="{ row }">
            <el-tag :type="row.status_tag" size="small">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100">
          <template slot-scope="{ row }">
            <el-button type="text" icon="el-icon-view" @click="loadTrace(row.id)">追溯</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-empty v-if="searched && searchList.length === 0" description="未找到匹配的工单"></el-empty>
    </el-card>

    <!-- 追溯结果 -->
    <template v-if="trace">
      <!-- 工单概览 -->
      <el-card class="box-card" shadow="never" style="margin-top: 14px">
        <div slot="header" class="card-header">
          <span><i class="el-icon-s-order"></i> 工单概览</span>
          <el-tag :type="trace.order.status_tag" size="small">{{ trace.order.status_text }}</el-tag>
        </div>
        <el-descriptions :column="4" border size="small">
          <el-descriptions-item label="工单号">{{ trace.order.order_no }}</el-descriptions-item>
          <el-descriptions-item label="类型">{{ trace.order.type_text }}</el-descriptions-item>
          <el-descriptions-item label="产品">{{ trace.order.product_name }}</el-descriptions-item>
          <el-descriptions-item label="规格">{{ trace.order.product_spec }}</el-descriptions-item>
          <el-descriptions-item label="客户">{{ trace.order.customer_name }}</el-descriptions-item>
          <el-descriptions-item label="计划数量">{{ trace.order.plan_quantity }}</el-descriptions-item>
          <el-descriptions-item label="完成数量">{{ trace.order.completed_quantity }}</el-descriptions-item>
          <el-descriptions-item label="进度">{{ trace.order.progress }}%</el-descriptions-item>
          <el-descriptions-item label="负责人">{{ trace.order.responsible_person_name || '—' }}</el-descriptions-item>
          <el-descriptions-item label="部门">{{ trace.order.department_name || '—' }}</el-descriptions-item>
          <el-descriptions-item label="计划开始">{{ trace.order.planned_start_date || '—' }}</el-descriptions-item>
          <el-descriptions-item label="计划完成">{{ trace.order.planned_end_date || '—' }}</el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 汇总统计 -->
      <el-card class="box-card" shadow="never" style="margin-top: 14px">
        <div slot="header" class="card-header">
          <span><i class="el-icon-data-analysis"></i> 追溯汇总</span>
          <el-button type="text" icon="el-icon-download" @click="doExport">导出</el-button>
        </div>
        <div class="stat-grid">
          <div class="stat-card"><div class="stat-num">{{ s.report_count }}</div><div class="stat-label">报工记录</div></div>
          <div class="stat-card"><div class="stat-num">{{ s.report_approved }}</div><div class="stat-label">已通过报工</div></div>
          <div class="stat-card"><div class="stat-num">{{ s.inspection_count }}</div><div class="stat-label">质检记录</div></div>
          <div class="stat-card ok"><div class="stat-num">{{ s.qualified_count }}</div><div class="stat-label">合格批次</div></div>
          <div class="stat-card bad"><div class="stat-num">{{ s.unqualified_count }}</div><div class="stat-label">不合格批次</div></div>
          <div class="stat-card"><div class="stat-num">{{ s.pick_count }}</div><div class="stat-label">领料单</div></div>
          <div class="stat-card"><div class="stat-num">{{ s.material_count }}</div><div class="stat-label">物料种数</div></div>
          <div class="stat-card"><div class="stat-num">{{ s.batch_count }}</div><div class="stat-label">关联批次</div></div>
        </div>
      </el-card>

      <!-- 派工记录 -->
      <el-card class="box-card" shadow="never" style="margin-top: 14px" v-if="trace.dispatch.length">
        <div slot="header" class="card-header"><span><i class="el-icon-s-promotion"></i> 派工记录</span></div>
        <el-table :data="trace.dispatch" size="small" border>
          <el-table-column prop="dispatch_no" label="派工单号" width="170"></el-table-column>
          <el-table-column prop="dispatcher_name" label="派工人" width="110"></el-table-column>
          <el-table-column prop="dispatch_date" label="派工日期" width="120"></el-table-column>
          <el-table-column prop="planned_start_date" label="计划开始" width="120"></el-table-column>
          <el-table-column prop="planned_end_date" label="计划结束" width="120"></el-table-column>
          <el-table-column prop="status_text" label="状态" width="90"></el-table-column>
          <el-table-column prop="remark" label="备注"></el-table-column>
        </el-table>
      </el-card>

      <!-- 工序报工时间线 -->
      <el-card class="box-card" shadow="never" style="margin-top: 14px" v-if="trace.reports.length">
        <div slot="header" class="card-header"><span><i class="el-icon-time"></i> 工序 / 报工记录（{{ trace.reports.length }}）</span></div>
        <el-timeline>
          <el-timeline-item
            v-for="r in trace.reports"
            :key="r.id"
            :timestamp="r.report_date + '  ' + r.report_no"
            :color="r.status === 2 ? '#52C41A' : r.status === 3 ? '#EA6668' : '#8BC8EA'"
          >
            <div class="tl-row">
              <span class="tl-tag">{{ r.task_text }}</span>
              <b>{{ r.process_name }}</b>
              <span class="tl-sub">工位：{{ r.workstation_name }}</span>
              <span class="tl-sub">设备：{{ r.device_name }}</span>
              <span class="tl-sub">报工人：{{ r.reporter_name }}</span>
              <span class="tl-sub">数量：{{ r.quantity }}</span>
              <span class="tl-sub">得分：{{ r.total_score }}</span>
              <el-tag :type="r.status_tag" size="mini">{{ r.status_text }}</el-tag>
            </div>
          </el-timeline-item>
        </el-timeline>
      </el-card>

      <!-- 质检记录 -->
      <el-card class="box-card" shadow="never" style="margin-top: 14px">
        <div slot="header" class="card-header"><span><i class="el-icon-circle-check"></i> 质检记录（{{ trace.inspections.length }}）</span></div>
        <el-table :data="trace.inspections" size="small" border v-if="trace.inspections.length">
          <el-table-column prop="inspection_no" label="检验单号" width="170"></el-table-column>
          <el-table-column prop="product_name" label="产品" min-width="120"></el-table-column>
          <el-table-column prop="inspector_name" label="检验员" width="100"></el-table-column>
          <el-table-column prop="inspection_date" label="检验日期" width="120"></el-table-column>
          <el-table-column prop="result_text" label="结果" width="90">
            <template slot-scope="{ row }">
              <el-tag :type="row.result_tag" size="small">{{ row.result_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="conclusion" label="结论" min-width="200"></el-table-column>
          <el-table-column label="检验项" width="110">
            <template slot-scope="{ row }">{{ row.qualified_count }}/{{ row.items.length }} 合格</template>
          </el-table-column>
          <el-table-column type="expand" width="40">
            <template slot-scope="{ row }">
              <el-table :data="row.items" size="mini" border>
                <el-table-column prop="item_name" label="检验项目" width="150"></el-table-column>
                <el-table-column prop="standard_value" label="标准值" width="160"></el-table-column>
                <el-table-column prop="measured_value" label="实测值" width="120"></el-table-column>
                <el-table-column prop="unit" label="单位" width="70"></el-table-column>
                <el-table-column label="判定" width="90">
                  <template slot-scope="{ row: it }">
                    <el-tag :type="it.is_qualified === 1 ? 'success' : 'danger'" size="mini">
                      {{ it.is_qualified === 1 ? '合格' : '不合格' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="remark" label="备注"></el-table-column>
              </el-table>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-else description="该工单暂无质检记录"></el-empty>
      </el-card>

      <!-- 领料记录 -->
      <el-card class="box-card" shadow="never" style="margin-top: 14px">
        <div slot="header" class="card-header"><span><i class="el-icon-box"></i> 领料 / 批次记录（{{ trace.picks.length }}）</span></div>
        <el-table :data="trace.picks" size="small" border v-if="trace.picks.length">
          <el-table-column prop="pick_no" label="领料单号" width="160"></el-table-column>
          <el-table-column prop="type_text" label="类型" width="100"></el-table-column>
          <el-table-column prop="picker_name" label="领料人" width="100"></el-table-column>
          <el-table-column prop="pick_date" label="领料日期" width="120"></el-table-column>
          <el-table-column prop="material_count" label="物料种数" width="90"></el-table-column>
          <el-table-column prop="total_quantity" label="总数量" width="90"></el-table-column>
          <el-table-column prop="status_text" label="状态" width="90"></el-table-column>
          <el-table-column type="expand" width="40">
            <template slot-scope="{ row }">
              <el-table :data="row.items" size="mini" border>
                <el-table-column prop="material_code" label="物料编码" width="120"></el-table-column>
                <el-table-column prop="material_name" label="物料名称" min-width="140"></el-table-column>
                <el-table-column prop="spec" label="规格" width="110"></el-table-column>
                <el-table-column prop="actual_quantity" label="数量" width="80"></el-table-column>
                <el-table-column prop="unit" label="单位" width="60"></el-table-column>
                <el-table-column label="关联批次" min-width="160">
                  <template slot-scope="{ row: it }">
                    <template v-if="it.batches && it.batches.length">
                      <el-tag v-for="b in it.batches" :key="b.id" size="mini" style="margin-right: 4px">{{ b.batch_no }}</el-tag>
                    </template>
                    <span v-else style="color: #999">—</span>
                  </template>
                </el-table-column>
              </el-table>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-else description="该工单暂无领料记录"></el-empty>
      </el-card>

      <!-- 批次记录 -->
      <el-card class="box-card" shadow="never" style="margin-top: 14px" v-if="trace.batches.length">
        <div slot="header" class="card-header"><span><i class="el-icon-collection-tag"></i> 批次记录（{{ trace.batches.length }}）</span></div>
        <el-table :data="trace.batches" size="small" border>
          <el-table-column prop="batch_no" label="批次号" width="160"></el-table-column>
          <el-table-column prop="item_name" label="物料/产品" min-width="140"></el-table-column>
          <el-table-column prop="quantity" label="数量" width="100"></el-table-column>
          <el-table-column prop="unit" label="单位" width="70"></el-table-column>
          <el-table-column prop="source" label="来源" width="100"></el-table-column>
          <el-table-column prop="source_no" label="来源单号" width="170"></el-table-column>
          <el-table-column prop="prod_date" label="生产日期" width="120"></el-table-column>
          <el-table-column prop="location" label="库位" width="100"></el-table-column>
          <el-table-column prop="status_text" label="状态" width="90"></el-table-column>
        </el-table>
      </el-card>
    </template>
  </div>
</template>

<script>
import request from '@/api/request'

export default {
  name: 'QualityTrace',
  data() {
    return {
      keyword: '',
      searched: false,
      searchList: [],
      current: null,
      trace: null
    }
  },
  computed: {
    s() {
      return this.trace ? this.trace.summary : {}
    }
  },
  methods: {
    doSearch() {
      const kw = this.keyword.trim()
      if (!kw) {
        this.$message.warning('请输入工单号或产品名称')
        return
      }
      request.get('/production/quality/trace/search', { params: { keyword: kw } }).then(res => {
        this.searchList = res.data.list || []
        this.searched = true
        if (this.searchList.length === 1) {
          this.loadTrace(this.searchList[0].id)
        }
      })
    },
    selectOrder(row) {
      this.current = row
    },
    loadTrace(id) {
      request.get('/production/quality/trace/' + id).then(res => {
        this.trace = res.data
        this.current = this.searchList.find(o => o.id === id) || this.current
        this.$message.success('追溯加载完成')
      }).catch(() => {
        this.$message.error('追溯加载失败')
      })
    },
    doExport() {
      if (!this.trace || !this.trace.order) return
      window.open('/api/production/quality/trace/export/' + this.trace.order.id, '_blank')
    }
  }
}
</script>

<style scoped>
.trace-page {
  padding: 4px;
}
.search-row {
  display: flex;
  align-items: center;
  gap: 10px;
}
.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-weight: 600;
}
.stat-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}
.stat-card {
  flex: 1 1 120px;
  min-width: 100px;
  text-align: center;
  padding: 12px 8px;
  border-radius: 10px;
  background: linear-gradient(135deg, rgba(139, 200, 234, 0.12), rgba(139, 200, 234, 0.28));
}
.stat-card.ok {
  background: linear-gradient(135deg, rgba(82, 196, 26, 0.1), rgba(82, 196, 26, 0.22));
}
.stat-card.bad {
  background: linear-gradient(135deg, rgba(234, 102, 104, 0.1), rgba(234, 102, 104, 0.22));
}
.stat-num {
  font-size: 22px;
  font-weight: 700;
  color: #1a1b1c;
}
.stat-label {
  font-size: 12px;
  color: #6b7280;
  margin-top: 2px;
}
.tl-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  font-size: 13px;
}
.tl-tag {
  background: #8bc8ea;
  color: #fff;
  border-radius: 4px;
  padding: 1px 8px;
  font-size: 12px;
}
.tl-sub {
  color: #6b7280;
}
</style>
