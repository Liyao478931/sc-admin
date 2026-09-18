<template>
  <div class="log-page">
    <!-- 安全告警横幅 -->
    <el-alert
      v-if="alerts.length > 0"
      :title="alertTitle"
      type="warning"
      :closable="true"
      show-icon
      style="margin-bottom: 16px;"
    />

    <!-- 4 Tab 切换 -->
    <el-tabs v-model="activeTab" @tab-click="handleTabClick">
      <!-- ========================================================== -->
      <!-- TAB 1: 日志列表                                              -->
      <!-- ========================================================== -->
      <el-tab-pane label="日志列表" name="list">
        <!-- 顶部标题行 -->
        <div class="page-header">
          <h3 style="margin:0;">日志列表</h3>
          <div class="header-actions">
            <el-select v-model="autoRefresh" size="small" style="width:130px;margin-right:8px;" @change="onAutoRefreshChange">
              <el-option label="关闭自动刷新" :value="0" />
              <el-option label="每30秒" :value="30000" />
              <el-option label="每60秒" :value="60000" />
              <el-option label="每120秒" :value="120000" />
            </el-select>
            <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="fetchList">刷新</el-button>
            <el-button size="small" type="success" icon="el-icon-download" @click="exportAudit">导出审计</el-button>
          </div>
        </div>

        <!-- 时间快捷筛选 -->
        <div class="filter-bar">
          <el-radio-group v-model="quickDate" size="small" @change="onQuickDateChange">
            <el-radio-button label="today">今天</el-radio-button>
            <el-radio-button label="yesterday">昨天</el-radio-button>
            <el-radio-button label="7d">最近7天</el-radio-button>
            <el-radio-button label="30d">最近30天</el-radio-button>
          </el-radio-group>
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="yyyy-MM-dd"
            size="small"
            style="margin-left:12px;width:240px;"
            @change="onDateRangeChange"
          />
        </div>

        <!-- 高级筛选 -->
        <el-collapse v-model="filterExpand" class="filter-collapse">
          <el-collapse-item title="高级筛选" name="adv">
            <el-row :gutter="12">
              <el-col :span="6"><el-select v-model="filters.log_type" placeholder="日志类型" clearable size="small" style="width:100%" @change="fetchList"><el-option label="全部" value="" /><el-option v-for="t in dictLogType" :key="t.value" :label="t.label" :value="t.value" /></el-select></el-col>
              <el-col :span="6"><el-select v-model="filters.result" placeholder="操作结果" clearable size="small" style="width:100%" @change="fetchList"><el-option label="全部" value="" /><el-option label="成功" value="success" /><el-option label="失败" value="fail" /></el-select></el-col>
              <el-col :span="6"><el-select v-model="filters.module" placeholder="操作模块" clearable filterable size="small" style="width:100%" @change="fetchList"><el-option label="全部模块" value="" /><el-option v-for="m in moduleOptions" :key="m" :label="m" :value="m" /></el-select></el-col>
              <el-col :span="6"><el-select v-model="filters.time_cost" placeholder="执行耗时" clearable size="small" style="width:100%" @change="fetchList"><el-option label="全部" value="" /><el-option label="< 100ms" value="fast" /><el-option label="100-500ms" value="medium" /><el-option label="500ms-1s" value="slow" /><el-option label="1s-3s" value="vslow" /><el-option label="> 3s" value="critical" /></el-select></el-col>
            </el-row>
            <el-row :gutter="12" style="margin-top:12px;">
              <el-col :span="6"><el-input v-model="filters.user" placeholder="操作用户" size="small" clearable @input="debouncedSearch" /></el-col>
              <el-col :span="6"><el-input v-model="filters.keyword" placeholder="搜索详情/对象/IP" size="small" clearable @input="debouncedSearch" /></el-col>
              <el-col :span="6"><el-select v-model="filters.method" placeholder="请求方法" clearable size="small" style="width:100%" @change="fetchList"><el-option label="全部" value="" /><el-option label="GET" value="GET" /><el-option label="POST" value="POST" /><el-option label="PUT" value="PUT" /><el-option label="DELETE" value="DELETE" /></el-select></el-col>
              <el-col :span="6"><el-button size="small" type="primary" @click="fetchList">搜索</el-button><el-button size="small" @click="resetFilters">重置</el-button></el-col>
            </el-row>
          </el-collapse-item>
        </el-collapse>

        <!-- 筛选标签 -->
        <div class="filter-tags" v-if="activeFilterTags.length > 0">
          <el-tag v-for="(tag,i) in activeFilterTags" :key="i" closable size="small" @close="removeFilterTag(tag.key)">{{ tag.label }}</el-tag>
          <span class="total-count">共 {{ total }} 条记录</span>
          <el-dropdown style="float:right;margin-left:8px;" @command="toggleColumn">
            <el-button size="mini">列设置<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-for="col in columnDefs" :key="col.prop" :command="col.prop" :disabled="col.fixed">
                <el-checkbox :checked="col.visible" :disabled="col.fixed" @click.native.stop @change="()=>{}" /> {{ col.label }}
              </el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
          <el-button size="mini" type="text" style="float:right;" @click="resetFilters">清空筛选</el-button>
        </div>

        <!-- 错误提示 -->
        <el-alert v-if="listError" :title="listError" type="error" show-icon style="margin-bottom:12px;" closable>
          <el-button size="mini" type="warning" slot="close" @click="fetchList">重试</el-button>
        </el-alert>

        <!-- 表格 -->
        <el-table ref="table" :data="list" v-loading="loading" stripe border style="width:100%" @row-click="showDetail" @sort-change="onSortChange" :empty-text="loading ? '加载中...' : '暂无日志数据，请调整筛选条件'">
          <el-table-column type="index" label="序号" width="60" fixed resizable="false" />
          <el-table-column v-if="colVisible('created_at')" prop="created_at" label="操作时间" width="170" sortable="custom" resizable />
          <el-table-column v-if="colVisible('log_type')" label="日志类型" width="110" resizable><template slot-scope="{row}"><el-tag :type="logTypeTag(row.log_type)" size="mini">{{ logTypeLabel(row.log_type) }}</el-tag></template></el-table-column>
          <el-table-column v-if="colVisible('username')" label="操作用户" width="120" resizable><template slot-scope="{row}"><el-tooltip :content="`ID:${row.user_id} ${row.username}`" placement="top"><span>{{ row.real_name||row.username||'-' }}</span></el-tooltip></template></el-table-column>
          <el-table-column v-if="colVisible('ip')" prop="ip" label="IP地址" width="150" resizable><template slot-scope="{row}"><el-tooltip :content="(row.ip_location||'') ? row.ip+' ('+row.ip_location+')' : row.ip" placement="top"><span>{{ row.ip||'-' }}</span></el-tooltip></template></el-table-column>
          <el-table-column v-if="colVisible('module')" prop="module" label="操作模块" width="120" resizable />
          <el-table-column v-if="colVisible('action')" prop="action" label="操作动作" width="100" resizable />
          <el-table-column v-if="colVisible('target_name')" prop="target_name" label="操作对象" min-width="150" resizable>
            <template slot-scope="{row}">
              <el-button v-if="row.target_name" type="text" size="small" @click.stop="navigateToTarget(row)">{{ row.target_name }}</el-button>
              <span v-else>-</span>
            </template>
          </el-table-column>
          <el-table-column v-if="colVisible('response_code')" label="操作结果" width="80" resizable><template slot-scope="{row}"><i v-if="row.response_code===0" class="el-icon-success" style="color:#67c23a;font-size:18px;" /><i v-else class="el-icon-error" style="color:#f56c6c;font-size:18px;" /></template></el-table-column>
          <el-table-column v-if="colVisible('execution_time')" prop="execution_time" label="执行耗时" width="100" sortable="custom" resizable><template slot-scope="{row}"><span :style="{color:row.execution_time>1000?'#f56c6c':'#333'}">{{ row.execution_time }}ms</span></template></el-table-column>
          <el-table-column label="操作" width="100" fixed="right" resizable="false"><template slot-scope="{row}"><el-button type="text" size="small" @click.stop="showDetail(row)">查看详情</el-button></template></el-table-column>
        </el-table>

        <!-- 分页 -->
        <div class="pagination-wrapper">
          <span class="page-info">共 {{ total }} 条记录</span>
          <el-pagination background :current-page="page" :page-size="limit" :total="total" :page-sizes="[20,50,100,200]" layout="sizes, prev, pager, next, jumper" @size-change="onSizeChange" @current-change="onPageChange" />
          <span class="page-stats">今日新增 {{ todayCount }} 条 | 本月新增 {{ monthCount }} 条</span>
        </div>
      </el-tab-pane>

      <!-- ========================================================== -->
      <!-- TAB 2: 统计看板                                              -->
      <!-- ========================================================== -->
      <el-tab-pane label="统计看板" name="statistics">
        <div class="stat-period">
          <el-radio-group v-model="statPeriod" size="small" @change="fetchStatistics">
            <el-radio-button label="today">今天</el-radio-button>
            <el-radio-button label="7d">最近7天</el-radio-button>
            <el-radio-button label="30d">最近30天</el-radio-button>
            <el-radio-button label="90d">最近90天</el-radio-button>
          </el-radio-group>
          <el-date-picker v-model="statDateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" size="small" style="margin-left:12px;width:240px;" @change="onStatDateChange" />
        </div>

        <!-- 统计卡片 -->
        <el-row :gutter="16" class="stat-cards">
          <el-col :span="4" v-for="card in statCards" :key="card.label">
            <el-card shadow="hover" class="stat-card">
              <div class="stat-label">{{ card.label }}</div>
              <div class="stat-value">{{ card.value }}</div>
              <div v-if="card.trendVal !== undefined" class="stat-change" :class="card.trendDir"><i :class="card.trendDir==='up'?'el-icon-top':'el-icon-bottom'" />{{ card.trendText }}</div>
              <div v-else class="stat-change" style="visibility:hidden;">-</div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 趋势图 -->
        <el-card shadow="never" style="margin-top:16px;">
          <div slot="header">日志趋势
            <el-button size="mini" style="float:right;" @click="downloadChart('trendChart')">下载图片</el-button>
          </div>
          <div ref="trendChart" style="width:100%;height:300px;"></div>
          <div v-if="!hasTrendData" style="text-align:center;color:#999;padding:60px 0;">暂无趋势数据</div>
        </el-card>

        <!-- 排行榜 + 图表 -->
        <el-row :gutter="16" style="margin-top:16px;">
          <el-col :span="8">
            <el-card shadow="never"><div slot="header">活跃用户 TOP10</div>
              <div v-for="(u,i) in statData.active_users||[]" :key="i" class="rank-item"><span class="rank-num">{{ i+1 }}</span><span class="rank-name">{{ u.real_name||u.username }}</span><span class="rank-count">{{ u.count }}次</span><el-progress :percentage="u.percent||0" :show-text="false" /></div>
              <el-empty v-if="!(statData.active_users||[]).length" description="暂无数据" />
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card shadow="never"><div slot="header">热门模块 TOP10</div>
              <div v-for="(m,i) in statData.hot_modules||[]" :key="i" class="rank-item"><span class="rank-num">{{ i+1 }}</span><span class="rank-name">{{ m.module }}</span><span class="rank-count">{{ m.count }}次</span><el-progress :percentage="m.percent||0" :show-text="false" /></div>
              <el-empty v-if="!(statData.hot_modules||[]).length" description="暂无数据" />
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card shadow="never"><div slot="header">最慢接口 TOP10</div>
              <div v-for="(a,i) in statData.slow_apis||[]" :key="i" class="rank-item"><span class="rank-num">{{ i+1 }}</span><span class="rank-name" style="flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">{{ a.request_url }}</span><span class="rank-count" style="color:#f56c6c;">{{ a.avg_time }}ms</span></div>
              <el-empty v-if="!(statData.slow_apis||[]).length" description="暂无数据" />
            </el-card>
          </el-col>
        </el-row>

        <!-- 操作分布饼图 + 登录时段柱状图 -->
        <el-row :gutter="16" style="margin-top:16px;">
          <el-col :span="12">
            <el-card shadow="never"><div slot="header">操作分布<el-button size="mini" style="float:right;" @click="downloadChart('pieChart')">下载图片</el-button></div>
              <div ref="pieChart" style="width:100%;height:280px;"></div>
              <div v-if="!hasActionData" style="text-align:center;color:#999;padding:60px 0;">暂无分布数据</div>
            </el-card>
          </el-col>
          <el-col :span="12">
            <el-card shadow="never"><div slot="header">登录时段分布<el-button size="mini" style="float:right;" @click="downloadChart('barChart')">下载图片</el-button></div>
              <div ref="barChart" style="width:100%;height:280px;"></div>
              <div v-if="!hasLoginHourData" style="text-align:center;color:#999;padding:60px 0;">暂无时段数据</div>
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <!-- ========================================================== -->
      <!-- TAB 3: 导出中心                                              -->
      <!-- ========================================================== -->
      <el-tab-pane label="导出中心" name="export">
        <el-card shadow="never"><div slot="header">新建导出任务</div>
          <el-form :model="exportForm" label-width="100px" size="small">
            <el-form-item label="导出类型"><el-select v-model="exportForm.type" style="width:200px;"><el-option v-for="t in dictLogType" :key="t.value" :label="t.label" :value="t.value" /></el-select></el-form-item>
            <el-form-item label="日期范围"><el-date-picker v-model="exportForm.dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" /></el-form-item>
            <el-form-item label="导出格式"><el-select v-model="exportForm.format" style="width:200px;"><el-option label="Excel" value="excel" /><el-option label="CSV" value="csv" /><el-option label="JSON" value="json" /><el-option label="PDF" value="pdf" /></el-select></el-form-item>
            <el-form-item label="导出字段"><el-checkbox-group v-model="exportForm.fields">
              <el-checkbox label="created_at">时间</el-checkbox>
              <el-checkbox label="log_type">日志类型</el-checkbox>
              <el-checkbox label="username">操作用户</el-checkbox>
              <el-checkbox label="ip">IP</el-checkbox>
              <el-checkbox label="module">模块</el-checkbox>
              <el-checkbox label="action">操作动作</el-checkbox>
              <el-checkbox label="target_name">对象名称</el-checkbox>
              <el-checkbox label="response_code">操作结果</el-checkbox>
              <el-checkbox label="execution_time">耗时</el-checkbox>
              <el-checkbox label="detail">详情描述</el-checkbox>
              <el-checkbox label="request_params">请求参数</el-checkbox>
              <el-checkbox label="response_msg">响应消息</el-checkbox>
            </el-checkbox-group></el-form-item>
            <el-form-item><el-button v-if="hasPerm('log:export')" type="primary" @click="handleExport">立即导出</el-button><el-button @click="resetExportForm">重置</el-button></el-form-item>
          </el-form>
        </el-card>
        <el-card shadow="never" style="margin-top:16px;"><div slot="header">导出任务列表</div>
          <el-table :data="exportTasks" stripe border size="small" v-loading="exportLoading">
            <el-table-column prop="id" label="任务编号" width="180" />
            <el-table-column prop="created_at" label="导出时间" width="170" />
            <el-table-column prop="format" label="导出格式" width="100" />
            <el-table-column prop="records" label="记录数" width="80" />
            <el-table-column prop="file_size" label="文件大小" width="100" />
            <el-table-column prop="status" label="任务状态" width="120"><template slot-scope="{row}"><el-tag :type="statusTag(row.status)" size="mini">{{ statusLabel(row.status) }}</el-tag></template></el-table-column>
            <el-table-column label="操作" width="140"><template slot-scope="{row}"><a v-if="row.status==='completed'" :href="downloadUrl(row.id)" target="_blank"><el-button type="text" size="small">下载</el-button></a><el-button v-if="row.status==='failed'" type="text" size="small">重试</el-button></template></el-table-column>
          </el-table>
          <div style="margin-top:12px;color:#999;font-size:12px;">
            文件保留7天，到期自动清理
            <el-button size="mini" type="text" style="float:right;" @click="clearCompletedTasks">清空已完成任务</el-button>
          </div>
        </el-card>
      </el-tab-pane>

      <!-- ========================================================== -->
      <!-- TAB 4: 日志设置                                              -->
      <!-- ========================================================== -->
      <el-tab-pane label="日志设置" name="settings">
        <el-card shadow="never"><div slot="header">日志记录设置</div>
          <el-form :model="settings" label-width="180px" size="small">
            <el-form-item label="启用日志记录"><el-switch v-model="settings.enabled" /></el-form-item>
            <el-form-item label="记录GET请求"><el-switch v-model="settings.record_get" /></el-form-item>
            <el-form-item label="记录响应数据"><el-switch v-model="settings.record_response" /></el-form-item>
            <el-form-item label="请求参数最大长度"><el-input-number v-model="settings.max_param_length" :min="500" :max="10000" /> 字符</el-form-item>
            <el-form-item label="敏感字段脱敏列表"><el-input v-model="settings.sensitive_fields_str" placeholder="用英文逗号分隔" /></el-form-item>
          </el-form>
        </el-card>
        <el-card shadow="never" style="margin-top:16px;"><div slot="header">日志清理策略</div>
          <el-form :model="settings" label-width="180px" size="small">
            <el-form-item label="启用自动清理"><el-switch v-model="settings.auto_clean" /></el-form-item>
            <el-form-item label="日志保留天数"><el-input-number v-model="settings.retain_days" :min="30" :max="365" /> 天</el-form-item>
            <el-form-item label="清理执行时间"><el-time-picker v-model="settings.clean_time" format="HH:mm" value-format="HH:mm" /></el-form-item>
            <el-form-item label="清理前通知"><el-switch v-model="settings.notify_before_clean" /></el-form-item>
            <el-form-item><el-button v-if="hasPerm('log:clean')" type="danger" size="small" @click="handleClean">立即清理</el-button><span style="color:#999;margin-left:8px;font-size:12px;">将删除保留天数之前的日志</span></el-form-item>
          </el-form>
        </el-card>
        <el-card shadow="never" style="margin-top:16px;"><div slot="header">通知设置</div>
          <el-form :model="settings" label-width="180px" size="small">
            <el-form-item label="日志写入失败通知"><el-switch v-model="settings.notify_write_fail" /></el-form-item>
            <el-form-item label="异常登录告警"><el-switch v-model="settings.notify_abnormal_login" /></el-form-item>
            <el-form-item label="存储空间告警"><el-switch v-model="settings.notify_storage_warning" /></el-form-item>
            <el-form-item label="存储空间告警阈值"><el-input-number v-model="settings.storage_threshold" :min="50" :max="95" /> %</el-form-item>
          </el-form>
        </el-card>
        <div style="margin-top:20px;text-align:center;"><el-button v-if="hasPerm('log:saveSettings')" type="primary" @click="handleSaveSettings">保存设置</el-button><el-button v-if="hasPerm('log:resetSettings')" @click="handleResetSettings">恢复默认</el-button></div>
      </el-tab-pane>
    </el-tabs>

    <!-- ============================================================ -->
    <!-- 日志详情弹窗                                                   -->
    <!-- ============================================================ -->
    <el-dialog title="日志详情" :visible.sync="detailVisible" :width="detailMaximized?'98%':'900px'" top="5vh" :close-on-click-modal="false" class="log-detail-dialog">
      <div style="position:absolute;top:16px;right:50px;z-index:10;">
        <el-button size="mini" circle :icon="detailMaximized?'el-icon-minus':'el-icon-full-screen'" @click="detailMaximized=!detailMaximized" />
        <el-button size="mini" circle icon="el-icon-printer" @click="printDetail" />
      </div>
      <template v-if="detailData">
        <!-- 顶部摘要 -->
        <div class="detail-header">
          <span class="detail-id">#{{ detailData.id }}</span>
          <el-tag :type="logTypeTag(detailData.log_type)" size="small">{{ logTypeLabel(detailData.log_type) }}</el-tag>
          <span :style="{color:detailData.response_code===0?'#67c23a':'#f56c6c',marginLeft:12}"><i :class="detailData.response_code===0?'el-icon-success':'el-icon-error'" /> {{ detailData.response_code===0?'成功':'失败' }}</span>
          <span style="margin-left:12px;color:#999;">{{ detailData.execution_time }}ms</span>
        </div>

        <!-- 基本信息 -->
        <el-row :gutter="16" class="detail-section">
          <el-col :span="12">
            <div><label>操作用户：</label>{{ detailData.real_name||detailData.username||'-' }}</div>
            <div><label>操作模块：</label>{{ detailData.module }}</div>
            <div><label>操作动作：</label>{{ detailData.action }}</div>
            <div><label>操作对象：</label>{{ detailData.target_name||'-' }}</div>
          </el-col>
          <el-col :span="12">
            <div><label>操作IP：</label>{{ detailData.ip||'-' }} <span v-if="detailData.ip_location" style="color:#999;font-size:12px;">({{ detailData.ip_location }})</span></div>
            <div><label>请求方法：</label>{{ detailData.request_method }}</div>
            <div><label>请求URL：</label><span style="word-break:break-all;">{{ detailData.request_url }}</span></div>
            <div><label>请求时间：</label>{{ detailData.created_at }}</div>
          </el-col>
        </el-row>

        <!-- 操作描述 -->
        <div class="detail-section"><h4>操作描述</h4><p>{{ detailData.detail||'无' }}</p></div>

        <!-- 数据对比 -->
        <div v-if="detailData.before_data||detailData.after_data" class="detail-section">
          <h4>数据变更</h4>
          <el-row :gutter="16">
            <el-col :span="12"><h5 style="color:#999;">修改前</h5><pre class="json-block">{{ formatJson(detailData.before_data) }}</pre></el-col>
            <el-col :span="12"><h5 style="color:#67c23a;">修改后</h5><pre class="json-block">{{ formatJson(detailData.after_data) }}</pre></el-col>
          </el-row>
        </div>

        <!-- 请求参数 -->
        <div class="detail-section"><h4>请求参数<el-button size="mini" type="text" style="float:right;" @click="copyText(detailData.request_params)">复制</el-button></h4><pre class="json-block">{{ formatJson(detailData.request_params) }}</pre></div>

        <!-- 响应信息 -->
        <div class="detail-section"><h4>响应消息</h4><pre class="json-block">{{ formatJson(detailData.response_data)||detailData.response_msg||'无' }}</pre></div>

        <!-- 系统信息（折叠） -->
        <div class="detail-section">
          <el-collapse><el-collapse-item title="系统信息">
            <div><label>User-Agent：</label><span style="word-break:break-all;">{{ detailData.user_agent||'-' }}</span></div>
            <div><label>内存消耗：</label>{{ detailData.memory_usage||0 }} KB</div>
            <div><label>请求参数大小：</label>{{ (detailData.request_params||'').length }} 字符</div>
            <div><label>响应数据大小：</label>{{ (detailData.response_data||'').length }} 字符</div>
            <div><label>DB查询次数：</label>{{ detailData.db_queries||0 }}</div>
            <div><label>缓存命中：</label>{{ detailData.cache_hits||0 }}</div>
          </el-collapse-item></el-collapse>
        </div>
      </template>
      <span slot="footer">
        <el-button size="small" @click="copyFullDetail">复制完整信息</el-button>
        <el-button size="small" @click="prevDetail" :disabled="!hasPrev">上一条</el-button>
        <el-button size="small" @click="nextDetail" :disabled="!hasNext">下一条</el-button>
        <el-button size="small" type="primary" @click="detailVisible=false">关闭</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getLogList, getLogDetail, getNeighborLog, getLogStatistics,
  exportLogs, getExportTasks, getLogSettings, saveLogSettings,
  resetLogSettings, cleanLogs, cleanLogsPreview, getLogAlerts } from '@/api/log'
