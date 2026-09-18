<template>
  <el-dialog title="发送消息" :visible="visible" @update:visible="$emit('update:visible', $event)" width="720px" top="6vh" :close-on-click-modal="false" @open="onOpen" @closed="reset">
    <el-form ref="form" :model="form" label-width="100px" size="small" :rules="rules">
      <!-- 基本信息 -->
      <el-form-item label="消息标题" prop="title">
        <el-input v-model="form.title" placeholder="请输入消息标题" maxlength="200" />
      </el-form-item>
      <el-form-item label="消息类型" prop="msg_type">
        <el-select v-model="form.msg_type" placeholder="请选择消息类型" style="width:100%">
          <el-option v-for="(t, k) in TYPE_MAP" :key="k" :label="t.label" :value="Number(k)" />
        </el-select>
      </el-form-item>

      <!-- 接收人 -->
      <el-form-item label="接收方式" prop="target_type">
        <el-radio-group v-model="form.target_type">
          <el-radio label="all">全体人员</el-radio>
          <el-radio label="dept">按部门</el-radio>
          <el-radio label="role">按角色</el-radio>
          <el-radio label="user">按人员</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-form-item v-if="form.target_type === 'dept'" label="选择部门">
        <el-select v-model="deptIds" multiple collapse-tags filterable placeholder="请选择部门" style="width:100%">
          <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="form.target_type === 'role'" label="选择角色">
        <el-select v-model="roleIds" multiple collapse-tags filterable placeholder="请选择角色" style="width:100%">
          <el-option v-for="r in roleOptions" :key="r.id" :label="r.name" :value="r.id" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="form.target_type === 'user'" label="选择人员">
        <el-select v-model="userIds" multiple collapse-tags filterable placeholder="请选择接收人" style="width:100%">
          <el-option v-for="u in userOptions" :key="u.id" :label="(u.real_name || u.username)" :value="u.id" />
        </el-select>
      </el-form-item>

      <!-- 消息内容 -->
      <el-form-item label="消息内容" prop="content">
        <el-input v-model="form.content" type="textarea" :rows="6" placeholder="请输入消息内容（支持HTML富文本，如 <b>加粗</b>、<a href='...'>链接</a>）" />
      </el-form-item>
      <el-form-item label="跳转链接">
        <el-input v-model="form.link_url" placeholder="业务跳转链接（可选，如 /safety/hazard/detail?id=1）" />
      </el-form-item>

      <!-- 发送渠道 -->
      <el-form-item label="发送渠道">
        <div class="channel-box">
          <el-checkbox v-for="c in CHANNEL_LIST" :key="c.value" v-model="form.channels[c.value]" :disabled="c.value === 'inbox'">
            {{ c.label }}<span v-if="c.value === 'inbox'" style="color:#E6A23C;">（必选）</span>
          </el-checkbox>
        </div>
      </el-form-item>

      <!-- 发送方式 -->
      <el-form-item label="发送方式">
        <el-radio-group v-model="form.send_mode">
          <el-radio label="now">立即发送</el-radio>
          <el-radio label="timed">定时发送</el-radio>
        </el-radio-group>
        <el-date-picker v-if="form.send_mode === 'timed'" v-model="form.send_time" type="datetime" placeholder="选择发送时间" value-format="yyyy-MM-dd HH:mm:ss" style="margin-left:12px;width:200px;" />
        <div v-if="form.send_mode === 'timed'" class="timed-tip">提示：定时发送当前按立即发送处理（需扩展定时任务后生效）</div>
      </el-form-item>
    </el-form>

    <span slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="sending" @click="submit">发送</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { sendMessage } from '@/api/notification'
import request from '@/api/request'

const TYPE_MAP = {
  1: { label: '系统公告', color: '#909399' },
  2: { label: '任务指派', color: '#409EFF' },
  3: { label: '审批通知', color: '#E6A23C' },
  4: { label: '预警提醒', color: '#F56C6C' },
  5: { label: '培训通知', color: '#67C23A' },
  6: { label: '工单通知', color: '#8E44AD' }
}
const CHANNEL_LIST = [
  { value: 'inbox', label: '站内信' },
  { value: 'email', label: '邮件' },
  { value: 'sms', label: '短信' },
  { value: 'wechat', label: '微信' },
  { value: 'dingtalk', label: '钉钉' },
  { value: 'workwx', label: '企业微信' }
]

