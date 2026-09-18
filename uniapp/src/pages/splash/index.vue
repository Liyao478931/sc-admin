<template>
  <view class="splash" :style="{ background: bgColor }">
    <!-- 图片 -->
    <image v-if="type===1||type===3" :src="image" mode="aspectFill" class="splash-img" />
    <!-- 视频 -->
    <video v-if="(type===2||type===3) && video" :src="video" autoplay loop muted class="splash-video" />

    <!-- 文字 -->
    <view v-if="showText && textContent" class="splash-text" :style="{ color: textColor, fontSize: textSize+'px', [posMap[textPosition]]:'50px', left:0, right:0, zIndex:3, fontWeight:600, textShadow:'0 2px 12px rgba(0,0,0,0.4)', padding:'0 24px', lineHeight:1.5 }">
      {{ textContent }}
    </view>

    <!-- 跳过按钮 -->
    <view v-if="skipEnabled && skipStyle!==3" class="skip-btn" :style="{ color: skipColor, background:'rgba(255,255,255,0.1)', backdropFilter:'blur(8px)', WebkitBackdropFilter:'blur(8px)', border:'1px solid rgba(255,255,255,0.12)' }" @click.stop="doSkip">
      {{ skipStyle===2 ? '跳过' : (skipText||'跳过') }}
    </view>

    <!-- 倒计时 -->
    <view class="timer">{{ countdown }}s</view>
  </view>
</template>

<script>
export default {
  data() {
    return {
      type:1, image:'', video:'', bgColor:'#ffffff', duration:3,
      skipEnabled:1, skipStyle:1, skipText:'跳过', skipColor:'#ffffff', skipPosition:1,
      showText:0, textContent:'', textColor:'#ffffff', textPosition:1, textSize:24, enabled:1,
      countdown:3, timer:null,
      posMap:{1:'top',2:'bottom',3:'top'},
    }
  },
  onLoad() { this.fetchSplash() },
  onUnload() { if(this.timer) clearInterval(this.timer) },
  methods: {
    async fetchSplash() {
      try {
        var r = await uni.request({ url:uni.$base + '/api/app/splash' })
        if(r.data && r.data.code === 0 && r.data.data) {
          var d = r.data.data
          this.type = d.type||1
          this.image = d.image||''
          this.video = d.video||''
          this.bgColor = d.background_color||'#ffffff'
          this.duration = d.duration||3
          this.skipEnabled = d.skip_enabled||0
          this.skipStyle = d.skip_style||1
          this.skipText = d.skip_text||'跳过'
          this.skipColor = d.skip_color||'#ffffff'
          this.skipPosition = d.skip_position||1
          this.showText = d.show_text||0
          this.textContent = d.text_content||''
          this.textColor = d.text_color||'#ffffff'
          this.textPosition = d.text_position||1
          this.textSize = d.text_size||24
          this.enabled = d.enabled||0
        }
      } catch(e) {}
      this.startTimer()
    },
    startTimer() {
      if(this.enabled !== 1) { this.goLogin(); return }
      this.countdown = this.duration
      this.timer = setInterval(function() {
        this.countdown--
        if(this.countdown <= 0) { clearInterval(this.timer); this.goLogin() }
      }.bind(this), 1000)
    },
    doSkip() { if(this.timer) clearInterval(this.timer); this.goLogin() },
    goLogin() { uni.reLaunch({ url:'/pages/login/index' }) },
  },
}
</script>

<style>
.splash{width:100vw;height:100vh;position:relative;overflow:hidden;display:flex;align-items:center;justify-content:center}
.splash-img{position:absolute;top:0;left:0;width:100%;height:100%;z-index:1}
.splash-video{position:absolute;top:0;left:0;width:100%;height:100%;z-index:1;object-fit:cover}
.splash-text{position:absolute;text-align:center;z-index:3}
.skip-btn{position:absolute;right:20px;top:50px;padding:8px 20px;border-radius:24px;font-size:14px;z-index:10;min-width:60px;text-align:center}
.timer{position:absolute;bottom:40px;left:50%;transform:translateX(-50%);color:rgba(255,255,255,0.3);font-size:12px;z-index:3;background:rgba(0,0,0,0.1);padding:2px 12px;border-radius:10px}
</style>
