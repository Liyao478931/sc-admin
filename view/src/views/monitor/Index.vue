<template>
  <div class="monitor-page" :style="{background:'linear-gradient(135deg,#0a0e27 0%,#0d1117 100%)'}">
    <div class="header-row">
      <div><h1 class="page-title">系统监控</h1><p class="page-subtitle">实时监控系统运行状态 · 数据更新于 {{ lastUpdate }}</p></div>
      <div class="header-actions">
        <el-select v-model="refreshInterval" size="small" style="width:120px;margin-right:8px" @change="changeInterval">
          <el-option label="关闭" :value="0" /><el-option label="10秒" :value="10000" /><el-option label="30秒" :value="30000" />
          <el-option label="60秒" :value="60000" /><el-option label="120秒" :value="120000" />
        </el-select>
        <el-button v-if="hasPerm('monitor:saveAlarmSettings')" size="small" circle icon="el-icon-setting" @click="showAlarm=true" title="告警配置" style="background:rgba(255,255,255,0.08);border-color:rgba(255,255,255,0.15);color:#fff" />
      </div>
    </div>
    <!-- 核心指标卡片 -->
    <div class="cards-row">
      <div class="glass-card card-cpu"><div class="card-body"><div class="ring-wrap"><svg viewBox="0 0 120 120" class="ring-svg"><circle cx="60" cy="60" r="52" fill="none" stroke="rgba(255,255,255,0.06)" stroke-width="8"/><circle cx="60" cy="60" r="52" fill="none" :stroke="cpuColor" stroke-width="8" stroke-linecap="round" :stroke-dasharray="circum" :stroke-dashoffset="circum*(1-ov.cpu_usage/100)" transform="rotate(-90,60,60)" class="ring-circle"/></svg><span class="ring-value" :style="{color:cpuColor}">{{ ov.cpu_usage }}<small>%</small></span></div><div class="card-right"><div class="card-title">CPU 使用率</div><div class="card-info">频率 2.4 GHz · {{ ov.num_cores||'--' }} 核</div><div class="card-footer">负载 {{ ov.cpu_load_1 }}/{{ ov.cpu_load_5 }}/{{ ov.cpu_load_15 }}</div></div></div></div>
      <div class="glass-card card-mem"><div class="card-body"><div class="ring-wrap"><svg viewBox="0 0 120 120" class="ring-svg"><circle cx="60" cy="60" r="52" fill="none" stroke="rgba(255,255,255,0.06)" stroke-width="8"/><circle cx="60" cy="60" r="52" fill="none" :stroke="memColor" stroke-width="8" stroke-linecap="round" :stroke-dasharray="circum" :stroke-dashoffset="circum*(1-ov.memory_usage/100)" transform="rotate(-90,60,60)" class="ring-circle"/></svg><span class="ring-value" :style="{color:memColor}">{{ ov.memory_usage }}<small>%</small></span></div><div class="card-right"><div class="card-title">内存使用率</div><div class="card-info">已用 {{ fmtSize(ov.memory_used) }} / {{ fmtSize(ov.memory_total) }}</div><div class="card-footer">Swap {{ ov.swap_usage }}%</div></div></div></div>
      <div class="glass-card card-dsk"><div class="card-body"><div class="ring-wrap"><svg viewBox="0 0 120 120" class="ring-svg"><circle cx="60" cy="60" r="52" fill="none" stroke="rgba(255,255,255,0.06)" stroke-width="8"/><circle cx="60" cy="60" r="52" fill="none" :stroke="dskColor" stroke-width="8" stroke-linecap="round" :stroke-dasharray="circum" :stroke-dashoffset="circum*(1-ov.disk_usage/100)" transform="rotate(-90,60,60)" class="ring-circle"/></svg><span class="ring-value" :style="{color:dskColor}">{{ ov.disk_usage }}<small>%</small></span></div><div class="card-right"><div class="card-title">磁盘使用率</div><div class="card-info">已用 {{ fmtSize(ov.disk_used) }} / {{ fmtSize(ov.disk_total) }}</div><div class="card-footer">读 {{ fmtSpeed(ov.disk_read) }}/s · 写 {{ fmtSpeed(ov.disk_write) }}/s</div></div></div></div>
      <div class="glass-card card-sts"><div class="card-body" style="justify-content:center"><div style="text-align:center"><div style="display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:8px"><span class="status-dot" :style="{background:statusColor}"></span><span class="status-text" :style="{color:statusColor}">运行中</span></div><div class="card-info">{{ ov.uptime }}</div><div class="card-footer" style="margin-top:8px;font-size:12px;color:rgba(255,255,255,0.45);line-height:1.8">在线用户 {{ appInfo.online_users||0 }} · PHP {{ sysInfo.php_version }}<br>MySQL {{ sysInfo.mysql_version }}</div></div></div></div>
    </div>
    <!-- 趋势图表 2x2 -->
    <div class="charts-grid">
      <div class="glass-card chart-card" v-for="ch in charts" :key="ch.key">
        <div class="chart-header"><span>{{ ch.title }}</span>
          <el-select v-model="ch.range" size="mini" style="width:100px" @change="()=>loadTrend(ch)">
            <el-option label="近1小时" value="1h" /><el-option label="近6小时" value="6h" /><el-option label="近24小时" value="24h" /><el-option label="近7天" value="7d" />
          </el-select>
        </div>
        <div :id="'chart-'+ch.key" style="width:100%;height:180px"></div>
      </div>
    </div>
    <!-- 底部双栏 -->
    <div class="bottom-row">
      <div class="glass-card" style="flex:1"><h3 class="sec-title">系统信息</h3>
        <div class="info-grid">
          <div><label>系统名称</label><span>{{ appInfo.app_name }}</span></div>
          <div><label>版本</label><span>{{ appInfo.version }}</span></div>
          <div><label>运行时长</label><span>{{ appInfo.runtime }}</span></div>
          <div><label>环境</label><span><el-tag :type="appInfo.env_type||'success'" size="mini" effect="dark">{{ appInfo.env_label||'生产' }}</el-tag></span></div>
          <div><label>主机名</label><span>{{ appInfo.hostname }}</span></div>
          <div><label>后端框架</label><span>{{ appInfo.framework }}</span></div>
          <div><label>前端框架</label><span>{{ appInfo.frontend_framework }}</span></div>
          <div><label>队列驱动</label><span>{{ appInfo.queue_driver }}</span></div>
          <div><label>存储驱动</label><span>{{ appInfo.storage_driver }}</span></div>
          <div><label>数据库</label><span :style="{color:appInfo.db_connected?'#67C23A':'#F56C6C'}">● {{ appInfo.db_connected?'已连接':'断开' }} {{ appInfo.db_latency_ms?`(${appInfo.db_latency_ms}ms)`:'' }}</span></div>
          <div><label>Redis</label><span :style="{color:appInfo.redis_connected?'#67C23A':'#F56C6C'}">● {{ appInfo.redis_connected?'已连接':'断开' }} {{ appInfo.redis_latency_ms?`(${appInfo.redis_latency_ms}ms)`:'' }}</span></div>
          <div style="grid-column:1/-1;border-top:1px solid rgba(255,255,255,0.06);padding-top:8px;margin-top:4px"></div>
          <div><label>操作系统</label><span>{{ sysInfo.os }}</span></div>
          <div><label>内核</label><span>{{ sysInfo.kernel }}</span></div>
          <div><label>PHP</label><span>{{ sysInfo.php_version }} ({{ sysInfo.php_mode }})</span></div>
          <div><label>Web</label><span>{{ sysInfo.web_server }}</span></div>
          <div><label>MySQL</label><span>{{ sysInfo.mysql_version }}</span></div>
          <div><label>Redis</label><span>{{ sysInfo.redis_version }}</span></div>
          <div><label>服务器时间</label><span>{{ sysInfo.server_time }}</span></div>
          <div><label>时区</label><span>{{ sysInfo.timezone }}</span></div>
        </div>
      </div>
      <div class="glass-card" style="flex:1;display:flex;flex-direction:column;min-height:0;background:rgba(15,15,35,0.5)">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;cursor:pointer" @click="showProcesses=!showProcesses">
          <h3 class="sec-title" style="margin:0">进程管理 ({{ processes.length }}) <i :class="showProcesses?'el-icon-arrow-down':'el-icon-arrow-right'" style="font-size:12px;color:rgba(255,255,255,0.4)"></i></h3>
          <el-input v-if="showProcesses" v-model="procSearch" size="mini" placeholder="搜索进程名" style="width:200px" prefix-icon="el-icon-search" clearable @click.stop />
        </div>
        <div v-show="showProcesses" style="flex:1;overflow:auto;min-height:0">
          <div style="overflow:auto;max-height:500px">
          <el-table :data="filteredProcs" size="mini" border stripe style="width:max-content;min-width:100%" @sort-change="s=>procSort={p:s.prop,o:s.order}" @row-click="showProcDetail">
            <el-table-column prop="pid" label="PID" width="60" sortable="custom" />
            <el-table-column prop="name" label="进程名" min-width="110" />
            <el-table-column prop="cpu_percent" label="CPU%" width="80" sortable="custom"><template slot-scope="{row}"><el-progress :percentage="Math.min(row.cpu_percent*5,100)" :stroke-width="6" size="small" :color="row.cpu_percent>10?'#F56C6C':'#67C23A'" :format="()=>row.cpu_percent+'%'" /></template></el-table-column>
            <el-table-column prop="memory_rss_format" label="内存" width="80" sortable="custom" />
            <el-table-column prop="state" label="状态" width="80">
              <template slot-scope="{row}"><el-tag :type="stateType(row.state)" size="mini" effect="dark">{{ row.state }}</el-tag></template>
            </el-table-column>
            <el-table-column prop="start_time" label="启动时间" width="145" />
            <el-table-column label="操作" width="70">
              <template slot-scope="{row}"><el-button v-if="hasPerm('monitor:killProcess')" size="mini" type="danger" @click.stop="confirmKill(row)">终止</el-button></template>
            </el-table-column>
          </el-table>
          </div>
        </div>
    </div>
    <!-- 进程详情弹窗 -->
    <el-dialog title="进程详情" :visible.sync="showProcDlg" width="550px">
      <div v-if="procDetail" class="proc-detail-grid">
        <div><label>进程ID</label><span>{{ procDetail.pid }}</span></div>
        <div><label>进程名</label><span>{{ procDetail.name }}</span></div>
        <div style="grid-column:1/-1"><label>命令行</label><span style="font-family:Consolas,monospace;font-size:12px;word-break:break-all">{{ procDetail.cmdline }}</span></div>
        <div><label>CPU使用率</label><span>{{ procDetail.cpu_percent }}%</span></div>
        <div><label>内存占用</label><span>{{ procDetail.memory_rss_format }}</span></div>
        <div><label>状态</label><span><el-tag :type="stateType(procDetail.state)" size="mini" effect="dark">{{ procDetail.state }}</el-tag></span></div>
        <div><label>启动时间</label><span>{{ procDetail.start_time }}</span></div>
      </div>
    </el-dialog>
    <!-- 告警配置弹窗 -->
    <el-dialog title="告警配置" :visible.sync="showAlarm" width="720px" :close-on-click-modal="false" custom-class="alarm-dialog">
      <el-tabs v-model="alarmTab">
        <el-tab-pane label="告警规则" name="rules">
          <el-form label-width="160px" size="small">
            <el-form-item label="启用CPU告警"><el-switch v-model="alarmForm.cpu_enabled" /></el-form-item>
            <el-form-item v-if="alarmForm.cpu_enabled" label="CPU使用率阈值(%)"><el-input-number v-model="alarmForm.cpu_threshold" :min="1" :max="100" style="width:100%" /></el-form-item>
            <el-form-item v-if="alarmForm.cpu_enabled" label="持续分钟"><el-input-number v-model="alarmForm.cpu_duration" :min="1" :max="60" style="width:100%" /></el-form-item>
            <el-form-item label="启用内存告警"><el-switch v-model="alarmForm.memory_enabled" /></el-form-item>
            <el-form-item v-if="alarmForm.memory_enabled" label="内存使用率阈值(%)"><el-input-number v-model="alarmForm.memory_threshold" :min="1" :max="100" style="width:100%" /></el-form-item>
            <el-form-item label="启用磁盘告警"><el-switch v-model="alarmForm.disk_enabled" /></el-form-item>
            <el-form-item v-if="alarmForm.disk_enabled" label="磁盘使用率阈值(%)"><el-input-number v-model="alarmForm.disk_threshold" :min="1" :max="100" style="width:100%" /></el-form-item>
            <el-form-item label="MySQL异常告警"><el-switch v-model="alarmForm.mysql_alarm" /></el-form-item>
            <el-form-item label="Redis异常告警"><el-switch v-model="alarmForm.redis_alarm" /></el-form-item>
            <el-form-item label="Nginx异常告警"><el-switch v-model="alarmForm.nginx_alarm" /></el-form-item>
            <el-form-item label="通知方式"><el-checkbox-group v-model="alarmForm.notify_channels"><el-checkbox label="system">站内消息</el-checkbox><el-checkbox label="email">邮件</el-checkbox></el-checkbox-group></el-form-item>
            <el-form-item label="邮件接收地址"><el-input v-model="alarmForm.notify_emails" placeholder="多个用逗号分隔" /></el-form-item>
          </el-form>
        </el-tab-pane>
        <el-tab-pane label="告警历史" name="history">
          <el-table :data="alarmList" size="mini" border stripe style="width:100%" max-height="400">
            <el-table-column prop="created_at" label="时间" width="160" />
            <el-table-column prop="alarm_type" label="类型" width="80" />
            <el-table-column prop="alarm_level" label="级别" width="70" />
            <el-table-column prop="content" label="内容" min-width="200" />
            <el-table-column prop="status" label="状态" width="80" :formatter="r=>r.status===0?'未处理':r.status===1?'已读':'已处理'" />
            <el-table-column label="操作" width="80"><template slot-scope="{row}"><el-button v-if="row.status===0 && hasPerm('monitor:markAlarmRead')" size="mini" @click="doMarkRead(row.id)">已读</el-button></template></el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
      <span slot="footer" v-if="alarmTab==='rules'">
        <el-button @click="showAlarm=false" size="small">取消</el-button>
        <el-button type="primary" :loading="savingAlarm" @click="saveAlarm" size="small">保存配置</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getOverview, getInfo, getSystemInfo, getCpuTrend, getMemoryTrend, getDiskTrend, getNetworkTrend,
  getProcesses, killProcess, getAlarmSettings, saveAlarmSettings, getAlarmHistory, markAlarmRead } from '@/api/monitor'

