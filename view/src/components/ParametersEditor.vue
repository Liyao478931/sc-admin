<!-- 文件：admin/src/components/ParametersEditor.vue -->
<template>
  <div class="params-editor">
    <!-- 模式切换 -->
    <div class="mode-bar">
      <el-radio-group v-model="mode" size="small" @change="handleModeChange">
        <el-radio-button label="visual">可视化</el-radio-button>
        <el-radio-button label="json">JSON</el-radio-button>
      </el-radio-group>
      <span class="mode-tip">{{ mode === 'json' ? 'JSON模式（高级）' : '可视化配置' }}</span>
    </div>

    <!-- 可视化模式：递归渲染参数树 -->
    <div v-if="mode === 'visual'" class="visual-mode">
      <param-tree :params="params" :depth="0" @change="emitChange" @toast="onToast" />
      <el-button size="small" type="primary" plain icon="el-icon-plus" @click="addParam">添加参数</el-button>
    </div>

    <!-- JSON 模式 -->
    <div v-else class="json-mode">
      <el-input v-model="jsonText" type="textarea" :rows="10" placeholder="{\n  \"type\": \"object\",\n  \"properties\": {}\n}" />
      <div class="json-actions">
        <el-button size="small" @click="formatJson">格式化</el-button>
        <el-button size="small" type="primary" @click="validateJson">校验</el-button>
      </div>
    </div>
  </div>
</template>

<script>
const PARAM_TYPES = ['string', 'number', 'integer', 'boolean', 'array', 'object']

// 递归参数树组件（支持多层嵌套，最多3层）
const ParamTree = {
  name: 'ParamTree',
  components: { ParamTree },
  props: { params: Array, depth: { type: Number, default: 0 } },
  methods: {
    addChild (p) {
      if (!p.children) p.children = []
      if (this.depth >= 2) { this.$emit('toast', '最多支持3层嵌套'); return }
      p.children.push({ name: '', type: 'string', required: false, title: '', default: '', children: [] })
      this.emitChange()
    },
    removeParam (idx) { this.params.splice(idx, 1); this.emitChange() },
    removeChild (p, childIdx) { if (p.children) p.children.splice(childIdx, 1); this.emitChange() },
    emitChange () { this.$emit('change') }
  },
  render (h) {
    const self = this
    return h('div', {}, this.params.map((p, idx) => {
      const row = h('div', { class: 'param-row', style: { marginLeft: this.depth * 24 + 'px' } }, [
        h('el-input', { props: { value: p.name, size: 'small', placeholder: '参数名' }, style: { width: '130px' }, on: { input: v => { p.name = v; self.emitChange() } } }),
        h('el-select', { props: { value: p.type, size: 'small' }, style: { width: '110px' }, on: { change: v => { p.type = v; self.emitChange() } } },
          PARAM_TYPES.map(t => h('el-option', { props: { key: t, label: t, value: t } }))),
        h('el-switch', { props: { value: p.required, activeText: '必填', inactiveText: '选填' }, on: { change: v => { p.required = v; self.emitChange() } } }),
        h('el-input', { props: { value: p.title, size: 'small', placeholder: '描述' }, style: { width: '150px' }, on: { input: v => { p.title = v; self.emitChange() } } }),
        h('el-input', { props: { value: p.default, size: 'small', placeholder: '默认值' }, style: { width: '100px' }, on: { input: v => { p.default = v; self.emitChange() } } }),
        (p.type === 'object' || p.type === 'array')
          ? h('el-button', { props: { size: 'small', icon: 'el-icon-plus' }, on: { click: () => self.addChild(p) } }, '子参数')
          : h('span', {}),
        h('el-button', { props: { size: 'small', type: 'danger', icon: 'el-icon-delete' }, on: { click: () => self.removeParam(idx) } })
      ])
      const children = (p.type === 'object' || p.type === 'array') && p.children && p.children.length
        ? h('param-tree', { props: { params: p.children, depth: this.depth + 1 }, on: { change: () => self.emitChange() } })
        : null
      return h('div', {}, [row, children])
    }))
  }
}

