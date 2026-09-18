<!--
  文件：admin/src/views/hr/salary/config/Index.vue
  功能：工资配置 V2（参考「华能数智 · 工资配置」页面）
  结构：配置列表 + 编辑页（基本设置/工资项目/等级标准/工龄工资/社保公积金 5 Tab）
  权限：hr:salary:config:view/add/edit/delete
-->
<template>
  <div class="wh-page">
    <!-- ===================== 列表视图 ===================== -->
    <template v-if="!editing">
      <el-breadcrumb separator="/" class="breadcrumb">
        <el-breadcrumb-item>人事管理</el-breadcrumb-item>
        <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
        <el-breadcrumb-item>工资配置</el-breadcrumb-item>
      </el-breadcrumb>

      <div class="search-bar">
        <el-form inline size="small" label-width="70px" @submit.native.prevent>
          <el-form-item label="年份">
            <el-select v-model="query.year" clearable placeholder="全部" style="width:120px">
              <el-option v-for="y in yearOptions" :key="y" :label="y + '年'" :value="y" />
            </el-select>
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="query.status" clearable placeholder="全部" style="width:120px">
              <el-option label="草稿" :value="0" /><el-option label="生效" :value="1" /><el-option label="历史" :value="2" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" icon="el-icon-search" @click="loadList">搜索</el-button>
            <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>
      </div>

      <div class="toolbar">
        <div class="toolbar-left">
          <el-button v-permission="'hr:salary:config:add'" type="primary" size="small" icon="el-icon-plus" @click="openCreate">新建配置</el-button>
          <el-button size="small" icon="el-icon-refresh" :loading="listLoading" @click="loadList">刷新</el-button>
        </div>
        <span class="total-text">共 {{ list.length }} 个配置</span>
      </div>

      <el-table :data="list" v-loading="listLoading" size="small" border stripe empty-text="暂无工资配置">
        <el-table-column type="index" label="#" width="55" align="center" />
        <el-table-column prop="config_name" label="配置名称" min-width="180" show-overflow-tooltip />
        <el-table-column label="年份" width="80" align="center"><template slot-scope="s">{{ s.row.config_year }}</template></el-table-column>
        <el-table-column label="月份" width="80" align="center"><template slot-scope="s">{{ s.row.config_month }}月</template></el-table-column>
        <el-table-column label="标准出勤" width="90" align="center"><template slot-scope="s">{{ s.row.standard_work_days }}天</template></el-table-column>
        <el-table-column label="项目" width="70" align="center"><template slot-scope="s">{{ s.row.item_count || 0 }}</template></el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="240" align="center" fixed="right">
          <template slot-scope="s">
            <el-button v-permission="'hr:salary:config:edit'" type="text" size="mini" @click="enterEdit(s.row.id)">编辑</el-button>
            <el-button v-permission="'hr:salary:config:add'" type="text" size="mini" @click="handleCopy(s.row)">复制</el-button>
            <el-button v-if="s.row.config_status !== 1" v-permission="'hr:salary:config:edit'" type="text" size="mini" class="success" @click="handleActivate(s.row)">生效</el-button>
            <el-button v-if="s.row.config_status !== 1" v-permission="'hr:salary:config:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </template>

    <!-- ===================== 编辑视图（5 Tab） ===================== -->
    <template v-else>
      <el-breadcrumb separator="/" class="breadcrumb">
        <el-breadcrumb-item>人事管理</el-breadcrumb-item>
        <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
        <el-breadcrumb-item>工资配置</el-breadcrumb-item>
        <el-breadcrumb-item>{{ detail.config.config_name || '' }}</el-breadcrumb-item>
      </el-breadcrumb>

      <div class="page-header">
        <div class="page-header-left">
          <span class="page-title">{{ detail.config.config_name || '工资配置' }}</span>
          <el-tag :type="statusTag" size="small">{{ statusText }}</el-tag>
          <span class="page-meta">标准出勤 {{ detail.config.standard_work_days }} 天</span>
        </div>
        <div class="page-header-right">
          <el-button size="small" icon="el-icon-back" @click="exitEdit">返回列表</el-button>
          <el-button size="small" icon="el-icon-copy-document" v-if="detail.config.config_status !== 1" @click="handleCopyCurrent">复制配置</el-button>
          <el-button v-if="detail.config.config_status !== 1" size="small" type="success" icon="el-icon-check" @click="handleActivateCurrent">生效配置</el-button>
        </div>
      </div>

      <el-alert type="info" :closable="false" class="std-tip" show-icon>
        💡 员工薪酬标准已在「薪酬标准表」中统一管理，此处无需配置等级标准。
      </el-alert>

      <el-tabs v-model="activeTab" type="border-card" class="cfg-tabs">
        <!-- ===== Tab1 基本设置 ===== -->
        <el-tab-pane label="基本设置" name="basic">
          <el-form :model="basicForm" label-width="110px" size="small" style="max-width:640px;">
            <el-form-item label="配置名称" required>
              <el-input v-model="basicForm.config_name" placeholder="如：2026年1月工资配置" />
            </el-form-item>
            <el-row :gutter="16">
              <el-col :span="12">
                <el-form-item label="适用年份" required>
                  <el-select v-model="basicForm.config_year" style="width:100%" @change="basicYearMonthChange">
                    <el-option v-for="y in yearOptions" :key="y" :label="y + '年'" :value="y" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="适用月份" required>
                  <el-select v-model="basicForm.config_month" style="width:100%" @change="basicYearMonthChange">
                    <el-option v-for="m in 12" :key="m" :label="m + '月'" :value="m" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>
            <el-form-item label="标准出勤天数" required>
              <el-input-number v-model="basicForm.standard_work_days" :min="1" :max="31" disabled /> 天
              <el-tag size="mini" type="success" style="margin-left:8px;">自动</el-tag>
              <div class="form-tip">自动按 {{ basicForm.config_year }}年{{ basicForm.config_month }}月工作日计算（排除周六、周日）</div>
            </el-form-item>
            <el-form-item label="加班规则配置">
              <div class="rate-row">
                <span>工作日加班</span><b style="color:#409EFF">{{ fmtRate(ruleWorkday) }}</b> 倍
                <span>休息日加班</span><b style="color:#409EFF">{{ fmtRate(ruleWeekend) }}</b> 倍
                <span>法定节假日</span><b style="color:#409EFF">{{ fmtRate(ruleHoliday) }}</b> 倍
                <el-button type="text" size="small" icon="el-icon-setting" @click="openOvertimeDialog">配置规则</el-button>
              </div>
              <div class="form-tip">优先级：特殊规则 &gt; 节假日 &gt; 默认规则；支持按日期精确配置节假日与特殊日加班倍数</div>
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="basicForm.remark" type="textarea" :rows="3" placeholder="配置说明" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" size="small" :loading="basicSaving" @click="saveBasic">保存基本设置</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- ===== Tab2 工资项目 ===== -->
        <el-tab-pane label="工资项目" name="items">
          <div class="toolbar">
            <div class="toolbar-left">
              <el-button v-permission="'hr:salary:config:edit'" type="primary" size="small" icon="el-icon-plus" @click="openItemDialog()">新增项目</el-button>
              <el-button size="small" icon="el-icon-refresh" @click="loadDetail">刷新</el-button>
            </div>
            <span class="total-text">共 {{ detail.items.length }} 个项目</span>
          </div>
          <el-table :data="detail.items" size="small" border stripe empty-text="暂无工资项目">
            <el-table-column type="index" label="#" width="55" align="center" />
            <el-table-column prop="item_name" label="项目名称" min-width="120" show-overflow-tooltip />
            <el-table-column prop="item_code" label="项目编码" width="170" class-name="col-code" />
            <el-table-column label="类型" width="80" align="center">
              <template slot-scope="s"><el-tag :type="s.row.item_type === 1 ? 'success' : 'danger'" size="mini">{{ s.row.item_type_text }}</el-tag></template>
            </el-table-column>
            <el-table-column prop="category_text" label="分类" width="100" align="center" />
            <el-table-column prop="calc_text" label="计算方式" width="100" align="center" />
            <el-table-column prop="sort" label="排序" width="70" align="center" />
            <el-table-column label="状态" width="90" align="center">
              <template slot-scope="s"><el-tag :type="s.row.status === 1 ? 'success' : 'info'" size="mini">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag></template>
            </el-table-column>
            <el-table-column label="操作" width="140" align="center" fixed="right">
              <template slot-scope="s">
                <el-button v-permission="'hr:salary:config:edit'" type="text" size="mini" @click="openItemDialog(s.row)">编辑</el-button>
                <el-button v-permission="'hr:salary:config:edit'" type="text" size="mini" class="danger" @click="handleItemDelete(s.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- ===== Tab4 工龄工资 ===== -->
        <el-tab-pane label="工龄工资" name="seniority">
          <div class="toolbar">
            <div class="toolbar-left">
              <span class="toolbar-tip">工龄工资按员工档案入职日期起算，每满 1 年工龄发放固定金额</span>
            </div>
            <div class="toolbar-left">
              <el-button v-permission="'hr:salary:config:edit'" type="primary" size="small" icon="el-icon-edit" @click="openSeniorityDialog">编辑工龄单价</el-button>
            </div>
          </div>
          <div class="seniority-grid">
            <div class="seniority-item">
              <div class="range">每 1 年工龄</div>
              <div class="amount">{{ seniorityAmount }} <span class="unit">元/月</span></div>
            </div>
            <div class="seniority-item">
              <div class="range">示例：工龄 14 年</div>
              <div class="amount">{{ seniorityAmount * 14 }} <span class="unit">元/月</span></div>
            </div>
            <div class="seniority-item">
              <div class="range">示例：工龄 20 年</div>
              <div class="amount">{{ seniorityAmount * 20 }} <span class="unit">元/月</span></div>
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </template>

    <!-- ===== 新建配置弹窗 ===== -->
    <el-dialog title="新建工资配置" :visible.sync="createVisible" width="480px" :close-on-click-modal="false">
      <el-form :model="createForm" label-width="110px" size="small">
        <el-form-item label="配置名称" required>
          <el-input v-model="createForm.config_name" placeholder="如：2026年1月工资配置" />
        </el-form-item>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="适用年份" required>
              <el-select v-model="createForm.config_year" style="width:100%" @change="createYearMonthChange">
                <el-option v-for="y in yearOptions" :key="y" :label="y + '年'" :value="y" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="适用月份" required>
              <el-select v-model="createForm.config_month" style="width:100%" @change="createYearMonthChange">
                <el-option v-for="m in 12" :key="m" :label="m + '月'" :value="m" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="标准出勤天数">
          <el-input-number v-model="createForm.standard_work_days" :min="1" :max="31" disabled /> 天
          <el-tag size="mini" type="success" style="margin-left:8px;">自动</el-tag>
          <div class="form-tip">自动按 {{ createForm.config_year }}年{{ createForm.config_month }}月工作日计算（排除周六、周日）</div>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="createForm.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="createVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="creating" @click="doCreate">创建</el-button>
      </div>
    </el-dialog>

    <!-- ===== 工资项目弹窗 ===== -->
    <el-dialog :title="itemForm.id ? '编辑工资项目' : '新增工资项目'" :visible.sync="itemVisible" width="560px" :close-on-click-modal="false">
      <el-form :model="itemForm" label-width="100px" size="small">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="项目名称" required><el-input v-model="itemForm.item_name" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="项目编码" required><el-input v-model="itemForm.item_code" placeholder="如 basic_wage" /></el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="项目类型" required>
              <el-radio-group v-model="itemForm.item_type">
                <el-radio :label="1">收入项</el-radio>
                <el-radio :label="2">扣除项</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="分类" required>
              <el-select v-model="itemForm.category" style="width:100%">
                <el-option v-for="(t, v) in CATEGORIES" :key="v" :label="t" :value="v" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="计算方式" required>
              <el-select v-model="itemForm.calculation_type" style="width:100%">
                <el-option v-for="(t, v) in CALC_TYPES" :key="v" :label="t" :value="v" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="排序"><el-input-number v-model="itemForm.sort" :min="0" style="width:100%" /></el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="公式表达式">
          <el-input v-model="itemForm.formula_expression" type="textarea" :rows="3" placeholder='{"type":"reference","source":"grade.basic_wage"}' />
        </el-form-item>
        <el-form-item label="默认值">
          <el-input-number v-model="itemForm.default_value" :min="0" :precision="2" style="width:100%" />
          <div class="form-tip">固定值类项目（如洗理费 35 元）在此填写金额</div>
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="itemForm.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="itemVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="saveItem">保存</el-button>
      </div>
    </el-dialog>

    <!-- ===== 工龄单价弹窗 ===== -->
    <el-dialog title="编辑工龄工资单价" :visible.sync="seniorityVisible" width="460px" :close-on-click-modal="false">
      <el-form label-width="120px" size="small">
        <el-form-item label="每 1 年工龄">
          <el-input-number v-model="seniorityAmount" :min="0" :precision="2" style="width:200px" /> 元/月
        </el-form-item>
        <div class="seniority-tip">
          工龄工资 = 工龄年限 × 每 1 年工龄金额<br>
          工龄年限从员工档案「入职日期」起自动计算（不满 1 年按 1 年计）
        </div>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="seniorityVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="saveAdvanced">保存</el-button>
      </div>
    </el-dialog>

    <!-- ===== 加班规则配置弹窗 ===== -->
    <el-dialog title="加班规则配置" :visible.sync="overtimeVisible" width="820px" top="5vh" :close-on-click-modal="false">
      <el-tabs v-model="overtimeTab">
        <!-- Tab1 默认规则 -->
        <el-tab-pane label="默认规则" name="rules">
          <div class="toolbar">
            <div class="toolbar-left"><span class="toolbar-tip">默认规则适用于未配置节假日的普通日期</span></div>
          </div>
          <el-table :data="defaultRules" size="small" border stripe>
            <el-table-column prop="date_type_text" label="加班类型" width="120" align="center" />
            <el-table-column prop="rule_name" label="规则名称" min-width="140" />
            <el-table-column label="加班倍数" width="200" align="center">
              <template slot-scope="s"><el-input-number v-model="s.row.multiplier" :min="0" :max="10" :step="0.5" size="mini" /> 倍</template>
            </el-table-column>
            <el-table-column label="状态" width="90" align="center">
              <template slot-scope="s"><el-switch v-model="s.row.status" :active-value="1" :inactive-value="0" /></template>
            </el-table-column>
          </el-table>
          <div class="ot-actions"><el-button type="primary" size="small" :loading="otSaving" @click="saveDefaultRules">保存默认规则</el-button></div>
        </el-tab-pane>

        <!-- Tab2 日历配置 -->
        <el-tab-pane label="日历配置" name="calendar">
          <div class="cal-toolbar">
            <div class="cal-left">
              <el-select v-model="calYear" size="small" style="width:90px" @change="loadCalendar">
                <el-option v-for="y in calYears" :key="y" :label="y + '年'" :value="y" />
              </el-select>
              <el-select v-model="calMonth" size="small" style="width:80px" @change="loadCalendar">
                <el-option v-for="m in 12" :key="m" :label="m + '月'" :value="m" />
              </el-select>
              <el-button size="small" icon="el-icon-arrow-left" @click="changeCalMonth(-1)" />
              <span class="cal-title">{{ calYear }}年{{ calMonth }}月</span>
              <el-button size="small" icon="el-icon-arrow-right" @click="changeCalMonth(1)" />
            </div>
            <div class="cal-right">
              <el-button v-permission="'hr:salary:config:edit'" size="small" type="primary" icon="el-icon-date" @click="loadNationalHoliday">加载国家节假日</el-button>
              <el-button v-permission="'hr:salary:config:edit'" size="small" icon="el-icon-delete" @click="clearMonth">清空本月</el-button>
              <el-button v-permission="'hr:salary:config:edit'" size="small" icon="el-icon-copy-document" @click="copyLastYear">复制上一年</el-button>
              <el-button size="small" icon="el-icon-download" @click="exportCalendar">导出</el-button>
              <el-button v-permission="'hr:salary:config:edit'" size="small" icon="el-icon-upload2" @click="calImportVisible = true">导入</el-button>
            </div>
          </div>

          <div class="cal-grid">
            <div class="cal-head"><span v-for="(w, i) in weekHeaders" :key="i" class="cal-head-cell">{{ w }}</span></div>
            <div class="cal-body">
              <div v-for="(cell, idx) in calendarCells" :key="idx" class="cal-cell" :class="cellClass(cell)" @click="clickCell(cell)" @dblclick="openCellDialog(cell)">
                <span class="cal-day-num">{{ cell.day || '' }}</span>
                <span v-if="cell.work_type || cell.auto_work_type" class="cal-badge">{{ badgeText(cell) }}</span>
                <span v-if="cell.holiday_name && cell.day" class="cal-name">{{ cell.holiday_name }}</span>
              </div>
            </div>
          </div>

          <div class="cal-footer">
            <div class="cal-legend">
              <span class="legend-item"><i class="legend-dot work-auto"></i>工作日（自动1.5倍）</span>
              <span class="legend-item"><i class="legend-dot rest-auto"></i>休息日（自动2倍）</span>
              <span class="legend-item"><i class="legend-dot work"></i>手动工作日</span>
              <span class="legend-item"><i class="legend-dot rest"></i>手动休息日</span>
              <span class="legend-item"><i class="legend-dot legal"></i>法定节假日（3倍）</span>
            </div>
            <div class="cal-stat" v-if="calendarStats">
              本月共 {{ calendarStats.total }} 天 · 工作日 {{ calendarStats.workday }} 天 · 休息日 {{ calendarStats.weekend }} 天 · 法定节假日 {{ calendarStats.legal_holiday }} 天
            </div>
          </div>
          <div class="cal-tip">💡 单击日期循环切换类型（默认→工作日→休息日→法定假日），双击打开详细配置</div>
        </el-tab-pane>

        <!-- Tab3 特殊规则 -->
        <el-tab-pane label="特殊规则" name="special">
          <div class="toolbar">
            <div class="toolbar-left">
              <span class="toolbar-tip">特殊规则优先级最高，适用于公司自定义特殊日期</span>
              <el-button v-permission="'hr:salary:config:edit'" type="primary" size="small" icon="el-icon-plus" @click="openSpecialDialog()">新增特殊规则</el-button>
            </div>
            <span class="total-text">共 {{ specialRules.length }} 条</span>
          </div>
          <el-table :data="specialRules" size="small" border stripe empty-text="暂无特殊规则">
            <el-table-column prop="rule_name" label="规则名称" min-width="160" />
            <el-table-column label="倍数" width="100" align="center"><template slot-scope="s">{{ s.row.multiplier }} 倍</template></el-table-column>
            <el-table-column label="状态" width="90" align="center">
              <template slot-scope="s"><el-tag :type="s.row.status === 1 ? 'success' : 'info'" size="mini">{{ s.row.status_label }}</el-tag></template>
            </el-table-column>
            <el-table-column label="操作" width="140" align="center">
              <template slot-scope="s">
                <el-button v-permission="'hr:salary:config:edit'" type="text" size="mini" @click="openSpecialDialog(s.row)">编辑</el-button>
                <el-button v-permission="'hr:salary:config:edit'" type="text" size="mini" class="danger" @click="handleSpecialDelete(s.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-dialog>

    <!-- ===== 节假日编辑弹窗 ===== -->
    <el-dialog title="新增/编辑节假日" :visible.sync="holidayDialogVisible" width="460px" :close-on-click-modal="false">
      <el-form :model="holidayForm" label-width="100px" size="small">
        <el-form-item label="日期" required><el-date-picker v-model="holidayForm.holiday_date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="节假日名称" required><el-input v-model="holidayForm.holiday_name" /></el-form-item>
        <el-form-item label="节假日类型">
          <el-radio-group v-model="holidayForm.holiday_type">
            <el-radio :label="1">法定节假日</el-radio>
            <el-radio :label="2">调休日</el-radio>
            <el-radio :label="3">公司特殊日</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="工作日类型">
          <el-radio-group v-model="holidayForm.work_type">
            <el-radio :label="0">默认</el-radio>
            <el-radio :label="1">工作日</el-radio>
            <el-radio :label="2">休息日</el-radio>
            <el-radio :label="3">法定假日</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="加班倍数"><el-input-number v-model="holidayForm.multiplier" :min="0" :max="10" :step="0.5" /> 倍</el-form-item>
        <el-form-item label="备注"><el-input v-model="holidayForm.remark" type="textarea" :rows="2" /></el-form-item>
        <div class="holiday-tip">
          💡 提示：<br>
          • 选择「工作日」：周六/日调休上班，加班按 1.5 倍计算<br>
          • 选择「休息日」：调休休息日，加班按 2 倍计算<br>
          • 选择「法定节假日」：法定假日，加班按 3 倍计算
        </div>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="holidayDialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="otSaving" @click="saveHoliday">保存</el-button>
      </div>
    </el-dialog>

    <!-- ===== 特殊规则编辑弹窗 ===== -->
    <el-dialog title="新增/编辑特殊规则" :visible.sync="specialDialogVisible" width="460px" :close-on-click-modal="false">
      <el-form :model="specialForm" label-width="100px" size="small">
        <el-form-item label="规则名称" required><el-input v-model="specialForm.rule_name" placeholder="如 年终盘点" /></el-form-item>
        <el-form-item label="加班倍数"><el-input-number v-model="specialForm.multiplier" :min="0" :max="10" :step="0.5" /> 倍</el-form-item>
        <el-form-item label="状态"><el-switch v-model="specialForm.status" :active-value="1" :inactive-value="0" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="specialForm.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="specialDialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="otSaving" @click="saveSpecial">保存</el-button>
      </div>
    </el-dialog>

    <!-- ===== 日期配置弹窗 ===== -->
    <el-dialog title="配置日期" :visible.sync="calDialogVisible" width="460px" :close-on-click-modal="false">
      <div class="cal-dialog-title">{{ calForm.date }}（{{ calForm.weekday_label }}）</div>
      <el-form label-width="90px" size="small">
        <el-form-item label="日期类型">
          <el-radio-group v-model="calForm.work_type">
            <el-radio :label="0">默认（按星期判断）</el-radio>
            <el-radio :label="1">工作日（1.5倍加班）</el-radio>
            <el-radio :label="2">休息日（2倍加班）</el-radio>
            <el-radio :label="3">法定节假日（3倍加班）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="节假日名称"><el-input v-model="calForm.holiday_name" placeholder="如：国庆调休上班" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="calForm.remark" type="textarea" :rows="2" /></el-form-item>
        <div class="holiday-tip">
          💡 提示：<br>
          • 选择「工作日」：周六/日调休上班，加班按 1.5 倍计算<br>
          • 选择「休息日」：调休休息日，加班按 2 倍计算<br>
          • 选择「法定节假日」：法定假日，加班按 3 倍计算
        </div>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="calDialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="otSaving" @click="saveCell">保存</el-button>
      </div>
    </el-dialog>

    <!-- ===== 日历导入弹窗 ===== -->
    <el-dialog title="导入节假日配置" :visible.sync="calImportVisible" width="430px" :close-on-click-modal="false">
      <div class="import-box">
        <el-upload drag action="#" :auto-upload="false" :on-change="onCalFileChange" :limit="1" accept=".xlsx,.xls">
          <i class="el-icon-upload"></i>
          <div class="el-upload__text">将 Excel 文件拖到此处，或<em>点击上传</em></div>
        </el-upload>
        <el-radio-group v-model="calImportStrategy" style="margin-top:14px;">
          <el-radio label="skip">跳过已有</el-radio>
          <el-radio label="overwrite">覆盖已有</el-radio>
        </el-radio-group>
        <div class="import-tip">导入模板字段：日期、星期、节假日名称、工作日类型（默认/工作日/休息日/法定节假日）、加班倍数</div>
      </div>
      <div slot="footer">
        <el-button size="small" @click="calImportVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="otSaving" @click="doCalImport">确认导入</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  getSalaryConfigV2List, getSalaryConfigV2Detail, createSalaryConfigV2, updateSalaryConfigV2,
  copySalaryConfigV2, activateSalaryConfigV2, deleteSalaryConfigV2,
  saveSalaryItem, deleteSalaryItem, saveSalaryAdvanced
} from '@/api/salaryConfigV2'
import {
  getOvertimeRules, saveOvertimeRule, getOvertimeHolidays, saveOvertimeHoliday, deleteOvertimeHoliday,
  getOvertimeSpecial, saveOvertimeSpecial, deleteOvertimeSpecial
} from '@/api/overtimeRule'
import request from '@/api/request'

