<!--
  文件：admin/src/views/production/plan/schedule/Index.vue
  功能：生产排程甘特图（筛选/统计卡片/ECharts 甘特图拖拽调整/自动排程/确认/导出/待排程区）
  权限：production:schedule:view / edit / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产计划</el-breadcrumb-item>
      <el-breadcrumb-item>生产排程</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 筛选与操作栏 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="70px" @submit.native.prevent>
        <el-form-item label="时间范围">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" @change="loadData" />
        </el-form-item>
        <el-form-item label="视图">
          <el-radio-group v-model="query.view" size="small" @change="renderCharts">
            <el-radio-button label="day">日视图</el-radio-button>
            <el-radio-button label="week">周视图</el-radio-button>
            <el-radio-button label="month">月视图</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="工位">
          <el-select v-model="query.workstation_id" clearable filterable placeholder="全部工位" style="width:140px" @change="loadData">
            <el-option v-for="w in wsOptions" :key="w.id" :label="w.workstation_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="工单编号">
          <el-input v-model="query.order_no" placeholder="请输入工单编号" clearable style="width:150px" @keyup.enter.native="loadData" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px" @change="loadData">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button v-permission="'production:schedule:edit'" type="primary" size="small" :loading="autoLoading" @click="handleAuto">自动排程</el-button>
          <el-button v-permission="'production:schedule:edit'" size="small" :loading="confirming" @click="handleConfirm">确认排程</el-button>
          <el-button v-permission="'production:schedule:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出排程</el-button>
          <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6"><div class="stat-card stat-orange" @click="quickFilter('pending')"><div class="stat-icon"><i class="el-icon-time" /></div><div class="stat-info"><div class="stat-num" style="color:#E6A23C">{{ stats.pending }}</div><div class="stat-label">待排程任务（点击查看）</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card stat-blue" @click="quickFilter('scheduled')"><div class="stat-icon"><i class="el-icon-document" /></div><div class="stat-info"><div class="stat-num" style="color:#409EFF">{{ stats.scheduled }}</div><div class="stat-label">已排程任务（点击查看）</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card stat-green" @click="quickFilter('running')"><div class="stat-icon"><i class="el-icon-loading" /></div><div class="stat-info"><div class="stat-num" style="color:#67C23A">{{ stats.running }}</div><div class="stat-label">进行中任务（点击查看）</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card stat-purple"><div class="stat-icon"><i class="el-icon-data-line" /></div><div class="stat-info"><div class="stat-num" style="color:#9B59B6">{{ Number(stats.utilization || 0).toFixed(1) }}%</div><div class="stat-label">工位利用率</div></div></div></el-col>
    </el-row>

    <!-- 甘特图主区域 -->
    <el-card class="gantt-card" shadow="never">
      <div ref="gantt" class="gantt-box" v-loading="loading" />
      <div class="gantt-tip">提示：拖动色块中部调整开始时间，拖动左右边缘调整时长；仅「已排程」状态可调整；冲突任务红色显示。时间轴可随上方视图切换（日/周/月）。</div>
    </el-card>

    <!-- 待排程任务区 -->
    <el-card class="pending-card" shadow="never">
      <div slot="header" class="pending-header"><span class="chart-title">待排程任务（{{ pending.length }}）</span><span class="pending-sub">已派工的工序任务尚未排程，点击「排程」快速安排</span></div>
      <el-table :data="pending" size="mini" border empty-text="暂无待排程任务">
        <el-table-column prop="order_no" label="工单编号" width="140" />
        <el-table-column prop="process_name" label="工序" min-width="110" show-overflow-tooltip />
        <el-table-column prop="workstation_name" label="派工工位" width="110" show-overflow-tooltip />
        <el-table-column label="计划工时" width="80" align="right"><template slot-scope="s">{{ Number(s.row.duration_hours) }}h</template></el-table-column>
        <el-table-column label="计划完成" width="100" align="center"><template slot-scope="s">{{ s.row.planned_end_date || '-' }}</template></el-table-column>
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="s"><el-button v-permission="'production:schedule:edit'" type="text" size="mini" @click="openPlace(s.row)">排程</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 自动排程结果摘要 -->
    <el-dialog title="自动排程结果" :visible.sync="autoVisible" width="560px" append-to-body>
      <div class="auto-summary">
        成功排程 <b class="c-blue">{{ autoResult.scheduled || 0 }}</b> 个任务；未排程 <b class="c-red">{{ (autoResult.failed || []).length }}</b> 个；工位利用率 <b class="c-purple">{{ Number(autoResult.utilization || 0).toFixed(1) }}%</b>
      </div>
      <el-table v-if="(autoResult.failed || []).length" :data="autoResult.failed" size="mini" border style="margin-top:10px">
        <el-table-column prop="order_no" label="工单编号" width="150" />
        <el-table-column prop="process_name" label="工序" min-width="120" />
        <el-table-column prop="reason" label="未排程原因" min-width="150" />
      </el-table>
      <div slot="footer"><el-button size="small" type="primary" @click="autoVisible = false; loadData()">知道了</el-button></div>
    </el-dialog>

    <!-- 待排程任务快速排程对话框 -->
    <el-dialog title="排程任务" :visible.sync="placeVisible" width="520px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="工序任务">
          <div class="audit-summary">{{ placeForm.order_no }} ｜ {{ placeForm.process_name }} ｜ 工时 {{ Number(placeForm.duration_hours) }}h</div>
        </el-form-item>
        <el-form-item label="指定工位">
          <el-select v-model="placeForm.workstation_id" filterable placeholder="请选择工位" style="width:100%" @change="onPlaceWs">
            <el-option v-for="w in wsOptions" :key="w.id" :label="w.workstation_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="指定设备">
          <el-select v-model="placeForm.device_id" filterable placeholder="选择该工位设备" style="width:100%" :disabled="!placeForm.workstation_id">
            <el-option v-for="d in placeDevices" :key="d.device_id" :label="`${d.device_name}（${d.device_code}）`" :value="d.device_id" />
          </el-select>
        </el-form-item>
        <el-form-item label="开始时间">
          <el-date-picker v-model="placeForm.start_time" type="datetime" value-format="yyyy-MM-dd HH:mm" placeholder="选择开始时间" style="width:100%" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="placeVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="placing" @click="confirmPlace">排程</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getScheduleData, saveSchedule, autoSchedule, confirmSchedule, checkScheduleConflict, exportSchedule, getDispatchDevices } from '@/api/production'