export default {
  name: 'NotificationSendDialog',
  props: { visible: { type: Boolean, default: false } },
  data () {
    return {
      TYPE_MAP, CHANNEL_LIST,
      sending: false,
      deptIds: [], roleIds: [], userIds: [],
      deptOptions: [], roleOptions: [], userOptions: [],
      form: {
        title: '', msg_type: '', target_type: 'all',
        content: '', link_url: '',
        channels: { inbox: true, email: false, sms: false, wechat: false, dingtalk: false, workwx: false },
        send_mode: 'now', send_time: ''
      },
      rules: {
        title: [{ required: true, message: '请输入消息标题', trigger: 'blur' }],
        msg_type: [{ required: true, message: '请选择消息类型', trigger: 'change' }],
        content: [{ required: true, message: '请输入消息内容', trigger: 'blur' }]
      }
    }
  },
  // 本组件由父级 v-if 控制挂载，首次创建时 visible 即为 true，
  // element-ui el-dialog 的 @open 事件只在 visible 由 false→true 变化时触发，初始 true 不会触发。
  // created 钩子必然执行，保证弹窗打开即加载部门/角色/人员数据；watch 覆盖常驻组件后续打开场景。
  created () {
    if (this.visible) this.onOpen()
  },
  watch: {
    visible (v) { if (v) this.onOpen() }
  },
  methods: {
    async onOpen () {
    // 加载部门/角色/人员选项（各数据源独立加载，任一失败不影响其他，避免“部门/角色/人员全空”）
    try {
      const d = await request({ url: '/organization/departments/tree', method: 'get' })
      this.deptOptions = this.flatten(d.data || [])
    } catch (e) { this.deptOptions = [] }
    try {
      const r = await request({ url: '/roles', method: 'get', params: { page: 1, limit: 100 } })
      this.roleOptions = (r.data && r.data.list) || r.data || []
    } catch (e) { this.roleOptions = [] }
    try {
      const u = await request({ url: '/users', method: 'get', params: { page: 1, limit: 500 } })
      this.userOptions = (u.data && u.data.list) || []
    } catch (e) { this.userOptions = [] }
  },
  reset () {
    this.form = { title: '', msg_type: '', target_type: 'all', content: '', link_url: '', channels: { inbox: true, email: false, sms: false, wechat: false, dingtalk: false, workwx: false }, send_mode: 'now', send_time: '' }
    this.deptIds = []; this.roleIds = []; this.userIds = []
    this.$refs.form && this.$refs.form.clearValidate()
  },
  flatten (nodes) {
    let r = []
    for (const n of nodes || []) { r.push({ id: n.id, name: n.name }); if (n.children) r = r.concat(this.flatten(n.children)) }
    return r
  },
  submit () {
    this.$refs.form.validate(async (ok) => {
      if (!ok) {
        this.$message.warning('请填写必填项：标题、消息类型、内容')
        return
      }
      let targetIds = []
      if (this.form.target_type === 'dept') targetIds = this.deptIds
      else if (this.form.target_type === 'role') targetIds = this.roleIds
      else if (this.form.target_type === 'user') targetIds = this.userIds
      if (this.form.target_type !== 'all' && !targetIds.length) {
        this.$message.warning('请选择接收对象')
        return
      }
      this.sending = true
      try {
        const d = {
          target_type: this.form.target_type,
          target_ids: targetIds,
          msg_type: this.form.msg_type,
          title: this.form.title,
          content: this.form.content,
          link_url: this.form.link_url,
          channels: Object.keys(this.form.channels).filter(k => this.form.channels[k]),
          send_time: this.form.send_mode === 'timed' && this.form.send_time ? this.form.send_time : ''
        }
        const r = await sendMessage(d)
        if (r.code === 0) {
          this.$message.success(r.msg || '发送成功')
          this.$emit('sent')
          this.$emit('update:visible', false)
        } else {
          this.$message.error(r.msg || '发送失败')
        }
      } catch (e) {
        this.$message.error((e && e.message) || '发送失败，请查看浏览器控制台')
      } finally { this.sending = false }
    })
  }
  }
}
</script>

<style scoped>
.channel-box { display: flex; flex-wrap: wrap; gap: 4px 16px; }
.timed-tip { font-size: 12px; color: #E6A23C; margin-top: 4px; }
</style>
