<template>
  <el-dialog :title="dialogTitle" :visible.sync="visible" width="720px" append-to-body @closed="resetForm">
    <el-form :model="form" label-width="110px" size="small">
      <el-form-item label="数据源名称" required>
        <el-input v-model="form.ds_name" maxlength="50" placeholder="如：用户数据库同步" />
      </el-form-item>
      <el-form-item label="数据源类型" required>
        <el-select v-model="form.ds_type" style="width: 100%;" :disabled="!!form.id" placeholder="选择类型" @change="onTypeChange">
          <el-option v-for="(v, k) in typeMap" :key="k" :label="v" :value="k" />
        </el-select>
      </el-form-item>
      <el-form-item label="关联知识库" required>
        <el-select v-model="form.kb_id" filterable style="width: 100%;" placeholder="选择知识库">
          <el-option v-for="kb in kbList" :key="kb.kb_id" :label="kb.kb_name" :value="kb.kb_id" />
        </el-select>
      </el-form-item>

      <!-- 数据库配置 -->
      <template v-if="form.ds_type === 'database'">
        <el-form-item label="数据库类型">
          <el-select v-model="form.config.db_type" style="width: 100%;">
            <el-option label="MySQL" value="mysql" /><el-option label="PostgreSQL" value="pgsql" />
            <el-option label="SQL Server" value="sqlsrv" /><el-option label="Oracle" value="oracle" />
            <el-option label="SQLite" value="sqlite" />
          </el-select>
        </el-form-item>
        <el-row :gutter="10">
          <el-col :span="14"><el-form-item label="主机地址"><el-input v-model="form.config.host" placeholder="如 127.0.0.1" /></el-form-item></el-col>
          <el-col :span="10"><el-form-item label="端口"><el-input-number v-model="form.config.port" :min="1" :max="65535" style="width: 100%;" /></el-form-item></el-col>
        </el-row>
        <el-form-item label="数据库名"><el-input v-model="form.config.database" placeholder="数据库名" /></el-form-item>
        <el-row :gutter="10">
          <el-col :span="12"><el-form-item label="用户名"><el-input v-model="form.config.username" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="密码"><el-input v-model="form.config.password" type="password" show-password /></el-form-item></el-col>
        </el-row>
        <el-form-item label="表名/视图名"><el-input v-model="form.config.table_name" placeholder="支持多表，逗号分隔" /></el-form-item>
        <el-form-item label="查询条件"><el-input v-model="form.config.query_condition" type="textarea" :rows="2" placeholder="选填，SQL WHERE 条件" /></el-form-item>
        <el-row :gutter="10">
          <el-col :span="12"><el-form-item label="增量字段"><el-input v-model="form.config.increment_field" placeholder="如 id、update_time" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="增量字段类型">
            <el-select v-model="form.config.increment_type" style="width: 100%;">
              <el-option label="数字" value="number" /><el-option label="日期时间" value="datetime" /><el-option label="字符串" value="string" />
            </el-select>
          </el-form-item></el-col>
        </el-row>
      </template>

      <!-- API 配置 -->
      <template v-else-if="form.ds_type === 'api'">
        <el-form-item label="API地址"><el-input v-model="form.config.url" placeholder="https://api.example.com/v1/users" /></el-form-item>
        <el-form-item label="请求方法">
          <el-radio-group v-model="form.config.method"><el-radio label="GET">GET</el-radio><el-radio label="POST">POST</el-radio></el-radio-group>
        </el-form-item>
        <el-form-item label="认证方式">
          <el-select v-model="form.config.auth_type" style="width: 100%;" @change="onAuthChange">
            <el-option label="无" value="none" /><el-option label="API Key" value="api_key" />
            <el-option label="Bearer Token" value="bearer" /><el-option label="Basic Auth" value="basic" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="form.config.auth_type === 'api_key'" label="API Key"><el-input v-model="form.config.api_key" /></el-form-item>
        <el-form-item v-if="form.config.auth_type === 'bearer'" label="Token"><el-input v-model="form.config.token" /></el-form-item>
        <template v-if="form.config.auth_type === 'basic'">
          <el-row :gutter="10">
            <el-col :span="12"><el-form-item label="用户名"><el-input v-model="form.config.username" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="密码"><el-input v-model="form.config.password" type="password" show-password /></el-form-item></el-col>
          </el-row>
        </template>
        <el-form-item label="数据路径"><el-input v-model="form.config.data_path" placeholder="JSON 路径，如 data.items" /></el-form-item>
        <el-form-item label="分页类型">
          <el-select v-model="form.config.page_type" style="width: 100%;">
            <el-option label="offset/limit" value="offset" /><el-option label="page/size" value="page" />
          </el-select>
        </el-form-item>
      </template>

      <!-- 网页配置 -->
      <template v-else-if="form.ds_type === 'webpage'">
        <el-form-item label="网页URL"><el-input v-model="form.config.url" placeholder="https://example.com/article" /></el-form-item>
        <el-form-item label="渲染方式">
          <el-radio-group v-model="form.config.render"><el-radio label="static">静态</el-radio><el-radio label="dynamic">动态(JS)</el-radio></el-radio-group>
        </el-form-item>
        <el-form-item label="抓取深度"><el-input-number v-model="form.config.depth" :min="1" :max="5" /></el-form-item>
      </template>

      <!-- 文件系统配置 -->
      <template v-else-if="form.ds_type === 'filesystem'">
        <el-form-item label="存储类型">
          <el-select v-model="form.config.storage_type" style="width: 100%;">
            <el-option label="本地" value="local" /><el-option label="FTP" value="ftp" /><el-option label="SFTP" value="sftp" />
            <el-option label="OSS" value="oss" /><el-option label="COS" value="cos" /><el-option label="S3" value="s3" />
          </el-select>
        </el-form-item>
        <el-form-item label="目录路径"><el-input v-model="form.config.path" placeholder="如 /data/docs" /></el-form-item>
        <el-form-item label="文件匹配"><el-input v-model="form.config.file_pattern" placeholder="如 *.txt、*.pdf" /></el-form-item>
        <el-form-item label="递归扫描"><el-switch v-model="form.config.recursive" :active-value="1" :inactive-value="0" /></el-form-item>
      </template>

      <!-- 文件配置 -->
      <template v-else-if="form.ds_type === 'file'">
        <el-form-item label="文件URL"><el-input v-model="form.config.file_url" placeholder="https://example.com/data.csv" /></el-form-item>
        <el-form-item label="文件格式">
          <el-radio-group v-model="form.config.file_format"><el-radio label="csv">CSV</el-radio><el-radio label="excel">Excel</el-radio></el-radio-group>
        </el-form-item>
        <el-row :gutter="10">
          <el-col :span="12"><el-form-item label="表头行"><el-input-number v-model="form.config.header_row" :min="1" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="数据起始行"><el-input-number v-model="form.config.data_start_row" :min="1" /></el-form-item></el-col>
        </el-row>
      </template>

      <!-- 同步配置 -->
      <el-divider content-position="left">同步配置</el-divider>
      <el-row :gutter="10">
        <el-col :span="12">
          <el-form-item label="同步频率">
            <el-select v-model="form.sync_config.frequency" style="width: 100%;">
              <el-option label="不自动同步" value="manual" /><el-option label="每小时" value="hourly" />
              <el-option label="每天" value="daily" /><el-option label="每周" value="weekly" /><el-option label="每月" value="monthly" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12"><el-form-item label="增量同步"><el-switch v-model="form.sync_config.incremental" active-text="开启" inactive-text="关闭" /></el-form-item></el-col>
      </el-row>
      <el-form-item label="预处理规则">
        <el-checkbox-group v-model="form.sync_config.preprocess">
          <el-checkbox label="strip_html">去HTML标签</el-checkbox>
          <el-checkbox label="clean_text">文本清洗</el-checkbox>
          <el-checkbox label="filter_special">过滤特殊字符</el-checkbox>
        </el-checkbox-group>
      </el-form-item>
      <el-row :gutter="10">
        <el-col :span="12"><el-form-item label="标题字段"><el-input v-model="form.field_mapping.title" placeholder="如 title、name" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="内容字段"><el-input v-model="form.field_mapping.content" placeholder="如 content、body" /></el-form-item></el-col>
      </el-row>
    </el-form>
    <div slot="footer">
      <el-button size="small" :loading="testing" @click="doTest">测试连接</el-button>
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">保存</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addDatasource, editDatasource, testDatasource } from '../../../../api/aiDatasource'

