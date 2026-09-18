<template>
  <footer v-if="theme.footer_show" class="layout-footer" :class="{ 'is-fixed': !!theme.footer_fixed }" :style="{ height: theme.footer_height+'px', lineHeight: theme.footer_height+'px', backgroundColor: theme.footer_bg_color, color: theme.footer_text_color, fontSize: footerTextSize, borderTop: theme.footer_divider ? '1px solid '+theme.footer_divider_color : 'none', padding: '0 20px' }">
    <div class="footer-inner">
      <span class="footer-left">{{ theme.footer_left_content || theme.footer_copyright }}</span>
      <span class="footer-links">
        <a v-for="(link, idx) in footerLinks" :key="idx" :href="link.value" :title="link.value" target="_blank" rel="noopener noreferrer" class="footer-link" :style="{ color: theme.footer_link_color, '--link-hover': theme.footer_link_hover_color }">{{ link.label }}</a>
      </span>
      <span class="footer-right"></span>
    </div>
  </footer>
</template>
<script>
import themeMixin from '@/mixins/theme'
const FONT_SIZE_MAP = { small:'12px', default:'13px', large:'14px' }
export default {
  name: 'AppFooter',
  mixins: [themeMixin],
  data () {
    return {}
  },
  computed: {
    footerTextSize() { return FONT_SIZE_MAP[this.theme.footer_text_size] || '13px' },
    footerLinks() {
      const links = this.theme.footer_links
      return Array.isArray(links) ? links.filter(l => l.label && l.value) : []
    },
  },
}
</script>
<style scoped>
.layout-footer { flex-shrink: 0; margin-top: auto; }
/* 页脚始终在内容下方（文档流推底），不遮挡内容；is-fixed 时 z-index 低于固定操作栏 */
.layout-footer.is-fixed { z-index: 0; }
.footer-inner { display:flex; justify-content:space-between; align-items:center; height:100%; gap:12px; }
.footer-left { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.footer-links { display:flex; gap:12px; flex-shrink:0; }
.footer-link { text-decoration:none; transition:color .2s; white-space:nowrap; }
.footer-link:hover { color:var(--link-hover) !important; }
.footer-right { white-space:nowrap; flex-shrink:0; display:flex; align-items:center; gap:8px; }
</style>
