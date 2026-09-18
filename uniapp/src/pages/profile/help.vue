<template>
  <view class="help-page">
    <view class="help-search">
      <view class="help-search-inner">
        <text class="help-search-icon">🔍</text>
        <input class="help-search-input" v-model="keyword" placeholder="搜索问题，如：审批 / 打卡 / 密码" placeholder-class="help-search-ph" />
      </view>
    </view>

    <view v-if="keyword" class="help-result">
      <view class="help-group" v-for="g in filteredGroups" :key="g.name">
        <view class="help-group-name">{{ g.name }}</view>
        <view class="help-list">
          <view class="help-item" v-for="(q, i) in g.items" :key="q.q">
            <view class="help-question" @click="toggle(g.name + i)">
              <text class="help-q-text">{{ q.q }}</text>
              <text class="help-arrow" :class="{ open: activeKey === g.name + i }">▾</text>
            </view>
            <view v-if="activeKey === g.name + i" class="help-answer">
              <text class="help-a-text">{{ q.a }}</text>
            </view>
          </view>
        </view>
      </view>
      <view v-if="filteredGroups.length === 0" class="help-empty">未找到相关问题，可在「意见反馈」中向我们提问</view>
    </view>

    <view v-else>
      <view class="help-group" v-for="g in groups" :key="g.name">
        <view class="help-group-name">{{ g.name }}</view>
        <view class="help-list">
          <view class="help-item" v-for="(q, i) in g.items" :key="q.q">
            <view class="help-question" @click="toggle(g.name + i)">
              <text class="help-q-text">{{ q.q }}</text>
              <text class="help-arrow" :class="{ open: activeKey === g.name + i }">▾</text>
            </view>
            <view v-if="activeKey === g.name + i" class="help-answer">
              <text class="help-a-text">{{ q.a }}</text>
            </view>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'

const activeKey = ref('账号与登录0')
const keyword = ref('')

const groups = [
  {
    name: '账号与登录',
    items: [
      { q: '如何修改个人信息？', a: '在「我的」页面点击个人信息卡片，进入个人档案页面即可修改头像、姓名、工号等信息。' },
      { q: '忘记密码怎么办？', a: '在登录页点击「忘记密码」，通过绑定手机号接收验证码后即可重置密码。' },
      { q: '账号被锁定怎么办？', a: '连续输错密码会触发安全策略暂时锁定，请等待锁定时间结束后重试，或联系管理员解锁。' },
      { q: '如何管理登录设备？', a: '进入「我的 → 更多设置 → 登录设备管理」，可查看所有已登录设备，并可远程退出可疑设备。' },
      { q: '如何修改登录密码？', a: '在「我的 → 更多设置 → 修改密码」中，验证原密码后设置新密码，建议定期更换。' },
    ]
  },
  {
    name: '审批与考勤',
    items: [
      { q: '如何提交审批申请？', a: '在工作台点击「快捷审批」或对应业务入口（如请假、报销、领用），填写信息并提交后进入审批流程。' },
      { q: '如何查看审批进度？', a: '在「审批 → 我发起的」中可查看申请单的当前处理节点与历史流转记录。' },
      { q: '收到审批待办如何操作？', a: '在「审批 → 待办」中查看待办单据，可同意、驳回或转交；紧急单据建议尽快处理避免超时。' },
      { q: '如何打卡？', a: '在「考勤」页面按排班进行打卡；如无法打卡，可提交补卡申请。' },
      { q: '请假后如何查看记录？', a: '在「考勤 → 假勤申请」中查看历史申请及审批状态。' },
    ]
  },
  {
    name: '消息与通讯',
    items: [
      { q: '如何与同事聊天？', a: '在「通讯录」选择联系人进入聊天，支持发送文字、图片、视频、文件与表情。' },
      { q: '消息提醒如何设置？', a: '在「我的 → 更多设置 → 消息通知」中可分别控制任务、审批、公告、聊天等类型的提醒开关。' },
      { q: '如何清除聊天记录？', a: '在「我的 → 更多设置 → 清除聊天记录」可删除本机保存的聊天缓存（不影响服务器记录）。' },
      { q: '省流模式有什么用？', a: '开启后聊天图片需点击才加载，可节省移动流量；在「更多设置 → 省流模式」中开启。' },
    ]
  },
  {
    name: '功能与安全',
    items: [
      { q: '如何查看工资条？', a: '在「我的」页面点击「工资查询」菜单，选择对应月份即可查看。' },
      { q: '如何提交意见反馈？', a: '在「我的 → 更多设置 → 意见反馈」中填写类型、内容与截图，提交后我们会及时处理。' },
      { q: '字体大小怎么调整？', a: '在「我的 → 更多设置 → 字体大小」中选择标准、大或特大，聊天等阅读场景即时生效。' },
      { q: '如何联系管理员？', a: '可通过「意见反馈」提交问题，或在工作台联系系统管理员。' },
      { q: '清理缓存会影响数据吗？', a: '清除缓存会清理本地缓存并退出登录，不会删除服务器上的业务数据，重新登录即可恢复。' },
    ]
  },
]

const filteredGroups = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  if (!kw) return groups
  return groups
    .map(g => ({ name: g.name, items: g.items.filter(x => (x.q + x.a).toLowerCase().indexOf(kw) >= 0) }))
    .filter(g => g.items.length > 0)
})

function toggle(key) { activeKey.value = activeKey.value === key ? '' : key }
</script>

<style scoped>
.help-page { min-height: 100vh; background: #F5F6FA; padding-bottom: 30px; }
.help-search { padding: 12px 16px 4px; }
.help-search-inner { display: flex; align-items: center; gap: 8px; background: #fff; border-radius: 24px; padding: 10px 14px; box-shadow: 0 2px 10px rgba(79,70,229,0.05); }
.help-search-icon { font-size: 15px; }
.help-search-input { flex: 1; font-size: 14px; color: #303133; }
.help-search-ph { color: #C0C4CC; }
.help-group { margin: 12px 16px 0; }
.help-group-name { font-size: 13px; color: #909399; font-weight: 500; padding: 0 4px 8px; }
.help-list { background: #fff; border-radius: 20px; overflow: hidden; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); }
.help-item { border-bottom: 1px solid #F5F6FA; }
.help-item:last-child { border-bottom: none; }
.help-question { padding: 14px 16px; display: flex; align-items: center; justify-content: space-between; }
.help-q-text { font-size: 15px; color: #303133; flex: 1; }
.help-arrow { font-size: 14px; color: #C0C4CC; transition: transform 0.2s; }
.help-arrow.open { transform: rotate(180deg); }
.help-answer { padding: 0 16px 14px; }
.help-a-text { font-size: 13px; color: #909399; line-height: 1.7; }
.help-empty { text-align: center; color: #C0C4CC; font-size: 13px; padding: 40px 0; }
</style>
