<template>
  <el-dialog title="培训管理" :visible.sync="dialogVisible" width="900px" append-to-body @open="loadDetail">
    <!-- ===== 线上培训：完成状态管理 ===== -->
    <template v-if="record.is_online === 1">
      <div class="stat-bar">
        <div class="stat-item"><span class="stat-num">{{ record.plan_count || 0 }}</span><span class="stat-label">计划人数</span></div>
        <div class="stat-item"><span class="stat-num green">{{ trainedCount }}</span><span class="stat-label">已完成</span></div>
        <div class="stat-item"><span class="stat-num orange">{{ untrainedCount }}</span><span class="stat-label">未完成</span></div>
        <div class="stat-item"><span class="stat-num blue">{{ trainedRate }}%</span><span class="stat-label">完成率</span></div>
      </div>
      <div class="attendee-bar">
        <span style="color:#909399">参训人员（{{ (attendees || []).length }} 人）— 线上培训通过观看课件完成</span>
      </div>
      <el-table :data="attendees" v-loading="loading" size="small" border stripe max-height="480">
        <el-table-column type="index" label="序号" width="55" />
        <el-table-column prop="user_name" label="姓名" min-width="100" />
        <el-table-column prop="department" label="部门" min-width="120">
          <template slot-scope="{ row }">{{ row.department || '-' }}</template>
        </el-table-column>
        <el-table-column prop="position" label="岗位" min-width="120">
          <template slot-scope="{ row }">{{ row.position || '-' }}</template>
        </el-table-column>
        <el-table-column label="学习进度" width="120" align="center">
          <template slot-scope="{ row }">
            <span>{{ row.watch_progress || 0 }}%</span>
          </template>
        </el-table-column>
        <el-table-column label="完成状态" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.is_trained === 1 ? 'success' : 'info'">{{ row.is_trained === 1 ? '已完成' : '未完成' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="complete_time" label="完成时间" width="160" align="center">
          <template slot-scope="{ row }">{{ row.complete_time || '-' }}</template>
        </el-table-column>
      </el-table>
    </template>

    <!-- ===== 线下培训：签到管理 ===== -->
    <template v-else>
      <!-- 顶部统计 -->
      <div class="stat-bar">
        <div class="stat-item"><span class="stat-num">{{ record.plan_count || 0 }}</span><span class="stat-label">计划人数</span></div>
        <div class="stat-item"><span class="stat-num green">{{ signedCount }}</span><span class="stat-label">已签到</span></div>
        <div class="stat-item"><span class="stat-num orange">{{ unsignedCount }}</span><span class="stat-label">未签到</span></div>
        <div class="stat-item"><span class="stat-num blue">{{ checkinRate }}%</span><span class="stat-label">签到率</span></div>
      </div>

      <!-- 签到地点 + 二维码 -->
      <div class="mid-row">
        <div class="mid-left">
          <div class="mid-title">签到地点</div>
          <div class="loc-info">
            <div><span class="lb">地点：</span>{{ record.checkin_location || '未设置' }}</div>
            <div><span class="lb">经纬度：</span>{{ record.checkin_lat != null ? record.checkin_lat + ', ' + record.checkin_lng : '未设置' }}</div>
            <div><span class="lb">签到范围：</span>{{ record.checkin_radius || 100 }} 米</div>
            <div><span class="lb">有效期：</span>{{ record.checkin_start_time || '-' }} 至 {{ record.checkin_end_time || '-' }}</div>
          </div>
          <el-button size="small" icon="el-icon-location-outline" @click="locationVisible = true">修改地点</el-button>
        </div>
        <div class="mid-right">
          <div class="mid-title">签到二维码</div>
          <img v-if="qrcodeUrl" :src="qrcodeUrl" class="qrcode-img" alt="签到二维码" />
          <div v-else class="qrcode-empty">点击生成二维码</div>
          <div class="qr-actions">
            <el-button size="small" type="primary" icon="el-icon-plus" @click="loadQrcode">生成二维码</el-button>
            <el-button v-if="qrcodeUrl" size="small" icon="el-icon-download" @click="downloadQrcode">下载</el-button>
          </div>
        </div>
      </div>

      <!-- 参训人员签到列表 -->
      <div class="attendee-bar">
        <span style="color:#909399">参训人员（{{ (attendees || []).length }} 人）</span>
        <div>
          <el-button size="small" type="primary" :disabled="!unsignedAttendees.length" @click="batchSign">批量签到</el-button>
          <el-button size="small" icon="el-icon-download" @click="doExport">导出签到表</el-button>
        </div>
      </div>
      <el-table :data="attendees" v-loading="loading" size="small" border stripe max-height="400">
        <el-table-column type="index" label="序号" width="55" />
        <el-table-column prop="user_name" label="姓名" min-width="80" />
        <el-table-column prop="department" label="部门" min-width="100">
          <template slot-scope="{ row }">{{ row.department || '-' }}</template>
        </el-table-column>
        <el-table-column prop="position" label="岗位" min-width="100">
          <template slot-scope="{ row }">{{ row.position || '-' }}</template>
        </el-table-column>
        <el-table-column label="签到状态" width="85" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.checkin_status === 'signed' ? 'success' : 'info'">{{ row.checkin_status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="checkin_time" label="签到时间" width="150" align="center">
          <template slot-scope="{ row }">{{ row.checkin_time || '-' }}</template>
        </el-table-column>
        <el-table-column prop="checkin_address" label="签到地点" min-width="120" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.checkin_address || (row.checkin_status === 'signed' ? '后台签到' : '-') }}</template>
        </el-table-column>
        <el-table-column label="偏差距离" width="90" align="center">
          <template slot-scope="{ row }">{{ row.checkin_deviation != null ? row.checkin_deviation + 'm' : '-' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="110" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="row.checkin_status === 'pending'" size="mini" type="text" style="color:#67C23A" @click="signOne(row)">签到</el-button>
            <el-button v-if="row.checkin_status === 'signed'" size="mini" type="text" style="color:#F56C6C" @click="undoSign(row)">取消签到</el-button>
          </template>
        </el-table-column>
      </el-table>
    </template>

    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">关闭</el-button>
    </div>

    <location-dialog :visible.sync="locationVisible" :record="record" @saved="loadDetail" />
  </el-dialog>
</template>

<script>
import { getRecordDetail, checkinRecord, batchCheckin, undoCheckinRecord, getCheckinQrcode, exportCheckin } from '@/api/safetyTrainingRecord'
import LocationDialog from './LocationDialog.vue'

export default {
  name: 'CheckinDialog',
  components: { LocationDialog },
  props: {
    visible: Boolean,
    recordId: { type: Number, default: 0 },
  },
  data() {
    return {
      dialogVisible: this.visible,
      loading: false,
      attendees: [],
      record: {},
      qrcodeUrl: '',
      locationVisible: false,
      pollTimer: null
    }
  },
  computed: {
    signedCount() { return (this.attendees || []).filter(a => a.checkin_status === 'signed').length },
    unsignedCount() { return (this.attendees || []).filter(a => a.checkin_status === 'pending').length },
    unsignedAttendees() { return (this.attendees || []).filter(a => a.checkin_status === 'pending') },
    checkinRate() {
      const total = (this.attendees || []).length
      return total ? Math.round(this.signedCount / total * 100) : 0
    },
    trainedCount() { return (this.attendees || []).filter(a => a.is_trained === 1).length },
    untrainedCount() { return (this.attendees || []).filter(a => a.is_trained !== 1).length },
    trainedRate() {
      const total = (this.attendees || []).length
      return total ? Math.round(this.trainedCount / total * 100) : 0
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val },
    dialogVisible(val) {
      this.$emit('update:visible', val)
      // 打开时启动轮询，员工扫码签到后实时更新
      if (val) this.startPoll()
      else this.stopPoll()
    },
  },
  beforeDestroy() { this.stopPoll() },
  methods: {
    startPoll() {
      this.stopPoll()
      this.pollTimer = setInterval(() => { this.loadDetail() }, 1000)
    },
    stopPoll() {
      if (this.pollTimer) { clearInterval(this.pollTimer); this.pollTimer = null }
    },
    async loadDetail() {
      if (!this.recordId) return
      this.loading = true
      try {
        const r = await getRecordDetail(this.recordId)
        if (r.code === 0) {
          this.record = r.data || {}
          this.attendees = (r.data.attendees || []).map(x => ({ ...x }))
        }
      } catch (e) {}
      this.loading = false
    },
    async loadQrcode() {
      try {
        const r = await getCheckinQrcode(this.recordId)
        if (r.code === 0 && r.data && r.data.url) this.qrcodeUrl = r.data.url
        else this.$message.error(r.msg || '二维码生成失败')
      } catch (e) {}
    },
    downloadQrcode() {
      if (this.qrcodeUrl) {
        const a = document.createElement('a')
        a.href = this.qrcodeUrl
        a.download = '签到二维码_' + this.record.record_code + '.png'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
      }
    },
    async signOne(row) {
      try {
        const r = await checkinRecord(this.recordId, row.user_id)
        if (r.code === 0) { this.$message.success('签到成功'); this.loadDetail() }
      } catch (e) {}
    },
    async undoSign(row) {
      this.$confirm(`确认取消「${row.user_name}」的签到？`, '取消签到', { type: 'warning' }).then(async () => {
        try {
          const r = await undoCheckinRecord(this.recordId, row.user_id)
          if (r.code === 0) { this.$message.success('已取消签到'); this.loadDetail() }
        } catch (e) {}
      }).catch(() => {})
    },
    async batchSign() {
      const ids = this.unsignedAttendees.map(a => a.user_id)
      this.$confirm(`确认对选中的 ${ids.length} 人批量签到？`, '批量签到', { type: 'warning' }).then(async () => {
        try {
          const r = await batchCheckin(this.recordId, ids)
          if (r.code === 0) { this.$message.success('批量签到成功'); this.loadDetail(); this.$emit('saved') }
        } catch (e) {}
      }).catch(() => {})
    },
    async doExport() {
      try {
        const r = await exportCheckin(this.recordId)
        if (r.code === 0 && r.data && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.stat-bar { display: flex; background: #f8f9fb; border-radius: 8px; padding: 14px; margin-bottom: 14px; }
.stat-item { flex: 1; text-align: center; }
.stat-num { display: block; font-size: 22px; font-weight: 700; color: #303133; }
.stat-num.green { color: #67C23A; }
.stat-num.orange { color: #E6A23C; }
.stat-num.blue { color: #409EFF; }
.stat-label { font-size: 12px; color: #909399; }
.mid-row { display: flex; gap: 16px; margin-bottom: 14px; }
.mid-left { flex: 1; border: 1px solid #ebeef5; border-radius: 8px; padding: 14px; }
.mid-right { flex: 1; border: 1px solid #ebeef5; border-radius: 8px; padding: 14px; text-align: center; }
.mid-title { font-weight: 600; margin-bottom: 10px; }
.loc-info { font-size: 13px; color: #606266; line-height: 2; margin-bottom: 10px; }
.loc-info .lb { color: #909399; }
.qrcode-img { width: 160px; height: 160px; }
.qrcode-empty { height: 120px; display: flex; align-items: center; justify-content: center; color: #c0c4cc; font-size: 13px; }
.qr-actions { margin-top: 10px; }
.attendee-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
</style>