function fmtSize(b) { if(!b||b<=0)return'0 B';const u=['B','KB','MB','GB','TB'];const i=Math.floor(Math.log(b)/Math.log(1024));return (b/Math.pow(1024,i)).toFixed(1)+' '+u[i]; }
function fmtSpeed(b){if(!b||b<=0)return'0 B';if(b<1024)return b.toFixed(0)+' B';if(b<1048576)return (b/1024).toFixed(0)+' KB';return (b/1048576).toFixed(1)+' MB';}
const circum = 2*Math.PI*52;

export default {
  name:'SystemMonitor',
  data(){
    return{
      circum,
      refreshInterval:30000, lastUpdate:'加载中...', timer:null,
      ov:{cpu_usage:0,cpu_load_1:0,cpu_load_5:0,cpu_load_15:0,memory_usage:0,memory_used:0,memory_total:0,swap_usage:0,disk_usage:0,disk_used:0,disk_total:0,disk_read:0,disk_write:0,uptime:'未知',num_cores:'--'},
      appInfo:{online_users:0}, sysInfo:{},
      procSearch:'', procSort:{p:'',o:''}, processes:[], showProcesses:false,
      showAlarm:false, alarmTab:'rules', savingAlarm:false,
      alarmForm:{cpu_enabled:true,cpu_threshold:80,cpu_duration:5,memory_enabled:true,memory_threshold:85,disk_enabled:true,disk_threshold:90,mysql_alarm:true,redis_alarm:true,nginx_alarm:true,notify_channels:['system'],notify_emails:''},
      alarmList:[], showProcDlg:false, procDetail:null,
      charts:[
        {key:'cpu',title:'CPU 使用率趋势',range:'1h',color:'#409EFF'},
        {key:'memory',title:'内存使用率趋势',range:'1h',color:'#9B59B6'},
        {key:'disk',title:'磁盘读写速率趋势',range:'1h',color:'#67C23A'},
        {key:'network',title:'网络流量趋势',range:'1h',color:'#E6A23C'},
      ],
      chartInstances:{},
    }
  },
  computed:{
    cpuColor(){const u=this.ov.cpu_usage;return u<60?'#67C23A':u<80?'#E6A23C':'#F56C6C'},
    memColor(){const u=this.ov.memory_usage;return u<60?'#67C23A':u<80?'#E6A23C':'#F56C6C'},
    dskColor(){const u=this.ov.disk_usage;return u<60?'#67C23A':u<80?'#E6A23C':'#F56C6C'},
    statusColor(){return'#67C23A'},
    filteredProcs(){
      let list=this.processes.filter(p=>p.pid>1).sort((a,b)=>b.cpu_percent-a.cpu_percent).slice(0,100)
      const q=this.procSearch.toLowerCase()
      if(q)list=list.filter(p=>p.name.toLowerCase().includes(q))
      if(this.procSort.p){const f=this.procSort.p;list.sort((a,b)=>{const va=a[f]||'',vb=b[f]||'';return va<vb?-1:va>vb?1:0});if(this.procSort.o==='desc')list.reverse()}
      return list
    },
  },
  async created(){await this.loadAll();this.startRefresh()},
  beforeDestroy(){clearInterval(this.timer);Object.values(this.chartInstances).forEach(c=>c.dispose())},
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    fmtSize, fmtSpeed,
    async loadAll(){
      try{const[ov,ai,si]=await Promise.all([getOverview(),getInfo(),getSystemInfo()]);if(ov.code===0)this.ov=ov.data;if(ai.code===0)this.appInfo=ai.data;if(si.code===0)this.sysInfo=si.data;this.lastUpdate=new Date().toLocaleString()}catch{}
      this.charts.forEach(ch=>this.loadTrend(ch));this.loadProcesses()
    },
    async loadTrend(ch){
      try{
        const apis={cpu:getCpuTrend,memory:getMemoryTrend,disk:getDiskTrend,network:getNetworkTrend}
        const r=await apis[ch.key](ch.range);if(r.code!==0)return
        this.renderChart(ch,r.data||[])
      }catch{}
    },
    renderChart(ch,data){
      const id='chart-'+ch.key
      this.$nextTick(()=>{
        const el=document.getElementById(id);if(!el)return
        if(!this.chartInstances[ch.key])this.chartInstances[ch.key]=echarts.init(el,{backgroundColor:'transparent'})
        const inst=this.chartInstances[ch.key]
        const times=data.map(d=>{const t=d.collected_at||'';return t.length>16?t.substring(11,16):t})
        let series=[]
        if(ch.key==='cpu')series=[
          {name:'CPU%',type:'line',data:data.map(d=>d.cpu_usage),smooth:true,lineStyle:{width:2},itemStyle:{color:ch.color},areaStyle:{color:{type:'linear',x:0,y:0,x2:0,y2:1,colorStops:[{offset:0,color:ch.color+'66'},{offset:1,color:ch.color+'00'}]}}},
          {name:'负载',type:'line',data:data.map(d=>d.cpu_load_1),smooth:true,lineStyle:{width:1,type:'dashed'},itemStyle:{color:'rgba(255,255,255,0.4)'}},
        ]
        else if(ch.key==='memory')series=[
          {name:'内存%',type:'line',data:data.map(d=>d.memory_usage),smooth:true,lineStyle:{width:2},itemStyle:{color:ch.color},areaStyle:{color:{type:'linear',x:0,y:0,x2:0,y2:1,colorStops:[{offset:0,color:ch.color+'66'},{offset:1,color:ch.color+'00'}]}}},
          {name:'Swap',type:'line',data:data.map(d=>d.swap_usage ?? 0),smooth:true,lineStyle:{width:1,type:'dashed'},itemStyle:{color:'rgba(255,255,255,0.4)'}},
        ]
        else if(ch.key==='disk')series=[
          {name:'读取',type:'line',data:data.map(d=>d.disk_read ?? 0),smooth:true,lineStyle:{width:2},itemStyle:{color:ch.color},areaStyle:{color:{type:'linear',x:0,y:0,x2:0,y2:1,colorStops:[{offset:0,color:ch.color+'66'},{offset:1,color:ch.color+'00'}]}}},
          {name:'写入',type:'line',data:data.map(d=>d.disk_write ?? 0),smooth:true,lineStyle:{width:1,type:'dashed'},itemStyle:{color:'rgba(255,255,255,0.4)'}},
        ]
        else if(ch.key==='network')series=[
          {name:'发送',type:'line',data:data.map(d=>d.net_send ?? 0),smooth:true,lineStyle:{width:2},itemStyle:{color:ch.color},areaStyle:{color:{type:'linear',x:0,y:0,x2:0,y2:1,colorStops:[{offset:0,color:ch.color+'66'},{offset:1,color:ch.color+'00'}]}}},
          {name:'接收',type:'line',data:data.map(d=>d.net_recv ?? 0),smooth:true,lineStyle:{width:1,type:'dashed'},itemStyle:{color:'rgba(255,255,255,0.4)'}},
        ]
        inst.setOption({
          tooltip:{trigger:'axis',backgroundColor:'rgba(10,10,26,0.9)',borderColor:'rgba(255,255,255,0.1)',textStyle:{color:'#fff',fontSize:12}},
          legend:{data:series.map(s=>s.name),textStyle:{color:'rgba(255,255,255,0.6)',fontSize:11},top:0,right:0},
          grid:{left:45,right:10,top:35,bottom:20},
          xAxis:{type:'category',data:times,axisLine:{lineStyle:{color:'rgba(255,255,255,0.08)'}},axisLabel:{color:'rgba(255,255,255,0.4)',fontSize:10,interval:Math.max(0,Math.floor(times.length/6)-1)}},
          yAxis:{type:'value',splitLine:{lineStyle:{color:'rgba(255,255,255,0.05)'}},axisLabel:{color:'rgba(255,255,255,0.4)',fontSize:10}},
          series,
        })
        inst.resize()
      })
    },
    async loadProcesses(){try{const r=await getProcesses();if(r.code===0)this.processes=r.data||[]}catch{}},
    async confirmKill(row){
      try{await this.$confirm(`确定终止进程 ${row.name} (PID: ${row.pid})？`,'危险操作',{type:'warning'});const r=await killProcess(row.pid);if(r.code===0){this.$message.success('已终止');this.loadProcesses()}else this.$message.error(r.message||'失败')}catch{}
    },
    showProcDetail(row){this.procDetail=row;this.showProcDlg=true},
    stateType(s){return{'运行中':'success','睡眠':'info','僵尸':'danger','停止':'info','R':'success','S':'info','Z':'danger','T':'info'}[s]||'info'},
    changeInterval(val){clearInterval(this.timer);if(val>0)this.timer=setInterval(()=>this.loadAll(),val)},
    startRefresh(){if(this.refreshInterval>0)this.timer=setInterval(()=>this.loadAll(),this.refreshInterval)},
    async saveAlarm(){this.savingAlarm=true;try{const r=await saveAlarmSettings(this.alarmForm);if(r.code===0){this.$message.success('保存成功');this.showAlarm=false}else this.$message.error(r.message||'失败')}catch{}finally{this.savingAlarm=false}},
    async doMarkRead(id){try{await markAlarmRead(id);this.loadAlarmHistory()}catch{}},
    async loadAlarmHistory(){try{const r=await getAlarmHistory({page:1});if(r.code===0)this.alarmList=r.data?.list||[]}catch{}},
  },
  watch:{showAlarm(v){if(v){this.loadAlarmHistory();getAlarmSettings().then(r=>{if(r.code===0&&r.data)Object.assign(this.alarmForm,r.data)}).catch(()=>{})}}},
}
</script>

