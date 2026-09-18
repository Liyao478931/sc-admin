<template>
  <!-- 系统健康检查页：PHP/MySQL/Redis/磁盘/内存/授权/更新/核心服务 -->
  <div class="health-page">
    <el-card shadow="never" v-loading="loading">
      <div slot="header" class="card-header">
        <span>系统健康检查</span>
        <el-button type="primary" size="small" icon="el-icon-refresh" :loading="loading" @click="load">刷新</el-button>
      </div>

      <!-- 概览 -->
      <div class="overview">
        <div class="ov-item"><div class="ov-num" :class="mysqlOk ? 'ok' : 'err'">●</div><div class="ov-label">MySQL</div></div>
        <div class="ov-item"><div class="ov-num" :class="redisOk ? 'ok' : 'err'">●</div><div class="ov-label">Redis</div></div>
        <div class="ov-item"><div class="ov-num" :class="cronOk ? 'ok' : 'err'">●</div><div class="ov-label">定时任务</div></div>
        <div class="ov-item"><div class="ov-num" :class="licenseOk ? 'ok' : 'err'">●</div><div class="ov-label">授权</div></div>
      </div>

      <el-row :gutter="16">
        <!-- 环境 -->
        <el-col :span="12">
          <el-card shadow="never" class="sub-card">
            <div slot="header">运行环境</div>
            <el-descriptions :column="1" size="small" border>
              <el-descriptions-item label="PHP 版本">{{ h.php?.version || '-' }}</el-descriptions-item>
              <el-descriptions-item label="memory_limit">{{ h.php?.memory_limit || '-' }}</el-descriptions-item>
              <el-descriptions-item label="max_execution_time">{{ h.php?.max_execution_time || '-' }}</el-descriptions-item>
            </el-descriptions>
            <div class="ext-list">
              <el-tag v-for="e in h.php?.extensions || []" :key="e.name" size="mini" :type="e.ok ? 'success' : 'danger'" style="margin:3px">{{ e.name }}</el-tag>
            </div>
          </el-card>

          <el-card shadow="never" class="sub-card">
            <div slot="header">授权状态</div>
            <el-descriptions :column="1" size="small" border>
              <el-descriptions-item label="状态">
                <el-tag :type="h.license?.valid ? 'success' : 'danger'" size="mini">{{ h.license?.status || '-' }}</el-tag>
                <span v-if="h.license?.project" style="margin-left:8px">{{ h.license.project }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="授权校验">{{ h.license?.check_enabled ? '已开启' : '未开启' }}</el-descriptions-item>
            </el-descriptions>
          </el-card>

          <el-card shadow="never" class="sub-card">
            <div slot="header">软件更新</div>
            <el-descriptions :column="1" size="small" border>
              <el-descriptions-item label="当前版本">v{{ h.update?.current_version || '-' }}</el-descriptions-item>
              <el-descriptions-item label="更新状态">
                <el-tag v-if="h.update?.has_update" type="warning" size="mini">有新版 v{{ h.update.new_version }}</el-tag>
                <el-tag v-else type="success" size="mini">已是最新</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="检查时间">{{ h.update?.checked_at || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-card>
        </el-col>

        <el-col :span="12">
          <el-card shadow="never" class="sub-card">
            <div slot="header">存储与资源</div>
            <el-descriptions :column="1" size="small" border>
              <el-descriptions-item label="MySQL">
                <el-tag :type="mysqlOk ? 'success' : 'danger'" size="mini">{{ mysqlOk ? (h.mysql?.version || '正常') : '异常' }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="Redis">
                <el-tag :type="redisOk ? 'success' : 'danger'" size="mini">{{ redisOk ? '正常' : '异常' }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="磁盘">
                <el-progress :percentage="h.disk?.percent || 0" :color="diskColor" :stroke-width="10" />
                <span class="meta">{{ h.disk?.free }} 可用 / {{ h.disk?.total }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="内存">
                <el-progress :percentage="h.memory?.percent || 0" :color="memColor" :stroke-width="10" />
                <span class="meta">{{ h.memory?.free }} 可用 / {{ h.memory?.total }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="定时任务">
                <el-tag :type="cronOk ? 'success' : 'danger'" size="mini">{{ cronOk ? '已配置' : '缺失' }}</el-tag>
              </el-descriptions-item>
            </el-descriptions>
          </el-card>

          <el-card shadow="never" class="sub-card">
            <div slot="header">核心服务（存储/短信/邮件/微信）</div>
            <div v-for="(svc, id) in h.services || {}" :key="id" class="svc-row">
              <span class="svc-name">{{ svcName(id) }}</span>
              <el-tag :type="svc.health ? 'success' : svc.enabled ? 'danger' : 'info'" size="mini">{{ svc.health ? '正常' : (svc.enabled ? '异常' : '未启用') }}</el-tag>
              <span class="svc-msg">{{ svc.message || '' }}</span>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script>
// 系统健康检查
import request from '@/api/request'

export default {
  name: 'SystemHealth',
  data() {
    return { loading: false, h: {} }
  },
  computed: {
    mysqlOk() { return !!(this.h.mysql && this.h.mysql.ok) },
    redisOk() { return !!(this.h.redis && this.h.redis.ok) },
    cronOk() { return !!(this.h.crontab && this.h.crontab.ok) },
    licenseOk() { return !!(this.h.license && this.h.license.valid) },
    diskColor() { const p = this.h.disk?.percent || 0; return p >= 90 ? '#F56C6C' : p >= 70 ? '#E6A23C' : '#67C23A' },
    memColor() { const p = this.h.memory?.percent || 0; return p >= 90 ? '#F56C6C' : p >= 70 ? '#E6A23C' : '#67C23A' },
  },
  created() { this.load() },
  methods: {
    async load() {
      this.loading = true
      try {
        const r = await request({ url: '/system/health', method: 'get' })
        if (r.code === 0) this.h = r.data || {}
      } finally {
        this.loading = false
      }
    },
    svcName(id) {
      return { storage: '存储', sms: '短信', email: '邮件', wechat: '微信' }[id] || id
    },
  },
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.overview { display: flex; gap: 24px; padding: 8px 0 16px; }
.ov-item { text-align: center; }
.ov-num { font-size: 22px; }
.ov-num.ok { color: #67C23A; }
.ov-num.err { color: #F56C6C; }
.ov-label { color: #909399; font-size: 12px; }
.sub-card { margin-bottom: 16px; }
.ext-list { margin-top: 8px; }
.meta { color: #909399; font-size: 12px; margin-left: 8px; }
.svc-row { display: flex; align-items: center; gap: 10px; padding: 6px 0; border-bottom: 1px dashed #EBEEF5; }
.svc-row:last-child { border-bottom: none; }
.svc-name { width: 48px; color: #606266; font-size: 13px; }
.svc-msg { color: #909399; font-size: 12px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
</style>
