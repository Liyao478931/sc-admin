<!-- 文件：admin/src/views/ai/voice/commands.vue（v1.68.0 快捷指令中心） -->
<template>
  <div class="vc-page">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>自然语言交互</span><i class="el-icon-arrow-right"></i><span class="cur">快捷指令中心</span></div>

    <div class="toolbar">
      <el-input v-model="keyword" size="small" placeholder="搜索指令..." clearable style="width:240px" @keyup.enter.native="search" />
      <el-button size="small" icon="el-icon-search" @click="search">搜索</el-button>
      <el-button size="small" type="primary" icon="el-icon-plus" @click="$router.push('/ai/voice/templates')">新建指令</el-button>
    </div>

    <div class="cat-cards">
      <div v-for="(c, k) in categories" :key="k" class="cat-card">
        <div class="c-icon">{{ c.icon }}</div>
        <div class="c-name">{{ c.name }}</div>
        <div class="c-count">{{ c.count }} 个指令</div>
      </div>
    </div>

    <div class="panel">
      <div class="panel-head">热门指令</div>
      <div v-for="(p, i) in popular" :key="p.id" class="pop-row" @click="tryCommand(p)">
        <span class="p-icon">🗣️</span>
        <span class="p-pattern">「{{ p.trigger_pattern }}」</span>
        <span class="p-action">{{ p.intent_text }}</span>
        <span class="p-count">⭐ {{ p.use_count }} 次</span>
        <el-button size="mini" type="text" @click.stop="tryCommand(p)">试一下</el-button>
      </div>
      <el-empty v-if="!popular.length" description="暂无热门指令" :image-size="50" />
    </div>
  </div>
</template>

<script>
import { getVoicePopular, executeVoice } from '@/api/aiVoice'

export default {
  name: 'AiVoiceCommands',
  data () {
    return { keyword: '', popular: [], all: [], categories: { query: { name: '查询类', icon: '📊', count: 0 }, navigate: { name: '导航类', icon: '🧭', count: 0 }, operate: { name: '操作类', icon: '⚡', count: 0 }, analyze: { name: '分析类', icon: '📈', count: 0 } } }
  },
  mounted () { this.load() },
  methods: {
    async load () {
      try {
        const r = await getVoicePopular()
        if (r.code === 0) { this.all = r.data.list || []; this.popular = this.all; this.countCats() }
      } catch (e) {}
    },
    countCats () {
      const c = { query: 0, navigate: 0, operate: 0, analyze: 0 }
      this.all.forEach(x => { if (c[x.intent_type] !== undefined) c[x.intent_type]++ })
      Object.keys(c).forEach(k => { this.categories[k].count = c[k] })
    },
    search () {
      this.popular = this.all.filter(x => !this.keyword || x.trigger_pattern.includes(this.keyword))
    },
    async tryCommand (p) {
      const input = p.trigger_pattern.replace(/\{[a-z_]+\}/g, '示例')
      try {
        const r = await executeVoice(input)
        if (r.code === 0) {
          if (r.data.action === 'navigate' && r.data.page) this.$router.push(r.data.page)
          else this.$message.success(r.data.reply || '指令已执行')
        }
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.toolbar { display: flex; align-items: center; gap: 8px; padding: 12px 16px; }
.cat-cards { display: flex; gap: 14px; padding: 0 16px 14px; }
.cat-card { flex: 1; background: #fff; border: 1px solid #ebeef5; border-radius: 8px; padding: 14px; text-align: center; }
.c-icon { font-size: 24px; }
.c-name { font-weight: 600; margin: 6px 0 2px; }
.c-count { font-size: 12px; color: #909399; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; margin: 0 16px 16px; padding: 12px 16px; }
.panel-head { font-weight: 600; margin-bottom: 8px; }
.pop-row { display: flex; align-items: center; gap: 10px; padding: 8px 0; border-bottom: 1px dashed #ebeef5; font-size: 13px; cursor: pointer; }
.pop-row:hover { background: #f5f7fa; }
.p-pattern { flex: 1; }
.p-action { color: #409eff; width: 70px; }
.p-count { color: #e6a23c; width: 90px; }
</style>
