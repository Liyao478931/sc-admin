<!--
  文件：admin/src/views/hr/assessment/template/components/IndicatorTab.vue
  功能：指标配置（树形管理/增删改/拖拽排序/启停用/指标库批量引入/总分实时校验）
  视觉：对齐参考模板（工具栏 / 指标树容器 / 底部总分栏）
-->
<template>
  <div class="indicator-tab">
    <template v-if="templateId">
      <div class="indicator-toolbar">
        <div class="btn-group">
          <el-button v-permission="'assessment:template:edit'" size="mini" type="primary" plain icon="el-icon-document-add" @click="openLibrary">从指标库添加</el-button>
          <el-button v-permission="'assessment:template:edit'" size="mini" plain icon="el-icon-folder-add" @click="openGroup">添加分组</el-button>
          <el-button v-permission="'assessment:template:edit'" size="mini" plain icon="el-icon-document" @click="openIndicator">添加指标</el-button>
        </div>
        <div style="flex:1;"></div>
        <div class="btn-group">
          <el-button size="mini" type="text" icon="el-icon-arrow-down" @click="expandAll">展开全部</el-button>
          <el-button size="mini" type="text" icon="el-icon-arrow-up" @click="collapseAll">收起全部</el-button>
          <el-button size="mini" type="text" icon="el-icon-refresh" @click="loadTree">刷新</el-button>
        </div>
      </div>

      <div class="indicator-tree-wrap" v-loading="loading">
        <template v-if="tree.length">
          <draggable v-model="tree" handle=".drag-handle" @end="onSortTop">
            <indicator-node
              v-for="node in tree" :key="node.id"
              :node="node" :template-id="templateId" :can-edit="canEdit"
              @add-child="openIndicatorUnder"
              @edit="openEdit"
              @duplicate="onDuplicate"
              @delete="onDelete"
              @toggle="onToggle"
              @sort="onSort"
            />
          </draggable>
        </template>
        <div v-else class="tree-empty">
          <el-empty description="暂无指标，点击上方按钮添加分组或指标" :image-size="80" />
        </div>
      </div>

      <div class="score-summary">
        <div class="left">
          <div class="total">总分：<span>{{ totalScore }}</span> / 100</div>
          <div class="hint" :class="scoreClass">{{ scoreText }}</div>
          <span class="text-muted">共 {{ leafCount }} 个指标 · {{ groupCount }} 个分组</span>
        </div>
        <div class="right">
          <el-button v-permission="'assessment:template:edit'" size="small" icon="el-icon-check" type="primary" @click="saveIndicators">保存指标</el-button>
          <el-button size="small" @click="loadTree">重置</el-button>
        </div>
      </div>

      <indicator-edit-dialog :visible="editVisible" :form="editForm" :parent-options="groupOptions" @save="onEditSave" @close="editVisible = false" />
      <indicator-library-dialog :visible="libraryVisible" @confirm="onLibraryConfirm" @close="libraryVisible = false" />
    </template>

    <div v-else class="unsaved-tip">
      <el-empty description="请先在「基本信息」标签页保存模板，再配置指标" :image-size="80" />
    </div>
  </div>
</template>

<script>
import draggable from 'vuedraggable'
import IndicatorNode from './IndicatorNode.vue'
import IndicatorEditDialog from './IndicatorEditDialog.vue'
import IndicatorLibraryDialog from './IndicatorLibraryDialog.vue'
import {
  getIndicatorTree, addIndicator, updateIndicator, deleteIndicator,
  batchAddIndicators, sortIndicators, toggleIndicatorStatus
} from '@/api/assessment'

function emptyForm () {
  return {
    id: 0, name: '', category: '', parent_id: 0, score: 0, scoring_type: 1,
    data_source_mode: 'manual', data_source: '', data_source_config: '',
    deduct_mode: 'by_count', conditions: [], ratio_value: 90, fixed_deduct: 0,
    grade: { a: 0, b: 0, c: 0, d: 0 }, threshold: 0, remark_template: ''
  }
}

