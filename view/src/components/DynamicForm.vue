<!-- 文件：admin/src/components/DynamicForm.vue -->
<template>
  <div class="dynamic-form">
    <el-form ref="form" :model="formData" :rules="rules" label-width="130px" size="small">
      <div v-for="(field, key) in fields" :key="key" class="df-field">
        <el-form-item :label="field.title" :prop="key" :class="{ 'is-required': field.required }">
          <template #label>
            <span>
              <span v-if="field.required" class="req-star">*</span>{{ field.title }}
              <el-tooltip v-if="field.desc" :content="field.desc" placement="top">
                <i class="el-icon-question"></i>
              </el-tooltip>
            </span>
          </template>
          <!-- string / number / integer / boolean / array / object -->
          <el-input v-if="field.type === 'string'" v-model="formData[key]"
            :placeholder="field.desc || field.title" />
          <el-input-number v-else-if="field.type === 'number' || field.type === 'integer'"
            v-model="formData[key]" :precision="field.type === 'integer' ? 0 : undefined" style="width:100%" />
          <el-switch v-else-if="field.type === 'boolean'" v-model="formData[key]"></el-switch>
          <template v-else-if="field.type === 'array' || field.type === 'object'">
            <!-- 嵌套参数：可折叠展开 -->
            <el-collapse :value="activePanels" @change="v => activePanels = v" class="df-collapse">
              <el-collapse-item :name="key">
                <template #title>
                  <span class="df-nested-title">{{ field.type === 'object' ? '对象参数' : '数组参数' }}</span>
                </template>
                <!-- object 子参数 -->
                <div v-if="field.type === 'object'" class="df-nested">
                  <dynamic-form :ref="'obj_' + key" :schema="{ type: 'object', properties: field.properties || {}, required: field.nestedRequired }"
                    :value="formData[key]" @input="v => { formData[key] = v; emitChange() }" />
                </div>
                <!-- array 元素 -->
                <div v-else class="df-array">
                  <div v-for="(item, idx) in (formData[key] || [])" :key="idx" class="df-array-item">
                    <dynamic-form v-if="field.items && field.items.type === 'object'"
                      :ref="'arr_' + key + '_' + idx"
                      :schema="{ type: 'object', properties: (field.items.properties || {}), required: ((field.items.required) || []) }"
                      :value="item" @input="v => { formData[key][idx] = v; emitChange() }" />
                    <el-input v-else v-model="formData[key][idx]" placeholder="数组元素" />
                    <el-button size="mini" type="danger" icon="el-icon-delete" @click="removeArrayItem(key, idx)"></el-button>
                  </div>
                  <el-button size="mini" type="primary" plain icon="el-icon-plus" @click="addArrayItem(key, field)">添加元素</el-button>
                </div>
              </el-collapse-item>
            </el-collapse>
          </template>
        </el-form-item>
      </div>
    </el-form>
  </div>
</template>

<script>
export default {
  name: 'DynamicForm',
  components: { DynamicForm },
  props: {
    schema: { type: Object, default: () => ({ type: 'object', properties: {} }) },
    value: { type: Object, default: () => ({}) }
  },
  data () {
    return { formData: {}, activePanels: [] }
  },
  computed: {
    fields () {
      const schema = this.schema || {}
      const props = schema.properties || {}
      const required = schema.required || []
      return Object.keys(props).map(key => {
        const p = props[key] || {}
        return {
          key,
          type: p.type || 'string',
          title: p.title || key,
          desc: p.description || '',
          required: required.includes(key),
          default: p.default,
          properties: p.properties,
          items: p.items,
          nestedRequired: p.required || []
        }
      })
    },
    /** 根据 schema.required 生成 el-form 校验规则（boolean 无法判断缺失，不校验） */
    rules () {
      const schema = this.schema || {}
      const required = schema.required || []
      const props = schema.properties || {}
      const rules = {}
      required.forEach(key => {
        const p = props[key] || {}
        if (p.type === 'boolean') return
        if (p.type === 'array') {
          rules[key] = [{ required: true, type: 'array', min: 1, message: '请至少添加一个元素', trigger: 'change' }]
        } else {
          rules[key] = [{ required: true, message: '此项必填', trigger: 'blur' }]
        }
      })
      return rules
    }
  },
  watch: {
    value: {
      immediate: true,
      handler (v) {
        // 仅当外部显式赋值（引用或内容变化）时同步，避免与内部 emit 循环
        const next = this.buildForm(v)
        if (JSON.stringify(next) !== JSON.stringify(this.formData)) {
          this.formData = next
          // 嵌套对象/数组默认展开
          const panels = []
          this.fields.forEach(f => {
            if (f.type === 'object' || f.type === 'array') panels.push(f.key)
          })
          this.activePanels = panels
        }
      }
    },
    formData: {
      deep: true,
      handler (nv, ov) {
        if (ov && JSON.stringify(nv) === JSON.stringify(ov)) return
        this.$emit('input', this.formData)
      }
    }
  },
  methods: {
    /** 合并外部值 + 默认值，构造内部表单数据 */
    buildForm (v) {
      const next = {}
      this.fields.forEach(f => {
        if (v && v[f.key] !== undefined) {
          next[f.key] = v[f.key]
        } else if (f.default !== undefined) {
          next[f.key] = f.default
        } else if (f.type === 'boolean') {
          next[f.key] = false
        } else if (f.type === 'array') {
          next[f.key] = []
        } else if (f.type === 'object') {
          next[f.key] = {}
        } else if (f.type === 'number' || f.type === 'integer') {
          next[f.key] = 0
        } else {
          next[f.key] = ''
        }
      })
      return next
    },
    emitChange () { this.$emit('input', this.formData) },
    addArrayItem (key, field) {
      if (!this.formData[key]) this.formData[key] = []
      if (field.items && field.items.type === 'object') {
        this.formData[key].push({})
      } else {
        this.formData[key].push('')
      }
      this.emitChange()
    },
    removeArrayItem (key, idx) {
      if (this.formData[key]) this.formData[key].splice(idx, 1)
      this.emitChange()
    },
    /**
     * 校验整个动态表单（含嵌套的 object / 数组元素子表单）
     * @returns {Promise<boolean>} true 全部通过
     */
    async validate () {
      const checks = []
      if (this.$refs.form) {
        checks.push(this.$refs.form.validate().then(() => true).catch(() => false))
      }
      Object.keys(this.$refs).forEach(name => {
        if (name === 'form') return
        const ref = this.$refs[name]
        const list = Array.isArray(ref) ? ref : [ref]
        list.forEach(c => {
          if (c && typeof c.validate === 'function') checks.push(c.validate())
        })
      })
      const results = await Promise.all(checks)
      return results.every(Boolean)
    }
  }
}
</script>

<style scoped>
.dynamic-form { width: 100%; }
.df-field { margin-bottom: 4px; }
.req-star { color: #F56C6C; margin-right: 3px; }
.df-collapse { border: none; }
.df-collapse >>> .el-collapse-item__header { height: 32px; line-height: 32px; background: #f8f9fb; padding: 0 10px; font-size: 13px; color: #606266; border-bottom: 1px solid #ebeef5; }
.df-collapse >>> .el-collapse-item__wrap { border-bottom: none; }
.df-nested-title { font-weight: 500; }
.df-nested { border-left: 2px solid #ebeef5; padding-left: 12px; }
.df-array-item { display: flex; gap: 8px; align-items: center; margin-bottom: 6px; }
</style>
