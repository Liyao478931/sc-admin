<template>
  <!-- 添加备件弹窗 -->
  <view v-if="visible" class="mask" @click.self="close">
    <view class="dialog">
      <view class="dialog-title">添加备件</view>
      <view class="form-item">
        <text class="label">备件名称 *</text>
        <input v-model="form.name" placeholder="请输入备件名称" />
      </view>
      <view class="form-item">
        <text class="label">规格型号</text>
        <input v-model="form.spec" placeholder="请输入规格型号" />
      </view>
      <view class="form-item">
        <text class="label">数量 *</text>
        <input v-model="form.quantity" type="number" placeholder="请输入数量" />
      </view>
      <view class="dialog-btns">
        <button class="btn cancel" @click="close">取消</button>
        <button class="btn ok" @click="confirm">确定</button>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  name: 'MaterialEditDialog',
  props: {
    visible: Boolean
  },
  data() {
    return { form: { name: '', spec: '', quantity: '' } }
  },
  watch: {
    visible(v) { if (v) this.form = { name: '', spec: '', quantity: '' } }
  },
  methods: {
    close() { this.$emit('update:visible', false) },
    confirm() {
      if (!this.form.name) { uni.showToast({ title: '请输入备件名称', icon: 'none' }); return }
      const qty = parseInt(this.form.quantity)
      if (!qty || qty <= 0) { uni.showToast({ title: '数量必须大于0', icon: 'none' }); return }
      this.$emit('confirm', { name: this.form.name, spec: this.form.spec || '', quantity: qty })
      this.close()
    }
  }
}
</script>

<style scoped>
.mask { position: fixed; left: 0; top: 0; right: 0; bottom: 0; background: rgba(0,0,0,.45); z-index: 999; display: flex; align-items: center; justify-content: center; }
.dialog { width: 600rpx; background: #fff; border-radius:20rpx; padding: 40rpx 32rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.dialog-title { font-size: 32rpx; font-weight: 600; text-align: center; margin-bottom: 32rpx; }
.form-item { margin-bottom: 24rpx; }
.form-item .label { display: block; font-size: 26rpx; color: #606266; margin-bottom: 12rpx; }
.form-item input { border: 1rpx solid #dcdfe6; border-radius:8rpx; padding: 16rpx 20rpx; font-size: 28rpx; }
.dialog-btns { display: flex; margin-top: 40rpx; }
.btn { flex: 1; margin: 0 8rpx; font-size: 30rpx; border-radius:8rpx; }
.btn.cancel { background: #f4f4f5; color: #606266; }
.btn.ok { background: #409EFF; color: #fff; }
</style>