const BAR_HEIGHT = 22
const FMT = n => `${n.getFullYear()}-${String(n.getMonth() + 1).padStart(2, '0')}-${String(n.getDate()).padStart(2, '0')} ${String(n.getHours()).padStart(2, '0')}:${String(n.getMinutes()).padStart(2, '0')}`

export default {
  name: 'ProductionSchedule',
  data () {
    return {
      statusOptions: { 0: '未排程', 1: '已排程', 2: '执行中', 3: '已完成' },
      query: { dateRange: this.weekRange(), view: 'week', workstation_id: '', order_no: '', status: '' },
      rows: [], tasks: [], pending: [], wsOptions: [], stats: { pending: 0, scheduled: 0, running: 0, utilization: 0 },
      loading: false, autoLoading: false, confirming: false, exporting: false,
      chart: null, drag: null,
      autoVisible: false, autoResult: {},
      placeVisible: false, placeForm: {}, placeDevices: [], placing: false
    }
  },
  created () { this.loadData() },
  beforeDestroy () {
    if (this.chart) { this.chart.dispose(); this.chart = null }
    window.removeEventListener('resize', this.handleResize)
  },
  methods: {
    weekRange () {
      const d = new Date()
      const day = (d.getDay() + 6) % 7 // 周一=0
      const mon = new Date(d.getFullYear(), d.getMonth(), d.getDate() - day)
      const sun = new Date(mon.getFullYear(), mon.getMonth(), mon.getDate() + 6)
      const f = n => `${n.getFullYear()}-${String(n.getMonth() + 1).padStart(2, '0')}-${String(n.getDate()).padStart(2, '0')}`
      return [f(mon), f(sun)]
    },
    buildParams () {
      const p = { start_date: this.query.dateRange[0], end_date: this.query.dateRange[1] }
      if (this.query.workstation_id !== '' && this.query.workstation_id !== null) p.workstation_id = this.query.workstation_id
      if (this.query.order_no) p.order_no = this.query.order_no
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getScheduleData(this.buildParams())
        if (r.code === 0 && r.data) {
          this.rows = r.data.rows || []
          this.tasks = (r.data.tasks || []).map(t => ({
            ...t,
            startMs: new Date(t.planned_start_time).getTime(),
            endMs: new Date(t.planned_end_time).getTime()
          }))
          this.pending = r.data.pending || []
          this.stats = r.data.stats || { pending: 0, scheduled: 0, running: 0, utilization: 0 }
          this.wsOptions = r.data.rows || []
        }
      } catch (e) {} finally {
        this.loading = false
        this.$nextTick(() => this.renderCharts())
      }
    },
    timeRange () {
      const s = new Date(this.query.dateRange[0] + ' 00:00:00').getTime()
      const e = new Date(this.query.dateRange[1] + ' 23:59:59').getTime()
      if (this.query.view === 'day') return [s, s + 24 * 3600000]
      if (this.query.view === 'month') {
        const d = new Date(this.query.dateRange[0] + ' 00:00:00')
        const start = new Date(d.getFullYear(), d.getMonth(), 1).getTime()
        const end = new Date(d.getFullYear(), d.getMonth() + 1, 1).getTime()
        return [start, end]
      }
      return [s, e + 3600000]
    },
    initChart () {
      if (!this.chart && this.$refs.gantt) {
        this.chart = echarts.init(this.$refs.gantt)
        this.chart.getZr().on('mousedown', this.onZrDown)
        this.chart.getZr().on('mousemove', this.onZrMove)
        this.chart.getZr().on('mouseup', this.onZrUp)
        window.addEventListener('resize', this.handleResize)
      }
    },
    handleResize () { if (this.chart) this.chart.resize() },
    renderCharts () {
      this.initChart()
      if (!this.chart) return
      const [min, max] = this.timeRange()
      const wsNames = this.rows.map(w => w.workstation_name)
      const colorMap = { 0: '#909399', 1: '#409EFF', 2: '#E6A23C', 3: '#67C23A' }
      const self = this
      this.chart.setOption({
        grid: { left: 150, right: 20, top: 30, bottom: 40 },
        tooltip: {
          trigger: 'item',
          formatter (p) {
            const t = p.data && p.data.task
            if (!t) return ''
            const conflict = t.conflict ? ' <b style="color:#F56C6C">【冲突】</b>' : ''
            return `${t.work_order_no}${conflict}<br/>工序：${t.process_name}<br/>工位：${t.workstation_name}｜设备：${t.device_name || '-'}<br/>时间：${t.planned_start_time} ~ ${t.planned_end_time}<br/>工时：${Number(t.duration_hours)}h<br/>状态：${t.status_label}`
          }
        },
        xAxis: { type: 'time', min, max, axisLabel: { formatter: '{MM}-{dd} {HH}:{mm}' }, splitLine: { show: true, lineStyle: { color: '#f0f0f0' } } },
        yAxis: { type: 'category', data: wsNames, axisLabel: { width: 140, overflow: 'truncate' } },
        series: [{
          type: 'custom',
          renderItem (params, api) {
            const start = api.coord([api.value(0), api.value(1)])
            const end = api.coord([api.value(2), api.value(1)])
            const width = Math.max(2, end[0] - start[0])
            const y = start[1] - BAR_HEIGHT / 2
            const t = params.data.task
            const color = t.conflict ? '#F56C6C' : (colorMap[t.status] || '#909399')
            return {
              type: 'group',
              children: [
                { type: 'rect', shape: { x: start[0], y, width, height: BAR_HEIGHT }, style: { fill: color, stroke: t.conflict ? '#C0392B' : 'rgba(0,0,0,0.12)', lineWidth: t.conflict ? 2 : 1, opacity: 0.9 } },
                width > 70 ? { type: 'text', style: { text: `${t.process_name} ${t.work_order_no}`, x: start[0] + 5, y: y + 5, fill: '#fff', fontSize: 10, overflow: 'truncate', width: width - 10 } } : null
              ]
            }
          },
          data: self.tasks.map(t => ({ value: [t.startMs, t.workstation_name, t.endMs], task: t }))
        }]
      }, true)
    },
    timeAtX (x) {
      const v = this.chart.convertFromPixel({ xAxisIndex: 0 }, [x, 0])
      const ms = Array.isArray(v) ? v[0] : v
      return Math.round(ms / 1800000) * 1800000 // 30 分钟粒度
    },
    getTaskRect (t) {
      const s = this.chart.convertToPixel({ xAxisIndex: 0 }, t.startMs)
      const e = this.chart.convertToPixel({ xAxisIndex: 0 }, t.endMs)
      const y = this.chart.convertToPixel({ yAxisIndex: 0 }, t.workstation_name)
      return { x: s, y: y - BAR_HEIGHT / 2, width: e - s, height: BAR_HEIGHT }
    },
    onZrDown (e) {
      if (!this.chart) return
      const perms = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      if (!perms.includes('production:schedule:edit')) return
      const p = [e.offsetX, e.offsetY]
      for (let i = this.tasks.length - 1; i >= 0; i--) {
        const t = this.tasks[i]
        if (t.status !== 1) continue
        const r = this.getTaskRect(t)
        if (r.width < 10) continue
        if (p[0] >= r.x && p[0] <= r.x + r.width && p[1] >= r.y - 3 && p[1] <= r.y + r.height + 3) {
          const mode = p[0] <= r.x + 8 ? 'left' : (p[0] >= r.x + r.width - 8 ? 'right' : 'move')
          this.drag = { index: i, mode, downX: p[0], origStart: t.startMs, origEnd: t.endMs }
          return
        }
      }
    },
    onZrMove (e) {
      if (!this.drag) return
      const t = this.tasks[this.drag.index]
      const nx = this.timeAtX(e.offsetX)
      const down = this.timeAtX(this.drag.downX)
      if (this.drag.mode === 'left') {
        t.startMs = Math.min(nx, t.endMs - 1800000)
      } else if (this.drag.mode === 'right') {
        t.endMs = Math.max(nx, t.startMs + 1800000)
      } else {
        const delta = nx - down
        t.startMs = this.drag.origStart + delta
        t.endMs = this.drag.origEnd + delta
      }
      this.renderCharts()
    },
    async onZrUp (e) {
      if (!this.drag) return
      const t = this.tasks[this.drag.index]
      this.drag = null
      const startStr = FMT(new Date(t.startMs))
      const endStr = FMT(new Date(t.endMs))
      if (endStr <= startStr) { this.$message.warning('结束时间必须晚于开始时间'); this.loadData(); return }
      try {
        const r = await checkScheduleConflict({ id: t.id, work_order_id: t.work_order_id, process_id: t.process_id, workstation_id: t.workstation_id, planned_start_time: startStr, planned_end_time: endStr })
        if (r.code === 0 && r.data && r.data.has_conflict) {
          this.$message.error('排程冲突：' + (r.data.conflicts || []).join('；'))
          this.loadData(); return
        }
        const s = await saveSchedule({ id: t.id, dispatch_task_id: t.dispatch_task_id, workstation_id: t.workstation_id, device_id: t.device_id, planned_start_time: startStr, planned_end_time: endStr })
        if (s.code === 0) { this.$message.success('排程已更新'); this.loadData() } else { this.$message.error(s.msg || '保存失败'); this.loadData() }
      } catch (err) { this.loadData() }
    },
    quickFilter (type) {
      if (type === 'pending') { this.$message.info('待排程任务见下方列表'); return }
      if (type === 'scheduled') this.query.status = 1
      if (type === 'running') this.query.status = 2
      this.loadData()
    },
    async handleAuto () {
      this.autoLoading = true
      try {
        const r = await autoSchedule({ start_date: this.query.dateRange[0], end_date: this.query.dateRange[1] })
        if (r.code === 0) { this.autoResult = r.data || {}; this.autoVisible = true } else this.$message.error(r.msg || '自动排程失败')
      } catch (e) {} finally { this.autoLoading = false }
    },
    async handleConfirm () {
      this.$confirm('确认当前排程方案？将发送通知给相关工位和工人。', '确认排程', { type: 'warning' }).then(async () => {
        this.confirming = true
        try {
          const r = await confirmSchedule({ start_date: this.query.dateRange[0], end_date: this.query.dateRange[1] })
          if (r.code === 0) { this.$message.success(r.msg || '已确认排程') } else this.$message.error(r.msg || '操作失败')
        } catch (e) {} finally { this.confirming = false }
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.buildParams() }
        const r = await exportSchedule(params)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `生产排程_${this.query.dateRange[0]}_${this.query.dateRange[1]}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    },
    openPlace (row) {
      const d = new Date()
      d.setMinutes(Math.ceil(d.getMinutes() / 30) * 30, 0, 0)
      this.placeForm = {
        dispatch_task_id: row.dispatch_task_id, order_no: row.order_no, process_name: row.process_name,
        duration_hours: Number(row.duration_hours) || 1,
        workstation_id: row.workstation_id || null, device_id: row.device_id || null,
        start_time: FMT(d)
      }
      this.placeDevices = []
      this.placeVisible = true
      if (this.placeForm.workstation_id) this.onPlaceWs()
    },
    async onPlaceWs () {
      this.placeForm.device_id = null
      this.placeDevices = []
      if (!this.placeForm.workstation_id) return
      try {
        const r = await getDispatchDevices(this.placeForm.workstation_id)
        if (r.code === 0) this.placeDevices = r.data.list || []
      } catch (e) { this.placeDevices = [] }
    },
    async confirmPlace () {
      if (!this.placeForm.workstation_id) { this.$message.warning('请选择工位'); return }
      if (!this.placeForm.start_time) { this.$message.warning('请选择开始时间'); return }
      const dur = Number(this.placeForm.duration_hours) || 1
      const startMs = new Date(this.placeForm.start_time.replace(' ', 'T')).getTime()
      const endMs = startMs + dur * 3600000
      this.placing = true
      try {
        const r = await saveSchedule({
          dispatch_task_id: this.placeForm.dispatch_task_id,
          workstation_id: this.placeForm.workstation_id, device_id: this.placeForm.device_id || 0,
          planned_start_time: FMT(new Date(startMs)), planned_end_time: FMT(new Date(endMs))
        })
        if (r.code === 0) { this.$message.success('排程成功'); this.placeVisible = false; this.loadData() } else this.$message.error(r.msg || '排程失败')
      } catch (e) {} finally { this.placing = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.stat-row { margin-top: 16px; }
.stat-card { display: flex; align-items: center; padding: 14px 18px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: transform .2s; }
.stat-card:hover { transform: translateY(-3px); }
.stat-blue { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-orange { background: linear-gradient(135deg, #fdf6ec, #fae8cd); }
.stat-green { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-purple { background: linear-gradient(135deg, #f5ecfb, #ecd9f7); }
.stat-icon { font-size: 28px; margin-right: 12px; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-green .stat-icon { color: #67C23A; }
.stat-purple .stat-icon { color: #9B59B6; }
.stat-num { font-size: 20px; font-weight: bold; color: #303133; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.gantt-card { margin-top: 16px; border-radius: 8px; }
.gantt-box { width: 100%; height: 480px; }
.gantt-tip { font-size: 12px; color: #909399; margin-top: 8px; }
.pending-card { margin-top: 16px; border-radius: 8px; }
.pending-header { display: flex; justify-content: space-between; align-items: center; }
.pending-sub { font-size: 12px; color: #909399; }
.chart-title { font-weight: 600; }
.auto-summary { font-size: 14px; color: #606266; }
.c-blue { color: #409EFF; } .c-red { color: #F56C6C; } .c-purple { color: #9B59B6; }
.audit-summary { font-size: 13px; color: #606266; background: #f8f9fb; padding: 8px 12px; border-radius: 4px; }
</style>
