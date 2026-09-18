<!-- 文件：admin/src/views/ai/chat/favorites.vue -->
<template>
  <div class="page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6">
        <div class="stat-card stat-gold" @click="quickFilter('all')">
          <i class="el-icon-star-on stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.total_favorites }}</div>
            <div class="stat-label">总收藏数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-blue" @click="quickFilter('today')">
          <i class="el-icon-date stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.today_favorites }}</div>
            <div class="stat-label">今日收藏</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-green" @click="quickFilter('week')">
          <i class="el-icon-calendar stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.week_favorites }}</div>
            <div class="stat-label">本周收藏</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-purple">
          <i class="el-icon-collection stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.category_count }}</div>
            <div class="stat-label">自定义分类数</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <el-card shadow="never" class="sec-card">
      <!-- 筛选 -->
      <el-form inline size="small" class="filter-form">
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="搜索问题或答案" clearable style="width:200px"
            @keyup.enter.native="handleSearch" @clear="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.category_id" placeholder="全部分类" clearable style="width:140px" @change="handleSearch">
            <el-option label="全部分类" value="" />
            <el-option v-for="c in categories" :key="c.id" :label="c.category_name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始日期"
            end-placeholder="结束日期" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 工具栏 -->
      <div class="toolbar">
        <span class="toolbar-tip">共 {{ total }} 条收藏</span>
        <div class="toolbar-right">
          <el-button size="small" icon="el-icon-set-up" @click="openCategoryManage">分类管理</el-button>
          <el-dropdown trigger="click" @command="handleExportCmd">
            <el-button size="small" icon="el-icon-download">导出</el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item command="all">导出全部</el-dropdown-item>
              <el-dropdown-item command="category">按分类导出</el-dropdown-item>
              <el-dropdown-item command="selected" :disabled="!selection.length">导出选中（{{ selection.length }}）</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
          <el-button size="small" type="danger" icon="el-icon-delete" :disabled="!selection.length" @click="batchDelete">批量取消收藏</el-button>
        </div>
      </div>

      <!-- 卡片列表 -->
      <el-checkbox-group v-model="selection" class="fav-list" v-loading="loading">
        <div v-for="f in favorites" :key="f.id" class="fav-card">
          <div class="fav-card-head">
            <el-checkbox :label="f" class="fav-checkbox"></el-checkbox>
            <div class="fav-content">
              <div class="fav-head">
                <span class="fav-question" @click="openDetail(f)">{{ f.summary || truncate(f.question, 50) }}</span>
                <div class="fav-meta">
                  <el-tag v-if="f.category_name" size="mini" :color="catColor(f.category_id)" class="cat-tag">{{ f.category_name }}</el-tag>
                  <span class="fav-time">{{ f.create_time }}</span>
                </div>
              </div>
              <div class="fav-answer" @click="openDetail(f)">{{ truncate(f.answer, 100) }}</div>
              <div class="fav-foot">
                <span v-if="f.session_title" class="fav-session" @click="openSession(f)"><i class="el-icon-chat-dot-round"></i> {{ f.session_title }}</span>
                <div class="fav-actions">
                  <el-button size="mini" type="text" @click.stop="openDetail(f)">详情</el-button>
                  <el-select v-model="f.category_id" size="mini" placeholder="分类" style="width:110px" @change="changeCategory(f)" @click.stop.native>
                    <el-option v-for="c in categories" :key="c.id" :label="c.category_name" :value="c.id" />
                  </el-select>
                  <el-button size="mini" type="text" @click.stop="openNoteEdit(f)">备注</el-button>
                  <el-button size="mini" type="text" style="color:#F56C6C" @click.stop="removeOne(f)">取消收藏</el-button>
                </div>
              </div>
            </div>
          </div>
        </div>
        <el-empty v-if="!loading && !favorites.length" description="暂无收藏" />
      </el-checkbox-group>

      <!-- 分页 -->
      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next" :total="total"
          :page-size="limit" :page-sizes="[10, 20, 50]" :current-page="page"
          @size-change="p => { limit = p; page = 1; loadList() }"
          @current-change="p => { page = p; loadList() }" />
      </div>
    </el-card>

    <!-- 收藏详情弹窗 -->
    <el-dialog title="收藏详情" :visible.sync="detailVisible" width="750px" top="6vh">
      <div v-if="detail" class="fav-detail">
        <div class="detail-section">
          <div class="section-label">问题</div>
          <div class="section-body question">{{ detail.question }}</div>
        </div>
        <div class="detail-section">
          <div class="section-label">回答</div>
          <div class="section-body"><ai-markdown :content="detail.answer" /></div>
        </div>
        <div class="detail-section">
          <div class="section-label">信息</div>
          <div class="info-row">
            <el-tag v-if="detail.category_name" size="small" :color="catColor(detail.category_id)" class="cat-tag">{{ detail.category_name }}</el-tag>
            <span class="info-item">收藏时间：{{ detail.create_time }}</span>
            <span class="info-item">备注：{{ detail.note || '无' }}</span>
          </div>
          <div class="info-row" v-if="detail.session_title">
            <el-link type="primary" :underline="false" @click="openSession(detail)">所属会话：{{ detail.session_title }} →</el-link>
          </div>
        </div>
      </div>
      <span slot="footer">
        <el-button size="small" type="primary" @click="continueAsk">继续提问</el-button>
        <el-button size="small" @click="openNoteEdit(detail)">编辑备注</el-button>
        <el-button size="small" type="danger" @click="removeOne(detail)">取消收藏</el-button>
      </span>
    </el-dialog>

    <!-- 分类管理弹窗 -->
    <el-dialog title="分类管理" :visible.sync="categoryVisible" width="550px" top="8vh">
      <el-table :data="categories" size="small" stripe>
        <el-table-column prop="category_name" label="分类名称" />
        <el-table-column label="颜色" width="90" align="center">
          <template slot-scope="s">
            <span class="color-dot" :style="{ background: s.row.category_color }"></span>
          </template>
        </el-table-column>
        <el-table-column prop="favorite_count" label="收藏数" width="80" align="center" />
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="s">
            <el-button size="mini" :disabled="s.row.is_system === 1" @click="openCatEdit(s.row)">编辑</el-button>
            <el-button size="mini" type="danger" :disabled="s.row.is_system === 1" @click="removeCategory(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="cat-add">
        <el-input v-model="newCat.name" placeholder="新分类名称" style="width:180px" maxlength="50" />
        <el-color-picker v-model="newCat.color" />
        <el-button type="primary" size="small" @click="addCategory">新增分类</el-button>
      </div>
      <span slot="footer"><el-button size="small" type="primary" @click="categoryVisible=false">完成</el-button></span>
    </el-dialog>

    <!-- 备注编辑弹窗 -->
    <el-dialog title="编辑备注" :visible.sync="noteVisible" width="450px" top="20vh">
      <el-input v-model="noteText" type="textarea" :rows="3" maxlength="255" show-word-limit placeholder="输入备注" />
      <span slot="footer">
        <el-button size="small" @click="noteVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="saveNote">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import AiMarkdown from '@/components/AiMarkdown.vue'