<style scoped>
.monitor-page { padding:24px; min-height:100vh; color:#fff; display:flex; flex-direction:column; gap:20px; }
.header-row { display:flex; justify-content:space-between; align-items:flex-start; }
.page-title { margin:0; font-size:22px; font-weight:700; color:#fff; }
.page-subtitle { margin:4px 0 0; font-size:13px; color:rgba(255,255,255,0.5); }
.header-actions { display:flex; align-items:center; }
.glass-card { background:rgba(255,255,255,0.06); border:1px solid rgba(255,255,255,0.08); border-radius:16px; padding:20px 24px; backdrop-filter:blur(12px); }
.cards-row { display:grid; grid-template-columns:repeat(4,1fr); gap:16px; }
.card-body { display:flex; align-items:center; gap:16px; height:100%; }
.ring-wrap { position:relative; width:90px; height:90px; flex-shrink:0; }
.ring-svg { width:90px; height:90px; }
.ring-circle { transition:stroke-dashoffset .5s ease; }
.ring-value { position:absolute; top:50%; left:50%; transform:translate(-50%,-50%); font-size:20px; font-weight:700; }
.ring-value small { font-size:11px; font-weight:400; opacity:.7; }
.card-right { flex:1; min-width:0; }
.card-title { font-size:14px; color:rgba(255,255,255,0.6); margin-bottom:4px; }
.card-info { font-size:13px; color:rgba(255,255,255,0.8); }
.card-footer { font-size:12px; color:rgba(255,255,255,0.45); margin-top:2px; }
.status-dot { width:12px; height:12px; border-radius:50%; display:inline-block; box-shadow:0 0 8px currentColor; }
.status-text { font-size:18px; font-weight:700; }
.charts-grid { display:grid; grid-template-columns:1fr 1fr; gap:16px; }
.chart-card { padding:16px 20px; }
.chart-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; font-size:14px; color:rgba(255,255,255,0.8); }
.bottom-row { display:flex; gap:16px; min-height:0; }
.info-grid { display:grid; grid-template-columns:1fr 1fr; gap:4px 20px; font-size:13px; }
.info-grid div { display:flex; padding:3px 0; }
.info-grid label { color:rgba(255,255,255,0.45); min-width:85px; flex-shrink:0; }
.info-grid span { color:rgba(255,255,255,0.8); }
.sec-title { font-size:15px; font-weight:600; color:#fff; margin:0 0 12px; padding-bottom:8px; border-bottom:1px solid rgba(255,255,255,0.06); }
.proc-detail-grid { display:grid; grid-template-columns:1fr 1fr; gap:8px 24px; }
.proc-detail-grid div { display:flex; padding:4px 0; }
.proc-detail-grid label { color:rgba(255,255,255,0.5); min-width:80px; flex-shrink:0; font-size:13px; }
.proc-detail-grid span { color:#fff; font-size:13px; }
::v-deep .el-table { background:transparent !important; }
::v-deep .el-table th { background:rgba(255,255,255,0.04) !important; color:rgba(255,255,255,0.7) !important; border-bottom:1px solid rgba(255,255,255,0.06) !important; }
::v-deep .el-table td { background:transparent !important; color:rgba(255,255,255,0.7) !important; border-bottom:1px solid rgba(255,255,255,0.04) !important; }
::v-deep .el-table--striped .el-table__body tr.el-table__row--striped td { background:rgba(255,255,255,0.02) !important; }
::v-deep .el-table--enable-row-hover .el-table__body tr:hover>td { background:rgba(255,255,255,0.06) !important; }
::v-deep .el-table__body-wrapper::-webkit-scrollbar { width:4px; }
::v-deep .el-table__body-wrapper::-webkit-scrollbar-thumb { background:rgba(255,255,255,0.15); border-radius:4px; }
::v-deep .el-select .el-input__inner { background:rgba(255,255,255,0.08) !important; border-color:rgba(255,255,255,0.15) !important; color:#fff !important; }
::v-deep .el-input__inner { background:rgba(255,255,255,0.08) !important; border-color:rgba(255,255,255,0.15) !important; color:#fff !important; }
::v-deep .el-input__prefix { color:rgba(255,255,255,0.4) !important; }
::v-deep .el-switch__core { border-color:rgba(255,255,255,0.2) !important; background:rgba(255,255,255,0.1) !important; }
::v-deep .el-progress__text { color:rgba(255,255,255,0.6) !important; font-size:10px !important; }
::v-deep .el-progress-bar__outer { background:rgba(255,255,255,0.1) !important; }
::v-deep .el-dialog { background:#0d1117 !important; border:1px solid rgba(255,255,255,0.12); border-radius:12px; }
::v-deep .el-dialog__title { color:#fff !important; }
::v-deep .el-dialog__body { color:rgba(255,255,255,0.8) !important; }
::v-deep .el-form-item__label { color:rgba(255,255,255,0.6) !important; }
::v-deep .el-tabs__item { color:rgba(255,255,255,0.5) !important; }
::v-deep .el-tabs__item.is-active { color:#409EFF !important; }
::v-deep .el-tabs__nav-wrap::after { background:rgba(255,255,255,0.06) !important; }
::v-deep .el-checkbox__label { color:rgba(255,255,255,0.7) !important; }
::v-deep .el-checkbox__input.is-checked+.el-checkbox__label { color:#409EFF !important; }
</style>
