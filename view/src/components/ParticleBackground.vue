<template>
  <canvas
    ref="canvas"
    class="particle-bg"
    :style="{ zIndex }"
    @mouseenter="onMouseEnter"
    @mouseleave="onMouseLeave"
    @mousemove="onMouseMove"
  />
</template>

<script>
/**
 * 鼠标跟随粒子特效组件
 * 发光圆点以闪现方式间歇跳变，鼠标移入时受吸引力聚集
 */
export default {
  name: 'ParticleBackground',
  props: {
    color:        { type: String,  default: '#409EFF' },
    particleCount:{ type: Number,  default: 60 },
    minSize:      { type: Number,  default: 2 },
    maxSize:      { type: Number,  default: 6 },
    minOpacity:   { type: Number,  default: 0.3 },
    maxOpacity:   { type: Number,  default: 0.9 },
    minInterval:  { type: Number,  default: 500 },
    maxInterval:  { type: Number,  default: 2000 },
    jumpDistance: { type: Number,  default: 80 },
    followStrength:{type: Number,  default: 0.3 },
    followRadius: { type: Number,  default: 300 },
    glowSize:     { type: Number,  default: 25 },
    zIndex:       { type: Number,  default: 1 },
  },
  data() {
    return {
      particles: [],
      mouseX: -9999,
      mouseY: -9999,
      mouseInside: false,
      animationId: null,
    }
  },
  mounted() {
    this.initCanvas()
    this.initParticles()
    this.animate()
    window.addEventListener('resize', this.onResize)
  },
  beforeDestroy() {
    if (this.animationId) cancelAnimationFrame(this.animationId)
    window.removeEventListener('resize', this.onResize)
  },
  methods: {
    /** 初始化画布尺寸 */
    initCanvas() {
      const cvs = this.$refs.canvas
      cvs.width = window.innerWidth
      cvs.height = window.innerHeight
    },
    /** 创建粒子 */
    initParticles() {
      const cvs = this.$refs.canvas
      const rand = (min, max) => min + Math.random() * (max - min)
      this.particles = Array.from({ length: this.particleCount }, () => {
        const x = Math.random() * cvs.width
        const y = Math.random() * cvs.height
        return {
          x, y,
          targetX: x, targetY: y,
          size: rand(this.minSize, this.maxSize),
          alpha: rand(this.minOpacity, this.maxOpacity),
          jumpTimer: 0,
          jumpInterval: rand(this.minInterval, this.maxInterval),
          phase: Math.random() * Math.PI * 2,
        }
      })
    },
    /** 计算粒子下一次闪现的目标位置 */
    computeTarget(p) {
      const cvs = this.$refs.canvas
      let tx = p.x + (Math.random() - 0.5) * this.jumpDistance * 2
      let ty = p.y + (Math.random() - 0.5) * this.jumpDistance * 2

      // 鼠标跟随吸引
      if (this.mouseInside) {
        const dx = this.mouseX - p.x
        const dy = this.mouseY - p.y
        const dist = Math.sqrt(dx * dx + dy * dy)
        if (dist < this.followRadius && dist > 0) {
          const strength = (1 - dist / this.followRadius) * this.followStrength
          tx += dx * strength
          ty += dy * strength
        }
      }

      // 边界约束
      tx = Math.max(10, Math.min(cvs.width - 10, tx))
      ty = Math.max(10, Math.min(cvs.height - 10, ty))
      return { targetX: tx, targetY: ty }
    },
    /** 绘制单个粒子（发光光晕） */
    drawParticle(ctx, p) {
      const gradient = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, this.glowSize)
      gradient.addColorStop(0, this.color)
      gradient.addColorStop(0.3, this.color)
      gradient.addColorStop(1, 'transparent')
      ctx.globalAlpha = p.alpha
      ctx.fillStyle = gradient
      ctx.beginPath()
      ctx.arc(p.x, p.y, this.glowSize, 0, Math.PI * 2)
      ctx.fill()

      // 核心亮点
      ctx.globalAlpha = Math.min(1, p.alpha * 1.5)
      ctx.fillStyle = '#ffffff'
      ctx.beginPath()
      ctx.arc(p.x, p.y, p.size * 0.4, 0, Math.PI * 2)
      ctx.fill()
    },
    /** 动画主循环 */
    animate() {
      const cvs = this.$refs.canvas
      if (!cvs) return
      const ctx = cvs.getContext('2d')
      const dt = 16

      ctx.clearRect(0, 0, cvs.width, cvs.height)

      for (const p of this.particles) {
        p.jumpTimer += dt

        // 鼠标跟随：持续平滑漂移
        if (this.mouseInside) {
          const dx = this.mouseX - p.x
          const dy = this.mouseY - p.y
          const dist = Math.sqrt(dx * dx + dy * dy)
          if (dist < this.followRadius && dist > 1) {
            // 吸引力：越近越强，限制单帧最大移动避免扎堆
            const pull = (1 - dist / this.followRadius) * this.followStrength * 3
            const maxPull = Math.min(pull, 8)
            p.x += (dx / dist) * maxPull
            p.y += (dy / dist) * maxPull
          }
          // 鼠标进入时缩短跳变间隔，跟随更灵敏
          p.jumpInterval = Math.max(this.minInterval * 0.3,
            this.minInterval + Math.random() * (this.maxInterval - this.minInterval) * 0.5)
        }

        // 闪现跳变
        if (p.jumpTimer >= p.jumpInterval) {
          const target = this.computeTarget(p)
          p.targetX = target.targetX
          p.targetY = target.targetY
          p.x = p.targetX
          p.y = p.targetY
          p.jumpTimer = 0
          p.jumpInterval = this.minInterval + Math.random() * (this.maxInterval - this.minInterval)
          this.$emit('jump', { index: this.particles.indexOf(p), x: p.x, y: p.y })
        }

        // 透明度呼吸
        p.phase += 0.02
        const breath = Math.sin(p.phase) * 0.15
        const baseAlpha = (p.alpha + this.minOpacity) / 2
        const currentAlpha = Math.max(this.minOpacity, Math.min(this.maxOpacity, baseAlpha + breath))
        p.currentAlpha = currentAlpha

        this.drawParticle(ctx, p)
      }

      this.animationId = requestAnimationFrame(this.animate)
    },
    onResize() {
      const cvs = this.$refs.canvas
      if (!cvs) return
      cvs.width = window.innerWidth
      cvs.height = window.innerHeight
    },
    onMouseEnter(e) {
      this.mouseInside = true
      this.mouseX = e.clientX
      this.mouseY = e.clientY
      this.$emit('mouseEnter')
    },
    onMouseMove(e) {
      this.mouseX = e.clientX
      this.mouseY = e.clientY
    },
    onMouseLeave() {
      this.mouseInside = false
      this.mouseX = -9999
      this.mouseY = -9999
      this.$emit('mouseLeave')
    },
  },
}
</script>

<style scoped>
.particle-bg {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: auto;
}
</style>
