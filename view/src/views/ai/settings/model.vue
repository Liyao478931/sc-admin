<!-- 文件：admin/src/views/ai/settings/model.vue -->
<template>
  <div class="page">
    <!-- 顶部统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6">
        <div class="stat-card stat-blue">
          <i class="el-icon-s-data stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.total_models }}</div>
            <div class="stat-label">总模型数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-green">
          <i class="el-icon-check stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.enabled_models }}</div>
            <div class="stat-label">已启用数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-orange">
          <i class="el-icon-chat-dot-round stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.total_calls }}</div>
            <div class="stat-label">总调用次数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-purple">
          <i class="el-icon-star-on stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num stat-name">{{ stats.default_model_name || '未设置' }}</div>
            <div class="stat-label">默认模型</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- Tab 切换 -->
    <el-card shadow="never" class="sec-card">
      <el-tabs v-model="activeTab">
        <!-- ============ 服务商管理 ============ -->
        <el-tab-pane label="服务商管理" name="provider">
          <div class="toolbar">
            <el-button type="primary" size="small" icon="el-icon-plus" @click="openProviderDialog()">新增服务商</el-button>
            <el-button size="small" icon="el-icon-refresh" @click="loadProviders">刷新</el-button>
          </div>
          <el-table :data="providers" size="small" stripe v-loading="providerLoading">
            <el-table-column type="index" label="序号" width="60" />
            <el-table-column prop="provider_code" label="服务商标识" width="130" />
            <el-table-column prop="provider_name" label="服务商名称" width="150" />
            <el-table-column prop="api_base_url" label="API地址" min-width="220" show-overflow-tooltip />
            <el-table-column prop="model_count" label="模型数量" width="90" align="center" />
            <el-table-column label="状态" width="80" align="center">
              <template slot-scope="s">
                <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="220" align="center">
              <template slot-scope="s">
                <el-button size="mini" @click="openProviderDialog(s.row)">编辑</el-button>
                <el-button size="mini" type="danger" :disabled="s.row.model_count > 0" @click="deleteProvider(s.row)">删除</el-button>
                <el-button size="mini" :type="s.row.status === 1 ? 'warning' : 'success'" @click="toggleProvider(s.row)">
                  {{ s.row.status === 1 ? '停用' : '启用' }}
                </el-button>
              </template>
            </el-table-column>
          </el-table>
          <div class="pager">
            <el-pagination background layout="total, prev, pager, next" :total="providerTotal" :page-size="providerLimit"
              :current-page="providerPage" @current-change="p => { providerPage = p; loadProviders() }" />
          </div>
        </el-tab-pane>

        <!-- ============ 模型管理 ============ -->
        <el-tab-pane label="模型管理" name="model">
          <div class="toolbar">
            <el-button type="primary" size="small" icon="el-icon-plus" @click="openModelDialog()">新增模型</el-button>
            <el-button size="small" icon="el-icon-refresh" @click="loadModels">刷新</el-button>
          </div>
          <el-table :data="models" size="small" stripe v-loading="modelLoading">
            <el-table-column type="index" label="序号" width="60" />
            <el-table-column prop="model_code" label="模型标识" width="150" />
            <el-table-column prop="model_name" label="模型名称" width="150" />
            <el-table-column prop="provider_name" label="所属服务商" width="120" />
            <el-table-column prop="context_length" label="上下文长度" width="100" align="center" />
            <el-table-column prop="input_price" label="输入价格" width="100" align="right">
              <template slot-scope="s">{{ Number(s.row.input_price).toFixed(4) }}</template>
            </el-table-column>
            <el-table-column prop="output_price" label="输出价格" width="100" align="right">
              <template slot-scope="s">{{ Number(s.row.output_price).toFixed(4) }}</template>
            </el-table-column>
            <el-table-column label="默认" width="70" align="center">
              <template slot-scope="s">
                <el-tag v-if="s.row.is_default === 1" size="mini" type="warning">默认</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="状态" width="80" align="center">
              <template slot-scope="s">
                <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="300" align="center">
              <template slot-scope="s">
                <el-button size="mini" @click="openModelDialog(s.row)">编辑</el-button>
                <el-button size="mini" type="danger" @click="deleteModel(s.row)">删除</el-button>
                <el-button size="mini" :type="s.row.status === 1 ? 'warning' : 'success'" @click="toggleModel(s.row)">
                  {{ s.row.status === 1 ? '停用' : '启用' }}
                </el-button>
                <el-button v-if="s.row.is_default !== 1" size="mini" type="primary" @click="setDefaultModel(s.row)">设为默认</el-button>
                <el-button size="mini" type="info" @click="testModel(s.row)">测试</el-button>
              </template>
            </el-table-column>
          </el-table>
          <div class="pager">
            <el-pagination background layout="total, prev, pager, next" :total="modelTotal" :page-size="modelLimit"
              :current-page="modelPage" @current-change="p => { modelPage = p; loadModels() }" />
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 服务商弹窗 -->
    <el-dialog :title="providerForm.id ? '编辑服务商' : '新增服务商'" :visible.sync="providerDialogVisible" width="600px" top="8vh">
      <el-form :model="providerForm" label-width="110px" size="small">
        <el-form-item label="服务商标识" required>
          <el-input v-model="providerForm.provider_code" :disabled="!!providerForm.id" placeholder="小写字母/数字/下划线" />
        </el-form-item>
        <el-form-item label="服务商名称" required><el-input v-model="providerForm.provider_name" /></el-form-item>
        <el-form-item label="API地址" required><el-input v-model="providerForm.api_base_url" placeholder="https://api.example.com" /></el-form-item>
        <el-form-item label="认证方式">
          <el-select v-model="providerForm.auth_type" style="width:100%">
            <el-option label="API Key" value="api_key" />
            <el-option label="JWT Token" value="jwt_token" />
          </el-select>
        </el-form-item>
        <el-form-item label="API Key" required>
          <el-input v-model="providerForm.api_key" type="password" show-password
            :placeholder="providerForm.id && providerForm.api_key === '******' ? '已设置（留空保持不变）' : '请输入API密钥'" />
        </el-form-item>
        <el-form-item label="排序"><el-input-number v-model="providerForm.sort" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="providerForm.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
        <el-form-item label="描述"><el-input v-model="providerForm.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="providerDialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="providerSaving" @click="saveProvider">保存</el-button>
      </span>
    </el-dialog>

    <!-- 模型弹窗 -->
    <el-dialog :title="modelForm.id ? '编辑模型' : '新增模型'" :visible.sync="modelDialogVisible" width="600px" top="8vh">
      <el-form :model="modelForm" label-width="130px" size="small">
        <el-form-item label="模型标识" required>
          <el-input v-model="modelForm.model_code" :disabled="!!modelForm.id" placeholder="小写字母/数字/短横线" />
        </el-form-item>
        <el-form-item label="模型名称" required><el-input v-model="modelForm.model_name" /></el-form-item>
        <el-form-item label="所属服务商" required>
          <el-select v-model="modelForm.provider_id" style="width:100%" placeholder="请选择">
            <el-option v-for="p in providerOptions" :key="p.id" :label="p.provider_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="上下文长度"><el-input-number v-model="modelForm.context_length" :min="1" :step="1000" style="width:100%" /></el-form-item>
        <el-form-item label="输入价格(元/百万tokens)"><el-input-number v-model="modelForm.input_price" :min="0" :precision="4" :step="0.1" style="width:100%" /></el-form-item>
        <el-form-item label="输出价格(元/百万tokens)"><el-input-number v-model="modelForm.output_price" :min="0" :precision="4" :step="0.1" style="width:100%" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="modelForm.sort" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="modelForm.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
        <el-form-item label="描述"><el-input v-model="modelForm.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="modelDialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="modelSaving" @click="saveModel">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getAiProviderList, getAiProviderOptions, getAiProviderDetail, addAiProvider, editAiProvider,
  deleteAiProvider, toggleAiProviderStatus,
  getAiModelList, getAiModelOptions, getAiModelDetail, addAiModel, editAiModel,
  deleteAiModel, toggleAiModelStatus, setDefaultAiModel, testAiModel, getAiModelStatistics
} from '@/api/aiModel'

