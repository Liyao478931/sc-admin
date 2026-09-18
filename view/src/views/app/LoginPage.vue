<template>
  <div class="login-page-mgr">
    <div class="mgr-header">
      <div><h2>登录页面管理</h2><span class="sub-title">配置移动端登录页视觉风格 · 实时预览</span></div>
      <el-button v-if="hasPerm('loginpage:save')" type="primary" :loading="saving" @click="handleSave">保存配置</el-button>
    </div>
    <div class="mgr-body">
      <div class="left-panel">
        <el-collapse v-model="activePanels">
          <el-collapse-item title="品牌配置" name="brand" class="cfg-card"><div class="card-badge">{{brandCount}}项</div>
            <el-form label-width="120px" size="small">
              <el-form-item label="Logo图片">
                <div class="lp-logo-row">
                  <el-upload action="" :show-file-list="false" :http-request="(o)=>uploadFile(o,'logo')" accept="image/*">
                    <img v-if="cfg.login_page_logo" :src="cfg.login_page_logo" style="height:32px" />
                    <el-button v-else size="small">上传</el-button>
                  </el-upload>
                  <el-button v-if="cfg.login_page_logo" size="mini" type="danger" plain icon="el-icon-delete" @click="cfg.login_page_logo = ''">删除</el-button>
                </div>
              </el-form-item>
              <el-form-item label="系统名称"><el-input v-model="cfg.login_page_system_name" maxlength="20" /></el-form-item>
              <el-form-item label="名称颜色"><el-color-picker v-model="cfg.login_page_system_name_color" /></el-form-item>
              <el-form-item label="副标题"><el-input v-model="cfg.login_page_subtitle" maxlength="50" /></el-form-item>
              <el-form-item label="副标题颜色"><el-color-picker v-model="cfg.login_page_subtitle_color" /></el-form-item>
              <el-form-item label="品牌融合渐变"><el-switch v-model="cfg.login_page_brand_gradient" active-value="1" inactive-value="0" /></el-form-item>
              <el-form-item label="欢迎大标题"><el-input v-model="cfg.login_page_welcome_title" maxlength="30" /></el-form-item>
              <el-form-item label="高亮词"><el-input v-model="cfg.login_page_highlight_word" maxlength="20" /></el-form-item>
              <el-form-item label="高亮渐变色起始"><el-color-picker v-model="cfg.login_page_highlight_start" /></el-form-item>
              <el-form-item label="高亮渐变色结束"><el-color-picker v-model="cfg.login_page_highlight_end" /></el-form-item>
              <el-form-item label="状态文字"><el-input v-model="cfg.login_page_status_text" maxlength="30" /></el-form-item>
              <el-form-item label="状态点颜色"><el-color-picker v-model="cfg.login_page_status_dot" /></el-form-item>
            </el-form>
          </el-collapse-item>
          <el-collapse-item title="背景配置" name="bg" class="cfg-card"><div class="card-badge">{{bgCount}}项</div>
            <el-form label-width="120px" size="small">
              <el-form-item label="背景类型"><el-select v-model="cfg.login_page_bg_type" style="width:100%"><el-option label="颜色" value="color" /><el-option label="图片" value="image" /><el-option label="渐变" value="gradient" /><el-option label="粒子线条" value="particle" /></el-select></el-form-item>
              <template v-if="cfg.login_page_bg_type==='color'"><el-form-item label="背景颜色"><el-color-picker v-model="cfg.login_page_bg_color" /></el-form-item></template>
              <template v-if="cfg.login_page_bg_type==='image'">
                <el-form-item label="背景图片"><el-upload action="" :show-file-list="false" :http-request="(o)=>uploadFile(o,'bg')" accept="image/*"><el-button size="small">上传</el-button></el-upload><img v-if="cfg.login_page_bg_image" :src="cfg.login_page_bg_image" style="max-width:120px;margin-top:4px" /></el-form-item>
                <el-form-item label="平铺方式"><el-select v-model="cfg.login_page_bg_image_fit" style="width:100%"><el-option label="覆盖" value="cover" /><el-option label="平铺" value="tile" /><el-option label="拉伸" value="stretch" /><el-option label="居中" value="center" /></el-select></el-form-item>
              </template>
              <template v-if="cfg.login_page_bg_type==='gradient'">
                <el-form-item label="渐变方向"><el-select v-model="cfg.login_page_gradient_direction" style="width:100%"><el-option label="从上到下" value="to bottom" /><el-option label="从左到右" value="to right" /><el-option label="左上到右下" value="to bottom right" /><el-option label="右上到左下" value="to bottom left" /></el-select></el-form-item>
                <el-form-item label="起始色"><el-color-picker v-model="cfg.login_page_gradient_start" /></el-form-item>
                <el-form-item label="结束色"><el-color-picker v-model="cfg.login_page_gradient_end" /></el-form-item>
              </template>
              <template v-if="cfg.login_page_bg_type==='particle'">
                <el-form-item label="线条颜色"><el-color-picker v-model="cfg.login_page_particle_color" /></el-form-item>
                <el-form-item label="粒子数量"><el-input-number v-model.number="cfg_particle_count" :min="50" :max="200" :step="5" style="width:100%" /></el-form-item>
                <el-form-item label="粒子速度"><el-slider v-model="cfg_particle_speed" :min="0.1" :max="1" :step="0.1" show-input style="width:200px" /></el-form-item>
                <el-form-item label="连接距离"><el-input-number v-model.number="cfg_particle_distance" :min="40" :max="200" :step="5" style="width:100%" /></el-form-item>
              </template>
            </el-form>
          </el-collapse-item>
          <el-collapse-item title="登录卡片配置" name="card" class="cfg-card"><div class="card-badge">{{cardCount}}项</div>
            <el-form label-width="120px" size="small">
              <el-form-item label="显示卡片"><el-switch v-model="cfg.login_page_card_enabled" active-value="1" inactive-value="0" /></el-form-item>
              <el-form-item label="卡片风格"><el-select v-model="cfg.login_page_card_style" style="width:100%"><el-option label="现代圆角（新）" value="modern" /><el-option label="经典（原）" value="classic" /></el-select></el-form-item>
              <el-form-item label="卡片位置"><el-select v-model="cfg.login_page_card_position" style="width:100%"><el-option label="居中" value="center" /><el-option label="靠左" value="left" /><el-option label="靠右" value="right" /></el-select></el-form-item>
              <el-form-item label="卡片宽度"><el-input-number v-model.number="cfg_card_width" :min="320" :max="520" :step="10" style="width:100%" /> px</el-form-item>
              <el-form-item label="背景色"><el-color-picker v-model="cfg.login_page_card_bg" /></el-form-item>
              <el-form-item label="透明度"><el-slider v-model="cfg_card_opacity" :min="0.1" :max="1" :step="0.05" show-input style="width:200px" /></el-form-item>
              <el-form-item label="圆角"><el-input-number v-model.number="cfg_card_radius" :min="0" :max="30" :step="2" style="width:100%" /> px</el-form-item>
              <el-form-item label="阴影强度"><el-select v-model="cfg.login_page_card_shadow" style="width:100%"><el-option label="无" value="none" /><el-option label="浅" value="light" /><el-option label="中等" value="medium" /><el-option label="深" value="heavy" /></el-select></el-form-item>
              <el-form-item label="毛玻璃模糊"><el-switch v-model="cfg.login_page_card_blur" active-value="1" inactive-value="0" /></el-form-item>
            </el-form>
          </el-collapse-item>
          <el-collapse-item title="表单样式配置" name="form" class="cfg-card"><div class="card-badge">{{formCount}}项</div>
            <el-form label-width="120px" size="small">
              <el-form-item label="按钮文字"><el-input v-model="cfg.login_page_btn_text" maxlength="10" /></el-form-item>
              <el-form-item label="按钮背景色"><el-color-picker v-model="cfg.login_page_btn_bg" /></el-form-item>
              <el-form-item label="按钮边框色"><el-color-picker v-model="cfg.login_page_btn_border" /></el-form-item>
              <el-form-item label="按钮文字色"><el-color-picker v-model="cfg.login_page_btn_color" /></el-form-item>
              <el-form-item label="按钮圆角"><el-input-number v-model.number="cfg_btn_radius" :min="4" :max="24" :step="2" style="width:100%" /> px</el-form-item>
              <el-form-item label="按钮高度"><el-input-number v-model.number="cfg_btn_height" :min="40" :max="72" :step="4" style="width:100%" /> px</el-form-item>
              <el-form-item label="按钮毛玻璃"><el-switch v-model="cfg.login_page_btn_blur" active-value="1" inactive-value="0" /></el-form-item>
              <el-form-item label="发光效果"><el-switch v-model="cfg.login_page_btn_glow" active-value="1" inactive-value="0" /></el-form-item>
              <el-form-item v-if="cfg.login_page_btn_glow==='1'" label="发光颜色"><el-color-picker v-model="cfg.login_page_btn_glow_color" /></el-form-item>
              <el-form-item label="输入框背景色"><el-color-picker v-model="cfg.login_page_input_bg" /></el-form-item>
              <el-form-item label="输入框边框色"><el-color-picker v-model="cfg.login_page_input_border" /></el-form-item>
              <el-form-item label="输入框文字色"><el-color-picker v-model="cfg.login_page_input_color" /></el-form-item>
              <el-form-item label="标签文字色"><el-color-picker v-model="cfg.login_page_label_color" /></el-form-item>
            </el-form>
          </el-collapse-item>
          <el-collapse-item title="登录方式状态查看" name="methods" class="cfg-card"><div class="card-badge">4项</div>
            <div v-for="(m,i) in methodsStatus" :key="i" class="method-row"><span>{{m.name}}</span><el-tag :type="m.status?'success':'info'" size="small">{{m.status?'已开启':'已关闭'}}</el-tag></div>
            <div style="font-size:12px;color:#909399;margin-top:12px">登录方式开关请在「系统设置 → 应用管理 → 登录方式配置」中管理</div>
          </el-collapse-item>
        </el-collapse>
      </div>
      <div class="right-panel">
        <div class="preview-label">实时预览</div>
        <div class="phone-frame">
          <div class="phone-notch"></div>
          <div class="phone-screen" :style="screenStyle">
            <!-- 登录页状态 -->
            <template v-if="!preview.loggedIn">
              <canvas v-if="showParticle" ref="particleCanvas" class="particle-canvas" />
              <div class="pl-bg" :style="bgStyle"></div>
              <div class="pl-content">
                <div class="pl-brand"><img v-if="cfg.login_page_logo" :src="cfg.login_page_logo" class="pl-logo" /><div><div class="pl-name" :style="brandNameStyle">{{cfg.login_page_system_name}}</div><div class="pl-sub" :style="{color:cfg.login_page_subtitle_color}">{{cfg.login_page_subtitle}}</div></div></div>
                <div class="pl-welcome"><div class="pl-title"><span v-for="(seg,si) in welcomeTitleSegs" :key="si"><template v-if="seg.highlight"><span :style="highlightStyle">{{seg.text}}</span></template><template v-else>{{seg.text}}</template></span></div><div class="pl-stat"><span class="pl-dot" :style="{background:cfg.login_page_status_dot}"></span><span style="font-size:10px;color:rgba(255,255,255,0.2)">{{cfg.login_page_status_text}}</span></div></div>
                <div v-if="cfg.login_page_card_enabled==='1'" class="pl-card" :style="cardStyle">
                  <div class="pl-tabs"><span :class="{act:preview.tab==='pwd'}" @click="preview.tab='pwd'">密码登录</span><span v-if="hasSms" :class="{act:preview.tab==='sms'}" @click="preview.tab='sms'">短信登录</span></div>
                  <template v-if="preview.tab==='pwd'">
                    <input v-model="preview.username" placeholder="用户名" :style="inputStyle" />
                    <input v-model="preview.password" type="password" placeholder="密码" :style="inputStyle" @keyup.enter="handlePwdLogin" />
                    <div v-if="preview.error" class="pl-error">{{preview.error}}</div>
                    <button :style="btnStyle" @click="handlePwdLogin">{{preview.loading?'登录中...':cfg.login_page_btn_text}}</button>
                  </template>
                  <template v-if="preview.tab==='sms'">
                    <input v-model="preview.phone" placeholder="手机号" maxlength="11" :style="inputStyle" />
                    <div class="sms-row"><input v-model="preview.code" placeholder="验证码" maxlength="6" :style="inputStyle" style="flex:1" /><button class="sms-btn" :disabled="preview.smsCount>0" @click="handleSendSms">{{preview.smsCount>0?preview.smsCount+'s':'获取验证码'}}</button></div>
                    <div v-if="preview.error" class="pl-error">{{preview.error}}</div>
                    <button :style="btnStyle" @click="handleSmsLogin">{{preview.loading?'登录中...':cfg.login_page_btn_text}}</button>
                  </template>
                  <div v-if="hasWechat" class="pl-wx" @click="handleWechat"><svg viewBox="0 0 24 24" width="18" fill="#07c160"><path d="M8.691 2.188C3.891 2.188 0 5.476 0 9.53c0 2.212 1.17 4.203 3.002 5.55a.59.59 0 0 1 .213.665l-.39 1.48 1.903-1.114a.864.864 0 0 1 .717-.098 10.16 10.16 0 0 0 2.837.403c.276 0 .543-.027.811-.05-.857-2.578.157-4.972 1.932-6.446 1.703-1.415 3.882-1.98 5.853-1.838-.576-3.583-4.196-6.348-8.596-6.348z"/></svg>微信一键登录</div>
                </div>
                <div v-else class="pl-form-raw">
                  <template v-if="preview.tab==='pwd'">
                    <input v-model="preview.username" placeholder="用户名" :style="inputStyle" />
                    <input v-model="preview.password" type="password" placeholder="密码" :style="inputStyle" @keyup.enter="handlePwdLogin" />
                    <div v-if="preview.error" class="pl-error">{{preview.error}}</div>
                    <button :style="btnStyle" @click="handlePwdLogin">{{preview.loading?'登录中...':cfg.login_page_btn_text}}</button>
                  </template>
                </div>
                <div class="pl-footer">{{cfg.login_page_copyright||''}}</div>
              </div>
            </template>
            <!-- 工作台状态 -->
            <template v-else>
              <div class="workbench">
                <div class="wb-header"><span>{{cfg.login_page_system_name}}</span><span style="font-size:12px">{{preview.user?.real_name||preview.user?.username}} · {{preview.user?.role||'管理员'}}</span><el-button type="text" size="mini" style="color:#fff" @click="exitPreview">退出预览</el-button></div>
                <div class="wb-stats"><div v-for="s in statsData" :key="s.name" class="wb-stat"><div class="wb-num">{{s.val}}</div><div class="wb-lb">{{s.name}}</div></div></div>
                <div class="wb-welcome"><div>欢迎回来</div><div style="font-size:16px;font-weight:600;margin:4px 0">{{preview.user?.real_name||preview.user?.username}}</div><div style="font-size:12px;color:#909399">{{preview.user?.role||'管理员'}} · {{preview.loginTime}}</div></div>
              </div>
            </template>
          </div>
          <div class="home-indicator"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getLoginMethods } from '@/api/app'