import { getDictByCode } from '@/api/dictionary'

export default {
  name: 'LogIndex',
  data() {
    return {
      activeTab: 'list',
      alerts: [],
      loading: false, list: [], total: 0, page: 1,
      limit: parseInt(localStorage.getItem('log_page_size')||'20'),
      todayCount: 0, monthCount: 0, moduleOptions: [],
      sortField: 'created_at', sortOrder: 'desc',
      quickDate: 'today', dateRange: [],
      filterExpand: [],
      filters: { log_type:'', result:'', module:'', time_cost:'', user:'', keyword:'', method:'' },
      dictLogType: [],
      listError: '',
      autoRefresh: 0, refreshTimer: null, searchTimer: null,
      detailVisible: false, detailData: null, detailMaximized: false,
      statPeriod: '7d', statDateRange: [], statData: {}, statCardsData: [],
      exportForm: { type:1, dateRange:[], format:'excel',
        fields:['created_at','log_type','username','ip','module','action','target_name','response_code','execution_time','detail','request_params','response_msg']
      },
      exportTasks: [], exportLoading: false, exportTimer: null,
      settings: {
        enabled:true, record_get:false, record_response:true, max_param_length:2000,
        auto_clean:true, retain_days:180, clean_time:'02:00',
        notify_before_clean:false, notify_write_fail:true,
        notify_abnormal_login:true, notify_storage_warning:true, storage_threshold:80,
        sensitive_fields_str: 'password,secret,token,code,old_password'
      },
      chartInstances: {}
    }
  },
  computed: {
    activeFilterTags() {
      const t=[]
      if(this.filters.log_type) t.push({key:'log_type',label:`类型: ${this.logTypeLabel(parseInt(this.filters.log_type))}`})
      if(this.filters.module) t.push({key:'module',label:`模块: ${this.filters.module}`})
      if(this.filters.user) t.push({key:'user',label:`用户: ${this.filters.user}`})
      if(this.filters.keyword) t.push({key:'keyword',label:`关键词: ${this.filters.keyword}`})
      if(this.filters.action) t.push({key:'action',label:`动作: ${this.filters.action}`})
      return t
    },
    alertTitle() { return this.alerts.map(a=>a.msg).join('；') },
    hasPrev() { return !!this.detailData?.id },
    hasNext() { return !!this.detailData?.id },
    hasTrendData() { return (this.statData.trend||[]).length > 0 },
    hasActionData() { return (this.statData.action_dist||[]).length > 0 },
    hasLoginHourData() { return (this.statData.login_hourly||[]).length > 0 },
    columnDefs(){
      const saved=localStorage.getItem('log_cols')
      const defaults={created_at:true,log_type:true,username:true,ip:true,module:true,action:true,target_name:true,response_code:true,execution_time:true}
      const vis=saved?JSON.parse(saved):defaults
      return [
        {prop:'created_at',label:'操作时间',visible:vis.created_at!==false},
        {prop:'log_type',label:'日志类型',visible:vis.log_type!==false},
        {prop:'username',label:'操作用户',visible:vis.username!==false},
        {prop:'ip',label:'IP地址',visible:vis.ip!==false},
        {prop:'module',label:'操作模块',visible:vis.module!==false},
        {prop:'action',label:'操作动作',visible:vis.action!==false},
        {prop:'target_name',label:'操作对象',visible:vis.target_name!==false},
        {prop:'response_code',label:'操作结果',visible:vis.response_code!==false},
        {prop:'execution_time',label:'执行耗时',visible:vis.execution_time!==false},
      ]
    },
    statCards() {
      const d=this.statData
      const trend=(v,dir)=>v!==undefined&&v!==null?{trendVal:Math.abs(v),trendDir:dir>0?'up':dir<0?'down':'','trendText':(dir>0?'+':'')+v+'%'}:{trendVal:undefined,trendDir:'','trendText':'-'}
      return [
        {label:'总日志量',value:d.total_logs??'-',...trend(d.total_trend)},
        {label:'本月新增',value:d.month_count??'-',...trend(d.month_trend,d.month_trend)},
        {label:'今日新增',value:d.today_count??'-',...trend(d.today_trend,d.today_trend)},
        {label:'今日登录成功率',value:(d.login_success_rate??'-')+'%',...trend(d.login_rate_trend,d.login_rate_trend)},
        {label:'平均响应时间',value:(d.avg_time??'-')+'ms',...trend(d.avg_time_trend,d.avg_time_trend)},
        {label:'最慢接口',value:d.slowest_api?.url?.substring(0,25)||'-'}
      ]
    }
  },
  created() {
    this.restoreFilters()
    this.fetchList()
    this.fetchAlerts()
    getDictByCode('log_type').then(r=>{if(r.code===0)this.dictLogType=r.data||[]}).catch(()=>{})
    // 导出默认日期=最近30天
    const e=new Date(),s=new Date(e);s.setDate(s.getDate()-29)
    this.exportForm.dateRange=[s.toISOString().slice(0,10),e.toISOString().slice(0,10)]
  },
  mounted() {
    this.$nextTick(() => { if (this.activeTab==='statistics') this.renderCharts() })
  },
  beforeDestroy() {
    clearInterval(this.refreshTimer)
    clearInterval(this.exportTimer)
    clearTimeout(this.searchTimer)
    this.saveFilters()
    Object.values(this.chartInstances).forEach(c => c?.dispose())
  },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    // ===== 导出审计日志（CSV） =====
    exportAudit() {
      const token = localStorage.getItem('access_token') || localStorage.getItem('token') || ''
      const xhr = new XMLHttpRequest()
      xhr.open('GET', '/api/system/audit/export?limit=1000', true)
      if (token) xhr.setRequestHeader('Authorization', 'Bearer ' + token)
      xhr.responseType = 'blob'
      xhr.onload = () => {
        if (xhr.status === 200) {
          const blob = xhr.response
          const a = document.createElement('a')
          a.href = URL.createObjectURL(blob)
          a.download = 'audit-' + new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-') + '.csv'
          document.body.appendChild(a)
          a.click()
          document.body.removeChild(a)
          URL.revokeObjectURL(a.href)
          this.$message.success('审计日志已导出')
        } else {
          this.$message.error('导出失败：' + (xhr.status || '未知错误'))
        }
      }
      xhr.onerror = () => this.$message.error('导出失败，请稍后重试')
      xhr.send()
    },
    // ===== 列表 =====
    async fetchList() {
      this.loading=true; this.listError=''
      try {
        const res=await getLogList({
          page:this.page, limit:this.limit,
          log_type:this.filters.log_type, result:this.filters.result,
          module:this.filters.module, time_cost:this.filters.time_cost,
          user:this.filters.user, keyword:this.filters.keyword,
          method:this.filters.method,
          action:this.filters.action,
          start_date:this.dateRange?.[0]||'', end_date:this.dateRange?.[1]||'',
          sort_field:this.sortField, sort_order:this.sortOrder
        })
        this.list=res.data.list; this.total=res.data.total
        this.todayCount=res.data.today_count; this.monthCount=res.data.month_count
        this.moduleOptions=res.data.modules||[]
      } catch(e) { this.listError='加载失败，请重试' }
      this.loading=false
    },
    debouncedSearch() {
      clearTimeout(this.searchTimer)
      this.searchTimer=setTimeout(()=>{ this.page=1; this.fetchList() }, 500)
    },
    onQuickDateChange(val) {
      const now=new Date(); const fmt=d=>d.toISOString().slice(0,10)
      switch(val){
        case 'today': this.dateRange=[fmt(now),fmt(now)]; break
        case 'yesterday':{const y=new Date(now);y.setDate(y.getDate()-1);this.dateRange=[fmt(y),fmt(y)];break}
        case '7d':{const d7=new Date(now);d7.setDate(d7.getDate()-6);this.dateRange=[fmt(d7),fmt(now)];break}
        case '30d':{const d30=new Date(now);d30.setDate(d30.getDate()-29);this.dateRange=[fmt(d30),fmt(now)];break}
      }
      this.page=1; this.fetchList()
    },
    onDateRangeChange(){ this.quickDate=''; this.page=1; this.fetchList() },
    onSortChange({prop,order}){ this.sortField=prop||'created_at'; this.sortOrder=order==='ascending'?'asc':'desc'; this.fetchList() },
    onPageChange(p){ this.page=p; this.fetchList() },
    onSizeChange(s){ this.limit=s; localStorage.setItem('log_page_size',String(s)); this.page=1; this.fetchList() },
    resetFilters(){ this.filters={log_type:'',result:'',module:'',time_cost:'',user:'',keyword:'',method:''}; this.dateRange=[]; this.quickDate='today'; this.page=1; this.fetchList() },
    removeFilterTag(key){ this.filters[key]=''; this.fetchList() },
    saveFilters(){ localStorage.setItem('log_filters',JSON.stringify({filters:this.filters,dateRange:this.dateRange,page:this.page})) },
    restoreFilters(){
      try{const s=JSON.parse(localStorage.getItem('log_filters'));if(s){this.filters={...this.filters,...s.filters};this.dateRange=s.dateRange||[];this.page=s.page||1}}catch(e){}
    },
    onAutoRefreshChange(val){ clearInterval(this.refreshTimer); if(val>0) this.refreshTimer=setInterval(()=>this.fetchList(),val) },

    // ===== 详情 =====
    async showDetail(row){
      try{const res=await getLogDetail(row.id); this.detailData=res.data; this.detailVisible=true}catch(e){}
    },
    async prevDetail(){if(!this.detailData?.id)return;try{const r=await getNeighborLog(this.detailData.id,'prev');if(r.data)this.detailData=r.data;else this.$message.info('已是第一条')}catch(e){}},
    async nextDetail(){if(!this.detailData?.id)return;try{const r=await getNeighborLog(this.detailData.id,'next');if(r.data)this.detailData=r.data;else this.$message.info('已是最后一条')}catch(e){}},
    formatJson(str){if(!str)return '';try{return JSON.stringify(typeof str==='string'?JSON.parse(str):str,null,2)}catch{return str}},
    copyText(text){if(!text)return;const t=typeof text==='string'?text:JSON.stringify(text);navigator.clipboard?.writeText(t);this.$message.success('已复制')},
    copyFullDetail(){this.copyText(this.detailData);this.$message.success('完整信息已复制')},
    printDetail(){window.print()},
    colVisible(prop){const def=this.columnDefs.find(c=>c.prop===prop);return def?def.visible:true},
    toggleColumn(prop){const saved=localStorage.getItem('log_cols');const vis=saved?JSON.parse(saved):{};vis[prop]=vis[prop]===false?true:false;localStorage.setItem('log_cols',JSON.stringify(vis));this.$forceUpdate()},
    navigateToTarget(row){
  // 模块→路由映射（与 router/index.js 保持一致）
  const routeMap={
    '用户管理':'/users',
    '角色管理':'/roles',
    '权限管理':'/permissions',
  }
  const basePath=routeMap[row.module]
  if(basePath && row.target_id){
    this.$router.push(basePath+'/'+row.target_id)
  }else{
    this.$message.info(`对象: ${row.target_name} (模块: ${row.module}, ID: ${row.target_id})`)
  }
},

    // ===== 统计 =====
    async fetchStatistics(){
      const now=new Date(); const fmt=d=>d.toISOString().slice(0,10); let start,end=fmt(now)
      switch(this.statPeriod){
        case 'today': start=end; break
        case '7d':{const d=new Date(now);d.setDate(d.getDate()-6);start=fmt(d);break}
        case '30d':{const d=new Date(now);d.setDate(d.getDate()-29);start=fmt(d);break}
        case '90d':{const d=new Date(now);d.setDate(d.getDate()-89);start=fmt(d);break}
        default:start=end
      }
      try{
        const res=await getLogStatistics({start_date:start,end_date:end})
        this.statData=res.data
        // 算百分比
        const calcPct=(arr)=>{const t=arr.reduce((s,i)=>s+i.count,0);arr.forEach(i=>{i.percent=t>0?Math.round(i.count/t*100):0})}
        if(this.statData.active_users) calcPct(this.statData.active_users)
        if(this.statData.hot_modules) calcPct(this.statData.hot_modules)
        if(this.statData.action_dist) calcPct(this.statData.action_dist)
        this.$nextTick(()=>this.renderCharts())
      }catch(e){}
    },
    onStatDateChange(){if(this.statDateRange?.length===2){this.statPeriod='';this.fetchStatistics()}},

    // ===== ECharts 渲染 =====
    renderCharts(){
      this.renderTrendChart()
      this.renderPieChart()
      this.renderBarChart()
    },
    renderTrendChart(){
      const el=this.$refs.trendChart; if(!el) return
      if(this.chartInstances.trend) this.chartInstances.trend.dispose()
      const chart=echarts.init(el); this.chartInstances.trend=chart
      const data=this.statData.trend||[]
      const dates=[...new Set(data.map(d=>d.date))]
      const typeMap={1:'操作日志',2:'登录日志',3:'系统运行日志'}
      const series=[1,2,3].map(t=>({
        name:typeMap[t], type:'line', stack:'total', areaStyle:{},
        data:dates.map(d=>{const item=data.find(i=>i.date===d&&i.log_type==t);return item?parseInt(item.count):0})
      }))
      chart.setOption({
        tooltip:{trigger:'axis'},
        legend:{data:['操作日志','登录日志','系统运行日志']},
        xAxis:{type:'category',data:dates},
        yAxis:{type:'value'},
        series
      })
      // 点击数据点→切换到日志列表并应用日期筛选
      chart.on('click', (params)=> {
        if(params.name && dates.includes(params.name)){
          this.dateRange=[params.name, params.name]
          this.quickDate=''
          this.activeTab='list'
          this.fetchList()
        }
      })
    },
    renderPieChart(){
      const el=this.$refs.pieChart; if(!el) return
      if(this.chartInstances.pie) this.chartInstances.pie.dispose()
      const chart=echarts.init(el); this.chartInstances.pie=chart
      const data=(this.statData.action_dist||[]).map(d=>({name:d.action,value:d.count}))
      chart.setOption({
        tooltip:{trigger:'item',formatter:'{b}: {c} ({d}%)'},
        series:[{type:'pie',radius:['30%','60%'],data,label:{formatter:'{b}\n{d}%'}}]
      })
      // 点击扇区→切换到日志列表并应用操作动作筛选
      chart.on('click', (params)=> {
        if(params.name){
          this.filters.action=params.name
          this.activeTab='list'
          this.fetchList()
        }
      })
    },
    renderBarChart(){
      const el=this.$refs.barChart; if(!el) return
      if(this.chartInstances.bar) this.chartInstances.bar.dispose()
      const chart=echarts.init(el); this.chartInstances.bar=chart
      const data=this.statData.login_hourly||[]
      const hours=Array.from({length:24},(_,i)=>i)
      const success=hours.map(h=>{const item=data.find(d=>parseInt(d.hour)===h&&d.response_code===0);return item?parseInt(item.count):0})
      const fail=hours.map(h=>{const item=data.find(d=>parseInt(d.hour)===h&&d.response_code!==0);return item?parseInt(item.count):0})
      const markData=[]
      fail.forEach((v,i)=>{if(v>5) markData.push({xAxis:i,yAxis:v,name:'异常时段',symbol:'pin',symbolSize:30,label:{show:true,formatter:'⚠',color:'red'}})})
      chart.setOption({
        tooltip:{trigger:'axis'},
        legend:{data:['成功','失败']},
        xAxis:{type:'category',data:hours.map(h=>h+'时')},
        yAxis:{type:'value'},
        series:[
          {name:'成功',type:'bar',data:success,itemStyle:{color:'#67c23a'}},
          {name:'失败',type:'bar',data:fail,itemStyle:{color:'#f56c6c'},
            markPoint:{data:markData}}
        ]
      })
    },
    downloadChart(refName){
      const chart=this.chartInstances[refName]; if(!chart) return
      const url=chart.getDataURL({type:'png',pixelRatio:2,backgroundColor:'#fff'})
      const a=document.createElement('a'); a.href=url; a.download=refName+'.png'; a.click()
    },

    // ===== 导出 =====
    async handleExport(){
      // 10000条上限校验（简化：前端预估天数）
      if(this.exportForm.dateRange?.length===2){
        const days=(new Date(this.exportForm.dateRange[1])-new Date(this.exportForm.dateRange[0]))/86400000+1
        if(days>90){this.$message.warning('记录数可能超过导出上限(10000条)，请缩小日期范围');return}
      }
      try{
        await exportLogs({type:this.exportForm.type,format:this.exportForm.format,start_date:this.exportForm.dateRange?.[0]||'',end_date:this.exportForm.dateRange?.[1]||'',fields:this.exportForm.fields?.join(',')})
        this.$message.success('导出任务已创建'); this.fetchExportTasks()
      }catch(e){}
    },
    async fetchExportTasks(){this.exportLoading=true;try{const r=await getExportTasks();this.exportTasks=r.data.list||[]}catch(e){};this.exportLoading=false},
    resetExportForm(){const e=new Date(),s=new Date(e);s.setDate(s.getDate()-29);this.exportForm={type:1,dateRange:[s.toISOString().slice(0,10),e.toISOString().slice(0,10)],format:'excel',fields:['created_at','log_type','username','ip','module','action','target_name','response_code','execution_time','detail','request_params','response_msg']}},
    startExportTimer(){clearInterval(this.exportTimer);this.exportTimer=setInterval(()=>this.fetchExportTasks(),5000)},
    async clearCompletedTasks(){await this.$confirm('确认清空所有已完成的任务记录？','提示',{type:'warning'});this.exportTasks=this.exportTasks.filter(t=>t.status!=='completed');this.$message.success('已清空')},
    downloadUrl(taskId){return '/api/logs/download?task_id='+taskId},

    // ===== 设置 =====
    async fetchSettings(){try{const r=await getLogSettings();if(r.data){
      // 前端兜底转换
      const bools=['enabled','record_get','record_response','auto_clean','notify_before_clean','notify_write_fail','notify_abnormal_login','notify_storage_warning']
      bools.forEach(f=>{if(r.data[f]!==undefined)r.data[f]=r.data[f]===true||r.data[f]==='1'||r.data[f]===1})
      const ints=['max_param_length','retain_days','storage_threshold']
      ints.forEach(f=>{if(r.data[f]!==undefined)r.data[f]=parseInt(r.data[f])||0})
      this.settings={...this.settings,...r.data}
    }}catch(e){}},
    async handleSaveSettings(){try{await saveLogSettings(this.settings);this.$message.success('设置已保存')}catch(e){}},
    async handleResetSettings(){await this.$confirm('确认恢复所有设置为默认值？','提示',{type:'warning'});try{await resetLogSettings();this.$message.success('已恢复默认设置');this.fetchSettings()}catch(e){}},
    async handleClean(){
  try{
    const preview = await cleanLogsPreview(this.settings.retain_days)
    const total = preview.data.total
    const deadline = preview.data.deadline
    if (total === 0) {
      this.$message.info(`${deadline} 之前没有日志需要清理`)
      return
    }
    await this.$confirm(`将删除 ${total} 条 ${deadline} 之前的日志记录，确认继续？`, '提示', { type: 'warning' })
    const r = await cleanLogs(this.settings.retain_days)
    this.$message.success(`已清理 ${r.data.deleted} 条日志`)
    this.fetchList()
  }catch(e){ /* 用户取消或错误 */ }
},

    // ===== 告警 =====
    async fetchAlerts(){try{const r=await getLogAlerts();this.alerts=r.data.alerts||[]}catch(e){}},

    // ===== Tab切换 =====
    handleTabClick(tab){
      if(tab.name==='statistics'){this.fetchStatistics()}
      if(tab.name==='export'){this.fetchExportTasks();this.startExportTimer()}
      if(tab.name==='settings'){this.fetchSettings()}
    },

    // ===== 工具 =====
    logTypeLabel(t){return {1:'操作日志',2:'登录日志',3:'系统运行日志'}[t]||'未知'},
    logTypeTag(t){return {1:'',2:'success',3:'warning'}[t]||'info'},
    statusTag(s){return {pending:'info',processing:'warning',completed:'success',failed:'danger'}[s]||'info'},
    statusLabel(s){return {pending:'排队中',processing:'生成中',completed:'已完成',failed:'已失败'}[s]||s}
  }
}
</script>

