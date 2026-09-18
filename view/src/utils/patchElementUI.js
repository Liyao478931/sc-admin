/**
 * element-ui 运行时补丁 —— ElCheckbox isLimitDisabled 空值兜底
 *
 * 背景：node_modules/element-ui/lib/checkbox.js 的计算属性 isLimitDisabled 直接访问
 *   this.model.length，当 checkbox-group 绑定的 v-model 不是数组（null/undefined）时
 *   会抛 TypeError: Cannot read properties of undefined (reading 'length')。
 * 产物修复：chunk-vendors 中 this.model.length -> (this.model||[]).length（共 3 处）。
 *
 * 此处通过覆盖组件选项 computed 的方式在运行时打补丁，不修改 node_modules，
 * 因此 npm install / 重新构建后补丁随本源码文件一起生效，不会丢失。
 * 必须在 Vue.use(ElementUI) 之前执行（main.js 中本文件在其上方 import）。
 */
import ElCheckbox from 'element-ui/lib/checkbox'

var comp = ElCheckbox && (ElCheckbox.default || ElCheckbox)
if (comp && comp.computed) {
  comp.computed.isLimitDisabled = function () {
    var group = this._checkboxGroup
    var max = group && group.max
    var min = group && group.min
    var model = this.model || []
    // 与 element-ui 原逻辑一致，仅把 this.model 兜底为 []
    return !!(max || min) && model.length >= max && !this.isChecked || model.length <= min && this.isChecked
  }
}