import { getLoginPageConfig, saveLoginPageConfig } from '@/api/app'
import { uploadSettingFile } from '@/api/settings'
// 登录API不再需要（预览模式已改为模拟）

export default {
  name: 'LoginPageMgr',
  data() {
    return {
      saving: false, activePanels: ['brand','bg','card','form','methods'],
      cfg: {
        login_page_logo:'', login_page_system_name:'华能科技', login_page_system_name_color:'#ffffff',
        login_page_subtitle:'智能管控平台', login_page_subtitle_color:'rgba(255,255,255,0.6)',
        login_page_brand_gradient:'0', login_page_welcome_title:'登录工业控制平台', login_page_highlight_word:'工业控制平台',
        login_page_highlight_start:'#00d4ff', login_page_highlight_end:'#ff8c00',
        login_page_status_text:'系统运行中 · 混合加密通道', login_page_status_dot:'#00d4ff',
        login_page_bg_type:'gradient', login_page_bg_color:'#0b1a3a', login_page_bg_image:'', login_page_bg_image_fit:'cover',
        login_page_gradient_direction:'to bottom', login_page_gradient_start:'#0b1a3a', login_page_gradient_end:'#1a1040',
        login_page_particle_color:'#00b4ff', login_page_particle_count:'100', login_page_particle_speed:'0.4', login_page_particle_distance:'80',
        login_page_card_enabled:'1', login_page_card_position:'center', login_page_card_width:'420', login_page_card_bg:'rgba(255,255,255,0.85)',
        login_page_card_opacity:'0.92', login_page_card_radius:'20', login_page_card_shadow:'medium', login_page_card_blur:'1',
        login_page_btn_text:'微信一键登录', login_page_btn_bg:'rgba(255,255,255,0.04)', login_page_btn_border:'rgba(255,255,255,0.06)',
        login_page_btn_color:'#ffffff', login_page_btn_radius:'12', login_page_btn_height:'56', login_page_btn_blur:'1', login_page_btn_glow:'0',
        login_page_btn_glow_color:'#00d4ff', login_page_input_bg:'rgba(255,255,255,0.04)', login_page_input_border:'rgba(255,255,255,0.1)',
        login_page_input_color:'#ffffff', login_page_label_color:'rgba(255,255,255,0.6)',
      },
      methodsData: [], preview: { loggedIn:false, tab:'pwd', username:'', password:'', phone:'', code:'', loading:false, error:'', smsCount:0, user:null, loginTime:'' },
      statsData: [{name:'总用户数',val:'1,284'},{name:'今日登录',val:'47'},{name:'待办任务',val:'12'},{name:'在线用户',val:'36'}],
    }
  },
  computed: {
    brandCount(){return 12}, bgCount(){return this.cfg.login_page_bg_type==='color'?2:this.cfg.login_page_bg_type==='image'?3:this.cfg.login_page_bg_type==='gradient'?5:7},
    cardCount(){return 8}, formCount(){return 13},
    cfg_particle_count:{get(){return Number(this.cfg.login_page_particle_count)||100},set(v){this.cfg.login_page_particle_count=String(v)}},
    cfg_particle_speed:{get(){return Number(this.cfg.login_page_particle_speed)||0.4},set(v){this.cfg.login_page_particle_speed=String(v)}},
    cfg_particle_distance:{get(){return Number(this.cfg.login_page_particle_distance)||80},set(v){this.cfg.login_page_particle_distance=String(v)}},
    cfg_card_width:{get(){return Number(this.cfg.login_page_card_width)||420},set(v){this.cfg.login_page_card_width=String(v)}},
    cfg_card_opacity:{get(){return Number(this.cfg.login_page_card_opacity)||0.92},set(v){this.cfg.login_page_card_opacity=String(v)}},
    cfg_card_radius:{get(){return Number(this.cfg.login_page_card_radius)||20},set(v){this.cfg.login_page_card_radius=String(v)}},
    cfg_btn_radius:{get(){return Number(this.cfg.login_page_btn_radius)||12},set(v){this.cfg.login_page_btn_radius=String(v)}},
    cfg_btn_height:{get(){return Number(this.cfg.login_page_btn_height)||56},set(v){this.cfg.login_page_btn_height=String(v)}},
    showParticle(){return this.cfg.login_page_bg_type==='particle'},
    hasSms(){return this.methodsData.some(m=>m.name==='验证码登录'&&m.status)},
    hasWechat(){return this.methodsData.some(m=>m.name==='微信一键登录'&&m.status)},
    methodsStatus(){return this.methodsData},
    brandNameStyle(){
      const c=this.cfg
      if(c.login_page_brand_gradient==='1')return{backgroundImage:`linear-gradient(135deg,${c.login_page_highlight_start},${c.login_page_highlight_end})`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',backgroundClip:'text'}
      return{color:c.login_page_system_name_color}
    },
    welcomeTitleSegs(){
      const c=this.cfg
      if(!c.login_page_highlight_word)return[{text:c.login_page_welcome_title||'',highlight:false}]
      const idx=c.login_page_welcome_title.indexOf(c.login_page_highlight_word)
      if(idx===-1)return[{text:c.login_page_welcome_title||'',highlight:false}]
      const before=c.login_page_welcome_title.substring(0,idx)
      const highlight=c.login_page_highlight_word
      const after=c.login_page_welcome_title.substring(idx+highlight.length)
      const segs=[]
      if(before)segs.push({text:before,highlight:false})
      segs.push({text:highlight,highlight:true})
      if(after)segs.push({text:after,highlight:false})
      return segs
    },
    highlightStyle(){
      const c=this.cfg
      return{background:`linear-gradient(135deg,${c.login_page_highlight_start},${c.login_page_highlight_end})`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',backgroundClip:'text',display:'inline'}
    },
    screenStyle(){return{background:this.cfg.login_page_bg_type==='color'?this.cfg.login_page_bg_color:'#0b1a3a'}},
    bgStyle(){
      const c=this.cfg
      if(c.login_page_bg_type==='image')return{backgroundImage:`url(${c.login_page_bg_image})`,backgroundSize:c.login_page_bg_image_fit==='tile'?'auto':c.login_page_bg_image_fit,backgroundPosition:'center',backgroundRepeat:c.login_page_bg_image_fit==='tile'?'repeat':'no-repeat'}
      if(c.login_page_bg_type==='gradient')return{background:`linear-gradient(${c.login_page_gradient_direction},${c.login_page_gradient_start},${c.login_page_gradient_end})`}
      return{}
    },
    cardStyle(){
      const c=this.cfg
      if(c.login_page_card_enabled!=='1')return{}
      const shadows={none:'none',light:'0 2px 12px rgba(0,0,0,0.1)',medium:'0 8px 32px rgba(0,0,0,0.18)',heavy:'0 16px 48px rgba(0,0,0,0.3)'}
      const s={width:this.cfg_card_width+'px',background:this.hexToRgba(c.login_page_card_bg,this.cfg_card_opacity),borderRadius:this.cfg_card_radius+'px',boxShadow:shadows[c.login_page_card_shadow]||shadows.medium}
      if(c.login_page_card_blur==='1')s.backdropFilter='blur(20px)'
      if(c.login_page_card_position==='left')s.marginRight='auto'; else if(c.login_page_card_position==='right')s.marginLeft='auto'; else s.margin='0 auto'
      return s
    },
    btnStyle(){
      const c=this.cfg
      const s={width:'100%',height:this.cfg_btn_height+'px',borderRadius:this.cfg_btn_radius+'px',background:c.login_page_btn_bg,border:'1px solid '+c.login_page_btn_border,color:c.login_page_btn_color,fontSize:'15px',cursor:'pointer',fontFamily:'inherit',letterSpacing:'0.5px',transition:'all 0.3s',display:'flex',alignItems:'center',justifyContent:'center',gap:'8px',marginTop:'8px'}
      if(c.login_page_btn_blur==='1')s.backdropFilter='blur(6px)'
      if(c.login_page_btn_glow==='1')s.boxShadow='0 0 20px '+c.login_page_btn_glow_color
      return s
    },
    inputStyle(){
      const c=this.cfg
      return{width:'100%',height:'44px',background:c.login_page_input_bg,border:'1px solid '+c.login_page_input_border,borderRadius:'8px',padding:'0 14px',color:c.login_page_input_color,fontSize:'14px',outline:'none',boxSizing:'border-box',marginBottom:'8px'}
    },
  },
  watch: {
    'cfg.login_page_bg_type'(v){if(v==='particle')this.$nextTick(()=>this.initParticle());else this.destroyParticle()},
    'cfg.login_page_particle_color'(){this.initParticle()},
    'cfg_particle_count'(){this.initParticle()},
    'cfg_particle_speed'(){this.initParticle()},
    'cfg_particle_distance'(){this.initParticle()},
  },
  created(){this.load();this.loadMethods()},
  mounted(){if(this.showParticle)this.$nextTick(()=>this.initParticle())},
  beforeDestroy(){this.destroyParticle()},
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async load(){try{const r=await getLoginPageConfig();if(r.code===0&&r.data)Object.assign(this.cfg,r.data)}catch(e){}},
    async loadMethods(){try{const r=await getLoginMethods();if(r.code===0&&r.data){const d=r.data;const keys=['login_method_h5_sms','login_method_h5_password','login_method_h5_wechat','login_method_mini_enabled','login_method_mp_enabled','login_method_mp_sms','login_method_mp_password','login_method_wxwork_enabled','login_method_wxwork_qrcode'];const all=[{name:'微信一键登录',code:'login_method_mini_enabled||login_method_h5_wechat||login_method_mp_enabled'},{name:'验证码登录',code:'login_method_h5_sms||login_method_mp_sms'},{name:'账号密码登录',code:'login_method_h5_password||login_method_mp_password'},{name:'企业微信登录',code:'login_method_wxwork_enabled'},{name:'企业微信扫码',code:'login_method_wxwork_qrcode'}];this.methodsData=all.map(a=>({name:a.name,status:a.code.split('||').some(k=>d[k]==='1')}))}else this.methodsData=[]}catch(e){this.methodsData=[]}},
    async handleSave(){this.saving=true;try{const r=await saveLoginPageConfig(this.cfg);if(r.code===0)this.$message.success('配置已保存');else this.$message.error(r.msg)}catch(e){this.$message.error('保存失败')};this.saving=false},
    async uploadFile({file,onSuccess},t){const fd=new FormData();fd.append('file',file);fd.append('type',t);try{const r=await uploadSettingFile(fd);if(r.code===0&&r.data?.url){if(t==='logo')this.cfg.login_page_logo=r.data.url;else this.cfg.login_page_bg_image=r.data.url;onSuccess()}}catch(e){}},
    async handlePwdLogin(){
      if(!this.preview.username||!this.preview.password){this.preview.error='请输入用户名和密码';return}
      this.preview.loading=true;this.preview.error=''
      // 预览模式使用模拟登录，不调真实API
      if(this.preview.username&&this.preview.password){this.preview.loggedIn=true;this.preview.user={username:this.preview.username,real_name:'演示用户',role:'管理员'};this.preview.loginTime=new Date().toLocaleString();this.preview.loading=false}else{this.preview.error='请输入用户名和密码';this.preview.loading=false}
    },
    async handleSendSms(){
      if(!/^1[3-9]\d{9}$/.test(this.preview.phone)){this.preview.error='请输入正确手机号';return}
      this.preview.error='';this.preview.smsCount=60;const t=setInterval(()=>{if(--this.preview.smsCount<=0){clearInterval(t);this.preview.smsCount=0}},1000)
    },
    async handleSmsLogin(){
      if(!this.preview.phone||!/^\d{6}$/.test(this.preview.code)){this.preview.error='请输入手机号和验证码';return}
      this.preview.loading=true;this.preview.error=''
      // 预览模式使用模拟登录
      if(this.preview.phone&&this.preview.code){this.preview.loggedIn=true;this.preview.user={phone:this.preview.phone,real_name:'演示用户',role:'员工'};this.preview.loginTime=new Date().toLocaleString()}
      this.preview.loading=false
    },
    handleWechat(){this.$message.info('预览模式下微信登录暂不可用')},
    exitPreview(){this.preview={loggedIn:false,tab:'pwd',username:'',password:'',phone:'',code:'',loading:false,error:'',smsCount:0,user:null,loginTime:''}},
    initParticle(){
      this.destroyParticle()
      const cvs=this.$refs.particleCanvas;if(!cvs)return
      cvs.width=cvs.offsetWidth*2;cvs.height=cvs.offsetHeight*2;cvs.style.width=cvs.offsetWidth+'px';cvs.style.height=cvs.offsetHeight+'px'
      const ctx=cvs.getContext('2d');ctx.scale(2,2)
      const w=cvs.offsetWidth,h=cvs.offsetHeight
      const count=this.cfg_particle_count||100,speed=this.cfg_particle_speed||0.4,dist=this.cfg_particle_distance||80,color=this.cfg.login_page_particle_color||'#00b4ff'
      const particles=Array.from({length:count},()=>({x:Math.random()*w,y:Math.random()*h,vx:(Math.random()-0.5)*speed,vy:(Math.random()-0.5)*speed}))
      let running=true
      const animate=()=>{if(!running)return;ctx.clearRect(0,0,w,h)
        particles.forEach(p=>{p.x+=p.vx;p.y+=p.vy;if(p.x<0||p.x>w)p.vx*=-1;if(p.y<0||p.y>h)p.vy*=-1
          ctx.beginPath();ctx.arc(p.x,p.y,1.5,0,Math.PI*2);ctx.fillStyle=color;ctx.globalAlpha=0.4;ctx.fill();ctx.globalAlpha=1})
        for(let i=0;i<particles.length;i++){for(let j=i+1;j<particles.length;j++){const dx=particles[i].x-particles[j].x,dy=particles[i].y-particles[j].y,d=Math.sqrt(dx*dx+dy*dy);if(d<dist){ctx.beginPath();ctx.moveTo(particles[i].x,particles[i].y);ctx.lineTo(particles[j].x,particles[j].y);ctx.strokeStyle=color;ctx.globalAlpha=(1-d/dist)*0.06;ctx.stroke();ctx.globalAlpha=1}}}
        this._particleRAF=requestAnimationFrame(animate)}
      this._particleStop=()=>{running=false;cancelAnimationFrame(this._particleRAF)}
      animate()
    },
    destroyParticle(){if(this._particleStop){this._particleStop();this._particleStop=null;this._particleRAF=null}},
    hexToRgba(hex,opacity){
      if(!hex)return'rgba(255,255,255,0.85)'
      const c=hex.replace('#','');if(c.length===3)return`rgba(${parseInt(c[0]+c[0],16)},${parseInt(c[1]+c[1],16)},${parseInt(c[2]+c[2],16)},${opacity})`
      if(c.length===6)return`rgba(${parseInt(c.substring(0,2),16)},${parseInt(c.substring(2,4),16)},${parseInt(c.substring(4,6),16)},${opacity})`
      return hex
    },
  }
}
</script>

<style scoped>
.login-page-mgr{height:100vh;display:flex;flex-direction:column;background:#f0f2f5}
.mgr-header{height:56px;background:#fff;border-bottom:1px solid #EBEEF5;padding:0 24px;display:flex;align-items:center;justify-content:space-between;flex-shrink:0}
.mgr-header h2{font-size:20px;font-weight:bold;color:#303133;margin:0;display:inline}
.sub-title{font-size:13px;color:#909399;margin-left:12px}
.mgr-body{flex:1;display:flex;overflow:hidden}
.left-panel{width:50%;overflow-y:auto;background:#fff;padding:16px}
.right-panel{width:50%;display:flex;flex-direction:column;align-items:center;justify-content:flex-start;padding:24px;background:#f0f2f5;position:relative;overflow-y:auto}
.preview-label{position:absolute;top:28px;left:28px;background:#fff;border-radius:4px;padding:2px 10px;font-size:11px;color:#909399;z-index:10}
.phone-frame{width:375px;min-height:812px;background:#1a1a2e;border-radius:40px;padding:12px;box-shadow:0 20px 60px rgba(0,0,0,0.15),0 0 0 1px rgba(255,255,255,0.1);position:relative;flex-shrink:0}
.phone-notch{position:absolute;top:0;left:50%;transform:translateX(-50%);width:150px;height:28px;background:#1a1a2e;border-radius:0 0 16px 16px;z-index:5}
.phone-screen{width:351px;height:788px;border-radius:30px;overflow:hidden;position:relative}
.home-indicator{position:absolute;bottom:8px;left:50%;transform:translateX(-50%);width:134px;height:5px;background:rgba(255,255,255,0.2);border-radius:3px}
.particle-canvas{position:absolute;inset:0;z-index:2;pointer-events:none}
.pl-bg{position:absolute;inset:0;z-index:1}
.pl-content{position:absolute;inset:0;z-index:3;display:flex;flex-direction:column;padding:60px 20px 20px;overflow-y:auto}
.pl-brand{display:flex;align-items:center;gap:12px;margin-bottom:24px;justify-content:center}
.pl-logo{height:36px}
.lp-logo-row{display:flex;align-items:center;gap:8px}
.pl-name{font-size:20px;font-weight:600;letter-spacing:1px}
.pl-sub{font-size:11px;letter-spacing:2px;font-weight:300}
.pl-welcome{text-align:center;margin-bottom:28px}
.pl-title{font-size:22px;font-weight:700;color:#fff;text-shadow:0 0 40px rgba(0,0,0,0.3)}
.pl-stat{display:flex;align-items:center;justify-content:center;gap:8px;margin-top:8px}
.pl-dot{width:5px;height:5px;border-radius:50%;animation:pulse 2s ease-in-out infinite}
@keyframes pulse{0%,100%{opacity:1;transform:scale(1)}50%{opacity:0.3;transform:scale(0.6)}}
.pl-card{padding:24px;border-radius:20px;margin-bottom:16px}
.pl-tabs{display:flex;gap:0;margin-bottom:16px;border-bottom:1px solid rgba(255,255,255,0.1)}
.pl-tabs span{flex:1;text-align:center;padding:8px 0;font-size:13px;color:rgba(255,255,255,0.4);cursor:pointer;border-bottom:2px solid transparent}
.pl-tabs span.act{color:#00d4ff;border-bottom-color:#00d4ff}
.pl-form-raw{padding:0 20px;margin-bottom:16px}
.pl-error{font-size:12px;color:#ff6b6b;margin:4px 0;text-align:center}
.pl-footer{position:absolute;bottom:12px;left:0;right:0;text-align:center;font-size:9px;color:rgba(255,255,255,0.15)}
.sms-row{display:flex;gap:8px;align-items:center}
.sms-btn{height:44px;padding:0 12px;background:rgba(0,212,255,0.1);color:#00d4ff;border:1px solid rgba(0,212,255,0.2);border-radius:8px;font-size:13px;white-space:nowrap;cursor:pointer;flex-shrink:0}
.sms-btn:disabled{opacity:0.4}
.pl-wx{display:flex;align-items:center;justify-content:center;gap:8px;margin-top:12px;padding:12px;background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.06);border-radius:12px;color:#fff;font-size:14px;cursor:pointer;letter-spacing:0.5px;transition:all 0.3s}
.pl-wx:hover{background:rgba(255,255,255,0.08)}
.cfg-card{position:relative}
.card-badge{position:absolute;top:16px;right:40px;font-size:11px;color:#909399;background:#f0f2f5;padding:0 8px;border-radius:8px;line-height:20px;z-index:1}
.method-row{display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-bottom:1px solid #f0f2f5;font-size:14px}
.workbench{position:absolute;inset:0;background:#f5f6fa;z-index:3;padding:20px;overflow-y:auto}
.wb-header{background:#304156;color:#fff;padding:12px 16px;border-radius:12px;display:flex;align-items:center;justify-content:space-between;margin-bottom:16px}
.wb-stats{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:20px}
.wb-stat{background:#fff;border-radius:12px;padding:16px;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,0.04)}
.wb-num{font-size:28px;font-weight:bold;color:#409EFF}
.wb-lb{font-size:12px;color:#909399;margin-top:4px}
.wb-welcome{background:#fff;border-radius:12px;padding:20px;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,0.04)}
</style>
