<template>
  <view class="biz-comp" :style="containerStyle">
    <view class="biz-head">
      <text class="biz-title">{{ cfg.titleConfig?.val || '数据列表' }}</text>
      <text v-if="total > 0" class="biz-count">共{{ total }}条</text>
    </view>
    <view v-if="loading" class="biz-loading"><text>加载中...</text></view>
    <u-empty v-else-if="!list.length" mode="list" text="暂无数据" :margin-top="20" />
    <view v-else class="biz-list">
      <view v-for="(it, i) in list" :key="i" class="biz-item" @click="onClick">
        <view class="biz-item-main">
          <text class="biz-item-name">{{ displayName(it) }}</text>
          <text v-if="displayCode(it)" class="biz-item-sub">{{ displayCode(it) }}</text>
        </view>
        <view class="biz-item-extra">
          <text v-if="displayStatus(it)" class="biz-item-tag" :style="tagStyle(it)">{{ displayStatus(it) }}</text>
          <u-icon name="arrow-right" size="14" color="#c0c4cc"></u-icon>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
// DIY 业务数据列表组件（数据驱动，按 api-url 调用业务接口渲染；点击跳转由组件配置 linkConfig 控制）
import { ref, computed, onMounted } from 'vue'
import { get } from '@/utils/request'

const props = defineProps({
  item: { type: Object, default: () => ({}) },
  apiUrl: { type: String, default: '' }
})

const cfg = computed(() => props.item || {})
const list = ref([])
const total = ref(0)
const loading = ref(true)

onMounted(async () => {
  try {
    const res = await get(props.apiUrl, { page: 1, limit: cfg.value.limitConfig?.val || 5 })
    if (res.code === 0) {
      list.value = res.data?.list || []
      total.value = res.data?.total || 0
    }
  } catch (e) {
    console.error('业务组件加载失败', props.apiUrl, e)
  }
  loading.value = false
})

function displayName(it) {
  return it.name || it.device_name || it.title || it.material_name || it.product_name || it.order_no || it.hazard_title || it.hazard_name || '—'
}
function displayCode(it) {
  return it.code || it.device_code || it.material_code || it.order_code || it.hazard_code || it.no || ''
}
function displayStatus(it) {
  if (it.status_text) return it.status_text
  if (it.alert_type) return it.alert_type === 'min' ? '库存不足' : it.alert_type === 'max' ? '超储' : it.alert_type
  const s = it.status
  if (s === undefined || s === null || s === '') return ''
  if (typeof s === 'number') return ['待处理', '处理中', '已完成'][s] || '状态' + s
  return String(s)
}
function tagStyle(it) {
  const t = displayStatus(it) || ''
  let color = '#909399'
  if (/不足|超储|高|紧急|待处理|待维修|故障|严重/.test(t)) color = '#e64340'
  else if (/中|进行|一般/.test(t)) color = '#f59a23'
  else if (/完成|正常|已|运行|低/.test(t)) color = '#07c160'
  return { color, background: color + '1a', borderColor: color }
}
function onClick() {
  const link = cfg.value.linkConfig?.val
  if (!link) return
  if (link.startsWith('/pages')) {
    uni.navigateTo({
      url: link,
      fail: () => {
        // #ifdef H5
        if (window.location.hash !== '#/' + link.slice(1)) window.location.hash = '#/' + link.slice(1)
        // #endif
      }
    })
  } else if (link.startsWith('http')) {
    // #ifdef H5
    window.open ? window.open(link) : (location.href = link)
    // #endif
  }
}
const containerStyle = computed(() => {
  const c = cfg.value
  const s = {}
  if (c.mbConfig?.val) s.marginTop = c.mbConfig.val + 'px'
  if (c.topConfig?.val) s.paddingTop = c.topConfig.val + 'px'
  if (c.bottomConfig?.val) s.paddingBottom = c.bottomConfig.val + 'px'
  if (c.prConfig?.val) { s.paddingLeft = c.prConfig.val + 'px'; s.paddingRight = c.prConfig.val + 'px' }
  if (c.fillet?.val) s.borderRadius = c.fillet.val + 'px'
  if (c.bgColor?.color?.[0]?.item) s.background = c.bgColor.color[0].item
  return s
})
</script>

<style scoped>
.biz-comp { background: #fff; }
.biz-head { display: flex; align-items: center; justify-content: space-between; padding: 14px 16px 4px; }
.biz-title { font-size: 16px; font-weight: 600; color: #303133; }
.biz-count { font-size: 12px; color: #909399; }
.biz-loading { display: flex; justify-content: center; align-items: center; padding: 30px 0; color: #999; font-size: 13px; }
.biz-list { padding: 4px 0 8px; }
.biz-item { display: flex; align-items: center; padding: 12px 16px; border-bottom: 1px solid #f5f6fa; }
.biz-item:last-child { border-bottom: none; }
.biz-item-main { flex: 1; min-width: 0; }
.biz-item-name { display: block; font-size: 15px; color: #303133; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.biz-item-sub { display: block; margin-top: 2px; font-size: 12px; color: #909399; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.biz-item-extra { display: flex; align-items: center; gap: 8px; margin-left: 10px; flex-shrink: 0; }
.biz-item-tag { font-size: 11px; padding: 2px 8px; border-radius:22px; border: 1px solid; }
</style>
