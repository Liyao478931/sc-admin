<template>
  <div v-if="theme.tabs_show" class="tags-view" :style="tagsStyle">
    <el-tabs v-model="activeTab" type="card" closable @tab-remove="removeTab" @tab-click="tabClick">
      <el-tab-pane v-for="tab in visitedTabs" :key="tab.path" :label="tab.title" :name="tab.path" />
    </el-tabs>
  </div>
</template>
<script>
import themeMixin from '@/mixins/theme'
export default {
  name: 'AppTagsView', mixins: [themeMixin],
  props: { visitedTabs: { type: Array, default: () => [] }, activeTab: { type: String, default: '' } },
  computed: {
    tagsStyle() {
      return {
        height: (this.theme.tabs_bar_height || 40) + 'px',
        lineHeight: (this.theme.tabs_bar_height || 40) + 'px',
        backgroundColor: this.theme.tabs_bg_color || '#ffffff',
        borderBottom: '1px solid ' + (this.theme.border_color || '#EBEEF5'),
        '--tabs-item-height': (this.theme.tabs_item_height || 32) + 'px',
        '--tabs-item-padding': (this.theme.tabs_item_padding || 12) + 'px',
        '--tabs-item-radius': (this.theme.tabs_item_radius || 4) + 'px',
        '--tabs-active-color': this.theme.tabs_color || '#409EFF',
        '--tabs-active-bg': this.theme.tabs_active_bg || '#ffffff',
        '--tabs-active-text': this.theme.tabs_active_text_color || '#409EFF',
      }
    },
  },
  methods: {
    removeTab(p) { this.$emit('remove-tab', p) },
    tabClick(t) { this.$router.push(t.name) },
  },
}
</script>
<style scoped>
.tags-view { padding: 0 10px; flex-shrink: 0; overflow: hidden; }
.tags-view >>> .el-tabs__header { margin: 0; border-bottom: none; }
.tags-view >>> .el-tabs__item { height: var(--tabs-item-height, 32px); line-height: var(--tabs-item-height, 32px); padding: 0 var(--tabs-item-padding, 12px); border: none !important; border-radius: var(--tabs-item-radius, 4px) !important; }
.tags-view >>> .el-tabs__item.is-active { color: var(--tabs-active-text, #409EFF) !important; background-color: var(--tabs-active-bg, #ffffff) !important; }
.tags-view >>> .el-tabs__item:not(.is-active) { color: var(--tabs-color, #606266); }
.tags-view >>> .el-tabs__active-bar { display: none; }
.tags-view >>> .el-tabs__item .el-icon-close { font-size: 12px; }
</style>