export default {
  name: 'AiModelConfig',
  data () {
    return {
      activeTab: 'provider',
      stats: { total_models: 0, enabled_models: 0, total_calls: 0, default_model_name: '' },
      // 服务商
      providers: [], providerTotal: 0, providerPage: 1, providerLimit: 20, providerLoading: false,
      providerDialogVisible: false, providerSaving: false,
      providerForm: { id: 0, provider_code: '', provider_name: '', api_base_url: '', auth_type: 'api_key', api_key: '', sort: 0, status: 1, description: '' },
      // 模型
      models: [], modelTotal: 0, modelPage: 1, modelLimit: 20, modelLoading: false,
      modelDialogVisible: false, modelSaving: false,
      modelForm: { id: 0, model_code: '', model_name: '', provider_id: 0, context_length: 128000, input_price: 0, output_price: 0, sort: 0, status: 1, description: '' },
      providerOptions: []
    }
  },
  created () {
    this.loadStatistics()
    this.loadProviders()
    this.loadModels()
    this.loadProviderOptions()
  },
  methods: {
    async loadStatistics () {
      try {
        const r = await getAiModelStatistics()
        if (r.code === 0) this.stats = Object.assign(this.stats, r.data || {})
      } catch (e) {}
    },
    async loadProviders () {
      this.providerLoading = true
      try {
        const r = await getAiProviderList({ page: this.providerPage, limit: this.providerLimit })
        if (r.code === 0) {
          this.providers = r.data.list || []
          this.providerTotal = r.data.total || 0
        }
      } catch (e) {} finally { this.providerLoading = false }
    },
    async loadProviderOptions () {
      try {
        const r = await getAiProviderOptions()
        if (r.code === 0) this.providerOptions = r.data.list || []
      } catch (e) {}
    },
    async loadModels () {
      this.modelLoading = true
      try {
        const r = await getAiModelList({ page: this.modelPage, limit: this.modelLimit })
        if (r.code === 0) {
          this.models = r.data.list || []
          this.modelTotal = r.data.total || 0
        }
      } catch (e) {} finally { this.modelLoading = false }
    },
    // ---- 服务商操作 ----
    openProviderDialog (row) {
      if (row) {
        getAiProviderDetail(row.id).then(r => {
          if (r.code === 0) {
            this.providerForm = Object.assign({ id: row.id }, r.data || {})
            this.providerDialogVisible = true
          }
        })
      } else {
        this.providerForm = { id: 0, provider_code: '', provider_name: '', api_base_url: '', auth_type: 'api_key', api_key: '', sort: 0, status: 1, description: '' }
        this.providerDialogVisible = true
      }
    },
    async saveProvider () {
      const f = this.providerForm
      if (!f.provider_name) return this.$message.warning('请填写服务商名称')
      if (!f.provider_code) return this.$message.warning('请填写服务商标识')
      if (!f.api_base_url) return this.$message.warning('请填写API地址')
      if (!f.id && !f.api_key) return this.$message.warning('请填写API Key')
      this.providerSaving = true
      try {
        const r = f.id ? await editAiProvider(f.id, f) : await addAiProvider(f)
        if (r.code === 0) {
          this.$message.success(r.msg || '保存成功')
          this.providerDialogVisible = false
          this.loadProviders(); this.loadProviderOptions(); this.loadStatistics()
        }
      } catch (e) {} finally { this.providerSaving = false }
    },
    async deleteProvider (row) {
      const c = await this.$confirm(`确认删除服务商「${row.provider_name}」？`, '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await deleteAiProvider(row.id)
        if (r.code === 0) { this.$message.success('已删除'); this.loadProviders() }
      } catch (e) {}
    },
    async toggleProvider (row) {
      try {
        const r = await toggleAiProviderStatus(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success('状态已更新'); this.loadProviders() }
      } catch (e) {}
    },
    // ---- 模型操作 ----
    openModelDialog (row) {
      if (row) {
        getAiModelDetail(row.id).then(r => {
          if (r.code === 0) {
            this.modelForm = Object.assign({ id: row.id }, r.data || {})
            this.modelDialogVisible = true
          }
        })
      } else {
        this.modelForm = { id: 0, model_code: '', model_name: '', provider_id: 0, context_length: 128000, input_price: 0, output_price: 0, sort: 0, status: 1, description: '' }
        this.modelDialogVisible = true
      }
    },
    async saveModel () {
      const f = this.modelForm
      if (!f.model_name) return this.$message.warning('请填写模型名称')
      if (!f.model_code) return this.$message.warning('请填写模型标识')
      if (!f.provider_id) return this.$message.warning('请选择所属服务商')
      this.modelSaving = true
      try {
        const r = f.id ? await editAiModel(f.id, f) : await addAiModel(f)
        if (r.code === 0) {
          this.$message.success(r.msg || '保存成功')
          this.modelDialogVisible = false
          this.loadModels(); this.loadStatistics()
        }
      } catch (e) {} finally { this.modelSaving = false }
    },
    async deleteModel (row) {
      const c = await this.$confirm(`确认删除模型「${row.model_name}」？`, '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await deleteAiModel(row.id)
        if (r.code === 0) { this.$message.success('已删除'); this.loadModels(); this.loadStatistics() }
      } catch (e) {}
    },
    async toggleModel (row) {
      try {
        const r = await toggleAiModelStatus(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success('状态已更新'); this.loadModels() }
      } catch (e) {}
    },
    async setDefaultModel (row) {
      try {
        const r = await setDefaultAiModel(row.id)
        if (r.code === 0) { this.$message.success('默认模型已更新'); this.loadModels(); this.loadStatistics() }
      } catch (e) {}
    },
    async testModel (row) {
      this.$message.info(`正在测试「${row.model_name}」...`)
      try {
        const r = await testAiModel(row.id)
        if (r.code === 0) {
          this.$message.success(`连接成功（${r.data.response_time || ''}）`)
        }
      } catch (e) {
        this.$message.error('连接失败，请检查 API Key 与网络')
      }
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; padding: 18px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
.stat-icon { font-size: 34px; margin-right: 14px; }
.stat-num { font-size: 22px; font-weight: 600; color: #303133; }
.stat-name { font-size: 16px; }
.stat-label { font-size: 12px; color: #909399; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-purple .stat-icon { color: #9B59B6; }
.toolbar { margin-bottom: 12px; }
.pager { margin-top: 12px; text-align: right; }
</style>