export default {
  name: 'ParametersEditor',
  components: { ParamTree },
  model: { prop: 'value', event: 'change' },
  props: {
    value: { type: Object, default: () => null }
  },
  data () {
    return {
      paramTypes: PARAM_TYPES,
      mode: 'visual',
      params: [],
      jsonText: ''
    }
  },
  watch: {
    value: {
      immediate: true,
      handler (v) {
        if (v && typeof v === 'object' && Object.keys(v).length) {
          this.jsonText = JSON.stringify(v, null, 2)
          this.params = this.schemaToParams(v)
        } else {
          this.jsonText = ''
          this.params = []
        }
      }
    }
  },
  methods: {
    // Schema → 可视化参数数组
    schemaToParams (schema) {
      const props = (schema && schema.properties) || {}
      const required = (schema && schema.required) || []
      return Object.keys(props).map(key => {
        const p = props[key] || {}
        const item = {
          name: key,
          type: p.type || 'string',
          required: required.includes(key),
          title: p.title || p.description || '',
          default: p.default !== undefined ? String(p.default) : '',
          children: []
        }
        if ((p.type === 'object' || p.type === 'array') && p.properties) {
          item.children = Object.keys(p.properties).map(c => ({
            name: c,
            type: p.properties[c].type || 'string',
            required: (p.required || []).includes(c),
            title: p.properties[c].title || '',
            default: p.properties[c].default !== undefined ? String(p.properties[c].default) : '',
            children: []
          }))
        }
        return item
      })
    },
    // 可视化参数 → Schema
    paramsToSchema () {
      const required = []
      const properties = {}
      this.params.forEach(p => {
        if (p.name) {
          if (p.required) required.push(p.name)
          const prop = { type: p.type }
          if (p.title) prop.title = p.title
          if (p.default !== '') prop.default = p.default
          if ((p.type === 'object' || p.type === 'array') && p.children && p.children.length) {
            const childRequired = []
            const childProps = {}
            p.children.forEach(c => {
              if (c.name) {
                if (c.required) childRequired.push(c.name)
                childProps[c.name] = { type: c.type }
                if (c.title) childProps[c.name].title = c.title
                if (c.default !== '') childProps[c.name].default = c.default
              }
            })
            if (Object.keys(childProps).length) prop.properties = childProps
            if (childRequired.length) prop.required = childRequired
          }
          properties[p.name] = prop
        }
      })
      return { type: 'object', properties, required: required.length ? required : undefined }
    },
    addParam () {
      this.params.push({ name: '', type: 'string', required: false, title: '', default: '', children: [] })
      this.emitChange()
    },
    onToast (msg) { this.$message.warning(msg) },
    emitChange () { this.$emit('change', this.paramsToSchema()) },
    // JSON 模式
    formatJson () {
      try {
        const obj = JSON.parse(this.jsonText || '{}')
        this.jsonText = JSON.stringify(obj, null, 2)
        this.$message.success('已格式化')
      } catch (e) { this.$message.error('JSON格式错误') }
    },
    validateJson () {
      try {
        JSON.parse(this.jsonText || '{}')
        this.$message.success('JSON合法')
      } catch (e) { this.$message.error('JSON格式错误') }
    },
    handleModeChange (mode) {
      if (mode === 'json') {
        this.jsonText = JSON.stringify(this.paramsToSchema(), null, 2)
      } else {
        try {
          const obj = JSON.parse(this.jsonText || '{}')
          this.params = this.schemaToParams(obj)
        } catch (e) { this.$message.error('JSON格式错误，无法切换到可视化模式') }
      }
    },
    getSchema () {
      if (this.mode === 'json') {
        try { return JSON.parse(this.jsonText || '{}') } catch (e) { return null }
      }
      return this.paramsToSchema()
    }
  }
}
</script>

<style scoped>
.mode-bar { margin-bottom: 12px; display: flex; align-items: center; gap: 12px; }
.mode-tip { font-size: 12px; color: #909399; }
.param-row { display: flex; gap: 8px; margin-bottom: 8px; align-items: center; }
.json-actions { margin-top: 8px; }
</style>
