<!-- 反馈按钮：有帮助 / 没帮助 / 重新生成 / 复制 / 分享 -->
<template>
  <div class="fb-wrap" @click.stop>
    <el-tooltip content="有帮助" placement="top">
      <i class="el-icon-top fb-btn" :class="{ 'fb-active': feedback === 'like' }" @click="$emit('like')"></i>
    </el-tooltip>
    <el-tooltip content="没帮助" placement="top">
      <i class="el-icon-bottom fb-btn" :class="{ 'fb-active': feedback === 'dislike' }" @click="$emit('dislike')"></i>
    </el-tooltip>
    <el-tooltip content="重新生成" placement="top">
      <i class="el-icon-refresh fb-btn" :class="{ 'fb-loading': regenerating }" @click="$emit('regenerate')"></i>
    </el-tooltip>
    <el-tooltip content="复制" placement="top">
      <i class="el-icon-document-copy fb-btn" @click="$emit('copy')"></i>
    </el-tooltip>
    <el-tooltip v-if="canShare" content="分享" placement="top">
      <i class="el-icon-share fb-btn" @click="$emit('share')"></i>
    </el-tooltip>
  </div>
</template>

<script>
export default {
  name: 'AiFeedbackButtons',
  props: {
    feedback: { type: String, default: '' },
    regenerating: { type: Boolean, default: false }
  },
  computed: {
    canShare () {
      const perms = this.$store.state.user.permissions || []
      return perms.includes('ai:assistant:share')
    }
  }
}
</script>

<style scoped>
.fb-wrap { display: flex; align-items: center; gap: 10px; margin-top: 4px; }
.fb-btn { font-size: 14px; color: #c0c4cc; cursor: pointer; transition: color .2s; }
.fb-btn:hover { color: #409eff; }
.fb-active { color: #409eff; }
.fb-loading { animation: fb-spin 1s linear infinite; color: #409eff; }
@keyframes fb-spin { from { transform: rotate(0); } to { transform: rotate(360deg); } }
</style>