const CATEGORIES = {
  basic_wage: '基本工资', allowance: '津贴', piece: '计件',
  assessment: '考核', insurance: '社保', other: '其它', tax: '税费'
}
const CALC_TYPES = { fixed: '固定值', ratio: '比例', formula: '公式', manual: '手动录入' }

export default {
  name: 'HrSalaryConfigV2',
  data () {
    return {
      CATEGORIES, CALC_TYPES,
      // 列表
      list: [], listLoading: false, editing: false,
      query: { year: '', status: '' },
      yearOptions: (() => { const y = new Date().getFullYear(); return [y + 1, y, y - 1, y - 2, y - 3] })(),
      // 编辑
      currentId: 0, activeTab: 'basic', detailLoading: false,
      detail: { config: {}, items: [], grades: [] },
      basicForm: { config_name: '', config_year: 2026, config_month: 1, standard_work_days: 22, overtime: { sat: 2, sun: 2, holiday: 3 }, remark: '' },
      basicSaving: false,
      // 新建
      createVisible: false, creating: false,
      createForm: { config_name: '', config_year: new Date().getFullYear(), config_month: new Date().getMonth() + 1, standard_work_days: 22, remark: '' },
      // 项目
      itemVisible: false, itemForm: this.emptyItem(),
      // 工龄
      seniorityVisible: false, saving: false,
      seniorityAmount: 20,
      // 加班规则
      overtimeVisible: false, overtimeTab: 'rules', otSaving: false,
      defaultRules: [], holidays: [], holidayYear: new Date().getFullYear(), holidayYears: [],
      holidayDialogVisible: false, holidayForm: {},
      specialRules: [], specialDialogVisible: false, specialForm: {},
      // 日历配置
      calYear: new Date().getFullYear(), calMonth: new Date().getMonth() + 1,
      calYears: (() => { const y = new Date().getFullYear(); return [y + 1, y, y - 1, y - 2] })(),
      calendarCells: [], calendarStats: null, weekHeaders: ['日', '一', '二', '三', '四', '五', '六'],
      calDialogVisible: false, calForm: {},
      calImportVisible: false, calImportStrategy: 'skip', calImportFile: null
    }
  },
  computed: {
    statusText () {
      const s = this.detail.config.config_status
      return s === 1 ? '生效' : (s === 2 ? '历史' : '草稿')
    },
    statusTag () {
      const s = this.detail.config.config_status
      return s === 1 ? 'success' : (s === 2 ? 'info' : 'warning')
    },
    ruleWorkday () { const r = this.defaultRules.find(x => x.date_type === 'workday'); return r ? r.multiplier : 1.5 },
    ruleWeekend () { const r = this.defaultRules.find(x => x.date_type === 'weekend'); return r ? r.multiplier : 2 },
    ruleHoliday () { const r = this.defaultRules.find(x => x.date_type === 'holiday'); return r ? r.multiplier : 3 }
  },
  created () { this.loadList() },
  methods: {
    emptyItem () {
      return { id: 0, item_name: '', item_code: '', item_type: 1, category: 'basic_wage', calculation_type: 'fixed', formula_expression: '', default_value: 0, sort: 0, status: 1 }
    },
    fmtMoney (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    fmtRate (v) { return Number(v || 0).toFixed(2) },
    // ===== 列表 =====
    async loadList () {
      this.listLoading = true
      try {
        const params = {}
        if (this.query.year !== '' && this.query.year !== null) params.year = this.query.year
        if (this.query.status !== '' && this.query.status !== null) params.status = this.query.status
        const r = await getSalaryConfigV2List(params)
        if (r.code === 0 && r.data) this.list = r.data.list || []
      } catch (e) {} finally { this.listLoading = false }
    },
    handleReset () { this.query = { year: '', status: '' }; this.loadList() },
    // 自动计算当月工作日天数（排除周六周日）
    calcWorkDays (year, month) {
      let days = 0
      const total = new Date(year, month, 0).getDate()
      for (let d = 1; d <= total; d++) {
        const w = new Date(year, month - 1, d).getDay()
        if (w !== 0 && w !== 6) days++
      }
      return days
    },
    openCreate () {
      const y = new Date().getFullYear()
      const m = new Date().getMonth() + 1
      this.createForm = { config_name: '', config_year: y, config_month: m, standard_work_days: this.calcWorkDays(y, m), remark: '' }
      this.createVisible = true
    },
    createYearMonthChange () {
      this.createForm.standard_work_days = this.calcWorkDays(this.createForm.config_year, this.createForm.config_month)
    },
    async doCreate () {
      if (!this.createForm.config_name.trim()) { this.$message.warning('请填写配置名称'); return }
      this.creating = true
      try {
        const r = await createSalaryConfigV2({ ...this.createForm, auto_standard_days: 1 })
        if (r.code === 0) { this.$message.success('创建成功'); this.createVisible = false; this.loadList(); this.enterEdit(r.data.id) }
        else this.$message.error(r.msg || '创建失败')
      } catch (e) {} finally { this.creating = false }
    },
    // ===== 编辑 =====
    async enterEdit (id) {
      this.currentId = id
      this.activeTab = 'basic'
      this.editing = true
      await this.loadDetail()
    },
    async loadDetail () {
      this.detailLoading = true
      try {
        const r = await getSalaryConfigV2Detail(this.currentId)
        if (r.code === 0 && r.data) {
          this.detail = r.data
          const cfg = r.data.config || {}
          const y = cfg.config_year || 2026
          const m = cfg.config_month || 1
          this.basicForm = {
            config_name: cfg.config_name || '', config_year: y, config_month: m,
            standard_work_days: this.calcWorkDays(y, m),
            overtime: cfg.overtime_rates_obj || { sat: 2, sun: 2, holiday: 3 },
            remark: cfg.remark || ''
          }
          this.seniorityAmount = cfg.seniority_amount_per_year || 20
        }
      } catch (e) {} finally { this.detailLoading = false }
    },
    exitEdit () { this.editing = false; this.loadList() },
    async saveBasic () {
      if (!this.basicForm.config_name.trim()) { this.$message.warning('请填写配置名称'); return }
      this.basicSaving = true
      try {
        const r = await updateSalaryConfigV2(this.currentId, {
          config_name: this.basicForm.config_name, config_year: this.basicForm.config_year,
          config_month: this.basicForm.config_month, auto_standard_days: 1,
          standard_work_days: this.basicForm.standard_work_days,
          overtime_rates: JSON.stringify(this.basicForm.overtime), remark: this.basicForm.remark
        })
        if (r.code === 0) { this.$message.success('保存成功'); this.loadDetail() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.basicSaving = false }
    },
    basicYearMonthChange () {
      this.basicForm.standard_work_days = this.calcWorkDays(this.basicForm.config_year, this.basicForm.config_month)
    },
    // ===== 复制/生效/删除 =====
    async handleCopy (row) {
      this.$confirm(`确认复制配置「${row.config_name}」吗？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await copySalaryConfigV2(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '复制成功'); this.loadList() } else this.$message.error(r.msg || '复制失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleCopyCurrent () { this.handleCopy({ id: this.currentId, config_name: this.detail.config.config_name }) },
    async handleActivate (row) {
      this.$confirm(`确认使配置「${row.config_name}」生效？生效后将覆盖同月份的其他配置。`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await activateSalaryConfigV2(row.id)
          if (r.code === 0) { this.$message.success('配置已生效'); this.loadList(); if (this.editing && this.currentId === row.id) this.loadDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleActivateCurrent () { this.handleActivate({ id: this.currentId, config_name: this.detail.config.config_name }) },
    async handleDelete (row) {
      this.$confirm(`确认删除配置「${row.config_name}」吗？删除后不可恢复！`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteSalaryConfigV2(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); if (this.editing && this.currentId === row.id) this.exitEdit(); else this.loadList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    // ===== 工资项目 =====
    openItemDialog (row) { this.itemForm = row ? { ...row, formula_expression: row.formula_expression || '' } : this.emptyItem(); this.itemVisible = true },
    async saveItem () {
      if (!this.itemForm.item_name.trim()) { this.$message.warning('请填写项目名称'); return }
      if (!this.itemForm.item_code.trim()) { this.$message.warning('请填写项目编码'); return }
      this.saving = true
      try {
        const r = await saveSalaryItem({ ...this.itemForm, config_id: this.currentId })
        if (r.code === 0) { this.$message.success('保存成功'); this.itemVisible = false; this.loadDetail() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    },
    handleItemDelete (row) {
      this.$confirm(`确认删除工资项目「${row.item_name}」吗？删除后不可恢复！`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteSalaryItem(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadDetail() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    // ===== 工龄 =====
    openSeniorityDialog () { this.seniorityVisible = true },
    async saveAdvanced () {
      this.saving = true
      try {
        const data = { config_id: this.currentId }
        if (this.seniorityVisible) data.seniority_amount_per_year = this.seniorityAmount
        const r = await saveSalaryAdvanced(data)
        if (r.code === 0) {
          this.$message.success('保存成功')
          this.seniorityVisible = false
          this.loadDetail()
        } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    },
    // ===== 加班规则 =====
    async openOvertimeDialog () {
      this.overtimeVisible = true
      this.overtimeTab = 'rules'
      await Promise.all([this.loadDefaultRules(), this.loadCalendar(), this.loadSpecial()])
    },
    async loadDefaultRules () {
      try {
        const r = await getOvertimeRules()
        if (r.code === 0) this.defaultRules = r.data || []
      } catch (e) {}
    },
    async saveDefaultRules () {
      this.otSaving = true
      try {
        for (const rule of this.defaultRules) {
          const r = await saveOvertimeRule({ id: rule.id, rule_name: rule.rule_name, date_type: rule.date_type, multiplier: rule.multiplier, status: rule.status })
          if (r.code !== 0) { this.$message.error(r.msg || '保存失败'); this.otSaving = false; return }
        }
        this.$message.success('默认规则已保存')
        await this.loadDefaultRules()
      } catch (e) {} finally { this.otSaving = false }
    },
    async loadHolidays () {
      try {
        const r = await getOvertimeHolidays({ year: this.holidayYear })
        if (r.code === 0 && r.data) {
          this.holidays = r.data.list || []
          if (r.data.years && r.data.years.length) this.holidayYears = r.data.years
        }
      } catch (e) {}
    },
    openHolidayDialog (row) {
      this.holidayForm = row ? { id: row.id, holiday_date: row.holiday_date, holiday_name: row.holiday_name, holiday_type: row.holiday_type, work_type: row.work_type || 0, multiplier: Number(row.multiplier), remark: row.remark || '' }
        : { id: 0, holiday_date: '', holiday_name: '', holiday_type: 1, work_type: 0, multiplier: 3, remark: '' }
      this.holidayDialogVisible = true
    },
    workTypeTag (t) { return { 0: 'info', 1: 'primary', 2: 'success', 3: 'danger' }[t] || 'info' },
    async saveHoliday () {
      if (!this.holidayForm.holiday_date) { this.$message.warning('请选择日期'); return }
      if (!this.holidayForm.holiday_name.trim()) { this.$message.warning('请填写节假日名称'); return }
      this.otSaving = true
      try {
        const r = await saveOvertimeHoliday(this.holidayForm)
        if (r.code === 0) { this.$message.success('保存成功'); this.holidayDialogVisible = false; this.loadHolidays() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.otSaving = false }
    },
    handleHolidayDelete (row) {
      this.$confirm(`确认删除节假日「${row.holiday_name}（${row.holiday_date}）」吗？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteOvertimeHoliday(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadHolidays() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async loadSpecial () {
      try {
        const r = await getOvertimeSpecial()
        if (r.code === 0) this.specialRules = r.data || []
      } catch (e) {}
    },
    openSpecialDialog (row) {
      this.specialForm = row ? { id: row.id, rule_name: row.rule_name, multiplier: Number(row.multiplier), status: row.status, remark: row.remark || '' }
        : { id: 0, rule_name: '', multiplier: 2, status: 1, remark: '' }
      this.specialDialogVisible = true
    },
    async saveSpecial () {
      if (!this.specialForm.rule_name.trim()) { this.$message.warning('请填写规则名称'); return }
      this.otSaving = true
      try {
        const r = await saveOvertimeSpecial(this.specialForm)
        if (r.code === 0) { this.$message.success('保存成功'); this.specialDialogVisible = false; this.loadSpecial() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.otSaving = false }
    },
    handleSpecialDelete (row) {
      this.$confirm(`确认删除特殊规则「${row.rule_name}」吗？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteOvertimeSpecial(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadSpecial() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    // ===== 日历配置 =====
    async loadCalendar () {
      try {
        const r = await request({ url: '/salary/overtime/calendar', method: 'get', params: { year: this.calYear, month: this.calMonth } })
        if (r.code === 0 && r.data) {
          const days = r.data.days || []
          const dayMap = {}
          days.forEach(d => { dayMap[d.day] = d })
          const firstDay = new Date(this.calYear, this.calMonth - 1, 1).getDay()
          const total = new Date(this.calYear, this.calMonth, 0).getDate()
          const cells = []
          // 上月补位
          const prevTotal = new Date(this.calYear, this.calMonth - 1, 0).getDate()
          for (let i = firstDay - 1; i >= 0; i--) {
            const pd = prevTotal - i
            const pm = this.calMonth === 1 ? 12 : this.calMonth - 1
            const py = this.calMonth === 1 ? this.calYear - 1 : this.calYear
            cells.push({ day: pd, date: `${py}-${String(pm).padStart(2, '0')}-${String(pd).padStart(2, '0')}`, work_type: 0, is_current_month: false })
          }
          for (let d = 1; d <= total; d++) {
            const item = dayMap[d] || { day: d, work_type: 0, holiday_name: null, is_today: false }
            cells.push({ ...item, is_current_month: true })
          }
          // 下月补位到 42 格
          let next = 1
          while (cells.length < 42) {
            const nm = this.calMonth === 12 ? 1 : this.calMonth + 1
            const ny = this.calMonth === 12 ? this.calYear + 1 : this.calYear
            cells.push({ day: next, date: `${ny}-${String(nm).padStart(2, '0')}-${String(next).padStart(2, '0')}`, work_type: 0, is_current_month: false })
            next++
          }
          this.calendarCells = cells
          this.calendarStats = r.data.statistics
        }
      } catch (e) {}
    },
    changeCalMonth (delta) {
      let m = this.calMonth + delta
      let y = this.calYear
      if (m < 1) { m = 12; y-- }
      if (m > 12) { m = 1; y++ }
      this.calYear = y
      this.calMonth = m
      this.loadCalendar()
    },
    cellClass (cell) {
      const cls = []
      if (!cell.is_current_month) cls.push('cal-other')
      if (cell.is_today) cls.push('cal-today')
      const t = cell.work_type || cell.auto_work_type || 0
      const manual = !!cell.work_type
      if (t === 1) cls.push(manual ? 'cal-work' : 'cal-work-auto')
      else if (t === 2) cls.push(manual ? 'cal-rest' : 'cal-rest-auto')
      else if (t === 3) cls.push('cal-legal')
      return cls
    },
    badgeText (cell) {
      const t = cell.work_type || cell.auto_work_type || 0
      return { 1: '班', 2: '休', 3: '法' }[t] || ''
    },
    clickCell (cell) {
      if (!cell.is_current_month) return
      // 循环切换：默认0 → 工作日1 → 休息日2 → 法定3 → 默认0
      const next = ((cell.work_type || 0) + 1) % 4
      const date = cell.date || `${this.calYear}-${String(this.calMonth).padStart(2, '0')}-${String(cell.day).padStart(2, '0')}`
      cell.work_type = next
      if (next === 0) cell.holiday_name = null
      this.saveCellDate(date, next, cell.holiday_name || '')
    },
    openCellDialog (cell) {
      if (!cell.is_current_month) return
      const date = cell.date || `${this.calYear}-${String(this.calMonth).padStart(2, '0')}-${String(cell.day).padStart(2, '0')}`
      const w = ['日', '一', '二', '三', '四', '五', '六'][new Date(date).getDay()]
      this.calForm = { date, weekday_label: '周' + w, work_type: cell.work_type || 0, holiday_name: cell.holiday_name || '', remark: '' }
      this.calDialogVisible = true
    },
    async saveCell () {
      this.otSaving = true
      try {
        const r = await request({ url: '/salary/overtime/calendar/update', method: 'post', data: { date: this.calForm.date, work_type: this.calForm.work_type, holiday_name: this.calForm.holiday_name, remark: this.calForm.remark } })
        if (r.code === 0) { this.$message.success('保存成功'); this.calDialogVisible = false; this.loadCalendar() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.otSaving = false }
    },
    async saveCellDate (date, workType, name) {
      try {
        await request({ url: '/salary/overtime/calendar/update', method: 'post', data: { date, work_type: workType, holiday_name: name } })
        this.loadCalendar()
      } catch (e) {}
    },
    clearMonth () {
      this.$confirm('确认清空当前月份所有配置？清空后将恢复默认。', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await request({ url: '/salary/overtime/calendar/clear-month', method: 'delete', params: { year: this.calYear, month: this.calMonth } })
          if (r.code === 0) { this.$message.success('已清空本月配置'); this.loadCalendar() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    copyLastYear () {
      this.$confirm(`确认将 ${this.calYear - 1} 年的节假日配置复制到 ${this.calYear} 年？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await request({ url: '/salary/overtime/calendar/copy-last-year', method: 'post', data: { year: this.calYear } })
          if (r.code === 0) { this.$message.success(r.msg || '复制成功'); this.loadCalendar() } else this.$message.error(r.msg || '复制失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async exportCalendar () {
      try {
        const r = await request({ url: '/salary/overtime/calendar/export', method: 'get', params: { year: this.calYear }, responseType: 'blob' })
        const blob = new Blob([r.data], { type: 'text/csv;charset=utf-8' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `节假日配置_${this.calYear}.csv`
        a.click()
        URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败') }
    },
    loadNationalHoliday () {
      this.$confirm(`将自动加载国家法定节假日配置到 ${this.calYear} 年（自动识别调休上班/休息日/法定假日），已有的用户手动配置将保留，是否继续？`, '加载国家节假日', { type: 'info' }).then(async () => {
        this.otSaving = true
        try {
          const r = await request({ url: '/salary/overtime/calendar/sync-national', method: 'post', data: { year: this.calYear, force: 0 } })
          if (r.code === 0) {
            this.$message.success(`${r.msg || '加载成功'}：新增${r.data.inserted}，更新${r.data.updated}，跳过${r.data.skipped}`)
            this.loadCalendar()
          } else this.$message.error(r.msg || '加载失败')
        } catch (e) { this.$message.error('加载失败，请检查网络') } finally { this.otSaving = false }
      }).catch(() => {})
    },
    onCalFileChange (file) { this.calImportFile = file.raw },
    async doCalImport () {
      if (!this.calImportFile) { this.$message.warning('请选择 Excel 文件'); return }
      this.otSaving = true
      try {
        const fd = new FormData()
        fd.append('file', this.calImportFile)
        fd.append('conflict_strategy', this.calImportStrategy)
        const r = await request({ url: '/salary/overtime/calendar/import', method: 'post', data: fd })
        if (r.code === 0) { this.$message.success(r.msg || '导入成功'); this.calImportVisible = false; this.calImportFile = null; this.loadCalendar() } else this.$message.error(r.msg || '导入失败')
      } catch (e) { this.$message.error('导入失败') } finally { this.otSaving = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; align-items: center; }
.toolbar-tip { font-size: 13px; color: #5a6f86; }
.total-text { color: #909399; font-size: 14px; }
.danger { color: #F56C6C; }
.success { color: #67C23A; }
.col-code { font-family: 'Courier New', monospace; color: #5a6f86; }

/* 编辑页头部 */
.page-header { display: flex; justify-content: space-between; align-items: center; margin: 12px 0; flex-wrap: wrap; gap: 10px; }
.page-header-left { display: flex; align-items: center; gap: 12px; }
.page-title { font-size: 20px; font-weight: 600; color: #0b1e33; }
.page-meta { font-size: 13px; color: #909399; }
.page-header-right { display: flex; gap: 8px; }
.cfg-tabs { border-radius: 12px; }

/* 加班费率 */
.rate-row { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; font-size: 13px; color: #5a6f86; }
.form-tip { font-size: 12px; color: #909399; line-height: 1.6; margin-top: 4px; }
.std-tip { margin-bottom: 12px; }
.ot-actions { margin-top: 14px; text-align: right; }
.holiday-tip { font-size: 12px; color: #909399; line-height: 1.8; background: #f5f7fa; border-radius: 8px; padding: 10px 14px; }

/* 日历配置 */
.cal-toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; flex-wrap: wrap; gap: 8px; }
.cal-left { display: flex; align-items: center; gap: 8px; }
.cal-right { display: flex; gap: 6px; }
.cal-title { font-size: 15px; font-weight: 600; color: #1a2332; min-width: 90px; text-align: center; }
.cal-grid { border: 1px solid #e8ecf1; border-radius: 10px; overflow: hidden; }
.cal-head { display: grid; grid-template-columns: repeat(7, 1fr); background: #f8fafc; border-bottom: 1px solid #e8ecf1; }
.cal-head-cell { text-align: center; padding: 8px 0; font-size: 12px; color: #8a9aa8; font-weight: 600; }
.cal-body { display: grid; grid-template-columns: repeat(7, 1fr); }
.cal-cell { min-height: 62px; border-right: 1px solid #f0f2f4; border-bottom: 1px solid #f0f2f4; padding: 6px 8px; cursor: pointer; position: relative; transition: 0.15s; display: flex; flex-direction: column; align-items: center; }
.cal-cell:nth-child(7n) { border-right: none; }
.cal-cell:hover { box-shadow: inset 0 0 0 2px rgba(64,158,255,0.3); }
.cal-cell.cal-other { background: #fafbfc; color: #c0c4cc; cursor: not-allowed; }
.cal-day-num { font-size: 14px; font-weight: 500; }
.cal-badge { margin-top: 2px; font-size: 11px; color: #fff; padding: 1px 8px; border-radius: 10px; }
.cal-name { font-size: 10px; color: rgba(255,255,255,0.9); margin-top: 2px; max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.cal-cell.cal-work { background: #409EFF; color: #fff; }
.cal-cell.cal-rest { background: #67C23A; color: #fff; }
.cal-cell.cal-legal { background: #F56C6C; color: #fff; }
.cal-cell.cal-work-auto { background: #e8f3ff; color: #409EFF; }
.cal-cell.cal-rest-auto { background: #eaf7ec; color: #67C23A; }
.cal-cell.cal-work-auto .cal-badge, .cal-cell.cal-rest-auto .cal-badge { background: transparent; color: inherit; font-weight: 600; }
.cal-cell.cal-today { box-shadow: inset 0 0 0 2px #e6a23c; }
.cal-footer { display: flex; justify-content: space-between; align-items: center; margin-top: 12px; flex-wrap: wrap; gap: 8px; }
.cal-legend { display: flex; gap: 14px; flex-wrap: wrap; font-size: 12px; color: #5a6f86; }
.legend-item { display: flex; align-items: center; gap: 4px; }
.legend-dot { width: 12px; height: 12px; border-radius: 3px; display: inline-block; border: 1px solid #e0e4ea; }
.legend-dot.def { background: #fff; }
.legend-dot.work { background: #409EFF; }
.legend-dot.rest { background: #67C23A; }
.legend-dot.legal { background: #F56C6C; }
.legend-dot.work-auto { background: #e8f3ff; border-color: #409EFF; }
.legend-dot.rest-auto { background: #eaf7ec; border-color: #67C23A; }
.cal-stat { font-size: 12px; color: #8a9aa8; }
.cal-tip { font-size: 12px; color: #909399; margin-top: 8px; }
.cal-dialog-title { font-size: 15px; font-weight: 600; color: #1a2332; margin-bottom: 12px; }
.import-box { text-align: center; }
.import-tip { font-size: 12px; color: #909399; margin-top: 12px; line-height: 1.7; text-align: left; }

/* 工龄阶梯 */
.seniority-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.seniority-item { background: #f8fafc; border-radius: 10px; padding: 18px; text-align: center; border: 1px solid #e8ecf1; }
.seniority-item .range { font-size: 14px; font-weight: 500; color: #1a2332; }
.seniority-item .amount { font-size: 22px; font-weight: 600; color: #409EFF; margin-top: 6px; }
.seniority-item .amount .unit { font-size: 13px; font-weight: 400; color: #8a9aa8; }
.seniority-tip { font-size: 12px; color: #909399; line-height: 1.8; background: #f5f7fa; border-radius: 8px; padding: 10px 14px; margin-top: 4px; }

@media (max-width: 1024px) {
  .seniority-grid { grid-template-columns: 1fr 1fr; }
}
@media (max-width: 640px) {
  .seniority-grid { grid-template-columns: 1fr; }
}
</style>
