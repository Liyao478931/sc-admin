<!--
  文件：admin/src/views/hr/assessment/template/components/TemplateList.vue
  功能：左侧模板列表（搜索/筛选/新建/选中高亮/启停/复制/删除）
  视觉：对齐参考模板（状态点/编码/更新日期/版本徽标/激活态白底蓝边框）
-->
<template>
  <div class="tpl-list">
    <div class="sidebar-header">
      <span class="title">📋 模板列表</span>
      <el-button
        v-permission="'assessment:template:create'"
        type="primary" size="mini" icon="el-icon-plus" circle @click="$emit('create')"
      ></el-button>
    </div>

    <div class="template-search">
      <el-input v-model="query.keyword" size="small" prefix-icon="el-icon-search" clearable placeholder="搜索模板名称 / 编码" @keyup.enter.native="doSearch" @clear="doSearch" />
    </div>

    <div class="list-filters">
      <el-select v-model="query.status" size="mini" clearable placeholder="全部状态" @change="doSearch">
        <el-option label="已启用" :value="1" />
        <el-option label="已停用" :value="0" />
      </el-select>
      <el-select v-model="query.category" size="mini" clearable placeholder="全部岗位" @change="doSearch">
        <el-option v-for="c in CATEGORIES" :key="c" :label="c" :value="c" />
      </el-select>
    </div>

    <div class="list-body" v-loading="loading">
      <div
        v-for="item in list" :key="item.id"
        class="template-item" :class="{ active: item.id === selectedId }"
        @click="$emit('select', item.id)"
      >
        <div class="info">
          <div class="name">
            {{ item.name }}
            <span class="tag">{{ item.category || '未分类' }}</span>
          </div>
          <div class="meta">
            <span><span class="dot" :class="item.status === 1 ? 'active' : 'inactive'"></span>{{ item.status === 1 ? '启用' : '停用' }}</span>
            <span>编码: {{ item.code }}</span>
            <span>更新: {{ fmtDate(item.updated_at) }}</span>
          </div>
        </div>
        <div class="right-col">
          <span class="version-badge">V{{ item.version }}</span>
          <el-switch
            v-permission="'assessment:template:toggle'"
            :value="item.status === 1"
            size="mini"
            @change="val => $emit('toggle', item, val)"
          />
        </div>
        <div class="item-actions" @click.stop>
          <el-button v-permission="'assessment:template:duplicate'" type="text" size="mini" icon="el-icon-copy-document" @click="$emit('duplicate', item)">复制</el-button>
          <el-button v-permission="'assessment:template:delete'" type="text" size="mini" class="danger" icon="el-icon-delete" @click="$emit('delete', item)">删除</el-button>
        </div>
      </div>
      <div v-if="!loading && !list.length" class="list-empty">暂无模板</div>
    </div>

    <div class="list-footer">共 {{ list.length }} 个模板</div>
  </div>
</template>

<script>
const CATEGORIES = ['操作工', '维修工', '质检员', '班组长', '管理人员']

export default {
  name: 'AssessmentTemplateList',
  props: {
    list: { type: Array, default: () => [] },
    loading: { type: Boolean, default: false },
    selectedId: { type: Number, default: 0 }
  },
  data () {
    return {
      CATEGORIES,
      query: { keyword: '', status: '', category: '' }
    }
  },
  methods: {
    doSearch () {
      this.$emit('search', { ...this.query })
    },
    fmtDate (d) {
      if (!d) return '-'
      return String(d).slice(0, 10)
    }
  }
}
</script>

<style scoped>
.tpl-list { display: flex; flex-direction: column; height: 100%; }
.sidebar-header { display: flex; align-items: center; justify-content: space-between; padding: 14px 16px 14px 0; }
.sidebar-header .title { font-size: 15px; font-weight: 600; color: #1d2129; }
.template-search { padding-right: 16px; margin-bottom: 10px; }
.template-search >>> .el-input__inner { border-radius: 20px; background: #ffffff; }
.list-filters { display: flex; gap: 8px; padding-right: 16px; margin-bottom: 10px; flex-wrap: wrap; }
.list-filters >>> .el-select { flex: 1; min-width: 0; }
.list-body { flex: 1; overflow-y: auto; padding-right: 8px; }
.template-item { position: relative; display: flex; align-items: center; justify-content: space-between; gap: 8px; padding: 12px 16px 12px 14px; border-radius: 10px; margin-bottom: 4px; cursor: pointer; transition: all .2s; border-left: 3px solid transparent; }
.template-item:hover { background: #eef2f7; }
.template-item.active { background: #ffffff; border-left-color: #1e6fff; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04); }
.template-item .info { display: flex; flex-direction: column; gap: 4px; flex: 1; min-width: 0; }
.template-item .name { font-size: 14px; font-weight: 500; color: #1d2129; display: flex; align-items: center; gap: 8px; overflow: hidden; }
.template-item .name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.template-item .name .tag { font-size: 11px; background: #e8ecf1; color: #4e5a6b; padding: 0 8px; border-radius: 10px; font-weight: 400; flex-shrink: 0; }
.template-item .meta { font-size: 12px; color: #8c8f9c; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.template-item .meta .dot { display: inline-block; width: 6px; height: 6px; border-radius: 50%; margin-right: 4px; vertical-align: middle; }
.template-item .meta .dot.active { background: #00b42a; }
.template-item .meta .dot.inactive { background: #c9cdd4; }
.template-item .right-col { display: flex; align-items: center; gap: 6px; flex-shrink: 0; }
.template-item .version-badge { font-size: 11px; background: #e8ecf1; color: #4e5a6b; padding: 0 10px; border-radius: 12px; line-height: 20px; white-space: nowrap; }
.template-item .item-actions { display: none; position: absolute; right: 12px; bottom: -6px; background: #ffffff; border: 1px solid #e8ecf1; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,.08); padding: 2px 6px; z-index: 2; }
.template-item:hover .item-actions { display: inline-flex; gap: 4px; }
.danger { color: #F56C6C; }
.list-empty { text-align: center; color: #c0c4cc; padding: 40px 0; font-size: 13px; }
.list-footer { padding: 12px 16px 12px 0; font-size: 12px; color: #8c8f9c; border-top: 1px solid #e8ecf1; margin-top: 8px; }
@media (max-width: 992px) {
  .list-body { display: flex; flex-wrap: nowrap; overflow-x: auto; gap: 8px; padding: 4px 0; }
  .template-item { min-width: 200px; flex-shrink: 0; background: #ffffff; border: 1px solid #e8ecf1; border-radius: 10px; padding: 10px 14px; }
  .template-item.active { border-left: 3px solid #1e6fff; }
}
</style>
