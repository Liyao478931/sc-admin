<template>
  <div class="diy-link-picker">
    <el-input :value="value" size="small" placeholder="点击右侧图标选择链接">
      <i slot="suffix" class="el-icon-link diy-link-icon" @click="openPicker"></i>
    </el-input>
    <el-dialog title="选择链接" :visible.sync="visible" width="480px" append-to-body>
      <div class="diy-link-list">
        <div class="diy-link-group-title">路径管理中的链接</div>
        <div class="diy-link-item" v-for="(p, i) in pageLinks" :key="i" @click="select(p)">
          <span class="diy-link-name">{{ p.label }}</span>
          <span class="diy-link-path">{{ p.value }}</span>
        </div>
        <div v-if="!pageLinks.length && !loading" class="diy-link-empty">暂无可用链接</div>
        <div class="diy-link-group-title">自定义链接</div>
        <div class="diy-link-custom">
          <el-input v-model="customUrl" size="small" placeholder="输入完整链接，如 /pages/xxx 或 https://..." />
          <el-button size="small" type="primary" @click="selectCustom">确定</el-button>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
// 链接选择器：从路径管理表（app_paths）动态加载全部已配置链接
import { getPathOptions } from '@/api/diy'

export default {
  name: 'DiyLinkPicker',
  props: {
    value: { type: String, default: '' }
  },
  data() {
    return {
      visible: false,
      customUrl: '',
      pageLinks: [],
      loading: false,
    }
  },
  methods: {
    openPicker() {
      this.customUrl = this.value || ''
      this.visible = true
      this.loadLinks()
    },
    async loadLinks() {
      this.loading = true
      try {
        const r = await getPathOptions()
        if (r.code === 0) this.pageLinks = r.data || []
      } catch (e) {
        this.pageLinks = []
      }
      this.loading = false
    },
    select(p) {
      this.$emit('input', p.value)
      this.visible = false
    },
    selectCustom() {
      const url = (this.customUrl || '').trim()
      if (!url) return
      this.$emit('input', url)
      this.visible = false
    }
  }
}
</script>

<style scoped>
.diy-link-icon { cursor: pointer; color: #409EFF; font-size: 16px; }
.diy-link-list { max-height: 420px; overflow-y: auto; }
.diy-link-group-title { font-size: 13px; color: #909399; padding: 8px 0 4px; }
.diy-link-item { display: flex; justify-content: space-between; align-items: center; padding: 8px 10px; cursor: pointer; border-radius: 4px; }
.diy-link-item:hover { background: #f0f4ff; }
.diy-link-name { font-size: 13px; color: #303133; }
.diy-link-path { font-size: 12px; color: #909399; }
.diy-link-empty { padding: 20px; text-align: center; color: #C0C4CC; font-size: 13px; }
.diy-link-custom { display: flex; gap: 8px; padding: 8px 0; }
</style>
