<template>
  <!-- 消息推送配置：公众号模板消息 + 小程序订阅消息 -->
  <div class="push-page">
    <el-card shadow="never" v-loading="loading">
      <div slot="header" class="card-header">
        <span>消息推送配置</span>
        <el-button type="primary" size="small" icon="el-icon-refresh" :loading="loading" @click="load">刷新</el-button>
      </div>

      <el-row :gutter="16">
        <!-- 公众号模板消息 -->
        <el-col :span="12">
          <el-card shadow="never" class="sub-card">
            <div slot="header">
              公众号模板消息
              <el-tag v-if="cfg.mp?.configured" type="success" size="mini" style="margin-left:8px">已就绪</el-tag>
              <el-tag v-else type="warning" size="mini" style="margin-left:8px">未完整配置</el-tag>
            </div>
            <el-descriptions :column="1" size="small" border>
              <el-descriptions-item label="服务号">
                <el-tag :type="cfg.mp?.enabled ? 'success' : 'danger'" size="mini">{{ cfg.mp?.enabled ? '已启用' : '未启用' }}</el-tag>
                <span v-if="cfg.mp?.app_id" style="margin-left:8px">{{ cfg.mp.app_id }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="模板消息ID">
                <el-input v-model="mpTemplateId" size="small" placeholder="微信公众平台 → 模板消息 获取模板ID" />
              </el-descriptions-item>
            </el-descriptions>
            <div class="mp-map">
              <div class="section-label">按业务场景模板（可选，优先于上方单模板）</div>
              <div v-for="(v, scene) in mpTemplateMap" :key="scene" class="mp-map-row">
                <span class="scene-name">{{ sceneLabel(scene) }}</span>
                <el-input v-model="mpTemplateMap[scene]" size="small" placeholder="模板ID" style="flex:1" />
                <span class="mp-fields">{{ fieldText(scene) }}</span>
              </div>
            </div>
            <div class="tip">模板消息要求用户已关注服务号，且 openid 为该服务号签发。模板需在微信公众平台「模板消息」选择后复制 ID。按业务场景配置后，对应业务自动用对应模板推送。</div>
          </el-card>
        </el-col>

        <!-- 小程序订阅消息 -->
        <el-col :span="12">
          <el-card shadow="never" class="sub-card">
            <div slot="header">
              小程序订阅消息
              <el-tag v-if="miniConfigured" type="success" size="mini" style="margin-left:8px">已配置</el-tag>
              <el-tag v-else type="warning" size="mini" style="margin-left:8px">未配置模板</el-tag>
            </div>
            <el-descriptions :column="1" size="small" border>
              <el-descriptions-item label="小程序AppID">{{ cfg.mini?.app_id || '未配置' }}</el-descriptions-item>
              <el-descriptions-item label="AppSecret">{{ cfg.mini?.secret_configured ? '已配置' : '未配置（基础服务→微信服务 填写）' }}</el-descriptions-item>
            </el-descriptions>
            <div class="sub-tpl-list">
              <div v-for="(v, scene) in subTemplates" :key="scene" class="sub-tpl-row">
                <span class="scene-name">{{ sceneName(scene) }}</span>
                <el-input v-model="subTemplates[scene]" size="small" placeholder="模板ID（微信公众平台订阅消息申请）" style="flex:1" />
              </div>
              <el-button size="mini" type="text" @click="addScene">+ 添加场景</el-button>
            </div>
            <div class="tip">订阅消息需用户在小程序内点击「订阅通知」授权（一次性订阅），授权后业务事件可推送。</div>
          </el-card>
        </el-col>
      </el-row>

      <!-- 保存 -->
      <div class="save-bar">
        <el-button type="primary" :loading="saving" @click="save">保存模板配置</el-button>
      </div>
    </el-card>

    <!-- 测试推送 -->
    <el-card shadow="never" class="test-card">
      <div slot="header">测试推送</div>
      <el-form :inline="true" size="small">
        <el-form-item label="测试用户">
          <el-select v-model="testUserId" filterable placeholder="选择有 openid 的用户" style="width:220px">
            <el-option v-for="u in cfg.users || []" :key="u.id" :label="(u.real_name || u.username) + '（' + userOpenid(u) + '）'" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="推送类型">
          <el-select v-model="testType" style="width:140px">
            <el-option label="公众号模板消息" value="mp" />
            <el-option label="小程序订阅消息" value="mini" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="testType === 'mp'" label="测试场景">
          <el-select v-model="testScene" style="width:140px">
            <el-option label="审批待办" value="approval" />
            <el-option label="假勤审批" value="leave" />
            <el-option label="报工" value="report" />
            <el-option label="维修工单" value="repair" />
            <el-option label="合同到期" value="contract" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="testing" @click="sendTest">发送测试</el-button>
        </el-form-item>
      </el-form>
      <div v-if="testResult" class="test-result" :class="testOk ? 'ok' : 'err'">{{ testResult }}</div>
    </el-card>
  </div>
</template>

<script>
// 消息推送配置：公众号模板消息 + 小程序订阅消息
import request from '@/api/request'

const SCENE_NAMES = { notice: '系统通知', approval: '审批待办', contract: '合同提醒', repair: '维修通知', safety: '安全预警', task: '任务提醒' }

export default {
  name: 'MpPushConfig',
  data() {
    return {
      loading: false,
      saving: false,
      testing: false,
      cfg: {},
      mpTemplateId: '',
      mpTemplateMap: { approval: '', leave: '', report: '', repair: '', contract: '', ship: '' },
      mpTemplateFields: {},
      subTemplates: {},
      testUserId: null,
      testType: 'mp',
      testScene: 'approval',
      testResult: '',
      testOk: false,
    }
  },
  computed: {
    miniConfigured() {
      const t = this.subTemplates || {}
      return Object.values(t).some(v => v && String(v).trim() !== '')
    },
  },
  created() { this.load() },
  methods: {
    async load() {
      this.loading = true
      try {
        const r = await request({ url: '/mp-push/config', method: 'get' })
        if (r.code === 0) {
          this.cfg = r.data || {}
          this.mpTemplateId = this.cfg.mp?.template_id || ''
          this.mpTemplateMap = Object.assign({ approval: '', leave: '', report: '', repair: '', contract: '', ship: '' }, this.cfg.mp?.template_map || {})
          this.mpTemplateFields = this.cfg.mp?.template_fields || {}
          this.subTemplates = Object.assign({ notice: '' }, this.cfg.mini?.templates || {})
        }
      } finally {
        this.loading = false
      }
    },
    addScene() {
      const next = 'scene' + (Object.keys(this.subTemplates).length + 1)
      this.$set(this.subTemplates, next, '')
    },
    sceneName(s) { return SCENE_NAMES[s] || s },
    sceneLabel(s) { return { approval: '审批待办', leave: '假勤审批', report: '报工', repair: '维修工单', contract: '合同到期', ship: '发货通知' }[s] || s },
    fieldText(scene) { const f = this.mpTemplateFields[scene] || {}; const keys = Object.keys(f); if (!keys.length) return ''; return keys.map(k => k + '=' + f[k]).join(', '); },
    userOpenid(u) {
      return (u && (u.wx_mp_openid || u.wechat_oa_openid || u.wx_mini_openid || '无openid')) || '无openid'
    },
    async save() {
      this.saving = true
      try {
        const r = await request({ url: '/mp-push/save-template', method: 'post', data: { mp_template_id: this.mpTemplateId, sub_templates: this.subTemplates, mp_template_map: this.mpTemplateMap } })
        this.$message.success(r.msg || '已保存')
        this.load()
      } finally {
        this.saving = false
      }
    },
    async sendTest() {
      if (!this.testUserId) { this.$message.warning('请选择测试用户'); return }
      this.testing = true
      this.testResult = ''
      try {
        const u = (this.cfg.users || []).find(x => x.id === this.testUserId)
        const openid = u && (this.testType === 'mini' ? u.wx_mini_openid : (u.wx_mp_openid || u.wechat_oa_openid))
        if (!openid) { this.$message.warning('该用户没有对应 openid'); return }
        const r = await request({ url: '/mp-push/send-test', method: 'post', data: { openid, type: this.testType, scene: this.testScene } })
        this.testOk = r.code === 0
        this.testResult = r.msg || (this.testOk ? '发送成功' : '发送失败')
      } catch (e) {
        this.testOk = false
        this.testResult = '发送失败：' + (e.message || '')
      } finally {
        this.testing = false
      }
    },
  },
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.sub-card { margin-bottom: 16px; }
.tip { color: #909399; font-size: 12px; line-height: 1.6; margin-top: 10px; }
.sub-tpl-list { margin-top: 12px; }
.mp-map { margin-top: 12px; }
.mp-map .section-label { font-size: 12px; color: #909399; margin-bottom: 6px; }
.mp-map-row { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.mp-fields { font-size: 11px; color: #909399; max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sub-tpl-row { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.scene-name { width: 80px; color: #606266; font-size: 13px; flex-shrink: 0; }
.save-bar { margin-top: 8px; }
.test-card { margin-top: 16px; }
.test-result { margin-top: 10px; font-size: 13px; }
.test-result.ok { color: #67C23A; }
.test-result.err { color: #F56C6C; }
</style>
