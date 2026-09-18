<!--
  文件：admin/src/views/business/product/bom/components/BomTreeTable.vue
  功能：BOM 结构树（详情页）
    - 自控树形：前端将树拍平 + 展开状态集合控制子行显隐（不依赖 el-table 树形 store，确保展开/折叠可靠）
    - 层级缩进（每级 24px）/ 层级列 / 背景交替 / 前缀字符 / 子件跳产品详情 / "查看BOM"
    - 全部展开/全部折叠 / 默认展开第一阶
-->
<template>
  <div class="bom-tree">
    <div class="toolbar">
      <el-button type="text" size="small" @click="expandAll">全部展开</el-button>
      <el-button type="text" size="small" @click="collapseAll">全部折叠</el-button>
    </div>
    <el-table :data="visibleRows" v-loading="loading" size="small" border :row-class-name="rowClass">
      <el-table-column label="层级" width="60" align="center">
        <template slot-scope="s"><span class="level-badge">L{{ s.row.level || 1 }}</span></template>
      </el-table-column>
      <el-table-column type="index" label="序号" width="50" align="center" />
      <el-table-column label="展开" width="50" align="center">
        <template slot-scope="s">
          <span v-if="s.row.hasChild" class="tree-arrow" :class="{ expanded: expandedKeys[s.row.id] }" @click="toggle(s.row)">
            <i class="el-icon-arrow-right"></i>
          </span>
        </template>
      </el-table-column>
      <el-table-column label="子件编码" width="140" show-overflow-tooltip>
        <template slot-scope="s">
          <span class="link-text" @click="viewProduct(s.row.component_product_id)">{{ s.row.component_code }}</span>
        </template>
      </el-table-column>
      <el-table-column label="子件名称" min-width="180" show-overflow-tooltip>
        <template slot-scope="s">
          <span :style="{ paddingLeft: (s.row._depth * 24) + 'px' }">
            <span v-if="s.row._depth > 0" class="tree-prefix">├─ </span>
            <span class="link-text" @click="viewProduct(s.row.component_product_id)">{{ s.row.component_name }}</span>
            <el-link v-if="s.row.default_bom_id" type="primary" :underline="false" class="view-bom" @click="viewBom(s.row.default_bom_id)">查看BOM</el-link>
          </span>
        </template>
      </el-table-column>
      <el-table-column prop="component_spec" label="子件规格" width="130" show-overflow-tooltip />
      <el-table-column prop="component_unit" label="单位" width="70" align="center" />
      <el-table-column prop="quantity" label="用量" width="100" align="right" />
      <el-table-column label="损耗率" width="90" align="right">
        <template slot-scope="s">{{ s.row.wastage_rate }}%</template>
      </el-table-column>
      <el-table-column label="来源类型" width="80" align="center">
        <template slot-scope="s">{{ s.row.source_type_label || '-' }}</template>
      </el-table-column>
      <el-table-column label="关键件" width="70" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="s.row.is_key === 1 ? 'success' : 'info'">{{ s.row.is_key === 1 ? '是' : '否' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="sort" label="排序" width="70" align="center" />
      <el-table-column prop="remark" label="备注" width="150" show-overflow-tooltip />
    </el-table>
    <el-empty v-if="!loading && !items.length" description="该BOM暂无子项" :image-size="80" />
  </div>
</template>

<script>
export default {
  name: 'BomTreeTable',
  props: {
    items: { type: Array, default: () => [] },
    loading: { type: Boolean, default: false }
  },
  data() {
    return {
      flatRows: [],
      expandedKeys: {} // { id: true } 展开状态
    }
  },
  computed: {
    /** 可见行：顶级行 + 父级已展开的行 */
    visibleRows() {
      return this.flatRows.filter(r => r._depth === 0 || this.expandedKeys[r._parentId])
    }
  },
  watch: {
    items() {
      this.rebuild()
    }
  },
  mounted() {
    this.rebuild()
  },
  methods: {
    rebuild() {
      this.flatRows = []
      this.expandedKeys = {}
      this.flatten(this.items, 0, null)
      // 默认展开第一阶：展开所有有子项的顶级节点
      this.items.forEach(r => {
        if (r.children && r.children.length) this.$set(this.expandedKeys, r.id, true)
      })
    },
    flatten(nodes, depth, parentId) {
      ;(nodes || []).forEach(n => {
        const hasChild = !!(n.children && n.children.length)
        this.flatRows.push({
          ...n,
          _depth: depth,
          _parentId: parentId,
          hasChild
        })
        if (hasChild) this.flatten(n.children, depth + 1, n.id)
      })
    },
    /** 行样式：偶数层级浅灰背景交替 */
    rowClass({ row }) {
      return ((row.level || 1) % 2 === 0) ? 'row-even' : ''
    },
    /** 点击箭头：切换展开状态 */
    toggle(row) {
      if (!row.hasChild) return
      if (this.expandedKeys[row.id]) {
        this.$delete(this.expandedKeys, row.id)
      } else {
        this.$set(this.expandedKeys, row.id, true)
      }
    },
    expandAll() {
      this.flatRows.forEach(r => { if (r.hasChild) this.$set(this.expandedKeys, r.id, true) })
    },
    collapseAll() {
      this.flatRows.forEach(r => { if (r.hasChild) this.$delete(this.expandedKeys, r.id) })
    },
    viewProduct(id) {
      if (!id) return
      this.$router.push(`/business/product/detail/${id}`)
    },
    /** 查看子件的默认 BOM（点击"查看BOM"） */
    viewBom(bomId) {
      if (!bomId) return
      this.$router.push(`/business/product/bom/detail/${bomId}`)
    }
  }
}
</script>

<style scoped>
.toolbar { display: flex; justify-content: flex-end; margin-bottom: 8px; }
.link-text { color: #409eff; cursor: pointer; }
.tree-prefix { color: #c0c4cc; }
.view-bom { margin-left: 8px; font-size: 12px; }
.level-badge { display: inline-block; padding: 0 6px; border-radius: 4px; background: #ecf5ff; color: #409eff; font-size: 12px; }
.tree-arrow { display: inline-flex; align-items: center; justify-content: center; width: 22px; height: 22px; cursor: pointer; color: #909399; transition: transform .2s; }
.tree-arrow.expanded i { transform: rotate(90deg); }
/* 偶数层级行背景（交替） */
::v-deep .el-table .row-even td { background-color: #f5f7fa; }
</style>