export default {
  name: 'AssessmentIndicatorTab',
  components: { draggable, IndicatorNode, IndicatorEditDialog, IndicatorLibraryDialog },
  props: {
    templateId: { type: Number, default: 0 },
    canEdit: { type: Boolean, default: true }
  },
  data () {
    return {
      tree: [],
      totalScore: 0,
      leafCount: 0,
      groupCount: 0,
      loading: false,
      editVisible: false,
      editForm: emptyForm(),
      libraryVisible: false
    }
  },
  computed: {
    scoreClass () {
      if (this.totalScore === 100) return 'success'
      return this.totalScore > 100 ? 'over' : 'under'
    },
    scoreText () {
      if (this.totalScore === 100) return '✅ 分值平衡'
      if (this.totalScore > 100) return `⚠️ 超出 ${this.totalScore - 100} 分`
      return `⚠️ 不足 ${100 - this.totalScore} 分`
    },
    groupOptions () {
      const opts = []
      const walk = (nodes, depth) => {
        nodes.forEach(n => {
          if ((n.children && n.children.length) || n._isGroup) {
            opts.push({ id: n.id, label: '　'.repeat(depth) + n.name, depth })
          }
          if (n.children) walk(n.children, depth + 1)
        })
      }
      walk(this.tree, 0)
      return opts
    }
  },
  watch: {
    templateId (v) { if (v) this.loadTree() }
  },
  mounted () {
    if (this.templateId) this.loadTree()
  },
  methods: {
    async loadTree () {
      if (!this.templateId) return
      this.loading = true
      try {
        const r = await getIndicatorTree(this.templateId)
        if (r.code === 0 && r.data) {
          this.tree = r.data.indicators || []
          this.totalScore = Number(r.data.total_score || 0)
          this.leafCount = Number(r.data.indicator_count || 0)
          this.walkSet(this.tree, '_expanded', true)
          this.countGroups()
          this.$emit('tree-change', {
            tree: this.tree, totalScore: this.totalScore,
            indicatorCount: this.leafCount, groupCount: this.groupCount
          })
        }
      } catch (e) {} finally { this.loading = false }
    },
    saveIndicators () {
      this.$message.success('指标已保存')
      this.loadTree()
    },
    walkSet (nodes, key, val) {
      nodes.forEach(n => {
        this.$set(n, key, val)
        if (n.children) this.walkSet(n.children, key, val)
      })
    },
    countGroups () {
      let count = 0
      const walk = nodes => {
        nodes.forEach(n => {
          if ((n.children && n.children.length) || n._isGroup) count++
          if (n.children) walk(n.children)
        })
      }
      walk(this.tree)
      this.groupCount = count
    },
    markGroup (id) {
      const find = nodes => {
        for (const n of nodes) {
          if (n.id === id) { this.$set(n, '_isGroup', true); this.$set(n, '_expanded', true); return true }
          if (n.children && find(n.children)) return true
        }
        return false
      }
      find(this.tree)
      this.countGroups()
    },
    // ===== 弹窗 =====
    openLibrary () {
      if (!this.templateId) { this.$message.warning('请先保存模板基本信息'); return }
      this.libraryVisible = true
    },
    openGroup () {
      if (!this.templateId) { this.$message.warning('请先保存模板基本信息'); return }
      this.editForm = Object.assign(emptyForm(), { parent_id: 0 })
      this.editVisible = true
    },
    openIndicator () {
      if (!this.templateId) { this.$message.warning('请先保存模板基本信息'); return }
      this.editForm = Object.assign(emptyForm(), { parent_id: 0 })
      this.editVisible = true
    },
    openIndicatorUnder (group) {
      if (!this.templateId) { this.$message.warning('请先保存模板基本信息'); return }
      this.editForm = Object.assign(emptyForm(), { parent_id: group.id })
      this.editVisible = true
    },
    openEdit (node) {
      if (!this.templateId) { this.$message.warning('请先保存模板基本信息'); return }
      const rule = node.auto_deduct_rule || {}
      const hasConditions = Array.isArray(rule.conditions) && rule.conditions.length
      this.editForm = Object.assign(emptyForm(), {
        id: node.id,
        name: node.name || '',
        category: node.category || '',
        parent_id: node.parent_id || 0,
        score: Number(node.score || 0),
        scoring_type: node.scoring_type || 1,
        data_source: node.data_source || '',
        data_source_config: node.data_source_config ? JSON.stringify(node.data_source_config, null, 2) : '',
        deduct_mode: rule.mode || 'by_count',
        conditions: hasConditions ? rule.conditions.map(c => ({ ...c })) : [{ field: '', operator: 'eq', value: '', deduct_per_unit: 1, max_deduct: 0 }],
        ratio_value: Number((rule.conditions && rule.conditions[0] && rule.conditions[0].value) || 90),
        fixed_deduct: Number((rule.conditions && rule.conditions[0] && rule.conditions[0].deduct_per_unit) || 0),
        grade: rule.grade || { a: 0, b: 0, c: 0, d: 0 },
        threshold: Number(rule.threshold || 0),
        remark_template: rule.remark_template || ''
      })
      if (node.data_source) this.editForm.data_source_mode = 'auto'
      this.editVisible = true
    },
    // ===== 保存/操作 =====
    async onEditSave (payload) {
      const data = {
        name: payload.name,
        category: payload.category,
        parent_id: payload.parent_id,
        score: payload.score,
        data_source: payload.data_source,
        data_source_config: payload.data_source_config || '',
        scoring_type: payload.scoring_type,
        auto_deduct_rule: payload.auto_deduct_rule || '',
        is_custom: 1
      }
      try {
        const r = payload.id
          ? await updateIndicator(this.templateId, payload.id, data)
          : await addIndicator(this.templateId, data)
        if (r.code === 0) {
          this.$message.success(payload.id ? '指标已更新' : '指标已添加')
          this.editVisible = false
          await this.loadTree()
        }
      } catch (e) {}
    },
    async onLibraryConfirm (ids) {
      try {
        const r = await batchAddIndicators(this.templateId, { parent_id: 0, indicator_ids: ids })
        if (r.code === 0) {
          this.$message.success(r.msg || '添加成功')
          this.libraryVisible = false
          await this.loadTree()
        }
      } catch (e) {}
    },
    async onDelete (node) {
      const name = node.name || ''
      this.$confirm(`确认删除「${name}」吗？删除后不可恢复${node.children && node.children.length ? '（将级联删除其下所有子指标）' : ''}！`, '提示', { type: 'warning' })
        .then(async () => {
          try {
            const r = await deleteIndicator(this.templateId, node.id)
            if (r.code === 0) { this.$message.success('删除成功'); await this.loadTree() } else this.$message.error(r.msg || '删除失败')
          } catch (e) {}
        }).catch(() => {})
    },
    async onDuplicate (node) {
      try {
        const data = {
          name: node.name + '_副本',
          category: node.category || '',
          parent_id: node.parent_id || 0,
          score: node.score || 0,
          data_source: node.data_source || '',
          data_source_config: node.data_source_config ? JSON.stringify(node.data_source_config) : '',
          scoring_type: node.scoring_type || 1,
          auto_deduct_rule: node.auto_deduct_rule ? JSON.stringify(node.auto_deduct_rule) : '',
          is_custom: 1
        }
        const r = await addIndicator(this.templateId, data)
        if (r.code === 0) { this.$message.success('已复制为新指标'); await this.loadTree() }
      } catch (e) {}
    },
    async onToggle (node, val) {
      try {
        const r = await toggleIndicatorStatus(this.templateId, node.id)
        if (r.code === 0) { await this.loadTree() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {}
    },
    async onSort (ids) {
      if (!ids || !ids.length) return
      try {
        const r = await sortIndicators(this.templateId, ids)
        if (r.code === 0) await this.loadTree()
      } catch (e) {}
    },
    onSortTop () {
      this.onSort(this.tree.map(t => t.id))
    },
    expandAll () {
      this.walkSet(this.tree, '_expanded', true)
    },
    collapseAll () {
      this.walkSet(this.tree, '_expanded', false)
    }
  }
}
</script>

<style scoped>
.indicator-tab { padding: 12px 16px; }
.indicator-toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; margin: 12px 0 16px 0; padding: 12px 16px; background: #f7f9fc; border-radius: 10px; }
.btn-group { display: flex; gap: 6px; flex-wrap: wrap; }
.indicator-tree-wrap { border: 1px solid #e8ecf1; border-radius: 12px; padding: 8px 4px 8px 12px; max-height: 480px; overflow-y: auto; background: #fafbfc; min-height: 200px; }
.tree-empty { padding: 30px 0; }
.score-summary { display: flex; align-items: center; justify-content: space-between; margin-top: 16px; padding: 12px 18px; background: #f7f9fc; border-radius: 10px; flex-wrap: wrap; gap: 12px; }
.score-summary .left { display: flex; align-items: center; gap: 24px; flex-wrap: wrap; }
.score-summary .left .total { font-size: 15px; font-weight: 600; color: #1d2129; }
.score-summary .left .total span { color: #1e6fff; }
.score-summary .left .hint { font-size: 13px; color: #f77234; }
.score-summary .left .hint.success { color: #00b42a; }
.score-summary .right { display: flex; gap: 8px; }
.text-muted { color: #8c8f9c; font-size: 12px; }
.unsaved-tip { padding: 40px 0; }
</style>
