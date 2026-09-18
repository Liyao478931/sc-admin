<!-- 文件：admin/src/components/HeadersEditor.vue -->
<template>
  <div class="headers-editor">
    <div v-for="(h, i) in items" :key="i" class="header-row">
      <el-input v-model="h.key" placeholder="Header名，如 Content-Type" size="small" style="width:200px" />
      <el-input v-model="h.value" placeholder="值" size="small" style="width:280px" />
      <el-button size="small" type="danger" icon="el-icon-delete" @click="removeHeader(i)"></el-button>
    </div>
    <el-button size="small" type="primary" plain icon="el-icon-plus" @click="addHeader">添加请求头</el-button>
  </div>
</template>

<script>
export default {
  name: 'HeadersEditor',
  model: {
    prop: 'value',
    event: 'change'
  },
  props: {
    value: { type: Array, default: () => [] }
  },
  data () {
    return { items: [] }
  },
  watch: {
    value: {
      immediate: true,
      handler (v) {
        const arr = Array.isArray(v) ? v : []
        this.items = arr.map(h => ({ key: h.key || h.k || '', value: h.value || h.v || '' }))
      }
    }
  },
  methods: {
    addHeader () {
      this.items.push({ key: '', value: '' })
    },
    removeHeader (i) {
      this.items.splice(i, 1)
      this.emitChange()
    },
    emitChange () {
      const obj = {}
      this.items.forEach(h => {
        if (h.key && h.key.trim()) obj[h.key.trim()] = h.value || ''
      })
      this.$emit('change', Object.keys(obj).length ? obj : [])
    }
  }
}
</script>

<style scoped>
.header-row { display: flex; gap: 8px; margin-bottom: 8px; align-items: center; }
</style>
