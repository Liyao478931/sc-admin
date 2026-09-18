<template>
  <div class="mobile-config-page">
    <div class="page-header">
      <div>
        <h2>移动端配置</h2>
        <span class="sub-title">管理移动端轮播图与启动页</span>
      </div>
    </div>
    <div class="page-body">
      <el-tabs v-model="activeTab" type="border-card">
        <el-tab-pane label="轮播图管理" name="banner">
          <div class="banner-layout">
            <div class="banner-left">
              <BannerGroups ref="bannerGroups" @select="onGroupSelect" />
            </div>
            <div class="banner-right">
              <BannerList ref="bannerList" :group-id="currentGroupId" />
            </div>
          </div>
        </el-tab-pane>
        <el-tab-pane label="启动页配置" name="splash">
          <SplashConfig />
        </el-tab-pane>
      </el-tabs>
    </div>
  </div>
</template>

<script>
import BannerGroups from './components/BannerGroups.vue'
import BannerList from './components/BannerList.vue'
import SplashConfig from './components/SplashConfig.vue'

export default {
  name: 'MobileConfig',
  components: { BannerGroups, BannerList, SplashConfig },
  data() {
    return { activeTab: 'banner', currentGroupId: null }
  },
  methods: {
    onGroupSelect(groupId) { this.currentGroupId = groupId }
  }
}
</script>

<style scoped>
.mobile-config-page { padding: 0; background: #f0f2f5; min-height: 100vh; }
.page-header { height: 56px; background: #fff; border-bottom: 1px solid #EBEEF5; padding: 0 24px; display: flex; align-items: center; }
.page-header h2 { font-size: 20px; font-weight: bold; color: #303133; margin: 0; display: inline; }
.sub-title { font-size: 13px; color: #909399; margin-left: 12px; }
.page-body { padding: 24px; }
.banner-layout { display: flex; gap: 24px; min-height: 500px; }
.banner-left { width: 320px; flex-shrink: 0; }
.banner-right { flex: 1; min-width: 0; }
</style>
