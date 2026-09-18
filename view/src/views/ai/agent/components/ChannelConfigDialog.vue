<template>
  <el-dialog title="渠道配置" :visible.sync="visible" width="520px" append-to-body>
    <el-form :model="form" label-width="100px" size="small">
      <el-form-item label="渠道类型">
        <el-input :value="channelLabel" disabled />
      </el-form-item>

      <!-- Web API -->
      <template v-if="channelType === 'webapi'">
        <el-form-item label="API Endpoint">
          <el-input :value="apiEndpoint" disabled placeholder="发布后自动生成" />
        </el-form-item>
        <el-form-item label="API 密钥">
          <el-input v-model="form.config.api_key" placeholder="调用 API 所需密钥" />
        </el-form-item>
      </template>

      <!-- 钉钉 -->
      <template v-else-if="channelType === 'dingtalk'">
        <el-form-item label="AppID"><el-input v-model="form.config.app_id" placeholder="钉钉应用 AppKey" /></el-form-item>
        <el-form-item label="AppSecret"><el-input v-model="form.config.app_secret" type="password" show-password placeholder="钉钉应用 AppSecret" /></el-form-item>
        <el-form-item label="Robot Code"><el-input v-model="form.config.robot_code" placeholder="钉钉机器人 Code" /></el-form-item>
      </template>

      <!-- 企业微信 -->
      <template v-else-if="channelType === 'workwx'">
        <el-form-item label="CorpId"><el-input v-model="form.config.corp_id" placeholder="企业微信 CorpId" /></el-form-item>
        <el-form-item label="AgentId"><el-input v-model="form.config.agent_id" placeholder="企业微信 AgentId" /></el-form-item>
        <el-form-item label="Secret"><el-input v-model="form.config.secret" type="password" show-password placeholder="企业微信 Secret" /></el-form-item>
      </template>

      <!-- 飞书 / 微信公众号 -->
      <template v-else-if="channelType === 'feishu' || channelType === 'wechat'">
        <el-form-item label="AppID"><el-input v-model="form.config.app_id" :placeholder="channelType === 'feishu' ? '飞书 AppID' : '公众号 AppID'" /></el-form-item>
        <el-form-item label="AppSecret"><el-input v-model="form.config.app_secret" type="password" show-password :placeholder="channelType === 'feishu' ? '飞书 AppSecret' : '公众号 AppSecret'" /></el-form-item>
      </template>

      <!-- Web 嵌入 -->
      <template v-else-if="channelType === 'webembed'">
        <el-form-item label="嵌入代码">
          <el-input :value="embedCode" type="textarea" :rows="4" disabled />
        </el-form-item>
      </template>

      <el-form-item label="启用">
        <el-switch v-model="form.enabled" active-text="启用" inactive-text="停用" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">保存</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { configPublishChannel } from '../../../../api/aiPublish'

export default {
  name: 'ChannelConfigDialog',
  props: {
    agentId: { type: String, default: '' }
  },
  data() {
    return {
      visible: false,
      saving: false,
      channelType: 'webapi',
      form: { config: {}, enabled: true }
    }
  },
  computed: {
    channelLabel() {
      return { webapi: 'Web API', dingtalk: '钉钉', workwx: '企业微信', feishu: '飞书', wechat: '微信公众号', webembed: 'Web嵌入' }[this.channelType] || this.channelType
    },
    apiEndpoint() {
      return window.location.origin + '/api/agent/chat?agent_id=' + this.agentId
    },
    embedCode() {
      return '<script src="' + window.location.origin + '/sdk/agent-widget.js" data-agent="' + this.agentId + '"><\/script>'
    }
  },
  methods: {
    open(ch) {
      this.channelType = ch.channel_type
      const cfg = (ch.config && Object.keys(ch.config).length) ? ch.config : {}
      this.form = { config: cfg, enabled: !!ch.enabled }
      this.visible = true
    },
    async submit() {
      this.saving = true
      try {
        const res = await configPublishChannel({
          agent_id: this.agentId,
          channel_type: this.channelType,
          config: this.form.config
        })
        this.$message.success(res.msg || '已保存')
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
