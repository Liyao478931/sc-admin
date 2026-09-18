<template>
  <el-dialog title="数据预览" :visible.sync="visible" width="720px" append-to-body>
    <div v-if="row" class="preview-dialog">
      <el-alert v-if="error" :title="error" type="error" :closable="false" show-icon style="margin-bottom:10px;" />
      <el-alert v-else :title="'原始数据 ' + (raw.length) + ' 条 / 预处理后 ' + (processed.length) + ' 条'" type="info" :closable="false" show-icon style="margin-bottom:10px;" />

      <el-tabs v-model="tab">
        <el-tab-pane label="原始数据" name="raw">
          <el-table :data="raw" size="mini" stripe max-height="380">
            <el-table-column type="index" label="#" width="40" />
            <el-table-column label="数据" min-width="300">
              <template slot-scope="s"><pre class="row-json">{{ JSON.stringify(s.row) }}</pre></template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!raw.length" description="无数据" :image-size="50" />
        </el-tab-pane>
        <el-tab-pane label="预处理后" name="processed">
          <el-table :data="processed" size="mini" stripe max-height="380">
            <el-table-column type="index" label="#" width="40" />
            <el-table-column label="数据" min-width="300">
              <template slot-scope="s"><pre class="row-json">{{ JSON.stringify(s.row) }}</pre></template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!processed.length" description="无数据" :image-size="50" />
        </el-tab-pane>
      </el-tabs>
    </div>
    <div slot="footer">
      <el-button size="small" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { previewDatasource } from '../../../../api/aiDatasource'

export default {
  name: 'DatasourcePreviewDialog',
  data() {
    return {
      visible: false,
      tab: 'raw',
      row: null,
      raw: [],
      processed: [],
      error: ''
    }
  },
  methods: {
    async open(row) {
      this.visible = true
      this.row = row
      this.tab = 'raw'
      this.raw = []
      this.processed = []
      this.error = ''
      try {
        const res = await previewDatasource({
          ds_type: row.ds_type,
          config: (row.config && typeof row.config === 'object') ? row.config : {},
          sync_config: (row.sync_config && typeof row.sync_config === 'object') ? row.sync_config : {}
        })
        const d = res.data || {}
        this.raw = d.raw || []
        this.processed = d.processed || []
        this.error = d.error || ''
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.row-json { margin: 0; font-size: 12px; white-space: pre-wrap; word-break: break-all; }
</style>