import {
  getAiFavoriteList, getAiFavoriteDetail, deleteAiFavorite, batchDeleteAiFavorite,
  getAiFavoriteCategories, addAiFavoriteCategory, editAiFavoriteCategory, deleteAiFavoriteCategory,
  updateAiFavoriteCategory, updateAiFavoriteNote, getAiFavoriteStatistics, exportAiFavorites
} from '@/api/aiFavorite'

export default {
  name: 'AiChatFavorites',
  components: { AiMarkdown },
  data () {
    return {
      stats: { total_favorites: 0, today_favorites: 0, week_favorites: 0, category_count: 0 },
      filters: { keyword: '', category_id: '' },
      dateRange: [],
      favorites: [], total: 0, page: 1, limit: 20, loading: false,
      selection: [],
      categories: [],
      detailVisible: false, detail: null,
      categoryVisible: false, newCat: { name: '', color: '#409EFF' }, editCatId: 0,
      noteVisible: false, noteText: '', noteFavId: 0
    }
  },
  created () {
    this.loadStats()
    this.loadList()
    this.loadCategories()
  },
  methods: {
    truncate (s, n) {
      if (!s) return ''
      return s.length > n ? s.slice(0, n) + '...' : s
    },
    catColor (id) {
      const c = this.categories.find(x => x.id === id)
      return c ? c.category_color : undefined
    },
    // ---- 数据 ----
    async loadStats () {
      try {
        const r = await getAiFavoriteStatistics()
        if (r.code === 0) this.stats = Object.assign(this.stats, r.data || {})
      } catch (e) {}
    },
    async loadList () {
      this.loading = true
      try {
        const params = {
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || undefined,
          category_id: this.filters.category_id || undefined
        }
        if (this.dateRange && this.dateRange.length === 2) {
          params.start_date = this.dateRange[0]
          params.end_date = this.dateRange[1]
        }
        const r = await getAiFavoriteList(params)
        if (r.code === 0) {
          this.favorites = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    async loadCategories () {
      try {
        const r = await getAiFavoriteCategories()
        if (r.code === 0) this.categories = r.data.list || []
      } catch (e) {}
    },
    loadAll () { this.page = 1; this.loadList(); this.loadStats() },
    handleSearch () { this.page = 1; this.loadList() },
    handleReset () {
      this.filters = { keyword: '', category_id: '' }
      this.dateRange = []
      this.handleSearch()
    },
    quickFilter (type) {
      if (type === 'today') {
        const today = new Date()
        const fmt = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
        this.dateRange = [fmt(today), fmt(today)]
      } else if (type === 'week') {
        const now = new Date()
        const day = now.getDay() === 0 ? 7 : now.getDay()
        const monday = new Date(now)
        monday.setDate(now.getDate() - day + 1)
        const fmt = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
        this.dateRange = [fmt(monday), fmt(now)]
      } else {
        this.dateRange = []
      }
      this.handleSearch()
    },
    // ---- 收藏操作 ----
    async openDetail (f) {
      try {
        const r = await getAiFavoriteDetail(f.id)
        if (r.code === 0) { this.detail = r.data; this.detailVisible = true }
      } catch (e) {}
    },
    async removeOne (f) {
      const c = await this.$confirm('确定要取消收藏该问答吗？', '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await deleteAiFavorite(f.id)
        if (r.code === 0) {
          this.$message.success('已取消收藏')
          if (this.detailVisible) this.detailVisible = false
          this.loadAll()
        }
      } catch (e) {}
    },
    async batchDelete () {
      if (!this.selection.length) return
      const c = await this.$confirm(`确定要取消收藏选中的 ${this.selection.length} 条问答吗？`, '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const ids = this.selection.map(s => s.id)
        const r = await batchDeleteAiFavorite(ids)
        if (r.code === 0) { this.$message.success(r.msg || '批量取消完成'); this.selection = []; this.loadAll() }
      } catch (e) {}
    },
    async changeCategory (f) {
      try {
        const r = await updateAiFavoriteCategory(f.id, f.category_id)
        if (r.code === 0) { this.$message.success('分类已更新'); this.loadStats() }
      } catch (e) {}
    },
    openNoteEdit (f) {
      this.noteVisible = true
      this.noteText = f.note || ''
      this.noteFavId = f.id
    },
    async saveNote () {
      try {
        const r = await updateAiFavoriteNote(this.noteFavId, this.noteText.trim())
        if (r.code === 0) { this.$message.success('备注已更新'); this.noteVisible = false; this.loadList() }
      } catch (e) {}
    },
    openSession (detail) {
      if (detail.session_id) this.$router.push({ path: '/ai/chat/create', query: { session_id: detail.session_id } })
    },
    continueAsk () {
      if (this.detail && this.detail.session_id) {
        this.$router.push({ path: '/ai/chat/create', query: { session_id: this.detail.session_id, ask: this.detail.question } })
      }
    },
    // ---- 分类管理 ----
    openCategoryManage () { this.categoryVisible = true; this.loadCategories() },
    async addCategory () {
      const name = this.newCat.name.trim()
      if (!name) { this.$message.warning('请输入分类名称'); return }
      try {
        const r = await addAiFavoriteCategory({ category_name: name, category_color: this.newCat.color })
        if (r.code === 0) {
          this.$message.success('分类已新增')
          this.newCat = { name: '', color: '#409EFF' }
          this.loadCategories(); this.loadStats()
        }
      } catch (e) {}
    },
    async openCatEdit (cat) {
      const { value } = await this.$prompt('请输入新分类名称', '编辑分类', {
        inputValue: cat.category_name, inputValidator: v => (v && v.trim().length >= 1) || '分类名称不能为空'
      }).catch(() => ({ value: null }))
      if (value === null) return
      try {
        const r = await editAiFavoriteCategory(cat.id, { category_name: value.trim() })
        if (r.code === 0) { this.$message.success('分类已更新'); this.loadCategories() }
      } catch (e) {}
    },
    async removeCategory (cat) {
      const c = await this.$confirm(`确定删除分类「${cat.category_name}」？`, '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await deleteAiFavoriteCategory(cat.id)
        if (r.code === 0) { this.$message.success('分类已删除'); this.loadCategories(); this.loadStats() }
      } catch (e) {}
    },
    // ---- 导出 ----
    handleExportCmd (cmd) {
      if (cmd === 'all') this.doExport({})
      else if (cmd === 'category') {
        if (!this.filters.category_id) {
          this.$message.warning('请先在筛选区选择分类')
          return
        }
        this.doExport({ category_id: this.filters.category_id })
      } else if (cmd === 'selected') {
        if (!this.selection.length) return
        this.doExport({ ids: this.selection.map(s => s.id) })
      }
    },
    async doExport (params) {
      try {
        const blob = await exportAiFavorites({ format: 'md', ...params })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'ai_favorites_' + new Date().toISOString().slice(0, 10) + '.md'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error('导出失败')
      }
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; padding: 18px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,0.06); cursor: pointer; transition: transform 0.15s; }
.stat-card:hover { transform: translateY(-2px); }
.stat-icon { font-size: 34px; margin-right: 14px; }
.stat-num { font-size: 22px; font-weight: 600; color: #303133; }
.stat-label { font-size: 12px; color: #909399; }
.stat-gold .stat-icon { color: #E6A23C; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-purple .stat-icon { color: #9B59B6; }
.filter-form { margin-bottom: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-tip { font-size: 13px; color: #909399; }
.fav-list { width: 100%; }
.fav-card { border: 1px solid #ebeef5; border-radius: 8px; margin-bottom: 12px; background: #fff; transition: box-shadow 0.2s; }
.fav-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
.fav-checkbox { display: block; padding: 14px 16px; width: 100%; }
.fav-card-head { display: flex; align-items: flex-start; padding: 14px 16px; }
.fav-content { display: block; width: 100%; }
.fav-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.fav-question { font-weight: 600; color: #303133; font-size: 14px; }
.fav-meta { display: flex; align-items: center; gap: 8px; }
.fav-time { font-size: 12px; color: #909399; }
.cat-tag { color: #fff; border: none; }
.fav-answer { font-size: 13px; color: #606266; margin-bottom: 8px; line-height: 1.6; }
.fav-foot { display: flex; justify-content: space-between; align-items: center; }
.fav-session { font-size: 12px; color: #909399; }
.fav-actions { display: flex; align-items: center; gap: 4px; }
.pager { margin-top: 12px; text-align: right; }
.detail-section { margin-bottom: 14px; }
.section-label { font-size: 13px; font-weight: 600; color: #909399; margin-bottom: 6px; }
.section-body { background: #f8f9fb; border-radius: 6px; padding: 10px 12px; font-size: 14px; line-height: 1.7; }
.section-body.question { font-weight: 600; }
.info-row { display: flex; align-items: center; gap: 14px; margin-top: 6px; font-size: 13px; color: #606266; }
.color-dot { display: inline-block; width: 16px; height: 16px; border-radius: 3px; vertical-align: middle; }
.cat-add { margin-top: 12px; display: flex; gap: 10px; align-items: center; }
</style>