<style scoped>
.log-page { padding: 0; }
.page-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:12px; }
.header-actions { display:flex; align-items:center; }
.filter-bar { display:flex; align-items:center; margin-bottom:12px; flex-wrap:wrap; }
.filter-collapse { margin-bottom:12px; }
.filter-tags { padding:8px 0; }
.filter-tags .el-tag { margin-right:6px; margin-bottom:4px; }
.total-count { margin-left:12px; color:#666; font-size:13px; }
.pagination-wrapper { display:flex; align-items:center; justify-content:space-between; padding:16px 0; flex-wrap:wrap; gap:12px; }
.page-info { color:#666; font-size:13px; }
.page-stats { color:#999; font-size:12px; }

.stat-period { margin-bottom:16px; }
.stat-card { text-align:center; }
.stat-card .stat-label { font-size:12px; color:#999; margin-bottom:8px; }
.stat-card .stat-value { font-size:24px; font-weight:bold; color:#333; }
.stat-card .stat-change { font-size:12px; margin-top:4px; }
.stat-card .stat-change.up { color:#67c23a; }
.stat-card .stat-change.down { color:#f56c6c; }

.rank-item { display:flex; align-items:center; gap:8px; padding:4px 0; font-size:13px; }
.rank-num { width:20px; color:#999; }
.rank-name { flex:1; }
.rank-count { color:#666; width:60px; text-align:right; }
.rank-item .el-progress { flex:1; }

.detail-header { padding:8px 0 16px; border-bottom:1px solid #eee; margin-bottom:16px; }
.detail-header .detail-id { font-weight:bold; margin-right:12px; }
.detail-section { margin-bottom:16px; }
.detail-section h4 { font-size:14px; color:#333; margin:0 0 8px; border-bottom:1px solid #f0f0f0; padding-bottom:4px; }
.detail-section label { color:#999; width:100px; display:inline-block; }
.detail-section div { margin-bottom:4px; font-size:13px; }
.json-block { background:#f5f7fa; padding:12px; border-radius:4px; font-size:12px; line-height:1.6; max-height:300px; overflow:auto; white-space:pre-wrap; word-break:break-all; }
</style>