export default {
  name: 'DatasourceFormDialog',
  props: {
    kbList: { type: Array, default: () => [] }
  },
  data() {
    return {
      visible: false,
      saving: false,
      testing: false,
      typeMap: { database: '数据库', api: 'API', webpage: '网页', filesystem: '文件系统', message_queue: '消息队列', file: '文件' },
      form: this.emptyForm()
    }
  },
  computed: {
    dialogTitle() {
      return this.form.id ? '编辑数据源' : '新增数据源'
    }
  },
  methods: {
    emptyForm() {
      return {
        id: null, ds_name: '', ds_type: 'database', kb_id: '',
        config: { db_type: 'mysql', host: '', port: 3306, database: '', username: '', password: '', table_name: '', query_condition: '', increment_field: '', increment_type: 'number', url: '', method: 'GET', auth_type: 'none', api_key: '', token: '', data_path: '', page_type: 'offset', render: 'static', depth: 1, storage_type: 'local', path: '', file_pattern: '*.txt', recursive: 0, file_url: '', file_format: 'csv', header_row: 1, data_start_row: 2 },
        sync_config: { frequency: 'manual', incremental: false, preprocess: [] },
        field_mapping: { title: '', content: '' }
      }
    },
    open(row, mode) {
      if (row) {
        const cfg = (row.config && typeof row.config === 'object') ? row.config : {}
        const sync = (row.sync_config && typeof row.sync_config === 'object') ? row.sync_config : {}
        const mapping = (row.field_mapping && typeof row.field_mapping === 'object') ? row.field_mapping : {}
        // 规范化布尔值：兼容旧数据中字符串 "true"/"false"（urlencoded 序列化遗留）
        const normBool = (v) => v === true || v === 'true' || v === 1 || v === '1'
        const normObj = (obj) => {
          const out = {}
          Object.keys(obj).forEach(k => {
            if (obj[k] === 'true' || obj[k] === 'false') out[k] = normBool(obj[k])
            else if (Array.isArray(obj[k])) out[k] = obj[k]
            else if (obj[k] && typeof obj[k] === 'object') out[k] = normObj(obj[k])
            else out[k] = obj[k]
          })
          return out
        }
        this.form = {
          id: row.id, ds_name: row.ds_name, ds_type: row.ds_type, kb_id: row.kb_id,
          config: Object.assign({}, this.emptyForm().config, normObj(cfg)),
          sync_config: Object.assign({}, this.emptyForm().sync_config, normObj(sync)),
          field_mapping: Object.assign({}, this.emptyForm().field_mapping, normObj(mapping))
        }
      }
      this.visible = true
    },
    resetForm() {
      this.form = this.emptyForm()
    },
    onTypeChange() {
      this.form.config = this.emptyForm().config
    },
    onAuthChange() {
      this.form.config.api_key = ''
      this.form.config.token = ''
      this.form.config.username = ''
      this.form.config.password = ''
    },
    async doTest() {
      this.testing = true
      try {
        const res = await testDatasource({ ds_type: this.form.ds_type, config: this.form.config })
        const ok = res.data && res.data.ok
        this.$message[ok ? 'success' : 'error']((res.data && res.data.message) || res.msg || '测试完成')
      } catch (e) {}
      this.testing = false
    },
    async submit() {
      if (!this.form.ds_name) return this.$message.warning('请输入数据源名称')
      if (!this.form.ds_type) return this.$message.warning('请选择数据源类型')
      if (!this.form.kb_id) return this.$message.warning('请选择关联知识库')
      this.saving = true
      try {
        const payload = {
          ds_name: this.form.ds_name, ds_type: this.form.ds_type, kb_id: this.form.kb_id,
          config: this.form.config, sync_config: this.form.sync_config, field_mapping: this.form.field_mapping
        }
        if (this.form.id) await editDatasource(this.form.id, payload)
        else await addDatasource(payload)
        this.$message.success(this.form.id ? '数据源已更新' : '数据源创建成功')
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
